package glide.engine

public class DataCacheGenerator <: DataFetcherGenerator {

  // private let cacheKeys: ArrayList<AnyKey>;
  // private let cacheKey: Option<AnyKey> = None;
  private let helper: DecodeHelper;
  private let cb: FetcherReadyCallback;

  private var sourceIdIndex: Int64 = -1;
  // private var sourceKey: AnyKey;
  // private var modelLoaders: ArrayList<ModelLoader<File, ?>>;
  // private var modelLoaderIndex: Int64;

  // volatile
  // private var loadData: LoadData<?>;

  // PMD is wrong here, this File must be an instance variable because it may be used across
  // multiple calls to startNext.
  private var cacheFile: Option<GlideFile> = None;

  public init(helper: DecodeHelper, cb: FetcherReadyCallback) {
    // this(helper.getCacheKeys(), helper, cb);
    this.helper = helper;
    this.cb = cb;
  }

  // In some cases we may want to load a specific cache key (when loading from source written to
  // cache), so we accept a list of keys rather than just obtain the list from the helper.
  // public init(cacheKey: AnyKey, helper: DecodeHelper, cb: FetcherReadyCallback) {
  //   // this.cacheKeys = cacheKeys;
  //   this.cacheKey = Some(cacheKey)
  //   this.helper = helper;
  //   this.cb = cb;
  // }

  public func startNext(): Bool {
    
    // GlideTrace.beginSection("DataCacheGenerator.startNext");
    try {
      // while (modelLoaders == null || !hasNextModelLoader()) {
      //   sourceIdIndex++;
      //   if (sourceIdIndex >= cacheKeys.size()) {
      //     return false;
      //   }

      //   Key sourceId = cacheKeys.get(sourceIdIndex);
      //   // PMD.AvoidInstantiatingObjectsInLoops The loop iterates a limited number of times
      //   // and the actions it performs are much more expensive than a single allocation.
      //   @SuppressWarnings("PMD.AvoidInstantiatingObjectsInLoops")
      //   Key originalKey = new DataCacheKey(sourceId, helper.getSignature());
      //   cacheFile = helper.getDiskCache().get(originalKey);
      //   if (cacheFile != null) {
      //     this.sourceKey = sourceId;
      //     modelLoaders = helper.getModelLoaders(cacheFile);
      //     modelLoaderIndex = 0;
      //   }
      // }

      // loadData = null;
      // boolean started = false;
      // while (!started && hasNextModelLoader()) {
      //   ModelLoader<File, ?> modelLoader = modelLoaders.get(modelLoaderIndex++);
      //   loadData =
      //       modelLoader.buildLoadData(
      //           cacheFile, helper.getWidth(), helper.getHeight(), helper.getOptions());
      //   if (loadData != null && helper.hasLoadPath(loadData.fetcher.getDataClass())) {
      //     started = true;
      //     loadData.fetcher.loadData(helper.getPriority(), this);
      //   }
      // }
      // return started;

      // 从磁盘缓存获取图片
      let originalKey: AnyKey = DataCacheKey(ModelKey(helper.getModel()), helper.getSignature());
      AppLog.error("DataCacheGenerator startNext get  ${originalKey}")
      cacheFile = helper.getDiskCache().get(originalKey);

      if(match(cacheFile) {
        case Some(x) => true
        case _ => false
      }) {
        AppLog.error("DataCacheGenerator  startNext  true : ${cacheFile.getOrThrow().filePath.toString()}")

        let outStream: ByteArrayStream = cacheFile.getOrThrow().toByteArrayStream()

        cb.onDataFetcherReady(ModelKey(helper.getModel()), Some(outStream), DataSource.DATA_DISK_CACHE);

        return true
      }
      return false
    } finally {
    }
  }

  // private boolean hasNextModelLoader() {
  //   return modelLoaderIndex < modelLoaders.size();
  // }

  public func cancel(): Unit {
    // LoadData<?> local = loadData;
    // if (local != null) {
    //   local.fetcher.cancel();
    // }
  }


}
