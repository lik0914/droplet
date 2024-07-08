package glide

from std import sync.*
from std import io.*
from std import fs.*


// interface DecodeJobListener {

//   func onEngineJobComplete(EngineJob<?> engineJob, Key key, EngineResource<?> resource);

//   func onEngineJobCancelled(EngineJob<?> engineJob, Key key);
// }

/** Responsible for starting loads and managing active and cached resources. */
public class Engine <: ActiveResourceRemovedListener & ResourceRemovedListener & ResourceListener & EngineJobListener {
//   private static let JOB_POOL_SIZE: Int64 = 150;
//   private static let boolean VERBOSE_IS_LOGGABLE = Log.isLoggable(TAG, Log.VERBOSE);
  private let jobs: Jobs;
  private let keyFactory: EngineKeyFactory;
  private let cache: MemoryCache;
//   private let engineJobFactory: EngineJobFactory;
//   private let ResourceRecycler resourceRecycler;
  private let diskCacheProvider: DiskCacheProvider;
  // private let decodeJobFactory: DecodeJobFactory;
  private let activeResources: ActiveResources;

  private let mtx = ReentrantMutex();

  public init(
      cache: MemoryCache,
      activeResources: ActiveResources,
      diskCacheFactory: DiskCacheFactory
      ) {
    this.cache = cache;
    this.diskCacheProvider = LazyDiskCacheProvider(diskCacheFactory);

    this.activeResources = activeResources;

    this.keyFactory = EngineKeyFactory();

    this.jobs = Jobs();

  }

  public func onEngineJobComplete(
      engineJob: EngineJob, key: AnyKey, resource: Option<AnyEngineResource>): Unit {
        AppLog.error("onEngineJobComplete: ${resource}")
    // A null resource indicates that the load failed, usually due to an exception.
    synchronized(mtx) {
      // if (resource != null && resource.isMemoryCacheable()) {
      //   activeResources.activate(key, resource);
      // }
      // AppLog.error("onEngineJobComplete")

      if(match(resource) {
        case Some(x) => true
        case _ => false
      }) {
        activeResources.put(key, resource.getOrThrow())
      }
      
      jobs.removeIfCurrent(key, engineJob);
    }
  }

  public func onEngineJobCancelled(engineJob: EngineJob, key: AnyKey): Unit {
    synchronized(mtx) {
      // AppLog.error("onEngineJobCancelled")
      jobs.removeIfCurrent(key, engineJob);
    }
  }

  public func setActiveResourceRemovedListener() {
    this.activeResources.setActiveResourceRemovedListener(this);
  }

  public func setResourceRemovedListener() {
    this.cache.setResourceRemovedListener(this);
  }

  public func load(
      glideContext: GlideContext,
      signature: AnyKey,
      model: Model,
      width: Int64,
      height: Int64,
      resourceTypeClass: ResourceTypeClass,
      transformationKey: TransformationKey,
      // Priority priority,
      diskCacheStrategy: DiskCacheStrategy,
      transformations: CachedHashCodeArrayMap<TransformationKey, AnyKey>,
      isTransformationRequired: Bool,
      isScaleOnlyOrNoTransform: Bool,
      options: GlideOptions,
      isMemoryCacheable: Bool,
      // useUnlimitedSourceExecutorPool: Bool,
      // useAnimationPool: Bool,
      onlyRetrieveFromCache: Bool,
      cb: ResourceCallback): Option<LoadStatus> {
    // long startTime = VERBOSE_IS_LOGGABLE ? LogTime.getLogTime() : 0;
    
    var key: EngineKey =
        keyFactory.buildKey(
            model,
            signature,
            width,
            height,
            transformations,
            resourceTypeClass,
            transformationKey,
            options);

    var memoryResource: Option<AnyEngineResource>;
    synchronized (mtx) {
      memoryResource = loadFromMemory(key, isMemoryCacheable);

      if (match(memoryResource) {
        case Some(x) => false
        case _ => true
      }) {
        return waitForExistingOrStartNewJob(
            glideContext,
            model,
            signature,
            width,
            height,
            resourceTypeClass,
            transformationKey,
            // priority,
            diskCacheStrategy,
            transformations,
            isTransformationRequired,
            isScaleOnlyOrNoTransform,
            options,
            isMemoryCacheable,
            // useUnlimitedSourceExecutorPool,
            // useAnimationPool,
            onlyRetrieveFromCache,
            cb,
            key
            // startTime
            );
      }
    }

    // Avoid calling back while holding the engine lock, doing so makes it easier for callers to
    // deadlock.
    cb.onResourceReady(
        (memoryResource.getOrThrow() as AnyGlideResource), DataSource.MEMORY_CACHE, /* isLoadedFromAlternateCacheKey= */ false);
    return None;
  }

