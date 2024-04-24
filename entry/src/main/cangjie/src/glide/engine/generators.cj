package glide.engine

from net import http.*
from net import tls.*

public class SourceGenerator <: DataFetcherGenerator & FetcherReadyCallback {
//   private static final String TAG = "SourceGenerator";

  private let helper: DecodeHelper;
  private let cb: FetcherReadyCallback;

    // volatile
  private var loadDataListIndex: Int64 = -1;
  // volatile
  private var sourceCacheGenerator: Option<DataCacheGenerator> = None;
  //volatile
  private var dataToCache: Option<Any> = None;
   //volatile
//   private volatile ModelLoader.LoadData<?> loadData;
   //volatile
  private var originalKey: Option<DataCacheKey> = None;

  public init(helper: DecodeHelper, cb: FetcherReadyCallback) {
    this.helper = helper;
    this.cb = cb;
  }

  // Concurrent access isn't supported.
  public func startNext(): Bool {
    // AppLog.error("SourceGenerator  startNext")
    if (match(dataToCache) {
      case Some(x) => true
      case _ => false
    }) {
      // AppLog.error("SourceGenerator  cacheData")
      let data: Any = dataToCache.getOrThrow();
      dataToCache = None;
      try {
        AppLog.error("SourceGenerator cacheData begin")
        let isDataInCache: Bool = cacheData(data);
        // If we failed to write the data to cache, the cacheData method will try to decode the
        // original data directly instead of going through the disk cache. Since cacheData has
        // already called our callback at this point, there's nothing more to do but return.
        if (!isDataInCache) {
          return true;
        }
        // If we were able to write the data to cache successfully, we now need to proceed to call
        // the sourceCacheGenerator below to load the data from cache.
      } catch (e: Exception) {
        // An IOException means we weren't able to write data to cache or we weren't able to rewind
        // it after a disk cache write failed. In either case we can just move on and try the next
        // fetch below.
        // if (Log.isLoggable(TAG, Log.DEBUG)) {
        //   Log.d(TAG, "Failed to properly rewind or write data to cache", e);
        // }
      }
    }

    if (match(sourceCacheGenerator) {
      case Some(x) => true
      case _ => false
      } && sourceCacheGenerator.getOrThrow().startNext()) {
        // AppLog.error("SourceGenerator  sourceCacheGenerator.getOrThrow().startNext()")
      return true;
    }

    sourceCacheGenerator = None;

    // loadData = null;
    // boolean started = false;
    // while (!started && hasNextModelLoader()) {
    //   loadData = helper.getLoadData().get(loadDataListIndex++);
    //   if (loadData != null
    //       && (helper.getDiskCacheStrategy().isDataCacheable(loadData.fetcher.getDataSource())
    //           || helper.hasLoadPath(loadData.fetcher.getDataClass()))) {
    //     started = true;
    //     startNextLoad(loadData);
    //   }
    // }
    // 加载数据

    AppLog.error("SourceGenerator  加载数据")

    

    let model: Model = helper.getModel()

    let modelLoaders: Option<ArrayList<ModelLoader>> = helper.getModelLoaders()

    if(match(modelLoaders) {
      case Some(x) => false
      case _ => true
    }) {
      return true
    }

    let modelLoader: ModelLoader = modelLoaders.getOrThrow()[0]

    let o: Option<InputStream> = match(model.modelType) {
      // case ModelType.ARRAY => None //modelLoader.loadModel(model.arr)
      case ModelType.STRING => modelLoader.loadModel(model.str, this.helper.getOptions())
      case ModelType.FILE => modelLoader.loadModel(model.file.getFileNoSeek(), this.helper.getOptions())
      case ModelType.GIFDECODER => None
      case _ => None
    }

    AppLog.error("hhs gilde biaoji")
    var size = match(o.getOrThrow() as Seekable){
        case Some(v) =>
            AppLog.error("hhs gilde biaoji aaa")
            v.remainLength
        case None =>
            AppLog.error("hhs gilde biaoji bbbb")
            0
    }
    AppLog.error("gilde hhs size1212121=${size}")

    if(match(o) {
      case Some(x) => true
      case _ => false
    }) {
      // AppLog.error("onResourceReady ca")

      let transformationKey = helper.getTransformationKey()
      // decodeType(TransformationKey)
      if(transformationKey.tType == TransformationKey.TRANSFORMATION_INPUTSTREAM) {
        // AppLog.error("onDataReadyInternal:  TRANSFORMATION_INPUTSTREAM")

      } else if(transformationKey.tType == TransformationKey.TRANSFORMATION_PIXELMAP) {
        // AppLog.error("onDataReadyInternal:  TRANSFORMATION_PIXELMAP")
        
        // cb.onResourceReady(Some(PixelMapResource.obtain(PixelMap(buf))), DataSource.REMOTE, false)
      }

      let oo = o.getOrThrow()
      // let buf: Array<UInt8> = Array<UInt8>(oo.length, item: 0)
      // oo.read(buf)

      onDataReadyInternal(oo, helper.getDataSource(), ModelKey(model));

      return true
    } else {
      // AppLog.error("onLoadFailed ca")
      // cb.onLoadFailed(GlideException("image load failed"))
      onDataFetcherFailed(
        ModelKey(helper.getModel()), 
        GlideException("image load failed"),
        helper.getDataSource())
      return true
    }

    

    return true;
  }

