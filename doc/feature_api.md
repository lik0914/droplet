
## droplet

### 介绍
专注于平滑滚动的图像加载和缓存库，Glide支持获取、解码和显示视频剧照、图像和动画GIF。

- 生命周期管理
- 静态图像加载
- 设置加载中和加载失败图片以及压缩图
- 加载 gif 图片资源
- 支持三级缓存策略
- 支持transform动画转换
- 支持自定义组件方式加载

### 1 Glide 图片处理库

#### 1.1 Glide 全局单例对象类

```cangjie
public class Glide {
    
    /**
     * 获取图片处理库实例对象
     * 
     * @参数 context - AbilityContext数据类型，上下文
     * @返回值 Glide 图片处理库实例对象
     */
    public static func get(context: AbilityContext): Glide

    /**
     * 根据页面标记，获取绑定的图片请求管理器实例对象，每个页面有一个单独的图片请求管理器。
     * 
     * @参数 context - AbilityContext数据类型，上下文
     * @返回值 RequestManager 图片请求管理器
     */
    public static func withContext(context: AbilityContext): RequestManager

    /**
     * 根据页面标记，获取绑定的图片请求管理器实例对象，每个页面有一个单独的图片请求管理器。
     * 
     * @参数 context - AbilityContext数据类型，上下文
     * @参数 label - String数据类型，标签，用于绑定生命周期
     * @返回值 RequestManager 图片请求管理器
     */
    public static func withContext(context: AbilityContext, label: String): RequestManager

    /**
     * 页面生命周期事件绑定函数，需在页面显示回调函数中调用。
     */
    public func onAppear(): Unit

    /**
     * 页面生命周期事件绑定函数，需在页面显示回调函数中调用。
     * 
     * @参数 key - String数据类型
     */
    public func onAppear(key: String): Unit

    /**
     * 页面生命周期事件绑定函数，需在页面隐藏回调函数中调用
     */
    public func onDisAppear(): Unit

    /**
     * 页面生命周期事件绑定函数，需在页面隐藏回调函数中调用
     * 
     * @参数 key - String数据类型
     */
    public func onDisAppear(key: String): Unit
    
    /**
     * 清空MemoryCache 注：不是活跃内存缓存
     * 
     * @参数 key - String数据类型
     */
    public func clearMemory(): Unit

    
}
```

#### 1.2 RequestManager 图片请求管理器

```cangjie
public class RequestManager <: ModelTypes<RequestBuilder<Drawable>> & LifecycleListener & Equatable<RequestManager> {
    
    /**
     * 根据传入的图片文件生成图片请求构建器实例
     * 
     * @参数 model - File数据类型，图片文件
     * @返回值 RequestBuilder<Drawable> 请求构建器实例
     */
    public func load(model: File): RequestBuilder<Drawable>

    /**
     * 根据传入的图片请求路径生成图片请求构建器实例
     * 
     * @参数 model - String数据类型，图片文件来了路径
     * @返回值 RequestBuilder<Drawable> 请求构建器实例
     */
    public func load(model: String): RequestBuilder<Drawable>

    /**
     * 根为图片请求管理器设置默认的图片加载设置，此图片请求管理器生成的所有请求默认都使用此配置。
     * 
     * @参数 requestOptions - RequestOptions数据类型，请求设置
     * @返回值 RequestManager 图片请求管理器
     */
    public func useDefaultRequestOptions(requestOptions: RequestOptions): RequestManager
}
```

#### 2.1 BaseRequestOptions<T> 基本请求参数设置

