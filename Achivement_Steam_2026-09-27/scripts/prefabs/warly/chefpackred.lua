local assets =
{
    Asset("ANIM", "anim/ui_krampusbag_2x8.zip"),
    Asset("ANIM", "anim/swap_chefpackred.zip"),
    Asset("ATLAS", "images/inventoryimages/chefpackred.xml"),
    Asset("IMAGE", "images/inventoryimages/chefpackred.tex"),
}

local prefabs =
{
    "ash",
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("backpack", "swap_chefpackred", "backpack")
    if inst.components.container then
        inst.components.container:Open(owner)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("backpack")
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
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", 0.125, 0.65)

    inst.AnimState:SetBank("backpack1")
    inst.AnimState:SetBuild("swap_chefpackred")
    inst.AnimState:PlayAnimation("anim")

    inst.foleysound = "dontstarve/movement/foley/backpack"

    inst:AddTag("backpack")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
	inst.components.inventoryitem.imagename = "chefpackred"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chefpackred.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BACK or EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("chefpackred")
    inst:AddComponent("preserver")
    inst.components.preserver:SetPerishRateMultiplier(0)

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    inst.components.burnable:SetOnBurntFn(onburnt)
    inst.components.burnable:SetOnIgniteFn(onignite)
    inst.components.burnable:SetOnExtinguishFn(onextinguish)

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end

return Prefab("chefpackred", fn, assets, prefabs)
