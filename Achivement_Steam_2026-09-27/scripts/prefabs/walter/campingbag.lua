local assets =
{
    Asset("ANIM", "anim/ui_krampusbag_2x8.zip"),
    Asset("ANIM", "anim/campingbag.zip"),
    Asset("ATLAS", "images/inventoryimages/campingbag.xml"),
}

local prefabs =
{
    "ash",
}

local HUNGER_DRAIN = 3 -- if not expertwalter3
local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:OverrideSymbol("backpack", "campingbag", "backpack")
    owner.AnimState:OverrideSymbol("swap_body", "campingbag", "swap_body")
    if inst.components.container then
        inst.components.container:Open(owner)
    end
    if chasni_hastag(inst, owner) then
    elseif owner.components.hunger then
        owner.components.hunger.burnratemodifiers:SetModifier(inst, HUNGER_DRAIN)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("backpack")
    if inst.components.container then
        inst.components.container:Close(owner)
    end
    if owner.components.hunger then
        owner.components.hunger.burnratemodifiers:RemoveModifier(inst)
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
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    local swap_data = {bank = "seedpouch", anim = "anim"}
    MakeInventoryFloatable(inst, "med", 0.125, 0.65, nil, nil, swap_data)

    inst.AnimState:SetBank("seedpouch")
    inst.AnimState:SetBuild("campingbag")
    inst.AnimState:PlayAnimation("anim")

    inst.foleysound = "dontstarve/movement/foley/backpack"

    inst:AddTag("backpack")

    inst._restrictedtag = "expertwalter3"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
    inst.components.inventoryitem.imagename = "campingbag"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/campingbag.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BACK or EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("campingbag")
    inst.components.container:EnableInfiniteStackSize(true)

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    inst.components.burnable:SetOnBurntFn(onburnt)
    inst.components.burnable:SetOnIgniteFn(onignite)
    inst.components.burnable:SetOnExtinguishFn(onextinguish)

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end

return Prefab("campingbag", fn, assets, prefabs)
