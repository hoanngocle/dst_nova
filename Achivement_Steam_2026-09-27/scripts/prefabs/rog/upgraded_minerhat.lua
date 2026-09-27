require "functions/helperfunctions"

local assets =
{
    Asset("ANIM", "anim/upgraded_minerhat.zip"),
    Asset("ATLAS", "images/inventoryimages/upgraded_minerhat.xml"),
}

local prefabs =
{
    "upgraded_minerhatlight"
}

local ARMOR = chasni_getitemconfig("upgraded_minerhat", "ARMOR") or 0.30
local FUEL = (chasni_getitemconfig("upgraded_minerhat", "FUEL") or 1) * TUNING.TOTAL_DAY_TIME
local LIGHT_RADIUS = chasni_getitemconfig("upgraded_minerhat", "LIGHT") or 4
local function turnoff(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and inst.components.equippable and inst.components.equippable:IsEquipped() then
        owner.AnimState:OverrideSymbol("swap_hat", "upgraded_minerhat", "swap_hat_off")
        chasni_hatswapequip(owner)
    end
    inst.components.fueled:StopConsuming()
    if inst._light then
        if inst._light:IsValid() then
            inst._light:Remove()
        end
        inst._light = nil
        local soundemitter = owner and owner.SoundEmitter or inst.SoundEmitter
        soundemitter:PlaySound("dontstarve/common/minerhatOut")
    end
end

local function ondepleted(inst)
    local equippable = inst.components.equippable
    if equippable and equippable:IsEquipped() then
        local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner or nil
        if owner then
            local data =
            {
                prefab = inst.prefab,
                equipslot = equippable.equipslot,
            }
            turnoff(inst)
            owner:PushEvent("torchranout", data)
            return
        end
    end
    turnoff(inst)
end

local function onequip(inst)
    local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner or nil
    if not inst.components.fueled:IsEmpty() then
        if inst._light == nil or not inst._light:IsValid() then
            inst._light = SpawnPrefab("upgraded_minerhatlight")
        end
        if owner then
            owner.AnimState:OverrideSymbol("swap_hat", "upgraded_minerhat", "swap_hat")
            chasni_hatswapequip(owner)

            inst._light.entity:SetParent(owner.entity)
        end
        inst.components.fueled:StartConsuming()
        local soundemitter = owner and owner.SoundEmitter or inst.SoundEmitter
        soundemitter:PlaySound("dontstarve/common/minerhatAddFuel")
    elseif owner then
        owner.AnimState:OverrideSymbol("swap_hat", "upgraded_minerhat", "swap_hat_off")
        chasni_hatswapequip(owner)
    end
end

local function onequiptomodel(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "upgraded_minerhat", "swap_hat")
    chasni_hatswapequip(owner)
    turnoff(inst)
end

local function onunequip(inst, owner)
    chasni_hatswapunequip(owner)

    turnoff(inst)
end

local function onremove(inst)
    if inst._light and inst._light:IsValid() then
        inst._light:Remove()
    end
end

local function ontakefuel(inst)
    if inst.components.equippable and inst.components.equippable:IsEquipped() then
        onequip(inst)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("upgraded_minerhat")
    inst.AnimState:SetBuild("upgraded_minerhat")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("waterproofer")
    inst:AddTag("chasni_hidearmorpctg")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("armor")
    inst.components.armor:InitIndestructible(ARMOR)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_ABSOLUTE)

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.CAVE
    inst.components.fueled:InitializeFuelLevel(FUEL)
    inst.components.fueled:SetDepletedFn(ondepleted)
    inst.components.fueled:SetTakeFuelFn(ontakefuel)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
    inst.components.fueled.accepting = true

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "upgraded_minerhat"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/upgraded_minerhat.xml"
    inst.components.inventoryitem:SetOnDroppedFn(turnoff)

    inst.OnRemoveEntity = onremove

    return inst
end

local function minerhatlightfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.Light:SetFalloff(0.5)
    inst.Light:SetIntensity(.75)
    inst.Light:SetRadius(LIGHT_RADIUS)
    inst.Light:SetColour(180 / 255, 195 / 255, 150 / 255)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    return inst
end

return
Prefab("upgraded_minerhat", fn, assets, prefabs),
Prefab("upgraded_minerhatlight", minerhatlightfn)
