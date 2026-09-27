-- Lục Nguyên Kiếm Đồng. Held/ground/icon visuals use Solo Leveling's
-- Hắc Ảnh Kiếm; flying sword effects retain their Tu Tiên visuals.
local Bridge = require("ttk_lucnguyen_combat")
local Rules = require("ttk_lucnguyen_rules")
local Elements = require("ttk_elemental_combat")

local BASE_DAMAGE = 88
local VANKIEM_BASE_DAMAGE = 93
local MAX_USES = 1000
local REPAIR_USES = 100
local FLIGHT_SPEED = 12
local TURN_RATE = 8
local FLIGHT_TIMEOUT = 3
local HIT_DISTANCE = .65
local MAX_FLIGHT_RANGE = 30
local SWORD_SPAWN_RADIUS = 3
local VANKIEM_ORBIT_RADIUS = 5
local LUCMACH_ORBIT_RADIUS = 3
local SWORD_LAUNCH_INTERVAL = .18
local SWORD_ORBIT_SPEED = 120 * DEGREES
local VOLLEY_COOLDOWN = 4.5
local SWORD_DAMAGE_MULT = { .2, .3, .45, .6, .75, 1 }

local function SetRitualLevel(inst, level)
    level = tonumber(level) or 0
    if level ~= level then level = 0 end
    inst._ttk_ritual_level = math.floor(math.max(0, math.min(9, level)))
end

local function OnSave(inst, data)
    data.ttk_ritual_level = inst._ttk_ritual_level or 0
end

local function OnLoad(inst, data)
    SetRitualLevel(inst, data ~= nil and data.ttk_ritual_level or 0)
end

local ELEMENTS = {
    -- The isolated Lục Mạch builds contain complete swords, all tip-down.
    -- One rotation rule keeps every Lục Nguyên projectile tip-first.
    { bank = "lucmachthankiem_magic", build = "ttk_vankiem_magic_001", anim = "idle", tip_rotation = 90, colour = { .85, .9, 1 } },
    { bank = "lucmachthankiem_magic", build = "ttk_vankiem_magic_002", anim = "idle", tip_rotation = 90, colour = { .3, .85, .35 } },
    { bank = "lucmachthankiem_magic", build = "ttk_vankiem_magic_003", anim = "idle", tip_rotation = 90, colour = { .3, .55, 1 } },
    { bank = "lucmachthankiem_magic", build = "ttk_vankiem_magic_004", anim = "idle", tip_rotation = 90, colour = { 1, .35, .08 } },
    { bank = "lucmachthankiem_magic", build = "ttk_vankiem_magic_005", anim = "idle", tip_rotation = 90, colour = { .8, .62, .2 } },
    { bank = "lucmachthankiem_magic", build = "ttk_vankiem_magic_006", anim = "idle", tip_rotation = 90, colour = { .75, .2, 1 } },
}

local function FaceFlightDirection(inst)
    inst.Transform:SetRotation(-inst._heading / DEGREES + inst._tip_rotation)
end

local CommandVolley