  private func waitForExistingOrStartNewJob(
      glideContext: GlideContext,
      model: Model,
      signature: AnyKey,
      width: Int64,
      height: Int64,
      resourceTypeClass: ResourceTypeClass,
      transformationKey: TransformationKey,
      // Priority priority,
      diskCacheStrategy: DiskCacheStrategy ,
      transformations: CachedHashCodeArrayMap<TransformationKey, AnyKey>,
      isTransformationRequired: Bool,
      isScaleOnlyOrNoTransform: Bool,
      options: GlideOptions,
      isMemoryCacheable: Bool,
      // useUnlimitedSourceExecutorPool: Bool,
      // useAnimationPool: Bool,
      onlyRetrieveFromCache: Bool,
      cb: ResourceCallback,
      key: EngineKey
      // long startTime
      ): Option<LoadStatus> {
        // AppLog.error("waitForExistingOrStartNewJob begin")
    let callbackExecutor = GlideExecutor<Option<InputStream>>()
    var current: Option<EngineJob> = jobs.get(key, onlyRetrieveFromCache);
    if (match(current) {
      case Some(x) => true
      case _ => false
    }) {
      // AppLog.error("waitForExistingOrStartNewJob current")
      current.getOrThrow().addCallback(cb, callbackExecutor);
      // if (VERBOSE_IS_LOGGABLE) {
      //   logWithTimeAndKey("Added to existing load", startTime, key);
      // }
      return LoadStatus(cb, mtx, current.getOrThrow());
    }
    
    let engineJob: EngineJob = EngineJob(callbackExecutor, this, this, resourceTypeClass)
                                .initEngine(
                                  key,
                                  isMemoryCacheable,
                                  onlyRetrieveFromCache)

    let decodeJob: DecodeJob = DecodeJob("DecodeJob", 
                                          diskCacheProvider, 
                                          cb,
                                          glideContext,
                                          model,
                                          key,
                                          signature,
                                          width,
                                          height,
                                          resourceTypeClass, 
                                          transformationKey,
                                          diskCacheStrategy,
                                          transformations,
                                          isTransformationRequired,
                                          isScaleOnlyOrNoTransform,
                                          onlyRetrieveFromCache,
                                          options,
                                          engineJob)

    jobs.put(key, engineJob);
    engineJob.addCallback(cb, callbackExecutor);
    engineJob.start(decodeJob)
    // engineJob.reschedule(decodeJob)

        // decodeJobFactory.build(
        //     glideContext,
        //     model,
        //     key,
        //     signature,
        //     width,
        //     height,
        //     resourceClass,
        //     transcodeClass,
        //     priority,
        //     diskCacheStrategy,
        //     transformations,
        //     isTransformationRequired,
        //     isScaleOnlyOrNoTransform,
        //     onlyRetrieveFromCache,
        //     options,
        //     cb);

    // jobs.put(key, decodeJob);
    // decodeJob.start()

    // return Some(LoadStatus(cb, decodeJob));



    let ls: LoadStatus = LoadStatus(cb, mtx, engineJob)
    return ls
  }

  // public func requestFinish(r: Array<UInt8>) {
  //   AppLog.error("requestFinish")
  //   for(aa in r) {
  //     AppLog.error(aa)
  //   }
  // }

  private func loadFromMemory(key: EngineKey, isMemoryCacheable: Bool): Option<AnyEngineResource> {
    AppLog.error("loadFromMemory : ${key} --- ${isMemoryCacheable}")
    if (!isMemoryCacheable) {
      return None;
    }

    var active: Option<AnyEngineResource> = loadFromActiveResources(key);
    if (match(active) {
      case Some(x) => true
      case _ => false
    }) {
      // if (VERBOSE_IS_LOGGABLE) {
      //   logWithTimeAndKey("Loaded resource from active resources", startTime, key);
      // }
      AppLog.error("active is : ${active.getOrThrow()}")
      return active;
    }

    var cached: Option<AnyEngineResource> = loadFromCache(key);
    if (match(cached) {
      case Some(x) => true
      case _ => false
    }) {
      // if (VERBOSE_IS_LOGGABLE) {
      //   logWithTimeAndKey("Loaded resource from cache", startTime, key);
      // }
      AppLog.error("cached is : ${cached.getOrThrow()}")
      return cached;
    }

    return None;
  }

  // private static void logWithTimeAndKey(String log, long startTime, Key key) {
  //   Log.v(TAG, log + " in " + LogTime.getElapsedMillis(startTime) + "ms, key: " + key);
  // }

  private func loadFromActiveResources(key: AnyKey): Option<AnyEngineResource> {
    AppLog.error("loadFromActiveResources : ${key}")
    var active: Option<AnyGlideResource> = activeResources.get(key);
    if(match(active) {
      case Some(x) => false
      case _ => true
    }) {
      AppLog.error("loadFromActiveResources fail")
      return None
    }
    AppLog.error("loadFromActiveResources success")
    return (active.getOrThrow() as AnyEngineResource)
  }

  private func loadFromCache(key: AnyKey): Option<AnyEngineResource> {
    AppLog.error("loadFromCache : ${key}")
    let r: Option<AnyEngineResource> = getEngineResourceFromCache(key)
    if(match(r) {
      case Some(x) => true
      case _ => false
    }) {
      AppLog.error("loadFromCache success")
      activeResources.put(key, r.getOrThrow())
    }
    return r;
  }

  private func getEngineResourceFromCache(key: AnyKey): Option<AnyEngineResource> {
    var cached: Option<AnyGlideResource> = cache.remove(key);

    var result: Option<AnyEngineResource>;
    if (match(cached) {
      case Some(x) => false
      case _ => true
    }) {
      result = None;
    } else if (cached.getOrThrow() is AnyEngineResource) {
      // Save an object allocation if we've cached an EngineResource (the typical case).
      result = cached.getOrThrow() as AnyEngineResource;
    } else {
      result = Some(AnyEngineResource(
              cached.getOrThrow(), /*isMemoryCacheable=*/ true, /*isRecyclable=*/ true, key, /*listener=*/ this, ResourceTypeClass.RESOURCE_TYPE_PIXELMAP));
    }
    return result;
  }

  public func release(resource: AnyGlideResource): Unit {
    if (resource is AnyEngineResource) {
      (resource as AnyEngineResource).getOrThrow().release();
    } else {
      throw IllegalArgumentException("Cannot release anything but an EngineResource");
    }
  }

  // public func onEngineJobComplete(engineJob: EngineJob, key: AnyKey, resource: AnyEngineResource): Unit {
  //       synchronized(mtx) {
  //         // A null resource indicates that the load failed, usually due to an exception.
  //         // if (resource != null && resource.isMemoryCacheable()) {
  //         //   activeResources.activate(key, resource);
  //         // }

  //         // jobs.removeIfCurrent(key, engineJob);
  //       }
  // }

  // public func onEngineJobCancelled(engineJob: EngineJob, key: AnyKey): Unit {
  //   synchronized(mtx) {
  //     // jobs.removeIfCurrent(key, engineJob);
  //   }
  // }

  public func onResourceRemoved(resource: AnyGlideResource): Unit {
    // Avoid deadlock with RequestManagers when recycling triggers recursive clear() calls.
    // See b/145519760.
    // TODO
    resource.recycle()
  }

