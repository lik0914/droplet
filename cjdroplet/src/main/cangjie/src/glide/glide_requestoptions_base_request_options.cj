package glide


from std import collection.*

from ohos import image.*
from ohos import component.*
from ohos import base.*

public interface AnyRequestOptions {

    func getFields(): Int64

    func getTransformationAllowed(): Bool

    func getSignature(): AnyKey

    func getResourceTypeClass(): ResourceTypeClass

    func getSizeMultiplier(): Float32
    func getPlaceholderDrawable(): Option<CJResourceDrawable>
    // func getPlaceholderId(): Int64
    func getErrorPlaceholderDrawable(): Option<CJResourceDrawable>
    // func getErrorId(): Int64
    // func getFallbackDrawable(): Option<CJResourceDrawable>
    // func getFallbackId(): Int64

    func getOverrideWidth(): Int64
    func getOverrideHeight(): Int64

    func isPrioritySet(): Bool
    func isValidOverride(): Bool

    func getCacheable(): Bool

    func getTransformationRequired(): Bool

    func getScaleOnlyOrNoTransform(): Bool

    func getOnlyRetrieveFromCache(): Bool

    func equals(o: Any): Bool

    func getOptions(): GlideOptions

    func getDiskCacheStrategy(): DiskCacheStrategy

    func getTransformations(): CachedHashCodeArrayMap<TransformationKey, AnyKey>

    func getPriority(): Priority
}

public open class BaseRequestOptions<T> <: AnyRequestOptions where T <: BaseRequestOptions<T> {

    // 选项设置标记

    protected static let SIZE_MULTIPLIER = 1 << 1;
    // 硬盘缓存策略
    protected static let DISK_CACHE_STRATEGY = 1 << 2;
    protected static let PRIORITY = 1 << 3;
    // 错误图片
    protected static let ERROR_PLACEHOLDER = 1 << 4;
    // protected static let ERROR_ID = 1 << 5;
    // 占位图
    protected static let PLACEHOLDER = 1 << 6;
    // protected static let PLACEHOLDER_ID = 1 << 7;
    // 是否使用内存缓存
    protected static let IS_CACHEABLE = 1 << 8;
    // 覆盖宽高
    protected static let OVERRIDE = 1 << 9;
    // 缓存自定义标记
    protected static let SIGNATURE = 1 << 10;
    // 图片变换
    protected static let TRANSFORMATION = 1 << 11;
    protected static let TRANSFORMATION_ALLOWED = 1 << 16;

    protected static let TRANSFORMATION_REQUIRED = 1 << 17;

    protected static let RESOURCE_CLASS = 1 << 12;
    // protected static let FALLBACK = 1 << 13;
    // protected static let FALLBACK_ID = 1 << 14;
    // protected static let THEME = 1 << 15;

    // protected static let USE_UNLIMITED_SOURCE_GENERATORS_POOL = 1 << 18;
    protected static let ONLY_RETRIEVE_FROM_CACHE = 1 << 19;
    // protected static let USE_ANIMATION_POOL = 1 << 20;

    public var sizeMultiplier: Float32 = 1.0f32;

    // 属性
    public var fields: Int64 = 0;

    public var isLocked: Bool = false;

    public var isAutoCloneEnabled: Bool = false;

    public var options: GlideOptions = GlideOptions();

    public var isScaleOnlyOrNoTransform: Bool = true;

    public var isTransformationAllowed: Bool = true;

    public var isTransformationRequired: Bool = false;

    public var resourceTypeClass: ResourceTypeClass = ResourceTypeClass.RESOURCE_TYPE_NONE

    public var transformations: CachedHashCodeArrayMap<TransformationKey, AnyKey> = CachedHashCodeArrayMap<TransformationKey, AnyKey>();

    public var errorPlaceholder: Option<CJResourceDrawable> = None;

    // public var errorId: Int64 = 0;
    public var placeholderDrawable: Option<CJResourceDrawable> = None;
    // public var placeholderId: Int64 = 0;

