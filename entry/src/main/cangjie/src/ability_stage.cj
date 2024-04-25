from ohos import base.*
from ohos import ability.*

class MyAbilityStage <: AbilityStage {
    public override func onCreate(): Unit {
        AppLog.info("MyAbilityStage onCreated.")
    }
}

func createAbilityStage(): MyAbilityStage {
    MyAbilityStage()
}

let ABILITY_STAGE_REGISTER_RESULT = AbilityStage.registerCreator("entry", createAbilityStage)
