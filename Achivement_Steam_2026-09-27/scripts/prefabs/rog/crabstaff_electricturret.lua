local assets =
{
    Asset("ANIM", "anim/bishop_projectile_yellow.zip"),
}
local assets_proj =
{
    Asset("ANIM", "anim/bishop_projectile_yellow.zip"),
    Asset("SOUND", "sound/chess.fsb"),
}

local prefabs =
{
    "crabstaff_electricturret_proj",
}

local MAX_LIGHT_FRAME = 24
local DURATION = chasni_getitemconfig("crabstaff_electricturret", "RNG") or 100
local RANGE = chasni_getitemconfig("crabstaff_electricturret", "RNG") or 15
local DAMAGE = chasni_getitemconfig("crabstaff_electricturret", "DMG") or 10
local DAMAGE_MULT = chasni_getitemconfig("crabstaff_electricturret", "DMGM") or 0.1
local function OnUpdateLight(inst, dframes)
    local frame = inst._lightframe:value() + dframes
    if frame >= MAX_LIGHT_FRAME then
        inst._lightframe:set_local(MAX_LIGHT_FRAME)
        inst._lighttask:Cancel()
        inst._lighttask = nil
    else
        inst._lightframe:set_local(frame)
    end

    if frame <= 20 then
        local k = frame / 20
        inst.Light:SetRadius(3.5 * k)
        inst.Light:SetIntensity(.9 * k + .65 * (1 - k))
        inst.Light:SetFalloff(.9 * k + .7 * (1 - k))
    else
        local k = (frame - 20) / (MAX_LIGHT_FRAME - 20)
        inst.Light:SetRadius(3.5 * (1 - k))
        inst.Light:SetIntensity(.65 * k + .9 * (1 - k))
        inst.Light:SetFalloff(.7 * k + .9 * (1 - k))
    end

    if TheWorld.ismastersim then
        inst.Light:Enable(frame < MAX_LIGHT_FRAME)
    end
end

local function OnLightDirty(inst)
    if inst._lighttask == nil then
        inst._lighttask = inst:DoPeriodicTask(FRAMES, OnUpdateLight, nil, 1)
    end
    OnUpdateLight(inst, 0)
end

local function triggerlight(inst)
    inst._lightframe:set(0)
    OnLightDirty(inst)
end

local function initCaster(inst, caster)
    inst._caster = caster
    inst:ListenForEvent("onhitother", function(_, data)
        if data and data.target and inst:GetDistanceSqToInst(data.target) < RANGE * RANGE then
            inst.sg:GoToState("attack", data.target)
        end
    end, caster)
end

local function getDamage(inst, attacker, target)
    if attacker and attacker._caster and attacker._caster.components.levelsystem then
        return DAMAGE + (attacker._caster.components.levelsystem.damagelevelamount * DAMAGE_MULT)
    end
    return DAMAGE
end

local function MakeWeapon(inst)
    local weapon = CreateEntity()
    weapon.entity:AddTransform()
    MakeInventoryPhysics(weapon)

    weapon:AddComponent("weapon")
    weapon.components.weapon:SetDamage(getDamage)
    weapon.components.weapon:SetRange(inst.components.combat.attackrange, inst.components.combat.attackrange+4)
    weapon.components.weapon:SetProjectile("crabstaff_electricturret_proj")
    weapon.components.weapon:SetElectric()
    weapon:AddComponent("equippable")
    weapon:AddComponent("inventoryitem")
    weapon.components.inventoryitem:SetOnDroppedFn(weapon.Remove)
    weapon.persists = false
    weapon:AddTag("nosteal")
    return weapon
end

local function OnTimerDone(inst, data)
    if data.name == "remove" then
        inst.AnimState:PlayAnimation("impact")
        inst.SoundEmitter:PlaySound("dontstarve/creatures/bishop/shotexplo")
        inst:DoTaskInTime(1, inst.Remove)
        inst.persists = false
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst:AddTag("crabstaff_turret")

    inst.AnimState:SetBank("bishop_projectile_yellow")
    inst.AnimState:SetBuild("bishop_projectile_yellow")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.Light:SetRadius(0)
    inst.Light:SetIntensity(.65)
    inst.Light:SetFalloff(.7)
    inst.Light:SetColour(251/255, 234/255, 234/255)
    inst.Light:Enable(false)
    inst.Light:EnableClientModulation(true)

    inst._lightframe = net_smallbyte(inst.GUID, "eyeturret._lightframe", "lightdirty")
    inst._lighttask = nil

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst:ListenForEvent("lightdirty", OnLightDirty)

        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetRange(RANGE)
    inst.components.combat:SetDefaultDamage(DAMAGE)
    inst.components.combat:SetAttackPeriod(3)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = TUNING.SANITYAURA_SMALL

    inst.weapon = MakeWeapon(inst)
    inst:AddComponent("inventory")
    inst.components.inventory:Equip(inst.weapon)

    inst:AddComponent("inspectable")
    inst:AddComponent("timer")
    inst.components.timer:StartTimer("remove", DURATION)
    inst:ListenForEvent("timerdone", OnTimerDone)

    inst.triggerlight = triggerlight
    inst.initCaster = initCaster
    inst.persists = false

    inst:SetStateGraph("SGCZcrabstaff_electricturret")

    return inst
end

local function OnHit(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/bishop/shotexplo")
    inst.AnimState:PlayAnimation("impact")
    inst.Physics:Stop()
    inst:ListenForEvent("animover", inst.Remove)
end

local function fn_charge()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("bishop_projectile_yellow")
    inst.AnimState:SetBuild("bishop_projectile_yellow")
    inst.AnimState:PlayAnimation("idle", true)
    inst.Transform:SetScale(0.6,0.6,0.6)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("projectile")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(30)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(1)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(OnHit)
    inst.components.projectile:SetLaunchOffset({x=0,y=0,z=0})

    inst.persists = false

    return inst
end

return Prefab("crabstaff_electricturret", fn, assets, prefabs),
Prefab("crabstaff_electricturret_proj", fn_charge, assets_proj) 