    // public var fallbackDrawable: Option<CJResourceDrawable> = None;
    // public var fallbackId: Int64 = 0;

    public var priority: Priority = Priority.NORMAL;
    public var isCacheable: Bool = true

    public var overrideWidth: Int64 = 0;
    public var overrideHeight: Int64 = 0;

    public var onlyRetrieveFromCache: Bool = false;

    public var signature: AnyKey = EmptySignature.obtain();

    public var diskCacheStrategy: DiskCacheStrategy = DiskCacheStrategyALL();

    public func getFields(): Int64 {
        return fields
    }

    public func getOptions(): GlideOptions {
        return options;
    }

    public func getTransformationRequired(): Bool {
        return isTransformationRequired
    }

    public func getScaleOnlyOrNoTransform(): Bool {
        return isScaleOnlyOrNoTransform
    }

    public func getOnlyRetrieveFromCache(): Bool {
        return onlyRetrieveFromCache
    }

    public func getSignature(): AnyKey {
        return signature
    }

    public func getResourceTypeClass(): ResourceTypeClass {
        return resourceTypeClass
    }

    public func getOverrideWidth(): Int64 {
        return overrideWidth;
    }

    public func getOverrideHeight(): Int64 {
        return overrideHeight;
    }

    public func getCacheable(): Bool {
        return isCacheable;
    }

    public func getDiskCacheStrategy(): DiskCacheStrategy {
        return diskCacheStrategy;
    }

    public func getTransformations(): CachedHashCodeArrayMap<TransformationKey, AnyKey> {
        AppLog.error("getTransformations : ${transformations}")
        return transformations;
    }

    public func set<V>(option: GlideOption<V>, value: V, t: T): T where V <: AnyGlideOptionValue {
        if (getIsAutoCloneEnabled()) {
            var t2 = clone(t)
            return t2.set(option, value, t2);
        }

        // Preconditions.checkNotNull(option);
        // Preconditions.checkNotNull(value);
        t.options.set<V>(option, value);
        return selfOrThrowIfLocked();
    }

    public func setSizeMultiplier(sizeMultiplier: Float32): T {
        setSizeMultiplier(sizeMultiplier, (this as T).getOrThrow())
    }

    public func setSizeMultiplier(sizeMultiplier: Float32, t: T): T {

        if (getIsAutoCloneEnabled()) {
            var t2 = clone(t)
            return t2.setSizeMultiplier(sizeMultiplier, t2);
        }

        if (sizeMultiplier < 0.0 || sizeMultiplier > 1.0) {
            throw IllegalArgumentException("sizeMultiplier must be between 0 and 1");
        }
        t.sizeMultiplier = sizeMultiplier;
        t.fields |= SIZE_MULTIPLIER;

        return selfOrThrowIfLocked();
    }

    public func getTransformationAllowed(): Bool {
        return isTransformationAllowed
    }

    public override func getSizeMultiplier(): Float32 {
        return sizeMultiplier;
    }

    public func getErrorPlaceholderDrawable(): Option<CJResourceDrawable> {
        return errorPlaceholder;
    }

    // public func getErrorId(): Int64 {
    //     return errorId;
    // }

    // public func getPlaceholderId(): Int64 {
    //     return placeholderId;
    // }

    public func getPlaceholderDrawable(): Option<CJResourceDrawable> {
        return placeholderDrawable;
    }

    // public func getFallbackId(): Int64 {
    //     return fallbackId;
    // }

    // public func getFallbackDrawable(): Option<CJResourceDrawable> {
    //     return fallbackDrawable;
    // }

    public func isPrioritySet(): Bool {
        return isSet(PRIORITY);
    }

    public func isValidOverride(): Bool {
        return Utils.isValidDimensions(overrideWidth, overrideHeight);
    }

