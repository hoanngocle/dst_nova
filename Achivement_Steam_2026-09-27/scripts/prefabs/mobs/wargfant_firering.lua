local assets =
{ 
    Asset("ANIM", "anim/fire.zip")
}

local prefabs =
{
    "wargfant_fire"
}

local DURATION = 30
local function OnSave(inst, data)
    data.duration = inst.duration or 0.1
    data.level = inst.level or 1
end

local function OnPreLoad(inst, data)
    if data then
        inst.duration = data.duration or 0.1
        local scale = 1.5 * (inst.duration / DURATION)
        inst.Transform:SetScale(scale, scale, scale)
        inst.level = data.level or 1
    end
end

local function AoeDamage(inst)
    if inst.level <= 0 then end
    local strength = inst.duration / DURATION
    if strength > 0.1 then
        local radius = strength + inst.level * 0.5
        local x, _, z = inst.Transform:GetWorldPosition()
        local ents = FindPlayersInRange(x, 0, z, radius, true)
        for i, v in ipairs(ents) do
            if v.components.health then
                v.components.health:DoDelta(-0.02)
                v.components.health:DeltaPenalty(0.03)
            end
            if v.components.sanity then
                v.components.sanity:DoDelta(-3)
            end
            if v.components.locomotor then
                if v._wargfantslowedtask then
                    v._wargfantslowedtask:Cancel()
                    v._wargfantslowedtask = nil
                end
                v._wargfantslowedtask = v:DoTaskInTime(0.4, function()
                    v.components.locomotor:RemoveExternalSpeedMultiplier(v, "wargfant_fire")
                end)
                v.components.locomotor:SetExternalSpeedMultiplier(v, "wargfant_fire", 0.15)
            end
            if v.AnimState then
                if v.blackedtask then
                    v.blackedtask:Cancel()
                    v.blackedtask = nil
                end
                v.blackedtask = v:DoTaskInTime(0.35, function()
                    v.AnimState:SetMultColour(1, 1, 1, 1)
                end)
                v.AnimState:SetMultColour(0, 0, 0, 1)
            end
        end
    end
end

local function UpdateFires(inst)
    inst.duration = inst.duration - 1

    if inst.task == nil then
        inst.task = true
        inst.components.sizetweener:StartTween(0.01, inst.duration)
    end

    if inst.duration <= 0 then
        inst:Remove()
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("fire")
    inst.AnimState:SetBank("fire")
    inst.AnimState:PlayAnimation("level3", true)
    inst.AnimState:SetMultColour(0, 0, 0, 1)

    inst:AddTag("NOCLICK")
    inst:AddTag("notraptrigger")
    inst:AddTag("FX")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.duration = DURATION
    inst.level = 3

    inst.OnSave = OnSave
    inst.OnPreLoad = OnPreLoad

    inst:DoPeriodicTask(1, UpdateFires)
    inst:DoPeriodicTask(0.5, AoeDamage)

    inst:AddComponent("sizetweener")

    return inst
end

local function fnring()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("notraptrigger")
    inst:AddTag("FX")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.SpawnFireRing = function(inst)
        for i = 1, 72 do
            local x, y, z = inst.Transform:GetWorldPosition()
            local theta = (inst.Transform:GetRotation() + (i *5))* DEGREES
            local xoffs = 14 * math.sin(theta)
            local zoffs = 14 * math.cos(theta)
            x = x + xoffs
            z = z + zoffs
            chasni_spawnprefab("wargfant_fire", x, y, z)
        end
        inst:Remove()
    end
    inst.OnLoad = inst.Remove

    return inst
end

return Prefab("wargfant_fire", fn, assets),
Prefab("wargfant_firering", fnring, {}, prefabs)
