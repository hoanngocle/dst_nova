local assets =
{
    Asset("ANIM", "anim/crocpack.zip"),
    Asset("ANIM", "anim/swap_crocpack.zip"),
    Asset("ANIM", "anim/ui_piggyback_2x6.zip"),
    Asset("ATLAS", "images/inventoryimages/crocpack.xml"),
}

local prefabs =
{
    "ash",
}

local ARMOR = chasni_getitemconfig("crocpack", "ARMOR") or 0.6
local function absorbfn(inst, attacker)
    if attacker then
        local owner = inst.components.inventoryitem:GetGrandOwner()
        local anglediff = owner.Transform:GetRotation() - owner:GetAngleToPoint(attacker.Transform:GetWorldPosition())
        if not (math.abs(anglediff) <= 90) then
            return ARMOR
        end
    end
    return 0
end

local function OnBlocked(owner)
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("backpack", "swap_crocpack", "backpack")
    owner.AnimState:OverrideSymbol("swap_body", "swap_crocpack", "swap_body")
    if inst.components.container then
        inst.components.container:Open(owner)
    end

    inst:ListenForEvent("blocked", OnBlocked, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("backpack")
    if inst.components.container then
        inst.components.container:Close(owner)
    end

    inst:RemoveEventCallback("blocked", OnBlocked, owner)
end

local function onequiptomodel(inst, owner, from_ground)
    if inst.components.container then
        inst.components.container:Close(owner)
    end
end

local function onburnt(inst)
    if inst.components.container then
        inst.components.container:DropEverything()
        inst.components.container:Close()
    end

    SpawnPrefab("ash").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function onignite(inst)
    if inst.components.container then
        inst.components.container.canbeopened = false
    end
end

local function onextinguish(inst)
    if inst.components.container then
        inst.components.container.canbeopened = true
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.2, 0.65)

    inst.AnimState:SetBank("backpack1")
    inst.AnimState:SetBuild("swap_crocpack")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("backpack")
    inst:AddTag("hide_percentage")

    inst.foleysound = "dontstarve/movement/foley/backpack"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
    inst.components.inventoryitem.imagename = "crocpack"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/crocpack.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BACK or EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)

    inst:AddComponent("armor")
    inst.components.armor:InitIndestructible(0)
    inst.components.armor.cz_absorb_fn = absorbfn

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("crocpack")

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    inst.components.burnable:SetOnBurntFn(onburnt)
    inst.components.burnable:SetOnIgniteFn(onignite)
    inst.components.burnable:SetOnExtinguishFn(onextinguish)

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end

return Prefab("crocpack", fn, assets, prefabs)