    public open func equals(o: Any): Bool {
        if (o is AnyRequestOptions) {
            var other: AnyRequestOptions = (o as AnyRequestOptions).getOrThrow();

            // AppLog.error("base requestOptions equals: sizeMultiplier ${other.getSizeMultiplier() == sizeMultiplier}")
            // AppLog.error("base requestOptions equals: isCacheable ${isCacheable == other.getCacheable()}")
            // AppLog.error("base requestOptions equals: overrideHeight ${overrideHeight == other.getOverrideHeight()}")
            // AppLog.error("base requestOptions equals: overrideWidth ${overrideWidth == other.getOverrideWidth()}")
            // AppLog.error("base requestOptions equals: isTransformationRequired ${isTransformationRequired == other.getTransformationRequired()}")
            // AppLog.error("base requestOptions equals: isTransformationAllowed ${isTransformationAllowed == other.getTransformationAllowed()}")
            // AppLog.error("base requestOptions equals: onlyRetrieveFromCache ${onlyRetrieveFromCache == other.getOnlyRetrieveFromCache()}")
            // AppLog.error("base requestOptions equals: diskCacheStrategy ${diskCacheStrategy.equals(other.getDiskCacheStrategy())}")
            // AppLog.error("base requestOptions equals: priority ${priority == other.getPriority()}")
            // AppLog.error("base requestOptions equals: options ${options == other.getOptions()}")
            // AppLog.error("base requestOptions equals: transformations ${transformations == other.getTransformations()}")
            // AppLog.error("base requestOptions equals: ${transformations} --- ${other.getTransformations()}")
            // AppLog.error("base requestOptions equals: resourceTypeClass ${resourceTypeClass == other.getResourceTypeClass()}")
            // AppLog.error("base requestOptions equals: signature ${signature == other.getSignature()}")
            return other.getSizeMultiplier() == sizeMultiplier
                // && errorId == other.errorId
                // && errorPlaceholder == other.getErrorPlaceholderDrawable()
                // && placeholderId == other.placeholderId
                // && placeholderDrawable ==  other.placeholderDrawable
                // && fallbackId == other.fallbackId
                // && fallbackDrawable == other.fallbackDrawable
                && isCacheable == other.getCacheable()
                && overrideHeight == other.getOverrideHeight()
                && overrideWidth == other.getOverrideWidth()
                && isTransformationRequired == other.getTransformationRequired()
                && isTransformationAllowed == other.getTransformationAllowed()
                // TODO useUnlimitedSourceGeneratorsPool
                // && useUnlimitedSourceGeneratorsPool == other.useUnlimitedSourceGeneratorsPool
                && onlyRetrieveFromCache == other.getOnlyRetrieveFromCache()
                && diskCacheStrategy.equals(other.getDiskCacheStrategy())
                && priority == other.getPriority()
                && options == other.getOptions()
                && transformations == other.getTransformations()
                && resourceTypeClass == other.getResourceTypeClass()
                && signature == other.getSignature()
                // && Util.bothNullOrEqual(theme, other.theme);
            }
            return false;
    }

    protected func selfOrThrowIfLocked(): T {
        if (isLocked) {
            throw IllegalStateException("You cannot modify locked T, consider clone()");
        }
        return self();
    }

    public func self(): T {
        return (this as T).getOrThrow()
    }

    private func isSet(flag: Int64): Bool {
        return isSetStatic(this.fields, flag);
    }

    private static func isSetStatic(fields: Int64, flag: Int64): Bool {
        return (fields & flag) != 0;
    }

    protected func getIsAutoCloneEnabled(): Bool {
        return isAutoCloneEnabled;
    }

    // 仓颉没有克隆方法 需要传入一个空对象来赋值
    public func clone(t: T): T {

        // TODO 克隆对象
        t.fields = this.fields
        t.sizeMultiplier = this.sizeMultiplier
        t.diskCacheStrategy = this.diskCacheStrategy
        t.priority = this.priority
        // t.errorPlaceholder = this.errorPlaceholder
        // t.errorId = this.errorId
        // t.placeholderDrawable = this.placeholderDrawable
        // t.placeholderId = this.placeholderId
        t.isCacheable = this.isCacheable
        // t.overrideHeight = this.overrideHeight
        // t.overrideWidth = this.overrideWidth
        t.signature = this.signature
        t.isTransformationRequired = this.isTransformationRequired
        t.isTransformationAllowed = this.isTransformationAllowed
        // t.fallbackDrawable = this.fallbackDrawable
        // t.fallbackId = this.fallbackId
        // t.resourceClass = this.resourceClass
        t.isScaleOnlyOrNoTransform = this.isScaleOnlyOrNoTransform

        let tempOptions = this.options
        t.options = GlideOptions();
        t.options.putAll(tempOptions);
        let tempTrans = this.transformations
        t.transformations = CachedHashCodeArrayMap<TransformationKey, AnyKey>();
        t.transformations.putAll(tempTrans);
        t.isLocked = false;
        t.isAutoCloneEnabled = false;

        return t
    }

