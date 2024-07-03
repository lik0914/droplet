package glide

from std import math.*
from std import collection.*
from ohos import image.*
from ohos import ability.*

enum Status {
    /** Created but not yet running. */
    PENDING
    |
        /** In the process of fetching media. */
        RUNNING
    |
        /** Waiting for a callback given to the Target to be called to determine target dimensions. */
        WAITING_FOR_SIZE
    |
        /** Finished loading media successfully. */
        COMPLETE
    |
        /** Failed to load media, may be restarted. */
        FAILED
    |
        /** Cleared by the user with a placeholder set, may be restarted. */
        CLEARED
}

public interface AnySingleRequest {
    func getRequestListenersSize(): Int64
    func getRequestLock(): ReentrantMutex
    func getOverrideWidth(): Int64
    func getOverrideHeight(): Int64
    func getModel(): Model
    func getPriority(): Priority
    func getRequestOptions(): AnyRequestOptions
    func getUniqueCode(): Int64
}

/**
 * A {@link Request} that loads a {@link com.bumptech.glide.load.engine.Resource} into a given
 * {@link Target}.
 *
 * @param <R> The type of the resource that will be transcoded from the loaded resource.
 */
public class SingleRequest<R> <: AnySingleRequest & LoadRequest & SizeReadyCallback & ResourceCallback {
    /** Tag for logging internal events, not generally suitable for public use. */
    private static let TAG: String = "GlideRequest";
    /** Tag for logging externally useful events (request completion, timing etc). */
    private static let GLIDE_TAG: String = "Glide";

    private static let TARGET_SIZE_ORIGINAL: Int64 = -0x7fffffffffffffff;

    private static var STATIC_UNIQUE_CODE: Int64 = 0;
    private var UNIQUE_CODE: Int64 = 0

    private let stateVerifier: StateVerifier = StateVerifier.newInstance();

    /* Variables mutated only when a request is initialized or returned to the object pool. */
    private let requestLock: ReentrantMutex

    private let targetListener: RequestListener<R>

    private let requestCoordinator: Option<RequestCoordinator>

    private let context: AbilityContext

    private let glideContext: GlideContext

    private let model: Model

    private let transcodeTypeClass: TransformationKey

    private let requestOptions: AnyRequestOptions

    private let overrideWidth: Int64

    private let overrideHeight: Int64

    private let priority: Priority

    private let target: Target<R>

    private let requestListeners: ArrayList<RequestListener<R>>

    private var resource: Option<GlideResource<R>> = None;

    private var loadStatus: Option<LoadStatus> = None;

    // Volatile because it's accessed outside of a lock and nullable, even though in practice it will
    // always be non-null unless the request is in the object pool.

    private var engine: Engine

    /* Variables mutated during a request. */
    private var status: Status
    private var errorDrawable: Option<CJResourceDrawable> = None;
    private var placeholderDrawable: Option<CJResourceDrawable> = None;
    private var fallbackDrawable: Option<CJResourceDrawable> = None;
    private var width: Int64 = 0;
    private var height: Int64 = 0;
    private var isCallingCallbacks: Bool = false;

