local BALLOONS = require "prefabs/balloons_common"
require "functions/helperfunctions"

local assets =
{
    Asset("ANIM", "anim/balloon.zip"),
    Asset("ANIM", "anim/balloon_shapes.zip"),
    Asset("ANIM", "anim/balloon2.zip"),
    Asset("ANIM", "anim/balloon_shapes2.zip"),
    Asset("SCRIPT", "scripts/prefabs/balloons_common.lua"),

    Asset("ATLAS", "images/inventoryimages/balloon_beefalo.xml"),
    Asset("IMAGE", "images/inventoryimages/balloon_beefalo.tex"),
    Asset("ATLAS", "images/inventoryimages/balloon_bunnyman.xml"),
    Asset("IMAGE", "images/inventoryimages/balloon_bunnyman.tex"),
    Asset("ATLAS", "images/inventoryimages/balloon_butterfly.xml"),
    Asset("IMAGE", "images/inventoryimages/balloon_butterfly.tex"),
    Asset("ATLAS", "images/inventoryimages/balloon_hound.xml"),
    Asset("IMAGE", "images/inventoryimages/balloon_hound.tex"),
    Asset("ATLAS", "images/inventoryimages/balloon_merm.xml"),
    Asset("IMAGE", "images/inventoryimages/balloon_merm.tex"),
    Asset("ATLAS", "images/inventoryimages/balloon_pig.xml"),
    Asset("IMAGE", "images/inventoryimages/balloon_pig.tex"),
    Asset("ATLAS", "images/inventoryimages/balloon_tentacle.xml"),
    Asset("IMAGE", "images/inventoryimages/balloon_tentacle.tex"),
    Asset("ATLAS", "images/inventoryimages/balloon_spider.xml"),
    Asset("IMAGE", "images/inventoryimages/balloon_spider.tex"),
}

local NUM_BALLOON_SHAPES = 9
for i = 1, NUM_BALLOON_SHAPES do
    table.insert(assets, Asset("INV_IMAGE", "balloon_"..tostring(i)))
end

local prefabs =
{
    "balloon_held_child",
}