  public func onActiveResourceRemoved(cacheKey: AnyKey, resource: AnyGlideResource): Unit {
        if(resource is AnyEngineResource) {
            let engineResource = (resource as AnyEngineResource).getOrThrow()
              if (engineResource.getMemoryCacheable()) {
                  cache.put(cacheKey, engineResource);
              } else {
                  engineResource.recycle();
              }
          }
  }

  public func onResourceReleased(cacheKey: AnyKey, resource: AnyEngineResource): Unit {
    // TODO 放到二级缓存中
     //activeResources.deactivate(cacheKey);
     if (resource.getMemoryCacheable()) {
       cache.put(cacheKey, resource);
     } else {
       resource.recycle()
     }
  }

  public func clearDiskCache(): Unit {
    // diskCacheProvider.getDiskCache().clear();
  }

  public func shutdown(): Unit {
    // engineJobFactory.shutdown();
    // diskCacheProvider.clearDiskCacheIfCreated();
    // activeResources.shutdown();
  }

}

public enum RunReason {
  /** The first time we've been submitted. */
  INITIALIZE |
  /** We want to switch from the disk cache service to the source executor. */
  SWITCH_TO_SOURCE_SERVICE |
  /**
    * We retrieved some data on a thread we don't own and want to switch back to our thread to
    * process the data.
    */
  DECODE_DATA
}

public enum RunStage {
    /** The initial stage. */
    INITIALIZE |
    /** Decode from a cached resource. */
    RESOURCE_CACHE |
    /** Decode from cached source data. */
    DATA_CACHE |
    /** Decode from retrieved source. */
    SOURCE |
    /** Encoding transformed resources after a successful load. */
    ENCODE |
    /** No more viable stages. */
    FINISHED
}

public class DecodeJob <: GlideThread<Option<InputStream>> & FetcherReadyCallback {

  private static let mtxtrans = ReentrantMutex()

  private let model: Model
  private var width: Int64
  private var height: Int64
  private let transformationKey: TransformationKey
  private let cb: ResourceCallback

  private let decodeHelper: DecodeHelper;

  private var runReason: RunReason
  private var runStage: RunStage

  private var glideContext: GlideContext
  private var loadKey: EngineKey
  private var signature: AnyKey

  private var diskCacheStrategy: DiskCacheStrategy
  private var options: GlideOptions
  public var onlyRetrieveFromCache: Bool;

  private let diskCacheProvider: DiskCacheProvider;

  // volatile
  private var currentGenerator: Option<DataFetcherGenerator> = None;

  private let callback: DecodeJobCallback;

  // volatile
  private var isCancelled: Bool = false

  private var currentData: Option<Any> = None;
  private var currentDataSource: Option<DataSource> = None;
  private var currentSourceKey: Option<AnyKey> = None

  // volatile
  private var isCallbackNotified: Bool = false;
  private var isLoadingFromAlternateCacheKey: Bool = false;

  private let stateVerifier: StateVerifier = StateVerifier.newInstance();

  private var deferredEncodeManager: Option<AnyDeferredEncodeManager> = None

  private let releaseManager: ReleaseManager = ReleaseManager();

  public init(name: String, 
    diskCacheProvider: DiskCacheProvider, 
    cb: ResourceCallback,
    glideContext: GlideContext,
      model: Model,
      loadKey: EngineKey,
      signature: AnyKey,
      width: Int64,
      height: Int64,
      resourceTypeClass: ResourceTypeClass,
      transformationKey: TransformationKey,
      // Priority priority,
      diskCacheStrategy: DiskCacheStrategy,
      transformations: CachedHashCodeArrayMap<TransformationKey, AnyKey>,
      isTransformationRequired: Bool,
      isScaleOnlyOrNoTransform: Bool,
      onlyRetrieveFromCache: Bool,
      options: GlideOptions,
      callback: DecodeJobCallback) {
    super(name)
    this.model = model
    this.width = width
    this.height = height
    this.transformationKey = transformationKey
    this.cb = cb
    this.runReason = RunReason.INITIALIZE;
    this.diskCacheProvider = diskCacheProvider
    this.glideContext = glideContext;
    this.signature = signature;
    // this.priority = priority;
    this.loadKey = loadKey;
    this.width = width;
    this.height = height;
    this.diskCacheStrategy = diskCacheStrategy;
    this.onlyRetrieveFromCache = onlyRetrieveFromCache;
    this.options = options;
    this.runStage = RunStage.INITIALIZE
    this.callback = callback 
    this.decodeHelper = DecodeHelper(glideContext,
        model,
        signature,
        width,
        height,
        diskCacheStrategy,
        resourceTypeClass,
        transformationKey,
        // priority,
        options,
        transformations,
        isTransformationRequired,
        isScaleOnlyOrNoTransform,
        diskCacheProvider)
  }

  private func runWrapped(): Unit {
    match(runReason) {
      case INITIALIZE =>
        runStage = getNextStage(RunStage.INITIALIZE);
        currentGenerator = getNextGenerator();
        runGenerators();

      case SWITCH_TO_SOURCE_SERVICE =>
        runGenerators();

      case DECODE_DATA =>
        decodeFromRetrievedData();

    }
  }

  public func runWrap(): Option<InputStream> {

    try {
      if (isCancelled) {
        notifyFailed();
        return Option<InputStream>.None;
      }
      runWrapped();
    } catch (e: Exception) {
      // Catch Throwable and not Exception to handle OOMs. Throwables are swallowed by our
      // usage of .submit() in GlideExecutor so we're not silently hiding crashes by doing this. We
      // are however ensuring that our callbacks are always notified when a load fails. Without this
      // notification, uncaught throwables never notify the corresponding callbacks, which can cause
      // loads to silently hang forever, a case that's especially bad for users using Futures on
      // background threads.
      // if (Log.isLoggable(TAG, Log.DEBUG)) {
      //   Log.d(
      //       TAG,
      //       "DecodeJob threw unexpectedly" + ", isCancelled: " + isCancelled + ", stage: " + stage,
      //       t);
      // }
      // When we're encoding we've already notified our callback and it isn't safe to do so again.
      AppLog.error("run wrap exception: ${e}")
      if (match(runStage) {
        case RunStage.ENCODE => false
        case _ => true
      }) {
        notifyFailed();
      }
      if (!isCancelled) {
        throw e;
      }
      throw e;
    }

    return Option<InputStream>.None;

  }

