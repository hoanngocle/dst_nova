local assets =
{
    Asset("ANIM", "anim/hat_tiaraflowerpetals.zip"),
    Asset("ATLAS", "images/inventoryimages/nature_hat.xml"),
}

local HUNGER_MOD = chasni_getitemconfig("nature_hat", "HUNG") or 0.05
local SPEED_MULT = chasni_getitemconfig("nature_hat", "SPD") or 0.8
local PERISHTIME = 480 * (chasni_getitemconfig("nature_hat", "DUR") or 5)
local TENDING_RANGE = (chasni_getitemconfig("nature_hat", "RNG") or 10)
local TAGS = {"farm_plant"}
local function tendingtask(inst)
    local owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner()
    if owner then
        local x,y,z = owner.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z, TENDING_RANGE, TAGS, chasni_TAG_NOTARGET)
        for k,v in pairs(ents) do
            if v.components.farmplanttendable then
                v.components.farmplanttendable:TendTo(owner)
            end
        end
    end
end

local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "hat_tiaraflowerpetals", "swap_hat")
    owner.AnimState:Show("HAT")
    inst.components.fueled:StartConsuming()
    if owner.components.hunger and chasni_hastag(inst, owner) then 
        owner.components.hunger.burnratemodifiers:SetModifier(inst, HUNGER_MOD)
    end
    if owner.components.houndedtarget == nil then
        owner:AddComponent("houndedtarget")
    end
    owner.components.houndedtarget.target_weight_mult:SetModifier(inst, 0)
    inst._updatetask = inst:DoPeriodicTask(1, tendingtask)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    inst.components.fueled:StopConsuming()
    if owner.components.hunger then
        owner.components.hunger.burnratemodifiers:RemoveModifier(inst)
    end
    if owner.components.houndedtarget then
        owner.components.houndedtarget.target_weight_mult:RemoveModifier(inst)
    end

    if inst._updatetask then
        inst._updatetask:Cancel()
        inst._updatetask = nil
    end
end

local function onequiptomodel(inst)
    inst.components.fueled:StopConsuming()
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.2, 0.5)

    inst.AnimState:SetBank("tiaraflowerpetalshat")
    inst.AnimState:SetBuild("hat_tiaraflowerpetals")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("nature_hat")

    inst._restrictedtag = "expertworm1"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)
    inst.components.equippable.walkspeedmult = SPEED_MULT

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "nature_hat"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/nature_hat.xml"

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(PERISHTIME)
    inst.components.fueled:SetDepletedFn(inst.Remove)

    return inst
end

return Prefab("nature_hat", fn, assets)