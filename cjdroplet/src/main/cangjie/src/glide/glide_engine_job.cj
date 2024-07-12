/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

from ohos import image.*

public class EngineResourceFactory {
    public func build<R>(
        resource: GlideResource<R>,
        isMemoryCacheable: Bool,
        key: AnyKey, 
        listener: ResourceListener,
        resourceTypeClass: ResourceTypeClass): EngineResource<R> {
      return EngineResource<R>(
          resource, isMemoryCacheable, /*isRecyclable=*/ true, key, listener, resourceTypeClass);
    }

    public func buildAny(
        resource: AnyGlideResource,
        isMemoryCacheable: Bool,
        key: AnyKey, 
        listener: ResourceListener,
        resourceTypeClass: ResourceTypeClass): AnyEngineResource {
      return AnyEngineResource(
          resource, isMemoryCacheable, /*isRecyclable=*/ true, key, listener, resourceTypeClass);
    }
}

public interface EngineJobListener {

  func onEngineJobComplete(engineJob: EngineJob, key: AnyKey, resource: Option<AnyEngineResource>): Unit;

  func onEngineJobCancelled(engineJob: EngineJob, key: AnyKey): Unit;
}

public class EngineJob <: DecodeJobCallback & Equatable<EngineJob> {

    private static let DEFAULT_FACTORY: EngineResourceFactory  = EngineResourceFactory();


    private let resourceListener: ResourceListener;
    private let engineResourceFactory: EngineResourceFactory = DEFAULT_FACTORY;
    private let stateVerifier: StateVerifier = StateVerifier.newInstance();
    public let excutor: GlideExecutor<Option<InputStream>>

    private var dataSource: Option<DataSource> = None;

    public var engineResource: Option<AnyEngineResource> = None;
    public var resource: Option<AnyGlideResource> = None;

    public var hasResource: Bool = false;
    public var hasLoadFailed: Bool = false;
    public var isCancelled: Bool = false;

    public var decodeJob: Option<DecodeJob> = None

    public let cbs: ArrayList<ResourceCallbackAndExecutor> = ArrayList<ResourceCallbackAndExecutor>(2);

    private let mtx: ReentrantMutex

    public let pendingCallbacks: AtomicInt64 = AtomicInt64(0);

    public var isLoadedFromAlternateCacheKey: Bool = false;

    public var key: Option<AnyKey> = None;
    public var isCacheable: Bool = false;
    public var onlyRetrieveFromCache: Bool = false;

    public let resourceTypeClass: ResourceTypeClass

    private var exception: Option<GlideException> = None;

    private var engineJobListener: EngineJobListener;

    public init(excutor: GlideExecutor<Option<InputStream>>, engineJobListener: EngineJobListener, resourceListener: ResourceListener, resourceTypeClass: ResourceTypeClass) {
        this.excutor = excutor
        this.resourceListener = resourceListener
        this.engineJobListener = engineJobListener
        this.resourceTypeClass = resourceTypeClass
        mtx = ReentrantMutex()
    }

    public func initEngine(key: AnyKey,
                            isCacheable: Bool,
                            onlyRetrieveFromCache: Bool): EngineJob {
        synchronized(mtx) {
            this.key = key
            this.isCacheable = isCacheable;
            this.onlyRetrieveFromCache = onlyRetrieveFromCache;
            return this
        }
        
    }

    public func getMtx():ReentrantMutex{
        return mtx
    }

    public func start(job: DecodeJob): Unit {
        synchronized(mtx) {
            this.decodeJob = job
            reschedule(job)
        }
    }

    public func reschedule(job: DecodeJob): Unit {
        excutor.execute(job)
    }

    public func callCallbackOnResourceReady(cb: ResourceCallback): Unit {
            cb.onResourceReady(engineResource.getOrThrow() as AnyGlideResource, dataSource.getOrThrow(), isLoadedFromAlternateCacheKey);
    }

