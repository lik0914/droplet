package glide

from std import sync.*
from std import io.*

public interface SizeReadyCallback {
    // 资源图片的原始尺寸
    func onSizeReady(width: Int64, height: Int64): Unit;
}

public interface AnyTarget <: LifecycleListener & Equatable<AnyTarget> {
  func onLoadStarted(placeholder: Option<CJResourceDrawable>): Unit;
  func onLoadFailed(placeholder: Option<CJResourceDrawable>): Unit;
  func onLoadCleared(placeholder: Option<CJResourceDrawable>): Unit;
  func getSize(cb: SizeReadyCallback): Unit;
   func removeCallback(): Unit;

  /** Sets the current request for this target to retain, should not be called outside of Glide. */
  func setRequest(request: Option<LoadRequest>): Unit;

  /** Retrieves the current request for this target, should not be called outside of Glide. */
  func getRequest(): Option<LoadRequest>;
}

public interface Target<R> <: AnyTarget {
  /**
   * The method that will be called when the resource load has finished.
   *
   * @param resource the loaded resource.
   */
  func onResourceReady(resource: R, transition: Option<DrawableTransition>): Unit;
}

public abstract class BaseTarget<R> <: Target<R> {

  protected var request: Option<LoadRequest> = None;

  public func setRequest(request: Option<LoadRequest>): Unit {
    this.request = request
  }

  public func getRequest(): Option<LoadRequest> {
    return this.request
  }

}
