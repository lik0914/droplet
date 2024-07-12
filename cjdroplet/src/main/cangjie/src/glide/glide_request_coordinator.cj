/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

from std import sync.*

/** A simple state enum to keep track of the states of individual subrequests. */
public class RequestState <: Equatable<RequestState> {

  public static let RUNNING: RequestState = RequestState(false, "RUNNING")
  public static let PAUSED: RequestState = RequestState(false, "PAUSED")
  public static let CLEARED: RequestState = RequestState(false, "CLEARED")
  public static let SUCCESS: RequestState = RequestState(true, "SUCCESS")
  public static let FAILED: RequestState = RequestState(true, "FAILED")

  // RUNNING(false),
  // PAUSED(false),
  // CLEARED(false),
  // SUCCESS(true),
  // FAILED(true);

  private let complete: Bool;
  private let states: String;

  public init(complete: Bool, states: String) {
    this.complete = complete;
    this.states = states;
  }

  func isComplete(): Bool {
    return complete;
  }

  func equals(that: RequestState): Bool {
    return (this.complete == that.complete) && (this.states == that.states)
  }

    public operator func ==(that: RequestState): Bool {
    return this.equals(that)
  }

  public operator func !=(that: RequestState): Bool {
    return !this.equals(that)
  }


}

public interface RequestCoordinator {

  /**
   * Returns true if the {@link Request} can display a loaded bitmap.
   *
   * @param request The {@link Request} requesting permission to display a bitmap.
   */
  func canSetImage(request: LoadRequest): Bool;

  /**
   * Returns true if the {@link Request} can display a placeholder.
   *
   * @param request The {@link Request} requesting permission to display a placeholder.
   */
  func canNotifyStatusChanged(request: LoadRequest): Bool;

  /**
   * Returns {@code true} if the {@link Request} can clear the {@link
   * com.bumptech.glide.request.target.Target}.
   */
  func canNotifyCleared(request: LoadRequest): Bool;

  /**
   * Returns true if any coordinated {@link Request} has successfully completed.
   *
   * @see Request#isComplete()
   */
  func isAnyResourceSet(): Bool;

  /** Must be called when a {@link Request} coordinated by this object completes successfully. */
  func onRequestSuccess(request: LoadRequest): Unit;

  /** Must be called when a {@link Request} coordinated by this object fails. */
  func onRequestFailed(request: LoadRequest): Unit;

  /** Returns the top most parent {@code RequestCoordinator}. */
  func getRoot(): RequestCoordinator;

}


public class ErrorRequestCoordinator <: RequestCoordinator & LoadRequest {

  private let requestLock: ReentrantMutex;
  private var parent: Option<RequestCoordinator> = None;

  public var primary: LoadRequest = NoRequest();
  public var error: LoadRequest = NoRequest();

  public var primaryState: RequestState = RequestState.CLEARED;

  public var errorState: RequestState = RequestState.CLEARED;

  public func equals(that: LoadRequest): Bool {
    if(that is ErrorRequestCoordinator) {
        var t: ErrorRequestCoordinator = (that as ErrorRequestCoordinator).getOrThrow()
        return t.primary.equals(this.primary) && t.error.equals(this.error) && t.primaryState == this.primaryState && t.errorState == this.errorState
    } else {
        return false
    }
  }

  public init(requestLock: ReentrantMutex, parent: Option<RequestCoordinator>) {
    this.requestLock = requestLock;
    this.parent = parent;
  }

  public func setRequests(primary: LoadRequest, error: LoadRequest): Unit {
    this.primary = primary;
    this.error = error;
  }

  public override func begin(): Unit {
    synchronized (requestLock) {
      if (primaryState != RequestState.RUNNING) {
        primaryState = RequestState.RUNNING;
        primary.begin();
      }
    }
  }

  public override func clear(): Unit {
    synchronized (requestLock) {
      primaryState = RequestState.CLEARED;
      primary.clear();
      // Don't check primary's failed state here because it will have been reset by the clear call
      // immediately before this.
      if (errorState != RequestState.CLEARED) {
        errorState = RequestState.CLEARED;
        error.clear();
      }
    }
  }

  public override func pause(): Unit {
    synchronized (requestLock) {
      if (primaryState == RequestState.RUNNING) {
        primaryState = RequestState.PAUSED;
        primary.pause();
      }
      if (errorState == RequestState.RUNNING) {
        errorState = RequestState.PAUSED;
        error.pause();
      }
    }
  }

