package glide

from std import fs.*
import glide.request.*
from std import collection.*
import glide.context.*
import glide.util.pool.*
import glide.util.*
import glide.lifecycle.*
import glide.manager.*
import glide.add.*

from ohos import image.*
from ohos import base.*

public class RequestManager <: ModelTypes<RequestBuilder<Drawable>> & LifecycleListener & Equatable<RequestManager> {
    private static let DECODE_TYPE_BITMAP: RequestOptions = RequestOptions.decodeTypeOf(ResourceTypeClass.RESOURCE_TYPE_PIXELMAP).lock();
    
    private static let DECODE_TYPE_GIF: RequestOptions = RequestOptions.decodeTypeOf(ResourceTypeClass.RESOURCE_TYPE_GIFDRAWABLE).lock();
    
    // private static let DOWNLOAD_ONLY_OPTIONS: RequestOptions = diskCacheStrategyOf(DiskCacheStrategy.DATA).priority(Priority.LOW).skipMemoryCache(true);
    private var requestOptions: RequestOptions

    protected let glide: Glide;
    protected let context: AbilityContext;
    public var requestManagerKey: String;
    public var lifecycle: Lifecycle;

    private let mtx = ReentrantMutex()

    // TODO CopyOnWriteArrayList
    private let defaultRequestListeners: ArrayList<RequestListener<Any>> = ArrayList<RequestListener<Any>>();

    private let requestTracker: RequestTracker;
    private let targetTracker: TargetTracker = TargetTracker();

    public init(glide: Glide, lifecycle: Lifecycle, context: AbilityContext, key: String) {
        this.context = context
        this.glide = glide
        this.lifecycle = lifecycle
        this.requestManagerKey = key
        var toSet = glide.getGlideContext().getDefaultRequestOptions()
        requestOptions = toSet.clone(toSet).autoClone();
        requestTracker = RequestTracker();
        lifecycle.addListener(this)
        glide.registerRequestManager(this);
    }

    public func compare(key: String): Bool {
        return this.requestManagerKey == Utils.getRequestManagerKey(key)
    }

    protected func setRequestOptions(toSet: RequestOptions) {
        synchronized(mtx) {
            requestOptions = toSet.clone(toSet).autoClone();
        }
    }

    private func updateRequestOptions(toUpdate: RequestOptions) {
        synchronized (mtx) {
            requestOptions = requestOptions.apply((toUpdate as AnyRequestOptions).getOrThrow(), requestOptions);
        }
    }

    public func useDefaultRequestOptions(requestOptions: RequestOptions): RequestManager {
        synchronized (mtx) {
            updateRequestOptions(requestOptions);
            return this;
        }
    }

    public func decodeAs<ResourceType>(transcodeTypeClass: TransformationKey): RequestBuilder<ResourceType> {
        return RequestBuilder<ResourceType>(glide, this, transcodeTypeClass, this.context);
    }

    public func decodeAsPixelMap() {
        return decodeAs<PixelMap>(TransformationKey(TransformationKey.TRANSFORMATION_PIXELMAP)).apply(DECODE_TYPE_BITMAP);
    }

    public func load(model: Model): RequestBuilder<Drawable> {
        return decodeAs<Drawable>(TransformationKey(TransformationKey.TRANSFORMATION_DRAWABLE)).load(model)
    }

    public func load(model: Array<UInt8>): RequestBuilder<Drawable> {
        return decodeAs<Drawable>(TransformationKey(TransformationKey.TRANSFORMATION_DRAWABLE)).load(model)
    }

    public func load(model: File): RequestBuilder<Drawable> {
        return decodeAs<Drawable>(TransformationKey(TransformationKey.TRANSFORMATION_DRAWABLE)).load(model)
    }

    public func load(model: fs.Path): RequestBuilder<Drawable> {
        return decodeAs<Drawable>(TransformationKey(TransformationKey.TRANSFORMATION_DRAWABLE)).load(model)
    }