    public func isEquivalentTo(o: SingleRequest<R>): Bool {
        if (!(o is AnySingleRequest)) {
            return false;
        }

        var localOverrideWidth: Int64 = 0;
        var localOverrideHeight: Int64 = 0;
        var localModel: Model

        // TODO TranscodeTypeClass
        var localRequestOptions: AnyRequestOptions
        var localPriority: Priority
        var localListenerCount: Int64 = 0;
        synchronized(requestLock) {
            localOverrideWidth = overrideWidth
            localOverrideHeight = overrideHeight
            localModel = model
            localRequestOptions = requestOptions
            localPriority = priority
            localListenerCount = requestListeners.size
        }

        var other: AnySingleRequest = (o as AnySingleRequest).getOrThrow();
        var otherLocalOverrideWidth: Int64 = 0;
        var otherLocalOverrideHeight: Int64 = 0;
        var otherLocalModel: Model
        // TODO TranscodeTypeClass
        var otherLocalRequestOptions: AnyRequestOptions
        var otherLocalPriority: Priority
        var otherLocalListenerCount: Int64 = 0;
        synchronized(other.getRequestLock()) {
            otherLocalOverrideWidth = other.getOverrideWidth()
            otherLocalOverrideHeight = other.getOverrideHeight()
            otherLocalModel = other.getModel()
            otherLocalRequestOptions = other.getRequestOptions()
            otherLocalPriority = other.getPriority()
            otherLocalListenerCount = other.getRequestListenersSize()
        }

        // If there's ever a case where synchronization matters for these values, something else has
        // gone wrong. It indicates that we'er comparing at least one recycled object, which has to be
        // protected against via other means. None of these values changes aside from object re-use.
        return localOverrideWidth == otherLocalOverrideWidth
            && localOverrideHeight == otherLocalOverrideHeight
            && localModel == otherLocalModel
            // TODO TranscodeTypeClass
            && localRequestOptions.equals(otherLocalRequestOptions)
            && localPriority == otherLocalPriority
            && localListenerCount == otherLocalListenerCount;
    }

    public operator func ==(that: ResourceCallback): Bool {
        if (that is SingleRequest<R>) {
            let other = (that as SingleRequest<R>).getOrThrow()
            return equals(other)
        }
        return false
    }

    public operator func !=(that: ResourceCallback): Bool {
        if (that is SingleRequest<R>) {
            let other = (that as SingleRequest<R>).getOrThrow()
            return !equals(other)
        }
        return true
    }


    public static func obtain<R2>(
        context: AbilityContext,
        glideContext: GlideContext,
        requestLock: ReentrantMutex,
        model: Model,
        transcodeTypeClass: TransformationKey,
        requestOptions: AnyRequestOptions,
        overrideWidth: Int64,
        overrideHeight: Int64,
        priority: Priority,
        target: Target<R2>,
        targetListener: RequestListener<R2>,
        requestListeners: ArrayList<RequestListener<R2>>,
        requestCoordinator: Option<RequestCoordinator>,
        engine: Engine
    ): SingleRequest<R2> {
        return SingleRequest<R2>(
            context,
            glideContext,
            requestLock,
            model,
            transcodeTypeClass,
            requestOptions,
            overrideWidth,
            overrideHeight,
            priority,
            target,
            targetListener,
            requestListeners,
            requestCoordinator,
            engine
        );
    }

    // We are in fact locking on the same lock that will be used for all subsequent method calls.
    public init(
        context: AbilityContext,
        glideContext: GlideContext,
        requestLock: ReentrantMutex,
        model: Model,
        transcodeTypeClass: TransformationKey,
        requestOptionscj: AnyRequestOptions,
        overrideWidth: Int64,
        overrideHeight: Int64,
        priority: Priority,
        targetcj: Target<R>,
        targetListener: RequestListener<R>,
        requestListeners: ArrayList<RequestListener<R>>,
        requestCoordinatorcj: Option<RequestCoordinator>,
        engine: Engine
    ) {
        this.requestLock = requestLock
        this.context = context
        this.glideContext = glideContext
        this.model = model
        this.transcodeTypeClass = transcodeTypeClass
        this.requestOptions = requestOptionscj
        this.overrideWidth = overrideWidth
        this.overrideHeight = overrideHeight
        this.priority = priority
        this.target = targetcj
        this.targetListener = targetListener
        this.requestListeners = requestListeners
        this.requestCoordinator = requestCoordinatorcj
        this.engine = engine
        status = Status.PENDING

        UNIQUE_CODE = STATIC_UNIQUE_CODE
        STATIC_UNIQUE_CODE = STATIC_UNIQUE_CODE + 1
    }

    public func getRequestListenersSize(): Int64 {
        return requestListeners.size
    }

    public func getRequestLock(): ReentrantMutex {
        return requestLock
    }

    public func getOverrideWidth(): Int64 {
        return overrideWidth
    }

    public func getOverrideHeight(): Int64 {
        return overrideHeight
    }