local assets = {
    -- Hắc Ảnh Kiếm visuals are bundled so this weapon works without Solo Leveling.
    Asset("ANIM", "anim/ttk_lucnguyen_hh.zip"),
    Asset("ANIM", "anim/ttk_lucnguyen_hh_flight.zip"),
    Asset("ANIM", "anim/ttk_vankiem_king.zip"),
    Asset("ANIM", "anim/ttk_vankiem_swap.zip"),
    Asset("ANIM", "anim/ttk_kim_display.zip"),
    Asset("ANIM", "anim/ttk_moc_display.zip"),
    Asset("ANIM", "anim/ttk_thuy_display.zip"),
    Asset("ANIM", "anim/ttk_hoa_flight.zip"),
    Asset("ANIM", "anim/ttk_tho_display.zip"),
    Asset("ANIM", "anim/ttk_makiem_display.zip"),
    Asset("ANIM", "anim/ttk_tho_flight.zip"),
    Asset("ANIM", "anim/ttk_makiem_flight.zip"),
    Asset("ANIM", "anim/lucmachthankiem_magic.zip"),
    Asset("ANIM", "anim/ttk_vankiem_magic_001.zip"),
    Asset("ANIM", "anim/ttk_vankiem_magic_002.zip"),
    Asset("ANIM", "anim/ttk_vankiem_magic_003.zip"),
    Asset("ANIM", "anim/ttk_vankiem_magic_004.zip"),
    Asset("ANIM", "anim/ttk_vankiem_magic_005.zip"),
    Asset("ANIM", "anim/ttk_vankiem_magic_006.zip"),
    Asset("ATLAS", "images/inventoryimages/ttk_lucnguyenkiemdong.xml"),
    Asset("IMAGE", "images/inventoryimages/ttk_lucnguyenkiemdong.tex"),
    Asset("ATLAS", "images/inventoryimages/ttk_vankiemquytong.xml"),
    Asset("IMAGE", "images/inventoryimages/ttk_vankiemquytong.tex"),
}

local prefabs = { "impact", "lucmachthankiem" }
for index = 1, #ELEMENTS do
    table.insert(prefabs, "ttk_lucnguyen_sword_" .. tostring(index))
    table.insert(prefabs, "ttk_lucnguyen_trail_" .. tostring(index))
end

local function IsValid(inst)
    return inst ~= nil and inst:IsValid()
end

local function IsLivingTarget(target)
    return IsValid(target)
        and not target:IsInLimbo()
        and (target.components.health == nil or not target.components.health:IsDead())
end

local function IsLivingOwner(owner)
    return IsValid(owner)
        and not owner:IsInLimbo()
        and not owner:HasTag("playerghost")
        and (owner.components.health == nil or not owner.components.health:IsDead())
end

local function CompleteSwordAttack(inst, hit)
    if hit and IsLivingOwner(inst._owner) and IsLivingTarget(inst._target) then
        local weapon = IsValid(inst._source_weapon) and inst._source_weapon or nil
        if inst._apply_impact == false then
            Bridge.ApplyAuxiliary(inst._owner, inst._target, inst._damage, weapon)
        else
            Elements.ApplySwordImpact(inst._owner, inst._target, inst._damage,
                weapon, inst._element)
        end
    end
    inst._target = nil
    if inst._temporary then
        inst:Remove()
    else
        inst._orbit_state = "return"
    end
end

local function StageSwordAroundOwner(inst, owner, target)
    local ox, oy, oz = owner.Transform:GetWorldPosition()
    local tx, _, tz = target.Transform:GetWorldPosition()
    local heading = math.atan2(tz - oz, tx - ox)
    -- Match Lục Mạch's radius and orbital speed. Start the first sword behind
    -- the player, then distribute the others around the full circle.
    local angle = heading + math.pi
        + (inst._stage_index - 1) * 2 * math.pi / inst._stage_count
        + (GetTime() - inst._stage_started) * SWORD_ORBIT_SPEED
    local x = ox + math.cos(angle) * SWORD_SPAWN_RADIUS
    local z = oz + math.sin(angle) * SWORD_SPAWN_RADIUS
    inst.Transform:SetPosition(x, oy + 1.2, z)
    inst._heading = math.atan2(tz - z, tx - x)
    FaceFlightDirection(inst)
end