```cangjie
public open class BaseRequestOptions<T> <: AnyRequestOptions where T <: BaseRequestOptions<T> {

    /**
     * 设置磁盘缓存策略
     * 
     * @参数 strategy - DiskCacheStrategy数据类型
     * @返回值 T 泛型数据类型
     */
    public func setDiskCacheStrategy(strategy: DiskCacheStrategy): T

    /**
     * 设置占位图，只支持静态图片资源
     * 
     * @参数 res - CJResource数据类型，静态图片资源
     * @返回值 T 泛型数据类型
     */
    public func placeholder(res: CJResource): T

    /**
     * 设置错误图，只支持静态图片资源
     * 
     * @参数 res - CJResource数据类型，静态图片资源
     * @返回值 T 泛型数据类型
     */
    public func error(res: CJResource): T
    
    /**
     * 禁用内存缓存。
     * 
     * @参数 skip - Bool数据类型
     * @参数 t - T泛型数据类型
     * @返回值 T 泛型数据类型
     */
    public func skipMemoryCache(skip: Bool, t: T): T
    
    /**
     * 只从缓存取数据。
     * 
     * @参数 flag - Bool数据类型
     * @参数 t - T泛型数据类型
     * @返回值 T 泛型数据类型
     */
    public func onlyRetrieveFromCachecj(flag:Bool,t:T):T{

    /**
     * 只从缓存加载图片资源。
     * 
     * @返回值 Bool 是否只从缓存加载图片资源
     */
    public func getOnlyRetrieveFromCache(): Bool
        
    /**
     * 设置图片宽高。
     * 
     * @参数 width - Int64图片宽度
     * @参数 height - Int64图片高度
     */
    public func setOverride(width:Int64,height:Int64)
            
     /**
     * 获取图片宽度。
     * 
     * @返回值 Int64 图片宽度
     */
    public func getOverrideWidth():Int64   
        
    /**
     * 获取图片高度。
     * 
     * @返回值 Int64 图片高度
     */
    public func getOverrideHeight():Int64    
        
        
     /**
     * 转换图片。
     * 
     * @参数 transformation - Transformation<PixelMap>要转换的类型   
     * @返回值  T 泛型数据类型
     */
     public func transform(transformation: Transformation<PixelMap>): T     
            
     /**
     * 转换图片多种效果叠加。
     * 
     * @参数 transformations - ArrayList<PixelMapTransformation>要转换的效果集合 
     * @返回值  T 泛型数据类型
     */
      public func transforms(transformations: ArrayList<PixelMapTransformation>):T   
        
     /**
     * 转换效果不生效
     * 
     * @返回值  T 泛型数据类型
     */   
     public func dontTransform(): T
        
     /**
     * 是否设置DiskCacheStrategy
     * 
     * @返回值  Bool true设置 false没有
     */      
    public func isDiskCacheStrategySet(): Bool {    
            
    /**
     * 获取磁盘缓存策略。
     * 
     * @返回值 DiskCacheStrategy 磁盘缓存策略
     */
    public func getDiskCacheStrategy(): DiskCacheStrategy
            
            
     /**
     * 设置签名，这个签名会影响缓存的key,签名不同，缓存的key必不同
     * 
     * @参数 signature: AnyKey 设置的签名，有个StringKey的实现类   
     * @返回值  T 泛型数据类型
     */       
    public func setSignature(signature: AnyKey): T
            
    
    /**
     * 获取设置的签名
     * 
     * @返回值  AnyKey 设置的签名,有个StringKey的实现类
     */           
    public func getSignature(): AnyKey
            
            
    /**
     * 设置glideoption
     * 
     * @参数 option: 选项的key
     * @参数 value:选项的value 
     * @返回值  T 泛型数据类型
     */         
    public func setOptions(option: String, value: String): T
    
    
}
```

#### 1.4 RequestBuilder 请求构建器

