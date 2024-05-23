package glide

from std import fs.*


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

