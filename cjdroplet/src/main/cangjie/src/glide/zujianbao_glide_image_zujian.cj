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
    // @Publish var options: Option<GlideOptions> = None
    //@Publish var overrideWidth: Int64 = 0//SIZE_ORIGINAL
    //@Publish var overrideHeight: Int64 = 0//SIZE_ORIGINAL
    //@Publish var signature: String = ""


    // 加载一张本地的jpg资源（必选）
    @Publish public var loadSrc: String = ""
    // 占位图使用本地资源icon_loading（可选）
    @Publish public var placeholder: Option<CJResource> = Option<CJResource>.None
    // 失败占位图使用本地资源icon_failed（可选）
    @Publish public var errholder: Option<CJResource> = Option<CJResource>.None
    // 磁盘缓存策略（可选）
    @Publish public var strategy: Option<DiskCacheStrategy> = Option<DiskCacheStrategy>.None
    //生命周期管理用到的标签名称
    @Publish public var label: String = ""
    //transform
    @Publish public var transformCate: Option<PixelMapTransformation> = Option<PixelMapTransformation>.None
    //@Publish var requestListener: Option<(PixelMap) -> Bool> = Option<(PixelMap) -> Bool>.None
    //是否禁用内存缓存
    @Publish public var isSkipMemory: Option<Bool> = Option<Bool>.None
    //Override
    @Publish public var overrideWH: Option<(Int64,Int64)> = Option<(Int64,Int64)>.None
    //apply
    @Publish public var applyRequestOption: Option<RequestOptions> = Option<RequestOptions>.None
    //只从缓存读取数据
    @Publish public var onlyRetrieveFromCache: Option<Bool> = Option<Bool>.None

}

@Component
public class GlideImageZJ {

    @Link @Watch[onOptionChanged]
    var option: GlideRequestOption


    var globalContext:Option<AbilityContext> = Option<AbilityContext>.None

    /*加载状态*/
    @State
    var isLoading: Bool = true
    /*错误状态*/
    @State
    var isError: Bool = false

    @Prop var beginFn: () -> Unit
    @Prop var endFn: () -> Unit

    var flag:Bool = false

    var oldWidth: Int64 = 0
    var oldHeight: Int64 = 0

    let size: Size = Size(width: 1, height: 1)
    //let opts : InitializationOptions = InitializationOptions(alphaType: OPAQUE, scaleMode: FIT_TARGET_SIZE, editable: true, pixelFormat: RGBA_8888, size: size);
	let opts: InitializationOptions = InitializationOptions(size:size)

    let color : Array<UInt8> = Array<UInt8>(96, item:0)
    @State var pixelMap: PixelMap = createPixelMap(color, opts)
//	@State var pixelMap: PixelMap = PixelMap(opts)

//    @StorageLink["pixelStore"]@Watch[imgChanged] var pixelStore: PixelMap = PixelMap(opts)
    //@StorageLink["pixelStore"]@Watch[imgChanged] var pixelStore: PixelMap = createPixelMap(color, opts)
 //   @State @Watch[imgChanged] var pixelStore: PixelMap = createPixelMap(color, opts)

 //   @State @Watch[imgError] var isErrorPicture: Bool = false



    // 生命周期：组件首次显示在屏幕上时调用
    public  func onAppear(key: String): Unit {
        AppLog.error("调了onAppear--------------------------------------------------------------------GlideImage")
        Glide.get(globalContext.getOrThrow()).onAppear(key)
    }
    //生命周期：组件从屏幕上消失时调用
    public  func onDisappear(key: String): Unit {
        AppLog.error("调了onDisAppear--------------------------------------------------------------------GlideImage")
        Glide.get(globalContext.getOrThrow()).onDisAppear(key)
    }

