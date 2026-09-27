local prefabs =
{
    "ice_splash",
    "groundlight_fx",
}

local DURATION = chasni_getitemconfig("book_voker", "IW_DUR") or 15
local RADIUS = 12
local SLOW = 0.25
local SLOWDOWN_MUST_TAGS = { "locomotor" }
local SLOWDOWN_CANT_TAGS = { "injoker", "flying", "playerghost", "INLIMBO" }
local function OnWorked(inst, worker)
    inst.components.lootdropper:DropLoot()
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/iceboulder_smash")
    local fx = SpawnPrefab("ice_splash")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx.AnimState:PlayAnimation("med")
    inst.iceaura:KillFX()
    inst:Remove()
end

local function ontimerdone(inst, data)
    if data.name == "gone" then
        OnWorked(inst)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

    inst.AnimState:SetBank("ice_boulder")
    inst.AnimState:SetBuild("ice_boulder")
    inst.AnimState:PlayAnimation("full", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("rock_ice_tall")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnWorked)

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)
    inst.components.timer:StartTimer("gone", DURATION)

    inst.persists = false
    inst.iceaura = SpawnPrefab("groundlight_fx")
    inst.iceaura.entity:SetParent(inst.entity)
    inst.iceaura.Transform:SetPosition(0,0,0)
    inst.iceaura.Transform:SetScale(1.5, 1.5, 1.5)
    inst.iceaura.AnimState:SetMultColour(0.7, 0.9, 1, 0.85)

    inst:DoPeriodicTask(0, function()
        local pt = Vector3(inst.Transform:GetWorldPosition())
        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, RADIUS, SLOWDOWN_MUST_TAGS, SLOWDOWN_CANT_TAGS)
        for i, v in ipairs(ents) do
            if v.components.locomotor and not chasni_friendpet(v, "injoker") then
                local slow = ((v:GetDistanceSqToPoint(pt.x, pt.y, pt.z)) / (RADIUS * RADIUS)) + SLOW
                v.components.locomotor:PushTempGroundSpeedMultiplier(math.clamp(slow, SLOW, 0.9), WORLD_TILES.MUD)
            end
        end
    end)
    return inst
end

return Prefab("voker_icewall", fn, {}, prefabs)
