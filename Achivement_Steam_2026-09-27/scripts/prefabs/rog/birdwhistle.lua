local assets =
{
    normal = {
        Asset("ANIM", "anim/antler.zip"),
        Asset("ANIM", "anim/swap_antler.zip"),
        Asset("ATLAS", "images/inventoryimages/birdwhistle.xml"),
    },
    corrupted = {
        Asset("ANIM", "anim/antler_corrupted.zip"),
        Asset("ANIM", "anim/swap_antler_corrupted.zip"),
        Asset("ATLAS", "images/inventoryimages/birdwhistlecorrupted.xml"),
    },
}

local prefabs =
{
    normal = { },
    corrupted = { "chasni_ancientherald", },
}

local SPAWN_DIST = 25
local USES = chasni_getitemconfig("chasni_birdwhistle", "USES1") or 4
local CORRUPTED_USES = chasni_getitemconfig("chasni_birdwhistle", "USES2") or 2
local function OnPlayed(inst, owner, bossprefab)
    if owner then
        local pt = owner:GetPosition()
        local spawn_pt = chasni_getspawnpoint(pt, SPAWN_DIST)
        if spawn_pt then
            local boss = SpawnPrefab(bossprefab)
            if boss then
                if boss.Physics then
                    boss.Physics:Teleport(spawn_pt:Get())
                elseif boss.Transform then
                    boss.Transform:SetPosition(spawn_pt:Get())
                end
                boss:FacePoint(pt:Get())
                if boss.components.combat then
                    boss.components.combat:SetTarget(owner)
                end
            end
        end
    end
end

local function getMiniBoss()
    local _monsprefab = (TheWorld.state.isspring and weighted_random_choice(chasni_boss_prefab_spring)) or
            (TheWorld.state.iswinter and weighted_random_choice(chasni_boss_prefab_winter)) or
            (TheWorld.state.issummer and weighted_random_choice(chasni_boss_prefab_summer)) or
            (TheWorld.state.isautumn and weighted_random_choice(chasni_boss_prefab_autumn)) or
            weighted_random_choice(chasni_boss_prefab_default)
    if _monsprefab == "none" then
        _monsprefab = weighted_random_choice(chasni_boss_prefab_default)
    end
    return _monsprefab
end

local function OnPlayedNormal(inst, owner) OnPlayed(inst, owner, getMiniBoss()) end
local function OnPlayedCorrupted(inst, owner)
    local pos = Vector3(owner.Transform:GetWorldPosition())
    local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, 15)
    local foundklaus_sack = false
    if #ents > 0 then
        for _, ent in ipairs(ents) do
            if ent.prefab == "klaus_sack" then
                local x, y, z = ent.Transform:GetWorldPosition()
                chasni_spawnprefab("explode_reskin", x, y, z)
                chasni_spawnprefab("chasni_klaus_sack", x, y, z)
                ent:Remove()
                foundklaus_sack = true
            end
        end
    end
    if not foundklaus_sack and owner then
        owner:DoTaskInTime(1.5, function()
            OnPlayed(inst, owner, "chasni_ancientherald")
        end)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddNetwork()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("antler")
    inst.AnimState:SetBuild("antler")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("tool")
    inst:AddTag("horn")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst:AddComponent("instrument")
    inst.components.instrument.range = 0
    inst.components.instrument.override_sound = "DLChasni/DLChasni/chasni_rocflute/play"

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.PLAY)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.PLAY, 1)

    MakeHauntableLaunch(inst)

    return inst
end

local function NormalFn()
    local inst = fn()
    inst.AnimState:SetBuild("antler")
    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.instrument:SetOnPlayedFn(OnPlayedNormal)
    inst.components.inventoryitem.imagename = "birdwhistle"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/birdwhistle.xml"
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(USES)

    inst.hornsymbol = "swap_antler"
    inst.hornbuild = "swap_antler"

    return inst
end

local function CorruptedFn()
    local inst = fn()
    inst.AnimState:SetBuild("antler_corrupted")
    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.instrument:SetOnPlayedFn(OnPlayedCorrupted)
    inst.components.inventoryitem.imagename = "birdwhistlecorrupted"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/birdwhistlecorrupted.xml"
    inst.components.finiteuses:SetMaxUses(CORRUPTED_USES)
    inst.components.finiteuses:SetUses(CORRUPTED_USES)

    inst.hornbuild = "swap_antler_corrupted"
    inst.hornsymbol = "swap_antler_corrupted"

    return inst
end

return
Prefab("chasni_birdwhistle",          NormalFn,    assets.normal,    prefabs.normal),
Prefab("chasni_birdwhistlecorrupted", CorruptedFn, assets.corrupted, prefabs.corrupted)
