/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public interface ActiveResourceRemovedListener {
    func onActiveResourceRemoved(key: AnyKey, r: AnyDropletResource): Unit;
}

public interface ResourceRemovedListener {
    func onResourceRemoved(r: AnyDropletResource): Unit;
}

public interface AnyDropletResource <: DropletAny<AnyDropletResource> {
  func getResourceTypeClass(): ResourceTypeClass;

  func getSize(): Int32;

  func recycle(): Unit;

  func getAsAny(): Any;
}

/**
 * A resource interface that wraps a particular type so that it can be pooled and reused.
 *
 * @param <Z> The type of resource wrapped by this class.
 */
public interface DropletResource<Z> <: AnyDropletResource {
  func get(): Z;
  func copy(): DropletResource<Z>;
}
