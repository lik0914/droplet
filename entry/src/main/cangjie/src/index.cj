/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */

from ohos import component.*
from ohos import state_manage.SubscriberManager
from ohos import state_manage.ObservedProperty
from ohos import state_macro_manage.*


@Entry
@Component
class MyView {
    let scroller = Scroller()

    func render() {
        Row {
            Text("Hello World")

        }.height(100.percent)
    }
}
