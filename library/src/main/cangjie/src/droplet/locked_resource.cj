/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

public class LockedResource<Z> <: DropletResource<Z> {

  private let stateVerifier: StateVerifier = StateVerifier.newInstance();
  private var toWrap: Option<DropletResource<Z>> = None;
  private var isLocked: Bool = false;
  private var isRecycled: Bool = false;
  private let mtx = ReentrantMutex()

  public static func obtain(resource: DropletResource<Z>): LockedResource<Z> {
    let result: LockedResource<Z> = LockedResource<Z>();
    result.initLockedResource(resource);
    return result;
  }

  private func initLockedResource(toWrap: DropletResource<Z>): Unit {
    isRecycled = false;
    isLocked = true;
    this.toWrap = Some(toWrap);
  }

  private func release(): Unit {
    toWrap = None;
  }

  public func unlock(): Unit {
    synchronized(mtx) {
        stateVerifier.throwIfRecycled();

        if (!isLocked) {
        throw DropletException("Already unlocked");
        }
        this.isLocked = false;
        if (isRecycled) {
            recycle();
        }
    }
  }

  public func getResourceTypeClass(): ResourceTypeClass {
    return toWrap.getOrThrow().getResourceTypeClass();
  }

  public func get(): Z {
    return toWrap.getOrThrow().get();
  }

  public func getSize(): Int32 {
    return toWrap.getOrThrow().getSize();
  }

  public func recycle(): Unit {
    synchronized(mtx) {
        stateVerifier.throwIfRecycled();

        this.isRecycled = true;
        if (!isLocked) {
            toWrap.getOrThrow().recycle();
            release();
        }
    }
  }

  public func getVerifier(): StateVerifier {
    return stateVerifier;
  }

    public override func getAsAny(): Any {
    return (get() as Any).getOrThrow()
  }

  public func toString(): String {
    // TODO LockedResource toString
      return "LockedResource ${isLocked} ${isRecycled}"
  }

  public func hashCode(): Int64 {
    // TODO LockedResource hashCode
      return this.toWrap.getOrThrow().hashCode()
  }

  public operator func ==(that: AnyDropletResource): Bool {
    // TODO LockedResource ==
    if(that is LockedResource<Z>) {
      return true
    }
    return false
  }

  public operator func !=(that: AnyDropletResource): Bool {
    // TODO LockedResource !=
    if(that is LockedResource<Z>) {
      return false
    }
    return true
  }

  public func copy(): DropletResource<Z> {
    return this
  }
}