    public func autoClone(): T {
        if (isLocked && !isAutoCloneEnabled) {
        throw IllegalStateException(
            "You cannot auto lock an already locked options object" + ", try clone() first");
        }
        isAutoCloneEnabled = true;
        return lock();
    }

    public func lock(): T {
        isLocked = true;
        // This is the only place we should not check locked.
        return self();
    }

    // public func apply(v: AnyRequestOptions): T {

    // }

    public func apply(v: AnyRequestOptions, t: T): T {
        if (getIsAutoCloneEnabled()) {
            var t2 = clone(t)
            return t2.apply(v, t2)
        }
        let other: AnyRequestOptions = v;

        // TODO
        if (isSetStatic(other.getFields(), SIZE_MULTIPLIER)) {
            t.sizeMultiplier = other.getSizeMultiplier();
        }
        // if (isSetStatic(other.getFields(), USE_UNLIMITED_SOURCE_GENERATORS_POOL)) {
        //     // t.useUnlimitedSourceGeneratorsPool = other.useUnlimitedSourceGeneratorsPool;
        // }
        // if (isSetStatic(other.getFields(), USE_ANIMATION_POOL)) {
        //     // t.useAnimationPool = other.useAnimationPool;
        // }
        if (isSetStatic(other.getFields(), DISK_CACHE_STRATEGY)) {
            t.diskCacheStrategy = other.getDiskCacheStrategy();
            // AppLog.error("apply DISK_CACHE_STRATEGY: ${t.diskCacheStrategy}")
        }
        if (isSetStatic(other.getFields(), PRIORITY)) {
            t.priority = other.getPriority();
        }
        if (isSetStatic(other.getFields(), ERROR_PLACEHOLDER)) {
            t.errorPlaceholder = other.getErrorPlaceholderDrawable();
            // t.errorId = 0;

            // t.fields &= ~ERROR_ID;
            // t.fields &= !ERROR_ID;
        }
        // if (isSetStatic(other.getFields(), ERROR_ID)) {
        //     // t.errorId = other.errorId;
        //     // t.errorPlaceholder = null;
        //     // t.fields &= ~ERROR_PLACEHOLDER;
        //     t.fields &= !ERROR_PLACEHOLDER;
        // }
        if (isSetStatic(other.getFields(), PLACEHOLDER)) {
            t.placeholderDrawable = other.getPlaceholderDrawable();
            // t.placeholderId = 0;
            // t.fields &= ~PLACEHOLDER_ID;
            // t.fields &= !PLACEHOLDER_ID;
        }
        // if (isSetStatic(other.getFields(), PLACEHOLDER_ID)) {
        //     // placeholderId = other.placeholderId;
        //     // placeholderDrawable = null;
        //     // fields &= ~PLACEHOLDER;

        //     t.fields &= !PLACEHOLDER;
        // }
        if (isSetStatic(other.getFields(), IS_CACHEABLE)) {
            t.isCacheable = other.getCacheable();
        }
        if (isSetStatic(other.getFields(), OVERRIDE)) {
            t.overrideWidth = other.getOverrideWidth();
            t.overrideHeight = other.getOverrideHeight();
        }
        if (isSetStatic(other.getFields(), SIGNATURE)) {
            t.signature = other.getSignature();
        }
        if (isSetStatic(other.getFields(), RESOURCE_CLASS)) {
            // t.resourceClass = other.resourceClass;
            t.resourceTypeClass = other.getResourceTypeClass();
        }
        // if (isSetStatic(other.getFields(), FALLBACK)) {
        //     // fallbackDrawable = other.fallbackDrawable;
        //     // fallbackId = 0;
        //     // fields &= ~FALLBACK_ID;
        //     t.fields &= !FALLBACK_ID;
        // }
        // if (isSetStatic(other.getFields(), FALLBACK_ID)) {
        //     // fallbackId = other.fallbackId;
        //     // fallbackDrawable = null;
        //     // fields &= ~FALLBACK;
        //     t.fields &= !FALLBACK;
        // }
        // if (isSetStatic(other.getFields(), THEME)) {
        //     // t.theme = other.theme;
        // }
        if (isSetStatic(other.getFields(), TRANSFORMATION_ALLOWED)) {
            t.isTransformationAllowed = other.getTransformationAllowed();
        }
        if (isSetStatic(other.getFields(), TRANSFORMATION_REQUIRED)) {
            t.isTransformationRequired = other.getTransformationRequired();
        }
        if (isSetStatic(other.getFields(), TRANSFORMATION)) {
            t.transformations.putAll(other.getTransformations());
            t.isScaleOnlyOrNoTransform = other.getScaleOnlyOrNoTransform();
        }
        if (isSetStatic(other.getFields(), ONLY_RETRIEVE_FROM_CACHE)) {
            t.onlyRetrieveFromCache = other.getOnlyRetrieveFromCache();
        }

        // // Applying options with dontTransform() is expected to clear our transformations.
        if (!t.isTransformationAllowed) {
            t.transformations.clear();
            // fields &= ~TRANSFORMATION;
            t.fields &= !TRANSFORMATION;
            t.isTransformationRequired = false;
            // fields &= ~TRANSFORMATION_REQUIRED;
            t.fields &= !TRANSFORMATION_REQUIRED;
            t.isScaleOnlyOrNoTransform = true;
        }

        t.fields |= other.getFields();

        // AppLog.error("apply t options: ${t.options} other options: ${other.getOptions()}")
        t.options.putAll(other.getOptions());
        // AppLog.error("apply t options after: ${t.options}")
        return t.selfOrThrowIfLocked();
    }

