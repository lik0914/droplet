package glide
///**
// * Created on 2024/3/4
// */
from ohos import state_macro_manage.*
from ohos import base.*
from ohos import component.*
from ohos import image.Component as ImageComponent
from ohos import image.Image as ImageImage
from ohos import image.*
from ohos import state_manage.*
from ohos import ability.*
from ohos import concurrency.*
from net import http.*
from std import socket.*
from net import tls.*
from std import io.*
from encoding import url.*
from std import fs.*

@Observed
public class GlideRequestOption {

    // 加载一张本地的jpg资源（必选）
    @Publish
    public var loadSrc: String = ""
    // 占位图使用本地资源icon_loading（可选）
    @Publish
    public var placeholder: Option<CJResource> = Option<CJResource>.None
    // 失败占位图使用本地资源icon_failed（可选）
    @Publish
    public var errholder: Option<CJResource> = Option<CJResource>.None
    // 磁盘缓存策略（可选）
    @Publish
    public var strategy: Option<DiskCacheStrategy> = Option<DiskCacheStrategy>.None
    //生命周期管理用到的标签名称
    @Publish
    public var label: String = ""
    //transform
    @Publish
    public var transformCate: Option<PixelMapTransformation> = Option<PixelMapTransformation>.None
    //是否禁用内存缓存
    @Publish
    public var transformListCate: Option<ArrayList<PixelMapTransformation>> = Option<ArrayList<PixelMapTransformation>>.None

    @Publish
    public var isSkipMemory: Option<Bool> = Option<Bool>.None
    //Override
    @Publish
    public var overrideWH: Option<(Int64, Int64)> = Option<(Int64, Int64)>.None
    //apply
    @Publish
    public var applyRequestOption: Option<RequestOptions> = Option<RequestOptions>.None
    //只从缓存读取数据
    @Publish
    public var onlyRetrieveFromCache: Option<Bool> = Option<Bool>.None
    //禁用动画
    @Publish
    public var dontTransform: Option<Bool> = Option<Bool>.None
    //usedefault
    @Publish
    public var useDefaultRequestOption: Option<RequestOptions> = Option<RequestOptions>.None
    //thumbnail float
    @Publish
    public var thumbnail: Option<Float32> = Option<Float32>.None
    //thumnail drawable
    @Publish
    public var thumbnaildrawable: Option<RequestBuilder<Drawable>> = Option<RequestBuilder<Drawable>>.None
    //signature
    @Publish
    public var signature: Option<String> = Option<String>.None
}

@Component
public class GlideImageZJ {
    @Link
    @Watch[onOptionChanged]
    var option: GlideRequestOption

    var globalContext: Option<AbilityContext> = Option<AbilityContext>.None

    /*加载状态*/
    @State
    var isLoading: Bool = true
    /*错误状态*/
    @State
    var isError: Bool = false

    @Prop
    var beginFn: () -> Unit
    @Prop
    var endFn: () -> Unit

    var flag: Bool = false

    var oldWidth: Int64 = 0
    var oldHeight: Int64 = 0

    let size: Size = Size(width: 1, height: 1)
    let opts: InitializationOptions = InitializationOptions(size: size)

    let color: Array<UInt8> = Array<UInt8>(96, item: 0)
    @State
    var pixelMap: PixelMap = createPixelMap(color, opts)

    // 生命周期：组件首次显示在屏幕上时调用
    public func onAppear(key: String): Unit {
        AppLog.error("调了onAppear--------------------------------------------------------------------GlideImage")
        Glide.get(globalContext.getOrThrow()).onAppear(key)
    }
    //生命周期：组件从屏幕上消失时调用
    public func onDisappear(key: String): Unit {
        AppLog.error("调了onDisAppear--------------------------------------------------------------------GlideImage")
        Glide.get(globalContext.getOrThrow()).onDisAppear(key)
    }

    func onOptionChanged() {
        AppLog.error(
            "GlideImage onOptionChanged--------------------------------------------------------------------GlideImage")
        updateImg(oldWidth, oldHeight)
    }

