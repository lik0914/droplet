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
from std import collection.*
from encoding import url.*
from std import fs.*

from cj_res_entry import cj_res_entry.app
from droplet import glide.*

@Entry
@Component
class TestNoAnimList {

    @State var text : String = ""
    @State var textTmp : String = ""
    var src1 : String = "https://pic.leetcode-cn.com/1614477066-olRayu-file_1614477068738"
    var src2 : String = "https://pic.leetcode-cn.com/1614477066-GQKVQV-file_1614477068755"

    var srcList:ArrayList<String> = ArrayList<String>()
    var srcListOption:ArrayList<GlideRequestOption> = ArrayList<GlideRequestOption>()


    public func onAppear() : Unit{
        srcList.append(src1)
        srcList.append(src2)
        for(index in 0..srcList.size){
            srcListOption.append(GlideRequestOption(
                 loadSrc:Option<String>.Some(srcList[index]),
                 placeholder:Option<Option<CJResource>>.Some(Option<CJResource>.Some(@r(app.media.loading))),
                 errholder:Option<Option<CJResource>>.Some(Option<CJResource>.Some(@r(app.media.img))),
                 strategy:Option<Option<DiskCacheStrategy>>.Some(Option<DiskCacheStrategy>.Some(DiskCacheStrategyDATA())),
                 label:Option<String>.Some("page"),
             ))
        }

    }

    public func onDisappear() : Unit{

    }

    let scroller = Scroller()
    func render() {
            Column(30){
                Scroll(this.scroller){
                    Column(){
                        ForEach(srcList,itemGeneratorFunc:{src:String,idx:Int64 =>
                              GlideImageZJ(globalContext:globalAbilityContext,option:srcListOption[idx],beginFn:{=> text= "begin";AppLog.error("glide begin")},endFn:{=> textTmp= "end";AppLog.error("glide end")})
                        })
                    }.width(100.percent)
                }
            }
    }
}
