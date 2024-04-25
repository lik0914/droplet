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

import glide.*
import glide.add.*
import glide.request.*
import glide.executor.*
import glide.util.utils.*

import glide.request_options.*

import glide.load.*
import glide.util.*
import glide.util.pool.*
import glide.util.calculator.*

//import glide.engine.cache.memory_cache.*


@Entry
@Component
class MyView {

    var width: Int64 = 640
    var height: Int64 = 480
    @State var src: String = "/data/storage/el1/bundle/entry/resources/base/media/testbmp.bmp"

    let size: Size = Size(width: 1, height: 1)
    let opts: InitializationOptions = InitializationOptions(size: size)
    let color: Array<UInt8> = Array<UInt8>(96, item: 0)

    @State
    var pixelMap: PixelMap = createPixelMap(color, opts)

    @Watch[imgChanged]
    @State
    var pixelStore: PixelMap = createPixelMap(color, opts)

    public func imgChanged(): Unit {
        AppLog.error("调用 GlideImage [imgChanged]----------------------------------------1")
        this.pixelMap = pixelStore
    }

    func render() {
        Column {
            Button("load png").onClick({event =>
                Glide.withContext(globalAbilityContext.getOrThrow()).load(src)
                .setDiskCacheStrategy(DiskCacheStrategyDATA())
                .listener({drawable: Drawable, model: Model, target: Target<Drawable>, datasource: DataSource, isFirstResource: Bool =>
                                AppLog.error("load成功----------------------------------------GlideImage [updateImg]")
                                return false
                            },
                            {e: GlideException, model: Model, target: Target<Drawable>, isFirstResource: Bool =>
                                AppLog.error("load失败----------------------------------------GlideImage [updateImg]")
                                return true
                            })
                .into({p: PixelMap =>
                            AppLog.error("callback 1----------------------------------------GlideImage [updateImg]")
                            pixelStore = p
                        }, width, height)

            }).width(400.px).height(150.px)

            Image(pixelMap).width(100.percent).objectFit(ImageFit.ScaleDown)
        }
    }
}