  public override func isRunning(): Bool {
    synchronized (requestLock) {
      return primaryState == RequestState.RUNNING || errorState == RequestState.RUNNING;
    }
  }

  public override func isComplete(): Bool {
    synchronized (requestLock) {
      return primaryState == RequestState.SUCCESS || errorState == RequestState.SUCCESS;
    }
  }

  public override func isCleared(): Bool {
    synchronized (requestLock) {
      return primaryState == RequestState.CLEARED && errorState == RequestState.CLEARED;
    }
  }

  public override func isEquivalentTo(o: LoadRequest): Bool {
    if (o is ErrorRequestCoordinator) {
      var other: ErrorRequestCoordinator = (o as ErrorRequestCoordinator).getOrThrow();
      return primary.isEquivalentTo(other.primary) && error.isEquivalentTo(other.error);
    }
    return false;
  }

  public override func canSetImage(request: LoadRequest): Bool {
    synchronized (requestLock) {
      // Only one of primary or error runs at a time, so if we've reached this point and nothing
      // else is broken, we should have nothing else to enforce.
      return parentCanSetImage();
    }
  }

  private func parentCanSetImage(): Bool {
    if(match(parent) {
        case Some(x) => false
        case _ => true
    }) {
        return true
    } else {
        return parent.getOrThrow().canSetImage(this);
    }
    // return parent == null || parent.canSetImage(this);
  }

  public override func canNotifyStatusChanged(request: LoadRequest): Bool {
    synchronized (requestLock) {
      return parentCanNotifyStatusChanged() && isValidRequestForStatusChanged(request);
    }
  }

  public override func canNotifyCleared(request: LoadRequest): Bool {
    synchronized (requestLock) {
      return parentCanNotifyCleared() && request.equals(primary);
    }
  }

  private func parentCanNotifyCleared(): Bool {
    if(match(parent) {
        case Some(x) => false
        case _ => true
    }) {
        return true
    } else {
        return parent.getOrThrow().canNotifyCleared(this);
    }
    // return parent == null || parent.canNotifyCleared(this);
  }

  private func parentCanNotifyStatusChanged(): Bool {
    if(match(parent) {
        case Some(x) => false
        case _ => true
    }) {
        return true
    } else {
        return parent.getOrThrow().canNotifyStatusChanged(this);
    }
    // return parent == null || parent.canNotifyStatusChanged(this);
  }

  private func isValidRequestForStatusChanged(request: LoadRequest): Bool {
    if (primaryState != RequestState.FAILED) {
      return request.equals(primary);
    } else {
      return request.equals(error)
          // We don't want to call onLoadStarted once for the primary request and then again
          // if it fails and the error request starts. It's already running, so we might as well
          // avoid the duplicate notification by only notifying about the error state when it's
          // final.
          && (errorState == RequestState.SUCCESS || errorState == RequestState.FAILED);
    }
  }

  public override func isAnyResourceSet(): Bool {
    synchronized (requestLock) {
      return primary.isAnyResourceSet() || error.isAnyResourceSet();
    }
  }

  public override func onRequestSuccess(request: LoadRequest): Unit {
    AppLog.error("ErrorRequestCoordinator onRequestSuccess")
    synchronized (requestLock) {
      if (request.equals(primary)) {
        primaryState = RequestState.SUCCESS;
      } else if (request.equals(error)) {
        errorState = RequestState.SUCCESS;
      }
      if(match(parent) {
        case Some(x) => true
        case _ => false
      }) {
        parent.getOrThrow().onRequestSuccess(this);
      }
    //   if (parent != null) {
    //     parent.onRequestSuccess(this);
    //   }
    }
  }

  public override func onRequestFailed(request: LoadRequest): Unit {
    synchronized (requestLock) {
      if (!request.equals(error)) {
        primaryState = RequestState.FAILED;
        if (errorState != RequestState.RUNNING) {
          errorState = RequestState.RUNNING;
          error.begin();
        }
        return;
      }

      errorState = RequestState.FAILED;

    if(match(parent) {
        case Some(x) => true
        case _ => false
      }) {
        parent.getOrThrow().onRequestFailed(this);
      }
    //   if (parent != null) {
    //     parent.onRequestFailed(this);
    //   }
    }
  }

