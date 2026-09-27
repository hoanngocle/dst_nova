local assets =
{
    Asset("ANIM", "anim/chasni_slash_ground.zip"),
}

local VACUUM_EXCLUDE = { "FX", "INLIMBO", "notarget", "noattack", "invisible" }
local function Vacuuming(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 4.5, nil, VACUUM_EXCLUDE)
    for _, v in ipairs(ents) do
        if inst.components.projectile and inst.components.projectile.hit_targets and inst.components.projectile.hit_targets[v] then
            local px, py, pz = v.Transform:GetWorldPosition()
            local rad = math.rad(v:GetAngleToPoint(x, y, z))
            local velx = math.cos(rad)
            local velz = -math.sin(rad)

            local m = math.clamp(inst:GetDistanceSqToPoint(px, py, pz) * inst.Transform:GetScale() / 50, 6, 30)
            local dx, dy, dz = px + (((FRAMES * 100) * velx) / m) * inst.Transform:GetScale(), py, pz + (((FRAMES * 100) * velz) / m) * inst.Transform:GetScale()

            local ground = TheWorld.Map:IsPassableAtPoint(dx, dy, dz)
            local boat = TheWorld.Map:GetPlatformAtPoint(dx, dz)
            local ocean = TheWorld.Map:IsOceanAtPoint(dx, dy, dz)
            if v and v.components.locomotor and dx and (ground or boat or ocean and v.components.locomotor:CanPathfindOnWater()) then
                v.Transform:SetPosition(dx, dy, dz)
            end
        end
    end
end

local function OnMiss(inst, owner, target)
    inst.AnimState:PlayAnimation("pst")
    inst:ListenForEvent("animover", inst.Remove)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("chasni_slash_ground")
    inst.AnimState:SetBuild("chasni_slash_ground")
    inst.AnimState:PlayAnimation("loop", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
    inst.AnimState:SetMultColour(1, 0.2, 1, 1)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst:AddTag("projectile")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(8)
    inst.components.projectile:SetRange(12)
    inst.components.projectile:SetHitDist(2)
    inst.components.projectile:SetOnMissFn(OnMiss)
    inst.components.projectile.has_damage_set = false

    inst:DoPeriodicTask(FRAMES, Vacuuming)

    inst.persists = false
    return inst
    end

return Prefab("chasni_critter_turtle_proj", fn, assets)
