/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package droplet.droplet

/** Verifies that the job is not in the recycled state. */
public abstract class StateVerifier {
//   private static let DEBUG: Bool = false;

  /** Creates a new {@link StateVerifier} instance. */
  public static func newInstance(): StateVerifier {
    // if (DEBUG) {
    //   return DebugStateVerifier();
    // } else {
    //   return DefaultStateVerifier();
    // }
    return DefaultStateVerifier();
  }

  /**
   * Throws an exception if we believe our object is recycled and inactive (i.e. is currently in an
   * object pool).
   */
  public func throwIfRecycled(): Unit;

  /** Sets whether or not our object is recycled. */
    public func setRecycled(isRecycled: Bool): Unit;

}

public class DefaultStateVerifier <: StateVerifier {
    private var isReleased: Bool = false;

    public override func throwIfRecycled(): Unit {
      if (isReleased) {
        throw IllegalStateExceptions("Already released")
      }
    }

    public override func setRecycled(isRecycled: Bool): Unit {
      this.isReleased = isRecycled;
    }
  }