  public func getRoot(): RequestCoordinator {
    synchronized (requestLock) {
        if(match(parent) {
        case Some(x) => true
        case _ => false
      }) {
        return parent.getOrThrow().getRoot()
      } else {
        return this
      }
    //   return parent != null ? parent.getRoot() : this;
    }
  }

  public override func hashCode(): Int64 {
    Utils.hashCodeWrite(this.primary.hashCode(), reset: true)
    Utils.hashCodeWrite(this.error.hashCode(), reset: true)
    return Utils.hashCodeFinish()
  }

    public operator func ==(that: LoadRequest): Bool {
        return this.equals(that)
    }

    public operator func !=(that: LoadRequest): Bool {
        return !this.equals(that)
    }
}


public class ThumbnailRequestCoordinator <: RequestCoordinator & LoadRequest {
  private var parent: Option<RequestCoordinator> = None;
  private var requestLock: ReentrantMutex;

  private var full: LoadRequest = NoRequest();
  private var thumb: LoadRequest = NoRequest();

  private var fullStatecj: RequestState = RequestState.CLEARED;

  private var thumbStatecj: RequestState = RequestState.CLEARED;
  // Only used to check if the full request is cleared by the thumbnail request.
  private var isRunningDuringBegin: Bool = false;

  public func equals(that: LoadRequest): Bool {
    if(that is ThumbnailRequestCoordinator) {
        var t: ThumbnailRequestCoordinator = (that as ThumbnailRequestCoordinator).getOrThrow()
        return t.full.equals(this.full) && t.thumb.equals(this.thumb) && t.fullStatecj == this.fullStatecj && t.thumbStatecj == this.thumbStatecj
    } else {
        return false
    }
  }

  public init(requestLock: ReentrantMutex, parent: Option<RequestCoordinator>) {
    AppLog.error("ThumbnailRequestCoordinator init")
    this.requestLock = requestLock;
    this.parent = parent;
  }

  public func setRequests(full: LoadRequest, thumb: LoadRequest): Unit {
    this.full = full;
    this.thumb = thumb;
  }

  public override func canSetImage(request: LoadRequest): Bool {
    synchronized (requestLock) {
      return parentCanSetImage() && (request.equals(full) || fullStatecj != RequestState.SUCCESS);
    }
  }

  private func parentCanSetImage(): Bool {
    if(match(parent) {
        case Some(x) => false
        case _ => true
    }) {
        return true
    } else {
        return parent.getOrThrow().canSetImage(this);
    }
    // return parent == null || parent.canSetImage(this);
  }

  /**
   * Returns true if the request is the request loading the full size image and if neither the full
   * nor the thumbnail image have completed successfully.
   *
   * @param request {@inheritDoc}.
   */
  public override func canNotifyStatusChanged(request: LoadRequest): Bool {
    synchronized (requestLock) {
      return parentCanNotifyStatusChanged() && request.equals(full) && !isAnyResourceSet();
    }
  }

  public override func canNotifyCleared(request: LoadRequest): Bool {
    synchronized (requestLock) {
      return parentCanNotifyCleared() && request.equals(full) && fullStatecj != RequestState.PAUSED;
    }
  }

  private func parentCanNotifyCleared(): Bool {
    if(match(parent) {
        case Some(x) => false
        case _ => true
    }) {
        return true
    } else {
        return parent.getOrThrow().canNotifyCleared(this);
    }
    // return parent == null || parent.canNotifyCleared(this);
  }

  private func parentCanNotifyStatusChanged(): Bool {
    if(match(parent) {
        case Some(x) => false
        case _ => true
    }) {
        return true
    } else {
        return parent.getOrThrow().canNotifyStatusChanged(this);
    }
    // return parent == null || parent.canNotifyStatusChanged(this);
  }

  public override func isAnyResourceSet(): Bool {
    synchronized (requestLock) {
      return thumb.isAnyResourceSet() || full.isAnyResourceSet();
    }
  }

