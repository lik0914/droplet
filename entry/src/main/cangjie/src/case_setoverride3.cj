from ohos import base.LengthProp
from ohos import component.*
from ohos import state_manage.*
from ohos import state_macro_manage.*
from ohos import base.*
from ohos import ability.*
from ohos import image.*
from ohos import concurrency.*
from ohos import ui_test.*
from ohos import test_runner.*
from ohos import hilog.*
from ohos import ability_delegator_registry.*

from net import http.*
from std import socket.*
from net import tls.*
from std import io.*
from encoding import url.*
from std import fs.*
from std import collection.*

from cj_res_entry import cj_res_entry.app
from droplet import glide.*



@Entry
@Component
class CaseSetOverride3 {
    let abilityContext = globalAbilityContext.getOrThrow()
    let glideIns:Glide = Glide.get(abilityContext)

    public func onAppear() : Unit{
    }

    public func onDisappear() : Unit{
    }

    let size: Size = Size(width: 1, height: 1)
    let opts: InitializationOptions = InitializationOptions(size:size)
    let color : Array<UInt8> = Array<UInt8>(96, item:0)
    @State var pixelMap: PixelMap = createPixelMap(color, opts)
    var requestManager:RequestManager = Glide.withContext(abilityContext,"TestGlideSetOverride3")
    //网络静态图片文件，路径可达
    let file_path:String = "https://pic.leetcode-cn.com/1614477066-HUVHQl-file_1614477068803"
    var requestBuilder:RequestBuilder<Drawable>= requestManager.load(file_path)

    let scroller = Scroller()
    func render() {
        Column(30) {
            Stack(Alignment.End) {
                Scroll(this.scroller) {
                    Column(){
                        Button("setOverride").onClick{
                            var requestOption:RequestOptions = RequestOptions()
                            requestOption = requestOption.setOverride(100,100)
                            requestBuilder.apply(requestOption)
                            .into({p: PixelMap =>
                                    launch{
                                        pixelMap = p
                                    }
                                }, 800, 600)
                            if(requestOption.getOverrideWidth() == 600 && requestOption.getOverrideHeight() == 0){
                                AppLog.error("setOverride success")
                            }
                        }
                        Image(pixelMap).width(100.percent).objectFit(ImageFit.ScaleDown)
                    }.width(100.percent)
                }
                .scrollBar(BarState.Off)
                .scrollable(ScrollDirection.Vertical)
                ScrollBar(this.scroller, ScrollBarDirection.Vertical, BarState.Auto) {
                    Text("")
                    .width(30)
                    .height(100)
                    .borderRadius(10)
                    .backgroundColor(0xC0C0C0)
                }
                .width(30)
                .backgroundColor(0xededed)
            }
        }
    }
}
