//package zujianbao
/////**
//// * Created on 2024/3/4
//// */
//from ohos import state_macro_manage.*
//from ohos import base.*
//from ohos import component.*
//from ohos import image.Component as ImageComponent
//from ohos import image.Image as ImageImage
//from ohos import image.*
//from ohos import state_manage.*
//from ohos import ability.*
//
//from net import http.*
//from std import socket.*
//from net import tls.*
//from std import io.*
//from encoding import url.*
//from std import fs.*
//
//import glide.*
//import glide.add.*
//import glide.request.*
//import glide.executor.*
//import glide.util.utils.*
//
//import glide.request_options.*
//import glide.util.pool.*
//import glide.load.*
//import glide.util.*
//import glide.util.calculator.*
//import glide.engine.cache.memory_cache.*
//
//@Observed
//public class GlideRequestOption {
//    // @Publish var options: Option<GlideOptions> = None
//    //@Publish var overrideWidth: Int64 = 0//SIZE_ORIGINAL
//    //@Publish var overrideHeight: Int64 = 0//SIZE_ORIGINAL
//    //@Publish var signature: String = ""
//
//
//    // 加载一张本地的jpg资源（必选）
//    @Publish var loadSrc: String = ""
//    // 占位图使用本地资源icon_loading（可选）
//    @Publish var placeholder: Option<CJResource> = Option<CJResource>.None
//    // 失败占位图使用本地资源icon_failed（可选）
//    @Publish var errholder: Option<CJResource> = Option<CJResource>.None
//    // 磁盘缓存策略（可选）
//    @Publish var strategy: Option<DiskCacheStrategy> = Option<DiskCacheStrategy>.None
//    //生命周期管理用到的标签名称
//    @Publish var label: String = ""
//
//
//    //@Publish var requestListener: Option<(PixelMap) -> Bool> = Option<(PixelMap) -> Bool>.None
//
//}
//
//@Component
//public class GlideImageZJ {
//
//    @Link @Watch[onOptionChanged]
//    var option: GlideRequestOption
//
//
//    var globalContext:Option<AbilityContext> = Option<AbilityContext>.None
//
//    /*加载状态*/
//    @State
//    var isLoading: Bool = true
//    /*错误状态*/
//    @State
//    var isError: Bool = false
//
//    @Prop var beginFn: () -> Unit
//    @Prop var endFn: () -> Unit
//
//    var flag:Bool = false
//
//    var oldWidth: Int64 = 0
//    var oldHeight: Int64 = 0
//
//    let size: Size = Size(width: 1, height: 1)
//    //let opts : InitializationOptions = InitializationOptions(alphaType: OPAQUE, scaleMode: FIT_TARGET_SIZE, editable: true, pixelFormat: RGBA_8888, size: size);
//	let opts: InitializationOptions = InitializationOptions(size:size)
//
//    let color : Array<UInt8> = Array<UInt8>(96, item:0)
//    @State var pixelMap: PixelMap = createPixelMap(color, opts)
////	@State var pixelMap: PixelMap = PixelMap(opts)
//
////    @StorageLink["pixelStore"]@Watch[imgChanged] var pixelStore: PixelMap = PixelMap(opts)
//    //@StorageLink["pixelStore"]@Watch[imgChanged] var pixelStore: PixelMap = createPixelMap(color, opts)
//    @State @Watch[imgChanged] var pixelStore: PixelMap = createPixelMap(color, opts)
//
//    @State @Watch[imgError] var isErrorPicture: Bool = false
//
////    let callback: (PixelMap) -> Unit = {p: PixelMap =>
////        // AppLog.error("callback: ${p.getImageInfo().size.width} - ${p.getImageInfo().size.height}")
////        AppLog.error("callback1")
////        //AppStorage.Set<PixelMap>("pixelStore", p)
////        pixelStore = p
////
////    }
//
//
//    // 生命周期：组件首次显示在屏幕上时调用
//    public  func onAppear(key: String): Unit {
//        AppLog.error("调了onAppear--------------------------------------------------------------------GlideImage")
//        Glide.get(globalContext.getOrThrow()).onAppear(key)
//    }
//    //生命周期：组件从屏幕上消失时调用
//    public  func onDisappear(key: String): Unit {
//        AppLog.error("调了onDisAppear--------------------------------------------------------------------GlideImage")
//        Glide.get(globalContext.getOrThrow()).onDisAppear(key)
//    }
//
//    func onOptionChanged() {
//        AppLog.error("GlideImage onOptionChanged--------------------------------------------------------------------GlideImage")
//        updateImg(oldWidth, oldHeight)
//    }
//
//    func imgChanged() {
//        AppLog.error("glidelog- imgChanged1")
//        isLoading = false
//        this.pixelMap = pixelStore
//    }
//
//    func imgError() {
//       AppLog.error("glidelog- imgError")
//       isError = isErrorPicture
//    }
//
//
//
//    func updateImg(width: Int64, height: Int64) {
//        if(option.loadSrc != "" && width > 0 && height > 0) {
//            beginFn()
//            AppLog.error("进来了233--------------------------------------------------------------------GlideImage")
//            AppLog.error("glide hhs updateImg run ${width} ${height} src=${option.loadSrc}--------------------------------------------------------------------GlideImage")
//
//            //lp--20240326--???--label为空的时候，withContext相当于调用没有label这个参数的同名函数
//            var glide = Glide.withContext(globalContext.getOrThrow(), option.label).load(option.loadSrc)
//            //设置三级缓存策略
//            if (let Some(v) <- option.strategy) {
//                glide = glide.setDiskCacheStrategy(v)
//            }
//            //设置占位符
//            if (let Some(v) <- option.placeholder) {
//                glide = glide.placeholder(v)
//            }
//            //设置错误占位符
//            if (let Some(v) <- option.errholder) {
//                glide = glide.error(v)
//            }
//
//            glide.listener({drawable: Drawable, model: Model, target: Target<Drawable>, datasource: DataSource, isFirstResource: Bool =>
//                                endFn()
//                                AppLog.error("load成功--------------------------------------------------------------------GlideImage")
//                                return false
//                            },
//                            {e: GlideException, model: Model, target: Target<Drawable>, isFirstResource: Bool =>
//                                AppLog.error("load失败--------------------------------------------------------------------GlideImage")
//                                return false
//                            })
//            .into({p: PixelMap =>
//                        AppLog.error("callback1--------------------------------------------------------------------GlideImage")
//                        pixelStore = p
//                    },{cjres: CJResource,isErrorPic:Bool =>
//                        AppLog.error("loaderror----------------------------------------------------${isErrorPic}----------------GlideImage")
//                        if(isErrorPic){
//                            AppLog.error("isErrorPic--------------------------------------------------------------------GlideImage")
//                            isErrorPicture = true
//                        }
//                    }, width, height)
//
//        }
//    }
//
//
//    func render(){
//        Column(30){
//                //Text("标记一下")
//                if(isError){
//                     if (let Some(w) <- option.errholder){
//                            Image(w).width(100.percent).objectFit(ImageFit.ScaleDown)
//                     }
//                }else{
//                    if(isLoading){
//                            //Text("标记一下2")
//                            if (let Some(v) <- option.placeholder){
//                                //Text("标记一下2")
//                                Image(v).width(100.percent).objectFit(ImageFit.ScaleDown)
//                                    .onAreaChange({ oldArea, newArea =>
//                                            let newWidth: Int64 = Int64(newArea.width)
//                                            let newHeight: Int64 = Int64(newArea.height)
//                                            AppLog.error("newWidth = ${newWidth} newHeight = ${newHeight}")
//                                            if(oldWidth != newWidth || oldHeight != newHeight) {
//                                                AppLog.error("进来了01--------------------------------------------------------------------GlideImage")
//                                                if(!flag){
//                                                    AppLog.error("进来了02--------------------------------------------------------------------GlideImage")
//                                                    flag = true
//                                                    updateImg(newWidth, newHeight)
//                                                    oldWidth = newWidth
//                                                    oldHeight = newHeight
//                                                }
//
//                                            }
//                                        })
//                            }else{
//                                //Text("占位图有错误")
//                            }
//                        }else{
//                            //Text("标记一下3")
//                             Image(pixelMap).width(100.percent)
//                                .objectFit(ImageFit.ScaleDown)
//                            }
//                    }
//
//        }
//    }
//}