    // TODO skipMemoryCache改成disableMemoryCache
    public func skipMemoryCache(skip: Bool, t: T): T {
        if (getIsAutoCloneEnabled()) {
            var t2 = clone(t)
            return t2.skipMemoryCache<T>(true, t2);
        }

        t.isCacheable = !skip;
        t.fields |= IS_CACHEABLE;

        return t.selfOrThrowIfLocked();
    }

    public func onlyRetrieveFromCachecj(flag:Bool,t:T):T{
        if(getIsAutoCloneEnabled()){
            var t2 = clone(t)
            return t2.onlyRetrieveFromCachecj<T>(true, t2);
        }
        t.onlyRetrieveFromCache = flag
        t.fields |= ONLY_RETRIEVE_FROM_CACHE;

        return t.selfOrThrowIfLocked();
    }

    public func setDiskCacheStrategy(strategy: DiskCacheStrategy): T{
        return setDiskCacheStrategy(strategy, (this as T).getOrThrow())
    }

    public func setDiskCacheStrategy(strategy: DiskCacheStrategy, t: T): T {
        // AppLog.error("setDiskCacheStrategy")
        // AppLog.error("setDiskCacheStrategy t.options1: ${t.options} ori: ${this.options}")
        if (getIsAutoCloneEnabled()) {
            // AppLog.error("getIsAutoCloneEnabled")
            var t2 = clone(t)
            // AppLog.error("t2 ${t2.options}")
            return t2.setDiskCacheStrategy(strategy, t2);
        }

        // AppLog.error("setDiskCacheStrategy t.options2: ${t.options} ori: ${this.options}")

        t.diskCacheStrategy = strategy;
        t.fields |= DISK_CACHE_STRATEGY;

        return t.selfOrThrowIfLocked();
    }

