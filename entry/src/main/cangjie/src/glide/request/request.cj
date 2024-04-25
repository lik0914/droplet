package glide.request

from std import sync.*

/** A request that loads a resource for an {@link com.bumptech.glide.request.target.Target}. */
public interface LoadRequest <: Hashable & Equatable<LoadRequest> {
  /** Starts an asynchronous load. */
  func begin(): Unit;

  /**
   * Prevents any bitmaps being loaded from previous requests, releases any resources held by this
   * request, displays the current placeholder if one was provided, and marks the request as having
   * been cancelled.
   */
  func clear(): Unit;

  /**
   * Similar to {@link #clear} for in progress requests (or portions of a request), but does nothing
   * if the request is already complete.
   *
   * <p>Unlike {@link #clear()}, this method allows implementations to act differently on subparts
   * of a request. For example if a Request has both a thumbnail and a primary request and the
   * thumbnail portion of the request is complete, this method allows only the primary portion of
   * the request to be paused without clearing the previously completed thumbnail portion.
   */
  func pause(): Unit;

  /** Returns true if this request is running and has not completed or failed. */
  func isRunning(): Bool;

  /** Returns true if the request has completed successfully. */
  func isComplete(): Bool;

  /** Returns true if the request has been cleared. */
  func isCleared(): Bool;

  /**
   * Returns true if a resource is set, even if the request is not yet complete or the primary
   * request has failed.
   */
  func isAnyResourceSet(): Bool;

  /**
   * Returns {@code true} if this {@link Request} is equivalent to the given {@link Request} (has
   * all of the same options and sizes).
   *
   * <p>This method is identical to {@link Object#equals(Object)} except that it's specific to
   * {@link Request} subclasses. We do not use {@link Object#equals(Object)} directly because we
   * track {@link Request}s in collections like {@link java.util.Set} and it's perfectly legitimate
   * to have two different {@link Request} objects for two different {@link
   * com.bumptech.glide.request.target.Target}s (for example). Using a similar but different method
   * let's us selectively compare {@link Request} objects to each other when it's useful in specific
   * scenarios.
   */
  func isEquivalentTo(other: LoadRequest): Bool;

  func equals(that: LoadRequest): Bool;
}

public class NoRequest <: LoadRequest {
  public func begin(): Unit {}

  public func clear(): Unit {}

  public func pause(): Unit {}

  public func isRunning(): Bool {
    return false
  }

  public func isComplete(): Bool {
    return true
  }

  public func isCleared(): Bool {
    return true
  }

  public func isAnyResourceSet(): Bool {
    return false
  }

  public func isEquivalentTo(other: LoadRequest): Bool {
    return true
  }

  public func equals(that: LoadRequest): Bool {
    return true
  }

  public override func hashCode(): Int64 {
    return 0
  }

    public operator func ==(that: LoadRequest): Bool {
        return this.equals(that)
    }

    public operator func !=(that: LoadRequest): Bool {
        return !this.equals(that)
    }
}