package zujianbao
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

from net import http.*
from std import socket.*
from net import tls.*
from std import io.*
from encoding import url.*
from std import fs.*

import glide.*
import glide.add.*
import glide.request.*
import glide.executor.*
import glide.util.utils.*

import glide.request_options.*
import glide.util.pool.*
import glide.load.*
import glide.util.*
import glide.util.calculator.*
import glide.engine.cache.memory_cache.*

/* ===== Emitted by MacroCall @Observed in glide_image_zujian.cj:34:1 ===== */
/* 34.1 */public class GlideRequestOption <: ObservedObject {
/* 34.2 */
/* 34.3 */    public var stateVarDecl_loadSrc_: ObservedProperty < String >= ObservedProperty < String >("stateVarDecl_loadSrc_", "")
/* 34.4 */
/* 34.5 */    public mut prop loadSrc: String {
/* 34.6 */        get() {
/* 34.7 */            return this.stateVarDecl_loadSrc_.get()
/* 34.8 */        }
/* 34.9 */        set(v) {
/* 34.10 */            this.stateVarDecl_loadSrc_.set(v)
/* 34.11 */        }
/* 34.12 */    }
/* 34.13 */
/* 34.14 */    private var stateVarDecl_placeholder_: ObservedProperty < Option < CJResource >>= ObservedProperty < Option < CJResource >>("stateVarDecl_placeholder_", Option < CJResource >.None)
/* 34.15 */
/* 34.16 */    mut prop placeholder: Option < CJResource > {
/* 34.17 */        get() {
/* 34.18 */            return this.stateVarDecl_placeholder_.get()
/* 34.19 */        }
/* 34.20 */        set(v) {
/* 34.21 */            this.stateVarDecl_placeholder_.set(v)
/* 34.22 */        }
/* 34.23 */    }
/* 34.24 */
/* 34.25 */    private var stateVarDecl_errholder_: ObservedProperty < Option < CJResource >>= ObservedProperty < Option < CJResource >>("stateVarDecl_errholder_", Option < CJResource >.None)
/* 34.26 */
/* 34.27 */    mut prop errholder: Option < CJResource > {
/* 34.28 */        get() {
/* 34.29 */            return this.stateVarDecl_errholder_.get()
/* 34.30 */        }
/* 34.31 */        set(v) {
/* 34.32 */            this.stateVarDecl_errholder_.set(v)
/* 34.33 */        }
/* 34.34 */    }
/* 34.35 */
/* 34.36 */    private var stateVarDecl_strategy_: ObservedProperty < Option < DiskCacheStrategy >>= ObservedProperty < Option < DiskCacheStrategy >>("stateVarDecl_strategy_", Option < DiskCacheStrategy >.None)
/* 34.37 */
/* 34.38 */    mut prop strategy: Option < DiskCacheStrategy > {
/* 34.39 */        get() {
/* 34.40 */            return this.stateVarDecl_strategy_.get()
/* 34.41 */        }
/* 34.42 */        set(v) {
/* 34.43 */            this.stateVarDecl_strategy_.set(v)
/* 34.44 */        }
/* 34.45 */    }
/* 34.46 */
/* 34.47 */    public var stateVarDecl_label_: ObservedProperty < String >= ObservedProperty < String >("stateVarDecl_label_", "")
/* 34.48 */
/* 34.49 */    public mut prop label: String {
/* 34.50 */        get() {
/* 34.51 */            return this.stateVarDecl_label_.get()
/* 34.52 */        }
/* 34.53 */        set(v) {
/* 34.54 */            this.stateVarDecl_label_.set(v)
/* 34.55 */        }
/* 34.56 */    }
/* 34.57 */
/* 34.58 */
/* 34.59 */
/* 34.60 */  public init(loadSrc!: Option < String >= None, placeholder!: Option < Option < CJResource >>= None, errholder!: Option < Option < CJResource >>= None, strategy!: Option < Option < DiskCacheStrategy >>= None, label!: Option < String >= None) {
/* 34.61 */
/* 34.62 */        match(loadSrc) {
/* 34.63 */            case Some(v) => this.stateVarDecl_loadSrc_ = ObservedProperty < String >("stateVarDecl_loadSrc_", v)
/* 34.64 */            case _ =>()
/* 34.65 */        }
/* 34.66 */
/* 34.67 */        match(placeholder) {
/* 34.68 */            case Some(v) => this.stateVarDecl_placeholder_ = ObservedProperty < Option < CJResource >>("stateVarDecl_placeholder_", v)
/* 34.69 */            case _ =>()
/* 34.70 */        }
/* 34.71 */
/* 34.72 */        match(errholder) {
/* 34.73 */            case Some(v) => this.stateVarDecl_errholder_ = ObservedProperty < Option < CJResource >>("stateVarDecl_errholder_", v)
/* 34.74 */            case _ =>()
/* 34.75 */        }
/* 34.76 */
/* 34.77 */        match(strategy) {
/* 34.78 */            case Some(v) => this.stateVarDecl_strategy_ = ObservedProperty < Option < DiskCacheStrategy >>("stateVarDecl_strategy_", v)
/* 34.79 */            case _ =>()
/* 34.80 */        }
/* 34.81 */
/* 34.82 */        match(label) {
/* 34.83 */            case Some(v) => this.stateVarDecl_label_ = ObservedProperty < String >("stateVarDecl_label_", v)
/* 34.84 */            case _ =>()
/* 34.85 */        }
/* 34.86 */
/* 34.87 */
/* 34.88 */        this.addPublishVar(this.stateVarDecl_loadSrc_)
/* 34.89 */        this.addPropsInfo("stateVarDecl_loadSrc_")
/* 34.90 */
/* 34.91 */        this.addPublishVar(this.stateVarDecl_placeholder_)
/* 34.92 */        this.addPropsInfo("stateVarDecl_placeholder_")
/* 34.93 */
/* 34.94 */        this.addPublishVar(this.stateVarDecl_errholder_)
/* 34.95 */        this.addPropsInfo("stateVarDecl_errholder_")
/* 34.96 */
/* 34.97 */        this.addPublishVar(this.stateVarDecl_strategy_)
/* 34.98 */        this.addPropsInfo("stateVarDecl_strategy_")
/* 34.99 */
/* 34.100 */        this.addPublishVar(this.stateVarDecl_label_)
/* 34.101 */        this.addPropsInfo("stateVarDecl_label_")
/* 34.102 */
/* 34.103 */    }
/* 34.104 */
/* 34.105 */
/* 34.106 */
/* 34.107 */    public func set(newValue: ObservedComplexAbstract) {
/* 34.108 */
/* 34.109 */        let realValue =(newValue as GlideRequestOption).getOrThrow()
/* 34.110 */
/* 34.111 */        this.loadSrc = realValue.loadSrc
/* 34.112 */
/* 34.113 */        this.placeholder = realValue.placeholder
/* 34.114 */
/* 34.115 */        this.errholder = realValue.errholder
/* 34.116 */
/* 34.117 */        this.strategy = realValue.strategy
/* 34.118 */
/* 34.119 */        this.label = realValue.label
/* 34.120 */
/* 34.121 */        ()
/* 34.122 */    }
/* 34.123 */
/* 34.124 */
/* 34.125 */}
/* 34.126 */
/* ===== End of the Emit ===== */

