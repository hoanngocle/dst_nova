local assets =
{
    Asset("ANIM", "anim/goldarmor.zip"),
    Asset("ATLAS", "images/inventoryimages/armorgold.xml"),
}

local ARMOR = chasni_getitemconfig("armorgold", "ARMOR") or 1
local function absorbfn(inst, attacker)
    if attacker and inst.components.container and inst.components.container then
        local gold_stack = inst.components.container:GetItemInSlot(1)
        local item = inst.components.container:RemoveItem(gold_stack, false)
        if item then
            item:Remove()
            return ARMOR
        end
    end
    return 0
end

local function OnBlocked(owner)
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "goldarmor", "swap_body")

    inst:ListenForEvent("blocked", OnBlocked, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst:RemoveEventCallback("blocked", OnBlocked, owner)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("goldarmor")
    inst.AnimState:SetBuild("goldarmor")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hide_percentage")

    inst.foleysound = "dontstarve/movement/foley/logarmour"

    local swap_data = {bank = "goldarmor", anim = "anim"}
    MakeInventoryFloatable(inst, "small", 0.2, 0.80, nil, nil, swap_data)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "armorgold"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/armorgold.xml"

    inst:AddComponent("armor")
    inst.components.armor:InitIndestructible(ARMOR)
    --inst.components.armor:AddWeakness("beaver", TUNING.BEAVER_WOOD_DAMAGE)
    --inst.components.armor:SetTags({ "epic" })
    inst.components.armor.cz_absorb_fn = absorbfn

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("armorgold")

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("armorgold", fn, assets)