local function UpdateOrbitSword(inst)
    local owner, weapon = inst._owner, inst._source_weapon
    if not IsLivingOwner(owner) or (not inst._temporary and not IsValid(weapon)) then
        inst:Remove()
        return
    end

    local ox, oy, oz = owner.Transform:GetWorldPosition()
    local angle = GetTime() * SWORD_ORBIT_SPEED + (inst._element - 1) * math.pi / 3
    local orbit_x = ox + math.cos(angle) * SWORD_SPAWN_RADIUS
    local orbit_z = oz + math.sin(angle) * SWORD_SPAWN_RADIUS
    local x, y, z = inst.Transform:GetWorldPosition()
    local dt = FRAMES

    if inst._orbit_state == "ready" then
        if not IsLivingTarget(inst._target) then
            inst:Remove()
            return
        end
        StageSwordAroundOwner(inst, owner, inst._target)
        if GetTime() >= inst._launch_at then
            inst._origin_x, inst._origin_z = ox, oz
            inst._elapsed = 0
            inst._orbit_state = "flight"
        end
        return
    end

    if inst._orbit_state == "flight" then
        local target = inst._target
        inst._elapsed = inst._elapsed + dt
        if not IsLivingTarget(target) or Rules.IsExpired(inst._elapsed, FLIGHT_TIMEOUT)
            or (x - inst._origin_x) ^ 2 + (z - inst._origin_z) ^ 2 > MAX_FLIGHT_RANGE ^ 2 then
            CompleteSwordAttack(inst, false)
            return
        end
        local tx, ty, tz = target.Transform:GetWorldPosition()
        local dx, dz = tx - x, tz - z
        local hit_range = HIT_DISTANCE
            + (target.GetPhysicsRadius ~= nil and target:GetPhysicsRadius(0) or 0)
        if dx * dx + dz * dz <= hit_range * hit_range then
            CompleteSwordAttack(inst, true)
            return
        end
        local nx, nz, heading, arrived = Rules.Step(
            x, z, inst._heading, tx, tz, dt, FLIGHT_SPEED, TURN_RATE
        )
        inst._heading = heading
        inst.Transform:SetPosition(nx, y + (ty - y) * .15, nz)
        FaceFlightDirection(inst)
        if arrived then
            CompleteSwordAttack(inst, true)
        end
        return
    end

    if inst._orbit_state == "return" then
        local dx, dz = orbit_x - x, orbit_z - z
        local distance = math.sqrt(dx * dx + dz * dz)
        if distance > .3 then
            local step = math.min(FLIGHT_SPEED * dt, distance)
            inst.Transform:SetPosition(x + dx / distance * step,
                y + (oy + 1.2 - y) * .2, z + dz / distance * step)
            inst._heading = math.atan2(dz, dx)
            FaceFlightDirection(inst)
            return
        end
        inst._orbit_state = "orbit"
    end

    inst.Transform:SetPosition(orbit_x, oy + 1.2, orbit_z)
    inst._heading = angle + math.pi / 2
    FaceFlightDirection(inst)
end

local function BindOrbitSword(inst, owner, weapon)
    if not IsLivingOwner(owner) or not IsValid(weapon) then return false end
    inst._owner = owner
    inst._source_weapon = weapon
    inst._element = inst._element_index
    inst._orbit_state = "orbit"
    local ox, oy, oz = owner.Transform:GetWorldPosition()
    local angle = GetTime() * SWORD_ORBIT_SPEED + (inst._element - 1) * math.pi / 3
    inst.Transform:SetPosition(ox + math.cos(angle) * SWORD_SPAWN_RADIUS,
        oy + 1.2, oz + math.sin(angle) * SWORD_SPAWN_RADIUS)
    inst._heading = angle + math.pi / 2
    FaceFlightDirection(inst)
    inst._update_task = inst:DoPeriodicTask(FRAMES, UpdateOrbitSword, 0)
    return true
end

