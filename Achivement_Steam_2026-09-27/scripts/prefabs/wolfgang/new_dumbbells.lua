local assets =
{
    Asset("ANIM", "anim/dumbbell_tinker.zip"),
    Asset("ANIM", "anim/swap_dumbbell_tinker.zip"),
    Asset("ATLAS", "images/inventoryimages/dumbell_tinker.xml"),
}

local DURATION = chasni_getitemconfig("dumbbells_tinker", "DUR") or 30
local SHORT_DURATION = chasni_getitemconfig("dumbbells_tinker", "SDUR") or 1
local TORNADO_COUNT = chasni_getitemconfig("dumbbells_tinker", "COUNT") or 5
local SANITY_GAIN = chasni_getitemconfig("dumbbells_tinker", "SAN") or 10
local SPEED = chasni_getitemconfig("dumbbells_tinker", "SPD") or 1.25
local USES = chasni_getitemconfig("dumbbells_tinker", "USES") or 500
local USAGE = chasni_getitemconfig("dumbbells_tinker", "USAGE") or 1
local DAMAGE = chasni_getitemconfig("dumbbells_tinker", "DMG") or 34
local EVASION_MIGHTY = chasni_getitemconfig("dumbbells_tinker", "EVA1") or 0.2
local EVASION_NORMAL = chasni_getitemconfig("dumbbells_tinker", "EVA2") or 0.5
local EVASION_WIMPY = chasni_getitemconfig("dumbbells_tinker", "EVA3") or 0.8
local MIN_DAMAGE = chasni_getitemconfig("dumbbells_tinker", "MDMG") or 20

local DUMBELL_EFFICIENCY = {
    tinker = { -10, -10, -10 }
}
local MUST_TAGS = { "_combat", "_health" }
local CANT_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO"}
local function ReticuleTargetFn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    for r = 6.5, 3.5, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function ReticuleShouldHideFn(inst)
    return not inst:HasTag("projectile")
end

local function HasFriendlyLeader(inst, target, attacker)
    local target_leader = (target.components.follower) and target.components.follower.leader or nil

    if target_leader then
        if target_leader.components.inventoryitem then
            target_leader = target_leader.components.inventoryitem:GetGrandOwner()
        end

        local PVP_enabled = TheNet:GetPVPEnabled()
        return (target_leader
                and (target_leader:HasTag("player")
                and not PVP_enabled)) or
                (target.components.domesticatable and target.components.domesticatable:IsDomesticated()
                        and not PVP_enabled) or
                (target.components.saltlicker and target.components.saltlicker.salted
                        and not PVP_enabled)
    end

    return false
end

local function CanDamage(inst, target, attacker)
    if target.components.minigame_participator or target.components.combat == nil then
        return false
    end

    if target:HasTag("player") and not TheNet:GetPVPEnabled() then
        return false
    end

    if target:HasTag("playerghost") and not target:HasTag("INLIMBO") then
        return false
    end

    if target:HasTag("monster") and not TheNet:GetPVPEnabled() and
            ((target.components.follower and target.components.follower.leader and
                    target.components.follower.leader:HasTag("player")) or target.bedazzled) then
        return false
    end

    if HasFriendlyLeader(inst, target, attacker) then
        return false
    end

    return true
end

local function ResetPhysics(inst)
    inst.Physics:SetFriction(0.1)
    inst.Physics:SetRestitution(0.5)
    inst.Physics:SetCollisionGroup(COLLISION.ITEMS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
end

local function onthrown(inst)
    inst:AddTag("NOCLICK")
    inst.persists = false

    local attacker = inst.components.complexprojectile.attacker
    if attacker then
        inst.components.mightydumbbell:DoAttackWorkout(attacker)
    end

    inst.AnimState:PlayAnimation("spin_loop", true)
    inst.SoundEmitter:PlaySound("wolfgang1/dumbbell/throw_twirl", "spin_loop")

    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.ITEMS)
end

