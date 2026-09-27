local assets =
{
    Asset("ANIM", "anim/ui_krampusbag_2x8.zip"),
    Asset("ANIM", "anim/swap_bookpack.zip"),
    Asset("ATLAS", "images/inventoryimages/bookpack.xml"),
    Asset("IMAGE", "images/inventoryimages/bookpack.tex"),
}

local prefabs =
{
    "ash",
}

local RESTORE_TIME = chasni_getitemconfig("bookpack", "REST") or 30
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("backpack", "swap_bookpack", "backpack")
    owner.AnimState:OverrideSymbol("swap_body", "swap_bookpack", "swap_body")
    if inst.components.container then
        inst.components.container:Open(owner)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("backpack")
    if inst.components.container then
        inst.components.container:Close(owner)
    end
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

local function RestoreBooks(inst)
    for k,v in pairs(inst.components.container.slots) do
        if v:HasTag("book") and v.components.finiteuses then
            local percent = v.components.finiteuses:GetPercent()
            if percent < 1 then
                v.components.finiteuses:SetPercent(math.min(1, percent + 0.04))
            end
        end
    end
end

local function ItemGet(inst)
    if inst.RestoreTask == nil then
        if inst.components.container:HasItemWithTag("book", 1) then
            inst.RestoreTask = inst:DoPeriodicTask(RESTORE_TIME, RestoreBooks)
        end
    end
end

local function ItemLose(inst)
    if not inst.components.container:HasItemWithTag("book", 1) then
        if inst.RestoreTask then
            inst.RestoreTask:Cancel()
            inst.RestoreTask = nil
        end
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

    inst.AnimState:SetBank("swap_bookpack")
    inst.AnimState:SetBuild("swap_bookpack")
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
	inst.components.inventoryitem.imagename = "bookpack"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/bookpack.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BACK or EQUIPSLOTS.BODY
	inst.components.equippable.dapperness = TUNING.DAPPERNESS_MED
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("bookpack")

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    inst.components.burnable:SetOnBurntFn(onburnt)
    inst.components.burnable:SetOnIgniteFn(onignite)
    inst.components.burnable:SetOnExtinguishFn(onextinguish)

    MakeHauntableLaunchAndDropFirstItem(inst)

    inst:ListenForEvent("itemget", ItemGet)
    inst:ListenForEvent("itemlose", ItemLose)

    return inst
end

return Prefab("bookpack", fn, assets, prefabs)
