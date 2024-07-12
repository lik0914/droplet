/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
package glide

from std import collection.*
from ohos import base.*

public class RequestTracker {


  private var requests: HashSet<LoadRequest> = HashSet<LoadRequest>()
  // A set of requests that have not completed and are queued to be run again. We use this list to
  // maintain hard references to these requests to ensure that they are not garbage collected
  // before they start running or while they are paused. See #346.
  private var pendingRequests: HashSet<LoadRequest> = HashSet<LoadRequest>();

  private var isPaused: Bool = false;

  /** Starts tracking the given request. */
  public func runRequest(request: LoadRequest): Unit {
    requests.put(request);
    if (!isPaused) {
      request.begin();
    } else {
      request.clear();
    //   if (Log.isLoggable(TAG, Log.VERBOSE)) {
    //     Log.v(TAG, "Paused, delaying request");
    //   }
      pendingRequests.put(request);
    }
  }

  func addRequest(request: LoadRequest): Unit {
    requests.put(request);
  }

  /**
   * Stops tracking the given request, clears, and recycles it, and returns {@code true} if the
   * request was removed or invalid or {@code false} if the request was not found.
   */
  public func clearAndRemove(requestcj: LoadRequest): Bool {
    var isOwnedByUs: Bool = requests.remove(requestcj);
    // Avoid short circuiting.
    isOwnedByUs = pendingRequests.remove(requestcj) || isOwnedByUs;
    if (isOwnedByUs) {
      requestcj.clear();
    }
    return isOwnedByUs;
  }

  public func getPaused(): Bool {
    return isPaused;
  }

  /** Stops any in progress requests. */
  public func pauseRequests(): Unit {
    isPaused = true;
    for (request in Utils.getSnapshot<LoadRequest>(requests)) {
      if (request.isRunning()) {
        // Avoid clearing parts of requests that may have completed (thumbnails) to avoid blinking
        // in the UI, while still making sure that any in progress parts of requests are immediately
        // stopped.
        request.pause();
        pendingRequests.put(request);
      }
    }
  }

  /** Stops any in progress requests and releases bitmaps associated with completed requests. */
  public func pauseAllRequests(): Unit {
    isPaused = true;
    for (request in Utils.getSnapshot<LoadRequest>(requests)) {
      // TODO(judds): Failed requests return false from isComplete(). They're still restarted in
      //  resumeRequests, but they're not cleared here. We should probably clear all requests here?
      if (request.isRunning() || request.isComplete()) {
        request.clear();
        pendingRequests.put(request);
      }
    }
  }

  /** Starts any not yet completed or failed requests. */
  public func resumeRequests(): Unit {
    isPaused = false;
    for (request in Utils.getSnapshot<LoadRequest>(requests)) {
      // We don't need to check for cleared here. Any explicit clear by a user will remove the
      // Request from the tracker, so the only way we'd find a cleared request here is if we cleared
      // it. As a result it should be safe for us to resume cleared requests.
      if (!request.isComplete() && !request.isRunning()) {
        AppLog.error("request tracker resumeRequests: request begin")
        request.begin();
      }
    }
    pendingRequests.clear();
  }

  /**
   * Cancels all requests and clears their resources.
   *
   * <p>After this call requests cannot be restarted.
   */
  public func clearRequests(): Unit {
    AppLog.error("clearRequests requests size: ${requests.size}  pending: ${pendingRequests.size}")
    for (request in Utils.getSnapshot<LoadRequest>(requests)) {
      // It's unsafe to recycle the Request here because we don't know who might else have a
      // reference to it.
      clearAndRemove(request);
    }
    pendingRequests.clear();
  }

  /** Restarts failed requests and cancels and restarts in progress requests. */
  public func restartRequests(): Unit {
    for (request_cj in Utils.getSnapshot<LoadRequest>(requests)) {
      if (!request_cj.isComplete() && !request_cj.isCleared()) {
        request_cj.clear();
        if (!isPaused) {
          request_cj.begin();
        } else {
          pendingRequests.put(request_cj);
        }
      }
    }
  }

  public func toString(): String {
    return "{numRequests=${requests.size}, isPaused=${isPaused}}";
  }

}