    public func onResourceReady(resource: AnyGlideResource, 
                          dataSource: DataSource, 
                          isLoadedFromAlternateCacheKey: Bool): Unit {

                            AppLog.error("onResourceReady")
                            synchronized (mtx) {
                                if(resource is GlideResource<InputStream>) {
                                    AppLog.error("resource is InputStream1")
                                } else if(resource is GlideResource<GifDrawable>) {
                                    AppLog.error("resource is GifDrawable1")
                                } else if(resource is GlideResource<PixelMap>) {
                                    AppLog.error("resource is PixelMap1")
                                }
                                this.resource = Some(resource);
                                this.dataSource = Some(dataSource);
                                this.isLoadedFromAlternateCacheKey = isLoadedFromAlternateCacheKey;
                            }
                            notifyCallbacksOfResult();

    }

    public func onLoadFailed(e: GlideException): Unit {
        AppLog.error("EngineJob onLoadFailed")
        synchronized (mtx) {
            this.exception = e;
        }
        notifyCallbacksOfException();
    }

    public func notifyCallbacksOfResult(): Unit {
        let copy: ArrayList<ResourceCallbackAndExecutor>
        let localKey: AnyKey;
        let localResource: AnyEngineResource;
        synchronized (mtx) {
            stateVerifier.throwIfRecycled();
            AppLog.error("isCancelled : ${isCancelled}")
            if (isCancelled) {
                // TODO: Seems like we might as well put this in the memory cache instead of just recycling
                // it since we've gotten this far...
                resource.getOrThrow().recycle();
                 AppLog.error("notifyCallbacksOfResult release")
                release();
                return;
            } else if (cbs.isEmpty()) {
                throw IllegalStateException("Received a resource without any callbacks to notify");
            } else if (hasResource) {
                throw IllegalStateException("Already have resource");
            }

            AppLog.error("notifyCallbacksOfResult 1")
            
            engineResource = Some(engineResourceFactory.buildAny(
                                resource.getOrThrow(),
                                isCacheable, 
                                key.getOrThrow(),
                                resourceListener, 
                                resourceTypeClass));

            // Hold on to resource for duration of our callbacks below so we don't recycle it in the
            // middle of notifying if it synchronously released by one of the callbacks. Acquire it under
            // a lock here so that any newly added callback that executes before the next locked section
            // below can't recycle the resource before we call the callbacks.
            hasResource = true;
            copy = cbs.clone();

            incrementPendingCallbacks(copy.size + 1);

            localKey = key.getOrThrow();
            localResource = engineResource.getOrThrow();
        }

        engineJobListener.onEngineJobComplete(this, localKey, Some(localResource));

        for (entry in copy) {
            entry.executor.execute(CallResourceReady("notifyCallbacksOfResult", entry.cb, this));
        }
        decrementPendingCallbacks();
    }

    public func notifyCallbacksOfException(): Unit {
        AppLog.error("notifyCallbacksOfException")
        let copy: ArrayList<ResourceCallbackAndExecutor>;
        let localKey: AnyKey;
        synchronized (mtx) {
            stateVerifier.throwIfRecycled();
            if (isCancelled) {
                AppLog.error("notifyCallbacksOfException release")
                release();
                return;
            } else if (cbs.isEmpty()) {
                throw IllegalStateException("Received an exception without any callbacks to notify");
            } else if (hasLoadFailed) {
                throw IllegalStateException("Already failed once");
            }
            hasLoadFailed = true;

            localKey = key.getOrThrow();

            copy = cbs.clone();

            // One for each callback below, plus one for ourselves so that we finish if a callback runs on
            // another thread before we finish scheduling all of them.
            incrementPendingCallbacks(copy.size + 1);
        }

        engineJobListener.onEngineJobComplete(this, localKey, /*resource=*/ Option<AnyEngineResource>.None);

        for (entry in copy) {
            entry.executor.execute(CallLoadFailed("notifyCallbacksOfException", entry.cb, this));
        }
        decrementPendingCallbacks();
    }

