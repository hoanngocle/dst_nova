require("stategraphs/commonstates")

-------------------------------------------------------------------------------

local function TriggerFX(inst) end

local DURATION = 15
local VACUUM_EXCLUDE = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "newklaus" }
local function Vacuuming(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 4.5, nil, VACUUM_EXCLUDE)
    for _, v in ipairs(ents) do
        local px, py, pz = v.Transform:GetWorldPosition()
        local rad = math.rad(v:GetAngleToPoint(x, y, z))
        local velx = math.cos(rad)
        local velz = -math.sin(rad)

        local m = math.clamp(inst:GetDistanceSqToPoint(px, py, pz) * inst.Transform:GetScale() / 50, 6, 30)
        local dx, dy, dz = px + (((FRAMES * 15) * velx) / m) * inst.Transform:GetScale(), py, pz + (((FRAMES * 15) * velz) / m) * inst.Transform:GetScale()

        local ground = TheWorld.Map:IsPassableAtPoint(dx, dy, dz)
        local boat = TheWorld.Map:GetPlatformAtPoint(dx, dz)
        local ocean = TheWorld.Map:IsOceanAtPoint(dx, dy, dz)
        if v and v.components.locomotor and dx and (ground or boat or ocean and v.components.locomotor:CanPathfindOnWater()) then
            v.Transform:SetPosition(dx, dy, dz)
        end
    end
end

-------------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("shadow_teleport")
    inst.AnimState:SetBuild("shadow_teleport")
    inst.AnimState:PlayAnimation("portal_in", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.Transform:SetScale(1.7, 1.7, 1.7)

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst:SetDeployExtraSpacing(4)
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("remove", DURATION)
    inst:ListenForEvent("timerdone", inst.Remove)

    inst:DoPeriodicTask(FRAMES, Vacuuming)

    inst.persists = false
    inst.killed = false
    inst.burstprefab = "sinkhole_spawn_fx_1"
    inst.fxprefabs = { "sinkhole_spawn_fx_2" }
    inst.TriggerFX = TriggerFX

    return inst
end

return Prefab("deer_purple_circle", fn)