  public func onDataReadyInternal(data: Option<Any>, dataSource: DataSource, sourceKey: Option<AnyKey>): Unit {
    let diskCacheStrategy: DiskCacheStrategy = helper.getDiskCacheStrategy();
    AppLog.error("onDataReadyInternal: ${dataSource} --- ${diskCacheStrategy} : ${diskCacheStrategy.isDataCacheable(dataSource)}")
    if (match(data) {
        case Some(x) => true
        case _ => false
      } && diskCacheStrategy.isDataCacheable(dataSource)) {
      dataToCache = data;
      // We might be being called back on someone else's thread. Before doing anything, we should
      // reschedule to get back onto Glide's thread. Then once we're back on Glide's thread, we'll
      // get called again and we can write the retrieved data to cache.
      cb.reschedule();
    } else {
      if(match(originalKey) {
        case Some(x) => true
        case _ => false
      }) {
         cb.onDataFetcherReady(
          sourceKey.getOrThrow(),
          data,
          dataSource,
          originalKey.getOrThrow() as AnyKey);
      } else {
        cb.onDataFetcherReady(
          sourceKey.getOrThrow(),
          data,
          dataSource,
          Option<AnyKey>.None);
      }
     
    }
  }

  /**
   * Returns {@code true} if we were able to cache the data and should try to decode the data
   * directly from cache and {@code false} if we were unable to cache the data and should make an
   * attempt to decode from source.
   */
  private func cacheData(dataToCache: Option<Any>): Bool {
    AppLog.error("cacheData begin")
    // long startTime = LogTime.getLogTime();
    // var isLoadingFromSourceData: Bool = false;
    // try {
    //   DataRewinder<Object> rewinder = helper.getRewinder(dataToCache);
    //   Object data = rewinder.rewindAndGet();
    //   Encoder<Object> encoder = helper.getSourceEncoder(data);
    let data: Any = dataToCache.getOrThrow()
    // let encoder: Option<Encoder> = helper.getSourceEncoder<InputStream>(data)
    if(data is InputStream) {
      AppLog.error("data is InputStream")
      let encoder: Encoder<InputStream> = InputStreamEncoder(helper.getArrayPool())
      let d: InputStream = (data as InputStream).getOrThrow()
      //AppLog.error("d length: ${d.length}")
      // var buffer: Array<UInt8> = Array<UInt8>(d.length, item: 0)
      // d.read(buffer)
      
      
      let writer: DataCacheWriter<InputStream> = DataCacheWriter<InputStream>(encoder, d, helper.getOptions());
      let newOriginalKey: DataCacheKey = DataCacheKey(ModelKey(helper.getModel()), helper.getSignature());
      let diskCache: DiskCache = helper.getDiskCache();
      AppLog.error("data put begin")
      diskCache.put(newOriginalKey, writer);

      //   if (Log.isLoggable(TAG, Log.VERBOSE)) {
    //     Log.v(
    //         TAG,
    //         "Finished encoding source to cache"
    //             + ", key: "
    //             + newOriginalKey
    //             + ", data: "
    //             + dataToCache
    //             + ", encoder: "
    //             + encoder
    //             + ", duration: "
    //             + LogTime.getElapsedMillis(startTime));
    //   }

      let cache: Option<GlideFile> = diskCache.get(newOriginalKey)
      if (match(cache) {
        case Some(x) => true
        case _ => false
      }) {
        originalKey = Some(newOriginalKey);
        sourceCacheGenerator = Some(DataCacheGenerator(helper, this));
        // We were able to write the data to cache.
        return true;
      } else {
        // if (Log.isLoggable(TAG, Log.DEBUG)) {
        //   Log.d(
        //       TAG,
        //       "Attempt to write: "
        //           + originalKey
        //           + ", data: "
        //           + dataToCache
        //           + " to the disk"
        //           + " cache failed, maybe the disk cache is disabled?"
        //           + " Trying to decode the data directly...");
        // AppLog.error("Attempt to write:  cache failed, maybe the disk cache is disabled?")

        // isLoadingFromSourceData = true;
        cb.onDataFetcherReady(
            ModelKey(helper.getModel()),
            data,
            helper.getDataSource(),
            Some(ModelKey(helper.getModel())));
      }

    }
    
      // We failed to write the data to cache.
      return false;
    // } finally {
    //   if (!isLoadingFromSourceData) {
    //     loadData.fetcher.cleanup();
    //   }
    // }
  }