    public func addCallback(cb: ResourceCallback, callbackExecutor: GlideExecutor<Option<InputStream>>) {
        synchronized(mtx) {
            stateVerifier.throwIfRecycled();
            cbs.append(ResourceCallbackAndExecutor(cb, callbackExecutor))
            if (hasResource) {
                // Acquire early so that the resource isn't recycled while the Runnable below is still sitting
                // in the executors queue.
                incrementPendingCallbacks(1);
                callbackExecutor.execute(CallResourceReady("engineJobCallResourceReady", cb, this));
            } else if (hasLoadFailed) {
                incrementPendingCallbacks(1);
                callbackExecutor.execute(CallLoadFailed("engineJobCallResourceReadyCallLoadFailed", cb, this));
            } else {
                if(isCancelled) {
                    throw GlideException("Cannot add callbacks to a cancelled EngineJob")
                }
            }
        }
    }

    public func removeCallback(cb: ResourceCallback): Unit {
        AppLog.error("removeCallback begin")
        synchronized(mtx) {
            stateVerifier.throwIfRecycled();
            try {
                for(i in 0 .. cbs.size) {
                    let f = cbs[i]
                    if(f.cb == cb) {
                        cbs.remove(i)
                        break;
                    }
                }
            } catch(e: Exception) {
                AppLog.error("removeCallback error: ${e}")
            }

            if (cbs.isEmpty()) {
                AppLog.error("removeCallback begin4")
                cancel();
                let isFinishedRunning: Bool = hasResource || hasLoadFailed;
                if (isFinishedRunning && pendingCallbacks.load() == 0) {
                    release();
                }
            }
            AppLog.error("removeCallback finish")
        }
    }

    public func cancel(): Unit {
        AppLog.error("Engine job cancel")
        if (isDone()) {
            return;
        }

        isCancelled = true;
        if(match(decodeJob) {
            case Some(x) => true
            case _ => false
        }) {
            decodeJob.getOrThrow().cancel();
        }
        
        if(match(key) {
            case Some(x) => true
            case _ => false
        }) {
            engineJobListener.onEngineJobCancelled(this, key.getOrThrow());
        }
        
    }

    public func callCallbackOnLoadFailed(cb: ResourceCallback): Unit {
        // This is overly broad, some Glide code is actually called here, but it's much
        // simpler to encapsulate here than to do so at the actual call point in the Request
        // implementation.
        try {
            cb.onLoadFailed(this.exception.getOrThrow());
        } catch (e: Exception) {
            throw GlideException("callCallbackOnLoadFailed: ${e}");
        }
    }

    public func incrementPendingCallbacks(count: Int64): Unit {
        synchronized(mtx) {
            if (pendingCallbacks.fetchAdd(count) == 0 && match(engineResource) {
                case Some(x) => true
                case _ => false
            }) {
                engineResource.getOrThrow().acquire();
            }
        }
    }

    public func decrementPendingCallbacks(): Unit {
        var toRelease: Option<AnyEngineResource> = None;
        synchronized (mtx) {
            stateVerifier.throwIfRecycled();
            pendingCallbacks.fetchSub(1)
            let decremented: Int64 = pendingCallbacks.load();
            if (decremented == 0) {
                toRelease = engineResource;

                AppLog.error("decrementPendingCallbacks release")
                release();
            }
        }

        if (match(toRelease) {
            case Some(x) => true
            case _ => false
        }) {
            toRelease.getOrThrow().release();
        }
    }

    private func release(): Unit {
        AppLog.error("engine job release")
        synchronized(mtx) {
            if (match(key) {
                case Some(x) => false
                case _ => true
            }) {
                throw IllegalArgumentException();
            }
            cbs.clear();
            key = None;
            engineResource = None;
            resource = None;
            hasLoadFailed = false;
            isCancelled = false;
            hasResource = false;
            isLoadedFromAlternateCacheKey = false;
            decodeJob.getOrThrow().release(/*isRemovedFromQueue=*/ false);
            decodeJob = None;
            dataSource = None;
        }
        
    }

