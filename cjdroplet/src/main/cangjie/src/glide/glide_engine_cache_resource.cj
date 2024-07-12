/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

public interface ActiveResourceRemovedListener {
    func onActiveResourceRemoved(key: AnyKey, r: AnyGlideResource): Unit;
}

public interface ResourceRemovedListener {
    func onResourceRemoved(r: AnyGlideResource): Unit;
}

public interface AnyGlideResource <: GlideAny<AnyGlideResource> {
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
public interface GlideResource<Z> <: AnyGlideResource {
  func get(): Z;
  func copy(): GlideResource<Z>;
}
