local assets =
{
    Asset("ANIM", "anim/dung_pile.zip"),
    Asset("IMAGE", "images/minimap/dung_pile.tex"),
    Asset("ATLAS", "images/minimap/dung_pile.xml"),
}

local prefabs =
{
    --"dungbeetle",
    --"dungball",
    "cutgrass",
    "flint",
    "twigs",
    "boneshard",
    "rocks",
    "poop",
    "collapse_small",
}

local loots =
{
    {"poop",        1.00},
    {"rocks",       1.00},
    {"cutgrass",    0.05},
    {"boneshard",   0.2},
    {"flint",       0.05},
    {"twigs",       0.05},
}

local SPAWNER_REGENTIME = 10
local SPAWNER_RELEASETIME = 1
local SPAWNER_MAXCHILD = 5
local SANITY_COST = 50
local function animname(inst, late)
    local cycles_left = late and inst.components.pickable.cycles_left + 1 or inst.components.pickable.cycles_left
    return cycles_left == 3 and "_full" or cycles_left == 2 and "_med" or cycles_left == 1 and "_low" or "_dead"
end

local function spawndungball(inst)
    --local ball = SpawnPrefab("dungball")
    --ball.Transform:SetPosition(inst.Transform:GetWorldPosition())
    --ball.AnimState:PlayAnimation("idle" .. animname(inst))
end

local function ondug(inst, worker)
    inst.SoundEmitter:PlaySound("dontstarve/common/food_rot")
    if worker:HasTag("dungbeetle") then
        spawndungball(inst)
    else
        local pt = Point(inst.Transform:GetWorldPosition())
        inst.AnimState:PlayAnimation("dig" .. animname(inst), false)
        for _ = 1, inst.components.pickable.cycles_left do
            inst.components.pickable.cycles_left = inst.components.pickable.cycles_left - 1
            inst.components.lootdropper:DropLoot(pt, inst.components.lootdropper:GenerateLoot())
            inst.AnimState:PushAnimation("dig" .. animname(inst), false)
        end
    end
    inst.components.workable.workleft = 0
    inst.SoundEmitter:PlaySound("dontstarve/common/food_rot")
end

local function OnEntityWake(inst)
    if inst.components.childspawner then
        inst.components.childspawner:StartSpawning()
    end
end

local function onpickedfn(inst, picker)
    inst.SoundEmitter:PlaySound("dontstarve/common/food_rot")
    local pt = Point(inst.Transform:GetWorldPosition())
    inst.components.lootdropper:DropLoot(pt, inst.components.lootdropper:GenerateLoot())

    if not inst.playing_dead_anim then
        inst.AnimState:PlayAnimation("dig" .. animname(inst, true), false)
    end
    if picker and picker.components.sanity then
        if picker:HasTag("plantkin") then
            picker.components.sanity:DoDelta(SANITY_COST)
        else
            picker.components.sanity:DoDelta(-SANITY_COST)
        end
    end
end

local function destroy(inst)
    local time_to_erode = 1
    local tick_time = TheSim:GetTickTime()

    if inst.DynamicShadow then
        inst.DynamicShadow:Enable(false)
    end

    inst:StartThread(function()
        local ticks = 0
        while ticks * tick_time < time_to_erode do
            local erode_amount = ticks * tick_time / time_to_erode
            inst.AnimState:SetErosionParams(erode_amount, 0.1, 1.0)
            ticks = ticks + 1
            Yield()
        end

        local quote = TheWorld.components.dungpileregistry and TheWorld.components.dungpileregistry:Count() > 0 and STRINGS.CHASNI_DUNGPILE.DESTORY.NOTDONE1 .. TheWorld.components.dungpileregistry:Count() - 1 .. STRINGS.CHASNI_DUNGPILE.DESTORY.NOTDONE2 or STRINGS.CHASNI_DUNGPILE.DESTORY.DONE
        TheNet:Announce(quote)
        inst:Remove()
    end)
end

local function getregentimefn(inst)
    return 0
end

local function onload(inst, data)
    inst.AnimState:PlayAnimation("idle" .. animname(inst))
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()

    inst.AnimState:SetBank("dung_pile")
    inst.AnimState:SetBuild("dung_pile")
    inst.AnimState:PlayAnimation("fall")

    inst.MiniMapEntity:SetPriority(5)
    inst.MiniMapEntity:SetIcon("dung_pile.tex")

    inst:AddTag("dungpile")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(ondug)

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"
    inst.components.pickable.getregentimefn = getregentimefn
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.max_cycles = 3
    inst.components.pickable.cycles_left = inst.components.pickable.max_cycles
    inst.components.pickable:SetUp(nil,0)
    inst.components.pickable.transplanted = true

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "chasni_blackfly"
    inst.components.childspawner:SetRegenPeriod(SPAWNER_REGENTIME)
    inst.components.childspawner:SetSpawnPeriod(SPAWNER_RELEASETIME)
    inst.components.childspawner.spawnvariance = 0
    inst.components.childspawner:SetMaxChildren(SPAWNER_MAXCHILD)
    --inst.components.childspawner:SetRareChild("dungbeetle", 0.01)

    inst:AddComponent("lootdropper")
    for i, v in pairs(loots) do
        inst.components.lootdropper:AddRandomLoot(v[1], v[2])
    end
    inst.components.lootdropper.numrandomloot = 1
    inst.components.lootdropper.speed = 2
    inst.components.lootdropper.alwaysinfront = true

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = function(inst, viewer)
        if not inst:HasTag("dungpile") then
            return "PICKED"
        end
    end

    inst:ListenForEvent("animover", function(inst, data)
        if inst.AnimState:IsCurrentAnimation("dig_low") then
            destroy(inst)
        end
    end)

    MakeSnowCovered(inst)
    MakeSmallPropagator(inst)

    inst.flies = inst:SpawnChild("flies")
    inst.OnEntityWake = OnEntityWake
    inst.OnLoad = onload

    if TheWorld.components.dungpileregistry == nil then
        TheWorld:AddComponent("dungpileregistry")
    end
    TheWorld.components.dungpileregistry:Register(inst)

    return inst
end

return Prefab("chasni_dungpile", fn, assets, prefabs)