    public func setOverride(width: Int64, height: Int64): T {
        return setOverride(width, height, (this as T).getOrThrow())
    }

    public func setOverride(width: Int64, height: Int64, t: T): T {
        if (getIsAutoCloneEnabled()) {
            var t2 = clone(t)
            return t2.setOverride(width, height, t2);
        }

        t.overrideWidth = width;
        t.overrideHeight = height;
        fields |= OVERRIDE;

        return t.selfOrThrowIfLocked();
    }


    public func optionalCenterInside(): T {
        return optionalCenterInside((this as T).getOrThrow())
    }

    /**
    * 转换失败时直接返回原图
    */
    public func optionalCenterInside(t: T): T {
        return optionalScaleOnlyTransform(DownsampleStrategy.CENTER_INSIDE, CenterInside(), t);
    }

    public func centerInside(): T {
        return centerInside((this as T).getOrThrow())
    }

    /**
    * 转换失败时报错
    */
    public func centerInside(t: T): T {
        return scaleOnlyTransform(DownsampleStrategy.CENTER_INSIDE, CenterInside(), t);
    }

    public func optionalCircleCrop(t: T): T {
        return optionalTransform(DownsampleStrategy.CENTER_OUTSIDE, CircleCrop(), t);
    }

    public func circleCrop(): T {
        return circleCrop((this as T).getOrThrow())
    }

    public func circleCrop(t: T): T {
        return transform(DownsampleStrategy.CENTER_INSIDE, CircleCrop(), t);
    }

    public func fitCenter(): T {
        return fitCenter((this as T).getOrThrow())
    }

    public func fitCenter(t: T): T {
        return scaleOnlyTransform(DownsampleStrategy.FIT_CENTER, FitCenter(), t);
    }

    public func optionalFitCenter(): T {
        return optionalFitCenter((this as T).getOrThrow())
    }

    public func optionalFitCenter(t: T): T {
        return optionalScaleOnlyTransform(DownsampleStrategy.FIT_CENTER, FitCenter(), t);
    }

    private func optionalScaleOnlyTransform(strategy: DownsampleStrategy ,transformation: Transformation<PixelMap>, t: T): T {
        return scaleOnlyTransform(strategy, transformation, false /*isTransformationRequired*/, t);
    }

    private func scaleOnlyTransform(strategy: DownsampleStrategy, transformation: Transformation<PixelMap>, t: T): T {
        return scaleOnlyTransform(strategy, transformation, true, t);
    }

    private func scaleOnlyTransform(strategy: DownsampleStrategy, transformation: Transformation<PixelMap>, isTransformationRequired: Bool, t: T): T {
        var result: BaseRequestOptions<T>
        if(isTransformationRequired) {
            result = transform(strategy, transformation, t)
        } else {
            result = optionalTransform(strategy, transformation, t);
        }
        result.isScaleOnlyOrNoTransform = true;
        return (result as T).getOrThrow();
    }

    public func optionalTransform(downsampleStrategy: DownsampleStrategy, transformation: Transformation<PixelMap>, t: T): T {
        if (getIsAutoCloneEnabled()) {
            var t2 = clone(t)
            return t2.optionalTransform(downsampleStrategy, transformation, t2);
        }

        t.downsample(downsampleStrategy);
        return t.transform(transformation, /*isRequired=*/ false, t);
    }

    // 目前只支持PixelMap
    // TODO 支持其他类型
    public func optionalTransform(resourceClass: TransformationKey, transformation: Transformation<PixelMap>, t: T): T {
        return transform(resourceClass, transformation, /*isRequired=*/ false, t);
    }

    // 目前只支持PixelMap
    // TODO 支持其他类型
    public func transform(downsampleStrategy: DownsampleStrategy, transformation: Transformation<PixelMap>, t: T): T {
        if (getIsAutoCloneEnabled()) {
            var t2 = clone(t)
            return t2.transform(downsampleStrategy, transformation, t2);
        }

        t.downsample(downsampleStrategy);
        return t.transform(transformation, t);
    }

