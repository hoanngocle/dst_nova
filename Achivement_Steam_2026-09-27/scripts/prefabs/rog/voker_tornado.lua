local assets =
{
    Asset("ANIM", "anim/chasni_tornado_weather.zip"),
}

local DURATION = chasni_getitemconfig("book_voker", "TD_DUR") or 5
local VACUUM_EXCLUDE = { "FX", "INLIMBO", "notarget", "noattack", "invisible", "injoker" }
local function Vacuuming(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 4.5, nil, VACUUM_EXCLUDE)
    for _, v in ipairs(ents) do
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

local function Moving(inst)
    if inst.velx and inst.velz then
        local x, _, z = inst.Transform:GetWorldPosition()
        inst.Transform:SetPosition(x + (inst.velx * 0.5), 0, z + (inst.velz * 0.5))
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("chasni_tornado_weather")
    inst.AnimState:SetBuild("chasni_tornado_weather")
    inst.AnimState:PlayAnimation("tornado_loop", true)

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("remove", DURATION)
    inst:ListenForEvent("timerdone", function()
        inst.AnimState:PlayAnimation("tornado_pst")
        inst:ListenForEvent("animover", inst.Remove)
    end)

    inst:DoPeriodicTask(FRAMES, Vacuuming)
    inst:DoPeriodicTask(FRAMES, Moving)

    inst.velx = nil
    inst.velz = nil
    inst.persists = false

    return inst
    end

return Prefab("voker_tornado", fn, assets)
