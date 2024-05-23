package glide

from std import fs.*
from std import io.*

from ohos import component.*

// public class TranscodeTypeClass <: Hashable & Equatable<TranscodeTypeClass> {

//     public static let TRANSCODE_TYPE_NONE: Int64 = 0
//     public static let TRANSCODE_TYPE_ARRAY: Int64 = 1
//     public static let TRANSCODE_TYPE_PIXELMAP: Int64 = 2
    
//     // 1 ARRAY  2 PIXELMAP
//     public var transcodeType: Int64 = TRANSCODE_TYPE_NONE

//     public init(transcodeType: Int64) {
//         this.transcodeType = transcodeType
//     }

//     public func hashCode(): Int64 {
//         return this.transcodeType.hashCode()
//     }

//     public operator func ==(that: TranscodeTypeClass): Bool {
//         return this.transcodeType == that.transcodeType
//     }

//     public operator func !=(that: TranscodeTypeClass): Bool {
//         return this.transcodeType != that.transcodeType
//     }
// }

public class NormalImgRequestListener<T> <: RequestListener<T> {
    public var resourceFn: (T, Model, Target<T>, DataSource, Bool) -> Bool
    public var failedFn: (GlideException, Model, Target<T>, Bool) -> Bool

    public init(resourceFn: (T, Model, Target<T>, DataSource, Bool) -> Bool, failedFn: (GlideException, Model, Target<T>, Bool) -> Bool) {
      this.resourceFn = resourceFn
      this.failedFn = failedFn
    }

    public func onLoadFailed(e: GlideException, model: Model, target: Target<T>, isFirstResource: Bool): Bool {
        return this.failedFn(e, model, target, isFirstResource)
    }

    public func onResourceReady(resource: T, model: Model, target: Target<T>, dataSource: DataSource, isFirstResource: Bool): Bool {
        return this.resourceFn(resource, model, target, dataSource, isFirstResource)
    }

}

public interface AnyRequestBuilder <: AnyRequestOptions {
    func getModel(): Option<Model>
    func getThumbnailBuilder(): Option<AnyRequestBuilder>
    func getErrorBuilder(): Option<AnyRequestBuilder>
    func getThumbSizeMultiplier(): Float32
    func getDefaultTransitionOptionsSet(): Bool
    func getModelSet(): Bool;
    func getContext(): AbilityContext;
    func getGlide(): Glide;
    func getRequestManager(): RequestManager;

    func getOverrideWidth(): Int64
    func getOverrideHeight(): Int64
}

