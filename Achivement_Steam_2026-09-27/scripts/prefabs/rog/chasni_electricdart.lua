local assets =
{
    Asset("ANIM", "anim/blowdart_lava.zip"),
    Asset("ANIM", "anim/swap_blowdart_lava.zip"),
}

local assets_projectile =
{
    Asset("ANIM", "anim/lavaarena_blowdart_attacks.zip"),
}

local prefabs =
{
    "chasni_electricdart_projectile",
    "chasni_electricdart_projectile_alt",
    "reticulelongmulti",
    "reticulelongmultiping",
}

local prefabs_projectile =
{
    "weaponsparks_piercing",
}

local PROJECTILE_DELAY = 4 * FRAMES
local USES = chasni_getitemconfig("chasni_electricdart", "USE") or 100
local DAMAGE = chasni_getitemconfig("chasni_electricdart", "DMG") or 51
local BARRAGE_DAMAGE = chasni_getitemconfig("chasni_electricdart", "BDMG") or 51
local BASE_DAMAGE = chasni_getitemconfig("chasni_electricdart", "BDM") or 5
local COOLDOWN = chasni_getitemconfig("chasni_electricdart", "CD") or 15

--------------------------------------------------------------------------
local function Barrage(inst, caster, pos)
    for i = 1,8 do
        inst:DoTaskInTime(0.08 * i, function()
            local offset = Vector3(math.random(), 0, math.random()):Normalize()
            local dart = SpawnPrefab("chasni_electricdart_projectile_alt")
            if i == 1 then dart.components.projectile:SetStimuli("strong") end
            dart.Transform:SetPosition((inst:GetPosition() + offset):Get())
            dart.components.projectile:Chasni_AimedThrow(inst, caster, pos + offset, BARRAGE_DAMAGE, true)
            dart.components.projectile:DelayVisibility(inst.projectiledelay)
        end)
    end
    caster.SoundEmitter:PlaySound("dontstarve/common/lava_arena/blow_dart_spread")
    inst.components.rechargeable:Discharge(COOLDOWN)
end

local function ReticuleTargetFn()
    return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
    if mousepos ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = mousepos.x - x
        local dz = mousepos.z - z
        local l = dx * dx + dz * dz
        if l <= 0 then
            return inst.components.reticule.targetpos
        end
        l = 6.5 / math.sqrt(l)
        return Vector3(x + dx * l, 0, z + dz * l)
    end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end

local function regaincharge(inst)
    if inst.components.finiteuses then
        inst.components.finiteuses:SetPercent(1)
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_blowdart_lava", "swap_blowdart_lava")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    -- >>>> DO NOT USE EventListener.. somehow the animation bugged,, WTAF
    owner.chasni_playerlighningstruck = function()
        regaincharge(inst)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    owner.chasni_playerlighningstruck = nil
end

local function getDamage(inst)
    return inst.components.finiteuses and inst.components.finiteuses:GetPercent() > 0 and DAMAGE or BASE_DAMAGE
end

local function OnCharged(inst)
    inst.components.aoetargeting:SetEnabled(true)
end

local function OnDischarged(inst)
    inst.components.aoetargeting:SetEnabled(false)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.4, 0.50)

    inst.AnimState:SetBank("blowdart_lava")
    inst.AnimState:SetBuild("blowdart_lava")
    inst.AnimState:PlayAnimation("idle")
    inst:AddTag("charges_percentage")

    inst:AddTag("blowdart")
    inst:AddTag("sharp")
    inst:AddTag("weapon")
    inst:AddTag("rechargeable")

    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetAlwaysValid(true)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticulelongmulti"
    inst.components.aoetargeting.reticule.pingprefab = "reticulelongmultiping"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
    inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true

    inst.projectiledelay = PROJECTILE_DELAY

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(Barrage)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "blowdart_lava"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(getDamage)
    inst.components.weapon:SetRange(10, 20)
    inst.components.weapon:SetProjectile("chasni_electricdart_projectile")

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(USES)

    return inst
end

--------------------------------------------------------------------------

local FADE_FRAMES = 5

local function CreateTail()
    local inst = CreateEntity()
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.entity:SetCanSleep(false)
    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("lavaarena_blowdart_attacks")
    inst.AnimState:SetBuild("lavaarena_blowdart_attacks")
    inst.AnimState:PlayAnimation("tail_1")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

    inst.persists = false

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end

local function OnUpdateProjectileTail(inst)
    local c = (not inst.entity:IsVisible() and 0) or (inst._fade ~= nil and (FADE_FRAMES - inst._fade:value() + 1) / FADE_FRAMES) or 1
    if c > 0 then
        local tail = CreateTail()
        tail.Transform:SetPosition(inst.Transform:GetWorldPosition())
        tail.Transform:SetRotation(inst.Transform:GetRotation())
        if c < 1 then
            tail.AnimState:SetTime(c * tail.AnimState:GetCurrentAnimationLength())
        end
    end
end

local function CreateFX(prefab, target, source)
    local fx = SpawnPrefab(prefab)
    local s = source or target
    if fx.OnSpawn then
        fx:OnSpawn({target = target, source = s or target})
    end
    return fx
end

local function OnHit(inst, attacker, target)
    CreateFX("weaponsparks_piercing", target, attacker)
    if target then
        target.dartalt_hits = target.dartalt_hits and (target.dartalt_hits + 1) or 1
        if not target.dartalt_task then
            target.dartalt_task = target:DoTaskInTime(1, function(inst)
                inst.dartalt_hits = nil
            end)
        end
    end
    inst:Remove()
end

local function commonprojectilefn(alt)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("lavaarena_blowdart_attacks")
    inst.AnimState:SetBuild("lavaarena_blowdart_attacks")
    inst.AnimState:PlayAnimation("attack_3", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetAddColour(1, 1, 0, 0)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst:AddTag("projectile")

    if not TheNet:IsDedicated() then
        inst:DoPeriodicTask(0, OnUpdateProjectileTail)
    end

    if alt then
        inst._fade = net_tinybyte(inst.GUID, "chasni_electricdart_projectile_alt._fade")
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(35)
    inst.components.projectile:SetRange(20)
    inst.components.projectile:SetHitDist(0.5)
    inst.components.projectile:SetLaunchOffset(Vector3(-2, 1, 0))
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:DelayVisibility(PROJECTILE_DELAY)

    if alt then
        inst.components.projectile:SetRange(30)
    end
    inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/blow_dart")

    return inst
end

local function projectilefn()
    return commonprojectilefn(false)
end

local function projectilealtfn()
    return commonprojectilefn(true)
end

return
Prefab("chasni_electricdart", fn, assets, prefabs),
Prefab("chasni_electricdart_projectile", projectilefn, assets_projectile, prefabs_projectile),
Prefab("chasni_electricdart_projectile_alt", projectilealtfn, assets_projectile, prefabs_projectile)