  public func cancel(): Unit {
    isCancelled = true;
    let local: Option<DataFetcherGenerator> = currentGenerator;
    if (match(local) {
      case Some(x) => true
      case _ => false
    }) {
      local.getOrThrow().cancel();
    }
  }

  public func release(isRemovedFromQueue: Bool): Unit {
    if (releaseManager.release(isRemovedFromQueue)) {
      releaseInternal();
    }
  }

  private func decodeFromRetrievedData(): Unit {

      if(currentData.getOrThrow() is InputStream) {
        let data: Any = currentData.getOrThrow()
        let rs: Option<Any> = decodeFromData<Any>(Some(data), currentDataSource.getOrThrow());
          if(match(rs) {
          case Some(x) => true
          case _ => false
        }) {
          let rr: Any = rs.getOrThrow()
          if(rr is ByteArrayStream) {
            AppLog.error("rr is ByteArrayStream")
            let ri: InputStream = (rr as ByteArrayStream).getOrThrow()
            let resource: GlideResource<InputStream> = InputStreamResource.obtain(ri)
            notifyEncodeAndRelease<InputStream>(resource, currentDataSource.getOrThrow(), isLoadingFromAlternateCacheKey);
          } else if(rr is GifDrawable) {
            AppLog.error("rr is GifDrawable")
            let ri: GifDrawable = (rr as GifDrawable).getOrThrow()
            let resource: GlideResource<GifDrawable> = GifDrawableResource.obtain(ri)
            notifyEncodeAndRelease<GifDrawable>(resource, currentDataSource.getOrThrow(), isLoadingFromAlternateCacheKey);
          } else if(rr is PixelMapDrawable) {
            AppLog.error("rr is PixelMapDrawable")
            let ri: PixelMapDrawable = (rr as PixelMapDrawable).getOrThrow()
            let resource: GlideResource<PixelMapDrawable> = PixelMapDrawableResource.obtain(ri)
            notifyEncodeAndRelease<PixelMapDrawable>(resource, currentDataSource.getOrThrow(), isLoadingFromAlternateCacheKey);
          } else {
            throw GlideException("rr is nothing")
          }
          
        }
      }
  }

  private func notifyEncodeAndRelease<R>(
      resource: GlideResource<R>, 
      dataSource: DataSource, 
      isLoadedFromAlternateCacheKey: Bool): Unit {
    // GlideTrace.beginSection("DecodeJob.notifyEncodeAndRelease");
    try {
      // if (resource instanceof Initializable) {
      //   ((Initializable) resource).initialize();
      // }

      var result: GlideResource<R> = resource;
      var lockedResource: Option<LockedResource<R>> = None;

      if(match(deferredEncodeManager) {
        case Some(x) => true
        case _ => false
      }) {
        AppLog.error("deferredEncodeManager true")
      } else {
        AppLog.error("deferredEncodeManager false")
      }

      if (match(deferredEncodeManager) {
        case Some(x) => true
        case _ => false
      } && deferredEncodeManager.getOrThrow().hasResourceToEncode()) {
        lockedResource = Some(LockedResource.obtain(resource));
        result = lockedResource.getOrThrow();
      }

      notifyComplete(result, dataSource, isLoadedFromAlternateCacheKey);

      runStage = RunStage.ENCODE;
      try {
        if (match(deferredEncodeManager) {
          case Some(x) => true
          case _ => false
        } && deferredEncodeManager.getOrThrow().hasResourceToEncode()) {
          AppLog.error("deferredEncodeManager encoder begin")
          deferredEncodeManager.getOrThrow().encode(diskCacheProvider, options);
        }
      } finally {
        if (match(lockedResource) {
          case Some(x) => true
          case _ => false
        }) {
          lockedResource.getOrThrow().unlock();
        }
      }

      // Call onEncodeComplete outside the finally block so that it's not called if the encode
      // process
      // throws.
      onEncodeComplete();
    } finally {
      // GlideTrace.endSection();
    }
  }

  private func onEncodeComplete(): Unit {
    if (releaseManager.onEncodeComplete()) {
      releaseInternal();
    }
  }

  private func releaseInternal(): Unit {
    releaseManager.reset();
    if(match(deferredEncodeManager) {
      case Some(x) => true
      case _ => false
    }) {
      deferredEncodeManager.getOrThrow().clear()
    }

    decodeHelper.clear();
    isCallbackNotified = false;

    // TODO  回收glideContext
    // glideContext = null;
    // TODO  回收signature
    // signature = null;
    // TODO  回收options
    // options = null;

    // 没有优先级
    // priority = null;

    // TODO  回收loadKey
    // loadKey = null;

    // TODO  回收callback
    // callback = null;

    // TODO  回收runStage
    // runStage = null;

    currentGenerator = None;
    // currentThread = null;

    currentSourceKey = None;
    currentData = None;
    currentDataSource = None;

    // currentFetcher = null;
    // startFetchTime = 0L;
    isCancelled = false;

    // TODO  回收model
    // model = null;
    
    // throwables.clear();
    // pool.release(this);
  }

  private func notifyComplete<R>(
      resource: GlideResource<R>, 
      dataSource: DataSource, 
      isLoadedFromAlternateCacheKey: Bool): Unit {
    setNotifiedOrThrow();
    callback.onResourceReady(resource, dataSource, isLoadedFromAlternateCacheKey);
  }

  private func notifyFailed(): Unit {
    setNotifiedOrThrow();
    // GlideException e = new GlideException("Failed to load resource", new ArrayList<>(throwables));
    callback.onLoadFailed(GlideException("Failed to load resource"));
    onLoadFailed();
  }

  private func onLoadFailed(): Unit {
    if (releaseManager.onFailed()) {
      releaseInternal();
    }
  }

