local assets =
{
    Asset("ANIM", "anim/fire_armor.zip"),
    Asset("ATLAS", "images/inventoryimages/fire_armor.xml")
}

local INSULATION = chasni_getitemconfig("fire_armor", "INS") or 240
local BASE_BONUS_DAMAGE = chasni_getitemconfig("fire_armor", "BDM") or 0.5
local function ontempchange(inst, owner)
    if owner.components.temperature then
        local currenttemp = owner.components.temperature and math.floor(owner.components.temperature.current) or 0
        local increment = currenttemp <= 0 and 0 or currenttemp / 60
        increment = math.floor(increment * 10) / 10
        inst.components.equippable.walkspeedmult = math.min(0.2 + increment, 2.2)
        if owner.components.combat then
            owner.components.combat.externaldamagemultipliers:SetModifier("fire_armor", BASE_BONUS_DAMAGE + increment)
        end
    end
end

local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "fire_armor", "swap_body")
    inst:ListenForEvent("temperaturedelta", inst._OnTempChange, owner)

end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst:RemoveEventCallback("temperaturedelta", inst._OnTempChange, owner)

    if owner.components.combat then
        owner.components.combat.externaldamagemultipliers:RemoveModifier("fire_armor")
    end
end

local function onsetbonus_enabled(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner.components.temperature then
        if chasni_hastag(inst, owner) then
            inst.originaloverheattemp = owner.components.temperature.overheattemp
            owner.components.temperature.overheattemp = owner.components.temperature.maxtemp + 10
            inst:AddTag("chasni_heatimune")
        end
    end
end

local function onsetbonus_disabled(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner.components.temperature and inst.originaloverheattemp then
        owner.components.temperature.overheattemp = inst.originaloverheattemp
        inst.originaloverheattemp = nil
    end
    inst:RemoveTag("chasni_heatimune")
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("fire_armor")
    inst.AnimState:SetBuild("fire_armor")
    inst.AnimState:PlayAnimation("anim")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst._restrictedtag = "expertwillow3"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "fire_armor"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/fire_armor.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(INSULATION)

    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName(EQUIPMENTSETNAMES.EXPERTWILLOW3)
    inst.components.setbonus:SetOnEnabledFn(onsetbonus_enabled)
    inst.components.setbonus:SetOnDisabledFn(onsetbonus_disabled)

    MakeHauntableLaunch(inst)
    inst.originaloverheattemp = nil
    inst._OnTempChange = function(owner, data) ontempchange(inst, owner) end

    return inst
end

return Prefab("fire_armor", fn, assets) 
