local assets =
{
    Asset("ANIM", "anim/spider_spike.zip"),
}

local prefabs =
{
    "erode_ash",
}

local ATTACK_RADIUS = 1
local DAMAGE = chasni_getitemconfig("webbermask", "S_DUR") or 20
local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "flying", "shadow", "ghost", "FX", "NOCLICK", "DECOR", "INLIMBO", "playerghost" }
local function KeepTargetFn() return false end
local function shouldhit(inst, target)
	return inst.owner ~= target and not target:HasTag("spider")
end

local function DoAttack(inst)
	local attacker = (inst.owner and inst.owner:IsValid()) and inst.owner or inst
    attacker.components.combat.ignorehitrange = true
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, y, z, ATTACK_RADIUS + 3, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS)) do
        if v:IsValid() and not v:IsInLimbo() and not (v.components.health and v.components.health:IsDead()) and shouldhit(inst, v) then
            local range = ATTACK_RADIUS + v:GetPhysicsRadius(.5)
            if v:GetDistanceSqToPoint(x, y, z) < range * range and inst.components.combat:CanTarget(v) and v.components.combat then
                v.components.combat:GetAttacked(attacker, DAMAGE)
            end
        end
    end
    attacker.components.combat.ignorehitrange = false
end

local function KillSpike(inst)
	if not inst.killed then
		if inst.attack_task then
			inst.attack_task:Cancel()
			inst.attack_task = nil
			inst:Remove()
		else
			inst.killed = true

			if inst.lifespan_task then
				inst.lifespan_task:Cancel()
				inst.lifespan_task = nil
			end

			inst.AnimState:PlayAnimation("spike_pst")
			DoAttack(inst)
            inst.SoundEmitter:PlaySound("turnoftides/creatures/together/spider_moon/break")
			inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, inst.Remove)
		end
	end
end

local function StartAttack(inst)
	inst.attack_task = nil

    inst.AnimState:PlayAnimation("spike_pre")
    inst.SoundEmitter:PlaySoundWithParams("turnoftides/creatures/together/spider_moon/spike", {intensity= math.random()})
    inst.AnimState:PushAnimation("spike_loop")

    inst.lifespan_task = inst:DoTaskInTime(2 + math.random() * 0.5, KillSpike)

	DoAttack(inst)
end

local function SetOwner(inst, owner)
	inst.owner = owner
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("spider_spike")
    inst.AnimState:SetBuild("spider_spike")
    inst.AnimState:PlayAnimation("empty")
    inst.AnimState:SetFinalOffset(1)

    inst:AddTag("NOCLICK")
    inst:AddTag("notarget")
    inst:AddTag("groundspike")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.SPIDER_MOON_SPIKE_DAMAGE)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst.persists = false

	inst.KillSpike = function() KillSpike(inst) end

	inst.attack_task = inst:DoTaskInTime(math.random() * 0.25, StartAttack)

	inst.SetOwner = SetOwner

    return inst
end

return Prefab("webbermask_spike", fn, assets, prefabs)
