local SANITY_TICK = 1
local HUNGER_TICK = 1
local SPEED_BUFF = 2
local ATTACK_BUFF = 2
local function OnTickSanity(inst, target)
    if target.components.health and not target.components.health:IsDead() and target.components.sanity and not target:HasTag("playerghost") then
        target.components.sanity:DoDelta(SANITY_TICK)
    else
        inst.components.debuff:Stop()
    end
end
local function OnTickHunger(inst, target)
    if target.components.health and not target.components.health:IsDead() and target.components.hunger and not target:HasTag("playerghost") then
        target.components.hunger:DoDelta(HUNGER_TICK)
    else
        inst.components.debuff:Stop()
    end
end
local function OnTickMoisture(inst, target)
    if target.components.health and not target.components.health:IsDead() and target.components.moisture and not target:HasTag("playerghost") then
        target.components.moisture:SetMoistureLevel(0)
    else
        inst.components.debuff:Stop()
    end
end
local function OnSpeed(inst, target)
    if target and target.components.locomotor and target.components.health and not target.components.health:IsDead() and not target:HasTag("playerghost") then
        target.components.locomotor:SetExternalSpeedMultiplier(target, "wormwood_speed_buff", SPEED_BUFF)
    else
        inst.components.debuff:Stop()
    end
end
local function OnDoneSpeed(inst, target)
    if target and target.components.locomotor then
        target.components.locomotor:RemoveExternalSpeedMultiplier(target, "wormwood_speed_buff")
    end
end

local function OnAttack(inst, target)
    if target and target.components.combat and target.components.health and not target.components.health:IsDead() and not target:HasTag("playerghost") then
        target.components.combat.externaldamagemultipliers:SetModifier("wormwood_attack_buff", ATTACK_BUFF)
    else
        inst.components.debuff:Stop()
    end
end
local function OnDoneAttack(inst, target)
    if target and target.components.combat then
        target.components.combat.externaldamagemultipliers:RemoveModifier("wormwood_attack_buff")
    end
end

local function buff_fn(name, tickfn, duration, tick, isonstart, ondone, glow)
    local function OnAttached(inst, target)
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0)
        if tick and tick > 0 and tickfn then
            inst.task = inst:DoPeriodicTask(tick, tickfn, nil, target)
        end
        if isonstart and tickfn then
            tickfn(inst, target)
        end
        inst.components.timer:StartTimer("regenover", duration)
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)
    end

    local function OnDetached(inst, target)
        if ondone then
            ondone(inst, target)
        end
        inst:Remove()
    end

    local function OnTimerDone(inst, data)
        if data.name == "regenover" then
            inst.components.debuff:Stop()
        end
    end

    local function OnExtended(inst, target)
        local time_remaining = inst.components.timer:GetTimeLeft("regenover")
        if time_remaining then
            if duration > time_remaining then
                inst.components.timer:SetTimeLeft("regenover", duration)
            end
        else
            inst.components.timer:StartTimer("regenover", duration)
        end
    end

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()

        inst:AddTag("CLASSIFIED")
        if glow then
            inst.entity:AddNetwork()
            inst.entity:AddLight()
            inst.Light:SetIntensity(.7)
            inst.Light:SetRadius(4)
            inst.Light:SetFalloff(0.6)
            inst.Light:SetColour(1, 1, 1)
            inst.Light:Enable(true)
        else
            inst.entity:Hide()
        end

        if not TheWorld.ismastersim then
            if not glow then
                inst:DoTaskInTime(0, inst.Remove)
            end
            return inst
        end

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff:SetDetachedFn(OnDetached)
        inst.components.debuff:SetExtendedFn(OnExtended)
        inst.components.debuff.keepondespawn = true

        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone", OnTimerDone)

        inst.persists = true

        return inst
    end

    return Prefab(name, fn)
end

return
buff_fn("wormwood_hunger_buff", OnTickHunger, 30, 1),
buff_fn("wormwood_sanity_buff", OnTickSanity, 30, 1),
buff_fn("wormwood_moisture_buff", OnTickMoisture, 120, 1),
buff_fn("wormwood_speed_buff", OnSpeed, 3, nil, true, OnDoneSpeed),
buff_fn("wormwood_attack_buff", OnAttack, 3, nil, true, OnDoneAttack),
buff_fn("wormwood_glow_buff", nil, 120, nil, nil, nil, true)