/* ===== Emitted by MacroCall @Component in glide_image_zujian.cj:58:1 ===== */
/* 58.1 */public class GlideImageZJ <: CustomView {
/* 58.2 */
/* 58.3 */
/* 58.4 */    private var stateVarDecl_option_: ObservedProperty < GlideRequestOption >
/* 58.5 */
/* 58.6 */
/* 58.7 */    private mut prop option: GlideRequestOption {
/* 58.8 */        get() {
/* 58.9 */            return this.stateVarDecl_option_.get()
/* 58.10 */        }
/* 58.11 */        set(v) {
/* 58.12 */            this.stateVarDecl_option_.set(v)
/* 58.13 */        }
/* 58.14 */    }
/* 58.15 */
/* 58.16 */
/* 58.17 */    var globalContext: Option < AbilityContext >= Option < AbilityContext >.None
/* 58.18 */
/* 58.19 */
/* 58.20 */    private var stateVarDecl_isLoading_: ObservedProperty < Bool >= ObservedProperty < Bool >("stateVarDecl_isLoading_", true)
/* 58.21 */
/* 58.22 */
/* 58.23 */    private mut prop isLoading: Bool {
/* 58.24 */        get() {
/* 58.25 */            return this.stateVarDecl_isLoading_.get()
/* 58.26 */        }
/* 58.27 */        set(v) {
/* 58.28 */            this.stateVarDecl_isLoading_.set(v)
/* 58.29 */        }
/* 58.30 */    }
/* 58.31 */
/* 58.32 */
/* 58.33 */    private var stateVarDecl_isError_: ObservedProperty < Bool >= ObservedProperty < Bool >("stateVarDecl_isError_", false)
/* 58.34 */
/* 58.35 */
/* 58.36 */    private mut prop isError: Bool {
/* 58.37 */        get() {
/* 58.38 */            return this.stateVarDecl_isError_.get()
/* 58.39 */        }
/* 58.40 */        set(v) {
/* 58.41 */            this.stateVarDecl_isError_.set(v)
/* 58.42 */        }
/* 58.43 */    }
/* 58.44 */
/* 58.45 */
/* 58.46 */    private var stateVarDecl_beginFn_: ObservedProperty <() -> Unit >
/* 58.47 */
/* 58.48 */
/* 58.49 */    private mut prop beginFn:() -> Unit {
/* 58.50 */        get() {
/* 58.51 */            return this.stateVarDecl_beginFn_.get()
/* 58.52 */        }
/* 58.53 */        set(v) {
/* 58.54 */            this.stateVarDecl_beginFn_.set(v)
/* 58.55 */        }
/* 58.56 */    }
/* 58.57 */
/* 58.58 */
/* 58.59 */    private var stateVarDecl_endFn_: ObservedProperty <() -> Unit >
/* 58.60 */
/* 58.61 */
/* 58.62 */    private mut prop endFn:() -> Unit {
/* 58.63 */        get() {
/* 58.64 */            return this.stateVarDecl_endFn_.get()
/* 58.65 */        }
/* 58.66 */        set(v) {
/* 58.67 */            this.stateVarDecl_endFn_.set(v)
/* 58.68 */        }
/* 58.69 */    }
/* 58.70 */
/* 58.71 */
/* 58.72 */    var flag: Bool = false
/* 58.73 */
/* 58.74 */
/* 58.75 */    var oldWidth: Int64 = 0
/* 58.76 */
/* 58.77 */
/* 58.78 */    var oldHeight: Int64 = 0
/* 58.79 */
/* 58.80 */
/* 58.81 */    let size: Size = Size(width: 1, height: 1)
/* 58.82 */
/* 58.83 */
/* 58.84 */    let opts: InitializationOptions = InitializationOptions(size: size)
/* 58.85 */
/* 58.86 */
/* 58.87 */    let color: Array < UInt8 >= Array < UInt8 >(96, item: 0)
/* 58.88 */
/* 58.89 */
/* 58.90 */    private var stateVarDecl_pixelMap_: ObservedProperty < PixelMap >= ObservedProperty < PixelMap >("stateVarDecl_pixelMap_", createPixelMap(color, opts))
/* 58.91 */
/* 58.92 */
/* 58.93 */    private mut prop pixelMap: PixelMap {
/* 58.94 */        get() {
/* 58.95 */            return this.stateVarDecl_pixelMap_.get()
/* 58.96 */        }
/* 58.97 */        set(v) {
/* 58.98 */            this.stateVarDecl_pixelMap_.set(v)
/* 58.99 */        }
/* 58.100 */    }
/* 58.101 */
/* 58.102 */
/* 58.103 */    private var stateVarDecl_pixelStore_: ObservedProperty < PixelMap >= ObservedProperty < PixelMap >("stateVarDecl_pixelStore_", createPixelMap(color, opts))
/* 58.104 */
/* 58.105 */
/* 58.106 */    private mut prop pixelStore: PixelMap {
/* 58.107 */        get() {
/* 58.108 */            return this.stateVarDecl_pixelStore_.get()
/* 58.109 */        }
/* 58.110 */        set(v) {
/* 58.111 */            this.stateVarDecl_pixelStore_.set(v)
/* 58.112 */        }
/* 58.113 */    }
/* 58.114 */
/* 58.115 */
/* 58.116 */    private var stateVarDecl_isErrorPicture_: ObservedProperty < Bool >= ObservedProperty < Bool >("stateVarDecl_isErrorPicture_", false)
/* 58.117 */
/* 58.118 */
/* 58.119 */    private mut prop isErrorPicture: Bool {
/* 58.120 */        get() {
/* 58.121 */            return this.stateVarDecl_isErrorPicture_.get()
/* 58.122 */        }
/* 58.123 */        set(v) {
/* 58.124 */            this.stateVarDecl_isErrorPicture_.set(v)
/* 58.125 */        }
/* 58.126 */    }
/* 58.127 */
/* 58.128 */
/* 58.129 */    public func onAppear(key: String): Unit {
/* 58.130 */        AppLog.error("调了onAppear--------------------------------------------------------------------GlideImage")
/* 58.131 */        Glide.get(globalContext.getOrThrow()).onAppear(key)
/* 58.132 */    }
/* 58.133 */
/* 58.134 */
/* 58.135 */    public func onDisappear(key: String): Unit {
/* 58.136 */        AppLog.error("调了onDisAppear--------------------------------------------------------------------GlideImage")
/* 58.137 */        Glide.get(globalContext.getOrThrow()).onDisAppear(key)
/* 58.138 */    }
/* 58.139 */
/* 58.140 */
/* 58.141 */    func onOptionChanged() {
/* 58.142 */        AppLog.error("GlideImage onOptionChanged--------------------------------------------------------------------GlideImage")
/* 58.143 */        updateImg(oldWidth, oldHeight)
/* 58.144 */    }
/* 58.145 */
/* 58.146 */
/* 58.147 */    func imgChanged() {
/* 58.148 */        AppLog.error("glidelog- imgChanged1")
/* 58.149 */        isLoading = false
/* 58.150 */        this.pixelMap = pixelStore
/* 58.151 */    }
/* 58.152 */
/* 58.153 */
/* 58.154 */    func imgError() {
/* 58.155 */        AppLog.error("glidelog- imgError")
/* 58.156 */        isError = isErrorPicture
/* 58.157 */    }
/* 58.158 */
/* 58.159 */
/* 58.160 */    func updateImg(width: Int64, height: Int64) {
/* 58.161 */        if(option.loadSrc != "" && width > 0 && height > 0) {
/* 58.162 */            beginFn()
/* 58.163 */            AppLog.error("进来了233--------------------------------------------------------------------GlideImage")
/* 58.164 */            AppLog.error("glide hhs updateImg run ${width} ${height} src=${option.loadSrc}--------------------------------------------------------------------GlideImage")
/* 58.165 */            var glide = Glide.withContext(globalContext.getOrThrow(), option.label).load(option.loadSrc)
/* 58.166 */            if(let Some(v) <- option.strategy) {
/* 58.167 */                glide = glide.setDiskCacheStrategy(v)
/* 58.168 */            }
/* 58.169 */            if(let Some(v) <- option.placeholder) {
/* 58.170 */                glide = glide.placeholder(v)
/* 58.171 */            }
/* 58.172 */            if(let Some(v) <- option.errholder) {
/* 58.173 */                glide = glide.error(v)
/* 58.174 */            }
/* 58.175 */            glide.listener({ drawable: Drawable, model: Model, target: Target < Drawable >, datasource: DataSource, isFirstResource: Bool => endFn()
/* 58.176 */                AppLog.error("load成功--------------------------------------------------------------------GlideImage")
/* 58.177 */            return false }, { e: GlideException, model: Model, target: Target < Drawable >, isFirstResource: Bool => AppLog.error("load失败--------------------------------------------------------------------GlideImage")
/* 58.178 */            return false }).into({ p: PixelMap => AppLog.error("callback1--------------------------------------------------------------------GlideImage")
/* 58.179 */            pixelStore = p }, { cjres: CJResource, isErrorPic: Bool => AppLog.error("loaderror----------------------------------------------------${isErrorPic}----------------GlideImage")
/* 58.180 */                if(isErrorPic) {
/* 58.181 */                    AppLog.error("isErrorPic--------------------------------------------------------------------GlideImage")
/* 58.182 */                    isErrorPicture = true
/* 58.183 */                }
/* 58.184 */            }, width, height)
/* 58.185 */        }
/* 58.186 */    }
/* 58.187 */
/* 58.188 */
/* 58.189 */
/* 58.190 */    public func render() {
/* 58.191 */
/* 58.192 */        this.observeComponentCreation({ elmtId, isInitialRender =>
/* 58.193 */            Column(30) { observeComponentCreation({ elmtId, isInitialRender => If { if(isError) {
/* 58.194 */                this.ifElseBranchUpdateFunction(0, { => observeComponentCreation({ elmtId, isInitialRender => If { if(let Some(w) <- option.errholder) {
/* 58.195 */                    this.ifElseBranchUpdateFunction(0, { => this.observeComponentCreation({ elmtId, isInitialRender => Image(w).width(100.percent).objectFit(ImageFit.ScaleDown) }) })
/* 58.196 */                }
/* 58.197 */                else {
/* 58.198 */                    If.branchId(1)
/* 58.199 */                }
/* 58.200 */            } }) })
/* 58.201 */        }
/* 58.202 */        else {
/* 58.203 */            this.ifElseBranchUpdateFunction(1, { => observeComponentCreation({ elmtId, isInitialRender => If { if(isLoading) {
/* 58.204 */                this.ifElseBranchUpdateFunction(0, { => observeComponentCreation({ elmtId, isInitialRender => If { if(let Some(v) <- option.placeholder) {
/* 58.205 */                    this.ifElseBranchUpdateFunction(0, { => this.observeComponentCreation({ elmtId, isInitialRender => Image(v).width(100.percent).objectFit(ImageFit.ScaleDown).onAreaChange({ oldArea, newArea => let newWidth: Int64 = Int64(newArea.width)
/* 58.206 */
/* 58.207 */                        let newHeight: Int64 = Int64(newArea.height)
/* 58.208 */
/* 58.209 */                        AppLog.error("newWidth = ${newWidth} newHeight = ${newHeight}")
/* 58.210 */                        if(oldWidth != newWidth || oldHeight != newHeight) {
/* 58.211 */                            AppLog.error("进来了01--------------------------------------------------------------------GlideImage")
/* 58.212 */                            if(! flag) {
/* 58.213 */                                AppLog.error("进来了02--------------------------------------------------------------------GlideImage")
/* 58.214 */                                flag = true
/* 58.215 */                                updateImg(newWidth, newHeight)
/* 58.216 */                                oldWidth = newWidth
/* 58.217 */                                oldHeight = newHeight
/* 58.218 */                            }
/* 58.219 */                        }
/* 58.220 */                    }) }) })
/* 58.221 */                }
/* 58.222 */                else {
/* 58.223 */                    this.ifElseBranchUpdateFunction(1, { => })
/* 58.224 */                }
/* 58.225 */            } }) })
/* 58.226 */        }
/* 58.227 */        else {
/* 58.228 */            this.ifElseBranchUpdateFunction(1, { => this.observeComponentCreation({ elmtId, isInitialRender => Image(pixelMap).width(100.percent).objectFit(ImageFit.ScaleDown) }) })
/* 58.229 */        }
/* 58.230 */    } }) })
/* 58.231 */}
/* 58.232 */} }) }
/* 58.233 */})
/* 58.234 */
/* 58.235 */()
/* 58.236 */}
/* 58.237 */
/* 58.238 */
/* 58.239 */public init(parent: Option < CustomView >, option!: ObservedProperty < GlideRequestOption >, globalContext!: Option < ObservedProperty < Option < AbilityContext >>>= None, isLoading!: Option < ObservedProperty < Bool >>= None, isError!: Option < ObservedProperty < Bool >>= None, beginFn!: ObservedProperty <() -> Unit >, endFn!: ObservedProperty <() -> Unit >, flag!: Option < ObservedProperty < Bool >>= None, oldWidth!: Option < ObservedProperty < Int64 >>= None, oldHeight!: Option < ObservedProperty < Int64 >>= None, pixelMap!: Option < ObservedProperty < PixelMap >>= None, pixelStore!: Option < ObservedProperty < PixelMap >>= None, isErrorPicture!: Option < ObservedProperty < Bool >>= None) {
/* 58.240 */super(parent)
/* 58.241 */
/* 58.242 */this.stateVarDecl_option_ = option
/* 58.243 */
/* 58.244 */match(globalContext) {
/* 58.245 */case Some(v) => this.globalContext = v.get()
/* 58.246 */case _ =>()
/* 58.247 */}
/* 58.248 */
/* 58.249 */match(isLoading) {
/* 58.250 */case Some(v) => this.stateVarDecl_isLoading_ = ObservedProperty < Bool >("stateVarDecl_isLoading_", v.get())
/* 58.251 */case _ =>()
/* 58.252 */}
/* 58.253 */
/* 58.254 */match(isError) {
/* 58.255 */case Some(v) => this.stateVarDecl_isError_ = ObservedProperty < Bool >("stateVarDecl_isError_", v.get())
/* 58.256 */case _ =>()
/* 58.257 */}
/* 58.258 */
/* 58.259 */this.stateVarDecl_beginFn_ = beginFn.createProp("stateVarDecl_beginFn_")
/* 58.260 */
/* 58.261 */this.stateVarDecl_endFn_ = endFn.createProp("stateVarDecl_endFn_")
/* 58.262 */
/* 58.263 */match(flag) {
/* 58.264 */case Some(v) => this.flag = v.get()
/* 58.265 */case _ =>()
/* 58.266 */}
/* 58.267 */
/* 58.268 */match(oldWidth) {
/* 58.269 */case Some(v) => this.oldWidth = v.get()
/* 58.270 */case _ =>()
/* 58.271 */}
/* 58.272 */
/* 58.273 */match(oldHeight) {
/* 58.274 */case Some(v) => this.oldHeight = v.get()
/* 58.275 */case _ =>()
/* 58.276 */}
/* 58.277 */
/* 58.278 */match(pixelMap) {
/* 58.279 */case Some(v) => this.stateVarDecl_pixelMap_ = ObservedProperty < PixelMap >("stateVarDecl_pixelMap_", v.get())
/* 58.280 */case _ =>()
/* 58.281 */}
/* 58.282 */
/* 58.283 */match(pixelStore) {
/* 58.284 */case Some(v) => this.stateVarDecl_pixelStore_ = ObservedProperty < PixelMap >("stateVarDecl_pixelStore_", v.get())
/* 58.285 */case _ =>()
/* 58.286 */}
/* 58.287 */
/* 58.288 */match(isErrorPicture) {
/* 58.289 */case Some(v) => this.stateVarDecl_isErrorPicture_ = ObservedProperty < Bool >("stateVarDecl_isErrorPicture_", v.get())
/* 58.290 */case _ =>()
/* 58.291 */}
/* 58.292 */
/* 58.293 */
/* 58.294 */this.stateVarDecl_option_.subscribeEx(this)
/* 58.295 */
/* 58.296 */this.stateVarDecl_isLoading_.subscribeEx(this)
/* 58.297 */
/* 58.298 */this.stateVarDecl_isError_.subscribeEx(this)
/* 58.299 */
/* 58.300 */this.stateVarDecl_beginFn_.subscribeEx(this)
/* 58.301 */
/* 58.302 */this.stateVarDecl_endFn_.subscribeEx(this)
/* 58.303 */
/* 58.304 */this.stateVarDecl_pixelMap_.subscribeEx(this)
/* 58.305 */
/* 58.306 */this.stateVarDecl_pixelStore_.subscribeEx(this)
/* 58.307 */
/* 58.308 */this.stateVarDecl_isErrorPicture_.subscribeEx(this)
/* 58.309 */
/* 58.310 */SubscriberManager.getInstance().add(this)
/* 58.311 */
/* 58.312 */
/* 58.313 */this.declareWatch < GlideRequestOption >(stateVarDecl_option_, onOptionChanged)
/* 58.314 */
/* 58.315 */this.declareWatch < PixelMap >(stateVarDecl_pixelStore_, imgChanged)
/* 58.316 */
/* 58.317 */this.declareWatch < Bool >(stateVarDecl_isErrorPicture_, imgError)
/* 58.318 */
/* 58.319 */registerSelf()
/* 58.320 */}
/* 58.321 */
/* 58.322 */
/* 58.323 */public func aboutToBeDeleted() {
/* 58.324 */SubscriberManager.getInstance().delete(this)
/* 58.325 */}
/* 58.326 */
/* 58.327 */
/* 58.328 */func updateWithValueParams(option!: Option < GlideRequestOption >= Option < GlideRequestOption >.None, globalContext!: Option < Option < AbilityContext >>= Option < Option < AbilityContext >>.None, isLoading!: Option < Bool >= Option < Bool >.None, isError!: Option < Bool >= Option < Bool >.None, beginFn!: Option <() -> Unit >= Option <() -> Unit >.None, endFn!: Option <() -> Unit >= Option <() -> Unit >.None, flag!: Option < Bool >= Option < Bool >.None, oldWidth!: Option < Int64 >= Option < Int64 >.None, oldHeight!: Option < Int64 >= Option < Int64 >.None, pixelMap!: Option < PixelMap >= Option < PixelMap >.None, pixelStore!: Option < PixelMap >= Option < PixelMap >.None, isErrorPicture!: Option < Bool >= Option < Bool >.None): Unit {
/* 58.329 */
/* 58.330 */match(isLoading) {
/* 58.331 */case Some(v) => this.isLoading = v
/* 58.332 */case _ =>()
/* 58.333 */}
/* 58.334 */
/* 58.335 */match(isError) {
/* 58.336 */case Some(v) => this.isError = v
/* 58.337 */case _ =>()
/* 58.338 */}
/* 58.339 */
/* 58.340 */match(beginFn) {
/* 58.341 */case Some(v) => this.beginFn = v
/* 58.342 */case _ =>()
/* 58.343 */}
/* 58.344 */
/* 58.345 */match(endFn) {
/* 58.346 */case Some(v) => this.endFn = v
/* 58.347 */case _ =>()
/* 58.348 */}
/* 58.349 */
/* 58.350 */match(pixelMap) {
/* 58.351 */case Some(v) => this.pixelMap = v
/* 58.352 */case _ =>()
/* 58.353 */}
/* 58.354 */
/* 58.355 */match(pixelStore) {
/* 58.356 */case Some(v) => this.pixelStore = v
/* 58.357 */case _ =>()
/* 58.358 */}
/* 58.359 */
/* 58.360 */match(isErrorPicture) {
/* 58.361 */case Some(v) => this.isErrorPicture = v
/* 58.362 */case _ =>()
/* 58.363 */}
/* 58.364 */
/* 58.365 */}
/* 58.366 */
/* 58.367 */
/* 58.368 */public func rerender() {
/* 58.369 */this.updateDirtyElements()
/* 58.370 */}
/* 58.371 */
/* 58.372 */
/* 58.373 */public func purgeVariableDependenciesOnElmtId(rmElmtId: Int64) {
/* 58.374 */
/* 58.375 */this.stateVarDecl_option_.purgeDependencyOnElmtId(rmElmtId)
/* 58.376 */
/* 58.377 */this.stateVarDecl_isLoading_.purgeDependencyOnElmtId(rmElmtId)
/* 58.378 */
/* 58.379 */this.stateVarDecl_isError_.purgeDependencyOnElmtId(rmElmtId)
/* 58.380 */
/* 58.381 */this.stateVarDecl_beginFn_.purgeDependencyOnElmtId(rmElmtId)
/* 58.382 */
/* 58.383 */this.stateVarDecl_endFn_.purgeDependencyOnElmtId(rmElmtId)
/* 58.384 */
/* 58.385 */this.stateVarDecl_pixelMap_.purgeDependencyOnElmtId(rmElmtId)
/* 58.386 */
/* 58.387 */this.stateVarDecl_pixelStore_.purgeDependencyOnElmtId(rmElmtId)
/* 58.388 */
/* 58.389 */this.stateVarDecl_isErrorPicture_.purgeDependencyOnElmtId(rmElmtId)
/* 58.390 */
/* 58.391 */}
/* 58.392 */
/* 58.393 */
/* 58.394 */}
/* 58.395 */
/* ===== End of the Emit ===== */
