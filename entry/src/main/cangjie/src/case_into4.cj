/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
from ohos import base.LengthProp
from ohos import component.*
from ohos import state_manage.*
from ohos import state_macro_manage.*
from ohos import base.*
from ohos import ability.*
from ohos import image.*
from ohos import concurrency.*

from net import http.*
from std import socket.*
from net import tls.*
from std import io.*
from encoding import url.*
from std import fs.*

from cj_res_entry import cj_res_entry.app
from droplet import glide.*

@Entry
@Component
class CaseInto4 {

    public func onAppear() : Unit{

    }

    public func onDisappear() : Unit{

    }

        let size: Size = Size(width: 1, height: 1)
    	let opts: InitializationOptions = InitializationOptions(size:size)
        let color : Array<UInt8> = Array<UInt8>(96, item:0)
        @State var pixelMap: PixelMap = createPixelMap(color, opts)

    let scroller = Scroller()
    func render() {
            Column(30){
                Scroll(this.scroller){
                    Column(){
                        Button("intoWebp").onClick{
                                    var requestManager:RequestManager = Glide.withContext(globalAbilityContext.getOrThrow(),"Test036")
                                    var requestBuilder = requestManager.load("https://img2.baidu.com/it/u=365005294,681333190&fm=253&fmt=auto&app=138&f=JPEG?w=750&h=500")
                                    requestBuilder.into({p: PixelMap =>
                                                launch{
                                                    pixelMap = p
                                                }
                                            },800, 600)
                        }
                        Image(pixelMap).width(100.percent).objectFit(ImageFit.ScaleDown)
                    }.width(100.percent)
                }
            }
    }
}