  public override func onRequestSuccess(request: LoadRequest): Unit {
    AppLog.error("ThumbnailRequestCoordinator onRequestSuccess")
    synchronized (requestLock) {
      if (request.equals(thumb)) {
        thumbStatecj = RequestState.SUCCESS;
        return;
      }
      fullStatecj = RequestState.SUCCESS;
      if(match(parent) {
        case Some(x) => true
        case _ => false
      }) {
        parent.getOrThrow().onRequestSuccess(this);
      }
    //   if (parent != null) {
    //     parent.onRequestSuccess(this);
    //   }
      // Clearing the thumb is not necessarily safe if the thumb is being displayed in the Target,
      // as a layer in a cross fade for example. The only way we know the thumb is not being
      // displayed and is therefore safe to clear is if the thumb request has not yet completed.
      if (!thumbStatecj.isComplete()) {
        AppLog.error("thumb is not complate")
        thumb.clear();
      } else {
        AppLog.error("thumb is complate")
      }
    }
  }

  public override func onRequestFailed(request: LoadRequest): Unit {
    synchronized (requestLock) {
      if (!request.equals(full)) {
        thumbStatecj = RequestState.FAILED;
        return;
      }
      fullStatecj = RequestState.FAILED;

    if(match(parent) {
        case Some(x) => true
        case _ => false
      }) {
        parent.getOrThrow().onRequestFailed(this);
      }
    //   if (parent != null) {
    //     parent.onRequestFailed(this);
    //   }
    }
  }

  public override func getRoot(): RequestCoordinator {
    synchronized (requestLock) {
        if(match(parent) {
        case Some(x) => true
        case _ => false
      }) {
        return parent.getOrThrow().getRoot()
      } else {
        return this
      }
    //   return parent != null ? parent.getRoot() : this;
    }
  }

  /** Starts first the thumb request and then the full request. */
  public override func begin(): Unit {
    synchronized (requestLock) {
      isRunningDuringBegin = true;
      try {
        if (fullStatecj != RequestState.SUCCESS && thumbStatecj != RequestState.RUNNING) {
          thumbStatecj = RequestState.RUNNING;
          AppLog.error("thumb.begins")
          thumb.begin();
        }
        if (isRunningDuringBegin && fullStatecj != RequestState.RUNNING) {
          fullStatecj = RequestState.RUNNING;
          AppLog.error("full.begins")
          full.begin();
        }
      } finally {
        isRunningDuringBegin = false;
      }
    }
  }

  public override func clear(): Unit {
    synchronized (requestLock) {
      isRunningDuringBegin = false;
      fullStatecj = RequestState.CLEARED;
      thumbStatecj = RequestState.CLEARED;
      thumb.clear();
      full.clear();
    }
  }

  public override func pause(): Unit {
    synchronized (requestLock) {
      if (!thumbStatecj.isComplete()) {
        thumbStatecj = RequestState.PAUSED;
        thumb.pause();
      }
      if (!fullStatecj.isComplete()) {
        fullStatecj = RequestState.PAUSED;
        full.pause();
      }
    }
  }

  public override func isRunning(): Bool {
    synchronized (requestLock) {
      return fullStatecj == RequestState.RUNNING;
    }
  }

  public override func isComplete(): Bool {
    synchronized (requestLock) {
      return fullStatecj == RequestState.SUCCESS;
    }
  }

  public override func isCleared(): Bool {
    synchronized (requestLock) {
      return fullStatecj == RequestState.CLEARED;
    }
  }

  public override func isEquivalentTo(o: LoadRequest): Bool {
    if (o is ThumbnailRequestCoordinator) {
      var that: ThumbnailRequestCoordinator = (o as ThumbnailRequestCoordinator).getOrThrow();
      return (if(full is NoRequest) {that.full is NoRequest} else {full.isEquivalentTo(that.full)}) && 
      (if(thumb is NoRequest) {that.thumb is NoRequest} else {thumb.isEquivalentTo(that.thumb)})
    //   return (full == null ? that.full == null : full.isEquivalentTo(that.full))
    //       && (thumb == null ? that.thumb == null : thumb.isEquivalentTo(that.thumb));
    }
    return false;
  }

  public override func hashCode(): Int64 {
    Utils.hashCodeWrite(this.full.hashCode(), reset: true)
    Utils.hashCodeWrite(this.thumb.hashCode(), reset: false)
    return Utils.hashCodeFinish()
  }

    public operator func ==(that: LoadRequest): Bool {
        return this.equals(that)
    }

    public operator func !=(that: LoadRequest): Bool {
        return !this.equals(that)
    }
}
