local elixir_tunings = require("prefabs/wendy/ghostly_elixirs_defs_perk").elixir_defs

local function getAsset(name)
    return {
        Asset("ANIM", "anim/chasni_ghostly_elixirs.zip"),
        Asset("ANIM", "anim/chasni_abigail_vial.zip"),
        Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
        Asset("SCRIPT", "scripts/prefabs/wendy/ghostly_elixirs_defs_perk.lua"),
    }
end

local function getPrefab(name)
    return {
        name.."_buff",
        name.."_fx",
        name.."_dripfx",
    }
end

local function DoApplyElixir(inst, giver, target)
    local buff_type = "elixir_buff"

    if inst.potion_tunings.super_elixir then
        buff_type = "super_elixir_buff"
    end

    local buff = target:AddDebuff(buff_type, inst.buff_prefab, nil, nil, function()
        local cur_buff = target:GetDebuff(buff_type)
        if cur_buff ~= nil and cur_buff.prefab ~= inst.buff_prefab then
            target:RemoveDebuff(buff_type)
        end
    end)

    if buff then
        local new_buff = target:GetDebuff(buff_type)
        new_buff:buff_skill_modifier_fn(giver, target)
        return buff
    end
end

local function potion_fn(anim, potion_tunings, buff_prefab, elixir_type)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("chasni_abigail_vial")
    inst.AnimState:SetBuild("chasni_abigail_vial")
    inst.AnimState:PlayAnimation(anim)
    inst.elixir_buff_type = elixir_type

    if potion_tunings.FLOATER then
        MakeInventoryFloatable(inst, potion_tunings.FLOATER[1], potion_tunings.FLOATER[2], potion_tunings.FLOATER[3])
    else
        MakeInventoryFloatable(inst)
    end

    inst:AddTag("ghostlyelixir")

    if potion_tunings.super_elixir then
        inst:AddTag("super_elixir")
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.buff_prefab = buff_prefab
    inst.potion_tunings = potion_tunings

    inst:AddComponent("inspectable")

    local image = "ghostlyelixir_" .. anim
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = image
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..image..".xml"
    inst:AddComponent("stackable")

    inst:AddComponent("ghostlyelixir")
    inst.components.ghostlyelixir.doapplyelixerfn = DoApplyElixir

    MakeHauntableLaunch(inst)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    return inst
end

local function buff_OnTick(inst, target)
    if target.components.health and not target.components.health:IsDead() then
        if target:HasTag("player") then
            if inst.potion_tunings.TICK_FN_PLAYER then
                inst.potion_tunings.TICK_FN_PLAYER(inst, target)
            end
        else
            inst.potion_tunings.TICK_FN(inst, target)
        end
    else
        inst.components.debuff:Stop()
    end
end

local function buff_DripFx(inst, target)
    if not target.inlimbo and not target.sg:HasStateTag("busy") then
        SpawnPrefab((target:HasTag("player") and inst.potion_tunings.dripfx_player) or inst.potion_tunings.dripfx).Transform:SetPosition(target.Transform:GetWorldPosition())
    end
end

local function buff_OnAttached(inst, target)
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0)

    if target:HasTag("player") then
        if inst.potion_tunings.ONAPPLY_PLAYER then
            inst.potion_tunings.ONAPPLY_PLAYER(inst, target)
        end
    else
        if inst.potion_tunings.ONAPPLY then
            inst.potion_tunings.ONAPPLY(inst, target)
        end
    end

    if inst.potion_tunings.TICK_RATE then
        inst.task = inst:DoPeriodicTask(inst.potion_tunings.TICK_RATE, buff_OnTick, nil, target)
    end
    inst.driptask = inst:DoPeriodicTask(TUNING.GHOSTLYELIXIR_DRIP_FX_DELAY, buff_DripFx, TUNING.GHOSTLYELIXIR_DRIP_FX_DELAY * 0.25, target)

    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)

    if inst.potion_tunings.fx and not target.inlimbo then
        local fx = SpawnPrefab((target:HasTag("player") and inst.potion_tunings.fx_player) or inst.potion_tunings.fx)
        fx.entity:SetParent(target.entity)
    end
end

local function buff_OnTimerDone(inst, data)
    if data.name == "decay" then
        inst.components.debuff:Stop()
    end
end

local function buff_OnExtended(inst, target)
    local duration = (target:HasTag("player") and inst.potion_tunings.DURATION_PLAYER) or inst.potion_tunings.DURATION

    if inst.duration_extended_by_skill then
        duration = duration * inst.duration_extended_by_skill
    end

    inst.components.timer:StopTimer("decay")
    inst.components.timer:StartTimer("decay", duration)

    if inst.task then
        inst.task:Cancel()
        inst.task = inst:DoPeriodicTask(inst.potion_tunings.TICK_RATE, buff_OnTick, nil, target)
    end

    if inst.potion_tunings.fx and not target.inlimbo and not target:HasTag("player") then
        local fx = SpawnPrefab(inst.potion_tunings.fx)
        fx.entity:SetParent(target.entity)
    end

    inst.slowed = nil