local function spawntornado(inst, attacker, target, duration)
    local tornado = SpawnPrefab("tornado")
    tornado:SetDuration(duration or DURATION)
    tornado.WINDSTAFF_CASTER = attacker
    tornado.WINDSTAFF_CASTER_ISPLAYER = tornado.WINDSTAFF_CASTER and tornado.WINDSTAFF_CASTER:HasTag("player")
    if target then
        tornado.Transform:SetPosition(0, 0, 0)
        tornado.entity:SetParent(target.entity)
    else
        local x, y, z = inst.Transform:GetWorldPosition()
        tornado.Transform:SetPosition(x, y, z)
    end

    if tornado.WINDSTAFF_CASTER_ISPLAYER then
        tornado.overridepkname = tornado.WINDSTAFF_CASTER:GetDisplayName()
        tornado.overridepkpet = true
    end
end

local function OnThrownHit(inst, attacker, target)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 2, MUST_TAGS, CANT_TAGS)

    if inst.istornadoattack then
        for _ = 1, TORNADO_COUNT do
            spawntornado(inst, attacker)
        end
    end

    local olddamage = inst.components.weapon.damage

    inst.components.weapon.damage = function(inst, attacker, target)
        local damage = olddamage
        if attacker and attacker.components.skilltreeupdater and attacker.components.skilltreeupdater:IsActivated("wolfgang_dumbbell_throwing_2") then
            damage = damage * TUNING.SKILLS.WOLFGANG_DUMBELL_TOSS_2
        elseif attacker and attacker.components.skilltreeupdater and attacker.components.skilltreeupdater:IsActivated("wolfgang_dumbbell_throwing_1") then
            damage = damage * TUNING.SKILLS.WOLFGANG_DUMBELL_TOSS_1
        end
        return damage
    end

    for i, ent in ipairs(ents) do
        if CanDamage(inst, ent, attacker) then
            if attacker and attacker:IsValid() then
                attacker.components.combat.ignorehitrange = true
                attacker.components.combat:DoAttack(ent, inst, inst)
                attacker.components.combat.ignorehitrange = false
            else
                ent.components.combat:GetAttacked(attacker, inst.components.weapon.damage(inst, inst.components.complexprojectile.attacker, ent) )
            end
        end
    end

    inst.components.weapon.damage = olddamage

    SpawnPrefab("round_puff_fx_sm").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.AnimState:PlayAnimation("land")
    inst.AnimState:PushAnimation("idle", true)

    inst:RemoveTag("NOCLICK")
    inst.persists = true

    inst.SoundEmitter:KillSound("spin_loop")
    inst.SoundEmitter:PlaySound(inst.impact_sound)

    inst.components.finiteuses:Use(inst.thrown_consumption)

    if inst.components.finiteuses:GetUses() > 0 then
        ResetPhysics(inst)
    end
end

local function MakeTossable(inst)
    if inst.components.complexprojectile == nil then
        inst:AddComponent("complexprojectile")
        inst.components.complexprojectile:SetHorizontalSpeed(15)
        inst.components.complexprojectile:SetGravity(-35)
        inst.components.complexprojectile:SetLaunchOffset(Vector3(1, 1, 0))
        inst.components.complexprojectile:SetOnLaunch(onthrown)
        inst.components.complexprojectile:SetOnHit(OnThrownHit)
        inst.components.complexprojectile.ismeleeweapon = true
    end
end

local function RemoveTossable(inst)
    if inst.components.complexprojectile then
        inst:RemoveComponent("complexprojectile")
    end
end

local function MakeWeapon(inst)
    inst:RemoveTag("punch")
end

local function MakePunch(inst)
    inst:AddTag("punch")
end

local function CheckMightiness(inst, data)
    local dumbbell = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if data and dumbbell then
        if data.state == "mighty" then
            MakeTossable(dumbbell)
        else
            RemoveTossable(dumbbell)
        end

        if data.state == "wimpy" then
            MakePunch(dumbbell)
        else
            MakeWeapon(dumbbell)
        end
    end
end

