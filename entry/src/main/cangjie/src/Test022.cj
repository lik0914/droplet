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
class Test022 {

    public func onAppear() : Unit{

    }

    public func onDisappear() : Unit{

    }

    let scroller = Scroller()
    func render() {
            Column(30){
                Scroll(this.scroller){
                    Column(){
                        Button("多次应用图片变换成功").onClick{
                            var requestManager:RequestManager = Glide.withContext(globalAbilityContext.getOrThrow(),"Test003")
                            var requestBuilder = requestManager.load("https://pic.leetcode-cn.com/1614477066-ZtVaEs-file_1614477068742")
                            requestBuilder.transform(InvertFilterTransformation())
                            requestBuilder.transform(BrightnessFilterTransformation(0.6))
                            if(requestBuilder.getTransformationAllowed() && requestBuilder.getTransformations().size() == 2){
                                AppLog.error("执行成功")
                            }
                        }
                    }.width(100.percent)
                }
            }
    }
}
