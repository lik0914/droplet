/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

from std import math.*
from std import sync.*


public class ActiveResources <: LruCache<AnyKey, AnyGlideResource> {

  private var listener: Option<ActiveResourceRemovedListener> = None;

  public init() {
    super(1000);
  }

  public init(size: Int64) {
    super(size);
  }

  public func moveMemory(memoryCache: MemoryCache): Unit {
    var iter: Iterator<CustomMapItem<AnyKey, MemoryEntry<AnyGlideResource>>> = this.cache.getIterator()
    while (true) {
      match (iter.next()) {
        case Some(i) => memoryCache.put(i.k, i.v.value)
        case None => break
      }
    }
    this.cache.clear()
  }

  public func setActiveResourceRemovedListener(listener: ActiveResourceRemovedListener): Unit {
    this.listener = listener;
  }

  protected override func onItemEvicted(key: AnyKey, item: AnyGlideResource): Unit {
    if (match(listener) {
      case Some(x) => true
      case _ => false
    }) {
      listener.getOrThrow().onActiveResourceRemoved(key, item);
    }
  }

  protected func getSize(item: AnyGlideResource): Int64 {
    return Int64(item.getSize());
  }

  public func trimMemory(level: Int64): Unit {
    // Name	                Value	Description
    // MEMORY_LEVEL_MODERATE	0	  Moderate memory usage.
    // MEMORY_LEVEL_LOW	      1	  Low memory usage.
    // MEMORY_LEVEL_CRITICAL	2	  High memory usage.
    if (level == 2) {
      // 全部清空
      clearMemory();
    } else if (level == 0) {
      // 清空一半内存
      trimToSize(getMaxSize() / 2);
    }
  }

}
