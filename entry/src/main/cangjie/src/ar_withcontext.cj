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
class Test002 {

    public func onAppear() : Unit{

    }

    public func onDisappear() : Unit{

    }

    let scroller = Scroller()
    func render() {
            Column(30){
                Scroll(this.scroller){
                    Column(){
                        Button("获取图片请求管理器实例对象成功").onClick{
                            var requestManager:RequestManager = Glide.withContext(globalAbilityContext.getOrThrow(),"Test002")
                            AppLog.error("执行成功")
                        }
                    }.width(100.percent)
                }
            }
    }
}
