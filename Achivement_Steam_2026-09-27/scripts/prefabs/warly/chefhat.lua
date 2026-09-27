require "functions/helperfunctions"

local assets =
{
    Asset("ANIM", "anim/chefhat.zip"),
    Asset("ATLAS", "images/inventoryimages/chefhat.xml"),
}

local BONUS_HUNGER_MULT = chasni_getitemconfig("chefhat", "HNG") or 0.8
local ARMOR = 1
local HUNGER_DAMAGE_MULT = 0.5
local function OnDamaged(inst, data)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and owner.components.hunger then
        local hungerdamage = data * HUNGER_DAMAGE_MULT
        local excessdamage = owner.components.hunger.current - hungerdamage
        owner.components.hunger:DoDelta(-hungerdamage)
        if excessdamage <= 0 and owner.components.health then
            owner.components.health:DoDelta(excessdamage)
        end
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "chefhat", "swap_hat")
    chasni_hatswapequip(owner)
    inst:ListenForEvent("armordamaged", OnDamaged, inst)

    if chasni_hastag(inst, owner) and owner.components.hunger then
        inst:DoTaskInTime(.51, function()
            local hunger = owner.components.hunger
            inst.increasedHunger = hunger.max * BONUS_HUNGER_MULT
            local amount = hunger.max + inst.increasedHunger
            chasni_setMaxHunger(hunger, amount)
        end)
    end
end

local function onunequip(inst, owner)
    chasni_hatswapunequip(owner)
    inst:RemoveEventCallback("armordamaged", OnDamaged, inst)

    if owner.components.hunger and inst.increasedHunger then
        local hunger = owner.components.hunger
        local amount = hunger.max > inst.increasedHunger and hunger.max - inst.increasedHunger or 1
        chasni_setMaxHunger(hunger, amount)
        inst.increasedHunger = nil
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("chefhat")
    inst.AnimState:SetBuild("chefhat")
    inst.AnimState:PlayAnimation("anim")

    inst._restrictedtag = "expertwarly3"

    inst:AddTag("hat")
    inst:AddTag("chefhat")
    inst:AddTag("hide_percentage")

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

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "chefhat"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chefhat.xml"

    inst.increasedHunger = nil
    return inst
end

return Prefab("chefhat", fn, assets)