  private func setNotifiedOrThrow(): Unit {
    stateVerifier.throwIfRecycled();
    // if (isCallbackNotified) {
    //   Throwable lastThrown = throwables.isEmpty() ? null : throwables.get(throwables.size() - 1);
    //   throw new IllegalStateException("Already notified", lastThrown);
    // }
    isCallbackNotified = true;
  }

    private func decodeFromDataSub<DATA>(dataSource:DataSource,arrData:Array<UInt8>):Option<DATA>{
                var result = Option<DATA>.None
                  if(match(dataSource) {
                    case RESOURCE_DISK_CACHE => true
                    case _ => false
                  }) {
                    AppLog.error("getDrawableResourceParser RESOURCE_DISK_CACHE")
                    let parser: ResourceDecoder<Array<UInt8>, Drawable> = decodeHelper.getDrawableResourceParser()
                    let d: Drawable = parser.decode(arrData, this.width, this.height, decodeHelper.getOptions())

                    AppLog.error("drawable type: ${d.getType()}  ${d is GifDrawable} ${d is PixelMapDrawable}")

                    if(d is GifDrawable) {
                      let dd: GifDrawable = (d as GifDrawable).getOrThrow()
                      result = dd as DATA
                    } else if(d is PixelMapDrawable) {
                      let dd: PixelMapDrawable = (d as PixelMapDrawable).getOrThrow()
                      let res: GlideResource<PixelMapDrawable> = onResourceDecoded<PixelMapDrawable>(dataSource, PixelMapDrawableResource.obtain(dd))

                      result = res.get() as DATA
                    } else {
                      throw GlideException("Drawable type error")
                    }

                  } else {
                    let decoders: ArrayList<ResourceDecoder<Array<UInt8>, Drawable>> = decodeHelper.getDrawableResourceDecoders()

                    var i: Int64 = decoders.size - 1
                    while(i >= 0) {
                      let r: ResourceDecoder<Array<UInt8>, Drawable> = decoders[i]
                      AppLog.error("handles begin")
                      if(r.handles(arrData, decodeHelper.getOptions())) {
                        let d: Drawable = r.decode(arrData, this.width, this.height, decodeHelper.getOptions())
                        AppLog.error("drawable type: ${d.getType()}  ${d is GifDrawable} ${d is PixelMapDrawable}")

                        if(d is GifDrawable) {
                          let dd: GifDrawable = (d as GifDrawable).getOrThrow()
                          result = dd as DATA
                        } else if(d is PixelMapDrawable) {
                          let dd: PixelMapDrawable = (d as PixelMapDrawable).getOrThrow()
                          let res: GlideResource<PixelMapDrawable> = onResourceDecoded<PixelMapDrawable>(dataSource, PixelMapDrawableResource.obtain(dd))

                          result = res.get() as DATA
                        } else {
                          throw GlideException("Drawable type error")
                        }

                        break
                      }
                      i--
                    }
                  }
        return result
    }


    private func  decodeFromDataSubTwo<DATA>(dataSource:DataSource,d:Any):Option<DATA>{
          var result = Option<DATA>.None

         let decoder: GifDecoder = (d as GifDecoder).getOrThrow()
                let gifFrameResourceDecoder: GifFrameResourceDecoder = GifFrameResourceDecoder()
                let decodeResource: PixelMap = gifFrameResourceDecoder.decode(decoder)
                let res: GlideResource<PixelMap> = onResourceDecoded<PixelMap>(dataSource, PixelMapResource.obtain(decodeResource))

                // TODO transcode
                let bas: ByteArrayStream = ByteArrayStream()
                // let data: Array<UInt8> = Utils.arrU32ToU8(res.get().arr)
                //适配
                //疑问
                //let (ii, data) = decodeResource.readPixelsToBuffer(UInt64(decodeResource.getPixelBytesNumber()))
                let data: Array<UInt8> = Array<UInt8>(Int64(decodeResource.getPixelBytesNumber()), item:0)
                decodeResource.readPixelsToBuffer(data)
                bas.write(data)
                // let r = InputStreamResource.obtain(bas)

                result = bas as DATA;
                return result
    }


     var isByteArrayStream:Bool = false

