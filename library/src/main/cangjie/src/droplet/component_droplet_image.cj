/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights resvered.
 */

package droplet.droplet
///**
// * Created on 2024/3/4
// */
import ohos.state_manage.*
import ohos.state_macro_manage.*
protected import ohos.base.*
protected import ohos.component.*
protected import ohos.image.Component as ImageComponent
protected import ohos.image.Image as ImageImage


internal import ohos.image.PixelMap
internal import ohos.image.InitializationOptions
internal import ohos.image.PixelMapFormat
internal import ohos.image.Size
internal import ohos.image.Region
internal import ohos.image.PositionArea
internal import ohos.image.createPixelMap
internal import ohos.image.createImageSource
internal import ohos.image.ImageSource
internal import ohos.image.SourceOptions
internal import ohos.image.DecodingOptions
internal import ohos.image.ImageInfo


//protected import ohos.state_manage.*
protected import ohos.ability.*
protected import ohos.concurrency.*
protected import net.http.*
protected import std.socket.*
protected import net.tls.*
protected import std.io.*
protected import encoding.url.*
protected import std.fs.Path as FSPath
protected import std.fs.*
protected import std.time.*
protected import std.os.posix.*
protected import std.collection.*
protected import std.math.*
protected import std.log.*
protected import encoding.hex.*
protected import std.sync.*
protected import ohos.resource_manager.*
protected import std.format.Formatter
protected import std.overflow.*


@Observed
public class DropletRequestOption {

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
public class DropletImageComponent {
    @Link
    @Watch[onOptionChanged]
    var option: DropletRequestOption

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
        Droplet.get(globalContext.getOrThrow()).onAppear(key)
    }
    //生命周期：组件从屏幕上消失时调用
    public func onDisappear(key: String): Unit {
        Droplet.get(globalContext.getOrThrow()).onDisAppear(key)
    }

    func onOptionChanged() {
        AppLog.error(
            "DropletImage onOptionChanged--------------------------------------------------------------------DropletImage")
        updateImg(oldWidth, oldHeight)
    }

    func updateImg(width: Int64, height: Int64) {
        if (option.loadSrc != "" && width > 0 && height > 0) {
            beginFn()

            var dropletManager = Option<RequestManager>.None
            if (let Some(v) <- option.useDefaultRequestOption) {
                dropletManager = Droplet.withContext(globalContext.getOrThrow(), option.label).useDefaultRequestOptions(v)
            } else {
                dropletManager = Droplet.withContext(globalContext.getOrThrow(), option.label)
            }
            var droplet = dropletManager.getOrThrow().load(option.loadSrc)
            //设置三级缓存策略
            if (let Some(v) <- option.strategy) {
                droplet = droplet.setDiskCacheStrategy(v)
            }

            if (let Some(v) <- option.onlyRetrieveFromCache) {
                droplet = droplet.onlyRetrieveFromCachecj(v, droplet)
            }

            if (let Some(v) <- option.isSkipMemory) {
                droplet = droplet.skipMemoryCache(v, droplet)
            }

            if (let Some(v) <- option.thumbnail) {
                droplet = droplet.thumbnail(v)
            }

            if (let Some(v) <- option.thumbnaildrawable) {
                droplet = droplet.thumbnail(v)
            }

            if (let Some(v) <- option.overrideWH) {
                droplet = droplet.setOverride(v[0], v[1])
            }

            if (let Some(v) <- option.transformCate) {
                droplet = droplet.transform(v)
            }

            if (let Some(v) <- option.transformListCate) {
                if (v.size > 1) {
                    droplet = droplet.transforms(v)
                } else if (v.size == 1) {
                    droplet = droplet.transform(v[0])
                }
            }

            if (let Some(v) <- option.dontTransform) {
                if (v) {
                    droplet = droplet.dontTransform(droplet)
                }
            }
            //设置占位符
            if (let Some(v) <- option.placeholder) {
                droplet = droplet.placeholder(v)
            }
            //设置错误占位符
            if (let Some(v) <- option.errholder) {
                droplet = droplet.error(v)
            }

            if (let Some(v) <- option.applyRequestOption) {
                droplet = droplet.apply(v)
            }

            if (let Some(v) <- option.signature) {
                droplet = droplet.setSignature(StringKey(v))
            }

            droplet.listener(
                {
                    drawable: Drawable, model: Model, target: Target<Drawable>, datasource: DataSource, 
                    isFirstResource: Bool =>
                    endFn()
                    AppLog.error(
                        "load成功--------------------------------------------------------------------DropletImage")
                    return false
                },
                {
                    e: DropletException, model: Model, target: Target<Drawable>, isFirstResource: Bool =>
                    AppLog.error(
                        "load失败--------------------------------------------------------------------DropletImage")
                    return false
                }
            ).into(
                {
                    p: PixelMap =>
                    AppLog.error(
                        "callback1--------------------------------------------------------------------DropletImage")
                    launch {
                        isLoading = false
                        pixelMap = p
                    }
                },
                {
                    cjres: CJResource, isErrorPic: Bool =>
                    AppLog.error(
                        "loaderror----------------------------------------------------${isErrorPic}----------------DropletImage"
                    )
                    if (isErrorPic) {
                        AppLog.error(
                            "isErrorPic--------------------------------------------------------------------DropletImage")
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

    func build() {
        Column(30) {
            if (isError) {
                if (let Some(w) <- option.errholder) {
                    Image(w).width(100.percent).objectFit(ImageFit.ScaleDown)
                }
            } else {
                //有占位图的时候加载中走这里
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
                        //没有占位图的时候加载中走这里
                        Image(pixelMap).width(100.percent).objectFit(ImageFit.ScaleDown).onAreaChange(
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
                    }
                } else {
                    Image(pixelMap).width(100.percent).objectFit(ImageFit.ScaleDown)
                }
            }
        }
    }
}
