local BRIGADEIRO_SPAWN_TICK = chasni_getitemconfig("new_warly_food", "BRTICK") or 10

local function OnAttached(inst, target)
    inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0)
end

local function OnTimerDone(inst, data)
    if data.name == "decay" then
        inst.components.debuff:Stop()
    end
end
local function OnEventTriggered(inst, buffname)
    if inst and inst.components.debuffable then
        inst.components.debuffable:RemoveDebuff(buffname)
    end
end

local function buff_OnExtended(inst, target)
    if inst.components.timer then
        local maxbuffduration = inst._buffduration or TUNING.TOTAL_DAY_TIME
        if (inst.components.timer:GetTimeLeft("decay") or 0) < maxbuffduration then
            inst.components.timer:SetTimeLeft("decay", maxbuffduration)
        end
    end
end

---- MOONCAKE
local function OnEventTriggeredMooncake(inst)
    OnEventTriggered(inst, "chasni_mooncakebuff")
end
local function OnAttachedMoonCake(inst, target)
    if target and not target:HasTag("playerghost") then
        OnAttached(inst, target)
        inst:ListenForEvent("goinsane", OnEventTriggeredMooncake, target)
        inst:ListenForEvent("chasni_blocked", function()
            inst.AnimState:PlayAnimation("hit")
            inst.AnimState:PushAnimation("idle_loop", true)
        end, target)
    else
        inst.components.debuff:Stop()
    end
end
local function OnDetachedMoonCake(inst, target)
    if target then
        inst:RemoveEventCallback("goinsane", OnEventTriggeredMooncake, target)
    end
    inst.AnimState:PlayAnimation("close")
    inst:DoTaskInTime(.6, function()
        inst:Remove()
    end)
end
---- BALUT
local function OnEventTriggeredBalut(inst)
    OnEventTriggered(inst, "chasni_balutbuff")
end
local function OnAttachedBalut(inst, target)
    if target and not target:HasTag("playerghost") then
        OnAttached(inst, target)
        inst:ListenForEvent("gosane", OnEventTriggeredBalut, target)
    else
        inst.components.debuff:Stop()
    end
end
local function OnDetachedBalut(inst, target)
    if target then
        inst:RemoveEventCallback("goinsane", OnEventTriggeredBalut, target)
    end
    if inst._fx then
        inst._fx:Remove()
    end
    inst:Remove()
end
local function BalutFx(inst)
    inst._fx = SpawnPrefab("thurible_smoke")
    inst._fx.OnEntityWake = nil
    inst._fx.OnEntitySleep = nil
    inst._fx.SoundEmitter:KillSound("loop")
    inst._fx.entity:SetParent(inst.entity)
