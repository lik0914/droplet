/**
 * Created on 2024/7/25
 */
package ohos_app_cangjie_entry

import ohos.component.*
import ohos.state_manage.*
import ohos.state_macro_manage.*
import ohos.base.*
import ohos.ability.*

import cj_res_entry.app
import droplet.droplet.*


@Entry
@Component
class TestJpg {

    @State var text : String = ""
    @State var textTmp : String = ""
    var src : String = "https://copyright.bdstatic.com/vcg/creative/cc9c744cf9f7c864889c563cbdeddce6.jpg"
    @State var option:DropletRequestOption = DropletRequestOption(
        loadSrc:Option<String>.Some(src),
        placeholder:Option<CJResource>.Some(@r(app.media.loading)),
        errholder:Option<CJResource>.Some(@r(app.media.img)),
        strategy:Option<DiskCacheStrategy>.Some(DiskCacheStrategyDATA()),
        signature:Option<String>.Some("1111")
    )

    public func onAppear() : Unit{

    }

    public func onDisappear() : Unit{

    }

    let scroller = Scroller()
    func build() {
            Column(30){
                Scroll(this.scroller){
                    Column(){
                        DropletImageComponent(globalContext:globalAbilityContext,option:option,beginFn:{=> text= "begin";AppLog.error("droplet begin")},endFn:{=> textTmp= "end";AppLog.error("droplet end")})
                    }.width(100.percent)
                }
            }
    }

}