local assets =
{
    Asset("ANIM", "anim/slipscraft.zip"),
    Asset("ATLAS", "images/inventoryimages/slipscraft.xml")
}

local INSULATION = chasni_getitemconfig("upgraded_whip", "INS") or 120
local MAX_DODGE = chasni_getitemconfig("upgraded_whip", "DODG") or 0.8
local ATTACK_RED = chasni_getitemconfig("upgraded_whip", "ATKRED") or 0.85
local function DodgeChanceFn(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and owner.components.leader and owner.components.leader.numfollowers > 0 then
        return math.min(owner.components.leader.numfollowers/10, MAX_DODGE)
    end
    return 0
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "slipscraft", "swap_body")

    owner:AddTag("sharedodgegeartofollower")
    if owner.components.combat then
        owner.components.combat.externaldamagemultipliers:SetModifier("slipscraft", ATTACK_RED)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")

    owner:RemoveTag("sharedodgegeartofollower")
    if owner.components.combat then
        owner.components.combat.externaldamagemultipliers:RemoveModifier("slipscraft")
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("slipscraft")
    inst.AnimState:SetBuild("slipscraft")
    inst.AnimState:PlayAnimation("anim")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "slipscraft"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/slipscraft.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(INSULATION)

    MakeHauntableLaunch(inst)

    inst.chasni_dodgechancegearfn = DodgeChanceFn

    return inst
end

return Prefab("slipscraft", fn, assets) 
