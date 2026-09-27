-- CC : set Were Transforming UI button rpc >> [Reward] expertwoodie1
local function dodetransform(inst)
    inst.components.wereness:SetPercent(0, true)
end

local function dotransform(inst, weremode)
    inst.components.wereness:SetWereMode(weremode)
    inst.components.wereness:SetPercent(1, true)
    inst:AddTag(weremode)
end

local function trytransform(inst, weremode)
    local previousform = inst:HasTag(weremode == "beaver" and weremode or "were"..weremode)
    if not previousform and inst.getWereCD and inst:getWereCD(weremode) < 1 then
        inst.components.talker:Say(GetString(inst, "WOODIE_TRANSFORM_FAIL"))
        return false
    end
    if inst:HasTag("playerghost") then return end
    dodetransform(inst)
    if previousform then
        return false
    end

    if inst.components.timer then
        dotransform(inst, weremode)
        inst.components.timer:StartTimer("werecd"..weremode, TUNING.EXPERT_WOODIE1_COOLDOWN[weremode])
        return true
    end
end

AddModRPCHandler("Woodie_Mod", "goose_button", function(inst)
    if trytransform(inst, "goose") then
        inst.net_goosecd:set(0)
    end
end)

AddModRPCHandler("Woodie_Mod", "beaver_button", function(inst)
    if trytransform(inst, "beaver") then
        inst.net_beavercd:set(0)
    end
end)

AddModRPCHandler("Woodie_Mod", "moose_button", function(inst)
    if trytransform(inst, "moose") then
        inst.net_moosecd:set(0)
    end
end)