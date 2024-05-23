package glide

from std import math.*
from std import sync.*

from ohos import base.*

/** An interface for adding and removing resources from an in memory cache. */
public interface MemoryCache {

  /** Returns the sum of the sizes of all the contents of the cache in bytes. */
  func getCurrentSize(): Int64;

  /** Returns the current maximum size in bytes of the cache. */
  func getMaxSize(): Int64;

  func setSizeMultiplier(multiplier: Float32): Unit;

  func remove(key: AnyKey): Option<AnyGlideResource>;

  func put(key: AnyKey, resource: AnyGlideResource): Option<AnyGlideResource>;

  func setResourceRemovedListener(listener: ResourceRemovedListener): Unit;

  func clearMemory(): Unit;

  func trimMemory(level: Int64): Unit;

}
