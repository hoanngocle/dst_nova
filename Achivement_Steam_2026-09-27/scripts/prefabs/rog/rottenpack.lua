local assets =
{
    Asset("ANIM", "anim/ui_krampusbag_2x8.zip"),
    Asset("ANIM", "anim/swap_rottenpack.zip"),
    Asset("ATLAS", "images/inventoryimages/rottenpack.xml"),
    Asset("IMAGE", "images/inventoryimages/rottenpack.tex"),
}

local prefabs =
{
    "ash",
}

local SHADOW_LEVEL = 4
local RESTORE_TIME = chasni_getitemconfig("rottenpack", "REST") or 1
local RESTORE_AMOUNT = chasni_getitemconfig("rottenpack", "RESA") or 0.001
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("backpack", "swap_rottenpack", "backpack")
    owner.AnimState:OverrideSymbol("swap_body", "swap_rottenpack", "swap_body")
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

local function onequiptomodel(inst, owner)
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

local function isMagicItemOrShadowItem(item)
    return item:HasTag("shadow_item") or item:HasTag("shadowlevel") or chasni_isMagicItem(item.prefab)
end

local function haveMagicItemOrShadowItem(inst)
    for k,v in pairs(inst.components.container.slots) do
        if isMagicItemOrShadowItem(v) then
            return true
        end
    end
    return false
end

local function RestoreItem(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and owner:HasTag("player") then
        for k,v in pairs(inst.components.container.slots) do
            if isMagicItemOrShadowItem(v) then
                if v.components.finiteuses then
                    local p = v.components.finiteuses:GetPercent()
                    v.components.finiteuses:SetPercent(math.min(1, p + RESTORE_AMOUNT))
                end
                if v.components.armor then
                    local p = v.components.armor:GetPercent()
                    v.components.armor:SetPercent(math.min(1, p + RESTORE_AMOUNT))
                end
                if v.components.fueled then
                    local p = v.components.fueled:GetPercent()
                    v.components.fueled:SetPercent(math.min(1, p + RESTORE_AMOUNT))
                end
            end
        end
    end
end

local function ItemGet(inst)
    if inst.RestoreTask == nil then
        if haveMagicItemOrShadowItem(inst) then
            inst.RestoreTask = inst:DoPeriodicTask(RESTORE_TIME, RestoreItem)
        end
    end
end

local function ItemLose(inst)
    if not haveMagicItemOrShadowItem(inst) then
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

    inst.AnimState:SetBank("swap_rottenpack")
    inst.AnimState:SetBuild("swap_rottenpack")
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
	inst.components.inventoryitem.imagename = "rottenpack"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/rottenpack.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BACK or EQUIPSLOTS.BODY
	inst.components.equippable.dapperness = TUNING.DAPPERNESS_MED
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(SHADOW_LEVEL)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("rottenpack")
    inst:AddComponent("preserver")
    inst.components.preserver:SetPerishRateMultiplier(10)

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

return Prefab("rottenpack", fn, assets, prefabs)
