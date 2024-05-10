package glide.engine.cache.memory_cache

public class LruResourceCache <: LruCache<AnyKey, AnyGlideResource> & MemoryCache {

  private var listener: Option<ResourceRemovedListener> = None;

  public init() {
    super(100);
  }

  public init(size: Int64) {
    super(size);
  }

  public override func setResourceRemovedListener(listener: ResourceRemovedListener): Unit {
    this.listener = listener;
  }

  protected override func onItemEvicted(key: AnyKey, item: AnyGlideResource): Unit {
    // if (listener != null && item != null) {
    if (match(listener) {
      case Some(x) => true
      case _ => false
    }) {
      listener.getOrThrow().onResourceRemoved(item);
    }
  }

  protected override func getSize(item: AnyGlideResource): Int64 {
    // if (item == null) {
    //   return super.getSize(null);
    // } else {
    //   return item.getSize();
    // }
    return Int64(item.getSize());
  }

  public override func trimMemory(level: Int64): Unit {
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
