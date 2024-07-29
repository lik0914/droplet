/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
package ohos_app_cangjie_entry

import ohos.component.*
import ohos.state_manage.*
import ohos.state_macro_manage.*

import ohos.base.*
import ohos.ability.*
import ohos.window.*

class MyAbilityStage <: AbilityStage {
    public override func onCreate(): Unit {
        AppLog.info("MyAbilityStage onCreated.")
    }
}

func createAbilityStage(): MyAbilityStage {
    MyAbilityStage()
}

let ABILITY_STAGE_REGISTER_RESULT = AbilityStage.registerCreator("entry", createAbilityStage)