    public func getCancelled(): Bool {
        synchronized(mtx) {
            return isCancelled;
        }
    }

    public func isDone(): Bool {
        return hasLoadFailed || hasResource || isCancelled;
    }

    public func equals(other: EngineJob): Bool {
        this.pendingCallbacks.load() == other.pendingCallbacks.load() && 
        this.key == other.key && 
        this.isCacheable == other.isCacheable && 
        this.onlyRetrieveFromCache == other.onlyRetrieveFromCache &&
        this.isLoadedFromAlternateCacheKey == other.isLoadedFromAlternateCacheKey &&
        this.cbs == other.cbs &&
        this.hasResource == other.hasResource &&
        this.hasLoadFailed == other.hasLoadFailed &&
        this.isCancelled == other.isCancelled
    }

    public operator func ==(that: EngineJob): Bool {
        if(that is EngineJob) {
            let other: EngineJob = (that as EngineJob).getOrThrow()
            return equals(other)
        }
        return false
    }

    public operator func !=(that: EngineJob): Bool {
        if(that is EngineJob) {
            let other: EngineJob = (that as EngineJob).getOrThrow()
            return !equals(other)
        }
        return true
    }

}


public class CallResourceReady <: GlideThread<Option<InputStream>> {

    private let cb: ResourceCallback;
    private let ej: EngineJob;

    public init(name: String, cb: ResourceCallback, ej: EngineJob) {
        super(name)
        this.cb = cb;
        this.ej = ej
    }

    public func runWrap(): Option<InputStream> {

        // Make sure we always acquire the request lock, then the EngineJob lock to avoid deadlock
      // TODO cb.getLock()
            AppLog.error("getLock begin ${cb}")
            synchronized (this.ej.getMtx()) {
                try {
                    if (this.ej.cbs.contains(ResourceCallbackAndExecutor(cb, this.ej.excutor))) {
                        this.ej.engineResource.getOrThrow().acquire();
                        this.ej.callCallbackOnResourceReady(cb);
                        this.ej.removeCallback(cb);
                    }
                    this.ej.decrementPendingCallbacks();
                } catch(e: Exception) {
                    AppLog.error("getLock error : ${e}")
                }
            }
        return None
    }

  }

  public class CallLoadFailed <: GlideThread<Option<InputStream>> {

    private let cb: ResourceCallback;
    private let ej: EngineJob;

    public init(name: String, cb: ResourceCallback, ej: EngineJob) {
        super(name)
        this.cb = cb;
        this.ej = ej
    }

    public func runWrap(): Option<InputStream> {
        // Make sure we always acquire the request lock, then the EngineJob lock to avoid deadlock
      // (b/136032534).
        // synchronized (cb.getLock()) {
            synchronized (this.ej.getMtx()) {
                if (this.ej.cbs.contains(ResourceCallbackAndExecutor(cb, this.ej.excutor))) {
                    this.ej.callCallbackOnLoadFailed(cb);
                }

                this.ej.decrementPendingCallbacks();
                return None
            }
    }

  }

  public class ResourceCallbackAndExecutor <: Equatable<ResourceCallbackAndExecutor> & Hashable {
    public let cb: ResourceCallback;
    public let executor: GlideExecutor<Option<InputStream>>;

    public init(cb: ResourceCallback, executor: GlideExecutor<Option<InputStream>>) {
      this.cb = cb;
      this.executor = executor;
    }

    public func equals(o: Any): Bool {
      if (o is ResourceCallbackAndExecutor) {
        let other: ResourceCallbackAndExecutor = (o as ResourceCallbackAndExecutor).getOrThrow();
        return cb == other.cb;
      }
      return false;
    }

     public operator func ==(that: ResourceCallbackAndExecutor): Bool {
        return equals(that)
    }

    public operator func !=(that: ResourceCallbackAndExecutor): Bool {
        return !equals(that)
    }

    public func hashCode(): Int64 {
      return cb.hashCode();
    }
  }
