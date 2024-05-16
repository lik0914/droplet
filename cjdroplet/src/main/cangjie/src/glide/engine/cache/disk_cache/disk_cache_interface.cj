package glide.engine.cache.disk_cache

from std import fs.*
import glide.util.*

public interface DiskCache {
    func get(key: AnyKey): Option<GlideFile>
    func put(key: AnyKey, writer: DiskCacheWriter): Unit
    func delete(key: AnyKey): Unit
    func clear(): Unit
}

public interface DiskCacheWriter {
    func write(file: GlideFile): Bool
}

public interface DiskCacheFactory {
    func build(): DiskCache
}

