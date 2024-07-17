/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */

from ohos import base.LengthProp
from ohos import component.Column
from ohos import component.Row
from ohos import component.Button
from ohos import component.Text
from ohos import component.CustomView
from ohos import component.CJEntry
from ohos import component.loadNativeView
from ohos import state_manage.SubscriberManager
from ohos import state_manage.ObservedProperty
from ohos import state_macro_manage.Entry
from ohos import state_macro_manage.Component
from ohos import state_macro_manage.State
from ohos import state_macro_manage.r
from ohos import router.*

@Entry
@Component
class MyView {
    let scroller = Scroller()

    func render() {
        Row {
            Scroll(this.scroller){
                         Column {
               Button("CasePng").onClick {Router.push(url: "CasePng")}
               Button("CaseJpg1").onClick {Router.push(url: "CaseJpg1")}
               Button("CaseBmp1").onClick {Router.push(url: "CaseBmp1")}
               Button("CaseBrightness").onClick {Router.push(url: "CaseBrightness")}
               Button("CaseWebp").onClick {Router.push(url: "CaseWebp")}


            }.width(100.percent)
            }

        }.height(100.percent)
    }
}