    public func getModel(): Model {
        return model
    }

    public func getPriority(): Priority {
        return priority
    }

    public func getRequestOptions(): AnyRequestOptions {
        return requestOptions
    }

    public override func begin(): Unit {
        synchronized(requestLock) {
            assertNotCallingCallbacks();
            stateVerifier.throwIfRecycled();

            if (match (status) {
                case Status.RUNNING => true
                case _ => false
            }) {
                throw IllegalArgumentException("Cannot restart a running request");
            }

            if (match (status) {
                case Status.COMPLETE => true
                case _ => false
            }) {
                onResourceReady((resource.getOrThrow() as AnyGlideResource), DataSource.MEMORY_CACHE, /* isLoadedFromAlternateCacheKey= */ false);
                return;
            }

            // Restarts for requests that are neither complete nor running can be treated as new requests
            // and can run again from the beginning.
            // 非完成和未开始的请求重新启动视为新请求  glide暂时不用废弃
            status = Status.WAITING_FOR_SIZE
            AppLog.error("request size: ${overrideWidth}  ${overrideHeight}")
            if (Utils.isValidDimensions(overrideWidth, overrideHeight)) {
                onSizeReady(overrideWidth, overrideHeight);
            } else {
                target.getSize(this);
            }

            let ffff = match (status) {
                case Status.RUNNING => "RUNNING"
                case Status.WAITING_FOR_SIZE => "WAITING_FOR_SIZE"
                case Status.COMPLETE => "COMPLETE"
                case Status.FAILED => "FAILED"
                case Status.CLEARED => "CLEARED"
                case _ => "OTHER"
            }
            AppLog.error("single request begin: ${ffff} ----  ${canNotifyStatusChanged()}")
            if ((match (status) {
                case Status.RUNNING | Status.WAITING_FOR_SIZE => true
                case _ => false
            }) && canNotifyStatusChanged()) {
                let d: Option<CJResourceDrawable> = getPlaceholderDrawable()
                if (match (d) {
                    case Some(x) => true
                    case _ => false
                }) {
                    target.onLoadStarted(Some(d.getOrThrow()));
                } else {
                    target.onLoadStarted(Option<CJResourceDrawable>.None)
                }
            }
        }
    }

    /**
     * Cancels the current load but does not release any resources held by the request and continues
     * to display the loaded resource if the load completed before the call to cancel.
     *
     * <p>Cancelled requests can be restarted with a subsequent call to {@link #begin()}.
     *
     * @see #clear()
     */
    private func cancel(): Unit {
        AppLog.error("singleRequest cancel")
        assertNotCallingCallbacks();
        stateVerifier.throwIfRecycled();
        target.removeCallback();

        // TODO Engine
        if (match (loadStatus) {
            case Some(x) => true
            case _ => false
        }) {
            loadStatus.getOrThrow().cancel()
            loadStatus = None
        }
    }

    // Avoids difficult to understand errors like #2413.
    private func assertNotCallingCallbacks(): Unit {
        if (isCallingCallbacks) {
            throw IllegalStateException(
                """
          You can't start or clear loads in RequestListener or 
          Target callbacks. If you're trying to start a fallback request when a load fails, 
          use RequestBuilder#error(RequestBuilder). Otherwise consider posting your into()
         or clear() calls to the main thread using a Handler instead."""
            );
        }
    }

