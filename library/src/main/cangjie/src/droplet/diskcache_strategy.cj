/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet


public abstract class DiskCacheStrategy <: ToString {

  public func isDataCacheable(dataSource: DataSource): Bool;

  public func isResourceCacheable(isFromAlternateCacheKey: Bool, dataSource: DataSource, encodeStrategy: EncodeStrategy): Bool;

  public func decodeCachedResource(): Bool;

  public func decodeCachedData(): Bool;

  public func equals(other: DiskCacheStrategy): Bool;

  public func toString(): String
}

public class DiskCacheStrategyALL <: DiskCacheStrategy {

    public func toString(): String {
        return "DiskCacheStrategyALL"
    }

    public func equals(other: DiskCacheStrategy): Bool {
        if(other is DiskCacheStrategyALL) {
            return true
        }
        return false
    }

    public func isDataCacheable(dataSource: DataSource): Bool {
        return match(dataSource) {
            case REMOTE => true
            case _ => false
        }
    }

    public func isResourceCacheable(isFromAlternateCacheKey: Bool,
        dataSource: DataSource,
        encodeStrategy: EncodeStrategy): Bool {
            
            return match(dataSource) {
                case RESOURCE_DISK_CACHE => 
                    AppLog.error("isResourceCacheable RESOURCE_DISK_CACHE")
                    return false
                case MEMORY_CACHE => 
                    AppLog.error("isResourceCacheable MEMORY_CACHE")
                    return false
                case _ => 
                    AppLog.error("isResourceCacheable ${dataSource} true")
                    return true
            }
            // return dataSource != DataSource.RESOURCE_DISK_CACHE
            //     && dataSource != DataSource.MEMORY_CACHE;
    }

    public func decodeCachedResource(): Bool {
        return true
    }

    public func decodeCachedData(): Bool {
        return true
    }
}

public class DiskCacheStrategyNONE <: DiskCacheStrategy {

    public func toString(): String {
        return "DiskCacheStrategyNONE"
    }

    public func equals(other: DiskCacheStrategy): Bool {
        if(other is DiskCacheStrategyNONE) {
            return true
        }
        return false
    }

    public func isDataCacheable(dataSource: DataSource): Bool {
        return false;
    }

    public func isResourceCacheable(isFromAlternateCacheKey: Bool,
        dataSource: DataSource,
        encodeStrategy: EncodeStrategy): Bool {
            return false;
    }

    public func decodeCachedResource(): Bool {
        return false
    }

    public func decodeCachedData(): Bool {
        return false
    }
}

public class DiskCacheStrategyDATA <: DiskCacheStrategy {

    public func toString(): String {
        return "DiskCacheStrategyDATA"
    }

    public func equals(other: DiskCacheStrategy): Bool {
        if(other is DiskCacheStrategyDATA) {
            return true
        }
        return false
    }

    public func isDataCacheable(dataSource: DataSource): Bool {
        return match(dataSource) {
                case DATA_DISK_CACHE => false
                case MEMORY_CACHE => false
                case _ => true
            }
        // return dataSource != DataSource.DATA_DISK_CACHE &&
        //  dataSource != DataSource.MEMORY_CACHE;
    }

    public func isResourceCacheable(isFromAlternateCacheKey: Bool,
        dataSource: DataSource,
        encodeStrategy: EncodeStrategy): Bool {
        return false;
    }

    public func decodeCachedResource(): Bool {
        return false;
    }

    public func decodeCachedData(): Bool {
        return true
    }
}


public class DiskCacheStrategyRESOURCE <: DiskCacheStrategy {

    public func toString(): String {
        return "DiskCacheStrategyRESOURCE"
    }

    public func equals(other: DiskCacheStrategy): Bool {
        if(other is DiskCacheStrategyRESOURCE) {
            return true
        }
        return false
    }

    public func isDataCacheable(dataSource: DataSource): Bool {
        return false;
    }

    public func isResourceCacheable(isFromAlternateCacheKey: Bool,
        dataSource: DataSource,
        encodeStrategy: EncodeStrategy): Bool {

            return match(dataSource) {
                case RESOURCE_DISK_CACHE => false
                case MEMORY_CACHE => false
                case _ => true
            }
        // return dataSource != DataSource.RESOURCE_DISK_CACHE
        //     && dataSource != DataSource.MEMORY_CACHE;
    }

    public func decodeCachedResource(): Bool {
        return true;
    }

    public func decodeCachedData(): Bool {
        return false
    }
}

public class DiskCacheStrategyAUTOMATIC <: DiskCacheStrategy {

    public func toString(): String {
        return "DiskCacheStrategyAUTOMATIC"
    }

    public func equals(other: DiskCacheStrategy): Bool {
        if(other is DiskCacheStrategyAUTOMATIC) {
            return true
        }
        return false
    }

    public func isDataCacheable(dataSource: DataSource): Bool {
        return match(dataSource) {
            case REMOTE => true
            case _ => false
        }
    }

    public func isResourceCacheable(isFromAlternateCacheKey: Bool,
        dataSource: DataSource,
        encodeStrategy: EncodeStrategy): Bool {

            return ((isFromAlternateCacheKey && match(dataSource) {
                case DATA_DISK_CACHE => true
                case _ => false
            }) || match(dataSource) {
                case LOCAL => true
                case _ => false
            }) && match(encodeStrategy) {
                case TRANSFORMED => true
                case _ => false
            };

        // return ((isFromAlternateCacheKey && dataSource == DataSource.DATA_DISK_CACHE)
        //           || dataSource == DataSource.LOCAL)
        //       && encodeStrategy == EncodeStrategy.TRANSFORMED;
    }

    public func decodeCachedResource(): Bool {
        return true;
    }

    public func decodeCachedData(): Bool {
        return true
    }
}
