local assets =
{
    Asset("ANIM", "anim/chasni_mermhat.zip"),
    Asset("ATLAS", "images/inventoryimages/chasni_mermhat.xml"),
}

local ARMOR = chasni_getitemconfig("chasni_mermhat", "ARMOR") or 0.5
local DURABILITY = chasni_getitemconfig("chasni_mermhat", "ARMOR") or 1500
local DAMAGE_MULT = chasni_getitemconfig("chasni_mermhat", "DMG") or 2.5
local SPEED_MULT = chasni_getitemconfig("chasni_mermhat", "SPD") or 1.25
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "chasni_mermhat", "swap_hat")
    owner.AnimState:Show("HAT")

    owner.components.combat.externaldamagemultipliers:SetModifier("chasni_mermhat", DAMAGE_MULT)
    owner.components.locomotor:SetExternalSpeedMultiplier(owner,"chasni_mermhat", SPEED_MULT)
    owner:AddTag("chasni_damagecap")
    owner._chasni_damagecap = -50
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")

    owner.components.combat.externaldamagemultipliers:RemoveModifier("chasni_mermhat")
    owner.components.locomotor:RemoveExternalSpeedMultiplier(owner, "chasni_mermhat")
    owner:RemoveTag("chasni_damagecap")
    owner._chasni_damagecap = nil
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("chasni_mermhat")
    inst.AnimState:SetBuild("chasni_mermhat")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("tradable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "chasni_mermhat"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_mermhat.xml"

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(DURABILITY, ARMOR)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.restrictedtag = "merm_npc"

    inst.increasedHealth = nil
    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("chasni_merm_hat", fn, assets) 