    /**
     * Cancels the current load if it is in progress, clears any resources held onto by the request
     * and replaces the loaded resource if the load completed with the placeholder.
     *
     * <p>Cleared requests can be restarted with a subsequent call to {@link #begin()}
     *
     * @see #cancel()
     */
    public override func clear(): Unit {
        AppLog.error("singleRequest clear")
        var toRelease: Option<GlideResource<R>> = None;
        synchronized(requestLock) {
            assertNotCallingCallbacks();
            stateVerifier.throwIfRecycled();

            let ffff = match (status) {
                case Status.RUNNING => "RUNNING"
                case Status.WAITING_FOR_SIZE => "WAITING_FOR_SIZE"
                case Status.COMPLETE => "COMPLETE"
                case Status.FAILED => "FAILED"
                case Status.CLEARED => "CLEARED"
                case _ => "OTHER"
            }
            AppLog.error("single request clear: ${ffff}")

            if (match (status) {
                case Status.CLEARED => true
                case _ => false
            }) {
                return;
            }
            cancel();
            // Resource must be released before canNotifyStatusChanged is called.
            if (match (resource) {
                case Some(x) => true
                case _ => false
            }) {
                toRelease = resource
                resource = None
            }
            if (canNotifyCleared()) {
                target.onLoadCleared(getPlaceholderDrawable());
            }

            status = Status.CLEARED
        }

        if (match (toRelease) {
            case Some(x) => true
            case _ => false
        }) {
            // Engine
            engine.release(toRelease.getOrThrow());
        }
    }

    public override func pause(): Unit {
        synchronized(requestLock) {
            if (isRunning()) {
                clear();
            }
        }
    }

    public override func isRunning(): Bool {
        synchronized(requestLock) {
            return (match (status) {
                case Status.RUNNING => true
                case _ => false
            } || match (status) {
                case Status.WAITING_FOR_SIZE => true
                case _ => false
            })
        }
    }

    public override func isComplete(): Bool {
        synchronized(requestLock) {
            return match (status) {
                case Status.COMPLETE => true
                case _ => false
            }
        }
    }

    public override func isCleared(): Bool {
        synchronized(requestLock) {
            return match (status) {
                case Status.CLEARED => true
                case _ => false
            }
        }
    }

    public override func isAnyResourceSet(): Bool {
        synchronized(requestLock) {
            return match (status) {
                case Status.COMPLETE => true
                case _ => false
            }
        }
    }

    public func getErrorDrawable(): Option<CJResourceDrawable> {
        return requestOptions.getErrorPlaceholderDrawable();
    }

    public func getPlaceholderDrawable(): Option<CJResourceDrawable> {
        return requestOptions.getPlaceholderDrawable();
    }


    public func setErrorPlaceholder(): Unit {
        if (!canNotifyStatusChanged()) {
            return;
        }

        var error: Option<CJResourceDrawable> = None;
        // Either the model isn't null, or there was no fallback drawable set.
        if (match (error) {
            case Some(x) => false
            case _ => true
        }) {
            error = getErrorDrawable()
        }
        // The model isn't null, no fallback drawable was set or no error drawable was set.
        if (match (error) {
            case Some(x) => false
            case _ => true
        }) {
            error = getPlaceholderDrawable()
        }

        if (match (error) {
            case Some(x) => false
            case _ => true
        }) {
            target.onLoadFailed(Option<CJResourceDrawable>.None);
        } else {
            target.onLoadFailed(Some(error.getOrThrow()));
        }
    }

    /** A callback method that should never be invoked directly. */
    public override func onSizeReady(width: Int64, height: Int64): Unit {
        AppLog.error("single request onSizeReady")
        stateVerifier.throwIfRecycled();
        synchronized(requestLock) {

            if (match (status) {
                case Status.WAITING_FOR_SIZE => false
                case _ => true
            }) {
                return;
            }
            status = Status.RUNNING

            var sizeMultiplier: Float32 = requestOptions.getSizeMultiplier();
            this.width = maybeApplySizeMultiplier(width, sizeMultiplier)
            this.height = maybeApplySizeMultiplier(height, sizeMultiplier)

            AppLog.error("width - height: ${this.width} - ${this.height}")


            // TODO Engine
            loadStatus = engine.load(
                glideContext,
                requestOptions.getSignature(),
                model,
                this.width,
                this.height,
                requestOptions.getResourceTypeClass(),
                transcodeTypeClass,
                requestOptions.getDiskCacheStrategy(),
                requestOptions.getTransformations(),
                requestOptions.getTransformationRequired(),
                requestOptions.getScaleOnlyOrNoTransform(),
                requestOptions.getOptions(),
                requestOptions.getCacheable(),
                requestOptions.getOnlyRetrieveFromCache(),
                this
            )

            // This is a hack that's only useful for testing right now where loads complete synchronously
            // even though under any executor running on any thread but the main thread, the load would
            // have completed asynchronously.
            // 这是一个现在只对测试加载同步完成有用的破解，即使在除主线程外的任何线程上运行的任何执行器下，加载都会异步完成。
            if (match (status) {
                case Status.RUNNING => false
                case _ => true
            }) {
                loadStatus = None
            }
        }
    }

