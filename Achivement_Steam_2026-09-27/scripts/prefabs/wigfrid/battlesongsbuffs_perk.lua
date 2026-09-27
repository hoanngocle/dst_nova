local function OnTimer(inst, data)
    if data.name == inst.name then
        inst.components.debuff:Stop()
    end
end

--- electric
local DURATION = chasni_getitemconfig("battlesong_instant_electric", "DUR") or 20
local function OnElectricBuff(inst, target)
    if not target.components.health:IsDead() then
        if target.components.combat then
            target.components.combat.externaldamagemultipliers:SetModifier("battlesong_instant_electric_buff", 1.5)
        end
        if target.components.locomotor then
            target.components.locomotor:SetExternalSpeedMultiplier(target, "battlesong_instant_electric_buff", 1.5)
        end

        if target.wormlight then
            if target.wormlight.prefab == "wormlight_light_lesser" then
                target.wormlight.components.spell.lifetime = 0
                target.wormlight.components.spell:ResumeSpell()
                return
            else
                target.wormlight.components.spell:OnFinish()
            end
        end

        local light = SpawnPrefab("wormlight_light_lesser")
        light.components.spell:SetTarget(target)
        if light:IsValid() then
            if light.components.spell.target == nil then
                light:Remove()
            else
                light.components.spell:StartSpell()
            end
        end
    else
        inst.components.debuff:Stop()
    end
end

local function OnElectricAttach(inst, target)
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0)
    OnElectricBuff(inst, target)
    inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
end

local function OnElectricExtended(inst, target)
    inst.components.timer:StopTimer(inst.name)
    inst.components.timer:StartTimer(inst.name, DURATION)
    OnElectricBuff(inst, target)
end

local function OnElectricDetach(inst,target)
    if target.components.combat then
        target.components.combat.externaldamagemultipliers:RemoveModifier("battlesong_instant_electric_buff")
    end
    if target.components.locomotor then
        target.components.locomotor:RemoveExternalSpeedMultiplier(target, "battlesong_instant_electric_buff")
    end
    inst:Remove()
end
--- stopmove
local STOP_MOVE_DURATION = chasni_getitemconfig("chasni_battlesong_instant_stopmove", "DUR") or 12
local function OnStopmoveBuff(inst, target)
    if not target.components.health:IsDead() then
        if target.components.combat then
            target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1.5)
        end
        if target.components.locomotor then
            target.components.locomotor:SetExternalSpeedMultiplier(target, "battlesong_instant_stopmove_debuff", 0)
        end
    else
        inst.components.debuff:Stop()
    end
end

local function OnStopmoveAttach(inst, target)
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0)
    OnStopmoveBuff(inst, target)
    inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
    inst:ListenForEvent("attacked", function() inst.components.debuff:Stop() end, target)
end

local function OnStopmoveExtended(inst, target)
    inst.components.timer:StopTimer(inst.name)
    inst.components.timer:StartTimer(inst.name, DURATION)
    OnStopmoveBuff(inst, target)
end

local function OnStopmoveDetach(inst,target)
    if target.components.combat then
        target.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst)
    end
    if target.components.locomotor then
        target.components.locomotor:RemoveExternalSpeedMultiplier(target, "battlesong_instant_stopmove_debuff")
    end
    inst:Remove()
end

--=====================================
local function makebuffs(name,data)
    local function fn()
        local inst = CreateEntity()
        if not TheWorld.ismastersim then
            inst:DoTaskInTime(0, inst.Remove)
            return inst
        end
        inst.entity:AddTransform()

        inst.entity:Hide()
        inst.persists = false

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(data.attach)
        inst.components.debuff:SetDetachedFn(data.stop)
        inst.components.debuff:SetExtendedFn(data.extended)
        inst.components.debuff.keepondespawn = true

        inst.name = name
        inst:AddComponent("timer")
        inst.components.timer:StartTimer(name, data.time)
        inst:ListenForEvent("timerdone", OnTimer)

        return inst
    end
    return Prefab(name, fn)
end

return
makebuffs("battlesong_instant_electric_buff",{attach = OnElectricAttach, extended = OnElectricExtended, stop = OnElectricDetach, time = DURATION}),
makebuffs("battlesong_instant_stopmove_debuff",{attach = OnStopmoveAttach, extended = OnStopmoveExtended, stop = OnStopmoveDetach, time = STOP_MOVE_DURATION})
