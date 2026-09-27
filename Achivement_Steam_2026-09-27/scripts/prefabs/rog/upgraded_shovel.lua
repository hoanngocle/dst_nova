local assets =
{
    Asset("ANIM", "anim/upgraded_shovel.zip"),
    Asset("ANIM", "anim/swap_upgraded_shovel.zip"),
    Asset("ATLAS", "images/inventoryimages/upgraded_shovel.xml"),
}

local prefabs =
{
    "upgraded_shovel_ground",
    "shovel_dirt"
}

local DAMAGE = 10
local USES = chasni_getitemconfig("upgraded_shovel", "USES") or 10
local RANGE = chasni_getitemconfig("upgraded_shovel", "RNG") or 20
local TAG = {"DIG_workable"}
local function onwork(owner, data)
    local x, y, z = owner.Transform:GetWorldPosition()
    local aoeworking = false
    local ents = TheSim:FindEntities(x, y, z, RANGE, TAG, chasni_TAG_NOTARGET)
    for _, v in pairs(ents) do
        if v ~= data.target and (v.prefab == data.target.prefab) and v.components.workable and v.components.workable:CanBeWorked() and v.components.workable:GetWorkAction() == ACTIONS.DIG then
            local vx, vy, vz = v.Transform:GetWorldPosition()
            chasni_spawnprefab("shovel_dirt", vx, vy, vz)
            v.components.workable:WorkedBy(owner, 1)
            aoeworking = true
        end
    end
    if aoeworking then
        owner:ShakeCamera(CAMERASHAKE.SIDE, 1, 0.02, 0.25)
        owner.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/step_stomp")
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_upgraded_shovel", "swap_shovel")
    inst:ListenForEvent("working", onwork, owner)

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    inst:RemoveEventCallback("working", onwork, owner)

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function castMagic(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    local pos = Vector3(owner.Transform:GetWorldPosition())
    chasni_spawnprefab("upgraded_shovel_ground", pos.x, pos.y, pos.z)
    inst.components.finiteuses:Use(1)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("upgraded_shovel")
    inst.AnimState:SetBuild("upgraded_shovel")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)

    inst:AddTag("tool")
    inst:AddTag("weapon")
    inst:AddComponent("floater")
    inst:AddTag("castspell_shovel")

    inst.spelltype = "SCIENCE"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetIgnoreCombatDurabilityLoss(true)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "upgraded_shovel"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/upgraded_shovel.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.DIG)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DAMAGE)

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canusefrominventory = true
    inst.components.spellcaster:SetSpellFn(castMagic)
    inst.components.spellcaster.castingstate = "castspell_shovel"

    MakeHauntableLaunch(inst)

    return inst
end

local function close(inst)
    inst.AnimState:PlayAnimation("no_access", true)
end

local function open(inst)
    inst.AnimState:PlayAnimation("open", true)
end

local function full(inst)
    inst.AnimState:PlayAnimation("over_capacity", true)
end

local function fn_shovelground()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("cave_entrance")
    inst.AnimState:SetBuild("cave_entrance")
    inst.AnimState:PlayAnimation("open")
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("antlion_sinkhole_blocker")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    if TheNet:GetServerIsClientHosted() and not (TheShard:IsMaster() or TheShard:IsSecondary()) then
        RemovePhysicsColliders(inst)
        inst.AnimState:SetScale(0,0)
        inst:AddTag("NOCLICK")
        inst:AddTag("CLASSIFIED")
    end

    inst:AddComponent("inspectable")

    inst.persists = false

    inst:ListenForEvent("migration_available", open)
    inst:ListenForEvent("migration_unavailable", close)
    inst:ListenForEvent("migration_full", full)

    inst:AddComponent("worldmigrator")
    inst.components.worldmigrator:SetEnabled(false)
    close(inst)

    inst:DoTaskInTime(.1,function()
        local sinkhole = GetClosestInstWithTag("cavehole", inst, 400)
        if inst.components.worldmigrator and sinkhole then
            open(inst)
            inst.components.worldmigrator:SetEnabled(true)
            inst.components.worldmigrator.id = sinkhole.components.worldmigrator.id
            inst.components.worldmigrator.auto = sinkhole.components.worldmigrator.auto
            inst.components.worldmigrator.linkedWorld = sinkhole.components.worldmigrator.linkedWorld
            inst.components.worldmigrator.receivedPortal = sinkhole.components.worldmigrator.receivedPortal
        end
    end)

    return inst
end

return
Prefab("upgraded_shovel", fn, assets, prefabs),
Prefab("upgraded_shovel_ground", fn_shovelground, assets)