    private static func maybeApplySizeMultiplier(size: Int64, sizeMultiplier: Float32): Int64 {
        return if (size == TARGET_SIZE_ORIGINAL) {
            size
        } else {
            Int64(round(sizeMultiplier * Float32(size)))
        }
    }

    private func canSetResource(): Bool {
        if (match (requestCoordinator) {
            case Some(x) => false
            case _ => true
        }) {
            return true
        }
        return requestCoordinator.getOrThrow().canSetImage(this);
    }

    private func canNotifyCleared(): Bool {
        if (match (requestCoordinator) {
            case Some(x) => false
            case _ => true
        }) {
            return true
        }
        return requestCoordinator.getOrThrow().canNotifyCleared(this);
    }

    private func canNotifyStatusChanged(): Bool {
        if (match (requestCoordinator) {
            case Some(x) => false
            case _ => true
        }) {
            return true
        }
        return requestCoordinator.getOrThrow().canNotifyStatusChanged(this);
    }

    private func isFirstReadyResource(): Bool {
        if (match (requestCoordinator) {
            case Some(x) => false
            case _ => true
        }) {
            return true
        }
        return !requestCoordinator.getOrThrow().getRoot().isAnyResourceSet()
    }

    private func notifyRequestCoordinatorLoadSucceeded(): Unit {
        if (match (requestCoordinator) {
            case Some(x) => true
            case _ => false
        }) {
            AppLog.error("notifyRequestCoordinatorLoadSucceeded has requestCoordinator")
            requestCoordinator.getOrThrow().onRequestSuccess(this);
        } else {
            AppLog.error("notifyRequestCoordinatorLoadSucceeded nothas requestCoordinator")
        }
    }

    private func notifyRequestCoordinatorLoadFailed(): Unit {
        if (match (requestCoordinator) {
            case Some(x) => true
            case _ => false
        }) {
            requestCoordinator.getOrThrow().onRequestFailed(this);
        }
    }

