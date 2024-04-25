package glide.engine.cache.disk_cache

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

        // AppLog.error("DiskLruCacheFactory build: ${cacheDir} ${cacheDir.isDirectory()} ${cacheDir.mkdirs()}")
        if (cacheDir.isDirectory() || cacheDir.mkdirs()) {
            return DiskLruCacheWrapper.create(cacheDir, diskCacheSize);
        }

        throw FSException("glideerror: glidefile create error")
    }
}