    private func decodeFromData<DATA>(data: Option<DATA>, dataSource: DataSource): Option<DATA> {
    try {
      if (match(data) {
        case Some(x) => false
        case _ => true
      }) {
        return None;
      }
      // long startTime = LogTime.getLogTime();
      // var result: Resource<InputStream> = decodeFromFetcher(data, dataSource);
      var result: Option<DATA> = None

      let d: Any = data.getOrThrow()

      if(d is InputStream) {
        let inputStream: InputStream = (d as InputStream).getOrThrow()
         isByteArrayStream = d is ByteArrayStream
        // asFile downloadOnly
        if(this.transformationKey.tType == TransformationKey.TRANSFORMATION_INPUTSTREAM) {
          return (inputStream as DATA)
        }

        //适配
        //var arrData: Array<UInt8> = Array<UInt8>(inputStream.length, item: 0)
        var size = match(inputStream as Seekable){
            case Some(v) =>
                v.length
            case None =>
                0
        }
        //var arrData: Array<UInt8> = Array<UInt8>(size, item: 0)

        //inputStream.read(arrData)
        var arrData:Option<Array<UInt8>> = Option<Array<UInt8>>.None
        if(isByteArrayStream){
            arrData = Array<UInt8>(size,item:0)
            inputStream.read(arrData.getOrThrow())
        }else{
            var arrDataTemp:Array<UInt8> = Array<UInt8>(2048,item:0)
            let listbuf:ArrayList<UInt8> = ArrayList<UInt8>()
            var read:Int64 = 0
            do{
                read = inputStream.read(arrDataTemp)
                listbuf.appendAll(arrDataTemp[0..read])
            }while(read > 0)
            arrData = listbuf.toArray()
        }

        // TODO 改为判断图片格式 区分gif和静态图片 保存图片格式到drawable

        // 解码器列表，进行图片解码
        if(this.transformationKey.tType == TransformationKey.TRANSFORMATION_DRAWABLE) {
                result = decodeFromDataSub(dataSource,arrData.getOrThrow())

        } else if(this.transformationKey.tType == TransformationKey.TRANSFORMATION_PIXELMAP) {
          let decoders: ArrayList<ResourceDecoder<Array<UInt8>, PixelMap>> = decodeHelper.getPixelMapResourceDecoders()
          
          var i: Int64 = decoders.size - 1
          while(i >= 0) {
            let r: ResourceDecoder<Array<UInt8>, PixelMap> = decoders[i]
            if(r.handles(arrData.getOrThrow(), decodeHelper.getOptions())) {
              let d: PixelMap = r.decode(arrData.getOrThrow(), this.width, this.height, decodeHelper.getOptions())
              let res: GlideResource<PixelMap> = onResourceDecoded<PixelMap>(dataSource, PixelMapResource.obtain(d))
              result = res.get() as DATA
              break
            }
            i--
          }

        } else {
          throw GlideException("error transformation type")
        }
        
        // old
        // let decodeResource: Option<GlideResource<PixelMapDrawable>> = decodeHelper.decodeImage(arrData, this.width, this.height)
        
        // if(match(decodeResource) {
        //   case Some(x) => true
        //   case _ => false
        // }) {
        //   AppLog.error("decodeResource isnot null")
        //   // PixelMap
        //   let res: GlideResource<PixelMapDrawable> = onResourceDecoded<PixelMapDrawable>(dataSource, decodeResource.getOrThrow())
        

        //   if(this.transformationKey.tType == TransformationKey.TRANSFORMATION_DRAWABLE) {
        //     return res.get() as DATA
        //   } else {
        //     throw GlideException("error transformation type")
        //   }

        //   // if(this.transformationKey.tType == TransformationKey.TRANSFORMATION_PIXELMAP) {
        //   //   return res.get() as DATA
        //   // }

        //   // AppLog.error("this.transformationKey.tType : ${this.transformationKey.tType}")
        //   // TODO transcode 需不需要？
        //   // let bas: ByteArrayStream = ByteArrayStream()
        //   // let data: Array<UInt8> = Utils.arrU32ToU8(res.get().getPixelMap().arr)
        //   // bas.write(data)
        //   // // let r = InputStreamResource.obtain(bas)

        //   // result = bas as DATA;
          
        // } else {
        //   AppLog.error("decodeResource is null")
        //   // GIF
        //   let decodeResourceGIF: Option<GifDrawable> = decodeHelper.decodeImageGIF(arrData, this.width, this.height)
        //   if(match(decodeResourceGIF) {
        //     case Some(x) => true
        //     case _ => false
        //   }) {
        //     let g: GifDrawable = decodeResourceGIF.getOrThrow()
        //     result = g as DATA
        //   }
        // }

      } else if(d is GifDecoder) {
        // TODO 待用
        result = decodeFromDataSubTwo(dataSource,d)
      } else {
        return None
      }
      
      // if (Log.isLoggable(TAG, Log.VERBOSE)) {
      //   logWithTimeAndKey("Decoded result " + result, startTime);
      // }
      return result;
    } finally {
      // fetcher.cleanup();
    }
  }

  private func runGenerators(): Unit {
    // currentThread = Thread.currentThread();
    // startFetchTime = LogTime.getLogTime();
    var isStarted: Bool = false;
    while (!isCancelled && 
        match(currentGenerator){
          case Some(x) => true
          case _ => false
        }) {
          isStarted = currentGenerator.getOrThrow().startNext()
          if(isStarted) {
            break;
          }
      runStage = getNextStage(runStage);
      currentGenerator = getNextGenerator();

      if (match(runStage) {
        case RunStage.SOURCE => true
        case _ => false
      }) {
        reschedule(RunReason.SWITCH_TO_SOURCE_SERVICE);
        return;
      }
    }
    // We've run out of stages and generators, give up.
    if ((match(runStage) {
        case RunStage.FINISHED => true
        case _ => false
      } || isCancelled) && !isStarted) {
      notifyFailed();
    }

    // Otherwise a generator started a new load and we expect to be called back in
    // onDataFetcherReady.
  }

  public func onDataFetcherReady(
        sourceKey: AnyKey,
        data: Option<Any>,
        dataSource: DataSource
        ): Unit {
          AppLog.error("decodejob  onDataFetcherReady")
          this.currentData = data
          this.currentDataSource = Some(dataSource)
          this.currentSourceKey = Some(sourceKey)
          reschedule(RunReason.DECODE_DATA);
        }
        
  public func onDataFetcherFailed(

        ): Unit {
    runGenerators()
  }

  private func reschedule(runReason: RunReason): Unit {
    this.runReason = runReason;
    callback.reschedule(this);
  }

  public func reschedule(): Unit {
    reschedule(RunReason.SWITCH_TO_SOURCE_SERVICE);
  }

  private func getNextGenerator(): Option<DataFetcherGenerator> {
    match(runStage) {
      case RESOURCE_CACHE =>
        return Some(ResourceCacheGenerator(decodeHelper, this));
      case DATA_CACHE =>
        return Some(DataCacheGenerator(decodeHelper, this));
      case SOURCE =>
        return Some(SourceGenerator(decodeHelper, this));
      case FINISHED =>
        AppLog.error("getNextGenerator FINISHED")
        return None;
      case _ =>
        throw GlideException("Unrecognized stage: ");
    }
  }

  private func getNextStage(current: RunStage): RunStage {
    match(current) {
      case RunStage.INITIALIZE =>
        return if(diskCacheStrategy.decodeCachedResource()) {
          RunStage.RESOURCE_CACHE
        } else {
          getNextStage(RunStage.RESOURCE_CACHE)
        }
      case RunStage.RESOURCE_CACHE => 
        return if(diskCacheStrategy.decodeCachedData()) {
          RunStage.DATA_CACHE
        } else {
          getNextStage(RunStage.DATA_CACHE)
        }
      case RunStage.DATA_CACHE =>
              // Skip loading from source if the user opted to only retrieve the resource from cache.
        return if(onlyRetrieveFromCache) {
          RunStage.FINISHED
        } else {
          RunStage.SOURCE
        }

      case RunStage.SOURCE | RunStage.FINISHED =>
        return RunStage.FINISHED;

      case _ => 
        throw GlideException("Unrecognized stage: ")
    }
  }

