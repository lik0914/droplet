/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights resvered.
 */
 
from ohos import base.*
from ohos import ability.*
from ohos import window.*

var globalAbilityContext: Option<AbilityContext> = Option<AbilityContext>.None

class MainAbility <: Ability {
    public init() {
        super()
        registerSelf()
    }

    public override func onCreate(want: Want, launchParam: LaunchParam): Unit {
        AppLog.info("MainAbility OnCreated.")
        globalAbilityContext = Option<AbilityContext>.Some(this.context)
    }

    public override func onWindowStageCreate(windowStage: WindowStage): Unit {
        AppLog.info("MainAbility onWindowStageCreate.")
        windowStage.loadContent("MyView")
    }
}

func createAbility(): MainAbility {
    MainAbility()
}

let ABILITY_REGISTER_RESULT = Ability.registerCreator("CangjieAbility", createAbility)