local balloon_defs =
{
    {
        name = "balloon_beefalo",
        balloon_num = 2,
        remove_fn = function(inst)
            local pt = inst:GetPosition()
            local pos = {}
            local theta = math.random() * 2 * PI
            local radius = math.random(0, 5)
            local result_offset = FindValidPositionByFan(theta, radius, 8, function(offset)
                local pos = pt + offset
                return #TheSim:FindEntities(pos.x, 0, pos.z, 1, nil, { "INLIMBO", "FX" }) <= 0 and TheWorld.Map:IsPassableAtPoint(pos:Get()) and TheWorld.Map:IsDeployPointClear(pos, nil, 1)
            end)

            if result_offset == nil then return end

            pos =  {x = pt.x + result_offset.x, z = pt.z + result_offset.z}
            chasni_spawnprefab("pillowfight_confetti_fx", pos.x, 0, pos.z)

            if math.random() < 0.01 then
                local beef = SpawnPrefab("beefalo")
                beef.components.domesticatable:DeltaDomestication(1) 
                beef.components.domesticatable:DeltaObedience(1) 
                beef.components.domesticatable:DeltaTendency('RIDER', 1)
                beef:SetTendency()
                beef.components.domesticatable:BecomeDomesticated()
                beef.components.hunger:SetPercent(1)
                beef.components.rideable:SetSaddle(nil, SpawnPrefab("saddle_race"))
                beef.Transform:SetPosition(pos.x, 0, pos.z)
            else
                chasni_spawnprefab("babybeefalo", pos.x, 0, pos.z)
            end
        end,
    },
    {
        name = "balloon_bunnyman",
        balloon_num = 9,
        remove_fn = function(inst)
            if #AllPlayers <= 0 then
                return
            end
            local player = AllPlayers[math.random(#AllPlayers)]
            local pt = player:GetPosition()
            local bunnycount = 1
            local num_fails = 0
            local positions = {}
            for k = 1, bunnycount do
                local theta = math.random() * 2 * PI
                local radius = math.random(1, 5)
                local result_offset = FindValidPositionByFan(theta, radius, 8, function(offset)
                    local pos = pt + offset
                    return #TheSim:FindEntities(pos.x, 0, pos.z, 1, nil, { "INLIMBO", "FX" }) <= 0 and TheWorld.Map:IsPassableAtPoint(pos:Get()) and TheWorld.Map:IsDeployPointClear(pos, nil, 1)
                end)
                if result_offset then table.insert(positions, {x = pt.x + result_offset.x, z = pt.z + result_offset.z}) else num_fails = num_fails + 1 end
            end

            if num_fails >= bunnycount then return end

            player:StartThread(function()
                for i, pos in ipairs(positions) do
                    chasni_spawnprefab("pillowfight_confetti_fx", pos.x, 0, pos.z)
                    local bunnyman = chasni_spawnprefab("bunnyman", pos.x, 0, pos.z)

                    if bunnyman.AnimState and bunnyman.Transform and bunnyman.components.follower and not player:HasTag("playerghost") then
                        if bunnyman.components.combat and bunnyman.components.combat:TargetIs(player) then
                            bunnyman.components.combat:SetTarget(nil)
                        end
                        if player.components.leader then
                            player:PushEvent("makefriend")
                            player.components.leader:AddFollower(bunnyman)
                            bunnyman.components.follower:AddLoyaltyTime(1440)
                            bunnyman.components.follower.maxfollowtime = 1440
                        end
                    end
                    Sleep(0.33)
                end
            end)
        end,
    },
    {
        name = "balloon_butterfly",
        balloon_num = 5,
        remove_fn = function(inst)
            if #AllPlayers <= 0 then
                return
            end
            local player = AllPlayers[math.random(#AllPlayers)]
            local pt = player:GetPosition()
            local spawncount = 3
            local num_fails = 0
            local positions = {}
            for k = 1, spawncount do
                local theta = math.random() * 2 * PI
                local radius = math.random(1, 4)
                local result_offset = FindValidPositionByFan(theta, radius, 6, function(offset)
                    local pos = pt + offset
                    return #TheSim:FindEntities(pos.x, 0, pos.z, 1, nil, { "INLIMBO", "FX" }) <= 0 and TheWorld.Map:IsPassableAtPoint(pos:Get()) and TheWorld.Map:IsDeployPointClear(pos, nil, 1)
                end)
                if result_offset then table.insert(positions, {x = pt.x + result_offset.x, z = pt.z + result_offset.z}) else num_fails = num_fails + 1 end
            end

            if num_fails >= spawncount then return end

            player:StartThread(function()
                for i, pos in ipairs(positions) do
                    chasni_spawnprefab("pillowfight_confetti_fx", pos.x, 0, pos.z)
                    chasni_spawnprefab("flower", pos.x, 0, pos.z)
                    chasni_spawnprefab("butterfly", pos.x, 0, pos.z)
                    Sleep(0.33)
                end
            end)
        end,
    },
    {
        name = "balloon_hound",
        balloon_num = 6,
        remove_fn = function(inst)
            if #AllPlayers <= 0 then
                return
            end
            local player = AllPlayers[math.random(#AllPlayers)]
            local pt = player:GetPosition()
            local pos = {}
            local theta = math.random() * 2 * PI
            local radius = math.random(1, 5)
            local result_offset = FindValidPositionByFan(theta, radius, 8, function(offset)
                local pos = pt + offset
                return #TheSim:FindEntities(pos.x, 0, pos.z, 1, nil, { "INLIMBO", "FX" }) <= 0 and TheWorld.Map:IsPassableAtPoint(pos:Get()) and TheWorld.Map:IsDeployPointClear(pos, nil, 1)
            end)

            if result_offset == nil then return end

            pos =  {x = pt.x + result_offset.x, z = pt.z + result_offset.z}
            chasni_spawnprefab("pillowfight_confetti_fx", pos.x, 0, pos.z)
            chasni_spawnprefab("warg", pos.x, 0, pos.z)
        end,
    },
    {
        name = "balloon_merm",
        balloon_num = 7,
        add_fn = function(inst)
            inst.components.equippable.dapperness = -TUNING.DAPPERNESS_SUPERHUGE
            inst.components.equippable.flipdapperonmerms = true
        end,
    },
    {
        name = "balloon_pig",
        balloon_num = 3,
        add_fn = function(inst)
            inst:AddComponent("tradable")
            inst.components.tradable.goldvalue = 1
        end,
    },
    {
        name = "balloon_tentacle",
        balloon_num = 8,
        add_fn = function(inst)
            inst:AddComponent("weapon")
            inst.components.weapon:SetDamage(TUNING.SPIKE_DAMAGE)
        end,
    },
    {
        name = "balloon_spider",
        balloon_num = 4,
        add_fn = function(inst)
            local function OnEquip(inst, owner, from_ground)
                BALLOONS.OnEquip_Hand(inst, owner, from_ground)
                if owner then
                    owner._trigger = owner.components.locomotor.triggerscreep
                    owner.components.locomotor:SetTriggersCreep(false)
                end
            end
            local function OnUnequip(inst, owner, from_ground)
                BALLOONS.OnUnequip_Hand(inst, owner, from_ground)
                if owner and owner._trigger then
                    owner.components.locomotor:SetTriggersCreep(owner._trigger)
                    owner._trigger = nil
                end
            end

            inst:AddComponent("equippable")
            inst.components.equippable:SetOnEquip(OnEquip)
            inst.components.equippable:SetOnUnequip(OnUnequip)
        end,
    },
}

local function SetBalloonShape(inst, num)
    inst.balloon_num = num
    inst.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes2", "balloon_"..tostring(num))
    inst.components.inventoryitem:ChangeImageName("balloon_"..tostring(num))
end

local function onsave(inst, data)
    data.num = inst.balloon_num
    data.colour_idx = inst.colour_idx
end

local function onload(inst, data)
    if data then
        if data.num and inst.balloon_num ~= data.num then
            SetBalloonShape(inst, data.num)
        end
        if data.colour_idx then
            inst.colour_idx = BALLOONS.SetColour(inst, data.colour_idx)
        end
    end
end

local function MakeBalloon(def)
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
        inst.AnimState:PlayAnimation("idle", true)
        inst.AnimState:SetRayTestOnBB(true)

        inst.DynamicShadow:SetSize(1, .5)

        inst:AddTag("nopunch")
        inst:AddTag("cattoyairborne")
        inst:AddTag("balloon")
        inst:AddTag("noepicmusic")

        if def.name == "balloon_tentacle" then inst:AddTag("weapon") end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.balloon_build = "balloon_shapes2"

        BALLOONS.MakeBalloonMasterInit(inst, BALLOONS.DoPop_Floating)

        inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

        SetBalloonShape(inst, def.balloon_num)

        BALLOONS.SetRopeShape(inst)

        inst.colour_idx = BALLOONS.SetColour(inst)

        if def.name ~= "balloon_spider" then
            inst:AddComponent("equippable")
            inst.components.equippable:SetOnEquip(BALLOONS.OnEquip_Hand)
            inst.components.equippable:SetOnUnequip(BALLOONS.OnUnequip_Hand)
        end

        if def.add_fn then
            def.add_fn(inst)
        end
        if def.remove_fn then
            inst.OnRemoveEntity = def.remove_fn
            inst.components.inventoryitem.canbepickedup = false
        end

        inst.OnSave = onsave
        inst.OnLoad = onload

        return inst
    end

    return Prefab(def.name, fn, assets, prefabs)
end

local ret = { }
for i, v in ipairs(balloon_defs) do
    table.insert(ret, MakeBalloon(v))
end
balloon_defs = nil
return unpack(ret)