  public func onResourceDecoded<Z>(dataSource: DataSource, decoded: GlideResource<Z>): GlideResource<Z> {
    // Class<Z> resourceSubClass = (Class<Z>) decoded.get().getClass();
    AppLog.error("onResourceDecoded begin")
    let transformationKey: TransformationKey = decodeHelper.getTransformationKey()
    //var appliedTransformation: Option<AnyTransformation> = None;
      let appliedTransformation : Option<AnyTransformation> = decodeHelper.getTransformation(transformationKey)
    var transformed: GlideResource<Z> = decoded;
    if (match(dataSource) {
      case DataSource.RESOURCE_DISK_CACHE => false
      case _ => true
    }) {
      //appliedTransformation = decodeHelper.getTransformation(transformationKey);
      if(match(appliedTransformation) {
        case Some(x) => true
        case _ => false
      }) {
        AppLog.error("transformation : ")
            synchronized(mtxtrans){
                transformed = (appliedTransformation.getOrThrow().transform(decoded, width, height) as GlideResource<Z>).getOrThrow();
            }
      }
      
    }
    // TODO: Make this the responsibility of the Transformation.
    // if (decoded != transformed) {
    //   decoded.recycle();
    // }

    var encodeStrategy: EncodeStrategy = EncodeStrategy.NONE;
    var encoder: Option<AnyResourceEncoder> = None;
    if (decodeHelper.isResourceEncoderAvailable(transformed)) {
      // encoder = decodeHelper.getResultEncoder(transformed);
      AppLog.error("encoder : PixelMapEncoder")
      if(transformed is GlideResource<PixelMapDrawable>) {
        encoder = Some(PixelMapDrawableEncoder())
        encodeStrategy = encoder.getOrThrow().getEncodeStrategy(options);
      } else if(transformed is GlideResource<PixelMap>) {
        encoder = Some(PixelMapEncoder())
        encodeStrategy = encoder.getOrThrow().getEncodeStrategy(options);
      } else {
        throw GlideException("resource type error")
      }
    }

    var result: GlideResource<Z> = transformed;
    let isFromAlternateCacheKey: Bool = true

    AppLog.error("diskCacheStrategy.isResourceCacheable : ${diskCacheStrategy} ${isFromAlternateCacheKey} ${dataSource} ${encodeStrategy}")
    let isCacheable = diskCacheStrategy.isResourceCacheable(
                                     isFromAlternateCacheKey, 
                                     dataSource, 
                                     encodeStrategy)
    AppLog.error("diskCacheStrategy isCacheable: ${isCacheable}")
    if (isCacheable) {
      if (match(encodeStrategy) {
        case NONE => true
        case _ => false
      }) {
        throw GlideException("encodeStrategy is null")
      }
      
      let key: AnyKey;
      match(encodeStrategy) {
        case SOURCE => 
          key = DataCacheKey(currentSourceKey.getOrThrow(), signature);

        case TRANSFORMED => 
          key = ResourceCacheKey(
                  decodeHelper.getArrayPool(),
                  currentSourceKey.getOrThrow(),
                  signature,
                  width,
                  height,
                  appliedTransformation.getOrThrow(),
                  // resourceSubClass,
                  transformationKey,
                  options);
          AppLog.error("ResourceCacheKey : ${key}")

        case _ =>
          throw GlideException("Unknown strategy: ");
      }

      let lockedResult: LockedResource<Z> = LockedResource.obtain(transformed);

      // AppLog.error("deferredEncodeManager DeferredEncodeManager init")
      if(match(encoder) {
        case Some(x) => false
        case _ => true
      }) {
        throw Exception("encoder is null")
      }
      deferredEncodeManager = Some(DeferredEncodeManager<Z>(key, (encoder.getOrThrow() as ResourceEncoder<Z>).getOrThrow(), lockedResult))
      result = lockedResult;
    }

    return result;
  }
}

public class ReleaseManager {
  private var isReleased: Bool = false
  private var isEncodeComplete: Bool = false
  private var isFailed: Bool = false
  private let mtx = ReentrantMutex()

  public func release(isRemovedFromQueue: Bool): Bool {
    synchronized(mtx) {
      isReleased = true;
      return isComplete(isRemovedFromQueue);
    }
  }

  public func onEncodeComplete(): Bool {
    synchronized(mtx) {
      isEncodeComplete = true;
      return isComplete(false /*isRemovedFromQueue*/);
    }
  }

  public func onFailed(): Bool {
    synchronized(mtx) {
      isFailed = true;
      return isComplete(false /*isRemovedFromQueue*/);
    }
  }

  public func reset(): Unit {
    synchronized(mtx) {
      isEncodeComplete = false;
      isReleased = false;
      isFailed = false;
    }
  }

  private func isComplete(isRemovedFromQueue: Bool): Bool {
    return (isFailed || isRemovedFromQueue || isEncodeComplete) && isReleased;
  }

}

public interface DecodeJobCallback {
    func onResourceReady(resource: AnyGlideResource, 
                          dataSource: DataSource, 
                          isLoadedFromAlternateCacheKey: Bool): Unit;

    func onLoadFailed(e: GlideException): Unit;

    func reschedule(job: DecodeJob): Unit;
}

// static class DecodeJobFactory {
//   public let diskCacheProvider: DiskCacheProvider;

//   final Pools.Pool<DecodeJob<?>> pool =
//       FactoryPools.threadSafe(
//           JOB_POOL_SIZE,
//           new FactoryPools.Factory<DecodeJob<?>>() {
//             @Override
//             public DecodeJob<?> create() {
//               return new DecodeJob<>(diskCacheProvider, pool);
//             }
//           });

//   private int creationOrder;