local function LaunchSingleSword(inst, data)
    if type(data) ~= "table" or not IsLivingOwner(data.owner)
        or not IsLivingTarget(data.target) or type(data.damage) ~= "number" then
        inst:Remove()
        return
    end
    inst._owner = data.owner
    inst._source_weapon = data.weapon
    inst._element = data.element or inst._element_index
    inst._damage = data.damage
    inst._apply_impact = data.apply_impact ~= false
    inst._temporary = true
    inst._orbit_state = data.stage and "ready" or "flight"
    inst._elapsed = 0
    local ox, oy, oz = data.owner.Transform:GetWorldPosition()
    local tx, _, tz = data.target.Transform:GetWorldPosition()
    inst._origin_x, inst._origin_z = ox, oz
    inst._target = data.target
    local base_heading = math.atan2(tz - oz, tx - ox)
    local center = ((data.count or 1) + 1) / 2
    local side = (data.index or 1) - center
    if math.abs(side) < .01 then
        side = inst._element % 2 == 0 and 1 or -1
    end
    if data.stage then
        inst._stage_index = data.index or 1
        inst._stage_count = math.max(1, data.count or 1)
        inst._stage_started = GetTime()
        inst._launch_at = inst._stage_started + .55
            + ((data.index or 1) - 1) * SWORD_LAUNCH_INTERVAL
        StageSwordAroundOwner(inst, data.owner, data.target)
        inst._update_task = inst:DoPeriodicTask(FRAMES, UpdateOrbitSword, 0)
        return
    end
    local fan = side * .42
    if math.abs(fan) < .65 then fan = fan < 0 and -.65 or .65 end
    inst._heading = base_heading + fan
    inst.Transform:SetPosition(ox - math.sin(base_heading) * side * .5,
        oy + 1.2, oz + math.cos(base_heading) * side * .5)
    FaceFlightDirection(inst)
    inst._update_task = inst:DoPeriodicTask(FRAMES, UpdateOrbitSword, 0)
end

local function StrikeFromOrbit(inst, target, damage)
    if inst._orbit_state ~= "orbit" or not IsLivingTarget(target) then return false end
    local owner = inst._owner
    if not IsLivingOwner(owner) then return false end
    local x, _, z = inst.Transform:GetWorldPosition()
    local tx, _, tz = target.Transform:GetWorldPosition()
    local ox, _, oz = owner.Transform:GetWorldPosition()
    inst._origin_x, inst._origin_z = ox, oz
    inst._target = target
    inst._damage = damage
    inst._elapsed = 0
    inst._heading = math.atan2(tz - z, tx - x)
    inst._orbit_state = "flight"
    FaceFlightDirection(inst)
    return true
end

local function MakeTrail(index)
    local envelope = "ttk_lucnguyen_trail_colour_" .. tostring(index)
    local initialized = false
    local colour = ELEMENTS[index].colour
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst:AddTag("FX")
        inst:AddTag("NOCLICK")
        inst.persists = false
        if TheNet:IsDedicated() then return inst end
        if not initialized then
            EnvelopeManager:AddColourEnvelope(envelope, {
                { 0, { colour[1], colour[2], colour[3], .8 } },
                { 1, { colour[1] * .4, colour[2] * .4, colour[3] * .4, 0 } },
            })
            initialized = true
        end
        local effect = inst.entity:AddVFXEffect()
        effect:InitEmitters(1)
        effect:SetRenderResources(0, "fx/sparkle.tex", "shaders/vfx_particle_add.ksh")
        effect:SetUVFrameSize(0, .25, 1)
        effect:SetMaxNumParticles(0, 40)
        effect:SetMaxLifetime(0, .3)
        effect:SetColourEnvelope(0, envelope)
        effect:SetBlendMode(0, BLENDMODE.Additive)
        effect:EnableBloomPass(0, true)
        effect:SetLayer(0, LAYER_GROUND)
        effect:SetSortOrder(0, 1)
        EmitterManager:AddEmitter(inst, nil, function()
            effect:AddParticle(0, .3, 0, .2, 0, 0, 0, 0)
        end)
        return inst
    end
    return Prefab("ttk_lucnguyen_trail_" .. tostring(index), fn)
end