end

local function buff_OnDetached(inst, target)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    if inst.driptask then
        inst.driptask:Cancel()
        inst.driptask = nil
    end

    if target:HasTag("player") then
        if inst.potion_tunings.ONDETACH_PLAYER then
            inst.potion_tunings.ONDETACH_PLAYER(inst, target)
        end
    else
        if inst.potion_tunings.ONDETACH then
            inst.potion_tunings.ONDETACH(inst, target)
        end
    end
    inst:Remove()
end

local function buff_skill_modifier_fn(inst,doer,target)
    local duration_mult = 1

    if inst.potion_tunings.skill_modifier_long_duration and doer.components.skilltreeupdater:IsActivated("wendy_potion_duration") then
        duration_mult = duration_mult + TUNING.SKILLS.WENDY.POTION_DURATION_MOD
        inst.duration_extended_by_skill = TUNING.SKILLS.WENDY.POTION_DURATION_MOD
    end

    local duration = (target:HasTag("player") and inst.potion_tunings.DURATION_PLAYER) or inst.potion_tunings.DURATION
    inst.components.timer:StopTimer("decay")
    inst.components.timer:StartTimer("decay", duration * duration_mult )

    if target:HasTag("ghost") then
        target:updatehealingbuffs()
    end
end

local function buff_fn(tunings, dodelta_fn)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:Hide()

    if not TheWorld.ismastersim then
        inst:DoTaskInTime(0, inst.Remove)
        return inst
    end

    inst.buff_skill_modifier_fn = buff_skill_modifier_fn
    inst.entity:AddTransform()

    --[[Non-networked entity]]
    --inst.entity:SetCanSleep(false)
    inst.entity:Hide()
    inst.persists = false

    inst.potion_tunings = tunings

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(buff_OnAttached)
    inst.components.debuff:SetDetachedFn(buff_OnDetached)
    inst.components.debuff:SetExtendedFn(buff_OnExtended)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("decay", tunings.DURATION)
    inst:ListenForEvent("timerdone", buff_OnTimerDone)

    return inst
end

local function light_fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.Light:SetRadius(3.5)
    inst.Light:SetFalloff(.9)
    inst.Light:SetIntensity(.5)
    inst.Light:SetColour(1, 1, 1)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

local function chansilunarpotion_fn() return potion_fn("lunar", elixir_tunings.ghostlyelixir_chasnilunar, "ghostlyelixir_chasnilunar_buff", "chasnilunar") end
local function chasnishadowpotion_fn() return potion_fn("shadow", elixir_tunings.ghostlyelixir_chasnishadow, "ghostlyelixir_chasnishadow_buff", "chasnishadow") end
local function temperaturepotion_fn() return potion_fn("temperature", elixir_tunings.ghostlyelixir_temperature, "ghostlyelixir_temperature_buff", "temperature") end
local function slowpotion_fn() return potion_fn("slow", elixir_tunings.ghostlyelixir_slow, "ghostlyelixir_slow_buff", "slow") end

local function chasnilunarbuff_fn() return buff_fn(elixir_tunings.ghostlyelixir_chasnilunar) end
local function chasnishadowbuff_fn() return buff_fn(elixir_tunings.ghostlyelixir_chasnishadow) end
local function temperaturebuff_fn() return buff_fn(elixir_tunings.ghostlyelixir_temperature) end
local function slowbuff_fn() return buff_fn(elixir_tunings.ghostlyelixir_slow) end

return
Prefab("ghostlyelixir_chasnilunar", chansilunarpotion_fn, getAsset("ghostlyelixir_lunar"), getPrefab("ghostlyelixir_chasnilunar")),
Prefab("ghostlyelixir_chasnishadow", chasnishadowpotion_fn, getAsset("ghostlyelixir_shadow"), getPrefab("ghostlyelixir_chasnishadow")),
Prefab("ghostlyelixir_temperature", temperaturepotion_fn, getAsset("ghostlyelixir_temperature"), getPrefab("ghostlyelixir_temperature")),
Prefab("ghostlyelixir_slow", slowpotion_fn, getAsset("ghostlyelixir_slow"), getPrefab("ghostlyelixir_slow")),

Prefab("ghostlyelixir_chasnilunar_buff", chasnilunarbuff_fn),
Prefab("ghostlyelixir_chasnishadow_buff", chasnishadowbuff_fn),
Prefab("ghostlyelixir_temperature_buff", temperaturebuff_fn),
Prefab("ghostlyelixir_slow_buff", slowbuff_fn),

Prefab("ghostlyelixir_speed_light", light_fn)

