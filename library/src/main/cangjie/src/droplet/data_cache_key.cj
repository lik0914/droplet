/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public class DataCacheKey <: AnyKey {

  private let sourceKey: AnyKey;
  private let signature: AnyKey;

  public init(sourceKey: AnyKey, signature: AnyKey) {
    this.sourceKey = sourceKey;
    this.signature = signature;
  }

  public func getSourceKey(): AnyKey {
    return sourceKey;
  }

  public func equals(o: AnyKey): Bool {
    if (o is DataCacheKey) {
      let other: DataCacheKey = (o as DataCacheKey).getOrThrow();
      return sourceKey == other.sourceKey && signature == other.signature;
    }
    return false;
  }

  public operator func ==(that: AnyKey): Bool {
    // AppLog.error("DataCacheKey == ${equals(that)}")
      return equals(that)
  }

  public operator func !=(that: AnyKey): Bool {
    // AppLog.error("DataCacheKey != ${!equals(that)}")
      return !equals(that)
  }

  public func hashCode(): Int64 {
    var result: Int64 = sourceKey.hashCode();
    result = 31 * result + signature.hashCode();
    // AppLog.error("DataCacheKey hashCode ${result}")
    return result;
  }

  public func toString(): String {
    return """
    DataCacheKey{sourceKey=${sourceKey},
     signature=${signature}""";
  }

  public func updateDiskCacheKey(md5: MD5): Unit {
    AppLog.error("DataCacheKey updateDiskCacheKey : ${sourceKey}")
    sourceKey.updateDiskCacheKey(md5);
    signature.updateDiskCacheKey(md5);
  }
}
