/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

from std import sync.*


public class GlideBuilder {

    public var defaultRequestOptionsFactory: DefaultRequestOptionsFactory = DefaultRequestOptionsFactory()

    public var requestManagerFactory: Option<RequestManagerFactory> = Option<RequestManagerFactory>.None;

    public var memorySizeCalculator: Option<MemorySizeCalculator> = Option<MemorySizeCalculator>.None;

    public var memoryCache: Option<MemoryCache> = None;
    public var activeResources: Option<ActiveResources> = None;
    public var engine: Option<Engine> = None;

    public var diskCacheFactory: Option<InternalCacheDiskCacheFactory> = None;

    public var arrayPool: Option<LruArrayPool> = None;

    public func setRequestManagerFactory(factory: RequestManagerFactory) {
        this.requestManagerFactory = Option<RequestManagerFactory>.Some(factory);
    }

    public func setMemorySizeCalculator(calculator: MemorySizeCalculator): GlideBuilder {
        this.memorySizeCalculator = Option<MemorySizeCalculator>.Some(calculator);
        return this;
    }

    public func build(context: AbilityContext) {

        if (match(arrayPool) {
            case Some(x) => false
            case _ => true
        }) {
            // arrayPool = LruArrayPool(memorySizeCalculator.getArrayPoolSizeInBytes());
            arrayPool = Some(LruArrayPool(4 * 1024 * 1024));
        }

        if (match(memoryCache) {
            case Some(x) => false
            case _ => true
        }) {
            // memoryCache = new LruResourceCache(memorySizeCalculator.getMemoryCacheSize());
            memoryCache = Some(LruResourceCache(8192*1000*1000));
        }

        if (match(activeResources) {
            case Some(x) => false
            case _ => true
        }) {
            activeResources = Some(ActiveResources(8192*1000*1000));
        }

        if (match(diskCacheFactory) {
            case Some(x) => false
            case _ => true
        }) {
            diskCacheFactory = Some(InternalCacheDiskCacheFactory());
        }

        if (match(engine) {
            case Some(x) => false
            case _ => true
        }) {
            engine = Some(Engine(
                    memoryCache.getOrThrow(),
                    activeResources.getOrThrow(),
                    diskCacheFactory.getOrThrow(),
                    ));
        }

        return Glide(RequestManagerRetriever(), defaultRequestOptionsFactory, memoryCache.getOrThrow(), activeResources.getOrThrow(), context, engine.getOrThrow(), arrayPool.getOrThrow())
    }
}

public class Glide <: ActiveResourceRemovedListener {

    public static var globalcontext:Option<AbilityContext> = Option<AbilityContext>.None

    public static let LIFECYCLE_KEY_GLOBAL: String = "global"

    private let requestManagerRetriever: RequestManagerRetriever
    private let glideContext: GlideContext;

    private static let mtx = ReentrantMutex()

    public static var glide: Option<Glide> = Option<Glide>.None;
    public static var isInitializing: Bool = false;

    private let managers: HashSet<RequestManager> = HashSet<RequestManager>();
    private static let mtxManagers = ReentrantMutex()

    public var memoryCache: MemoryCache;
    public var activeResources: ActiveResources;

    public var engine: Engine;

    public var arrayPool: ArrayPool

    public init(requestManagerRetriever: RequestManagerRetriever, defaultRequestOptionsFactory: RequestOptionsFactory, memoryCache: MemoryCache, activeResources: ActiveResources, context: AbilityContext, engine: Engine, arrayPool: ArrayPool) {
        this.requestManagerRetriever = requestManagerRetriever
        this.glideContext = GlideContext(defaultRequestOptionsFactory, context, arrayPool)
        this.memoryCache = memoryCache
        this.activeResources = activeResources
        this.engine = engine
        this.arrayPool = arrayPool
        this.activeResources.setActiveResourceRemovedListener(this)
        globalcontext = context
    }

    public func getEngine(): Engine {
        return engine;
    }

    public func getGlideContext(): GlideContext {
        return this.glideContext
    }

    public func getArrayPool(): ArrayPool {
        return arrayPool;
    }

    public func setStringModelLoader(modelLoader: ModelLoader): Unit {
        this.glideContext.getManager().setStringModelLoader(modelLoader)
    }

    public func setFileModelLoaders(modelLoader: ModelLoader): Unit {
        this.glideContext.getManager().setFileModelLoader(modelLoader)
    }