```cangjie
public class RequestBuilder<TranscodeType> <: BaseRequestOptions<RequestBuilder<TranscodeType>> 
& AnyRequestBuilder 
& ModelTypes<RequestBuilder<TranscodeType>>
& Equatable<RequestBuilder<TranscodeType>>
& Cloneable<RequestBuilder<TranscodeType>> {
    
    /**
     * 加加载图片并显示，不包括占位图或错误图
     * 
     * @参数 f - (PixelMap) -> Unit函数类型，用于加载图片并显示
     * @参数 width - Int64数据类型，宽
     * @参数 height - Int64数据类型，高
     * @返回值 Target<TranscodeType> - Target<TranscodeType>数据类型
     */
    public func into(f: (PixelMap) -> Unit, width: Int64, height: Int64): Target<TranscodeType>

    /**
     * 加载图片并显示，包括占位图或错误图
     * 
     * @参数 f - (PixelMap) -> Unit函数类型，用于加载图片并显示
     * @参数 r - (CJResource) -> Unit函数类型，用于加载并显示占位图或错误图
     * @参数 width - Int64数据类型，宽
     * @参数 height - Int64数据类型，高
     * @返回值 Target<TranscodeType> - Target<TranscodeType>数据类型
     */
    public func into(f: (PixelMap) -> Unit, r: (CJResource) -> Unit, width: Int64, height: Int64): Target<TranscodeType>
    
    /**
     * 加载图片不显示
     *
     * @返回值 Target<TranscodeType> - Target<TranscodeType>数据类型
     */
    public func submit(): FutureTarget<TranscodeType> 
    
    /**
     * 加载图片指定大小不显示
     *
     * @参数 width  Int64，图片宽
     * @参数 height  Int64，图片高
     * @返回值 Target<TranscodeType> - Target<TranscodeType>数据类型
     */
    public func submit(width: Int64, height: Int64): FutureTarget<TranscodeType>
    
    
     /**
     * 只下载图片不显示，默认图片原始宽高
     *
     * @返回值 FutureTarget<TranscodeType> - FutureTarget<TranscodeType>数据类型
     */
    public func downloadOnly(): FutureTarget<InputStream>
    
    /**
     * 指定宽高下载图片不显示
     *
     * @参数 width  Int64，图片宽
     * @参数 height  Int64，图片高
     * @返回值 FutureTarget<TranscodeType> - FutureTarget<TranscodeType>数据类型
     */
    public func downloadOnly(width: Int64, height: Int64): FutureTarget<InputStream> {
    
    /**
     * 缩略图为原图缩放,参数是缩小的倍数 值在0-1之间,根据缩略图和原图的加载速度差异不保证必现
     *
     * @参数 sizeMultiplier  Float32，缩放的倍数
     * @返回值 Target<TranscodeType> - Target<TranscodeType>数据类型
     */
    public func thumbnail(sizeMultiplier: Float32): RequestBuilder<TranscodeType>
    
    /**
     * 缩略图为指定图的缩放,根据缩略图和原图的加载速度差异不保证必现
     *
     * @参数 thumbnailRequest  Option<RequestBuilder<TranscodeType>>，指定的缩略图
     * @返回值 Target<TranscodeType> - Target<TranscodeType>数据类型
     */
    public func thumbnail(thumbnailRequest: Option<RequestBuilder<TranscodeType>>): RequestBuilder<TranscodeType> {

    /**
     * 为图片请求构建器应用图片加载设置。
     * 
     * @参数 requestOptions - AnyRequestOptions数据类型，请求设置
     * @返回值 RequestBuilder<TranscodeType> 请求构建器
     */
    public func apply(requestOptions: AnyRequestOptions): RequestBuilder<TranscodeType>
            
    /**
     * 是否设置图片路径
     * 
     * @返回值  Bool true设置 false没有
     */      
    public func getModelSet(): Bool;           

    /**
     * 设置请求监听器。
     *
     * @参数 requestListener - RequestListener<TranscodeType>数据类型，请求监听器
     * @返回值 RequestBuilder<TranscodeType> 请求构建器
     */
    public func listener(requestListener: RequestListener<TranscodeType>): RequestBuilder<TranscodeType>
    
    
     /**
     * 添加请求监听器。
     *
     * @参数 requestListener - RequestListener<TranscodeType>数据类型，请求监听器
     * @返回值 RequestBuilder<TranscodeType> 请求构建器
     */
    public func addListener(requestListener: RequestListener<TranscodeType>): RequestBuilder<TranscodeType> {
    
}
```

