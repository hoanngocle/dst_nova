local assets =
{
    Asset("ANIM", "anim/accomplishment_shrine.zip"),
    Asset("ATLAS", "images/inventoryimages/accomplishrine.xml"),
}

local prefabs =
{
    "collapse_small",
}

local COOLDOWN = TUNING.TOTAL_DAY_TIME * (chasni_getitemconfig("accomplishrine", "CD") or 10)
local DURATION = TUNING.TOTAL_DAY_TIME * (chasni_getitemconfig("accomplishrine", "DUR") or 1)
local function onhammered(inst, worker)
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal", nil, 0.3)
    inst:Remove()
end

local function onhit(inst)
    inst.AnimState:PlayAnimation("hit")
    if inst.components.timer:TimerExists("cooldown") then
        inst.AnimState:PushAnimation("active", true)
    else
        inst.AnimState:PushAnimation("idle", true)
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", true)
end

local function OnLoad(inst, data)
    if inst.components.timer:TimerExists("cooldown") then
        inst:AddTag("fueldepleted")
        inst.AnimState:PushAnimation("active", true)
    end
end

local function OnTimerDone(inst, data)
    if data.name == "cooldown" then
        inst.components.machine:TurnOff()
        inst.SoundEmitter:PlaySound("dontstarve/common/shrine/shrine_final")
        inst.AnimState:PushAnimation("idle", true)
        inst:RemoveTag("fueldepleted")
    end
end

local function TurnOn(inst)
    if inst.components.timer:TimerExists("cooldown") then
        return
    end
    local pos = inst:GetPosition()
    local nearby_player = FindClosestPlayerInRange(pos.x, pos.y, pos.z, 5, true)
    if nearby_player and nearby_player.components.allachivevent and nearby_player.components.timer then
        nearby_player.components.talker:Say(GetString(nearby_player, "ACCOMPLISHRINESUCCESS"))
        nearby_player.components.timer:StopTimer("accomplishrinebuff")
        nearby_player.components.timer:StartTimer("accomplishrinebuff", DURATION)

        inst.SoundEmitter:PlaySound("dontstarve/common/shrine/shrine_click")
        inst.AnimState:PushAnimation("active", true)
        inst.components.timer:StartTimer("cooldown", COOLDOWN)
        inst:AddTag("fueldepleted")
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("accomplishment_shrine")
    inst.AnimState:SetBuild("accomplishment_shrine")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("structure")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("machine")
    inst.components.machine.turnonfn = TurnOn

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")
    inst:AddComponent("timer")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:ListenForEvent("onbuilt", onbuilt)
    inst:ListenForEvent("timerdone", OnTimerDone)
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("accomplishrine", fn, assets, prefabs),
MakePlacer("accomplishrine_placer", "accomplishment_shrine", "accomplishment_shrine", "idle")