    public func downsample(strategy: DownsampleStrategy): T {
        // var s1 = (DownsampleStrategy.OPTION as GlideOption<AnyGlideOption>).getOrThrow()
        // AppLog.error("downsample set")
        var s2 = (this as T).getOrThrow()

        return set<DownsampleStrategy>(DownsampleStrategy.OPTION, strategy, s2);
    }

    public func transform(transformation: Transformation<PixelMap>): T {
        return transform(transformation, true, (this as T).getOrThrow());
    }

    public func transform(transformation: Transformation<PixelMap>, t: T): T {
        return transform(transformation, true, t);
    }

    public func transform(transformation: Transformation<PixelMap>, isRequired: Bool, t: T): T {
        if (getIsAutoCloneEnabled()) {
            var t2 = clone(t)
            return t2.transform(transformation, isRequired, t2);
        }

        // var drawableTransformation: DrawableTransformation = DrawableTransformation(transformation, isRequired);
        t.transform<PixelMap>(TransformationKey(TransformationKey.TRANSFORMATION_PIXELMAP), transformation, isRequired, t);
        let drawableTransformation: DrawableTransformation = DrawableTransformation(transformation, isRequired);
        t.transform<PixelMapDrawable>(TransformationKey(TransformationKey.TRANSFORMATION_DRAWABLE), drawableTransformation, isRequired, t);
        // transform(TransformationKey(TransformationKey.TRANSFORMATION_INPUTSTREAM), transformation, isRequired, t);

        // transform(Drawable.class, drawableTransformation, isRequired);
        // TODO: remove BitmapDrawable decoder and this transformation.
        // Registering as BitmapDrawable is simply an optimization to avoid some iteration and
        // isAssignableFrom checks when obtaining the transformation later on. It can be removed without
        // affecting the functionality.
        // transform(BitmapDrawable.class, drawableTransformation.asBitmapDrawable(), isRequired);
        // transform(GifDrawable.class, new GifDrawableTransformation(transformation), isRequired);
        return selfOrThrowIfLocked();
    }

    public func transform<Y>(resourceClass: TransformationKey, transformation: Transformation<Y>, isRequired: Bool, t: T): T {
        if (getIsAutoCloneEnabled()) {
            var t2: T = clone(t)
            return t2.transform(resourceClass, transformation, isRequired, t2);
        }

        // Preconditions.checkNotNull(resourceClass);
        // Preconditions.checkNotNull(transformation);
        AppLog.error("put transform : ${transformation}")
        t.transformations.put(resourceClass, transformation);
        t.fields |= TRANSFORMATION;
        t.isTransformationAllowed = true;
        t.fields |= TRANSFORMATION_ALLOWED;
        // Always set to false here. Known scale only transformations will call this method and then
        // set isScaleOnlyOrNoTransform to true immediately after.
        t.isScaleOnlyOrNoTransform = false;
        if (isRequired) {
            t.fields |= TRANSFORMATION_REQUIRED;
            t.isTransformationRequired = true;
        }
        return t.selfOrThrowIfLocked();
    }

    public func getPriority(): Priority {
        return priority;
    }

    public func decode(resourceTypeClass: ResourceTypeClass, t: T): T {
        if (getIsAutoCloneEnabled()) {
            var t2: T = clone(t)
            return t2.decode(resourceTypeClass, t2);
        }

        t.resourceTypeClass = resourceTypeClass;
        t.fields |= RESOURCE_CLASS;
        return t.selfOrThrowIfLocked();
    }

    public func placeholder(res: CJResource): T {

        this.placeholderDrawable = Some(CJResourceDrawable(res));
        fields |= PLACEHOLDER;

        // placeholderId = 0;
        // fields &= !PLACEHOLDER_ID;

        return self();
    }

    public func error(res: CJResource): T {

        this.errorPlaceholder = Some(CJResourceDrawable(res));
        fields |= ERROR_PLACEHOLDER;

        // this.errorId = 0;
        // fields &= !ERROR_ID;

        return self();
    }
}