local function MakeSword(index)
    local element = ELEMENTS[index]
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank(element.bank)
        inst.AnimState:SetBuild(element.build)
        inst.AnimState:PlayAnimation(element.anim, true)
        -- These Tu Tiên sword sprites are drawn on the ground plane. Without
        -- this orientation the trail renders, but the sword body disappears.
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLightOverride(.25)
        inst.AnimState:SetScale(1.1, 1.1, 1.1)
        inst:AddTag("FX")
        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")
        inst.persists = false
        inst._element_index = index
        inst._tip_rotation = element.tip_rotation
        inst._trail_prefab = "ttk_lucnguyen_trail_" .. tostring(index)
        if not TheNet:IsDedicated() then
            inst:DoTaskInTime(0, function(sword)
                if sword:IsValid() then sword:SpawnChild(sword._trail_prefab) end
            end)
        end
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end
        inst.Launch = LaunchSingleSword
        inst.Bind = BindOrbitSword
        inst.Strike = StrikeFromOrbit
        return inst
    end
    return Prefab("ttk_lucnguyen_sword_" .. tostring(index), fn, assets, prefabs)
end

local function StopSummons(weapon)
    if weapon._art_task ~= nil then
        weapon._art_task:Cancel()
        weapon._art_task = nil
    end
    local proxy = weapon._lucmach_proxy
    weapon._lucmach_proxy = nil
    if IsValid(proxy) then
        proxy.summon_controller:OnUnequip()
        proxy:Desummon()
        proxy:Remove()
    end
    local owner = weapon._equipped_owner
    if IsValid(owner) then
        owner.lucmachthankiem_auto_attack = weapon._previous_lucmach_auto_attack
    end
    weapon._previous_lucmach_auto_attack = nil
    if weapon._auto_attack_task ~= nil then
        weapon._auto_attack_task:Cancel()
        weapon._auto_attack_task = nil
    end
    if weapon._launch_tasks ~= nil then
        for _, task in ipairs(weapon._launch_tasks) do task:Cancel() end
        weapon._launch_tasks = nil
    end
    if weapon._summons ~= nil then
        for _, sword in ipairs(weapon._summons) do
            if IsValid(sword) then sword:Remove() end
        end
        weapon._summons = nil
    end
    weapon._equipped_owner = nil
end

CommandVolley = function(weapon, target, already_charged)
    local proxy = IsValid(weapon) and weapon._lucmach_proxy or nil
    if not IsValid(proxy) or not IsLivingTarget(target) then return false end
    proxy:Attack(weapon._equipped_owner, target)
    return true
end

local function AutoAttack(weapon)
    local owner = weapon._equipped_owner
    if not IsLivingOwner(owner) or weapon._auto_attack_enabled == false then return end
    if GetTime() < (weapon._next_volley_at or 0) then return end
    local targets = Elements.CollectEnemies(owner, owner, 24, nil, 1)
    if targets[1] ~= nil then CommandVolley(weapon, targets[1]) end
end

local function GiveSummonElement(proxy, summon, owner, weapon, index)
    -- Lục Mạch resolves hits through each summon's real_weapon. Give each
    -- sword its own weapon so the existing hit timing triggers the matching
    -- Lục Nguyên status without a second direct hit.
    local real = CreateEntity()
    real.entity:AddTransform()
    real.entity:SetParent(proxy.entity)
    real:AddTag("NOCLICK")
    real:AddTag("NOBLOCK")
    real:AddTag("weapon")
    real.persists = false
    real.damage_mult = proxy.real_weapon.damage_mult
    real:AddComponent("weapon")
    local base = TUNING.LUCMACHTHANKIEM_DAMAGE or BASE_DAMAGE
    real.components.weapon:SetDamage(base)
    real.components.weapon:SetOnAttack(function(_, attacker, target)
        if IsLivingOwner(owner) and IsValid(target) then
            Elements.ApplySwordStatus(owner, target, base / #ELEMENTS,
                weapon, index)
        end
    end)
    real:AddComponent("planardamage")
    real.components.planardamage:SetBaseDamage(
        TUNING.LUCMACHTHANKIEM_PLANARDAMAGE or 0)
    summon.real_weapon = real