    public static func get(context: AbilityContext): Glide {
        if (match(glide) {
            case Some(x) => false
            case _ => true
        }) {
            synchronized (mtx) {
                if (match(glide) {
                    case Some(x) => false
                    case _ => true
                }) {
                    checkAndInitializeGlide(context);
                }
            }
        }
        return glide.getOrThrow()
    }

    public static func checkAndInitializeGlide(context: AbilityContext) {
        if(isInitializing) {
            throw IllegalStateException("You cannot call Glide.get() in registerComponents(), use the provided Glide instance instead")
        }

        isInitializing = true;
        initializeGlide(context, GlideBuilder());
        isInitializing = false;
    }

    private static func initializeGlide(context: AbilityContext, builder: GlideBuilder) {
        // build
        let glideLocal: Glide = builder.build(context)

        Glide.glide = Some(glideLocal)
    }

    public func getRequestManagerRetriever() {
        return this.requestManagerRetriever
    }

    public static func getRetriever(context: AbilityContext): RequestManagerRetriever {
        return Glide.get(context).getRequestManagerRetriever()
    }

    public static func withContext(context: AbilityContext): RequestManager {
        return getRetriever(context).get(context, LIFECYCLE_KEY_GLOBAL)
    }

    //lipei--lp--20240401
    public static func withContext(context: AbilityContext, label: String): RequestManager {
        if (label.isEmpty()) {
            return getRetriever(context).get(context, LIFECYCLE_KEY_GLOBAL)
        }
        return getRetriever(context).get(context, label)
    }

    public func removeFromManagers(target: AnyTarget): Bool {
        synchronized (mtxManagers) {
            for (requestManager in managers) {
                if (requestManager.untrack(target)) {
                    return true;
                }
            }
        }

        return false;
    }

    public func clearMemory(): Unit {
        memoryCache.clearMemory();
    }

    public func trimMemory(level: Int64): Unit {
        // Name	                Value	Description
        // MEMORY_LEVEL_MODERATE	0	Moderate memory usage.
        // MEMORY_LEVEL_LOW	        1	Low memory usage.
        // MEMORY_LEVEL_CRITICAL	2	High memory usage.
        synchronized (mtxManagers) {
            for (manager in managers) {
                manager.onTrimMemory(level);
            }
        }
        // memory cache needs to be trimmed before bitmap pool to trim re-pooled Bitmaps too. See #687.
        memoryCache.trimMemory(level);
    }

    public func onActiveResourceRemoved(key: AnyKey, r: AnyGlideResource): Unit {
        memoryCache.put(key, r)
    }

    public func onAppear(): Unit {
        getRetriever(glideContext.ctx).getDeviceLifecycle(LIFECYCLE_KEY_GLOBAL).onAppear()
    }

    //lipei--lp--20240401
    public func onAppear(key: String): Unit {
        if (key.isEmpty()) {
            getRetriever(glideContext.ctx).getDeviceLifecycle(LIFECYCLE_KEY_GLOBAL).onAppear()
        } else {
            getRetriever(glideContext.ctx).getDeviceLifecycle(key).onAppear()
        }
    }

    public func onDisAppear(): Unit {
        getRetriever(glideContext.ctx).getDeviceLifecycle(LIFECYCLE_KEY_GLOBAL).onDisAppear()
    }

    //lipei--lp--20240401
    public func onDisAppear(key: String): Unit {
        if (key.isEmpty()) {
            getRetriever(glideContext.ctx).getDeviceLifecycle(LIFECYCLE_KEY_GLOBAL).onDisAppear()
        } else {
            getRetriever(glideContext.ctx).getDeviceLifecycle(key).onDisAppear()
        }
    }

    // public func onPageHide(key: String): Unit {
    //     var m: RequestManager = getRetriever(glideContext.ctx).get(glideContext.ctx, key)
    //     m.onStop()
    // }

    // public func getRequestManager(key: String): Option<RequestManager> {
    //     for(manager in managers) {
    //         if(manager.compare(key)) {
    //             return manager
    //         }
    //     }
    //     return None
    // }

    public func registerRequestManager(requestManager: RequestManager): Unit {
        synchronized (mtxManagers) {
            if (!managers.contains(requestManager)) {
                managers.put(requestManager);
            }
        }
    }

    public func unregisterRequestManager(requestManager: RequestManager): Unit {
        synchronized (mtxManagers) {
            AppLog.error("unregisterRequestManager ${managers.size}  ${requestManager.requestManagerKey}")
            for(m in managers) {
                AppLog.error(m.requestManagerKey)
            }
            if (!managers.contains(requestManager)) {
                throw IllegalStateException("Cannot unregister not yet registered manager");
            }
            managers.remove(requestManager);
        }
    }


}