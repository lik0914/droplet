package glide.engine

import glide.util.pool.*

public class LockedResource<Z> <: GlideResource<Z> {

  private let stateVerifier: StateVerifier = StateVerifier.newInstance();
  private var toWrap: Option<GlideResource<Z>> = None;
  private var isLocked: Bool = false;
  private var isRecycled: Bool = false;
  private let mtx = ReentrantMutex()

  public static func obtain(resource: GlideResource<Z>): LockedResource<Z> {
    let result: LockedResource<Z> = LockedResource<Z>();
    result.initLockedResource(resource);
    return result;
  }

  private func initLockedResource(toWrap: GlideResource<Z>): Unit {
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
        throw GlideException("Already unlocked");
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
      // return this.pixelMap.toString()
      return "LockedResource ${isLocked} ${isRecycled}"
  }

  public func hashCode(): Int64 {
    // TODO LockedResource hashCode
      // return this.pixelMap.hashCode()
      return this.toWrap.getOrThrow().hashCode()
  }

  public operator func ==(that: AnyGlideResource): Bool {
    // TODO LockedResource ==
    if(that is LockedResource<Z>) {
      return true
    }
    return false
      // return that.get() == this.get()
  }

  public operator func !=(that: AnyGlideResource): Bool {
    // TODO LockedResource !=
    if(that is LockedResource<Z>) {
      return false
    }
    return true
      // return that.get() != this.get()
  }

  public func copy(): GlideResource<Z> {
    return this
  }
}
