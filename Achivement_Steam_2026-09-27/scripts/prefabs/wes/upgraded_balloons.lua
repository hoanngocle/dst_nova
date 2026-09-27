local BALLOONS = require "prefabs/balloons_common"
local easing = require "easing"

local RED_CHANCE = chasni_getitemconfig("balloon", "RED") or 0.5
local PURPLE_CHANCE = chasni_getitemconfig("balloon", "PURPLE") or 0.5
local BLUE_CHANCE = chasni_getitemconfig("balloon", "BLUE") or 0.5
local YELLOW_CHANCE = chasni_getitemconfig("balloon", "YELLOW") or 0.5
local GREEN_CHANCE = chasni_getitemconfig("balloon", "GREEN") or 0.5
local function onpop(inst)
    inst:DoTaskInTime(FRAMES * 5, function()
        local fx = SpawnPrefab("pillowfight_confetti_fx")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end)

    BALLOONS.DoPop_Floating(inst)
end

------------------------------------------------------------------------
-- RED
------------------------------------------------------------------------
local function SpawnMeteor(target)
    local x, y, z = target.Transform:GetWorldPosition()
    local theta = math.random() * 2 * PI
    local radius = easing.outSine(math.random(), math.random() * 7, 2, 1)

    local map = TheWorld.Map
    local fan_offset = FindValidPositionByFan(theta, radius, 10, function(offset) return map:IsPassableAtPoint(x + offset.x, y + offset.y, z + offset.z) end)
    if fan_offset then
        local met = SpawnPrefab("shadowmeteor")
        met.Transform:SetPosition(x + fan_offset.x, y + fan_offset.y, z + fan_offset.z)
        met:SetSize("large", 1)
    end
end

local function onpopred(inst)
    onpop(inst)
    inst:DoTaskInTime(FRAMES * 5, function()
        if math.random() < RED_CHANCE then
            local x, y, z = inst.Transform:GetWorldPosition()
            local range = 15
            local rocks = TheSim:FindEntities(x, y, z, range)
            for _, v in ipairs(rocks) do
                if v.components.workable and v.components.workable.action == ACTIONS.MINE then
                    v.components.workable:WorkedBy(inst, v.components.workable.workleft)
                end
            end
        else
            for _, v in ipairs(AllPlayers) do
                SpawnMeteor(v)
                SpawnMeteor(v)
                SpawnMeteor(v)
                SpawnMeteor(v)
                SpawnMeteor(v)
            end
        end
    end)
end

------------------------------------------------------------------------
-- PURPLE
------------------------------------------------------------------------
local function CanTransformIntoLeifTest(target)
    return (target:HasTag("evergreens") and not target.noleif and target.components.growable and target.components.growable.stage <= 3)
            or (target:HasTag("birchnut") and target.leaf_state ~= "barren" and not target.monster and target.monster_start_task == nil and target.monster_stop_task == nil and target.domonsterstop_task == nil)
end

local function DelayedStartMonster(inst)
    inst.monster_start_task = nil
    inst:StartMonster()
end

local function WakeUpLeif(ent)
    ent.components.sleeper:WakeUp()
end

local function WakeUpNearbyLeifs(x, y, z, doer)
    local ents = TheSim:FindEntities(x, y, z, 10, { "leif" })
    for _, v in ipairs(ents) do
        if v.components.sleeper and v.components.sleeper:IsAsleep() then
            v:DoTaskInTime(math.random(), WakeUpLeif)
        end
        if doer then
            v.components.combat:SuggestTarget(doer)
        end
    end
end

local function SpawnNewLeifs(x, y, z, doer)
    local ents = TheSim:FindEntities(x, y, z, 10, { "tree" }, { "leif", "fire", "stump", "burnt", "monster", "FX", "NOCLICK", "DECOR", "INLIMBO" }, { "evergreens", "birchnut" })
    for _, v in ipairs(ents) do
        if CanTransformIntoLeifTest(v) then
            if v.TransformIntoLeif then
                v:TransformIntoLeif(doer)
            elseif v.StartMonster then
                v.monster_start_task = v:DoTaskInTime(math.random(1, 2), DelayedStartMonster)
            end
        end
    end
