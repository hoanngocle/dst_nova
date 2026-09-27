local assets =
{
    Asset("ANIM", "anim/lavaarena_firestaff_meteor.zip"),
}

local assets_splash = {
    Asset("ANIM", "anim/lavaarena_fire_fx.zip"),
}

local prefabs =
{
    "fire_staff_meteor_splash",
    "fire_staff_meteor_splashhit",
}

local prefabs_splash =
{
    "fire_staff_meteor_splashbase",
}

local RADIUS = 5
local CENTER_MULT = 1
local IMPACT_RADIUS = 16
local function ShakeIfClose(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .5, .03, .25, inst, 30)
end

local function GetImpactDamage(inst, target, base_damage)
    local centerpos = inst:GetPosition()
    local center_mult = CENTER_MULT
    local base_dist = IMPACT_RADIUS
    local dist = distsq(centerpos, target:GetPosition())
    local dist_ratio = math.max(0, 1 - dist / base_dist)
    return base_damage * (1 + Lerp(0, center_mult, dist_ratio))
end

local function OnImpact(inst)
	inst:DoTaskInTime(FRAMES*3, function(inst)
        local scale = inst.Transform:GetScale()
		local splash_fx = chasni_spawnFX("fire_staff_meteor_splash", nil, inst.attacker)
        splash_fx:Init(inst:GetPosition(), splash_fx)

        local x, y, z = inst:GetPosition():Get()
        local targets = TheSim:FindEntities(x, y, z, RADIUS * scale, inst.tags.inc, inst.tags.ex)
        for p, target in ipairs(targets) do
            if target.components.health and not target.components.health:IsDead() and target.components.combat then
                target.components.combat:GetAttacked(inst, GetImpactDamage(inst, target, inst.base_damage))
            end
        end
        ShakeIfClose(inst)
        inst:Remove()
	end)
end
--------------------------------------------------------------------------
local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lavaarena_firestaff_meteor")
    inst.AnimState:SetBuild("lavaarena_firestaff_meteor")
    inst.AnimState:PlayAnimation("crash")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    MakeInventoryFloatable(inst)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("notarget")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animover", OnImpact)

    inst.tags = {}
	inst.InitState = function(inst, attacker, weapon, pos, tags_inc, tags_ex, base_damage)
		if weapon then weapon.meteor = inst end
		inst.attacker = attacker
		inst.owner = weapon
		inst.Transform:SetPosition(pos:Get())
		inst.tags = {inc = tags_inc or {}, ex = tags_ex or {}}
        inst.base_damage = base_damage
    end

    return inst
end

local function splashfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lavaarena_fire_fx")
    inst.AnimState:SetBuild("lavaarena_fire_fx")
    inst.AnimState:PlayAnimation("firestaff_ult")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(1)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animover", inst.Remove)

    inst.Init = function(inst, pos, source)
		inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/meteor_strike")
		inst.Transform:SetPosition(pos:Get())
        chasni_spawnprefab("fire_staff_meteor_splashbase", pos.x, pos.y, pos.z)
        chasni_spawnprefab("fire_staff_meteor_splashhit", pos.x, pos.y, pos.z)
	end

    return inst
end
--------------------------------------------------------------------------
local function splashbasefn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lavaarena_fire_fx")
    inst.AnimState:SetBuild("lavaarena_fire_fx")
    inst.AnimState:PlayAnimation("firestaff_ult_projection")

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end
--------------------------------------------------------------------------
local function splashhitfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lavaarena_fire_fx")
    inst.AnimState:SetBuild("lavaarena_fire_fx")
    inst.AnimState:PlayAnimation("firestaff_ult_hit")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(1)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.SetTarget = function(inst, target)
		inst.Transform:SetPosition(target:GetPosition():Get())
		local scale = target:HasTag("minion") and .5 or (target:HasTag("largecreature") and 1.3 or .8)
		inst.AnimState:SetScale(scale, scale)
	end

    inst:ListenForEvent("animover", inst.Remove)
    inst.OnLoad = inst.Remove

    return inst
end
--------------------------------------------------------------------------
return Prefab("fire_staff_meteor", fn, assets, prefabs),
    Prefab("fire_staff_meteor_splash", splashfn, assets_splash, prefabs_splash),
    Prefab("fire_staff_meteor_splashbase", splashbasefn, assets_splash),
    Prefab("fire_staff_meteor_splashhit", splashhitfn, assets_splash)
