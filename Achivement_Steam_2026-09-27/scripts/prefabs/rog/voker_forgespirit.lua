local brain = require "brains/generic_staticbrain"

local assets =
{
    Asset("ANIM", "anim/lavaarena_elemental_basic.zip"),
}

local assets_proj =
{
    Asset("ANIM", "anim/fireball_2_fx.zip"),
}

local HEALTH = chasni_getitemconfig("book_voker", "FS_HP") or 490
local DAMAGE = chasni_getitemconfig("book_voker", "FS_DMG") or 49
local ATTACK_PERIOD = chasni_getitemconfig("book_voker", "FS_ASP") or 1.5
local ATTACK_RANGE = chasni_getitemconfig("book_voker", "FS_ARN") or 12
local DURATION = chasni_getitemconfig("book_voker", "FS_DUR") or 49
local RETARGET_PERIOD = 1
local KEEPTARGET_RANGE = 12
local function Retarget(inst)
    return FindEntity(inst, ATTACK_RANGE + 1, function(guy)
        if guy.components.combat and guy.components.health and not guy.components.health:IsDead() then
            return (guy.components.combat.target == inst or guy:HasTag("character") or guy:HasTag("monster") or guy:HasTag("animal")) and not guy:HasTag("injoker") and not (guy.prefab == inst.prefab)
        end
    end)
end

local function KeepTargetFn(inst, target)
    return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
end

local function OnAttacked(inst, data)
    chasni_solosharetarget(inst, data)
end

local function OnAnimOver(inst, data)
    inst:RemoveEventCallback("animover", OnAnimOver)
    inst.sg:GoToState("death")
end

local function OnTimerDone(inst, data)
    if data.name == "death" then
        inst:ListenForEvent("animover", OnAnimOver)
    end
end

local function MakeWeapon()
    local weapon = CreateEntity()
    weapon.entity:AddTransform()

    MakeInventoryPhysics(weapon)

    weapon:AddComponent("weapon")
    weapon.components.weapon:SetProjectile("voker_forgespirit_proj")
    weapon.components.weapon:SetDamage(DAMAGE)
    weapon.components.weapon:SetRange(ATTACK_RANGE)
    weapon:AddTag("nosteal")

    weapon:AddComponent("equippable")
    weapon:AddComponent("inventoryitem")
    weapon.components.inventoryitem:SetOnDroppedFn(weapon.Remove)

    weapon.persists = false

    return weapon
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddPhysics()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddDynamicShadow()

    MakeCharacterPhysics(inst, 250, 1.5)

    inst.DynamicShadow:SetSize(2.5, 1.5)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("lavaarena_elemental_basic")
    inst.AnimState:SetBuild("lavaarena_elemental_basic")

    inst:AddTag("scarytoprey")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("inspectable")
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DAMAGE)
    inst.components.combat:SetRange(ATTACK_RANGE)
    inst.components.combat:SetAttackPeriod(ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(RETARGET_PERIOD, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(HEALTH)

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("death", DURATION)
    inst:ListenForEvent("timerdone", OnTimerDone)

    inst.weapon = MakeWeapon(inst)
    inst:AddComponent("inventory")
    inst.components.inventory:Equip(inst.weapon)

    inst:ListenForEvent("attacked", OnAttacked)

    inst:SetStateGraph("SGCZforgespirit")
    inst:SetBrain(brain)

    return inst
end

local function OnThrown(inst)
    inst:Show()
    inst.AnimState:PlayAnimation("idle_loop")
end

local function OnHit(inst)
    inst.AnimState:PlayAnimation("disappear")
    inst:ListenForEvent("animover", function(inst) inst:Remove() end)
end

local function OnMiss(inst)
    inst.AnimState:PlayAnimation("disappear")
    inst:ListenForEvent("animover", function(inst) inst:Remove() end)
end

local function projfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddPhysics()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.Transform:SetScale(0.6, 0.6, 0.6)
    inst.Transform:SetTwoFaced()

    inst.AnimState:SetBank("fireball_fx")
    inst.AnimState:SetBuild("fireball_2_fx")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:SetMultColour(1, 0.7, 0.7, 1)
    inst.AnimState:SetFinalOffset(-1)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("projectile")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(40)
    inst.components.projectile:SetHoming(true)
    inst.components.projectile:SetHitDist(1)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(OnMiss)
    inst.components.projectile:SetOnThrownFn(OnThrown)
    inst.components.projectile:SetLaunchOffset(Vector3(2, 0.3, 2))

    return inst
end

return Prefab("voker_forgespirit", fn, assets),
Prefab("voker_forgespirit_proj", projfn, assets_proj)