end
---- BRIGADEIRO
local function spawnButterfly(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local butterfly = chasni_spawnprefab("butterfly", x, y, z)
    if butterfly and butterfly.components.lootdropper then
        butterfly.components.lootdropper:AddChanceLoot("butter", 0.1)
    end
end
local function OnAttachedBrigadeiro(inst, target)
    if target and not target:HasTag("playerghost") then
        OnAttached(inst, target)
        spawnButterfly(inst)
        inst.brigadeirotask = inst:DoPeriodicTask(BRIGADEIRO_SPAWN_TICK, spawnButterfly)
    else
        inst.components.debuff:Stop()
    end
end
local function OnDetachedBrigadeiro(inst, target)
    if inst.brigadeirotask then
        inst.brigadeirotask:Cancel()
        inst.brigadeirotask = nil
    end
    inst:Remove()
end
---- KYIVCAKE
local function OnAttachedKyivcake(inst, target)
    if target and not target:HasTag("playerghost") then
        OnAttached(inst, target)
    else
        inst.components.debuff:Stop()
    end
end
local function OnDetachedKyivcake(inst, target)
    inst:Remove()
end
---- Empanadas
local function OnAttachedEmpanadas(inst, target)
    if target and not target:HasTag("playerghost") then
        OnAttached(inst, target)
        if target.components.efficientuser == nil then
            target:AddComponent("efficientuser")
        end
        target.components.efficientuser:AddMultiplier(ACTIONS.CHOP,     0.5, inst)
        target.components.efficientuser:AddMultiplier(ACTIONS.MINE,     0.5, inst)
        target.components.efficientuser:AddMultiplier(ACTIONS.HAMMER,   0.5, inst)
        target.components.efficientuser:AddMultiplier(ACTIONS.DIG,      0.5, inst)
        target.components.efficientuser:AddMultiplier(ACTIONS.TILL,     0.5, inst)
        target.components.efficientuser:AddMultiplier(ACTIONS.SCYTHE,   0.5, inst)
        target.components.efficientuser:AddMultiplier(ACTIONS.NET,      0.5, inst)
        target.components.efficientuser:AddMultiplier(ACTIONS.CAST_NET, 0.5, inst)
        target.components.efficientuser:AddMultiplier(ACTIONS.FAN,      0.5, inst)
        target.components.efficientuser:AddMultiplier(ACTIONS.PLAY,     0.5, inst)
        target.components.efficientuser:AddMultiplier(ACTIONS.ROW,      0.5, inst)
        target.components.efficientuser:AddMultiplier(ACTIONS.ROW_FAIL, 0.5, inst)
        target.components.efficientuser:AddMultiplier(ACTIONS.UNSADDLE, 0.5, inst)
        target.components.efficientuser:AddMultiplier(ACTIONS.BRUSH,    0.5, inst)
    else
        inst.components.debuff:Stop()
    end
end
local function OnDetachedEmpanadas(inst, target)
    if target then
        if target.components.efficientuser == nil then
            target:AddComponent("efficientuser")
        end
        target.components.efficientuser:RemoveMultiplier(ACTIONS.CHOP,     inst)
        target.components.efficientuser:RemoveMultiplier(ACTIONS.MINE,     inst)
        target.components.efficientuser:RemoveMultiplier(ACTIONS.HAMMER,   inst)
        target.components.efficientuser:RemoveMultiplier(ACTIONS.DIG,      inst)
        target.components.efficientuser:RemoveMultiplier(ACTIONS.TILL,     inst)
        target.components.efficientuser:RemoveMultiplier(ACTIONS.SCYTHE,   inst)
        target.components.efficientuser:RemoveMultiplier(ACTIONS.NET,      inst)
        target.components.efficientuser:RemoveMultiplier(ACTIONS.CAST_NET, inst)
        target.components.efficientuser:RemoveMultiplier(ACTIONS.FAN,      inst)
        target.components.efficientuser:RemoveMultiplier(ACTIONS.PLAY,     inst)
        target.components.efficientuser:RemoveMultiplier(ACTIONS.ROW,      inst)
        target.components.efficientuser:RemoveMultiplier(ACTIONS.ROW_FAIL, inst)
        target.components.efficientuser:RemoveMultiplier(ACTIONS.UNSADDLE, inst)
        target.components.efficientuser:RemoveMultiplier(ACTIONS.BRUSH,    inst)
    end
    inst:Remove()
end
---- KIMCHI
local function OnAttachedKimchi(inst, target)
    if target and not target:HasTag("playerghost") then
        OnAttached(inst, target)
    else
        inst.components.debuff:Stop()
    end
end
local function OnDetachedKimchi(inst, target)
    inst:Remove()
end
---- ANZAC
local function OnEventTriggeredAnzac(inst)
    OnEventTriggered(inst, "chasni_anzacbuff")
end
local function OnAttachedAnzac(inst, target)
    if target and not target:HasTag("playerghost") then
        OnAttached(inst, target)
        inst:ListenForEvent("onhitother", OnEventTriggeredAnzac, target)
    else
        inst.components.debuff:Stop()
    end
end
local function OnDetachedAnzac(inst, target)
    if target then
        inst:RemoveEventCallback("onhitother", OnEventTriggeredAnzac, target)
    end
    inst:Remove()
end
---- MOPANE
local function OnAttachedMopane(inst, target)
    if target and not target:HasTag("playerghost") then
        OnAttached(inst, target)
    else
        inst.components.debuff:Stop()
    end
end
local function OnDetachedMopane(inst, target)
    if target then
        chasni_unquiprestrictedtag2(target)
    end
    inst:Remove()
end
------------------------------------------------------------------------------------------------------------------------------------------------

local function fn(attachfn, detachfn, time, MasterFXfn, bank, build, anim, animloop)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("CLASSIFIED")

    if bank then
        inst.entity:AddAnimState()
        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation(anim)
        if animloop then
            inst.AnimState:PushAnimation(animloop, true)
        end
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    if MasterFXfn then
        inst._inittask = inst:DoTaskInTime(0, MasterFXfn)
    end

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(attachfn)
    inst.components.debuff:SetDetachedFn(detachfn)
    inst.components.debuff:SetExtendedFn(buff_OnExtended)
    inst.components.debuff.keepondespawn = true

    if time then
        inst:AddComponent("timer")
        inst.components.timer:StartTimer("decay", time)
        inst:ListenForEvent("timerdone", OnTimerDone)
    end

    inst._buffduration = time
    inst.persists = true

    return inst
end

local function mooncakefn() return fn(OnAttachedMoonCake, OnDetachedMoonCake, TUNING.TOTAL_DAY_TIME, nil, "forcefieldlunar", "forcefieldlunar", "open", "idle_loop") end
local function balutfn() return fn(OnAttachedBalut, OnDetachedBalut, TUNING.TOTAL_DAY_TIME, BalutFx) end
local function brigadeirofn() return fn(OnAttachedBrigadeiro, OnDetachedBrigadeiro, TUNING.TOTAL_DAY_TIME) end
local function kyivcakefn() return fn(OnAttachedKyivcake, OnDetachedKyivcake, TUNING.TOTAL_DAY_TIME) end
local function empanadasfn() return fn(OnAttachedEmpanadas, OnDetachedEmpanadas, TUNING.TOTAL_DAY_TIME) end
local function kimchifn() return fn(OnAttachedKimchi, OnDetachedKimchi, TUNING.TOTAL_DAY_TIME) end
local function anzacfn() return fn(OnAttachedAnzac, OnDetachedAnzac, TUNING.TOTAL_DAY_TIME) end
local function mopanefn() return fn(OnAttachedMopane, OnDetachedMopane, 10*TUNING.TOTAL_DAY_TIME) end

return
Prefab("chasni_mooncakebuff", mooncakefn),
Prefab("chasni_balutbuff", balutfn),
Prefab("chasni_brigadeirobuff", brigadeirofn),
Prefab("chasni_kyivcakebuff", kyivcakefn),
Prefab("chasni_empanadasbuff", empanadasfn),
Prefab("chasni_kimchibuff", kimchifn),
Prefab("chasni_anzacbuff", anzacfn),
Prefab("chasni_mopanebuff", mopanefn)
