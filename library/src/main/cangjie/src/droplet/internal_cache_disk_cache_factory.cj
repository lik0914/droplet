/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public class InternalCacheDiskCacheFactory <: DiskLruCacheFactory {
    /** 250 MB of cache. */
    public static let DEFAULT_DISK_CACHE_SIZE: Int64 = 250 * 1024 * 1024;

    public static let DEFAULT_DISK_CACHE_DIR: String = "image_manager_disk_cache";
    
    public init() {
        this(
            DEFAULT_DISK_CACHE_DIR,
            DEFAULT_DISK_CACHE_SIZE);
    }

    public init(diskCacheSize: Int64) {
        this(DEFAULT_DISK_CACHE_DIR, diskCacheSize);
    }

    public init(diskCacheName: Option<String>, diskCacheSize: Int64) {
        super(InternalCacheDirectoryGetter(diskCacheName), diskCacheSize)
    }
}

public interface CacheDirectoryGetter {
    func getCacheDirectory(): DropletFile;
}

public class InternalCacheDirectoryGetter <: CacheDirectoryGetter {

    public InternalCacheDirectoryGetter(var diskCacheName: Option<String>) {
    }

    public func getCacheDirectory(): DropletFile {

        // TODO 缓存文件夹
        var cacheDirectory: DropletFile = DropletFile("/data/storage/el2/base/haps/entry/diskcachetemp")
        if (match(this.diskCacheName) {
            case Some(x) => true
            case _ => false
        }) {
            return DropletFile(cacheDirectory, this.diskCacheName.getOrThrow());
        }

        return cacheDirectory;
    }
}

public class DefaultCacheDirectoryGetter <: CacheDirectoryGetter {
    public DefaultCacheDirectoryGetter(var diskCacheFolder: String) {

    }
    public override func getCacheDirectory(): DropletFile {
        return DropletFile(diskCacheFolder)
    }
}

public class DefaultCacheDirectoryGetter2 <: CacheDirectoryGetter {
    public DefaultCacheDirectoryGetter2(var diskCacheFolder: String, var diskCacheName: String) {

    }
    public override func getCacheDirectory(): DropletFile {
        return DropletFile(diskCacheFolder, diskCacheName)
    }
}