    public func load(model: String): RequestBuilder<Drawable> {
        return decodeAs<Drawable>(TransformationKey(TransformationKey.TRANSFORMATION_DRAWABLE)).load(model)
    }

    public func getDefaultRequestListeners(): ArrayList<RequestListener<Any>> {
        return defaultRequestListeners;
    }

    public func clear(t: AnyTarget): Unit {
        untrackOrDelegate(t);
    }

    private func untrackOrDelegate(t: AnyTarget): Unit {
        var isOwnedByUs: Bool = untrack(t);

        var request: Option<LoadRequest> = t.getRequest();
        var requestNotNone: Bool = match(request) {
            case Some(x) => true
            case _ => false
        }
        if (!isOwnedByUs && !glide.removeFromManagers(t) && requestNotNone) {
            t.setRequest(Option<LoadRequest>.None);
            request.getOrThrow().clear();
        }
    }

    public func track(t: AnyTarget, request: LoadRequest) {
        synchronized(mtx) {
            targetTracker.track(t);
            requestTracker.runRequest(request);
        }
    }

    public func untrack(t: AnyTarget): Bool {
        AppLog.error("request manager untrack begin")
        synchronized(mtx) {
            var request: Option<LoadRequest> = t.getRequest();
            // If the Target doesn't have a request, it's already been cleared.
            if (match(request) {
                case Some(x) => false
                case _ => true
            }) {
                return true;
            }
            
            if (requestTracker.clearAndRemove(request.getOrThrow())) {
                targetTracker.untrack(t);
                t.setRequest(Option<LoadRequest>.None);
                return true;
            } else {
                return false;
            }
            return false
        }
    }

    public override func onStart(): Unit {
        AppLog.error("manager ${requestManagerKey} onStart");
        synchronized(mtx) {
            resumeRequests();
            targetTracker.onStart();
        }
    }

    public func resumeRequests(): Unit {
        synchronized(mtx) {
            requestTracker.resumeRequests();
        }
    }

    public override func onStop(): Unit {
        AppLog.error("manager ${requestManagerKey} onStop");
        synchronized(mtx) {
            pauseRequests();
            targetTracker.onStop();
        }
    }

    public func pauseRequests(): Unit {
        synchronized(mtx) {
            requestTracker.pauseRequests();
        }
    }

    public func pauseAllRequests(): Unit {
        synchronized(mtx) {
            requestTracker.pauseAllRequests();
        }
    }

    public override func onDestroy(): Unit {
        AppLog.error("manager ${requestManagerKey} onDestroy");
        synchronized(mtx) {
            try {
                targetTracker.onDestroy();
                for (target in targetTracker.getAll()) {
                    clear(target);
                }
                targetTracker.clear();
                requestTracker.clearRequests();
                lifecycle.removeListener(this);
                // TODO 网络管理
                // lifecycle.removeListener(connectivityMonitor);
                glide.unregisterRequestManager(this);
            } catch(e: Exception) {
                AppLog.error("request manager error: ${e}")
                throw e
            }
            
        }
    }

    public func onTrimMemory(level: Int64): Unit {
        AppLog.error("manager ${requestManagerKey} onTrimMemory: ${level}");
        if (level == 0) {
            // 暂停请求
            pauseAllRequests();
        }
    }

    public override func hashCode(): Int64 {
        return requestManagerKey.hashCode()
    }

    public operator func ==(that: LifecycleListener): Bool {
        if(that is RequestManager) {
            return this.requestManagerKey == (that as RequestManager).getOrThrow().requestManagerKey
        }
        return false
    }

    public operator func !=(that: LifecycleListener): Bool {
        if(that is RequestManager) {
            return this.requestManagerKey != (that as RequestManager).getOrThrow().requestManagerKey
        }
        return true
    }

    public operator func ==(that: RequestManager): Bool {
        return this.requestManagerKey == that.requestManagerKey
    }

    public operator func !=(that: RequestManager): Bool {
        return this.requestManagerKey != that.requestManagerKey
    }

}
