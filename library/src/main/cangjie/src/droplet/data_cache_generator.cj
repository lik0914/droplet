/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public class DataCacheGenerator <: DataFetcherGenerator {

  private let helper: DecodeHelper;
  private let cb: FetcherReadyCallback;

  private var sourceIdIndex: Int64 = -1;

  // PMD is wrong here, this File must be an instance variable because it may be used across
  // multiple calls to startNext.
  private var cacheFile: Option<DropletFile> = None;

  public init(helper: DecodeHelper, cb: FetcherReadyCallback) {
    this.helper = helper;
    this.cb = cb;
  }

  // In some cases we may want to load a specific cache key (when loading from source written to
  // cache), so we accept a list of keys rather than just obtain the list from the helper.

  public func startNext(): Bool {
    
    try {
      // 从磁盘缓存获取图片
      let originalKey: AnyKey = DataCacheKey(ModelKey(helper.getModel()), helper.getSignature());
      cacheFile = helper.getDiskCache().get(originalKey);

      if(match(cacheFile) {
        case Some(x) => true
        case _ => false
      }) {

        let outStream: ByteArrayStream = cacheFile.getOrThrow().toByteArrayStream()

        cb.onDataFetcherReady(ModelKey(helper.getModel()), Some(outStream), DataSource.DATA_DISK_CACHE);

        return true
      }
      return false
    } finally {
    }
  }


  public func cancel(): Unit {

  }

}
