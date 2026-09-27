local assets =
{
    Asset("ANIM", "anim/armor_seashell.zip"),
    Asset("ATLAS", "images/inventoryimages/armor_seashell.xml"),
}

local SLOW = chasni_getitemconfig("marbled_armor", "SLOW") or 0.25
local ARMOR = chasni_getitemconfig("marbled_armor", "ARMOR") or 0.25
local BONUS_HEALTH_MULT = chasni_getitemconfig("marbled_armor", "HLM") or 1.5
local function OnBlocked(owner)
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "armor_seashell", "swap_body")
    inst:ListenForEvent("blocked", OnBlocked, owner)

    if chasni_hastag(inst, owner) and owner.components.health then
        inst:DoTaskInTime(0.01, function()
            local health = owner.components.health
            inst.increasedHealth = health.maxhealth * BONUS_HEALTH_MULT
            local amount = health.maxhealth + inst.increasedHealth
            chasni_setMaxHealth(health, amount)
        end)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst:RemoveEventCallback("blocked", OnBlocked, owner)

    if owner.components.health and inst.increasedHealth then
        local health = owner.components.health
        local amount = health.maxhealth > inst.increasedHealth and health.maxhealth - inst.increasedHealth or 1
        chasni_setMaxHealth(health, amount)
        inst.increasedHealth = nil
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("armor_seashell")
    inst.AnimState:SetBuild("armor_seashell")
    inst.AnimState:PlayAnimation("anim")

    inst.foleysound = "dontstarve/movement/foley/marblearmour"
    inst._restrictedtag = "expertwolf2"

    inst:AddTag("hide_percentage")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetSinks(true)
    inst.components.inventoryitem.imagename = "armor_seashell"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/armor_seashell.xml"

    inst:AddComponent("armor")
    inst.components.armor:InitIndestructible(ARMOR)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = SLOW

    inst.increasedHealth = nil
    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("marbled_armor", fn, assets) 
