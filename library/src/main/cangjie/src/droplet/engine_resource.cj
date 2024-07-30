/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public interface ResourceListener {
    func onResourceReleased(key: AnyKey, resource: AnyEngineResource): Unit;
}

public open class AnyEngineResource <: AnyDropletResource {
  public let isMemoryCacheable: Bool;
  public let isRecyclable: Bool;
  public let resource: AnyDropletResource;
  public let resourceTypeClass: ResourceTypeClass;
  public let listener: ResourceListener;
  public let key: AnyKey;

  public var acquired: Int64 = 0;
  public var isRecycled: Bool = false;

  private let mtx = ReentrantMutex();

  public init(toWrap: AnyDropletResource,
      isMemoryCacheable: Bool,
      isRecyclable: Bool,
      key: AnyKey,
      listener: ResourceListener,
      resourceTypeClass: ResourceTypeClass) {
    this.resource = toWrap;
    this.isMemoryCacheable = isMemoryCacheable;
    this.isRecyclable = isRecyclable;
    this.key = key;
    this.listener = listener;
    this.resourceTypeClass = resourceTypeClass;
  }

  public func getResource(): AnyDropletResource {
    return resource;
  }

  public func getMemoryCacheable(): Bool {
    return isMemoryCacheable;
  }

  public func getResourceTypeClass(): ResourceTypeClass {
    return resource.getResourceTypeClass();
  }

  public func getAsAny(): Any {
    return resource.getAsAny();
  }

  public func getSize(): Int32 {
    return resource.getSize();
  }

  public func recycle(): Unit {
    synchronized(mtx) {
        if (acquired > 0) {
            throw IllegalStateException("Cannot recycle a resource while it is still acquired");
        }
        if (isRecycled) {
            throw IllegalStateException("Cannot recycle a resource that has already been recycled");
        }
        isRecycled = true;
        if (isRecyclable) {
            resource.recycle();
        }
    }
  }

  /**
   * Increments the number of consumers using the wrapped resource. Must be called on the main
   * thread.
   *
   * <p>This must be called with a number corresponding to the number of new consumers each time new
   * consumers begin using the wrapped resource. It is always safer to call acquire more often than
   * necessary. Generally external users should never call this method, the framework will take care
   * of this for you.
   */
   public func acquire(): Unit {
    synchronized(mtx) {
        if (isRecycled) {
            throw IllegalStateException("Cannot acquire a recycled resource");
        }
        acquired = acquired + 1;
    }
    }

  /**
   * Decrements the number of consumers using the wrapped resource. Must be called on the main
   * thread.
   *
   * <p>This must only be called when a consumer that called the {@link #acquire()} method is now
   * done with the resource. Generally external users should never call this method, the framework
   * will take care of this for you.
   */
  // listener is effectively final.
  public func release(): Unit {
    var release: Bool = false;
    synchronized (mtx) {
      if (acquired <= 0) {
        throw IllegalStateException("Cannot release a recycled or not yet acquired resource");
      }
      acquired = acquired - 1
      if (acquired == 0) {
        release = true;
      }
    }
    if (release) {
      listener.onResourceReleased(key, this);
    }
  }

  public func toString(): String {
    synchronized(mtx) {
        return """
        EngineResource{isMemoryCacheable=
        ${isMemoryCacheable}, key=
        ${key}, acquired=
        ${acquired}, isRecycled=
        ${isRecycled}, resource=
        ${resource}}""";
    }
  }

    public func hashCode(): Int64 {
        return this.resource.hashCode()
    }

    public operator func ==(that: AnyDropletResource): Bool {
        if(that is AnyEngineResource) {
            var other = (that as AnyEngineResource).getOrThrow()
            return other.resource == this.resource
        }
        return false
    }

    public operator func !=(that: AnyDropletResource): Bool {
        if(that is AnyEngineResource) {
            var other = (that as AnyEngineResource).getOrThrow()
            return other.resource != this.resource
        }
        return true
    }

}

public class EngineResource<Z> <: AnyEngineResource & DropletResource<Z> {

  public let resourceZ: DropletResource<Z>;

  public init(toWrap: DropletResource<Z>,
      isMemoryCacheable: Bool,
      isRecyclable: Bool,
      key: AnyKey,
      listener: ResourceListener,
      resourceTypeClass: ResourceTypeClass) {
    super(toWrap, isMemoryCacheable, isRecyclable, key, listener, resourceTypeClass)
    resourceZ = toWrap
  }

  public func get(): Z {
    return resourceZ.get()
  }

  public func copy(): DropletResource<Z> {
    return this
  }
}