    func updateImg(width: Int64, height: Int64) {
        if (option.loadSrc != "" && width > 0 && height > 0) {
            beginFn()

            var glideManager = Option<RequestManager>.None
            if (let Some(v) <- option.useDefaultRequestOption) {
                glideManager = Glide.withContext(globalContext.getOrThrow(), option.label).useDefaultRequestOptions(v)
            } else {
                glideManager = Glide.withContext(globalContext.getOrThrow(), option.label)
            }
            var glide = glideManager.getOrThrow().load(option.loadSrc)
            //设置三级缓存策略
            if (let Some(v) <- option.strategy) {
                glide = glide.setDiskCacheStrategy(v)
            }

            if (let Some(v) <- option.onlyRetrieveFromCache) {
                glide = glide.onlyRetrieveFromCachecj(v, glide)
            }

            if (let Some(v) <- option.isSkipMemory) {
                glide = glide.skipMemoryCache(v, glide)
            }

            if (let Some(v) <- option.thumbnail) {
                glide = glide.thumbnail(v)
            }

            if (let Some(v) <- option.thumbnaildrawable) {
                glide = glide.thumbnail(v)
            }

            if (let Some(v) <- option.overrideWH) {
                glide = glide.setOverride(v[0], v[1])
            }

            if (let Some(v) <- option.transformCate) {
                glide = glide.transform(v)
            }

            if (let Some(v) <- option.transformListCate) {
                if (v.size > 1) {
                    glide = glide.transforms(v)
                } else if (v.size == 1) {
                    glide = glide.transform(v[0])
                }
            }

            if (let Some(v) <- option.dontTransform) {
                if (v) {
                    glide = glide.dontTransform(glide)
                }
            }
            //设置占位符
            if (let Some(v) <- option.placeholder) {
                glide = glide.placeholder(v)
            }
            //设置错误占位符
            if (let Some(v) <- option.errholder) {
                glide = glide.error(v)
            }

            if (let Some(v) <- option.applyRequestOption) {
                glide = glide.apply(v)
            }

            if (let Some(v) <- option.signature) {
                glide = glide.setSignature(StringKey(v))
            }

            glide.listener(
                {
                    drawable: Drawable, model: Model, target: Target<Drawable>, datasource: DataSource, 
                    isFirstResource: Bool =>
                    endFn()
                    AppLog.error(
                        "load成功--------------------------------------------------------------------GlideImage")
                    return false
                },
                {
                    e: GlideException, model: Model, target: Target<Drawable>, isFirstResource: Bool =>
                    AppLog.error(
                        "load失败--------------------------------------------------------------------GlideImage")
                    return false
                }
            ).into(
                {
                    p: PixelMap =>
                    AppLog.error(
                        "callback1--------------------------------------------------------------------GlideImage")
                    launch {
                        isLoading = false
                        pixelMap = p
                    }
                },
                {
                    cjres: CJResource, isErrorPic: Bool =>
                    AppLog.error(
                        "loaderror----------------------------------------------------${isErrorPic}----------------GlideImage"
                    )
                    if (isErrorPic) {
                        AppLog.error(
                            "isErrorPic--------------------------------------------------------------------GlideImage")
                        launch {
                            isError = true
                        }
                    }
                },
                width,
                height
            )
        }
    }

    func render() {
        Column(30) {
            if (isError) {
                if (let Some(w) <- option.errholder) {
                    Image(w).width(100.percent).objectFit(ImageFit.ScaleDown)
                }
            } else {
                if (isLoading) {
                    if (let Some(v) <- option.placeholder) {
                        Image(v).width(100.percent).objectFit(ImageFit.ScaleDown).onAreaChange(
                            {
                                oldArea, newArea =>
                                let newWidth: Int64 = Int64(newArea.width)
                                let newHeight: Int64 = Int64(newArea.height)
                                AppLog.error("newWidth = ${newWidth} newHeight = ${newHeight}")
                                if (oldWidth != newWidth || oldHeight != newHeight) {
                                    if (!flag && newWidth > 0 && newHeight > 0) {
                                        flag = true
                                        updateImg(newWidth, newHeight)
                                        oldWidth = newWidth
                                        oldHeight = newHeight
                                    }
                                }
                            }
                        )
                    } else {
                    }
                } else {
                    Image(pixelMap).width(100.percent).objectFit(ImageFit.ScaleDown)
                }
            }
        }
    }
}
