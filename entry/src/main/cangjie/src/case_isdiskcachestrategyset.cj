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
class CaseIsDiskCacheStrategySet {
    public func onAppear(): Unit {
    }

    public func onDisappear(): Unit {
    }

    let scroller = Scroller()
    func render() {
        Column(30) {
            Scroll(this.scroller) {
                Column() {
                    Button("获取磁盘缓存设置状态").onClick {
                        var requestManager: RequestManager = Glide.withContext(globalAbilityContext.getOrThrow(),
                            "Test041")
                        var requestBuilder = requestManager.load(
                            "https://pic.leetcode-cn.com/1614477066-ZtVaEs-file_1614477068742")
                        requestBuilder.setDiskCacheStrategy(DiskCacheStrategyDATA())
                        if (requestBuilder.isDiskCacheStrategySet()) {
                            AppLog.error("执行成功")
                        } else {
                            AppLog.error("执行失败")
                        }
                    }
                }.width(100.percent)
            }
        }
    }
}
