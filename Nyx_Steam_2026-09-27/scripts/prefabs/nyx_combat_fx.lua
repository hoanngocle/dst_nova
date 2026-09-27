local Common = require "util/nyx_combat_common"
local SkillDamage = require "util/nyx_skill_damage"

local assets = {
    Asset("ANIM", "anim/eva_scythe.zip"),
    Asset("ANIM", "anim/lavaarena_shadow_lunge_fx.zip"),
}

local function AddFxTags(inst)
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
end

local function ConfigureScythe(inst, scale, alpha)
    inst.AnimState:SetBank("eva_scythe")
    inst.AnimState:SetBuild("eva_scythe")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetMultColour(0.72, 0.46, 1, alpha or 1)
    inst.AnimState:SetAddColour(0.18, 0.06, 0.3, 0)
    inst.AnimState:SetLightOverride(0.7)
    inst.Transform:SetScale(scale, scale, scale)
end

local function melee_wave_fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    AddFxTags(inst)
    inst.Transform:SetEightFaced()
    inst.AnimState:SetBank("lavaarena_shadow_lunge_fx")
    inst.AnimState:SetBuild("lavaarena_shadow_lunge_fx")
    inst.AnimState:PlayAnimation("curve", true)
    inst.AnimState:SetMultColour(0.72, 0.56, 1, 0.9)
    inst.AnimState:SetAddColour(0.22, 0.12, 0.34, 0)
    inst.AnimState:SetLightOverride(0.75)
    inst.AnimState:SetFinalOffset(1)
    inst.Transform:SetScale(1.25, 1.25, 1.25)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.entity:SetCanSleep(false)
    inst.persists = false
    inst.owner = nil
    inst.owner_component = nil
    inst.rotation = 0
    inst.hit_targets = {}
    inst.update_task = nil
    inst.timeout_task = nil

    local function TryHitTargets()
        if not Common.CanOwnerRemain(inst.owner) then
            inst:Remove()
            return false
        end
        local x, _, z = inst.Transform:GetWorldPosition()
        for _, target in ipairs(Common.FindTargetsAt(
                inst.owner, x, z, Common.MELEE_WAVE_RADIUS)) do
            if not inst:IsValid() or not Common.CanOwnerRemain(inst.owner) then
                return false
            end
            if inst.hit_targets[target] == nil
                and Common.IsValidTarget(inst.owner, target) then
                inst.hit_targets[target] = true
                SkillDamage.Apply(inst.owner, target, Common.MELEE_WAVE_DAMAGE, "nyx_melee_wave")
                if not inst:IsValid() or not Common.CanOwnerRemain(inst.owner) then
                    return false
                end
            end
        end
        return true
    end

    local function Update()
        if not TryHitTargets() then return end
        local x, y, z = inst.Transform:GetWorldPosition()
        local theta = inst.rotation * DEGREES
        local step = Common.MELEE_WAVE_SPEED * FRAMES
        inst.Transform:SetPosition(
            x + math.cos(theta) * step,
            y,
            z - math.sin(theta) * step)
    end

    function inst:Launch(owner, owner_component, rotation)
        if self.owner ~= nil or not Common.CanOwnerRemain(owner) then return false end
        self.owner = owner
        self.owner_component = owner_component
        self.rotation = rotation or self.Transform:GetRotation()
        self.update_task = self:DoPeriodicTask(FRAMES, Update, 0)
        self.timeout_task = self:DoTaskInTime(Common.MELEE_WAVE_LIFETIME, self.Remove)
        return true
    end

    inst.OnRemoveEntity = function(self)
        if self.update_task ~= nil then self.update_task:Cancel() end
        if self.timeout_task ~= nil then self.timeout_task:Cancel() end
        local component = self.owner_component
        self.owner = nil
        self.owner_component = nil
        if component ~= nil then component:_OnWaveRemoved(self) end
    end
    return inst
end

local DAYDU_PROJECTILE_SPEED = 20
local DAYDU_PROJECTILE_HIT_DISTANCE = 0.55
local DAYDU_PROJECTILE_LIFETIME = 2

return Prefab("nyx_melee_wave_fx", melee_wave_fn, assets)
