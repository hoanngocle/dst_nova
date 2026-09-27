local assets =
{
    Asset("ANIM", "anim/telebrella.zip"),
    Asset("ANIM", "anim/swap_telebrella.zip"),
    Asset("ANIM", "anim/swap_telebrella_red.zip"),
    Asset("ANIM", "anim/swap_telebrella_green.zip"),

    Asset("ATLAS", "images/inventoryimages/telebrella.xml"),
    Asset("IMAGE", "images/inventoryimages/telebrella.tex"),
}

local TELEDIST = 100 * 100 -- 42.5 * 12.75
local MINTELEDIST = 10 * 10 -- 42.5 * 12.75
local USES = chasni_getitemconfig("telebrella", "USE") or 20
local function UpdateSound(inst)
    if inst.components.equippable:IsEquipped() and TheWorld.state.israining and not inst.SoundEmitter:PlayingSound("umbrellarainsound") then
        if TheWorld.state.israining then
            inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_telebrella/rain", "umbrellarainsound", 0.6)
        else
            inst.SoundEmitter:KillSound("umbrellarainsound")
        end
    end
end

local function findeligiblepad(inst, sourcepad)
    local target = inst.components.inventoryitem.owner
    if sourcepad then
        target = sourcepad
    end
    local pad
    if TheWorld.chasni_telipads then
        local dist = TELEDIST * TELEDIST
        local mindist = MINTELEDIST * MINTELEDIST
        for i,testpad in ipairs(TheWorld.chasni_telipads) do
            local x,y,z = testpad.Transform:GetWorldPosition()
            local ground = TheWorld
            local tile = ground.Map:GetTileAtPoint(x,y,z)
            if tile ~= GROUND.INTERIOR then
                local testdist = target:GetDistanceSqToInst(testpad)
                if testdist < dist and testpad ~= target and testdist > mindist then
                    pad = testpad
                    dist = testdist
                end
            end
        end
    end
    return pad
end

local function checkconnection(inst)
    local player = inst.components.inventoryitem.owner
    local pad = findeligiblepad(inst)
    if inst.lastpad then
        inst.lastpad.turnoff(inst.lastpad)
    end
    if pad then
        if player:GetDistanceSqToInst(pad) < 2*2 then
            local otherpad = findeligiblepad(inst,pad)
            inst.lastpad = pad
            if otherpad then
                inst.lastpad.turnon(inst.lastpad)
            end
            pad = otherpad
        end
        return pad
    end
end

local function canteleport(inst, staff, caster, target, pos)
    if checkconnection(inst, staff) and not TheCamera.interior then
        return true
    end
end

local function postteleport(inst)
    local player = inst.components.inventoryitem.owner
    local light = SpawnPrefab("telebrella_glow")
    if light then
        local x,y,z = player.Transform:GetWorldPosition()
        light.Transform:SetPosition(x,y,z)
    end
    inst.components.finiteuses:Use(1)
end

local function teleport(inst, staff)
    local player = inst.components.inventoryitem.owner
    local pad
    if canteleport(inst, staff) then
        pad = checkconnection(inst, staff)
    end
    if pad then
        local pos = pad:GetPosition()
        if player.Physics then
            player.Physics:Teleport(pos.x, 0, pos.z)
        else
            player.Transform:SetPosition(pos.x, 0, pos.z)
        end
        player:SnapCamera()
        player:ScreenFade(true, 1)
        inst:DoTaskInTime(1, postteleport)
    end
end

local function IsRiding(inst)
    return inst.components.rider and inst.components.rider:IsRiding()
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_telebrella", "swap_telebrella")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    UpdateSound(inst)

    local INTERVAL = 0.1
    inst.task = inst:DoPeriodicTask(INTERVAL, function()
        local player = owner

        local pad = checkconnection(inst)
        if pad and not TheCamera.interior and not IsRiding(owner) then
            inst.flashtime = inst.flashtime + INTERVAL
            local switch = false

            local dist = player:GetDistanceSqToInst(pad)

            local period = INTERVAL
            if not inst.red then
                local max = TELEDIST*TELEDIST
                if dist > max *0.9 then
                    period = INTERVAL
                elseif dist > max *0.75 then
                    period = 1
                elseif dist > max *0.5 then
                    period = 3
                else
                    period = 9999999
                end
            end

            if inst.flashtime > period then
                switch = true
                inst.flashtime = 0
            end
            if switch then
                if not inst.red then
                    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_telebrella/beep")
                    inst.red = true
                else
                    inst.red = nil
                end
            end
            if inst.red then
                player.AnimState:OverrideSymbol("swap_object", "swap_telebrella_red", "swap_telebrella")
            else
                player.AnimState:OverrideSymbol("swap_object", "swap_telebrella_green", "swap_telebrella")

                if inst.components.spellcaster == nil then
                    inst:AddComponent("spellcaster")
                end

                if inst.components.spellcaster then
                    inst.components.spellcaster:SetSpellFn(teleport)
                    inst.components.spellcaster.canuseonpoint = true
                    inst.components.spellcaster.canuseonpoint_water = true -- Does not work for some reason
                    inst.components.spellcaster.canusefrominventory = false
                    inst.components.spellcaster.quickcast = false
                    inst.components.spellcaster.castingstate = "telebrella"
                end
            end
        else
            player.AnimState:OverrideSymbol("swap_object", "swap_telebrella", "swap_telebrella")
            inst:RemoveComponent("spellcaster")
        end
    end)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    UpdateSound(inst)

    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small")

    inst.AnimState:SetBank("telebrella")
    inst.AnimState:SetBuild("telebrella")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("allow_action_on_impassable")
    inst:AddTag("telebrella")
    inst:AddTag("waterproofer")

    inst.spelltype = "SCIENCE"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetIgnoreCombatDurabilityLoss(true)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_HUGE)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(1)

    inst.teleport = teleport

    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(teleport)
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canuseonpoint_water = true
    inst.components.spellcaster.canusefrominventory = false
    inst.components.spellcaster.quickcast = false
    inst.components.spellcaster.castingstate = "telebrella"

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "telebrella"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/telebrella.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst.flashtime = 0

    inst:WatchWorldState("israining", UpdateSound)

    MakeHauntableLaunch(inst)

    return inst
end

local INTENSITY = 1

local function fadein(inst)
    inst.components.fader:StopAll()
    inst.Light:Enable(true)
    if inst:IsAsleep() then
        inst.Light:SetIntensity(INTENSITY)
    else
        inst.Light:SetIntensity(0)
        inst.components.fader:Fade(0, INTENSITY, 0.6, function(v) inst.Light:SetIntensity(v) end)
    end
end

local function fadeout(inst)
    inst.components.fader:StopAll()
    if inst:IsAsleep() then
        inst.Light:SetIntensity(0)
    else
        inst.components.fader:Fade(INTENSITY, 0, 0.6, function(v) inst.Light:SetIntensity(v) end, function() inst.Light:Enable(false) end)
    end
end

local function glowfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.Light:SetFalloff(.7)
    inst.Light:SetIntensity(INTENSITY)
    inst.Light:SetRadius(2)
    inst.Light:SetColour(220/255, 220/255, 220/255)
    inst.Light:Enable(false)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("fader")
    inst.fadein = fadein
    inst.fadeout = fadeout
    inst:DoTaskInTime(0,function() fadein(inst) end)
    inst:DoTaskInTime(0.6,function() fadeout(inst) end)
    inst:DoTaskInTime(0.6 * 2,function() inst:Remove() end)
    return inst
end

return Prefab("chasni_telebrella", fn, assets),
    Prefab("telebrella_glow", glowfn, assets) 