//   DecodeJobFactory(DecodeJob.DiskCacheProvider diskCacheProvider) {
//     this.diskCacheProvider = diskCacheProvider;
//   }

//   @SuppressWarnings("unchecked")
//   <R> DecodeJob<R> build(
//       GlideContext glideContext,
//       Object model,
//       EngineKey loadKey,
//       Key signature,
//       int width,
//       int height,
//       Class<?> resourceClass,
//       Class<R> transcodeClass,
//       Priority priority,
//       DiskCacheStrategy diskCacheStrategy,
//       Map<Class<?>, Transformation<?>> transformations,
//       boolean isTransformationRequired,
//       boolean isScaleOnlyOrNoTransform,
//       boolean onlyRetrieveFromCache,
//       Options options,
//       DecodeJob.Callback<R> callback) {
//     DecodeJob<R> result = Preconditions.checkNotNull((DecodeJob<R>) pool.acquire());
//     return result.init(
//         glideContext,
//         model,
//         loadKey,
//         signature,
//         width,
//         height,
//         resourceClass,
//         transcodeClass,
//         priority,
//         diskCacheStrategy,
//         transformations,
//         isTransformationRequired,
//         isScaleOnlyOrNoTransform,
//         onlyRetrieveFromCache,
//         options,
//         callback,
//         creationOrder++);
//   }
// }

public interface DiskCacheProvider {
  func getDiskCache(): DiskCache;
}

public class LazyDiskCacheProvider <: DiskCacheProvider {
    private let factory: DiskCacheFactory;
    private var diskCache: Option<DiskCache> = None;
    private let mtx = ReentrantMutex()

    public init(factory: DiskCacheFactory) {
      this.factory = factory;
    }

    public func clearDiskCacheIfCreated(): Unit {
      synchronized(mtx) {
        if (match(diskCache) {
          case Some(x) => false
          case _ => true
        }) {
          return;
        }
        diskCache.getOrThrow().clear();
      }
    }

    public func getDiskCache(): DiskCache {
      if (match(diskCache) {
          case Some(x) => false
          case _ => true
        }) {
          synchronized (mtx) {
            if (match(diskCache) {
            case Some(x) => false
            case _ => true
          }) {
              diskCache = Some(factory.build());
            }
            if (match(diskCache) {
            case Some(x) => false
            case _ => true
          }) {
              // diskCache = Some(DiskCacheAdapter());
              throw Exception("glide LazyDiskCacheProvider error")
            }
          }
        }
      return diskCache.getOrThrow();
    }
}

public class LoadStatus {
  private let cb: ResourceCallback;
  private let mtx: ReentrantMutex;
  private let engineJob: EngineJob;

  private var futures: Option<ArrayList<Future<Option<InputStream>>>> = None;

  public init(cb: ResourceCallback, mtx: ReentrantMutex, engineJob: EngineJob) {
    this.cb = cb;
    this.mtx = mtx;
    this.engineJob = engineJob;
  }

  // public func getFuture(): Future<Option<InputStream>> {
  //   return this.engineJob.mainFuture.getOrThrow()
  // }

  // 取消解码 取消回调
  public func cancel(): Unit {
    AppLog.error("LoadStatus cancel")
    // Acquire the Engine lock so that a new request can't get access to a particular EngineJob
    // just after the EngineJob has been cancelled. Without this lock, we'd allow new requests
    // to find the cancelling EngineJob in our Jobs data structure. With this lock, the EngineJob
    // is both cancelled and removed from Jobs atomically.
    synchronized (mtx) {
      engineJob.removeCallback(this.cb);
    }
  }
}

public interface AnyDeferredEncodeManager {
  func encode(diskCacheProvider: DiskCacheProvider, options: GlideOptions): Unit
  func hasResourceToEncode(): Bool
  func clear(): Unit
}

public class DeferredEncodeManager<Z> <: AnyDeferredEncodeManager {
  private var key: Option<AnyKey> = None
  private var encoder: Option<ResourceEncoder<Z>> = None
  private var toEncode: Option<LockedResource<Z>> = None

  public init(key: AnyKey, encoder: ResourceEncoder<Z>, toEncode: LockedResource<Z>) {
    this.key = Some(key);
    this.encoder = Some(encoder);
    this.toEncode = Some(toEncode);
  }

  // We just need the encoder and resource type to match, which this will enforce.
  // public func initDeferredEncodeManager(key: AnyKey, encoder: ResourceEncoder<Z>, toEncode: LockedResource<Z>): Unit {
  //   this.key = Some(key);
  //   this.encoder = Some(encoder);
  //   this.toEncode = Some(toEncode);
  // }

  public func encode(diskCacheProvider: DiskCacheProvider, options: GlideOptions): Unit {
    // GlideTrace.beginSection("DecodeJob.encode");
    AppLog.error("encode begin")
    try {
      diskCacheProvider
          .getDiskCache()
          .put(key.getOrThrow(), 
              DataCacheWriter<GlideResource<Z>>(encoder.getOrThrow(), 
                                  toEncode.getOrThrow(), 
                                  options)
              );
    } finally {
      toEncode.getOrThrow().unlock();
      // GlideTrace.endSection();
    }
  }

  public func hasResourceToEncode(): Bool {
    return match(toEncode) {
      case Some(x) => true
      case _ => false
    }
  }

  public func clear(): Unit {
    key = None;
    encoder = None;
    toEncode = None;
  }
}

// public interface DecodeCallback<ResourceType> {
//   func onResourceDecoded(resource: GlideResource<ResourceType>): GlideResource<ResourceType>;
// }

// private final class DecodeCallback<Z> implements DecodePath.DecodeCallback<Z> {

//     private final DataSource dataSource;

//     @Synthetic
//     DecodeCallback(DataSource dataSource) {
//       this.dataSource = dataSource;
//     }

//     @NonNull
//     @Override
//     public Resource<Z> onResourceDecoded(@NonNull Resource<Z> decoded) {
//       return DecodeJob.this.onResourceDecoded(dataSource, decoded);
//     }
//   }
