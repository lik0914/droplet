/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

public open class DiskLruCacheFactory <: DiskCacheFactory {
    private var diskCacheSize: Int64 = 0
    private var cacheDirectoryGetter: CacheDirectoryGetter
    
    public init(diskCacheFolder: String, diskCacheSize: Int64) {
        this(DefaultCacheDirectoryGetter(diskCacheFolder), diskCacheSize);
    }

    public init(diskCacheFolder: String, diskCacheName: String, diskCacheSize: Int64) {
        this(DefaultCacheDirectoryGetter2(diskCacheFolder, diskCacheName), diskCacheSize);
    }

    public init(cacheDirectoryGetter: CacheDirectoryGetter, diskCacheSize: Int64) {
        this.diskCacheSize = diskCacheSize;
        this.cacheDirectoryGetter = cacheDirectoryGetter;
    }

    public override func build(): DiskCache {
        var cacheDir: GlideFile = cacheDirectoryGetter.getCacheDirectory();

        if (cacheDir.isDirectory() || cacheDir.mkdirs()) {
            return DiskLruCacheWrapper.create(cacheDir, diskCacheSize);
        }
        throw Exception("glideerror: glidefile create error")
    }
}