end

local function onpoppurple(inst)
    onpop(inst)
    inst:DoTaskInTime(FRAMES * 5, function()
        if math.random() < PURPLE_CHANCE then
            local x, y, z = inst.Transform:GetWorldPosition()
            local range = 15
            local trees = TheSim:FindEntities(x, y, z, range, {"tree"}, nil, nil)
            for _, v in ipairs(trees) do
                if v.components.workable and v.components.workable.action == ACTIONS.CHOP then
                    v.components.workable:WorkedBy(inst, v.components.workable.workleft)
                end
            end
            local stump = TheSim:FindEntities(x, y, z, range, {"stump"})
            for _, v in ipairs(stump) do
                if v.components.workable and v.components.workable.action == ACTIONS.DIG then
                    v.components.workable:WorkedBy(inst, v.components.workable.workleft)
                end
            end
        else
            for _, v in ipairs(AllPlayers) do
                local x, y, z = v.Transform:GetWorldPosition()
                WakeUpNearbyLeifs(x, y, z, v)
                SpawnNewLeifs(x, y, z, v)
            end
        end
    end)
end
------------------------------------------------------------------------
-- BLUE
------------------------------------------------------------------------
local function onpopblue(inst)
    onpop(inst)
    inst:DoTaskInTime(FRAMES * 5, function()
        if math.random() < BLUE_CHANCE then
            local x, y, z = inst.Transform:GetWorldPosition()
            local range = 15
            local ents = TheSim:FindEntities(x, y, z, range, { "freezable" }, { "FX", "NOCLICK", "DECOR", "INLIMBO", "player" })
            for _, v in pairs(ents) do
                if v.components.freezable then
                    v.components.freezable:AddColdness(5)
                end
            end
        else
            for _, v in ipairs(AllPlayers) do
                if v.components.freezable then
                    v.components.freezable:AddColdness(10, 10)
                end
            end
        end
    end)
end
------------------------------------------------------------------------
-- YELLOW
------------------------------------------------------------------------
local function SpawnTallbird(player)
    local pt = player:GetPosition()
    local tallbirdcount = 3
    local num_fails = 0
    local positions = {}
    for k = 1, tallbirdcount do
        local theta = math.random() * 2 * PI
        local radius = math.random(1, 5)
        local result_offset = FindValidPositionByFan(theta, radius, 8, function(offset)
            local pos = pt + offset
            return #TheSim:FindEntities(pos.x, 0, pos.z, 1, nil, { "INLIMBO", "FX" }) <= 0 and TheWorld.Map:IsPassableAtPoint(pos:Get()) and TheWorld.Map:IsDeployPointClear(pos, nil, 1)
        end)
        if result_offset then table.insert(positions, {x = pt.x + result_offset.x, z = pt.z + result_offset.z}) else num_fails = num_fails + 1 end
    end

    if num_fails >= tallbirdcount then return end

    player:StartThread(function()
        for i, pos in ipairs(positions) do
            chasni_spawnprefab("pillowfight_confetti_fx", pos.x, 0, pos.z)
            local tallbird = chasni_spawnprefab("tallbird", pos.x, 0, pos.z)
            if tallbird.components.combat and not tallbird.components.combat:TargetIs(player) then
                tallbird.components.combat:SetTarget(player)
            end
            Sleep(0.33)
        end
    end)
end

