package glide.engine.cache.disk_cache

public class DiskCacheWriteLocker {
  private let locks: HashMap<String, WriteLock> = HashMap<String, WriteLock>();
  private let writeLockPool: WriteLockPool = WriteLockPool();
  private let mtx = ReentrantMutex();

  public func acquire(safeKey: String) {
    var writeLock: Option<WriteLock>;
    synchronized (mtx) {
      writeLock = locks.get(safeKey);
      if (match(writeLock) {
        case Some(x) => false
        case _ => true
      }) {
        writeLock = Some(writeLockPool.obtain());
        locks.put(safeKey, writeLock.getOrThrow());
      }
      writeLock.getOrThrow().interestedThreads++;
    }

    writeLock.getOrThrow().lock.lock();
  }

  public func release(safeKey: String): Unit {
    var writeLock: Option<WriteLock>;
    synchronized (mtx) {
      writeLock = locks.get(safeKey);
      if(match(writeLock) {
        case Some(x) => false
        case _ => true
      }) {
        throw Exception("glide error: release --- writeLock is null")
      }
      if (writeLock.getOrThrow().interestedThreads < 1) {
        throw Exception("Cannot release a lock that is not held safeKey: ${safeKey}, interestedThreads: ${writeLock.getOrThrow().interestedThreads}");
      }

      writeLock.getOrThrow().interestedThreads--;
      if (writeLock.getOrThrow().interestedThreads == 0) {
        var removed: Option<WriteLock> = locks.remove(safeKey);
        if (!(removed.getOrThrow() == writeLock.getOrThrow())) {
          throw Exception("glide error: Removed the wrong lock")
          // throw Exception(
          //     "Removed the wrong lock"
          //         + ", expected to remove: "
          //         + writeLock
          //         + ", but actually removed: "
          //         + removed
          //         + ", safeKey: "
          //         + safeKey);
        }
        writeLockPool.offer(removed.getOrThrow());
      }
    }

    writeLock.getOrThrow().lock.unlock();
  }
}
