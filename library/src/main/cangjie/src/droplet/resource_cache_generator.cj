/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public class ResourceCacheGenerator <: DataFetcherGenerator {

  private let cb: FetcherReadyCallback;
  private let helper: DecodeHelper;

//   private int sourceIdIndex;
//   private int resourceClassIndex = -1;
  private var sourceKey: Option<AnyKey> = None;
//   private List<ModelLoader<File, ?>> modelLoaders;
//   private int modelLoaderIndex;
//   private volatile LoadData<?> loadData;
//   private File cacheFile;
  private var cacheFile: Option<DropletFile> = None;

  private var currentKey: Option<ResourceCacheKey> = None;

  public init(helper: DecodeHelper, cb: FetcherReadyCallback) {
    this.helper = helper;
    this.cb = cb;
  }

  public func startNext(): Bool {
    // DropletTrace.beginSection("ResourceCacheGenerator.startNext");
    try {
    //   List<Key> sourceIds = helper.getCacheKeys();
    //   if (sourceIds.isEmpty()) {
    //     return false;
    //   }
    //   List<Class<?>> resourceClasses = helper.getRegisteredResourceClasses();
    //   if (resourceClasses.isEmpty()) {
    //     if (File.class.equals(helper.getTranscodeClass())) {
    //       return false;
    //     }
    //     throw new IllegalStateException(
    //         "Failed to find any load path from "
    //             + helper.getModelClass()
    //             + " to "
    //             + helper.getTranscodeClass());
    //   }
    //   while (modelLoaders == null || !hasNextModelLoader()) {
    //     resourceClassIndex++;
    //     if (resourceClassIndex >= resourceClasses.size()) {
    //       sourceIdIndex++;
    //       if (sourceIdIndex >= sourceIds.size()) {
    //         return false;
    //       }
    //       resourceClassIndex = 0;
    //     }

    //     // Key sourceId = sourceIds.get(sourceIdIndex);
    //     // Class<?> resourceClass = resourceClasses.get(resourceClassIndex);
    //     Transformation<?> transformation = helper.getTransformation(resourceClass);
    //     // PMD.AvoidInstantiatingObjectsInLoops Each iteration is comparatively expensive anyway,
    //     // we only run until the first one succeeds, the loop runs for only a limited
    //     // number of iterations on the order of 10-20 in the worst case.
    //     currentKey =
    //         new ResourceCacheKey( // NOPMD AvoidInstantiatingObjectsInLoops
    //             helper.getArrayPool(),
    //             sourceId,
    //             helper.getSignature(),
    //             helper.getWidth(),
    //             helper.getHeight(),
    //             transformation,
    //             resourceClass,
    //             helper.getOptions());
    //     cacheFile = helper.getDiskCache().get(currentKey);
    //     if (cacheFile != null) {
    //       sourceKey = sourceId;
    //       modelLoaders = helper.getModelLoaders(cacheFile);
    //       modelLoaderIndex = 0;
    //     }
    //   }

    //   loadData = null;
    //   boolean started = false;
    //   while (!started && hasNextModelLoader()) {
    //     ModelLoader<File, ?> modelLoader = modelLoaders.get(modelLoaderIndex++);
    //     loadData =
    //         modelLoader.buildLoadData(
    //             cacheFile, helper.getWidth(), helper.getHeight(), helper.getOptions());
    //     if (loadData != null && helper.hasLoadPath(loadData.fetcher.getDataClass())) {
    //       started = true;
    //       loadData.fetcher.loadData(helper.getPriority(), this);
    //     }
    //   }

    let transformationKey: TransformationKey = helper.getTransformationKey()
    // 查询缓存
    let a = helper.getTransformation(transformationKey)
    if(match(a){
        case Some(x) => true
        case None => false
    }) {
        AppLog.error("not null")
    } else {
        AppLog.error("null")
    }

    currentKey = Some(ResourceCacheKey( // NOPMD AvoidInstantiatingObjectsInLoops
                helper.getArrayPool(),
                ModelKey(helper.getModel()),
                helper.getSignature(),
                helper.getWidth(),
                helper.getHeight(),
                helper.getTransformation(transformationKey).getOrThrow(),
                transformationKey,
                helper.getOptions()));

    AppLog.error("SourceGenerator startNext get  ${currentKey}")
        cacheFile = helper.getDiskCache().get(currentKey.getOrThrow());

        if(match(cacheFile) {
        case Some(x) => true
        case _ => false
      }) {
        
        AppLog.error("DataCacheGenerator  startNext  true : ${cacheFile.getOrThrow().filePath.toString()}")
        // cacheFile to inputstream

        let outStream: ByteArrayStream = cacheFile.getOrThrow().toByteArrayStream()

        // TODO 关闭 or seek
        //cacheFile.getOrThrow().close()

        // AppLog.error("brs length: ${brs.length}")
        cb.onDataFetcherReady(ModelKey(helper.getModel()), Some(outStream), DataSource.RESOURCE_DISK_CACHE);
        // cb.onDataFetcherFailed(ModelKey(helper.getModel()), e, loadData.fetcher, DataSource.DATA_DISK_CACHE);
        AppLog.error("resource 查找成功 :")
        return true
      }

      AppLog.error("resource 查找失败")

      return false;
    } finally {
    //   DropletTrace.endSection();
    }
  }

//   private boolean hasNextModelLoader() {
//     return modelLoaderIndex < modelLoaders.size();
//   }

  public func cancel(): Unit {
    // LoadData<?> local = loadData;
    // if (local != null) {
    //   local.fetcher.cancel();
    // }
  }

  public func onDataReady(data: Any): Unit {
      cb.onDataFetcherReady(sourceKey.getOrThrow(), Some(data), DataSource.RESOURCE_DISK_CACHE);
    }

  public func onLoadFailed(e: DropletException): Unit {
    AppLog.error("DropletException ${e.toString()}")
    cb.onDataFetcherFailed();

  }
}
