local assets =
{
    Asset("ANIM", "anim/upgraded_hat_catcoon.zip"),
    Asset("ATLAS", "images/inventoryimages/upgraded_hat_catcoon.xml"),
}

local prefabs =
{
    "chasni_kitcoon_healer",
    "spawn_fx_tiny"
}

local SPAWN_RANGE = 2
local function SpawnKitCoon(inst, owner)
    if owner and owner.components.leader and owner:HasTag("player") then
        local x, _, z = owner.Transform:GetWorldPosition()
        local radius = SPAWN_RANGE
        local i = math.random(1, 6)
        local delta_theta = PI2 / 6
        local pos_x, pos_y, pos_z = x + radius * math.cos((i-1) * delta_theta), 0, z + radius * math.sin((i-1) * delta_theta)
        local kitcoon = SpawnPrefab("chasni_kitcoon_healer")
        kitcoon.Transform:SetPosition(pos_x, pos_y, pos_z)
        owner.components.leader:AddFollower(kitcoon)
        kitcoon.sg.mem.prevcasttime = GetTime()
        inst.kitcoon = kitcoon

        local fx = SpawnPrefab("spawn_fx_tiny")
        fx.entity:SetParent(kitcoon.entity)
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "upgraded_hat_catcoon", "swap_hat")
    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")

    SpawnKitCoon(inst, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if inst.kitcoon then
        local x, y, z = inst.kitcoon.Transform:GetWorldPosition()
        if x and y and z then
            chasni_spawnprefab("spawn_fx_tiny", x, y, z)
        end
        inst.kitcoon:Remove()
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", 0.8)

    inst.AnimState:SetBank("upgraded_hat_catcoon")
    inst.AnimState:SetBuild("upgraded_hat_catcoon")
    inst.AnimState:PlayAnimation("anim")

    inst.Transform:SetScale(0.85,0.85,0.85)
    inst:AddTag("hat")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.dapperness = TUNING.DAPPERNESS_MED

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "upgraded_hat_catcoon"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/upgraded_hat_catcoon.xml"

    inst.catcoon = nil

    return inst
end

return Prefab("upgraded_catcoonhat", fn, assets, prefabs)