  public func cancel(): Unit {
    // LoadData<?> local = loadData;
    // if (local != null) {
    //   local.fetcher.cancel();
    // }
  }

  // public func onDataReadyInternal(LoadData<?> loadData, Object data) {
  //   DiskCacheStrategy diskCacheStrategy = helper.getDiskCacheStrategy();
  //   if (data != null && diskCacheStrategy.isDataCacheable(loadData.fetcher.getDataSource())) {
  //     dataToCache = data;
  //     // We might be being called back on someone else's thread. Before doing anything, we should
  //     // reschedule to get back onto Glide's thread. Then once we're back on Glide's thread, we'll
  //     // get called again and we can write the retrieved data to cache.
  //     cb.reschedule();
  //   } else {
  //     cb.onDataFetcherReady(
  //         loadData.sourceKey,
  //         data,
  //         loadData.fetcher,
  //         loadData.fetcher.getDataSource(),
  //         originalKey);
  //   }
  // }

  // void onLoadFailedInternal(LoadData<?> loadData, @NonNull Exception e) {
  //   cb.onDataFetcherFailed(originalKey, e, loadData.fetcher, loadData.fetcher.getDataSource());
  // }

  public func reschedule(): Unit {
    // We don't expect this to happen, although if we ever need it to we can delegate to our
    // callback.
    throw GlideException("SourceGenerator cannot reschedule !!!");
  }

  // Called from source cache generator.
  public func onDataFetcherReady(
      sourceKey: AnyKey, data: Option<Any>, dataSource: DataSource, attemptedKey: Option<AnyKey>): Unit {
    // This data fetcher will be loading from a File and provide the wrong data source, so override
    // with the data source of the original fetcher
    // cb.onDataFetcherReady(sourceKey, data, fetcher, loadData.fetcher.getDataSource(), sourceKey);
    cb.onDataFetcherReady(sourceKey, data, dataSource, Some(sourceKey));
  }

  public func onDataFetcherFailed(
      sourceKey: AnyKey, e: GlideException, dataSource: DataSource) {
    cb.onDataFetcherFailed(sourceKey, e, dataSource);
  }
}

public class ModelKey <: AnyKey {
  public var model: Model;

  public init(model: Model) {
    this.model = model;
  }

  public operator func ==(that: AnyKey): Bool {
      return equals(that)
  }

  public operator func !=(that: AnyKey): Bool {
      return !equals(that)
  }

  public func hashCode(): Int64 {
    return model.hashCode();
  }

  public func toString(): String {
    return """
    ModelKey{model=${model}""";
  }

  public func equals(o: AnyKey): Bool {
    if (o is ModelKey) {
      var other: ModelKey = (o as ModelKey).getOrThrow()
      AppLog.error("ModelKey equals ${model} == ${other.model}  -> ${model == other.model}")
      return model == other.model;
    }
    return false;
  }

  public func updateDiskCacheKey(md5: MD5): Unit {
    AppLog.error("ModelKey updateDiskCacheKey: ${model.toString()}")
    //适配
    //md5.MD5Update(model.toString().toUtf8Array())
    md5.MD5Update(model.toString().toArray())
  }
}