#### 1.5 RequestListener 请求监听器
```cangjie
public interface RequestListener<R> {
    /**
     * 图片加载成功时，在图片显示之前调用。
     * 
     * @参数 resource - R数据类型，图片资源
     * @参数 model - Model数据类型，图片模型
     * @参数 target - Target<R>数据类型，图片请求构建器
     * @参数 dataSource - DataSource数据类型，数据源
     * @参数 isFirstResource - Boolean数据类型，是否是第一个资源
     * @返回值 Boolean 是否消费事件 true：消费事件，停止后续加载流程，取消图片显示流程 false：不消费事件，继续图片加载流程，图片正常显示
     */
    func onResourceReady(resource: R, model: Model, target: Target<R>, dataSource: DataSource, isFirstResource: Bool): Bool;

    /**
     * 图片加载失败时调用。
     *
     * @参数 e - GlideException数据类型，图片加载异常
     * @参数 model - Model数据类型，图片模型
     * @参数 target - Target<R>数据类型，图片请求构建器
     * @参数 isFirstResource - Boolean数据类型，是否是第一个资源
     * @返回值 Boolean 是否消费事件 true：消费事件，停止后续加载流程，不显示错误图 false：继续图片加载流程，显示错误图
     */
    func onLoadFailed(e: GlideException, model: Model, target: Target<R>, isFirstResource: Bool): Bool;
}
```

#### 1.6 GifDrawable 
```cangjie
public class GifDrawable <: Drawable & Animatable2 & FrameCallback {
    /**
     * Gif动画播放次数
     * 
     * @参数 loopCount - Int64数据类型播放次数
     */
     public func setLoopCount(loopCount: Int64): Unit 
    
    /**
     * 开始播放动图
     *
     */
     public override func start(): Unit 
    
     /**
     * 结束播放动图
     *
     */
     public override func stop(): Unit 
    
    
    /**
     * 注册动画回调
     *
     * @参数 animationCallback - AnimationCallback数据类型 回调方法
     */
     public override func registerAnimationCallback(animationCallback: AnimationCallback): Unit 

    /**
     * 取消注册动画回调
     *
     * @参数 animationCallback - AnimationCallback数据类型 回调方法
     * @返回值 Bool 成功为true 失败false
     */
     public override func unregisterAnimationCallback(animationCallback: AnimationCallback): Bool {
    
    /**
     * 清空动画回调
     *
     */
     public override func clearAnimationCallbacks(): Unit {
            
}
```

### 2 图片变换接口

#### 2.1 CenterCrop

```cangjie
public class CenterCrop <: PixelMapTransformation {
    /**
     * 居中裁剪：使图片居中，并去掉显示范围之外的部分。
     */
    public init()
}
```

#### 2.2 CenterInside

```cangjie
public class CenterInside <: PixelMapTransformation {
    /**
     * 居中缩小：使图片居中，如果图片超出显示范围，则缩小图片，使图片完整显示，图片的宽高比例保持不变。
     */
    public init()
}
```

#### 2.3 CircleCrop

```cangjie
public class CircleCrop <: PixelMapTransformation {
    /**
     * 圆形裁剪：将图片裁剪成圆形。
     */
    public init()
}
```

#### 2.4 FitCenter

```cangjie
public class FitCenter <: PixelMapTransformation {
    /**
     * 居中缩放：缩放图片以适应Image组件的显示范围，图片宽高比例保持不变。
     */
    public init()
}
```

#### 2.5 Rotate

```cangjie
public class Rotate <: PixelMapTransformation {
    /**
     * 居中缩放：将图片旋转指定角度。
     *
     * @参数 degree - 旋转角度
     */
    public init(degree: Float32)
}
```

#### 2.6 RoundedCorners

```cangjie
public class RoundedCorners <: PixelMapTransformation {
    /**
     * 圆角变换：添加指定半径的圆角。
     *
     * @参数 radius - 圆角半径
     */
    public init(radius: Int32)
}
```

#### 2.7 GranularRoundedCorners

