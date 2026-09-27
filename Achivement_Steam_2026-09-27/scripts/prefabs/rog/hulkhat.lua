local assets =
{
    Asset("ANIM", "anim/chasni_artifacthat.zip"),
    Asset("ATLAS", "images/inventoryimages/chasni_artifacthat.xml"),
}

local prefabs =
{
    "hulkhat_shield_buff"
}

local FUEL = chasni_getitemconfig("hulkhat", "USE") or 10
local function toggle(inst, owner, ison)
    if inst.components.fueled and not inst.components.fueled:IsEmpty() then
        if ison then
            owner:AddDebuff("hulkhat_shield_buff", "hulkhat_shield_buff")
            if inst.components.fueled then
                inst.components.fueled:StartConsuming()
            end
        else
            owner:RemoveDebuff("hulkhat_shield_buff")
            if inst.components.fueled then
                inst.components.fueled:StopConsuming()
            end
        end
    else
        owner:RemoveDebuff("hulkhat_shield_buff")
        if inst.components.fueled then
            inst.components.fueled:StopConsuming()
        end
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "chasni_artifacthat", "swap_hat")
    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")

    inst:RemoveTag("chasni_cannot_toggleable")
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if inst.components.toggleableitem and inst.components.toggleableitem.on == true then
        inst.components.toggleableitem:ToggleItem()
    end
    inst:AddTag("chasni_cannot_toggleable")
end

local function onuse(inst, ison)
    local owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner()
    if owner then
        toggle(inst, owner, ison)
    end
end

local function OnFuelDepleted(inst)
    if inst.components.toggleableitem and inst.components.toggleableitem.on == true then
        inst.components.toggleableitem:ToggleItem()
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("chasni_artifacthat")
    inst.AnimState:SetBuild("chasni_artifacthat")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("chasni_cannot_toggleable")
    inst:AddTag("toggleableitem_equip")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("toggleableitem")
    inst.components.toggleableitem:SetOnToggleFn(onuse)

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.CHEMICAL
    inst.components.fueled:InitializeFuelLevel(FUEL)
    inst.components.fueled.no_sewing = true
    inst.components.fueled.accepting = true
    inst.components.fueled.period = FRAMES
    inst.components.fueled:SetDepletedFn(OnFuelDepleted)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "chasni_artifacthat"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_artifacthat.xml"

    inst.catcoon = nil

    return inst
end

return Prefab("hulkhat", fn, assets, prefabs)