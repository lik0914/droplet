/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet



/** An interface for adding and removing resources from an in memory cache. */
public interface MemoryCache {

  /** Returns the sum of the sizes of all the contents of the cache in bytes. */
  func getCurrentSize(): Int64;

  /** Returns the current maximum size in bytes of the cache. */
  func getMaxSize(): Int64;

  func setSizeMultiplier(multiplier: Float32): Unit;

  func remove(key: AnyKey): Option<AnyDropletResource>;

  func put(key: AnyKey, resource: AnyDropletResource): Option<AnyDropletResource>;

  func setResourceRemovedListener(listener: ResourceRemovedListener): Unit;

  func clearMemory(): Unit;

  func trimMemory(level: Int64): Unit;

}