    /** A callback method that should never be invoked directly. */
    public override func onResourceReady(resource: Option<AnyGlideResource>, dataSource: DataSource,
        isLoadedFromAlternateCacheKey: Bool): Unit {
        stateVerifier.throwIfRecycled();

        let fff = match (status) {
            case Status.RUNNING => "RUNNING"
            case Status.WAITING_FOR_SIZE => "WAITING_FOR_SIZE"
            case Status.COMPLETE => "COMPLETE"
            case Status.FAILED => "FAILED"
            case Status.CLEARED => "CLEARED"
            case _ => "OTHER"
        }

        var toRelease: Option<AnyGlideResource> = None;
        synchronized(requestLock) {
            try {
                if (match (resource) {
                    case Some(x) => false
                    case _ => true
                }) {
                    // TODO onLoadFailed
                    var exception: GlideException = GlideException(
                        "Expected to receive a Resource<R> with an object of ${transcodeTypeClass} inside, but instead got null."
                    );
                    onLoadFailed(exception);
                    return;
                }

                var received: Any = resource.getOrThrow().getAsAny();

                // TODO 解码类型和资源类型不同的情况 正常应该执行不到

                if (!canSetResource()) {
                    toRelease = resource
                    this.resource = None
                    // We can't put the status to complete before asking canSetResource().
                    AppLog.error("status = Status.COMPLETE")
                    status = Status.COMPLETE
                    return;
                }

                let a: Option<GlideResource<R>> = resource.getOrThrow() as GlideResource<R>

                var b: Option<R> = received as R

                // transcode
                var s: Option<InputStream> = None
                var g: Option<GifDrawable> = None
                var pixelMap: Option<PixelMap> = None
                if (received is PixelMap) {
                    AppLog.error("received is PixelMap")
                    pixelMap = received as PixelMap
                } else if (received is InputStream) {
                    AppLog.error("received is InputStream")
                    s = received as InputStream
                } else if (received is GifDrawable) {
                    AppLog.error("received is GifDrawable")
                    g = received as GifDrawable

                    if (transcodeTypeClass == TransformationKey(TransformationKey.TRANSFORMATION_PIXELMAP)) {
                        pixelMap = Some(g.getOrThrow().getCurrentFrame())
                    } else {
                        // 从内存加载的Drawable
                        if (match (dataSource) {
                            case MEMORY_CACHE => true
                            case _ => false
                        }) {
                            // TODO 复制一个新的GifDrawable
                        }
                    }
                } else if (received is PixelMapDrawable) {
                    AppLog.error("received is PixelMapDrawable")
                    // 从内存加载的Drawable
                    if (match (dataSource) {
                        case MEMORY_CACHE => true
                        case _ => false
                    }) {
                        // TODO 复制一个新的PixelMapDrawable
                    }
                }

                // 文件下载
                if (match (s) {
                    case Some(x) => true
                    case _ => false
                }) {
                    if (transcodeTypeClass == TransformationKey(TransformationKey.TRANSFORMATION_PIXELMAP)) {
                        let inputStream: InputStream = s.getOrThrow()
                        var size = match (inputStream as Seekable) {
                            case Some(v) => v.length
                            case None => 0
                        }
                        let buf: Array<UInt8> = Array<UInt8>(size, item: 0)

                        inputStream.read(buf)
                    }
                }

                // 图片显示
                if (match (pixelMap) {
                    case Some(x) => true
                    case _ => false
                }) {
                    b = pixelMap.getOrThrow() as R
                }

                if (match (b) {
                    case Some(x) => true
                    case _ => false
                }) {
                    AppLog.error("onResourceReady b not none ")
                } else {
                    AppLog.error("onResourceReady b is none ")
                }
                onResourceReady(a, b.getOrThrow(), dataSource);
            } finally {

                // TODO engine
                if (match (toRelease) {
                    case Some(x) => true
                    case _ => false
                }) {
                    engine.release(toRelease.getOrThrow())
                }
            }
        }
    }

    private func onResourceReady(resource: Option<GlideResource<R>>, result: R, dataSource: DataSource): Unit {
        // We must call isFirstReadyResource before setting status.
        var isFirstResource: Bool = isFirstReadyResource();
        AppLog.error("isFirstResource : ${isFirstResource}")
        AppLog.error("status = Status.COMPLETE")
        status = Status.COMPLETE
        this.resource = resource

        notifyRequestCoordinatorLoadSucceeded();

        isCallingCallbacks = true
        try {
            var anyListenerHandledUpdatingTarget: Bool = false;

            AppLog.error("anyListenerHandledUpdatingTarget : ${anyListenerHandledUpdatingTarget}")
            if (!requestListeners.isEmpty()) {
                AppLog.error("!requestListeners.isEmpty()")
                for (listener in requestListeners) {
                    if (listener.onResourceReady(result, model, target, dataSource, isFirstResource)) {
                        anyListenerHandledUpdatingTarget = true
                    }
                }
            }

            AppLog.error("targetListener.onResourceReady")
            if (targetListener.onResourceReady(result, model, target, dataSource, isFirstResource)) {
                anyListenerHandledUpdatingTarget = true
            }

            if (!anyListenerHandledUpdatingTarget) {
                AppLog.error("target.onResourceReady")
                // TODO transition  animationFactory.build(dataSource, isFirstResource);
                let t: Option<DrawableTransition> = None
                target.onResourceReady(result, t);
            }
        } finally {
            isCallingCallbacks = false
        }

    }

    /** A callback method that should never be invoked directly. */
    public override func onLoadFailed(e: GlideException): Unit {
        onLoadFailed(e, 0);
    }

    public func getLock(): ReentrantMutex {
        stateVerifier.throwIfRecycled();
        return requestLock;
    }