local function DodgeChanceFn(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    return owner and ((owner:HasTag("mightiness_mighty") and EVASION_MIGHTY) or (owner:HasTag("mightiness_normal") and EVASION_NORMAL) or (owner:HasTag("mightiness_wimpy") and EVASION_WIMPY)) or 0
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", inst.swap_dumbbell, inst.swap_dumbbell_symbol)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    CheckMightiness(owner, {
        state = (owner.components.mightiness and owner.components.mightiness:GetState()) or nil,
    })

    inst._spawnlatchtornado = function(_, data) spawntornado(inst, owner, data and data.attacker, SHORT_DURATION) end
    owner:ListenForEvent("chasni_dododge", inst._spawnlatchtornado)
    inst:ListenForEvent("mightiness_statechange", CheckMightiness, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    if inst:HasTag("lifting") then
        owner:PushEvent("stopliftingdumbbell", {instant = true})
    end

    owner:RemoveEventCallback("chasni_dododge", inst._spawnlatchtornado)
    inst:RemoveEventCallback("mightiness_statechange", CheckMightiness, owner)
end

local function OnAttack(inst, attacker, target)
    if inst.components.inventoryitem:IsHeldBy(attacker) then
        inst.components.mightydumbbell:DoAttackWorkout(attacker)
    end
end

local function OnDropped(inst)
    if inst._prev_owner and inst._onattackedfn then
        inst._prev_owner:RemoveEventCallback("attacked", inst._onattackedfn)
    end
end

local function OnPickup(inst, owner)
    if owner then
        if owner:HasTag("mightiness_mighty") then
            MakeTossable(inst)
        else
            RemoveTossable(inst)
        end

        if owner:HasTag("mightiness_wimpy") then
            MakePunch(inst)
        else
            MakeWeapon(inst)
        end

        OnDropped(inst)
        inst._prev_owner = owner
        inst._onattackedfn = function(_, data)
            if data.damageresolved > MIN_DAMAGE then
                spawntornado(inst, owner, data and data.attacker, SHORT_DURATION)
            end
        end
        owner:ListenForEvent("attacked", inst._onattackedfn)
    end
end

local function onlift_tinker(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and owner.components.sanity then
        owner.components.sanity:DoDelta(SANITY_GAIN)
    end
end

local function MakeDumbbell(name, consumption, efficiency, uses, damage, impact_sound, onliftfn, walkspeedmult)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("dumbbell_golden")
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle", true)

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "small", 0.15, 0.9)

        inst:AddTag("dumbbell")
        inst:AddTag("keep_equip_toss")

        inst:AddComponent("reticule")
        inst.components.reticule.targetfn = ReticuleTargetFn
        inst.components.reticule.shouldhidefn = ReticuleShouldHideFn
        inst.components.reticule.ease = true

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        if name == "dumbbell_tinker" then
            inst.istornadoattack = true
        end

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/dumbell_tinker.xml"
        inst.components.inventoryitem.imagename = "dumbell_tinker"
        inst:AddComponent("inspectable")

        inst:AddComponent("equippable")
        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)
        if walkspeedmult then
            inst.components.equippable.walkspeedmult = walkspeedmult
        end

        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(damage)
        inst.components.weapon:SetOnAttack(OnAttack)
        inst.components.weapon.attackwear = consumption * TUNING.DUMBBELL_ATTACK_CONSUMPTION_MULT

        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetMaxUses(uses)
        inst.components.finiteuses:SetUses(uses)
        inst.components.finiteuses:SetOnFinished(function()
            if inst.components.inventoryitem:GetGrandOwner() == nil then
                inst.components.inventoryitem.canbepickedup = false
                inst:DoTaskInTime(1, ErodeAway)
            else
                inst:Remove()
            end
        end)

        MakeHauntableLaunch(inst)

        inst:AddComponent("mightydumbbell")
        inst.components.mightydumbbell:SetConsumption(consumption)
        inst.components.mightydumbbell:SetEfficiency(efficiency[1], efficiency[2], efficiency[3])
        inst.components.mightydumbbell.negativeefficiency = true
        if onliftfn then
            inst.components.mightydumbbell.onliftfn = onliftfn
        end

        inst.swap_dumbbell = "swap_" .. name
        inst.swap_dumbbell_symbol = "swap_dumbbell_golden"
        inst.thrown_consumption = consumption * TUNING.DUMBBELL_THROWN_CONSUMPTION_MULT
        inst.impact_sound = impact_sound
        inst.chasni_dodgechancegearfn = DodgeChanceFn

        inst:ListenForEvent("onputininventory", OnPickup)
        inst:ListenForEvent("ondropped", OnDropped)
        inst:ListenForEvent("onremove", OnDropped)

        return inst
    end

    return Prefab(name, fn, assets)
end

return MakeDumbbell("dumbbell_tinker",      USAGE,       DUMBELL_EFFICIENCY.tinker, USES, DAMAGE,    "wolfgang1/dumbbell/stone_impact", onlift_tinker, SPEED)