```cangjie
public class GranularRoundedCorners <: PixelMapTransformation {
    /**
     * 圆角变换：添加指定半径的圆角，四个角可以设置不同的圆角半径。
     *
     * @参数 radiusTL - 左上圆角半径。
     * @参数 radiusTR - 右上圆角半径。
     * @参数 radiusBL - 左下圆角半径。
     * @参数 radiusBR - 右下圆角半径。
     */
    public init(radiusTL: Int32, radiusTR: Int32, radiusBL: Int32, radiusBR: Int32)
}
```

#### 2.8 GrayscaleTransformation

```cangjie
public class GrayscaleTransformation <: PixelMapTransformation {
    /**
     * 灰度变换：为图片添加灰度滤镜。
     */
    public init()
}
```

#### 2.9 PixelationFilterTransformation

```cangjie
public class PixelationFilterTransformation <: PixelMapTransformation {
    /**
     * 像素化变换：为图片添加像素化滤镜。
     */
    public init()
}
```

#### 2.10 SketchFilterTransformation

```cangjie
public class SketchFilterTransformation <: PixelMapTransformation {
    /**
     * 素描变换：为图片添加素描滤镜。
     */
    public init()
}
```

#### 2.11 InvertFilterTransformation

```cangjie
public class InvertFilterTransformation <: PixelMapTransformation {
    /**
     * 反色变换：为图片添加反色滤镜。
     */
    public init()
}
```

#### 2.12 BrightnessFilterTransformation

```cangjie
public class BrightnessFilterTransformation <: PixelMapTransformation {
    /**
     * 增亮变换：图片增亮滤镜，增加亮度值默认为0。
     */
    public init()

    /**
     * 增亮变换：图片增亮滤镜。
     *
     * @参数 brightness - 增加亮度值。
     */
    public init(brightness: Float32)
}
```

#### 2.13 ContrastFilterTransformation

```cangjie
public class ContrastFilterTransformation <: PixelMapTransformation {
    /**
     * 对比度变换：调节图片对比度，对比度值默认为1.0。
     */
    public init()

    /**
     * 对比度变换：调节图片对比度。
     * 
     * @参数 contrast - 对比度值。
     */
    public init(contrast: Float32)
}
```

#### 2.14 FastBlur

```cangjie
public class FastBlur <: PixelMapTransformation {

    /**
     * 快速模糊变换：为图片添加快速模糊滤镜。
     * 
     * @参数 radius - 模糊半径。
     */
    public init(radius: Int32)
}
```

#### 2.15 KuwaharaFilterTransformation

```cangjie
public class KuwaharaFilterTransformation <: PixelMapTransformation {

    /**
     * 油画效果变换：为图片添加油画效果滤镜，效果半径默认为25。
     */
    public init()

    /**
     * 油画效果变换：为图片添加油画效果滤镜。
     * 
     * @参数 radius - 效果半径。
     */
    public init(radius: Int32)
}
```

#### 2.16 SepiaFilterTransformation

```cangjie
public class SepiaFilterTransformation <: PixelMapTransformation {

    /**
     * 棕褐色变换：为图片添加棕褐色滤镜，效果强度默认为10.0。
     */
    public init()

    /**
     * 棕褐色变换：为图片添加棕褐色滤镜。
     * 
     * @参数 intensity - 效果强度。
     */
    public init(intensity: Float32)
}
```

#### 2.17 SwirlFilterTransformation

```cangjie
public class SwirlFilterTransformation <: PixelMapTransformation {

    /**
     * 扭曲效果变换：为图片添加扭曲效果滤镜，扭曲半径默认为0.5，扭曲角度默认为1.0，扭曲中心点x坐标默认为0.5，扭曲中心点y坐标默认为0.5。
     */
    public init()

    /**
     * 扭曲效果变换：为图片添加扭曲效果滤镜。
     * 
     * @参数 radius - 扭曲半径。
     * @参数 angle - 扭曲角度。
     * @参数 x - 扭曲中心点x坐标。
     * @参数 y - 扭曲中心点y坐标。
     */
    public init(radius: Float32, angle: Float32, x: Float32, y: Float32)
}
```

#### 2.18 VignetteFilterTransformation

