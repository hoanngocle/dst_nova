local assets =
{
    Asset("ANIM", "anim/fluffyhouse.zip"),
    Asset("ATLAS", "images/inventoryimages/fluffyhouse.xml"),
}

local prefabs =
{
    "collapse_small",
}

local RESPAWN_TIME = chasni_getmobconfig("chasni_fluffy", "CD") or 480
local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal", nil, 0.3)
    inst:Remove()
end

local function onhit(inst)
    local hitanim = "_inside"
    if inst.fluffystate == -1 then
        hitanim = "_dead"
    elseif inst.fluffystate == 0 then
        hitanim = "_outside"
    end

    inst.AnimState:PlayAnimation("hit" .. hitanim)
    inst.AnimState:PushAnimation("idle" .. hitanim, true)
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("spawn")
    inst.AnimState:PushAnimation("idle_inside", true)
    inst.components.machine:TurnOn()
    inst:AddTag("fueldepleted")
    inst:RemoveTag("fueldepleted")
    inst.fluffystate = 1
end

local function ReSpawnFluffy(inst)
    if inst then
        inst:DoTaskInTime(RESPAWN_TIME, function()
            inst.AnimState:PlayAnimation("fluffy_respawn")
            inst.AnimState:PushAnimation("idle_inside", true)
            inst.fluffystate = 1
        end)
        inst.RespawnTime = GetTime() + RESPAWN_TIME
    end
end

local function OnSave(inst, data)
    data.fluffystate = inst.fluffystate
    data.RespawnTime = nil

    if inst.RespawnTime then
        local time = GetTime()
        if inst.RespawnTime > time then
            data.RespawnTime = inst.RespawnTime - time
        end
    end
end

local function OnLoad(inst, data)
    if data then
        inst.fluffystate = data.fluffystate or -1
        if inst.fluffystate == 0 then
            inst:DoTaskInTime(0.1, function()
                inst.AnimState:PlayAnimation("fluffy_respawn")
                inst.AnimState:PushAnimation("idle_inside", true)
                inst.fluffystate = 1
            end)
            return
        end
        local spawntime = data.RespawnTime
        if spawntime then
            inst:DoTaskInTime(spawntime, function()
                inst.AnimState:PlayAnimation("fluffy_respawn")
                inst.AnimState:PushAnimation("idle_inside", true)
                inst.fluffystate = 1
            end)
        end
    end
    inst.RefreshLook(inst)
end

local function RefreshLook(inst)
    if inst.fluffystate == -1 then
        inst.AnimState:PlayAnimation("idle_dead", true)
    elseif inst.fluffystate == 0 then
        inst.AnimState:PlayAnimation("idle_outside", true)
    else
        inst.AnimState:PlayAnimation("idle_inside", true)
    end
end

local function TurnOff(inst)
    local pos = inst:GetPosition()
    local nearby_player = FindClosestPlayerInRange(pos.x, pos.y, pos.z, 5, true)
    if nearby_player == nil then
        return
    end

    if not (nearby_player.components.allachivcoin and nearby_player.components.allachivcoin.expertwebber2) then
        nearby_player.components.talker:Say(GetString(nearby_player, "SISTURN_TELE_FAIL"))
    elseif inst.fluffystate == -1 then
        nearby_player.components.talker:Say(GetString(nearby_player, "CALLFLUFFYFAIL1"))
    elseif inst.fluffystate == 0 then
        nearby_player.components.talker:Say(GetString(nearby_player, "CALLFLUFFYFAIL2"))
    elseif nearby_player.components.leader then
        local pt = Vector3(inst.Transform:GetWorldPosition())
        local fluffy = chasni_spawnprefab("chasni_fluffy", pt.x, pt.y, pt.z)
        fluffy.House = inst
        nearby_player.components.leader:AddFollower(fluffy)
        inst.fluffystate = 0
        inst.RefreshLook(inst)
    end

    inst:AddTag("fueldepleted")
    inst:DoTaskInTime(.1,function()
        inst.components.machine:TurnOn()
        inst:RemoveTag("fueldepleted")
    end)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("fluffyhouse")
    inst.AnimState:SetBuild("fluffyhouse")
    inst.AnimState:PlayAnimation("idle_inside", true)

    inst:AddTag("structure")
    inst:AddTag("fluffyhouse")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("machine")
    inst.components.machine.turnofffn = TurnOff
    inst.components.machine:TurnOn()

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:ListenForEvent("onbuilt", onbuilt)
    inst.OnLoad = OnLoad
    inst.OnSave = OnSave
    inst.RefreshLook = RefreshLook
    inst.ReSpawnFluffy = ReSpawnFluffy
    inst.RespawnTime = 0

    return inst
end

return Prefab("fluffyhouse", fn, assets, prefabs),
MakePlacer("fluffyhouse_placer", "fluffyhouse", "fluffyhouse", "idle_inside")