end

local function StartSummons(weapon, owner)
    if not TheWorld.ismastersim or not IsLivingOwner(owner) then return end
    StopSummons(weapon)
    weapon._equipped_owner = owner
    weapon._auto_attack_enabled = owner._ttk_vankiem_auto_attack ~= false
    weapon._previous_lucmach_auto_attack = owner.lucmachthankiem_auto_attack
    owner.lucmachthankiem_auto_attack = weapon._auto_attack_enabled
    -- Use Lục Mạch's summon controller and attack state graph, with wider
    -- orbit positions and full Tu Tiên sword art.
    local proxy = SpawnPrefab("lucmachthankiem")
    if proxy == nil then
        StopSummons(weapon)
        return
    end
    weapon._lucmach_proxy = proxy
    proxy.persists = false
    proxy:AddTag("NOCLICK")
    proxy.Transform:SetPosition(owner.Transform:GetWorldPosition())
    -- Update the proxy's centre in the same tick as its orbit positions.
    -- The old independent periodic task could run one frame apart, making
    -- large summoned swords and their shadows visibly jump while moving.
    local controller = proxy.summon_controller
    local original_update_surround = controller.UpdateSurround
    controller.UpdateSurround = function(self, dt)
        if IsLivingOwner(owner) then
            self.inst.Transform:SetPosition(owner.Transform:GetWorldPosition())
        end
        original_update_surround(self, dt)
        local cx, _, cz = self.inst.Transform:GetWorldPosition()
        for _, position in ipairs(self.positions) do
            position.x = cx + (position.x - cx) * VANKIEM_ORBIT_RADIUS / LUCMACH_ORBIT_RADIUS
            position.z = cz + (position.z - cz) * VANKIEM_ORBIT_RADIUS / LUCMACH_ORBIT_RADIUS
        end
    end
    -- Lục Mạch switches to a separate behind-the-player formation above a
    -- movement speed threshold. Keep this weapon's six swords on one orbit.
    controller.GetFollowPos = controller.GetSurroundingPos
    proxy.AnimState:SetMultColour(1, 1, 1, 0)
    if proxy.Light ~= nil then proxy.Light:Enable(false) end
    if proxy.Physics ~= nil then proxy.Physics:ClearCollisionMask() end
    if proxy.components.inventoryitem ~= nil then
        proxy.components.inventoryitem.canbepickedup = false
    end
    proxy.equip_owner = owner
    proxy.summon_controller:OnEquip(owner)
    proxy:SetSummonCount(#ELEMENTS)
    for index = 1, #ELEMENTS do
        local sword = proxy.summons[index]
        if IsValid(sword) then GiveSummonElement(proxy, sword, owner, weapon, index) end
    end
    weapon._art_task = weapon:DoPeriodicTask(.2, function(inst)
        local controller = inst._lucmach_proxy
        if not IsValid(controller) then return end
        controller.AnimState:SetMultColour(1, 1, 1, 0)
        if controller.Light ~= nil then controller.Light:Enable(false) end
        for index = 1, #ELEMENTS do
            local sword = controller.summons[index]
            if IsValid(sword) then
                sword.AnimState:SetBuild(string.format("ttk_vankiem_magic_%03d", index))
                sword.AnimState:SetScale(2, 2, 2)
                -- The original glow remains available to its state graph,
                -- but should not wash out the detailed sword texture.
                sword.AnimState:SetSymbolMultColour("glow", 1, 1, 1, .25)
            end
        end
    end, 0)
end

local function OnPrimaryThrown(inst)
    inst.AnimState:PlayAnimation("idle", true)
    inst:AddTag("NOCLICK")
    inst.persists = false
end

local function OnPrimaryPreHit(inst, attacker, target)
    Bridge.BeginPrimary(attacker, target, inst, inst, inst._base_damage or BASE_DAMAGE)
end

local function OnPrimaryHit(inst, attacker, target)
    local context = Bridge.EndPrimary(inst)
    local weapon = inst._source_weapon
    if context ~= nil and IsValid(weapon) then
        Bridge.LaunchVolley(context.owner, context.target, context.base_damage,
            nil, function(data)
                data.weapon = weapon
                data.stage = true
                local sword = SpawnPrefab("ttk_lucnguyen_sword_"
                    .. tostring(data.element))
                if sword ~= nil then sword:Launch(data) end
            end)
    end
    local impact = SpawnPrefab("impact")
    if impact ~= nil then impact.Transform:SetPosition(target.Transform:GetWorldPosition()) end
    inst:Remove()
end

local function OnPrimaryMiss(inst)
    Bridge.CancelPrimary(inst)
    inst:Remove()
end

local function PrimaryProjectileFn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    inst.AnimState:SetBank("ttk_lucnguyen_fx")
    inst.AnimState:SetBuild("ttk_lucng3")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetScale(.35, .35, .35)
    inst.AnimState:SetLightOverride(.25)
    inst:AddTag("projectile")
    inst:AddTag("NOCLICK")
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(BASE_DAMAGE)
    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(60)
    inst.components.projectile:SetRange(30)
    inst.components.projectile:SetOnPreHitFn(OnPrimaryPreHit)
    inst.components.projectile:SetOnHitFn(OnPrimaryHit)
    inst.components.projectile:SetOnMissFn(OnPrimaryMiss)
    inst.components.projectile.has_damage_set = true
    inst:ListenForEvent("onthrown", OnPrimaryThrown)
    return inst
end

local function OnEquip(inst, owner)
    if inst:HasTag("ttk_vankiemquytong") then
        owner.AnimState:OverrideSymbol("swap_object", "ttk_vkwgm_swap", "swap_daogam")
    else
        owner.AnimState:OverrideSymbol("swap_object", "ttk_lucng2", "swap")
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function OnEquipVanKiem(inst, owner)
    OnEquip(inst, owner)
    StartSummons(inst, owner)
    if TheWorld.ismastersim and owner.player_classified ~= nil
        and owner.player_classified.equip_ttk_vankiem ~= nil then
        owner.player_classified.equip_ttk_vankiem:set(true)
    end
end

local function OnUnequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function OnUnequipVanKiem(inst, owner)
    OnUnequip(inst, owner)
    if TheWorld.ismastersim then StopSummons(inst) end
    if TheWorld.ismastersim and owner.player_classified ~= nil
        and owner.player_classified.equip_ttk_vankiem ~= nil then
        owner.player_classified.equip_ttk_vankiem:set(false)
    end
end

local function OnProjectileLaunched(inst, attacker, target, projectile)
    if projectile == nil then return end
    local uses = inst.components.finiteuses
    if uses == nil or uses:GetUses() <= 0 then
        projectile:Remove()
        return
    end
    -- Apply once to the launch snapshot, leaving Solo's weapon base untouched.
    -- Summoned swords use the same enhanced damage basis when they attack.
    local damage = Bridge.DamageSnapshot(inst, attacker, target)
        * (1 + (inst._ttk_ritual_level or 0) * 0.05)
    if not projectile._ttk_lucnguyen_charge_consumed then
        projectile._ttk_lucnguyen_charge_consumed = true
        uses:Use(1)
    end
    projectile._base_damage = damage
    projectile._source_weapon = inst
    projectile.components.weapon:SetDamage(damage)
    if target ~= nil and target.Transform ~= nil and attacker ~= nil
        and attacker.Transform ~= nil then
        local x, _, z = attacker.Transform:GetWorldPosition()
        local tx, _, tz = target.Transform:GetWorldPosition()
        local heading = math.atan2(tz - z, tx - x)
        projectile.Transform:SetRotation(-heading / DEGREES - 90)
    end
    -- Retain the shooter directly. Projectile:Throw initially stores the held
    -- weapon as owner, which loses attribution if that weapon is transferred
    -- or removed before impact.
    projectile.components.projectile.owner = attacker
end

local function CanRepair(inst, item, giver, count)
    return item ~= nil and item.prefab == "xd_lingshi1"
        and (count == nil or count == 1)
        and inst.components.finiteuses:GetUses() < MAX_USES
end

local function OnRepair(inst, giver)
    inst.components.finiteuses:Repair(REPAIR_USES)
    if giver ~= nil and giver.SoundEmitter ~= nil then
        giver.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
    end
end

local function WeaponFn(is_vankiem)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", .05, { .75, .5, .75 })
    inst.AnimState:SetBank(is_vankiem and "ttk_vankiem_king" or "ttk_lucnguyen_hh")
    inst.AnimState:SetBuild(is_vankiem and "ttk_vkwgm" or "ttk_lucng2")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetScale(.7, .7, .7)
    inst:AddTag("weapon")
    inst:AddTag("rangedweapon")
    inst:AddTag("sharp")
    inst:AddTag("alltrader")
    if is_vankiem then inst:AddTag("ttk_vankiemquytong") end
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(is_vankiem and VANKIEM_BASE_DAMAGE or BASE_DAMAGE)
    inst.components.weapon:SetRange(24, 26)
    if is_vankiem then
        inst.components.weapon:SetOnAttack(function(weapon, attacker, target)
            CommandVolley(weapon, target)
        end)
    else
        inst.components.weapon:SetProjectile("ttk_lucnguyen_primary_projectile")
        inst.components.weapon:SetOnProjectileLaunched(OnProjectileLaunched)
    end

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(MAX_USES)
    inst.components.finiteuses:SetUses(MAX_USES)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    local image_name = is_vankiem and "ttk_vankiemquytong" or "ttk_lucnguyenkiemdong"
    inst.components.inventoryitem.atlasname =
        "images/inventoryimages/" .. image_name .. ".xml"
    inst.components.inventoryitem.imagename = image_name

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(is_vankiem and OnEquipVanKiem or OnEquip)
    inst.components.equippable:SetOnUnequip(is_vankiem and OnUnequipVanKiem or OnUnequip)

    inst:AddComponent("trader")
    inst.components.trader.acceptnontradable = true
    inst.components.trader:SetAbleToAcceptTest(CanRepair)
    inst.components.trader.onaccept = OnRepair

    inst.TTKApplyRitualLevel = SetRitualLevel
    if is_vankiem then
        inst.Attack = function(self, doer, target)
            if self._equipped_owner == doer then return CommandVolley(self, target) end
            return false
        end
        inst.SetAutoAttack = function(self, enabled)
            self._auto_attack_enabled = enabled ~= false
            if IsValid(self._equipped_owner) then
                self._equipped_owner.lucmachthankiem_auto_attack = self._auto_attack_enabled
            end
        end
    end
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    SetRitualLevel(inst, 0)
    if is_vankiem then inst:ListenForEvent("onremove", StopSummons) end

    MakeHauntableLaunch(inst)
    return inst
end

local results = {
    Prefab("ttk_lucnguyenkiemdong", function() return WeaponFn(false) end, assets, prefabs),
    Prefab("ttk_vankiemquytong", function() return WeaponFn(true) end, assets, prefabs),
    Prefab("ttk_lucnguyen_primary_projectile", PrimaryProjectileFn, assets, prefabs),
}
for index = 1, #ELEMENTS do
    table.insert(results, MakeSword(index))
    table.insert(results, MakeTrail(index))
end
return unpack(results)