```cangjie
public class VignetteFilterTransformation <: PixelMapTransformation {

    /**
     * 装饰图变换：为图片添加装饰图滤镜，装饰图中心点默认为0.5，0.5。装饰图颜色默认为0，0，0。装饰图颜色透明度起始半径默认为0，装饰图颜色透明度结束半径默认为0.75。
     */
    public init()

    /**
     * 装饰图变换：为图片添加装饰图滤镜。
     * 
     * @参数 x - 装饰图中心点x坐标。
     * @参数 y - 装饰图中心点y坐标。
     * @参数 r - 装饰图颜色r通道。
     * @参数 g - 装饰图颜色g通道。
     * @参数 b - 装饰图颜色b通道。
     * @参数 start - 装饰图颜色透明度起始半径。
     * @参数 end - 装饰图颜色透明度结束半径。
     */
    public init(x: Float32, y: Float32, r: Float32, g: Float32, b: Float32, start: Float32, end: Float32)
}
```

#### 2.19 ToonFilterTransformation

```cangjie
public class ToonFilterTransformation <: PixelMapTransformation {

    /**
     * 卡通效果变换：为图片添加卡通效果滤镜，量化阈值默认为0.2，量化级别默认值为10.0。
     */
    public init()

    /**
     * 卡通效果变换：为图片添加卡通效果滤镜。
     * 
     * @参数 threshold - 量化阈值。
     * @参数 quantizationLevels - 量化级别。
     */
    public init(threshold: Float32, quantizationLevels: Float32)
}
```

### 3 示例

```cangjie
from ohos import base.*
from ohos import component.*
from ohos import state_manage.*
from ohos import state_macro_manage.*
from cj_res import default.*

from net import http.*
from std import socket.*
from net import tls.*
from std import io.*
from encoding import url.*
from std import fs.*
from std import time.*

import glide.engine.cache.disk_lru_cache.Entry as DisLruEntry
import glide.engine.cache.memory_cache.Entry as LruEntry

import zujianbao.*
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


@Entry
@Component
class MyView {

	@State var text: String = ""

    @State var textTmp: String = ""


    @State
    var option: GlideRequestOption = GlideRequestOption (
        // 加载一张本地的jpg资源（必选）
        loadSrc: Option<String>.Some("https://pic.leetcode-cn.com/1614477066-YeEeWg-file_1614477068523"),    // bmp
        //loadSrc: "/data/storage/el1/bundle/testjpg.jpg",    // jpg
        //loadSrc: "/data/storage/el1/bundle/testpng.png",    // png
        //loadSrc: "/data/storage/el1/bundle/testwebp.webp",  // wbep
        //loadSrc: "/data/storage/el1/bundle/test.gif",       // gif

        placeholder: Option < Option < CJResource >>.Some(Option < CJResource >.Some(@r(app.media.loading))),             // 占位图使用本地资源icon_loading（可选）
        errholder: Option < Option < CJResource >>.Some(Option < CJResource >.Some(@r(app.media.img))),                     // 失败占位图使用本地资源icon_failed（可选）
        strategy: Option < Option < DiskCacheStrategy >>.Some(Option < DiskCacheStrategy >.Some(DiskCacheStrategyDATA())),                // 磁盘缓存策略（可选）
        label: Option<String>.Some("page")                                         // 生命周期标签
    )

    public func onAppear(): Unit {
        AppLog.error("调了onAppear1--------------------------------------------------------------------GlideImage")
        Glide.get(globalAbilityContext.getOrThrow()).onAppear(option.label)
    }
    public func onDisappear(): Unit {
        AppLog.error("调了onDisAppear1--------------------------------------------------------------------GlideImage")
        Glide.get(globalAbilityContext.getOrThrow()).onDisAppear(option.label)
    }

    func render() {
        Column(30) {
            Column() {
                GlideImageZJ(globalContext:globalAbilityContext,option: option, beginFn: {=> text = "begin";AppLog.error("glide hhs begin")}, endFn: {=> textTmp = "end";AppLog.error("glide hhs end")})
            }.width(100.percent)
        }
    }

}

```

执行结果如下：
图片在手机正常显示

```shell
load成功
```
