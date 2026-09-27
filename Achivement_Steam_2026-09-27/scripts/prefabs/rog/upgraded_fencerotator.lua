local assets =
{
    Asset("ANIM", "anim/upgraded_fencerotator.zip"),
    Asset("ATLAS", "images/inventoryimages/upgraded_fencerotator.xml"),
}

local prefabs =
{
    "fence_rotator_fx",
}

local DAMAGE = chasni_getitemconfig("upgraded_fencerotator", "DMG") or 85
local DISARM_CHANCE = chasni_getitemconfig("upgraded_fencerotator", "CHC") or 0.5
local function onattack(inst, attacker, target)
    if target and target:IsValid() and math.random() < DISARM_CHANCE then
        local snap = SpawnPrefab("fence_rotator_fx")
        local x, _, z = inst.Transform:GetWorldPosition()
        local x1, y1, z1 = target.Transform:GetWorldPosition()
        local angle = -math.atan2(z1 - z, x1 - x)
        snap.Transform:SetPosition(x1, y1, z1)
        snap.Transform:SetRotation(angle * RADIANS)
        local rotation = target.Transform:GetRotation()
        if target.SetOrientation then
            target.SetOrientation(target, rotation + 180)
        else
            target.Transform:SetRotation(rotation + 180)
        end
        if target.sg then
            target.sg:GoToState("hit")
        end
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "upgraded_fencerotator", "swap_fence_rotator")

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("fence_rotator")
    inst.AnimState:SetBuild("upgraded_fencerotator")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("fence_rotator")
    inst:AddTag("nopunch")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", 0.05, {1.1, 0.5, 1.1}, true, -9)

    inst:AddTag("sharp")
    inst:AddTag("pointy")
    inst:AddTag("jab")
    inst:AddTag("weapon")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DAMAGE)
    inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "upgraded_fencerotator"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/upgraded_fencerotator.xml"

    inst:AddComponent("fencerotator")
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    return inst
end

return Prefab("upgraded_fencerotator", fn, assets, prefabs)
