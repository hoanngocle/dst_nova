local assets =
{
    Asset("ANIM", "anim/chefhat.zip"),
    Asset("ATLAS", "images/inventoryimages/chefhat.xml"),
}

local prefabs =
{
    "dark_beeguard",
    "bee_poof_big"
}

local ARMOR = 0.6
local MAX_ARMY = 3
local SPAWN_RANGE = 2
local function SpawnDarkBeeGuard(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    owner:MakeGenericCommander()
    if owner.components.commander:GetNumSoldiers("dark_beeguard") >= MAX_ARMY then
        return
    end

    local x, _, z = owner.Transform:GetWorldPosition()
    local radius = SPAWN_RANGE
    local i = math.random(1, 2)
    local delta_theta = PI2 / 2
    local pos_x, pos_y, pos_z = x + radius * math.cos((i-1) * delta_theta), 0, z + radius * math.sin((i-1) * delta_theta)
    local bee = SpawnPrefab("dark_beeguard")
    bee.Transform:SetPosition(pos_x, pos_y, pos_z)
    bee:AddToArmy(owner)
    SpawnPrefab("bee_poof_big").Transform:SetPosition(pos_x, pos_y, pos_z)
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "hat_bee", "swap_hat")
    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")

    if owner and owner.components.sanity then
        owner.components.sanity.neg_aura_absorb = 1
    end
    if inst.spawningtask then
        inst.spawningtask:Cancel()
        inst.spawningtask = nil
    end
    if owner:HasTag("player") then
        inst.spawningtask = inst:DoPeriodicTask(5, SpawnDarkBeeGuard)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner and owner.components.sanity then
        owner.components.sanity.neg_aura_absorb = 0
    end
    if inst.spawningtask then
        inst.spawningtask:Cancel()
        inst.spawningtask = nil
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.2, 0.8)

    inst.AnimState:SetBank("chefhat")
    inst.AnimState:SetBuild("chefhat")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("waterproofer")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("armor")
    inst.components.armor:InitIndestructible(ARMOR)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "chefhat"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chefhat.xml"

    return inst
end

return Prefab("upgraded_beehat", fn, assets, prefabs)