    private func onLoadFailed(e: GlideException, maxLogLevel: Int64) {
        stateVerifier.throwIfRecycled();
        synchronized(requestLock) {

            loadStatus = None
            status = Status.FAILED

            notifyRequestCoordinatorLoadFailed();

            isCallingCallbacks = true
            try {
                // TODO: what if this is a thumbnail request?
                var anyListenerHandledUpdatingTarget: Bool = false;
                if (!requestListeners.isEmpty()) {
                    for (listener in requestListeners) {
                        if (listener.onLoadFailed(e, model, target, isFirstReadyResource())) {
                            anyListenerHandledUpdatingTarget = true
                        }
                    }
                }

                if (targetListener.onLoadFailed(e, model, target, isFirstReadyResource())) {
                    anyListenerHandledUpdatingTarget = true
                }

                if (!anyListenerHandledUpdatingTarget) {
                    setErrorPlaceholder();
                }
            } finally {
                isCallingCallbacks = false
            }
        }
    }

    public override func isEquivalentTo(o: LoadRequest): Bool {
        if (!(o is AnySingleRequest)) {
            return false;
        }

        var localOverrideWidth: Int64 = 0;
        var localOverrideHeight: Int64 = 0;
        var localModel: Model

        // TODO TranscodeTypeClass
        var localRequestOptions: AnyRequestOptions
        var localPriority: Priority
        var localListenerCount: Int64 = 0;
        synchronized(requestLock) {
            localOverrideWidth = overrideWidth
            localOverrideHeight = overrideHeight
            localModel = model
            localRequestOptions = requestOptions
            localPriority = priority
            localListenerCount = requestListeners.size
        }

        var other: AnySingleRequest = (o as AnySingleRequest).getOrThrow();
        var otherLocalOverrideWidth: Int64 = 0;
        var otherLocalOverrideHeight: Int64 = 0;
        var otherLocalModel: Model
        // TODO TranscodeTypeClass
        var otherLocalRequestOptions: AnyRequestOptions
        var otherLocalPriority: Priority
        var otherLocalListenerCount: Int64 = 0;
        synchronized(other.getRequestLock()) {
            otherLocalOverrideWidth = other.getOverrideWidth()
            otherLocalOverrideHeight = other.getOverrideHeight()
            otherLocalModel = other.getModel()
            otherLocalRequestOptions = other.getRequestOptions()
            otherLocalPriority = other.getPriority()
            otherLocalListenerCount = other.getRequestListenersSize()
        }

        // If there's ever a case where synchronization matters for these values, something else has
        // gone wrong. It indicates that we'er comparing at least one recycled object, which has to be
        // protected against via other means. None of these values changes aside from object re-use.
        return localOverrideWidth == otherLocalOverrideWidth
            && localOverrideHeight == otherLocalOverrideHeight
            && localModel == otherLocalModel
            // TODO TranscodeTypeClass
            && localRequestOptions.equals(otherLocalRequestOptions)
            && localPriority == otherLocalPriority
            // We do not want to require that RequestListeners implement equals/hashcode, so we
            // don't compare them using equals(). We can however, at least assert that the same
            // amount of request listeners are present in both requests.
            && localListenerCount == otherLocalListenerCount;
    }

    public func getUniqueCode(): Int64 {
        return UNIQUE_CODE
    }

    public func equals(that: LoadRequest): Bool {
        if (!(that is AnySingleRequest)) {
            return false;
        }
        let aa = isEquivalentTo(that)
        let bb = (UNIQUE_CODE == (that as AnySingleRequest).getOrThrow().getUniqueCode())
        return aa && bb
    }


    // TODO
    public func toString(): String {
        return "[model=TODO, transcodeClass=TODO] UNIQUE_CODE=${UNIQUE_CODE}"
    }

    public override func hashCode(): Int64 {
        return toString().hashCode()
    }

    public operator func ==(that: LoadRequest): Bool {
        return equals(that)
    }

    public operator func !=(that: LoadRequest): Bool {
        return !equals(that)
    }
}
