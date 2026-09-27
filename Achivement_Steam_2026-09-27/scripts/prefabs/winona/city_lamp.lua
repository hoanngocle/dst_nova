local assets =
{
    Asset("ANIM", "anim/lamp_post2.zip"),
    Asset("ANIM", "anim/lamp_post2_city_build.zip"),
    Asset("ANIM", "anim/lamp_post2_yotp_build.zip"),
    Asset("INV_IMAGE", "city_lamp"),
    Asset("ATLAS", "images/prefabs/city_lamp.xml"),
}

local INTENSITY = .75
local RADIUS = 13
local FUEL_MAX = TUNING.TOTAL_DAY_TIME * 5
local FUEL_RATE = 1

local function updatelight(inst)
    if not TheWorld.state.isday and not inst.components.fueled:IsEmpty() then
        inst.components.fueled:StartConsuming()

        local fueled = inst.components.fueled
        local fuel_pct = fueled.currentfuel / fueled.maxfuel
        inst.Light:SetIntensity(INTENSITY * fuel_pct)
        inst.Light:SetRadius(RADIUS * fuel_pct)
        inst.Light:Enable(true)

        inst.AnimState:Show("FIRE")
        inst.AnimState:Show("GLOW")
        inst.lighton = true
    else
        inst.components.fueled:StopConsuming()
        inst.Light:Enable(false)
        inst.Light:SetIntensity(0)

        inst.AnimState:Hide("FIRE")
        inst.AnimState:Hide("GLOW")
        inst.lighton = false
    end
end

local function onfuelupdate(newsection, oldsection, inst)
    updatelight(inst)
end

local function updatefuelrate()
    for _, player in ipairs(AllPlayers) do
        if player and player.components.allachivcoin and player.components.allachivcoin.expertwinona1 then
            return 0
        end
    end
    return FUEL_RATE
end

local function onupdatefueled(inst)
    if inst.components.fueled ~= nil then
        inst.components.fueled.rate = updatefuelrate()
    end
end

local function onhammered(inst, worker)
    inst.SoundEmitter:KillSound("onsound")
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal")

    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())

    inst:Remove()
end

local function onhit(inst, worker)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", true)
    inst:DoTaskInTime(0.3, function() updatelight(inst) end)
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", true)
    inst:DoTaskInTime(0, function() updatelight(inst) end)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddSoundEmitter()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.25)

    inst.entity:AddLight()
    inst.Light:SetColour(180 / 255, 195 / 255, 150 / 255)
    inst.Light:SetFalloff(.75)
    inst.Light:SetRadius(RADIUS)
    inst.Light:SetIntensity(INTENSITY)
    inst.Light:Enable(false)

    inst.AnimState:SetBank("lamp_post")
    inst.AnimState:SetBuild("lamp_post2_city_build")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:Hide("FIRE")
    inst.AnimState:Hide("GLOW")

    inst:AddTag("chasni_city_lamp")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = FUEL_MAX
    inst.components.fueled.rate = 1
    inst.components.fueled:SetSections(4)
    inst.components.fueled:SetTakeFuelFn(updatelight)
    inst.components.fueled:SetUpdateFn(onupdatefueled)
    inst.components.fueled:SetSectionCallback(onfuelupdate)
    inst.components.fueled:InitializeFuelLevel(FUEL_MAX)

    local _updatelight = function() updatelight(inst) end
    inst:WatchWorldState("phase", _updatelight)

    inst:ListenForEvent("onbuilt", onbuilt)

    return inst
end

return Prefab("chasni_city_lamp", fn, assets),
MakePlacer("chasni_city_lamp_placer", "lamp_post", "lamp_post2_city_build", "idle")
