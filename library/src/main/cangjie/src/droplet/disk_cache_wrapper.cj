/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet


public class DiskLruCacheWrapper <: DiskCache {
  private static let TAG: String = "DiskLruCacheWrapper";

  private static let APP_VERSION: Int64 = 1;
  private static let VALUE_COUNT: Int64 = 1;
  private static var wrapper: Option<DiskLruCacheWrapper> = None;

  private let safeKeyGenerator: SafeKeyGenerator;
  private var directory: DropletFile;
  private let maxSize: Int64;

  private let writeLocker: DiskCacheWriteLocker = DiskCacheWriteLocker();
  private var diskLruCache: Option<DiskLruCache> = None;


  private static let mtx = ReentrantMutex()

  /**
   * Get a DiskCache in the given directory and size. If a disk cache has already been created with
   * a different directory and/or size, it will be returned instead and the new arguments will be
   * ignored.
   *
   * @param directory The directory for the disk cache
   * @param maxSize The max size for the disk cache
   * @return The new disk cache with the given arguments, or the current cache if one already exists
   * @deprecated Use {@link #create(File, long)} to create a new cache with the specified arguments.
   */
  public static func getStatic(directory: DropletFile, maxSize: Int64): DiskCache {
    // TODO calling twice with different arguments makes it return the cache for the same
    // directory, it's public!

    synchronized(mtx) {
        if (match(wrapper) {
            case Some(x) => false
            case _ => true
        }) {
            wrapper = Some(DiskLruCacheWrapper(directory, maxSize));
        }
        return wrapper.getOrThrow();
    }
  }

  /**
   * Create a new DiskCache in the given directory with a specified max size.
   *
   * @param directory The directory for the disk cache
   * @param maxSize The max size for the disk cache
   * @return The new disk cache with the given arguments
   */
  public static func create(directory: DropletFile, maxSize: Int64): DiskCache {
    return DiskLruCacheWrapper(directory, maxSize);
  }

  /**
   * @deprecated Do not extend this class.
   */
  public init(directory: DropletFile, maxSize: Int64) {
    this.directory = directory;
    this.maxSize = maxSize;
    this.safeKeyGenerator = SafeKeyGenerator();
  }

  private func getDiskCache(): DiskLruCache {
    synchronized(mtx) {
        if (match(diskLruCache) {
          case Some(x) => false
          case _ => true
        }) {
            diskLruCache = Some(DiskLruCache.openStatic(directory, APP_VERSION, VALUE_COUNT, maxSize));
        }
        return diskLruCache.getOrThrow();
    }
  }

  public func get(key: AnyKey): Option<DropletFile> {
    var safeKey: String = safeKeyGenerator.getSafeKey(key);
    var result: Option<DropletFile> = None;
    try {
      // It is possible that the there will be a put in between these two gets. If so that shouldn't
      // be a problem because we will always put the same value at the same key so our input streams
      // will still represent the same data.
      let value: Option<Value> = getDiskCache().get(safeKey);
      if (match(value) {
        case Some(x) => true
        case _ => false
      }) {
        result = Some(value.getOrThrow().getFile(0));
      }
    } catch (e: Exception) {
    }
    return result;
  }

  public func put(key: AnyKey, writer: DiskCacheWriter): Unit {
    // We want to make sure that puts block so that data is available when put completes. We may
    // actually not write any data if we find that data is written by the time we acquire the lock.
    var safeKey: String = safeKeyGenerator.getSafeKey(key);
    writeLocker.acquire(safeKey);
    try {
      try {
        // We assume we only need to put once, so if data was written while we were trying to get
        // the lock, we can simply abort.
        var diskCache: DiskLruCache = getDiskCache();
        var current: Option<Value> = diskCache.get(safeKey);
        if (match(current) {
          case Some(x) => true
          case _ => false
        }) {
          return;
        }
        var editor: Option<Editor> = diskCache.edit(safeKey);
        if (match(editor) {
          case Some(x) => false
          case _ => true
        }) {
          throw Exception("droplet error: Had two simultaneous puts for: " + safeKey);
        }
        try {
          var file: DropletFile = editor.getOrThrow().getFile(0);
          if (writer.write(file)) {
            editor.getOrThrow().commit();
          }
        } finally {
          editor.getOrThrow().abortUnlessCommitted();
        }
      } catch (e: Exception) {
        AppLog.error("droplet exception: Unable to put to disk cache ${e}")
      }
    } catch(e: Exception) {

    } finally {
      writeLocker.release(safeKey);
    }
  }

  public func delete(key: AnyKey): Unit {
    var safeKey: String = safeKeyGenerator.getSafeKey(key);
    try {
      getDiskCache().remove(safeKey);
    } catch (e: Exception) {
      AppLog.error("droplet error: Unable to delete from disk cache")
    }
  }

  public func clear(): Unit {
    synchronized(mtx) {
      try {
        getDiskCache().delete();
      } catch (e: Exception) {
        AppLog.error("Unable to clear disk cache or disk cache cleared externally")
      } finally {
        // Delete can close the cache but still throw. If we don't null out the disk cache here, every
        // subsequent request will try to act on a closed disk cache and fail. By nulling out the disk
        // cache we at least allow for attempts to open the cache in the future. See #2465.
        resetDiskCache();
      }
    }
  }

  private func resetDiskCache(): Unit {
    synchronized(mtx) {
      diskLruCache = None;
    }
  }
}