public class RequestBuilder<TranscodeType> <: BaseRequestOptions<RequestBuilder<TranscodeType>> 
& AnyRequestBuilder 
& ModelTypes<RequestBuilder<TranscodeType>>
& Equatable<RequestBuilder<TranscodeType>>
& Cloneable<RequestBuilder<TranscodeType>> {

    protected static var DOWNLOAD_ONLY_OPTIONS: Option<RequestOptions> = None

    public var model: Option<Model> = None

    public var isModelSet: Bool = false

    public var context: AbilityContext;

    public var glide: Glide;
    public var glideContext: GlideContext;
    public var requestManager: RequestManager

    public var transcodeTypeClass: TransformationKey

    public var requestListeners: ArrayList<RequestListener<TranscodeType>> = ArrayList<RequestListener<TranscodeType>>();
    public var thumbnailBuilder: Option<RequestBuilder<TranscodeType>> = None;
    public var errorBuilder: Option<RequestBuilder<TranscodeType>> = None;

    public var isThumbnailBuilt: Bool = false;

    public var isDefaultTransitionOptionsSet: Bool = true;

    public var thumbSizeMultiplier: Float32 = 0.0;

    public init(glide: Glide, requestManager: RequestManager, transcodeTypeClass: TransformationKey, context: AbilityContext) {
        this.glide = glide
        this.requestManager = requestManager
        this.transcodeTypeClass = transcodeTypeClass
        this.glideContext = glide.getGlideContext();
        this.context = context

        initRequestListeners(requestManager.getDefaultRequestListeners());
        this.requestListeners = ArrayList<RequestListener<TranscodeType>>()
        // apply(requestManager.getDefaultRequestOptions());

        var o = RequestOptions()

        o = o.setDiskCacheStrategy(DiskCacheStrategyDATA(), o)
        //   .priority(Priority.LOW)
        // AppLog.error("requestbuilder init setDiskCacheStrategy: ${o.getDiskCacheStrategy()}")
        o = o.skipMemoryCache(true, o);
        // AppLog.error("requestbuilder init skipMemoryCache: ${o.getDiskCacheStrategy()} ${o.getCacheable()}")
        
        DOWNLOAD_ONLY_OPTIONS = Some(o)
        // AppLog.error("requestbuilder init DOWNLOAD_ONLY_OPTIONS: ${DOWNLOAD_ONLY_OPTIONS.getOrThrow().getDiskCacheStrategy()}")
    }

    public init(transcodeTypeClass: TransformationKey, other: AnyRequestBuilder) {
        this(other.getGlide(), other.getRequestManager(), transcodeTypeClass, other.getContext());
        model = other.getModel();
        isModelSet = other.getModelSet();

        if(other is RequestBuilder<TranscodeType>) {
            AppLog.error("init requestOptions is RequestBuilder<TranscodeType>")
        }

        // This is safe because it will always mutate, no one else has access to the object.
        // AppLog.error("apply1: ${(other as AnyRequestOptions).getOrThrow().getOptions()}")
        apply(other);
        // AppLog.error("apply1 after: ${(this as AnyRequestOptions).getOrThrow().getOptions()}")
    }

    public func getContext(): AbilityContext {
        return context;
    }

    public func getGlide(): Glide {
        return glide
    }

    public func getRequestManager(): RequestManager {
        return requestManager
    }
    
    public func load(model: Model): RequestBuilder<TranscodeType> {
        return loadGeneric(model)
    }

    public func load(model: Array<UInt8>): RequestBuilder<TranscodeType> {
        return loadGeneric(LoadModel(model))
    }

    public func load(model: fs.Path): RequestBuilder<TranscodeType> {
        return loadGeneric(LoadModel(model))
    }

    public func load(model: File): RequestBuilder<TranscodeType> {
        return loadGeneric(LoadModel(model))
    }

    public func load(model: String): RequestBuilder<TranscodeType> {
        return loadGeneric(LoadModel(model))
    }

    public func clone(): RequestBuilder<TranscodeType> {
        return super.clone(RequestBuilder<TranscodeType>(this.glide, this.requestManager, this.transcodeTypeClass, this.context))
    }

    public func cloneBuilder(): RequestBuilder<TranscodeType> {
        AppLog.error("cloneBuilder before:  ${this.thumbSizeMultiplier}")
        var r: RequestBuilder<TranscodeType> = this.clone()
        r.model = this.model
        r.isModelSet = this.isModelSet
        r.context = this.context
        r.glideContext = this.glideContext
        r.requestManager = this.requestManager
        r.transcodeTypeClass = this.transcodeTypeClass
        r.isThumbnailBuilt = this.isThumbnailBuilt;
        r.isDefaultTransitionOptionsSet = this.isDefaultTransitionOptionsSet;
        r.thumbSizeMultiplier = this.thumbSizeMultiplier;
        AppLog.error("cloneBuilder  ${r.diskCacheStrategy} ${this.diskCacheStrategy}")
        return r
    }

    public func loadGeneric(model: Model): RequestBuilder<TranscodeType> {
        if (getIsAutoCloneEnabled()) {
            // AppLog.error("getIsAutoCloneEnabled")
            return cloneBuilder().loadGeneric(model);
        }
        this.model = Some(model);
        this.isModelSet = true;
        return selfOrThrowIfLocked();
    }

    public operator func ==(that: RequestBuilder<TranscodeType>): Bool {
        return this.equals(that)
    }

    public operator func !=(that: RequestBuilder<TranscodeType>): Bool {
        return !this.equals(that)
    }

    public func equals(o: Any): Bool {
        if (o is AnyRequestBuilder && o is AnyRequestOptions) {
        var that: AnyRequestBuilder = (o as AnyRequestBuilder).getOrThrow();
        var thatSuper: AnyRequestOptions = (o as AnyRequestOptions).getOrThrow();

        return super.equals(thatSuper)
            // && Objects.equals(transcodeClass, that.transcodeClass)
            // && transitionOptions.equals(that.transitionOptions)
            && model == that.getModel() 
            // && Objects.equals(requestListeners, that.requestListeners)
            && Utils.optionEqualsNotSame<RequestBuilder<TranscodeType>, AnyRequestBuilder>(thumbnailBuilder, that.getThumbnailBuilder())
            && Utils.optionEqualsNotSame<RequestBuilder<TranscodeType>, AnyRequestBuilder>(errorBuilder, that.getErrorBuilder())
            && thumbSizeMultiplier == that.getThumbSizeMultiplier()
            && isDefaultTransitionOptionsSet == that.getDefaultTransitionOptionsSet()
            && isModelSet == that.getModelSet();
        }
        return false;
    }

    // TODO  apply改成useRequestOptions
    public func apply(requestOptions: AnyRequestOptions): RequestBuilder<TranscodeType> {
        AppLog.error("apply func before : ${this.getIsAutoCloneEnabled()}  --- ${this.thumbSizeMultiplier}")
        // let r: RequestBuilder<TranscodeType>
        // if(this.getIsAutoCloneEnabled()) {
        //     r = super.apply(requestOptions, cloneBuilder());
        // } else {
        //     r = super.apply(requestOptions, this);
        // }

        let r: RequestBuilder<TranscodeType> = super.apply(requestOptions, this);

        if(requestOptions is RequestBuilder<TranscodeType>) {
            AppLog.error("requestOptions is RequestBuilder<TranscodeType>")
        }

        // r.model = this.model
        // r.isModelSet = this.isModelSet
        // r.context = this.context
        // r.glideContext = this.glideContext
        // r.requestManager = this.requestManager
        // r.transcodeTypeClass = this.transcodeTypeClass
        // r.isThumbnailBuilt = this.isThumbnailBuilt;
        // r.isDefaultTransitionOptionsSet = this.isDefaultTransitionOptionsSet;
        // r.thumbSizeMultiplier = this.thumbSizeMultiplier;
         
        AppLog.error("apply func after : ${this.getIsAutoCloneEnabled()}  --- ${this.thumbSizeMultiplier}")
        return r
    }

    // public func apply(requestOptions: AnyRequestOptions): RequestBuilder<TranscodeType> {
    //     AppLog.error("apply before:  ${this.thumbSizeMultiplier}")
    //     // clone
    //     var r = RequestBuilder<TranscodeType>(this.glide, this.requestManager, this.transcodeTypeClass, this.context)
        
    //     // AppLog.error("apply  ${r.thumbSizeMultiplier} ${this.thumbSizeMultiplier}")
    //     // r.autoClone()

    //     r = super.apply(requestOptions, r);
    //     r.model = this.model
    //     r.isModelSet = this.isModelSet
    //     r.context = this.context
    //     r.glideContext = this.glideContext
    //     r.requestManager = this.requestManager
    //     r.transcodeTypeClass = this.transcodeTypeClass
    //     r.isThumbnailBuilt = this.isThumbnailBuilt;
    //     r.isDefaultTransitionOptionsSet = this.isDefaultTransitionOptionsSet;
    //     r.thumbSizeMultiplier = this.thumbSizeMultiplier;
    //     AppLog.error("apply after: ${r.thumbSizeMultiplier} ${this.thumbSizeMultiplier}")
    //     return r
    // }

    public func getModel(): Option<Model> {
        return model
    }

    public func getThumbnailBuilder(): Option<AnyRequestBuilder> {
        if(match(thumbnailBuilder) {
            case Some(x) => false
            case _ => true
        }) {
            return None
        }
        return (thumbnailBuilder.getOrThrow() as AnyRequestBuilder)
    }

    public func getErrorBuilder(): Option<AnyRequestBuilder> {
        if(match(errorBuilder) {
            case Some(x) => false
            case _ => true
        }) {
            return None
        }
        return (errorBuilder.getOrThrow() as AnyRequestBuilder)
    }

    public func getThumbSizeMultiplier(): Float32 {
        return thumbSizeMultiplier
    }

    public func getDefaultTransitionOptionsSet(): Bool {
        return isDefaultTransitionOptionsSet
    }

    public func getModelSet(): Bool {
        return isModelSet
    }

    public func downloadOnly(): FutureTarget<InputStream> {
        return getDownloadOnlyRequest().submit(Downsampler.SIZE_ORIGINAL, Downsampler.SIZE_ORIGINAL);
    }

    public func downloadOnly(width: Int64, height: Int64): FutureTarget<InputStream> {
        AppLog.error("downloadOnly : ${this.thumbSizeMultiplier}")
        return getDownloadOnlyRequest().submit(width, height);
    }

    public func submit(width: Int64, height: Int64): FutureTarget<TranscodeType> {
        let target: RequestFutureTarget<TranscodeType> = RequestFutureTarget<TranscodeType>(width, height);
        return into(target, target);
    }

    public func submit(): FutureTarget<TranscodeType> {
        return submit(Downsampler.SIZE_ORIGINAL, Downsampler.SIZE_ORIGINAL);
    }

    public func getDownloadOnlyRequest(): RequestBuilder<InputStream> {
        var r = RequestBuilder<InputStream>(TransformationKey(TransformationKey.TRANSFORMATION_INPUTSTREAM), this)
        r = r.apply(DOWNLOAD_ONLY_OPTIONS.getOrThrow());
        return r
    }

    // 必须使用克隆，暂时去掉
    // public func thumbnail(thumbnails: ArrayList<RequestBuilder<TranscodeType>>): RequestBuilder<TranscodeType> {
    //     if (thumbnails.isEmpty()) {
    //         return thumbnail(Option<RequestBuilder<TranscodeType>>.None);
    //     }

    //     var previous: Option<RequestBuilder<TranscodeType>> = Option<RequestBuilder<TranscodeType>>.None;

    //     // Start with the lowest priority thumbnail so that we can safely handle mutations if
    //     // autoClone() is enabled by assigning the result of calling thumbnail() during the iteration.
    //     // Starting with the highest priority thumbnail would prevent us from assigning the result of
    //     // thumbnail because the mutated request wouldn't be used in the next iteration.
    //     var i: Int64 = thumbnails.size - 1
    //     while(i >= 0) {
    //         var current: RequestBuilder<TranscodeType> = thumbnails[i];
    //         if (match(previous) {
    //             case Some(x) => false
    //             case _ => true
    //         }) {
    //             // If we don't yet have our first non-null request, set it and continue.
    //             previous = current;
    //         } else {
    //             // Otherwise make our next lowest priority request the thumbnail of our current request.
    //             // 必须使用克隆
    //             previous = current.thumbnail(previous);
    //         }
    //         i--
    //     }
    //     return thumbnail(previous);
    // }

    public func thumbnail(thumbnailRequest: Option<RequestBuilder<TranscodeType>>): RequestBuilder<TranscodeType> {
        // if (isAutoCloneEnabled()) {
        // return clone().thumbnail(thumbnailRequest);
        // }
        this.thumbnailBuilder = thumbnailRequest;

        return self();
    }

    public func thumbnail(sizeMultiplier: Float32): RequestBuilder<TranscodeType> {
        AppLog.error("thumbnail : ${getIsAutoCloneEnabled()}")
        if (getIsAutoCloneEnabled()) {
            return cloneBuilder().thumbnail(sizeMultiplier);
        }
        if (sizeMultiplier < 0.0 || sizeMultiplier > 1.0) {
            throw IllegalArgumentException("sizeMultiplier must be between 0 and 1");
        }
        this.thumbSizeMultiplier = sizeMultiplier;

        return selfOrThrowIfLocked();
    }

    public func error(src: String): RequestBuilder<TranscodeType> {
        return error(LoadModel(src))
    }

    private func error(errorBuilder: Option<RequestBuilder<TranscodeType>>): RequestBuilder<TranscodeType> {
        // if (isAutoCloneEnabled()) {
        // return clone().error(errorBuilder);
        // }
        this.errorBuilder = errorBuilder;
        return self();
    }

    private func error(model: Model): RequestBuilder<TranscodeType> {
        // if (model == null) {
        // return error((RequestBuilder<TranscodeType>) null);
        // }
        return error(cloneWithNullErrorAndThumbnail().load(model));
    }

    private func cloneWithNullErrorAndThumbnail(): RequestBuilder<TranscodeType> {
        // return cloneBuilder()
        return cloneBuilder()
            .error(Option<RequestBuilder<TranscodeType>>.None)
            .thumbnail(Option<RequestBuilder<TranscodeType>>.None);
    }

    public func into(width: Int64, height: Int64): Target<TranscodeType> {
        let target: Target<TranscodeType> = (StringDrawableTarget(width, height) as Target<TranscodeType>).getOrThrow()
        return into<Target<TranscodeType>>(target);
    }

    public func into(f: (PixelMap) -> Unit, width: Int64, height: Int64): Target<TranscodeType> {
        let target: Target<TranscodeType> = (DrawableTarget(f, width, height) as Target<TranscodeType>).getOrThrow()
        return into<Target<TranscodeType>>(target);
    }

    public func into(f: (PixelMap) -> Unit, r: (CJResource,Bool) -> Unit, width: Int64, height: Int64): Target<TranscodeType> {
        let target: Target<TranscodeType> = (DrawableTarget(f, r, width, height) as Target<TranscodeType>).getOrThrow()
        return into<Target<TranscodeType>>(target);
    }

    public func into<Y>(target: Y): Y where Y <: Target<TranscodeType>  {
        return into(target, /*targetListener=*/ NoRequestListener<TranscodeType>());
    }

    public func into<Y>(target: Y, targetListener: RequestListener<TranscodeType>): Y where Y <: Target<TranscodeType> {
        return into(target, targetListener, /*options=*/ this);
    }

    public func into<Y, Y2>(target: Y, targetListener: RequestListener<TranscodeType>, options: Y2): Y where Y <: Target<TranscodeType>, Y2 <: BaseRequestOptions<Y2> & Cloneable<Y2> {
        if (!isModelSet) {
            throw IllegalArgumentException("You must call #load() before calling #into()");
        }

        var request: LoadRequest = buildRequest<Y2>(target, targetListener, options);

        var previous: Option<LoadRequest> = target.getRequest()
        if(match(previous) {
            case Some(x) => true
            case _ => false
        }) {
            if (request.isEquivalentTo(previous.getOrThrow()) && !isSkipMemoryCacheWithCompletePreviousRequest(options, previous.getOrThrow())) {
                // If the request is completed, beginning again will ensure the result is re-delivered,
                // triggering RequestListeners and Targets. If the request is failed, beginning again will
                // restart the request, giving it another chance to complete. If the request is already
                // running, we can let it continue running without interruption.

                // if (!Preconditions.checkNotNull(previous).isRunning()) {
                //     // Use the previous request rather than the new one to allow for optimizations like skipping
                //     // setting placeholders, tracking and un-tracking Targets, and obtaining View dimensions
                //     // that are done in the individual Request.
                //     previous.begin();
                // }
                if(!previous.getOrThrow().isRunning()) {
                    previous.getOrThrow().begin();
                }
                return target;
            }
        }

        requestManager.clear(target);
        target.setRequest(request);
        requestManager.track(target, request);

        return target;
    }

    private func isSkipMemoryCacheWithCompletePreviousRequest(options: AnyRequestOptions, previous: LoadRequest): Bool {
        return !options.getCacheable() && previous.isComplete();
    }

    private func buildRequest<Y2>(target: Target<TranscodeType>, targetListener: RequestListener<TranscodeType>, requestOptions: Y2) where Y2 <: BaseRequestOptions<Y2> & Cloneable<Y2> {
        return buildRequestRecursive<Y2>(
            /*requestLock=*/ ReentrantMutex(),
            target,
            targetListener,
            // /*parentCoordinator=*/ null,
            Option<RequestCoordinator>.None,
            // transitionOptions,
            requestOptions.getPriority(),
            requestOptions.getOverrideWidth(),
            requestOptions.getOverrideHeight(),
            requestOptions);
    }

    private func buildRequestRecursive<Y2>(
        requestLock: ReentrantMutex, 
        target: Target<TranscodeType>, 
        targetListener: RequestListener<TranscodeType>,
        parentCoordinator: Option<RequestCoordinator>,
        // transitionOptions: TransitionOptions<?, ? super TranscodeType> ,
        priority: Priority,
        overrideWidth: Int64,
        overrideHeight: Int64,
        requestOptions: Y2
        // callbackExecutor: Executor
        ): LoadRequest where Y2 <: BaseRequestOptions<Y2> & Cloneable<Y2> {

        // Build the ErrorRequestCoordinator first if necessary so we can update parentCoordinator.
        // errorRequestCoordinator: ErrorRequestCoordinator = null;
        // if (errorBuilder != null) {
        // errorRequestCoordinator = ErrorRequestCoordinator(requestLock, parentCoordinator);
        // parentCoordinator = errorRequestCoordinator;
        // }

        var mainRequest: LoadRequest;

        var errorRequestCoordinator: ErrorRequestCoordinator = ErrorRequestCoordinator(requestLock, parentCoordinator);

        if(let Some(x) <- errorBuilder){
            var parentCoordinator2: Option<RequestCoordinator> = Some(errorRequestCoordinator);
            
            mainRequest = buildThumbnailRequestRecursive<Y2>(requestLock,target,targetListener,parentCoordinator2,
                priority,overrideWidth,overrideHeight,requestOptions);
        } else {
            mainRequest = buildThumbnailRequestRecursive<Y2>(requestLock,target,targetListener,parentCoordinator,priority,
                overrideWidth,overrideHeight,requestOptions);
            return mainRequest;
        }

        var errorOverrideWidth: Int64 = errorBuilder.getOrThrow().getOverrideWidth();
        var errorOverrideHeight: Int64 = errorBuilder.getOrThrow().getOverrideHeight();
        if (Utils.isValidDimensions(overrideWidth, overrideHeight) && !errorBuilder.getOrThrow().isValidOverride()) {
            errorOverrideWidth = requestOptions.getOverrideWidth();
            errorOverrideHeight = requestOptions.getOverrideHeight();
        }

        var errorRequest: LoadRequest =
            errorBuilder.getOrThrow().buildRequestRecursive<RequestBuilder<TranscodeType>>(requestLock,target,targetListener,errorRequestCoordinator,
                errorBuilder.getOrThrow().getPriority(),errorOverrideWidth,errorOverrideHeight,errorBuilder.getOrThrow());
        errorRequestCoordinator.setRequests(mainRequest, errorRequest);
        return errorRequestCoordinator;
    }

    private func buildThumbnailRequestRecursive<Y2>(
        requestLock: ReentrantMutex,
        target: Target<TranscodeType>,
        targetListener: RequestListener<TranscodeType>,
        parentCoordinator: Option<RequestCoordinator>,
        // TransitionOptions<?, ? super TranscodeType> transitionOptions,
        priority: Priority,
        overrideWidth: Int64,
        overrideHeight: Int64,
        requestOptions: Y2
        // Executor callbackExecutor
        ): LoadRequest where Y2 <: BaseRequestOptions<Y2> & Cloneable<Y2> {
            AppLog.error("buildThumbnailRequestRecursive: thumbSizeMultiplier: ${thumbSizeMultiplier}")
            if(match(thumbnailBuilder) {
                case Some(x) => true
                case _ => false
            }) {
                 AppLog.error("thumbnailBuilder != null")
                // Recursive case: contains a potentially recursive thumbnail request builder.
                if (isThumbnailBuilt) {
                    throw IllegalStateException(
                        "You cannot use a request as both the main request and a "
                            + "thumbnail, consider using clone() on the request(s) passed to thumbnail()");
                }

        // TODO TransitionOptions
        // TransitionOptions<?, ? super TranscodeType> thumbTransitionOptions = thumbnailBuilder.getOrThrow().transitionOptions;
        

        // Apply our transition by default to thumbnail requests but avoid overriding custom options
        // that may have been applied on the thumbnail request explicitly.
        if (thumbnailBuilder.getOrThrow().isDefaultTransitionOptionsSet) {
            // TODO TransitionOptions
            // thumbTransitionOptions = transitionOptions;
        }

        var thumbPriority: Priority = if(thumbnailBuilder.getOrThrow().isPrioritySet()) {
            thumbnailBuilder.getOrThrow().getPriority()
        } else {
            getThumbnailPriority(priority);
        }

        var thumbOverrideWidth: Int64 = thumbnailBuilder.getOrThrow().getOverrideWidth();
        var thumbOverrideHeight: Int64 = thumbnailBuilder.getOrThrow().getOverrideHeight();
        if (Utils.isValidDimensions(overrideWidth, overrideHeight)
            && !thumbnailBuilder.getOrThrow().isValidOverride()) {
            thumbOverrideWidth = requestOptions.getOverrideWidth();
            thumbOverrideHeight = requestOptions.getOverrideHeight();
        }

        var coordinator: ThumbnailRequestCoordinator = ThumbnailRequestCoordinator(requestLock, parentCoordinator);
        var fullRequest: LoadRequest = obtainRequest<Y2>(
                requestLock,
                target,
                targetListener,
                requestOptions,
                coordinator,
                // transitionOptions,
                priority,
                overrideWidth,
                overrideHeight
                // callbackExecutor
                );
        isThumbnailBuilt = true;
        // Recursively generate thumbnail requests.
        var thumbRequest: LoadRequest =
            thumbnailBuilder.getOrThrow().buildRequestRecursive<RequestBuilder<TranscodeType>>(
                requestLock,
                target,
                targetListener,
                coordinator,
                // thumbTransitionOptions,
                thumbPriority,
                thumbOverrideWidth,
                thumbOverrideHeight,
                thumbnailBuilder.getOrThrow()
                // callbackExecutor
                );
        isThumbnailBuilt = false;
        coordinator.setRequests(fullRequest, thumbRequest);
        return coordinator;

            } else if(thumbSizeMultiplier != 0.0) {
                AppLog.error("thumbSizeMultiplier != 0.0")
                // Base case: thumbnail multiplier generates a thumbnail request, but cannot recurse.
        var coordinator: ThumbnailRequestCoordinator = ThumbnailRequestCoordinator(requestLock, parentCoordinator);
        var fullRequest: LoadRequest = obtainRequest<Y2>(
                requestLock,
                target,
                targetListener,
                requestOptions,
                coordinator,
                // transitionOptions,
                priority,
                overrideWidth,
                overrideHeight
                // callbackExecutor
                );
        //var thumbnailOptions: Y2 = requestOptions.setSizeMultiplier(thumbSizeMultiplier);
        var thumbnailOptions: Y2 = requestOptions.clone().setSizeMultiplier(thumbSizeMultiplier)

        var thumbnailRequest: LoadRequest =
            obtainRequest<Y2>(
                requestLock,
                target,
                targetListener,
                thumbnailOptions,
                coordinator,
                // transitionOptions,
                getThumbnailPriority(priority),
                overrideWidth,
                overrideHeight
                // callbackExecutor
                );

        coordinator.setRequests(fullRequest, thumbnailRequest);
        return coordinator;

            } else {

                // Base case: no thumbnail.
        return obtainRequest<Y2>(
            requestLock,
            target,
            targetListener,
            requestOptions,
            parentCoordinator,
            // transitionOptions,
            priority,
            overrideWidth,
            overrideHeight
            // callbackExecutor
            );

            }

    }

    private func obtainRequest<Y2>(
    requestLock: ReentrantMutex,
      targetcj: Target<TranscodeType> ,
      targetListener: RequestListener<TranscodeType> ,
      requestOptions: Y2,
      requestCoordinatorcj: Option<RequestCoordinator>,
    //   TransitionOptions<?, ? super TranscodeType> transitionOptions,
      prioritycj: Priority,
      overrideWidth: Int64,
      overrideHeight: Int64
    //   Executor callbackExecutor
      ): LoadRequest where Y2 <: BaseRequestOptions<Y2> & Cloneable<Y2> {
    return SingleRequest<TranscodeType>.obtain<TranscodeType>(
        context,
        glideContext,
        requestLock,
        model.getOrThrow(),
        transcodeTypeClass,
        requestOptions,
        overrideWidth,
        overrideHeight,
        prioritycj,
        targetcj,
        targetListener,
        requestListeners,
        requestCoordinatorcj,
        glide.getEngine()
        // transitionOptions.getTransitionFactory(),
        // callbackExecutor
        );
  }

    private func getThumbnailPriority(current: Priority): Priority {
        return if(current == Priority.LOW) {
            Priority.NORMAL
        } else if(current == Priority.NORMAL) {
            Priority.HIGH
        } else if(current == Priority.HIGH || current == Priority.IMMEDIATE) {
            Priority.IMMEDIATE
        } else {
            throw IllegalArgumentException("unknown priority: ${getPriority()}");
        }

    }

    private func initRequestListeners(requestListeners: ArrayList<RequestListener<Any>>): Unit {
        for (listener in requestListeners) {
            addListener((listener as RequestListener<TranscodeType>).getOrThrow());
        }
    }

    public func addListener(requestListener: RequestListener<TranscodeType>): RequestBuilder<TranscodeType> {
        if (getIsAutoCloneEnabled()) {
            return cloneBuilder().addListener(requestListener);
        }
        
        this.requestListeners.append(requestListener);
        return selfOrThrowIfLocked();
    }

    public func listener(requestListener: RequestListener<TranscodeType>): RequestBuilder<TranscodeType> {
        if (getIsAutoCloneEnabled()) {
            return cloneBuilder().listener(requestListener);
        }
        this.requestListeners = ArrayList<RequestListener<TranscodeType>>();
        return addListener(requestListener);
    }

    public func listener(resourceFn: (TranscodeType, Model, Target<TranscodeType>, DataSource, Bool) -> Bool, failedFn: (GlideException, Model, Target<TranscodeType>, Bool) -> Bool): RequestBuilder<TranscodeType> {
        return this.listener(NormalImgRequestListener<TranscodeType>(resourceFn, failedFn))
    }
}