local function onpopyellow(inst)
    onpop(inst)
    inst:DoTaskInTime(FRAMES * 5, function()
        if math.random() < YELLOW_CHANCE then
            local x, y, z = inst.Transform:GetWorldPosition()
            local range = 7
            local ents = TheSim:FindEntities(x, y, z, range)
            for _, v in pairs(ents) do
                if v.components.hatchable and not (v.components.inventoryitem and v.components.inventoryitem.owner) then
                    local hatchable = v.components.hatchable
                    if hatchable.state == "unhatched" then
                        hatchable.progress = hatchable.cracktime
                        hatchable:OnState("crack", true)
                    end
                    hatchable:OnState("comfy", true)
                    hatchable.progress = hatchable.hatchtime
                    hatchable:StopUpdating()
                    hatchable:OnState("hatch", true)
                end
            end
        else
            for _, v in ipairs(AllPlayers) do
                SpawnTallbird(v)
            end
        end
    end)
end
------------------------------------------------------------------------
-- GREEN
------------------------------------------------------------------------
local function onpopgreen(inst)
    onpop(inst)
    inst:DoTaskInTime(FRAMES * 5, function()
        if math.random() < GREEN_CHANCE then
            for _, player in ipairs(AllPlayers) do
                if not player:HasTag("playerghost") then
                    if player.components.health and player.components.sanity and player.components.hunger then
                        player.components.hunger:DoDelta(25)
                        player.components.sanity:DoDelta(25)
                        player.components.health:DoDelta(25)
                    end
                    for _,v in pairs(player.components.inventory.itemslots) do
                        if v and v.components.perishable then
                            v.components.perishable:AddTime(240)
                        end
                    end
                    for _,v in pairs(player.components.inventory.equipslots) do
                        if v and v.components.perishable then
                            v.components.perishable:AddTime(240)
                        end
                    end
                end
            end
        else
            for _, v in ipairs(AllPlayers) do
                local x, y, z = v.Transform:GetWorldPosition()
                chasni_spawnprefab("sporecloud", x, y, z)
                if v.components.pinnable then
                    v.components.pinnable:Stick()
                end
            end
        end
    end)
end

local function MakeBalloon(name, popfn)
    local assets =
    {
        Asset("ANIM", "anim/balloon.zip"),
        Asset("ANIM", "anim/balloon2.zip"),
        Asset("ANIM", "anim/"..name..".zip"),
        Asset("SCRIPT", "scripts/prefabs/balloons_common.lua"),
        Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
    }

    local prefabs =
    {
        "balloon_held_child",
        "balloonparty_confetti_cloud",
    }

    local function oncollide(inst, other)
        if (inst:IsValid() and Vector3(inst.Physics:GetVelocity()):LengthSq() > .1) or
                (other and other:IsValid() and other.Physics and Vector3(other.Physics:GetVelocity()):LengthSq() > .1) then
            inst.AnimState:PlayAnimation("hit")
            inst.AnimState:PushAnimation("idle", true)
        end
    end

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddNetwork()

        BALLOONS.MakeFloatingBallonPhysics(inst)

        inst.AnimState:SetBank("balloon2")
        inst.AnimState:SetBuild("balloon2")
        inst.AnimState:OverrideSymbol("swap_balloon", name, "balloon_1")
        inst.AnimState:PlayAnimation("idle", true)
        inst.AnimState:SetRayTestOnBB(true)

        inst.DynamicShadow:SetSize(1, .5)

        inst:AddTag("nopunch")
        inst:AddTag("cattoyairborne")
        inst:AddTag("balloon")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.balloon_build = name

        BALLOONS.MakeBalloonMasterInit(inst, popfn)

        inst.Physics:SetCollisionCallback(oncollide)

        inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

        BALLOONS.SetRopeShape(inst)

        inst:AddComponent("equippable")
        inst.components.equippable:SetOnEquip(BALLOONS.OnEquip_Hand)
        inst.components.equippable:SetOnUnequip(BALLOONS.OnUnequip_Hand)

        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"
        inst.components.inventoryitem.imagename = name

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

-------------------------------------------------------------------------------
return
MakeBalloon("balloon_chasni_red", onpopred),
MakeBalloon("balloon_chasni_yellow", onpopyellow),
MakeBalloon("balloon_chasni_blue", onpopblue),
MakeBalloon("balloon_chasni_purple", onpoppurple),
MakeBalloon("balloon_chasni_green", onpopgreen)