    func onOptionChanged() {
        AppLog.error("GlideImage onOptionChanged--------------------------------------------------------------------GlideImage")
        updateImg(oldWidth, oldHeight)
    }

//    func imgChanged() {
//        AppLog.error("glidelog- imgChanged1")
//        isLoading = false
//        this.pixelMap = pixelStore
//    }

//    func imgError() {
//       AppLog.error("glidelog- imgError")
//       isError = isErrorPicture
//    }



    func updateImg(width: Int64, height: Int64) {
        if(option.loadSrc != "" && width > 0 && height > 0) {
            beginFn()
            AppLog.error("进来了233--------------------------------------------------------------------GlideImage")
            AppLog.error("glide hhs updateImg run ${width} ${height} src=${option.loadSrc}--------------------------------------------------------------------GlideImage")

            //lp--20240326--???--label为空的时候，withContext相当于调用没有label这个参数的同名函数
            var glide = Glide.withContext(globalContext.getOrThrow(), option.label).load(option.loadSrc)
            //设置三级缓存策略
            if (let Some(v) <- option.strategy) {
                glide = glide.setDiskCacheStrategy(v)
            }

            if (let Some(v) <- option.onlyRetrieveFromCache) {
                glide = glide.onlyRetrieveFromCachecj(v,glide)
            }

            if (let Some(v) <- option.isSkipMemory) {
                glide = glide.skipMemoryCache(v,glide)
            }

            if (let Some(v) <- option.overrideWH) {
                glide = glide.setOverride(v[0],v[1])
            }

             if (let Some(v) <- option.transformCate) {
                glide = glide.transform(v)
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

            glide.listener({drawable: Drawable, model: Model, target: Target<Drawable>, datasource: DataSource, isFirstResource: Bool =>
                                endFn()
                                AppLog.error("load成功--------------------------------------------------------------------GlideImage")
                                return false
                            },
                            {e: GlideException, model: Model, target: Target<Drawable>, isFirstResource: Bool =>
                                AppLog.error("load失败--------------------------------------------------------------------GlideImage")
                                return false
                            })
            .into({p: PixelMap =>
                        AppLog.error("callback1--------------------------------------------------------------------GlideImage")
                        launch{
                            isLoading = false
                            pixelMap = p
                        }
                    },{cjres: CJResource,isErrorPic:Bool =>
                        AppLog.error("loaderror----------------------------------------------------${isErrorPic}----------------GlideImage")
                        if(isErrorPic){
                            AppLog.error("isErrorPic--------------------------------------------------------------------GlideImage")
                            launch{
                                isError = true
                            }
                        }
                    }, width, height)

        }
    }


    func render(){
        Column(30){
                //Text("标记一下")
                if(isError){
                     if (let Some(w) <- option.errholder){
                            Image(w).width(100.percent).objectFit(ImageFit.ScaleDown)
                     }
                }else{
                    if(isLoading){
                            //Text("标记一下2")
                            if (let Some(v) <- option.placeholder){
                                //Text("标记一下2")
                                Image(v).width(100.percent).objectFit(ImageFit.ScaleDown)
                                    .onAreaChange({ oldArea, newArea =>
                                            let newWidth: Int64 = Int64(newArea.width)
                                            let newHeight: Int64 = Int64(newArea.height)
                                            AppLog.error("newWidth = ${newWidth} newHeight = ${newHeight}")
                                            if(oldWidth != newWidth || oldHeight != newHeight) {
                                                AppLog.error("进来了01--------------------------------------------------------------------GlideImage")
                                                if(!flag && newWidth>0 && newHeight>0){
                                                    AppLog.error("进来了02--------------------------------------------------------------------GlideImage")
                                                    flag = true
                                                    updateImg(newWidth, newHeight)
                                                    oldWidth = newWidth
                                                    oldHeight = newHeight
                                                }

                                            }
                                        })
                            }else{
                                //Text("占位图有错误")
                            }
                        }else{
                            //Text("标记一下3")
                             Image(pixelMap).width(100.percent)
                                .objectFit(ImageFit.ScaleDown)
                            }
                    }

        }
    }
}

