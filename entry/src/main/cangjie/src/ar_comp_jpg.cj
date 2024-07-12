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
class ar_comp_jpg {

    @State var text : String = ""
    @State var textTmp : String = ""
    var src : String = "https://copyright.bdstatic.com/vcg/creative/cc9c744cf9f7c864889c563cbdeddce6.jpg"
    @State var option:GlideRequestOption = GlideRequestOption(
        loadSrc:Option<String>.Some(src),
        placeholder:Option<Option<CJResource>>.Some(Option<CJResource>.Some(@r(app.media.loading))),
        errholder:Option<Option<CJResource>>.Some(Option<CJResource>.Some(@r(app.media.img))),
    )

    public func onAppear() : Unit{

    }

    public func onDisappear() : Unit{

    }

    let scroller = Scroller()
    func render() {
            Column(30){
                Scroll(this.scroller){
                    Column(){
                        GlideImageZJ(globalContext:globalAbilityContext,option:option,beginFn:{=> text= "begin";AppLog.error("glide begin")},endFn:{=> textTmp= "end";AppLog.error("glide end")})
                    }.width(100.percent)
                }
            }
    }
}
