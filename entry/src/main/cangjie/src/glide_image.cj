
from ohos import base.*
from ohos import component.*

from ohos import image.Image as MultiImage
from ohos import image.Component as ImageComponent
from ohos import image.*

from ohos import state_manage.*
from ohos import state_macro_manage.*

import glide.*
import glide.add.*
import glide.request.*

from std import fs.*
from std import time.*
from std import sync.*
from std import collection.*

@Observed
class GlideRequestOption {
    @Publish var overrideWidth: Int64 = 0
    @Publish var overrideHeight: Int64 = 0
    @Publish var signature: String = ""
    @Publish var requestListener: Option<(PixelMap) -> Bool> = Option<(PixelMap) -> Bool>.None

    // 加载一张本地的jpg资源（必选）
    @Publish var loadSrc: String = ""
    // 占位图使用本地资源icon_loading（可选）
    @Publish var placeholder: Option<CJResource> = Option<CJResource>.None
    // 失败占位图使用本地资源icon_failed（可选）
    @Publish var errorholder: Option<CJResource> = Option<CJResource>.None
    //磁盘缓存策略（可选）
    @Publish var strategy: Option<DiskCacheStrategy> = Option<DiskCacheStrategy>.None
    //生命周期管理用到的标签名称
    @Publish var label: String = ""
}

@Component
class GlideImage {

    @Link
    @Watch[onOptionChanged]
    var option: GlideRequestOption

    @State
    var isLoading: Bool = true   /*加载状态*/
    @State
    var isError: Bool = false   /*错误状态*/

    @Prop var beginFn: () -> Unit
    @Prop var endFn: () -> Unit

    @State
    var flag: Bool = false

    /* 上一次图片宽度 */
    var oldWidth: Int64 = 0
     /* 上一次图片高度 */
    var oldHeight: Int64 = 0

    /* 初始化像素图大小 */
    let size: Size = Size(width: 1, height: 1)
    /* 初始化像素图选项 */
    let opts: InitializationOptions = InitializationOptions(size: size)

    let color: Array<UInt8> = Array<UInt8>(96, item: 0)
    @State
    var pixelMap: PixelMap = createPixelMap(color, opts)

    /* 临时像素图，通过Watch监听变化，用于异步加载图片 */
    @Watch[imgChanged]
    @State
    var pixelStore: PixelMap = createPixelMap(color, opts)

    // 生命周期：组件首次显示在屏幕上时调用
    public func onAppear(): Unit {
        AppLog.error("调用 GlideImage [onAppear]----------------------------------------1")
        Glide.get(globalAbilityContext.getOrThrow()).onAppear(option.label)
    }

    //生命周期：组件从屏幕上消失时调用
    public func onDisappear(): Unit {
        AppLog.error("调用 GlideImage [onDisappear]----------------------------------------1")
        //Glide.get(globalAbilityContext.getOrThrow()).onDisappear(option.label)
    }

    // Watch监听函数：本地图片路径变化时调用，用于处理本地图片加载逻辑
    public func onOptionChanged(): Unit {
        updateImg(oldWidth, oldHeight)
    }

    // Watch监听函数：像素图或错误图资源路径变化时调用，更新显示的图片或错误图
    public func imgChanged(): Unit {
        AppLog.error("调用 GlideImage [imgChanged]----------------------------------------1")
        this.pixelMap = pixelStore
    }

    public func updateImg(width: Int64, height: Int64): Unit {
        if (option.loadSrc != "" && width > 0 && width > 0) {
            beginFn()
            AppLog.error("进来了 GlideImage [updateImg]----------------------------------------1")
            //option.label为空字符串时，withContext相当于调用，没有label这个参数的同名函数
            var glide = Glide.withContext(globalAbilityContext.getOrThrow(), option.label).load(option.loadSrc)

            //设置三级缓存策略
            if (let Some(v) <- option.strategy) {
                glide = glide.setDiskCacheStrategy(v)
            }
            //设置占位图
            if (let Some(v) <- option.placeholder) {
                glide = glide.placeholder(v)
            }
            //设置错误占位图
            if (let Some(v) <- option.errorholder) {
                glide = glide.error(v)
            }

            glide.listener({drawable: Drawable, model: Model, target: Target<Drawable>, datasource: DataSource, isFirstResource: Bool =>
                                endFn()
                                AppLog.error("load成功----------------------------------------GlideImage [updateImg]")
                                return false
                            },
                            {e: GlideException, model: Model, target: Target<Drawable>, isFirstResource: Bool =>
                                AppLog.error("load失败----------------------------------------GlideImage [updateImg]")
                                isError = true
                                return true
                            })
                 .into({p: PixelMap =>
                            AppLog.error("callback 1----------------------------------------GlideImage [updateImg]")
                            isLoading = false
                            pixelStore = p
                        },
                        {cjres: CJResource,isErrorPic:Bool =>
                            AppLog.error("callback 2----------------------------------------GlideImage [updateImg]")
                            isLoading = false
                        }, width, height)
        }
    }
    
    // 组件渲染
    func render() {
        if (isLoading) {
            //显示，加载中占位图
            if (let Some(v) <- option.placeholder) {
                Image(v).width(100.percent).objectFit(ImageFit.ScaleDown)
                //.onAreaChanged({oldArea, newArea =>
                //                    let newWidth: Int64 = Int64(newArea.width)
                //                    let newHeight: Int64 = Int64(newArea.height)
                //                    // 检测图片区域大小变化
                //                    if (oldWidth != newWidth || oldHeight != newHeight) {
                //                        if (!flag) {
                //                            flag = true
                //                            updateImg(newWidth, newHeight)
                //                            oldWidth = newWidth
                //                            oldHeight = newHeight
                //                        }
                //                    }
                //                })
            }
        } else if(!isLoading && isLoading) { //显示，加载失败占位图
            if (let Some(v) <- option.errorholder) {
                Image(v).width(100.percent).objectFit(ImageFit.ScaleDown)
            }
        } else if(!isLoading && !isLoading) { //显示，加载成功的图片
            Image(this.pixelMap).width(100.percent).objectFit(ImageFit.ScaleDown)
        }
    }

}
