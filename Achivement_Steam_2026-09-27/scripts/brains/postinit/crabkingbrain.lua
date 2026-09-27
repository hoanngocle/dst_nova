local UpvalueHacker = require "functions/upvaluehacker"

local Brain = require("brains/crabkingbrain")
local ShouldFreeze = UpvalueHacker.GetUpvalue(Brain.OnStart, "ShouldFreeze")
local function New_ShouldFreeze(inst, ...)
    if inst:HasTag("chasni_crabqueen") then
        return nil
    end
    return ShouldFreeze(inst, ...)
end

UpvalueHacker.SetUpvalue(Brain.OnStart, New_ShouldFreeze, "ShouldFreeze")
