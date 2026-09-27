local CritterCommon = require "prefabs/duppercritter/chasni_critters_common"

-- chasni_critter_atops
local function atops_spellfn(inst)
    inst:DoTaskInTime(0.5, function()
        local gems = { yellowgem = 0.035, orangegem = 0.035, greengem = 0.035, purplegem = 0.15, redgem = 0.37, bluegem = 0.37, opalpreciousgem = 0.005, }
        local x, y, z = inst.Transform:GetWorldPosition()
        local gem = chasni_spawnprefab(weighted_random_choice(gems), x, y, z,  0.5, 0.5, 0.5)
        gem.AnimState:SetFinalOffset(-1)
        inst.blobfx.KillFX(inst.blobfx)
    end)
end
-- chasni_critter_bee
local ONEOF_TAGS = { "plant", "lichen", "oceanvine", "mushroom_farm", "kelp", "silviculture", "tree", "winter_tree"  }
local CANT_TAGS = { "magicgrowth", "player", "FX", "leif", "pickable", "stump", "withered", "barren", "INLIMBO", "ancienttree" }
local function MaximizePlant(inst)
    if inst.components.farmplantstress ~= nil then
        if inst.components.farmplanttendable then
            inst.components.farmplanttendable:TendTo()
        end

        inst.magic_tending = true
        local _x, _y, _z = inst.Transform:GetWorldPosition()
        local x, y = TheWorld.Map:GetTileCoordsAtPoint(_x, _y, _z)

        local nutrient_consumption = inst.plant_def.nutrient_consumption
        TheWorld.components.farming_manager:AddTileNutrients(x, y, nutrient_consumption[1]*6, nutrient_consumption[2]*6, nutrient_consumption[3]*6)
    end
end
local function trygrowth(inst, maximize)
    if not inst:IsValid() or inst:IsInLimbo() or (inst.components.witherable ~= nil and inst.components.witherable:IsWithered()) then
        return
    end
    MaximizePlant(inst)
    if inst.components.growable ~= nil then
        if inst.components.growable.magicgrowable or ((inst:HasTag("tree") or inst:HasTag("winter_tree")) and not inst:HasTag("stump")) then
            if inst.components.simplemagicgrower ~= nil then
                inst.components.simplemagicgrower:StartGrowing()
            elseif inst.components.growable.domagicgrowthfn ~= nil then
                inst.magic_growth_delay = maximize and 2 or nil
                inst.components.growable:DoMagicGrowth()
            else
                return inst.components.growable:DoGrowth()
            end
        end
    end

    if inst.components.pickable ~= nil then
        if inst.components.pickable:CanBePicked() and inst.components.pickable.caninteractwith then
            return
        end
        if inst.components.pickable:FinishGrowing() then
            inst.components.pickable:ConsumeCycles(1) -- magic grow is hard on plants
            return
        end
    end

    if inst.components.crop ~= nil and (inst.components.crop.rate or 0) > 0 then
        if inst.components.crop:DoGrow(1 / inst.components.crop.rate, true) then
            return
        end
    end

    if inst.components.harvestable ~= nil and inst.components.harvestable:CanBeHarvested() and inst:HasTag("mushroom_farm") then
        if inst.components.harvestable:IsMagicGrowable() then
            inst.components.harvestable:DoMagicGrowth()
            return
        else
            if inst.components.harvestable:Grow() then
                return
            end
        end

    end
end
local function bee_spellfn(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local range = 30
    local _ents = TheSim:FindEntities(x, y, z, range, nil, CANT_TAGS, ONEOF_TAGS)
    local ents = {}

    for k,v in pairs(_ents) do
        if v.components.pickable or v.components.crop or v.components.growable or v.components.harvestable then
            table.insert (ents, v)
        end
    end

    if #ents > 0 then
        trygrowth(table.remove(ents, math.random(#ents)))
        if #ents > 0 then
            local timevar = 1 - 1 / (#ents + 1)
            for i, v in ipairs(ents) do
                v:DoTaskInTime(timevar * math.random(), trygrowth)
            end
        end
    end
    inst:DoTaskInTime(1, function()
        inst.blobfx.KillFX(inst.blobfx)
    end)
end
-- chasni_critter_bug
local BUG_PROJECTILE_PREFAB="chasni_critter_bug_proj"
local function shotProj(inst, target)
    if target and target:IsValid() then
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
        local x, y, z = inst.Transform:GetWorldPosition()
        local projectile = chasni_spawnprefab(BUG_PROJECTILE_PREFAB, x, y, z)
        inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast"))
        if projectile then
            projectile.owner = inst
            if projectile.components.projectile ~= nil then
                projectile.components.projectile:Throw(inst, target)
            else
                projectile:Remove()
            end
        end
    end
end
local function bug_spellfn(inst)
    local target = inst.components.combat and inst.components.combat.target
    if target then
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
        if inst.prefab == "chasni_critter_bug_a" then
            inst:DoTaskInTime(0.7, function() shotProj(inst, target) end)
            inst:DoTaskInTime(1.2, function() shotProj(inst, target) end)
            inst:DoTaskInTime(1.3, function()
                inst.blobfx.KillFX(inst.blobfx)
            end)
        else
            inst:DoTaskInTime(0.7, function() shotProj(inst, target) end)
            inst:DoTaskInTime(0.8, function() shotProj(inst, target) end)
            inst:DoTaskInTime(0.9, function()
                inst.blobfx.KillFX(inst.blobfx)
            end)
        end
    else
        inst.blobfx.KillFX(inst.blobfx)
    end
end
-- chasni_critter_crab
local function crab_spellfn(inst)
    inst:DoTaskInTime(1, function()
        local x, y, z = inst.Transform:GetWorldPosition()
        local range = inst:calculateSpellValue()
        local players = FindPlayersInRange(x, y, z, range)
        for _, player in ipairs(players) do
            if player and player:IsValid() then
                player:AddDebuff("chasni_critter_crab_shield_buff", "chasni_critter_crab_shield_buff")
            end
        end
        inst.blobfx.KillFX(inst.blobfx)
    end)
    if inst.prefab == "chasni_critter_crab_b" then
        inst:DoTaskInTime(0, function() inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast_b")) end)
        inst:DoTaskInTime(0.3, function() inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast_b2")) end)
        inst:DoTaskInTime(0.5, function() inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast_b2")) end)
        inst:DoTaskInTime(0.6, function() inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast_b2")) end)
        inst:DoTaskInTime(0.7, function() inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast_b2")) end)
        inst:DoTaskInTime(0.8, function() inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast_b2")) end)
        inst:DoTaskInTime(1.1, function() inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast_b2")) end)
        inst:DoTaskInTime(1.2, function() inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast_b2")) end)
        inst:DoTaskInTime(1.5, function() inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast_b2")) end)
        inst:DoTaskInTime(1.6, function() inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast_b2")) end)
        inst:DoTaskInTime(1.7, function() inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast_b2")) end)
        inst:DoTaskInTime(1.8, function() inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast_b2")) end)
    end
end
-- chasni_critter_dog
local DOG_RADIUS = 6
local function dog_spellfn(inst)
    local target = inst.components.follower and inst.components.follower:GetLeader()
    if target then
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
        inst:DoTaskInTime(0.5, function(_inst)
            local x, y, z = target.Transform:GetWorldPosition()
            chasni_spawnprefab("chasni_tooth_green2", x, y, z)
            local heal = inst:calculateSpellValue()
            local ents = TheSim:FindEntities(x, y, z, DOG_RADIUS)
            for _, v in pairs(ents) do
                if v.components.health and not v:HasTag("playerghost") then
                    local isplayerorcompanion = v:HasTag("player") or v:HasTag("companion")
                    local isfollower =
                    v.components.follower and v.components.follower.leader ~= nil and v.components.follower.leader:HasTag("player")
                    if isplayerorcompanion or isfollower then
                        v.components.health:DoDelta(heal)
                        chasni_spawnprefab("chasni_blast_green", 0, 0, 0, 1, 1, 1, v.entity)
                    end
                end
            end

            inst.blobfx.KillFX(inst.blobfx)
        end)
    else
        inst.blobfx.KillFX(inst.blobfx)
    end
end
-- chasni_critter_dog_pink
local DOG_PINK_RADIUS = 6
local function dog_pink_spellfn(inst)
    local target = inst.components.combat and inst.components.combat.target
    if target then
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
        inst:DoTaskInTime(0.5, function(_inst)
            local x, y, z = target.Transform:GetWorldPosition()
            chasni_spawnprefab("chasni_tooth_pink2", x, y, z)
            local damage = inst:calculateSpellValue()
            chasni_doaoedamage(x, y, z, DOG_PINK_RADIUS, nil, nil, _inst, damage, nil, true, "chasni_blast_pink")

            inst.blobfx.KillFX(inst.blobfx)
        end)
    else
        inst.blobfx.KillFX(inst.blobfx)
    end
end
-- chasni_critter_driller
local DRILLER_RANGE = 10
local function driller_cancastfn(inst)
    return TheWorld:HasTag("cave")
end
local function driller_spellfn(inst)
    inst:DoTaskInTime(0.5, function()
        if TheWorld:HasTag("cave") then
            local x, y, z = inst.Transform:GetWorldPosition()
            local statincrease = inst:calculateSpellValue()
            local players = FindPlayersInRange(x, y, z, DRILLER_RANGE)
            for _, player in ipairs(players) do
                if player and player.components.health then
                    player.components.health:DoDelta(statincrease)
                end
                if player and player.components.hunger then
                    player.components.hunger:DoDelta(statincrease)
                end
                if player and player.components.sanity then
                    player.components.sanity:DoDelta(statincrease)
                end
            end
        end
        inst.blobfx.KillFX(inst.blobfx)
    end)
end
-- chasni_critter_fish_burn
local FISH_BURN_RADIUS = 2
local CANT_BURN_TAGS = {"FX", "NOCLICK", "INLIMBO", "DECOR", "wet"}
local function fish_burn_spellfn(inst)
    local target = inst.components.combat and inst.components.combat.target
    if target then
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
        inst:DoTaskInTime(0.1, function(_inst)
            local x, y, z = target.Transform:GetWorldPosition()
            chasni_spawnprefab("pyro_fire_fx", x, y, z)
            local damage = inst:calculateSpellValue()
            chasni_doaoedamage(x, y, z, FISH_BURN_RADIUS, {"fire"}, nil, _inst, damage, nil, true)
            local ents = TheSim:FindEntities(x, y, z, FISH_BURN_RADIUS, nil, CANT_BURN_TAGS)
            for _, v in ipairs(ents) do
                if v.components.fueled == nil and v.components.burnable and not v.components.burnable:IsBurning() and not v:HasTag("burnt") then
                    v.components.burnable:Ignite()
                end
                v.components.burnable:Ignite()
            end

            _inst.blobfx.KillFX(inst.blobfx)
        end)
    else
        inst.blobfx.KillFX(inst.blobfx)
    end
end
-- chasni_critter_fish_wet
local FISH_WET_RADIUS = 2
local FISH_WET_DURATION = 12
local CANT_WET_TAGS = {"FX", "NOCLICK", "INLIMBO", "DECOR"}
local function do_water_wetting(target, duration)
    if target.waterspearwet_endtime and target.waterspearwet_endtime - GetTime() > duration then
        return
    end
    if target._waterspearwet_task then
        target._waterspearwet_task:Cancel()
        target._waterspearwet_task = nil
    end
    target.waterspearwet_endtime = GetTime() + duration
    target:Chasni_AddTag("wet")
    target._waterspearwet_task = target:DoTaskInTime(duration, function(_target)
        _target._waterspearwet_task = nil
        _target:Chasni_RemoveTag("wet")
    end)
end
local function fish_wet_spellfn(inst)
    local target = inst.components.combat and inst.components.combat.target
    if target then
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
        inst:DoTaskInTime(0.1, function(_inst)
            local x, y, z = target.Transform:GetWorldPosition()
            chasni_spawnprefab("big_water_splash", x, y, z)
            local damageorwetness = inst:calculateSpellValue()
            chasni_doaoedamage(x, y, z, FISH_WET_RADIUS, {"wet"}, nil, _inst, damageorwetness, nil, true)
            if _inst.components.wateryprotection then
                _inst.components.wateryprotection.addwetness = damageorwetness
                _inst.components.wateryprotection:SpreadProtectionAtPoint(x, y, z)
            end
            local ents = TheSim:FindEntities(x, y, z, FISH_WET_RADIUS, nil, CANT_WET_TAGS)
            for _, v in ipairs(ents) do
                do_water_wetting(v, FISH_WET_DURATION)
            end

            _inst.blobfx.KillFX(inst.blobfx)
        end)
    else
        inst.blobfx.KillFX(inst.blobfx)
    end
end
-- chasni_critter_light
local LIGHT_RADIUS = 6
local function light_attackfn(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    chasni_spawnprefab("chasni_blink_fx", x, y, z)
    local stafflight = chasni_spawnprefab("staff_castinglight_small", x, y, z)
    stafflight:SetUp({ 1, 1, 1 }, 1, 0.1)

    inst:DoTaskInTime(0.85, function()
        if inst.components.combat then
            inst.components.combat:DoAreaAttack(stafflight, LIGHT_RADIUS, nil, function(target, attacker)
                if target == attacker or attacker.components.combat:IsAlly(target) then
                    return false
                end
                local leader = attacker.components.follower and attacker.components.follower:GetLeader()
                if leader and target and target.components.combat and not target.components.combat:TargetIs(leader) and target.components.combat:CanTarget(leader) then
                    target.components.combat:SetTarget(leader)
                end
                chasni_spawnprefab("chasni_blink_fx2", 0, 0, 0, nil, nil, nil, target.entity)
                return true
            end)
        end
    end)
end
-- chasni_critter_mamo
local MAMO_RADIUS = 5.5
local function mamo_attackfn(inst)
    if inst.prefab == "chasni_critter_mamo_a" then
        inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast"))
    end
    local delay = inst.prefab == "chasni_critter_mamo_a" and 1.2 or 0.3
    inst:DoTaskInTime(delay, function(_inst)
        if _inst.components.combat and _inst.components.groundpounder then
            _inst.components.groundpounder:GroundPound()
            if inst.prefab == "chasni_critter_mamo_a" then
                inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "attack"))
            end
        end
    end)
end
local function mamo_spellfn(inst)
    if inst.prefab == "chasni_critter_mamo_a" then
        inst:DoTaskInTime(0.2, function() inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast")) end)
        inst:DoTaskInTime(0.5, function() inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast")) end)
        inst:DoTaskInTime(0.6, function() inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast")) end)
        inst:DoTaskInTime(0.7, function() inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "cast")) end)
    end
    inst:DoTaskInTime(1, function(_inst)
        local x, y, z = _inst.Transform:GetWorldPosition()
        chasni_spawnprefab("smallbluefx_ring", x, y, z)
        local coldness = inst.prefab == "chasni_critter_mamo_a" and 1 or 3
        local frozentime = inst:calculateSpellValue()
        local ents = TheSim:FindEntities(x, y, z, MAMO_RADIUS, { "freezable" }, { "FX", "NOCLICK", "DECOR", "INLIMBO", "player" })
        for _, v in pairs(ents) do
            if v.components.freezable then
                v.components.freezable:AddColdness(coldness, frozentime)
            end
        end
        if inst.prefab == "chasni_critter_mamo_b" then
            inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, "attack0"))
        end
        _inst.blobfx.KillFX(inst.blobfx)
    end)
end
-- chasni_critter_moo
local MOO_RADIUS = 5.5
local MOO_TICK = 1.25
local function StartSingRing(inst, ringfx, effectfn)
    inst:DoTaskInTime(0, function(_inst)
        _inst.singringfx = chasni_spawnprefab(ringfx, 0, 0, 0, 1, 1, 1, _inst.entity)

        _inst.soundtask = _inst:DoTaskInTime(5, function() _inst.SoundEmitter:PlaySound(_inst:getSound(_inst.prefab == "chasni_critter_moo" and "cast1" or "cast2")) end)
        if _inst.singringtask then
            _inst.singringtask:Cancel()
            _inst.singringtask = nil
        end
        _inst.singringtask = _inst:DoPeriodicTask(MOO_TICK, function()
            local x, y, z = _inst.Transform:GetWorldPosition()
            local value = _inst:calculateSpellValue()
            effectfn(_inst, x, y, z, value)
        end)

        local function OnNewState(__inst)
            if __inst.soundtask then
                __inst.soundtask:Cancel()
                __inst.soundtask = nil
            end
            if __inst.singringtask then
                __inst.singringtask:Cancel()
                __inst.singringtask = nil
            end
            if __inst.singringfx then
                __inst.singringfx:RemoveFX()
            end
            __inst:RemoveEventCallback("newstate", OnNewState)
        end

        _inst:ListenForEvent("newstate", OnNewState)
        _inst.blobfx.KillFX(inst.blobfx)
    end)
end
local function moo_spellfn(inst)
    StartSingRing(inst, "orbit_sing_greenfx", function(_inst, x, y, z, value)
        chasni_doaoeheal(x, y, z, MOO_RADIUS, nil, nil, _inst, value, false, "chasni_sing_green_fx")
    end)
end
local function moodeng_spellfn(inst)
    StartSingRing(inst, "orbit_sing_blackfx", function(_inst, x, y, z, value)
        chasni_doaoedamage(x, y, z, MOO_RADIUS, nil, nil, _inst, value, nil, true, "chasni_sing_black_fx")
    end)
end
-- chasni_critter_mosq
local MOSQ_RADIUS = 5.5
local function mosq_onhitother_buff(inst, data)
    if data and data.damageresolved and data.damageresolved > 0 and data.target and inst.components.health and not inst.components.health:IsDead() and inst.mosq_lifestealvalue and inst.mosq_lifestealvalue > 0 and chasni_isLifeDrainable(data.target) then
        inst.components.health:DoDelta(data.damageresolved * (inst.mosq_lifestealvalue / 100))
        inst.mosq_lifestealvalue = nil
        inst:RemoveDebuff("critter_mosq_buff")
        inst:RemoveEventCallback("onhitother", mosq_onhitother_buff)
    end
end
local function mosq_spellfn(inst)
    inst:DoTaskInTime(1.5, function(_inst)
        local x, y, z = _inst.Transform:GetWorldPosition()
        local lifestealvalue = _inst:calculateSpellValue()
        local ents = TheSim:FindEntities(x, y, z, MOSQ_RADIUS, { "_combat" }, { "INLIMBO", "FX", "playerghost" })
        for _, v in pairs(ents) do
            if v.components.health and (v:HasTag("player") or chasni_friendpet(v) or chasni_ownpet(v, _inst)) then
                v:AddDebuff("critter_mosq_buff", "critter_mosq_buff")
                v.mosq_lifestealvalue = lifestealvalue
                v:RemoveEventCallback("onhitother", mosq_onhitother_buff)
                v:ListenForEvent("onhitother", mosq_onhitother_buff)
            end
        end
        _inst.blobfx.KillFX(_inst.blobfx)
    end)
end
local function mosq_onhitother(inst, data)
    if data.target and chasni_isLifeDrainable(data.target) then
        local leader = inst.components.follower and inst.components.follower:GetLeader()
        local lifesteal = inst.calculatePassiveValue and inst:calculatePassiveValue() or nil
        if leader and leader.components.health and lifesteal and lifesteal > 0 then
            leader.components.health:DoDelta(lifesteal)
        end
    end
end
-- chasni_critter_puff
local function puff_activatefn(inst, doer)
    inst.sg:GoToState("cast")
    if doer then
        inst:DoTaskInTime(1, function(_inst)
            local stat = inst:calculateSpellValue()
            if _inst.prefab == "chasni_critter_puff_health_a" or _inst.prefab == "chasni_critter_puff_health_b" then
                if doer.components.health then
                    doer.components.health:DoDelta(stat)
                end
            elseif _inst.prefab == "chasni_critter_puff_hunger_a" or _inst.prefab == "chasni_critter_puff_hunger_b" then
                if doer.components.hunger then
                    doer.components.hunger:DoDelta(stat)
                end
            elseif _inst.prefab == "chasni_critter_puff_sanity_a" or _inst.prefab == "chasni_critter_puff_sanity_b" then
                if doer.components.sanity then
                    doer.components.sanity:DoDelta(stat)
                end
            elseif _inst.prefab == "chasni_critter_puff_insanity_a" or _inst.prefab == "chasni_critter_puff_insanity_b" then
                if doer.components.sanity then
                    doer.components.sanity:DoDelta(-stat)
                end
            end
        end)
    end
end
local function puff_cancast(inst)
    return not inst._alternateform
end
local function puff_spellfn(inst)
    if inst._alternateform then
        inst._alternateform = false
        inst.components.activatable.inactive = false
        inst:DoTaskInTime(0.5, function(_inst)
            _inst.SoundEmitter:PlaySound(_inst:getSound(nil, nil, "cast3"))
        end)
    else
        inst._alternateform = true
        inst:DoTaskInTime(0.5, function(_inst)
            _inst.SoundEmitter:PlaySound(_inst:getSound(nil, nil, "cast2"))
            _inst.components.activatable.inactive = true
            _inst.blobfx.KillFX(_inst.blobfx)
        end)
    end
end
-- chasni_critter_raptor
local RAPTOR_RADIUS = 5.5
local function ShootSpreadProjectile(inst, target, angleoffset)
    local x, y, z = inst.Transform:GetWorldPosition()
    local tx, ty, tz = target.Transform:GetWorldPosition()
    local dir = Vector3(tx - x, 0, tz - z):GetNormalized()
    local angle = math.atan2(dir.z, dir.x) + angleoffset * DEGREES
    local distance = 8
    local targetpos = Vector3(x + math.cos(angle) * distance, 0, z + math.sin(angle) * distance)

    local dart = chasni_spawnprefab("chasni_critter_raptor_proj",x, y, z)
    if dart and dart.components.projectile then
        dart.components.projectile:Chasni_AimedThrow(inst, inst, targetpos, 100, true)
    end
end
local function raptor_attackfn(inst, target)
    inst:DoTaskInTime(0.5, function(_inst)
        if target then
            ShootSpreadProjectile(_inst, target, -15)
            ShootSpreadProjectile(_inst, target, 0)
            ShootSpreadProjectile(_inst, target, 15)
        end
    end)
end
local function raptor_spellfn(inst)
    inst:DoTaskInTime(1, function(_inst)
        local x, y, z = _inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, RAPTOR_RADIUS, { "_combat" }, { "INLIMBO", "FX", "playerghost" })
        for _, v in pairs(ents) do
            if v.components.health and (v:HasTag("player") or chasni_friendpet(v) or chasni_ownpet(v, _inst)) then
                v:AddDebuff("critter_raptor_buff", "critter_raptor_buff")
            end
        end
        _inst.blobfx.KillFX(_inst.blobfx)
    end)
end
-- chasni_critter_wool
local WOOL_PROJECTILE_PREFAB="chasni_critter_wool_proj"
local function ShootMultiProjectile(inst, target)
    local x, y, z = inst.Transform:GetWorldPosition()
    local projectile = chasni_spawnprefab(WOOL_PROJECTILE_PREFAB, x, y, z)
    if projectile then
        projectile.owner = inst
        if projectile.components.projectile ~= nil then
            projectile.components.projectile:Throw(inst, target)
        else
            projectile:Remove()
        end
    end
end
local function wool_attackfn(inst, target)
    if target and target:IsValid() then
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
        inst:DoTaskInTime(0, function(_inst)
            ShootMultiProjectile(inst, target)
        end)
        inst:DoTaskInTime(0.2, function(_inst)
            _inst.SoundEmitter:PlaySound(_inst:getSound("attack"))
            ShootMultiProjectile(inst, target)
        end)
    end
end
-- chasni_critter_seal
local SEAL_RADIUS = 5.5
local SEAL_DURATION = 8
local function seal_spellfn(inst)
    inst:DoTaskInTime(1, function(_inst)
        local x, y, z = _inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, SEAL_RADIUS, { "_combat" }, { "INLIMBO", "FX", "playerghost" })
        local misschance = _inst:calculateSpellValue()
        for _, v in pairs(ents) do
            if _inst ~= v and (v:HasTag("player") or chasni_friendpet(v) or chasni_ownpet(v, _inst)) then
                chasni_addtimedbuff(v, "critter_seal_buff", SEAL_DURATION)
                v._sealmisschance = misschance
            end
        end
        _inst.blobfx.KillFX(_inst.blobfx)
    end)
end
-- chasni_critter_slug
local function slug_xp_spellfn(inst)
    inst:DoTaskInTime(0.5, function(_inst)
        local target = _inst.components.follower and _inst.components.follower:GetLeader()
        if target.components.levelsystem then
            local xp = _inst:calculateSpellValue()
            target.components.levelsystem:xpDoDelta(xp, target, false, true)
            chasni_spawnprefab("chasni_neuron_blast", 0, 2, 0, nil, nil, nil, target.entity)
        end
        _inst.blobfx.KillFX(_inst.blobfx)
    end)
end
-- chasni_critter_stego
local STEGO_RADIUS = 6
local STEGO_SPELL_RAD = 5.5
local function stego_attackfn(inst)
    inst:DoTaskInTime(0.3, function()
        if inst.components.combat then
            inst.components.combat:DoAreaAttack(inst, STEGO_RADIUS, nil, function(target, attacker)
                if chasni_isincone(target, attacker) then
                    local leader = attacker.components.follower and attacker.components.follower:GetLeader()
                    if leader and target and target.components.combat and not target.components.combat:TargetIs(leader) and target.components.combat:CanTarget(leader) then
                        target.components.combat:SetTarget(leader)
                    end
                    return true
                end
                return false
            end)
        end
    end)
end
local function stego_onattacked_buff(inst, data)
    if (data and data.damageresolved and data.attacker and not data.redirected) then
        if data.attacker.components.health and not data.attacker.components.health:IsDead() and data.attacker.components.combat and inst._stego_damage_reflect and inst._stego_damage_reflect > 0 then
            data.attacker.components.combat:GetAttacked(inst, data.damageresolved * (inst._stego_damage_reflect / 100))
        end
        inst:RemoveDebuff("critter_stego_buff")
        inst:RemoveEventCallback("attacked", stego_onattacked_buff)
        inst._stego_damage_reflect = nil
    end
end
local function stego_spellfn(inst)
    inst:DoTaskInTime(1, function() inst.SoundEmitter:PlaySound(inst:getSound("cast")) end)
    inst:DoTaskInTime(1.2, function() inst.SoundEmitter:PlaySound(inst:getSound("cast")) end)
    inst:DoTaskInTime(1.5, function(_inst)
        local x, y, z = _inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, STEGO_SPELL_RAD, { "_combat" }, { "INLIMBO", "FX", "playerghost" })
        local reflect = inst:calculateSpellValue()
        for _, v in pairs(ents) do
            if v.components.health and (v:HasTag("player") or chasni_friendpet(v) or chasni_ownpet(v, _inst)) then
                v:AddDebuff("critter_stego_buff", "critter_stego_buff")
                v:RemoveEventCallback("attacked", stego_onattacked_buff)
                v:ListenForEvent("attacked", stego_onattacked_buff)
                v._stego_damage_reflect = reflect
            end
        end
        _inst.blobfx.KillFX(_inst.blobfx)
    end)
end
-- chasni_critter_worm
local WORM_RADIUS = 12
local function worm_spellfn(inst)
    local target = inst.components.combat and inst.components.combat.target
    if target then
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
        inst:DoTaskInTime(4, function(_inst)
            _inst.SoundEmitter:PlaySound(_inst:getSound(nil, nil, "cast"))
            local x, y, z = _inst.Transform:GetWorldPosition()
            local damage = _inst:calculateSpellValue()
            chasni_spawnprefab("cyanfx_ring", x, y, z)
            chasni_doaoedamage(x, y, z, WORM_RADIUS, nil, nil, _inst, 0, nil, true, { "chasni_explosion_magic_green_fx1", "chasni_explosion_magic_green_fx2" }, {planar=damage,})

            inst.blobfx.KillFX(inst.blobfx)
        end)
    else
        inst.blobfx.KillFX(inst.blobfx)
    end
end
-- chasni_critter_elecfish
local ELECFISH_RADIUS = 5.5
local ELECFISH_DURATION = 8
local function elecfish_onhitother_buff(inst, data)
    if data and data.target then
        SpawnElectricHitSparks(data.projectile and data.projectile:IsValid() and data.projectile or inst, data.target, true)
    end
end
local function elecfish_spellfn(inst)
    inst:DoTaskInTime(1, function(_inst)
        local x, y, z = _inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, ELECFISH_RADIUS, { "_combat" }, { "INLIMBO", "FX", "playerghost" })
        for _, v in pairs(ents) do
            if (v:HasTag("player") or chasni_friendpet(v) or chasni_ownpet(v, _inst)) then
                chasni_addtimedbuff(v, "critter_elecfish_buff", ELECFISH_DURATION, function(target)
                    if target.components.electricattacks then
                        target.components.electricattacks:RemoveSource("critter_elecfish_buff")
                    end
                    target:RemoveEventCallback("onhitother", elecfish_onhitother_buff)
                end)
                if v.components.electricattacks == nil then
                    v:AddComponent("electricattacks")
                end
                v.components.electricattacks:AddSource("critter_elecfish_buff")

                v:RemoveEventCallback("onhitother", elecfish_onhitother_buff)
                v:ListenForEvent("onhitother", elecfish_onhitother_buff)
            end
        end
        _inst.blobfx.KillFX(_inst.blobfx)
    end)
end
-- chasni_critter_fugu
local function fugu_activatefn(inst)
    inst.components.activatable.inactive = false
    CritterCommon.StopCastLoop(inst)
    inst.SoundEmitter:PlaySound(inst:getSound("cast2"))
    inst:DoTaskInTime(0.7, function(_inst)
        local product = "chasni_fish_roe"
        local prd = SpawnPrefab(product)
        local pt = Vector3(_inst.Transform:GetWorldPosition()) + Vector3(0,2,0)
        prd.Transform:SetPosition(pt:Get())
        local down = TheCamera:GetDownVec()
        local angle = math.atan2(down.z, down.x) + (math.random()*60)*DEGREES
        local sp = 3 + math.random()
        prd.Physics:SetVel(sp*math.cos(angle), math.random()*2+8, sp*math.sin(angle))
    end)
end
local function fugu_spellfn(inst)
    inst:DoTaskInTime(1, function(_inst)
        _inst.components.activatable.inactive = true
        _inst.blobfx.KillFX(_inst.blobfx)
        _inst.SoundEmitter:PlaySound(_inst:getSound(nil, nil, "cast"))
    end)
end
-- chasni_critter_seahorse
local SEAHORSE_RANGE = 10
local function seahorse_aurafind(x, y, z, radius, inst)
    local targets = {}
    local ents = FindPlayersInRange(x, y, z, radius)
    for _, v in ipairs(ents) do
        local mount = v and v.components.rider and v.components.rider:IsRiding() and v.components.rider:GetMount()
        if mount and mount.components.rideable then
            table.insert(targets, mount)
        end
    end

    return targets
end
local function seahorse_cancastfn(inst)
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    return leader and leader.components.rider and leader.components.rider:IsRiding()
end
local function seahorse_spellfn(inst)
    inst:DoTaskInTime(0.5, function()
        local x, y, z = inst.Transform:GetWorldPosition()
        local statincrease = inst:calculateSpellValue()
        local players = FindPlayersInRange(x, y, z, SEAHORSE_RANGE)
        for _, player in ipairs(players) do
            local mount = player and player.components.rider and player.components.rider:IsRiding() and player.components.rider:GetMount()
            if mount and mount.components.health then
                mount.components.health:DoDelta(statincrease)
            end
            if mount and mount.components.hunger then
                mount.components.hunger:DoDelta(statincrease)
            end
        end
        inst.blobfx.KillFX(inst.blobfx)
    end)
end
-- chasni_critter_turtle
local TURTLE_A_DURATION = 4
local TURTLE_B_DURATION = 7
local function turtle_stopcastfn(inst)
    inst:RemoveDebuff("critter_turtle_buff_self")
    inst.components.buffaura:RemoveAura("chasni_critter_turtle_aura_buff_active")
    inst._maxcastlooptime = nil
    inst.SoundEmitter:PlaySound(inst:getSound("cast2"))
    CritterCommon.StopCastLoop(inst)
end
local function turtle_spellfn(inst)
    inst._maxcastlooptime = (inst.prefab == "chasni_critter_turtle_a" and TURTLE_A_DURATION or TURTLE_B_DURATION) +1 -- +1 second because DoTaskInTime(1)
    inst:DoTaskInTime(1, function(_inst)
        _inst:AddDebuff("critter_turtle_buff_self", "critter_turtle_buff_self")
        _inst.components.buffaura:AddAura("chasni_critter_turtle_aura_buff_active", "chasni_critter_turtle_aura_buff_active", 6)
        _inst.blobfx.KillFX(_inst.blobfx)
    end)
end
local function turtle_attackfn(inst, target)
    local targetpos = target:GetPosition()
    local slash = SpawnPrefab("chasni_critter_turtle_proj")
    slash.Transform:SetPosition((inst:GetPosition()):Get())
    slash.components.projectile:Chasni_AimedThrow(inst, inst, targetpos, 100, true)
    slash.components.projectile:DelayVisibility(4 * FRAMES)
    --slash:DoPeriodicTask(1, function()
    --    if slash.components.projectile then
    --        slash.components.projectile.hit_targets = {}
    --    end
    --end)
end

-- chasni_critter_squid
local SQUID_RANGE = 10
local function squid_cancastfn(inst)
    return not TheWorld:HasTag("cave") and not inst:IsOnValidGround()
end
local function squid_spellfn(inst)
    if inst.prefab == "chasni_critter_squid_b" then
        inst.SoundEmitter:PlaySound(inst:getSound("cast_b"))
    end

    inst:DoTaskInTime(0.5, function()
        if not TheWorld:HasTag("cave") and not inst:IsOnValidGround() then
            local x, y, z = inst.Transform:GetWorldPosition()
            local statincrease = inst:calculateSpellValue()
            local players = FindPlayersInRange(x, y, z, SQUID_RANGE)
            for _, player in ipairs(players) do
                if player and player.components.health then
                    player.components.health:DoDelta(statincrease)
                end
                if player and player.components.hunger then
                    player.components.hunger:DoDelta(statincrease)
                end
                if player and player.components.sanity then
                    player.components.sanity:DoDelta(statincrease)
                end
            end
        end
        inst.blobfx.KillFX(inst.blobfx)
    end)
end
local function squid_a_attack(inst, target)
    local x, y, z = inst.Transform:GetWorldPosition()
    chasni_spawnprefab("chasni_squid_ink_fx", x, y + 1.5, z)
    local pos = target:GetPosition()
    local dir
    if pos ~= nil then
        inst:ForceFacePoint(pos)
        dir = inst.Transform:GetRotation() * DEGREES
    else
        dir = inst.Transform:GetRotation() * DEGREES
        pos = Vector3(x + 8 * math.cos(dir), 0, z - 8 * math.sin(dir))
    end

    local targets = {} --shared table for the whole patch of particles
    local proj = SpawnPrefab("squid_proj")
    proj.Physics:Teleport(x, y, z)
    proj.targets = targets
    proj.components.complexprojectile:Launch(pos, inst)
end
local function squid_b_attackfn(inst, target)
    squid_a_attack(inst, target)
    inst:DoTaskInTime(0.3, function()
        squid_a_attack(inst, target)
    end)
    inst:DoTaskInTime(0.6, function()
        squid_a_attack(inst, target)
    end)
end
-- chasni_critter_bot
local function FxOnUpdate(inst, dt)
    inst.t = inst.t + dt
    if inst.t < 0.5 then
        local k = 1 - inst.t / 0.5
        k = k * k
        inst.AnimState:SetMultColour(1, 1, 1, k)
        k = (2 - 1.7 * k) * (inst.scalemult or 1)
        inst.AnimState:SetScale(k, k)
    else
        inst:Remove()
    end
end
local function CreateDomeFX()
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("chasni_barrier")
    inst.AnimState:SetBuild("chasni_barrier")
    inst.AnimState:PlayAnimation("barrier_dome")
    inst.AnimState:SetMultColour(0, 0, 0, 0.1)
    inst.AnimState:SetFinalOffset(7)

    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(FxOnUpdate)
    inst.t = 0
    FxOnUpdate(inst, 0)

    return inst
end
local function CLIENT_TriggerFX(inst)
    local fx = CreateDomeFX()
    fx.entity:SetParent(inst.entity)
end
local function bot_onaccepttradefn(inst)
    if inst.memorycolor == "blue" then
        inst.components.raindome:Enable()
        inst.triggerfx:push()
        if not TheNet:IsDedicated() then
            CLIENT_TriggerFX(inst)
        end
    else
        inst.components.raindome:Disable()
    end
    if inst.memorycolor == "red" then
        inst:AddTag("cooker")
    else
        inst:RemoveTag("cooker")
    end
    if inst.memorycolor == "brown" then
        inst.components.container.canbeopened = true
    else
        inst.components.container.canbeopened = false
        inst.components.container:Close()
    end
end
local BOT_RADIUS = 12
local function bot_cancastfn(inst)
    if inst.memorycolor == "yellow" then
        return CritterCommon.CanSpellOnCombat(inst)
    end
    if inst.memorycolor == "pink" then
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, BOT_RADIUS, { "playerghost" })
        return #ents > 0
    end
    return false
end
local function bot_spellfn(inst)
    if inst.memorycolor == "yellow" then
        local x, y, z = inst.Transform:GetWorldPosition()
        chasni_spawnprefab("yellowfx_ring", x, y, z)
        inst:DoTaskInTime(0.2, function(_inst)
            inst.components.combat:DoAreaAttack(inst, BOT_RADIUS, nil, function(target, attacker)
                if target == attacker or attacker.components.combat:IsAlly(target) then
                    return false
                end
                local leader = attacker.components.follower and attacker.components.follower:GetLeader()
                if leader and target and target.components.combat and not target.components.combat:TargetIs(leader) and target.components.combat:CanTarget(leader) then
                    target.components.combat:SetTarget(leader)
                end
                return true
            end)
        end)
    elseif inst.memorycolor == "pink" then
        local x, y, z = inst.Transform:GetWorldPosition()
        chasni_spawnprefab("pinkfx_ring", x, y, z)
        local ents = TheSim:FindEntities(x, y, z, BOT_RADIUS, { "playerghost" })
        for _, v in ipairs(ents) do
            local announcement_string = v:GetDisplayName().." "..STRINGS.UI.HUD.REZ_ANNOUNCEMENT.." "..inst:GetDisplayName().."."
            TheNet:AnnounceResurrect(announcement_string, inst.entity)
            v:PushEvent("respawnfromghost", { source = inst })
        end
    end
    inst.memorycolor = "white"
    if inst.ResetBotBank then
        inst:ResetBotBank()
    end
    inst:DoTaskInTime(0.5, function()
        inst.blobfx.KillFX(inst.blobfx)
    end)
end
local function bot_attackfn(inst)
    inst:DoTaskInTime(0.8, function()
        if inst.components.combat then
            local x, _, z = inst.Transform:GetWorldPosition()
            local bombprefab = inst.memorycolor == "green" and "chasni_botbombbig" or "chasni_botbomb"
            local bomb = chasni_spawnprefab(bombprefab, x, 2, z)
            if bomb and bomb.components.explosive then
                bomb.components.explosive:SetAttacker(inst)
            end
        end
    end)
end
-- 480 = 1 day
return
CritterCommon.MakeBuilder("chasni_critter_atops_a"),
--region ATOPS
CritterCommon.MakeCritter(
        "chasni_critter_atops_a",
        {speed=3,ev="diemeteor", walkvolume=0.25},
        {
            dmg     = 5,
            range   = 1.5,
            cd      = 30,
            mincd   = 7,
        },
        {
            spellcd = TUNING.TOTAL_DAY_TIME * 3,
            minspellcd = TUNING.TOTAL_DAY_TIME * 2,
            canfn = CritterCommon.AlwaysSpell,
            spellfn = atops_spellfn,
        },
        {walk="floor_floor_1_0_loop", atk="eat_pre", cast="poop"},
        {bank="atops"}
),
CritterCommon.MakeCritter(
        "chasni_critter_atops_b",
        {speed=3.5,nosleep=true, walkvolume=0.3},
        {
            dmg     = 10,
            range   = 2,
            cd      = 30,
            mincd   = 7,
        },
        {
            spellcd = TUNING.TOTAL_DAY_TIME * 2,
            minspellcd = TUNING.TOTAL_DAY_TIME,
            canfn = CritterCommon.AlwaysSpell,
            spellfn = atops_spellfn,
        },
        {walk="floor_floor_1_0_loop", atk="eat_pre", cast="fart", },
        {bank="atops"}
),
--endregion
--region BEE
CritterCommon.MakeBuilder("chasni_critter_bee_a"),
CritterCommon.MakeCritter(
        "chasni_critter_bee_a",
        {speed=2,haveinventory=1,ev="honeymaster"},
        {
            dmg     = 1,
            range   = 1.5,
            cd      = 30,
            mincd   = 7,
        },
        {
            spellcd = TUNING.TOTAL_DAY_TIME * 3,
            minspellcd = TUNING.TOTAL_DAY_TIME * 2,
            canfn = CritterCommon.AlwaysSpell,
            spellfn = bee_spellfn,
        },
        {atk="hit", castpre="call_pre", cast="call_pst", hoppre="drown_pre", hoploop="drown_loop", hoppst="drown_pst", sink="drown_loop", sink="drown_loop", pick="hit", },
        {bank="bee", cast="cast2", pick="pick"}
),
CritterCommon.MakeCritter(
        "chasni_critter_bee_b",
        {speed=6,nosleep=true, haveinventory=1, flying=true, loopsound="walk_b"},
        {
            dmg     = 5,
            range   = 2,
            cd      = 30,
            mincd   = 7,
        },
        {
            spellcd = TUNING.TOTAL_DAY_TIME * 2,
            minspellcd = TUNING.TOTAL_DAY_TIME,
            canfn = CritterCommon.AlwaysSpell,
            spellfn = bee_spellfn,
        },
        {walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", atk="hit", castpre="mining_pre", cast="mining_loop", castpst="mining_pst", pick="hit", },
        {bank="bee", walk="", pick="pick"}
),
--endregion
--region BUG
CritterCommon.MakeBuilder("chasni_critter_bug_a"),
CritterCommon.MakeCritter(
        "chasni_critter_bug_a",
        {speed=3,ev="craftnet"},
        {
            dmg     = 5,
            range   = 1.5,
            cd      = 30,
            mincd   = 7,
        },
        {
            passivepower = 1, -- percentage
            maxpassivepower = 5,
            spellcd = 60,
            minspellcd = 40,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = bug_spellfn,
        },
        {atk="eat_pre", castpre="call_pre", cast="call_loop", castpst="call_pst", },
        {bank="bug", cast="", }
),
CritterCommon.MakeCritter(
        "chasni_critter_bug_b",
        {speed=3.5,nosleep=true},
        {
            dmg     = 10,
            range   = 2,
            cd      = 20,
            mincd   = 3,
        },
        {
            passivepower = 1, -- percentage
            maxpassivepower = 20,
            spellcd = 40,
            minspellcd = 20,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = bug_spellfn,
        },
        {atk="hit", cast="escape", },
        {bank="bug", cast="",}
),
--endregion
--region CRAB
CritterCommon.MakeBuilder("chasni_critter_crab_a"),
CritterCommon.MakeCritter(
        "chasni_critter_crab_a",
        {speed=3, aurabuff="chasni_critter_crab_aura_buff", aurafind=CritterCommon.AllyTargeting,ev="friendrocky"},
        {
            dmg     = 1,
            range   = 8,
            cd      = 30,
            mincd   = 7,
            delay   = 0.5,
            proj    = "chasni_critter_crab_proj",
        },
        {
            spellpower = 4,
            spellpowerincrease = 1,
            passivepower = 1, -- percentage
            maxpassivepower = 15,
            spellcd = 120,
            minspellcd = 60,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = crab_spellfn,
        },
        {atk="poop", castpre="call_pre", cast="call_loop", castpst="call_pst", },
        {bank="crab"}
),
CritterCommon.MakeCritter(
        "chasni_critter_crab_b",
        {speed=3.5,nosleep=true, aurabuff="chasni_critter_crab_aura_buff", aurafind=CritterCommon.AllyTargeting},
        {
            dmg     = 50,
            range   = 4,
            cd      = 30,
            mincd   = 3,
            delay   = 0.5,
        },
        {
            spellpower = 3,
            spellpowerincrease = 1,
            passivepower = 5, -- percentage
            maxpassivepower = 35,
            spellcd = 80,
            minspellcd = 30,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = crab_spellfn,
        },
        {atkpre="slap_pre", atk="slap", atkpst="slap_pst", castpre="clean_water_pre", cast="clean_water_loop", castpst="clean_water_pst", },
        {bank="crab", attack="attack_b", cast=""}
),
--endregion
--region DOG
CritterCommon.MakeBuilder("chasni_critter_dog_a"),
CritterCommon.MakeCritter(
        "chasni_critter_dog_a",
        {speed=3.5, aurabuff="chasni_critter_dog_aura_buff", aurafind=CritterCommon.EnemyTargeting,ev="dance"},
        {
            dmg     = 4,
            range   = 10,
            cd      = 50,
            mincd   = 7,
            delay   = 1,
            proj    = "chasni_critter_dog_proj",
        },
        {
            spellpower = 5,
            spellpowerincrease = 1,
            passivepower = 1, -- percentage
            maxpassivepower = 15,
            spellcd = 60,
            minspellcd = 30,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = dog_spellfn,
        },
        {atk="poop", cast="incubator_variant", },
        {bank="dog"}
),
CritterCommon.MakeCritter("chasni_critter_dog_b",
        {speed=4,nosleep=true, aurabuff="chasni_critter_dog_aura_buff", aurafind=CritterCommon.EnemyTargeting},
        {
            dmg     = 10,
            range   = 10,
            cd      = 40,
            mincd   = 3,
            proj    = "chasni_critter_dog_proj",
        },
        {
            spellpower = 10,
            spellpowerincrease = 1,
            passivepower = 5, -- percentage
            maxpassivepower = 35,
            spellcd = 50,
            minspellcd = 15,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = dog_spellfn,
        },
        {atk="waiting_pre", atkpst="waiting_pst", cast="excited_loop", },
        {bank="dog"}
),
CritterCommon.MakeBuilder("chasni_critter_dog_pink_a"),
CritterCommon.MakeCritter(
        "chasni_critter_dog_pink_a",
        {speed=3.5, aurabuff="chasni_critter_dog_pink_aura_buff", aurafind=CritterCommon.EnemyTargeting,ev="dance"},
        {
            dmg     = 4,
            range   = 10,
            cd      = 50,
            mincd   = 7,
            delay   = 1,
            proj    = "chasni_critter_dog_pink_proj",
        },
        {
            spellpower = 5,
            spellpowerincrease = 1,
            passivepower = 1,
            passivepowerincrease = 0.5,
            spellcd = 60,
            minspellcd = 30,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = dog_pink_spellfn,
        },
        {atk="poop", cast="incubator_variant", },
        {bank="dog"}
),
CritterCommon.MakeCritter("chasni_critter_dog_pink_b",
        {speed=4,nosleep=true, aurabuff="chasni_critter_dog_pink_aura_buff", aurafind=CritterCommon.EnemyTargeting},
        {
            dmg     = 10,
            range   = 10,
            cd      = 40,
            mincd   = 3,
            proj    = "chasni_critter_dog_pink_proj",
        },
        {
            spellpower = 10,
            spellpowerincrease = 1,
            passivepower = 1,
            passivepowerincrease = 1,
            spellcd = 50,
            minspellcd = 15,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = dog_pink_spellfn,
        },
        {atk="waiting_pre", atkpst="waiting_pst", cast="excited_loop", },
        {bank="dog"}
),
--endregion
--region DRILLER
CritterCommon.MakeBuilder("chasni_critter_driller_a"),
CritterCommon.MakeCritter("chasni_critter_driller_a",
        {speed=3.5,nosleep=true, aurabuff="chasni_critter_driller_aura_buff", passiveaurarange=true,ev="bigworm"},
        {
            dmg     = 7,
            range   = 8,
            cd      = 40,
            mincd   = 7,
            proj    = "chasni_critter_driller_proj",
        },
        {
            spellpower = 1,
            spellpowerincrease = 0.1,
            passivepower = 3,
            passivepowerincrease = 0.1,
            spellcd = 300,
            minspellcd = 100,
            canfn = driller_cancastfn,
            spellfn = driller_spellfn,
        },
        {atk="hit", cast="poop", hoppre="floor_floor_1_0_pre", hoploop="floor_floor_1_0_loop", hoppst="floor_floor_1_0_pst", },
        {bank="driller"}
),
CritterCommon.MakeCritter("chasni_critter_driller_b",
        {speed=3.5,nosleep=true, aurabuff="chasni_critter_driller_aura_buff", passiveaurarange=true},
        {
            dmg     = 25,
            range   = 8,
            cd      = 30,
            mincd   = 3,
            proj    = "chasni_critter_driller_proj",
        },
        {
            spellpower = 10,
            spellpowerincrease = 0.2,
            passivepower = 4,
            passivepowerincrease = 0.2,
            spellcd = 120,
            minspellcd = 60,
            canfn = driller_cancastfn,
            spellfn = driller_spellfn,
        },
        {atk="hit", cast="poop", hoppre="floor_floor_1_0_pre", hoploop="floor_floor_1_0_loop", hoppst="floor_floor_1_0_pst", },
        {bank="driller"}
),
--endregion
--region FISH
CritterCommon.MakeBuilder("chasni_critter_fish_burn_a"),
CritterCommon.MakeCritter("chasni_critter_fish_burn_a",
        {speed=3.5,nosleep=true,flying=true, aurabuff="chasni_critter_fish_burn_aura_buff", aurafind=CritterCommon.EnemyTargeting,ev="burn"},
        {
            dmg     = 5,
            range   = 8,
            cd      = 30,
            mincd   = 3,
            proj    = "chasni_critter_fish_burn_proj",
        },
        {
            spellpower = 5,
            spellpowerincrease = 1,
            passivepower = 5, -- percentage
            passivepowerincrease = 1,
            spellcd = 60,
            minspellcd = 30,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = fish_burn_spellfn,
        },
        {walkpre="swim_swim_1_0_pre", walkloop="swim_swim_1_0_loop", walkpst="swim_swim_1_0_pst", atk="poop", cast="poop", },
        {bank="fish"}
),
CritterCommon.MakeCritter("chasni_critter_fish_burn_b",
        {speed=4,nosleep=true,flying=true, aurabuff="chasni_critter_fish_burn_aura_buff", aurafind=CritterCommon.EnemyTargeting},
        {
            dmg     = 10,
            range   = 8,
            cd      = 30,
            mincd   = 3,
            proj    = "chasni_critter_fish_burn_proj",
        },
        {
            spellpower = 10,
            spellpowerincrease = 1,
            passivepower = 10, -- percentage
            passivepowerincrease = 2,
            spellcd = 40,
            minspellcd = 10,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = fish_burn_spellfn,
        },
        {walkpre="swim_swim_1_0_pre", walkloop="swim_swim_1_0_loop", walkpst="swim_swim_1_0_pst", atk="poop", cast="poop", },
        {bank="fish"}
),
CritterCommon.MakeBuilder("chasni_critter_fish_wet_a"),
CritterCommon.MakeCritter("chasni_critter_fish_wet_a",
        {speed=3.5,nosleep=true,flying=true,havewater=true, aurabuff="chasni_critter_fish_wet_aura_buff", aurafind=CritterCommon.EnemyTargeting,ev="drown"},
        {
            dmg     = 5,
            range   = 8,
            cd      = 30,
            mincd   = 3,
            proj    = "chasni_critter_fish_wet_proj",
        },
        {
            spellpower = 5,
            spellpowerincrease = 1,
            passivepower = 5, -- percentage
            passivepowerincrease = 1,
            spellcd = 60,
            minspellcd = 30,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = fish_wet_spellfn,
        },
        {walkpre="swim_swim_1_0_pre", walkloop="swim_swim_1_0_loop", walkpst="swim_swim_1_0_pst", atk="poop", cast="poop", },
        {bank="fish"}
),
CritterCommon.MakeCritter("chasni_critter_fish_wet_b",
        {speed=4,nosleep=true,flying=true,havewater=true, aurabuff="chasni_critter_fish_wet_aura_buff", aurafind=CritterCommon.EnemyTargeting},
        {
            dmg     = 10,
            range   = 8,
            cd      = 30,
            mincd   = 3,
            proj    = "chasni_critter_fish_wet_proj",
        },
        {
            spellpower = 10,
            spellpowerincrease = 1,
            passivepower = 10, -- percentage
            passivepowerincrease = 2,
            spellcd = 40,
            minspellcd = 10,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = fish_wet_spellfn,
        },
        {walkpre="swim_swim_1_0_pre", walkloop="swim_swim_1_0_loop", walkpst="swim_swim_1_0_pst", atk="poop", cast="poop", },
        {bank="fish"}
),
--endregion
--region LIGHT
CritterCommon.MakeBuilder("chasni_critter_light_off_a"),
CritterCommon.MakeCritter("chasni_critter_light_off_a",
        {speed=5,flying=true, loopsound="walk", aurabuff="chasni_critter_light_off_aura_buff", aurafind=CritterCommon.AllyTargeting,ev="death"},
        {
            dmg     = 1,
            range   = 5,
            cd      = 50,
            mincd   = 10,
            attackfn = light_attackfn,
        },
        {
            passivepower = 0.1,
            passivepowerincrease = 0.1,
        },
        {walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", atk="hatching_pst", castpre="call_pre", cast="call_loop", castpst="call_pst", },
        {bank="light", walk=""}
),
CritterCommon.MakeCritter("chasni_critter_light_off_b",
        {speed=5,flying=true, loopsound="walk", aurabuff="chasni_critter_light_off_aura_buff", aurafind=CritterCommon.AllyTargeting},
        {
            dmg     = 2,
            range   = 5,
            cd      = 40,
            mincd   = 7,
            attackfn = light_attackfn,
        },
        {
            passivepower = 0.1,
            passivepowerincrease = 0.1,
        },
        {walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", atk="hit", cast="excited_loop", sleeppre="grooming_pre", sleeploop="grooming_loop", sleeppst="grooming_pst", },
        {bank="light", walk=""}
),
CritterCommon.MakeBuilder("chasni_critter_light_on_a"),
CritterCommon.MakeCritter("chasni_critter_light_on_a",
        {speed=5,flying=true, loopsound="walk", aurabuff="chasni_critter_light_on_aura_buff", aurafind=CritterCommon.AllyTargeting,ev="revive"},
        {
            dmg     = 1,
            range   = 5,
            cd      = 50,
            mincd   = 10,
            attackfn = light_attackfn,
        },
        {
            passivepower = 0.1,
            passivepowerincrease = 0.1,
        },
        {walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", atk="hatching_pst", castpre="call_pre", cast="call_loop", castpst="call_pst", },
        {bank="light", walk=""}
),
CritterCommon.MakeCritter("chasni_critter_light_on_b",
        {speed=5,flying=true, loopsound="walk", aurabuff="chasni_critter_light_on_aura_buff", aurafind=CritterCommon.AllyTargeting},
        {
            dmg     = 2,
            range   = 5,
            cd      = 40,
            mincd   = 7,
            attackfn = light_attackfn,
        },
        {
            passivepower = 0.1,
            passivepowerincrease = 0.1,
        },
        {walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", atk="hit", cast="excited_loop", sleeppre="grooming_pre", sleeploop="grooming_loop", sleeppst="grooming_pst", },
        {bank="light", walk=""}
),
--endregion
--region MAMO
CritterCommon.MakeBuilder("chasni_critter_mamo_a"),
CritterCommon.MakeCritter("chasni_critter_mamo_a",
        {speed=3,haveground=true, aurabuff="chasni_critter_mamo_aura_buff", aurafind=CritterCommon.EnemyTargeting,ev="freeze"},
        {
            dmg     = 2,
            range   = 5,
            cd      = 50,
            mincd   = 10,
            attackfn = mamo_attackfn,
        },
        {
            spellpower = 1,
            spellpowerincrease = 0.1,
            passivepower = 1, -- percentage
            maxpassivepower = 20,
            spellcd = 80,
            minspellcd = 30,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = mamo_spellfn,
        },
        {walk="floor_floor_1_0_loop", hop="floor_floor_1_0_loop", atk="death", castpre="call_pre", cast="call_loop", castpst="call_pst", },
        {bank="mamo", attack="", cast=""}
),
CritterCommon.MakeCritter("chasni_critter_mamo_b",
        {speed=2.5,nosleep=true, haveground=true, aurabuff="chasni_critter_mamo_aura_buff", aurafind=CritterCommon.EnemyTargeting},
        {
            dmg     = 4,
            range   = 5,
            cd      = 40,
            mincd   = 7,
            attackfn = mamo_attackfn,
        },
        {
            spellpower = 2,
            spellpowerincrease = 0.1,
            passivepower = 2, -- percentage
            maxpassivepower = 40,
            spellcd = 60,
            minspellcd = 15,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = mamo_spellfn,
        },
        {atk="lay_egg_pst", cast="poop", },
        {bank="mamo", cast="cast_b"}
),
--endregion
--region MOO
CritterCommon.MakeBuilder("chasni_critter_moo"),
CritterCommon.MakeCritter("chasni_critter_moo",
        {speed=3,flying=true},
        {
            dmg     = 10,
            range   = 2,
            cd      = 40,
            mincd   = 3,
            delay   = 1.1,
        },
        {
            spellpower = 1,
            spellpowerincrease = 0.2,
            spellcd = 60,
            minspellcd = 15,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = moo_spellfn,
        },
        {walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", atkpre="drink_pre", atk="drink_loop", atkpst="drink_pst", castpre="beckoning_pre", cast="beckoning_loop", castpst="beckoning_pst", sleeppre="grooming_pre", sleeploop="grooming_loop", sleeppst="grooming_pst", },
        {bank="moo"}
),
CritterCommon.MakeBuilder("chasni_critter_moodeng"),
CritterCommon.MakeCritter("chasni_critter_moodeng",
        {speed=3,flying=true},
        {
            dmg     = 10,
            range   = 2,
            cd      = 40,
            mincd   = 3,
            delay   = 1.1,
        },
        {
            spellpower = 1,
            spellpowerincrease = 0.1,
            spellcd = 60,
            minspellcd = 15,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = moodeng_spellfn,
        },
        {walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", atkpre="drink_pre", atk="drink_loop", atkpst="drink_pst", castpre="diesel_beckoning_pre", cast="diesel_beckoning_loop", castpst="diesel_beckoning_pst", sleeppre="grooming_pre", sleeploop="grooming_loop", sleeppst="grooming_pst", },
        {bank="moo", }
),
--endregion
--region MOSQ
CritterCommon.MakeBuilder("chasni_critter_mosq_a"),
CritterCommon.MakeCritter("chasni_critter_mosq_a",
        {speed=3,flying=true, cannotattack=true,ev="waterballoon"},
        {
            dmg     = 0,
            range   = 1,
            cd      = 0,
            mincd   = 0,
        },
        {
            spellpower = 10, -- percentage
            spellpowerincrease = 1,
            spellcd = 60,
            minspellcd = 30,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = mosq_spellfn,
        },
        {walkpre="swim_swim_1_0_pre", walkloop="swim_swim_1_0_loop", walkpst="swim_swim_1_0_pst", atk="harvest", cast="flop_loop", },
        {bank="mosq"}
),
CritterCommon.MakeCritter("chasni_critter_mosq_b",
        {speed=5.5,nosleep=true, flying=true, onhitother=mosq_onhitother},
        {
            dmg     = 15,
            range   = 2,
            cd      = 50,
            mincd   = 3,
        },
        {
            spellpower = 20, -- percentage
            spellpowerincrease = 2,
            passivepower = 5,
            passivepowerincrease = 1,
            spellcd = 50,
            minspellcd = 20,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = mosq_spellfn,
        },
        {walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", atkpre="attack_pre", atk="attack_loop", atkpst="attack_pst", cast="cc_working_pre", castpst="cc_working_pst", },
        {bank="mosq", cast="cast_b", attackbank="dontstarve/creatures/mosquito/mosquito_attack"}
),
--endregion
--region PUFF
CritterCommon.MakeBuilder("chasni_critter_puff_health_a"),
CritterCommon.MakeCritter("chasni_critter_puff_health_a",
        {speed=4,activatefn = puff_activatefn, cannotattack=true, flying=true, aurabuff="chasni_critter_puff_health_aura_buff", aurafind=CritterCommon.AllyTargeting,ev="healtillweed"},
        {
            dmg     = 0,
            range   = 1,
            cd      = 0,
            mincd   = 0,
        },
        {
            spellpower = 10,
            spellpowerincrease = 0.1,
            passivepower = 1, -- percentage
            maxpassivepower = 20,
            spellcd = 480,
            minspellcd = 240,
            canfn = puff_cancast,
            spellfn = puff_spellfn,
        },
        {idle2="idle_loop_full", walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", walkpre2="hover_hover_1_0_pre_full", walkloop2="hover_hover_1_0_loop_full", walkpst2="walk_pst_full", castpre="inhale_pre", cast="inhale_loop", castpst2="inhale_pst", cast2="poop"},
        {bank="puft"}
),
CritterCommon.MakeCritter("chasni_critter_puff_health_b",
        {speed=4,nosleep=true,activatefn = puff_activatefn, cannotattack=true, flying=true, aurabuff="chasni_critter_puff_health_aura_buff", aurafind=CritterCommon.AllyTargeting},
        {
            dmg     = 0,
            range   = 1,
            cd      = 0,
            mincd   = 0,
        },
        {
            spellpower = 10,
            spellpowerincrease = 0.2,
            passivepower = 2, -- percentage
            maxpassivepower = 40,
            spellcd = 240,
            minspellcd = 120,
            canfn = puff_cancast,
            spellfn = puff_spellfn,
        },
        {idle2="idle_loop_full", walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", walkpre2="hover_hover_1_0_pre_full", walkloop2="hover_hover_1_0_loop_full", walkpst2="walk_pst_full", castpre="inhale_pre", cast="inhale_loop", castpst2="inhale_pst", cast2="poop"},
        {bank="puft"}
),
CritterCommon.MakeBuilder("chasni_critter_puff_hunger_a"),
CritterCommon.MakeCritter("chasni_critter_puff_hunger_a",
        {speed=4,activatefn = puff_activatefn, cannotattack=true, flying=true, aurabuff="chasni_critter_puff_hunger_aura_buff", aurafind=CritterCommon.AllyTargeting,ev="starve"},
        {
            dmg     = 0,
            range   = 1,
            cd      = 0,
            mincd   = 0,
        },
        {
            spellpower = 10,
            spellpowerincrease = 0.1,
            passivepower = 1, -- percentage
            maxpassivepower = 40,
            spellcd = 480,
            minspellcd = 240,
            canfn = puff_cancast,
            spellfn = puff_spellfn,
        },
        {idle2="idle_loop_full", walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", walkpre2="hover_hover_1_0_pre_full", walkloop2="hover_hover_1_0_loop_full", walkpst2="walk_pst_full", castpre="inhale_pre", cast="inhale_loop", castpst2="inhale_pst", cast2="poop"},
        {bank="puft"}
),
CritterCommon.MakeCritter("chasni_critter_puff_hunger_b",
        {speed=4,nosleep=true,activatefn = puff_activatefn, cannotattack=true, flying=true, aurabuff="chasni_critter_puff_hunger_aura_buff", aurafind=CritterCommon.AllyTargeting},
        {
            dmg     = 0,
            range   = 1,
            cd      = 0,
            mincd   = 0,
        },
        {
            spellpower = 10,
            spellpowerincrease = 0.2,
            passivepower = 5, -- percentage
            maxpassivepower = 60,
            spellcd = 240,
            minspellcd = 120,
            canfn = puff_cancast,
            spellfn = puff_spellfn,
        },
        {idle2="idle_loop_full", walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", walkpre2="hover_hover_1_0_pre_full", walkloop2="hover_hover_1_0_loop_full", walkpst2="walk_pst_full", castpre="inhale_pre", cast="inhale_loop", castpst2="inhale_pst", cast2="poop"},
        {bank="puft"}
),
CritterCommon.MakeBuilder("chasni_critter_puff_insanity_a"),
CritterCommon.MakeCritter("chasni_critter_puff_insanity_a",
        {speed=4,activatefn = puff_activatefn, cannotattack=true, flying=true, sanityaura="negative",ev="lunacy"},
        {
            dmg     = 0,
            range   = 1,
            cd      = 0,
            mincd   = 0,
        },
        {
            spellpower = 10,
            spellpowerincrease = 0.1,
            passivepower = 10,
            passivepowerincrease = 5,
            spellcd = 480,
            minspellcd = 240,
            canfn = puff_cancast,
            spellfn = puff_spellfn,
        },
        {idle2="idle_loop_full", walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", walkpre2="hover_hover_1_0_pre_full", walkloop2="hover_hover_1_0_loop_full", walkpst2="walk_pst_full", castpre="inhale_pre", cast="inhale_loop", castpst2="inhale_pst", cast2="poop"},
        {bank="puft"}
),
CritterCommon.MakeCritter("chasni_critter_puff_insanity_b",
        {speed=4,nosleep=true,activatefn = puff_activatefn, cannotattack=true, flying=true, sanityaura="negative"},
        {
            dmg     = 0,
            range   = 1,
            cd      = 0,
            mincd   = 0,
        },
        {
            spellpower = 10,
            spellpowerincrease = 0.2,
            passivepower = 20,
            passivepowerincrease = 5,
            spellcd = 240,
            minspellcd = 120,
            canfn = puff_cancast,
            spellfn = puff_spellfn,
        },
        {idle2="idle_loop_full", walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", walkpre2="hover_hover_1_0_pre_full", walkloop2="hover_hover_1_0_loop_full", walkpst2="walk_pst_full", castpre="inhale_pre", cast="inhale_loop", castpst2="inhale_pst", cast2="poop"},
        {bank="puft"}
),
CritterCommon.MakeBuilder("chasni_critter_puff_sanity_a"),
CritterCommon.MakeCritter("chasni_critter_puff_sanity_a",
        {speed=4,activatefn = puff_activatefn, cannotattack=true, flying=true, sanityaura="positive",ev="nosanity"},
        {
            dmg     = 0,
            range   = 1,
            cd      = 0,
            mincd   = 0,
        },
        {
            spellpower = 10,
            spellpowerincrease = 0.1,
            passivepower = 10,
            passivepowerincrease = 5,
            spellcd = 480,
            minspellcd = 240,
            canfn = puff_cancast,
            spellfn = puff_spellfn,
        },
        {idle2="idle_loop_full", walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", walkpre2="hover_hover_1_0_pre_full", walkloop2="hover_hover_1_0_loop_full", walkpst2="walk_pst_full", castpre="inhale_pre", cast="inhale_loop", castpst2="inhale_pst", cast2="poop"},
        {bank="puft"}
),
CritterCommon.MakeCritter("chasni_critter_puff_sanity_b",
        {speed=4,nosleep=true,activatefn = puff_activatefn, cannotattack=true, flying=true, sanityaura="positive"},
        {
            dmg     = 0,
            range   = 1,
            cd      = 0,
            mincd   = 0,
        },
        {
            spellpower = 10,
            spellpowerincrease = 0.2,
            passivepower = 20,
            passivepowerincrease = 5,
            spellcd = 240,
            minspellcd = 120,
            canfn = puff_cancast,
            spellfn = puff_spellfn,
        },
        {idle2="idle_loop_full", walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", walkpre2="hover_hover_1_0_pre_full", walkloop2="hover_hover_1_0_loop_full", walkpst2="walk_pst_full", castpre="inhale_pre", cast="inhale_loop", castpst2="inhale_pst", cast2="poop"},
        {bank="puft"}
),
--endregion
--region RAPTOR
CritterCommon.MakeBuilder("chasni_critter_raptor_a"),
CritterCommon.MakeCritter("chasni_critter_raptor_a",
        {speed=4.5,cannotattack=true, aurabuff="chasni_critter_raptor_aura_buff", aurafind=CritterCommon.AllyTargeting,ev="damagedeal"},
        {
            dmg     = 0,
            range   = 1,
            cd      = 0,
            mincd   = 0,
        },
        {
            passivepower = 1, -- percentage
            passivepowerincrease = 1,
            spellcd = 100,
            minspellcd = 40,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = raptor_spellfn,
        },
        {walk="floor_floor_1_0_loop", castpre="call_pre", cast="call_loop", castpst="call_pst", hop="floor_floor_1_0_loop", },
        {bank="raptor"}
),
CritterCommon.MakeCritter("chasni_critter_raptor_b",
        {speed=4, aurabuff="chasni_critter_raptor_aura_buff", aurafind=CritterCommon.AllyTargeting},
        {
            dmg     = 25,
            range   = 12,
            cd      = 40,
            mincd   = 7,
            delay   = 0.4,
            attackfn = raptor_attackfn,
        },
        {
            passivepower = 10, -- percentage
            passivepowerincrease = 1,
            spellcd = 80,
            minspellcd = 25,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = raptor_spellfn,
        },
        {walk="floor_floor_1_0_loop", atk="roar", cast="signal", sleeppre="grooming_pre", sleeploop="grooming_loop", sleeppst="grooming_pst", },
        {bank="raptor", cast="cast_b"}
),
--endregion
--region WOOL
CritterCommon.MakeBuilder("chasni_critter_wool_a"),
CritterCommon.MakeCritter("chasni_critter_wool_a",
        {speed=3,planardamage=5, aurabuff="chasni_critter_wool_aura_buff",ev="celestialchampion"},
        {
            dmg     = 0,
            range   = 8,
            cd      = 40,
            mincd   = 7,
            delay   = 0.8,
            attackfn = wool_attackfn,
        },
        {
            passivepower = 1,
            passivepowerincrease = 1,
        },
        {atk="interact", cast="poop", },
        {bank="wool", walkbank="chasni_critter/chasni_critter/worm/walk"}
),
CritterCommon.MakeCritter("chasni_critter_wool_b",
        {speed=2.5,nosleep=true, planardamage=40, aurabuff="chasni_critter_wool_aura_buff"},
        {
            dmg     = 0,
            range   = 10,
            cd      = 40,
            mincd   = 7,
            delay   = 0.3,
            proj    = "chasni_critter_wool_big_proj",
        },
        {
            passivepower = 5,
            passivepowerincrease = 2,
        },
        {atk="eat_pre", cast="poop", },
        {bank="wool", walkbank="chasni_critter/chasni_critter/worm/walk", attackbank="dontstarve/creatures/spat/spit"}
),
--endregion
--region SEAL
CritterCommon.MakeBuilder("chasni_critter_seal_a"),
CritterCommon.MakeCritter("chasni_critter_seal_a",
        {speed=2,cannotattack=true, aurabuff="chasni_critter_seal_aura_buff", aurafind=CritterCommon.AllyTargeting,ev="dmgnodmg"},
        {
            dmg     = 0,
            range   = 1,
            cd      = 0,
            mincd   = 0,
        },
        {
            spellpower = 1, -- percentage
            maxspellpower = 20,
            passivepower = 10,
            passivepowerincrease = 1,
            spellcd = 80,
            minspellcd = 40,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = seal_spellfn,
        },
        {atk="eat_pre", cast="poop", },
        {bank="seal"}
),
CritterCommon.MakeCritter("chasni_critter_seal_b",
        {speed=2.5, aurabuff="chasni_critter_seal_aura_buff", aurafind=CritterCommon.AllyTargeting},
        {
            dmg     = 60,
            range   = 2.5,
            cd      = 40,
            mincd   = 3,
            delay   = 1,
        },
        {
            spellpower = 5, -- percentage
            maxspellpower = 40,
            passivepower = 20,
            passivepowerincrease = 2,
            spellcd = 50,
            minspellcd = 20,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = seal_spellfn,
        },
        {atk="eat_ore_pre", cast="poop", sleeppre="queue_pre", sleeploop="queue_loop", sleeppst="queue_pst", },
        {bank="seal"}
),
--endregion
--region SLUG
CritterCommon.MakeBuilder("chasni_critter_slug_star_a"),
CritterCommon.MakeCritter("chasni_critter_slug_star_a",
        {speed=2,cannotattack=true, aurabuff="chasni_critter_slug_star_aura_buff",ev="complete"},
        {
            dmg     = 0,
            range   = 1,
            cd      = 0,
            mincd   = 0,
        },
        {
            passivepower = 1, -- percentage
            maxpassivepower = 20,
            spellcd = TUNING.TOTAL_DAY_TIME * 10,
            minspellcd = TUNING.TOTAL_DAY_TIME * 8,
            canfn = function() return false end,
        },
        {cast="poop", },
        {bank="slug"}
),
CritterCommon.MakeCritter("chasni_critter_slug_star_b",
        {speed=2,nosleep=true, aurabuff="chasni_critter_slug_star_aura_buff"},
        {
            dmg     = 10,
            range   = 8,
            cd      = 30,
            mincd   = 3,
            proj    = "chasni_critter_slug_star_proj",
        },
        {
            passivepower = 15, -- percentage
            maxpassivepower = 70,
            spellcd = TUNING.TOTAL_DAY_TIME * 4,
            minspellcd = TUNING.TOTAL_DAY_TIME,
            canfn = function() return false end,
        },
        {atk="hit", cast="poop", },
        {bank="slug"}
),
CritterCommon.MakeBuilder("chasni_critter_slug_xp_a"),
CritterCommon.MakeCritter("chasni_critter_slug_xp_a",
        {speed=2,cannotattack=true, aurabuff="chasni_critter_slug_xp_aura_buff",ev="walkturf"},
        {
            dmg     = 0,
            range   = 1,
            cd      = 0,
            mincd   = 0,
        },
        {
            spellpower = 10,
            spellpowerincrease = 2,
            passivepower = 2, -- percentage
            passivepowerincrease = 2,
            spellcd = TUNING.TOTAL_DAY_TIME * 5,
            minspellcd = TUNING.TOTAL_DAY_TIME * 3,
            canfn = CritterCommon.AlwaysSpell,
            spellfn = slug_xp_spellfn,
        },
        {cast="poop", },
        {bank="slug"}
),
CritterCommon.MakeCritter("chasni_critter_slug_xp_b",
        {speed=2,nosleep=true, aurabuff="chasni_critter_slug_xp_aura_buff"},
        {
            dmg     = 10,
            range   = 8,
            cd      = 30,
            mincd   = 3,
            proj    = "chasni_critter_slug_xp_proj",
        },
        {
            spellpower = 20,
            spellpowerincrease = 5,
            passivepower = 5, -- percentage
            passivepowerincrease = 2.5,
            spellcd = TUNING.TOTAL_DAY_TIME * 5,
            minspellcd = TUNING.TOTAL_DAY_TIME,
            canfn = CritterCommon.AlwaysSpell,
            spellfn = slug_xp_spellfn,
        },
        {atk="hit", cast="poop", },
        {bank="slug"}
),
--endregion
--region STEGO
CritterCommon.MakeBuilder("chasni_critter_stego_a"),
CritterCommon.MakeCritter("chasni_critter_stego_a",
        {speed=3,nosleep=true},
        {
            dmg     = 5,
            range   = 3.5,
            cd      = 40,
            mincd   = 7,
            delay   = 0.4,
            attackfn = stego_attackfn,
        },
        {
            spellpower = 60, -- percentage
            spellpowerincrease = 10,
            spellcd = 80,
            minspellcd = 15,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = stego_spellfn,
        },
        {atk="roar", castpre="call_pre", cast="call_loop", castpst="call_pst", },
        {bank="stego"}
),
--endregion
--region WORM
CritterCommon.MakeBuilder("chasni_critter_worm_a"),
CritterCommon.MakeCritter("chasni_critter_worm_a",
        {speed=2,ev="killbutterfly"},
        {
            dmg     = 1,
            range   = 6,
            cd      = 50,
            mincd   = 7,
            delay   = 0.3,
            proj    = "chasni_critter_worm_proj",
        },
        {},
        {atkpre="call_pre", atk="call_loop", atkpst="call_pst", hoppre="floor_floor_1_0_pre", hoploop="floor_floor_1_0_loop", hoppst="floor_floor_1_0_pst", },
        {bank="worm", attack="attack2"}
),
CritterCommon.MakeCritter("chasni_critter_worm_b",
        {speed=6,flying=true, aurabuff="chasni_critter_worm_aura_buff", aurafind=CritterCommon.AllyTargeting},
        {
            dmg     = 7,
            range   = 9,
            cd      = 40,
            mincd   = 3,
            proj    = "chasni_critter_worm_proj",
        },
        {
            spellpower = 5,
            spellpowerincrease = 1,
            passivepower = 5, -- percentage
            passivepowerincrease = 1,
            spellcd = 60,
            minspellcd = 20,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = worm_spellfn,
        },
        {walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", atk="hit", cast="flyaway_reversed", castpst="escape", },
        {bank="worm", walk="", cast=""}
),
--endregion
--region ELECFISH
CritterCommon.MakeBuilder("chasni_critter_elecfish_a"),
CritterCommon.MakeCritter("chasni_critter_elecfish_a",
        {speed=3.5,flying=true, aurabuff="chasni_critter_elecfish_aura_buff", aurafind=CritterCommon.EnemyTargeting, ev="lightning"},
        {
            dmg     = 2,
            range   = 5,
            cd      = 50,
            mincd   = 12,
            proj    = "chasni_critter_elecfish_proj",
        },
        {
            passivepower = 10, -- percentage
            passivepowerincrease = 1,
            spellcd = 60,
            minspellcd = 30,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = elecfish_spellfn,
        },
        {walkpre="swim_swim_1_0_pre", walkloop="swim_swim_1_0_loop", walkpst="swim_swim_1_0_pst", atk="eat_loop", cast="poop"},
        {bank="elecfish"}
),
CritterCommon.MakeCritter("chasni_critter_elecfish_b",
        {speed=4,flying=true, aurabuff="chasni_critter_elecfish_aura_buff", aurafind=CritterCommon.EnemyTargeting},
        {
            dmg     = 5,
            range   = 7,
            cd      = 40,
            mincd   = 3,
            proj    = "chasni_critter_elecfish_proj",
        },
        {
            passivepower = 25, -- percentage
            passivepowerincrease = 2.5,
            spellcd = 40,
            minspellcd = 10,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = elecfish_spellfn,
        },
        {walkpre="swim_swim_1_0_pre", walkloop="swim_swim_1_0_loop", walkpst="swim_swim_1_0_pst", atk="eat_loop", cast="poop"},
        {bank="elecfish"}
),
--endregion
--region FUGU
CritterCommon.MakeBuilder("chasni_critter_fugu_a"),
CritterCommon.MakeCritter("chasni_critter_fugu_a",
        {speed=3, flying=true,ev="killhutch"},
        {
            dmg     = 1,
            range   = 6,
            cd      = 60,
            mincd   = 12,
            delay   = 0.1,
            proj    = "chasni_critter_fugu_proj",
        },
        {},
        {walkpre="swim_swim_1_0_pre", walkloop="swim_swim_1_0_loop", walkpst="swim_swim_1_0_pst", atk="eat_pst"},
        {bank="fugu"}
),
CritterCommon.MakeCritter("chasni_critter_fugu_b",
        {speed=3,activatefn = fugu_activatefn, nosleep=true, flying=true, casttype="cast_loop", aurabuff="chasni_critter_fugu_aura_buff"},
        {
            dmg     = 7,
            range   = 6,
            cd      = 40,
            mincd   = 3,
            delay   = 0.5,
            proj    = "chasni_critter_fugu_proj",
        },
        {
            spellcd = 480,
            minspellcd = 120,
            canfn = CritterCommon.AlwaysSpell,
            spellfn = fugu_spellfn,
        },
        {walkpre="swim_swim_1_0_pre", walkloop="swim_swim_1_0_loop", walkpst="swim_swim_1_0_pst", atk="eat_pre", castpre="full_pre", cast="full_loop", castpst="full_pst"},
        {bank="fugu", cast="", attack="attack_b"}
),
--endregion
--region SEAHORSE
CritterCommon.MakeBuilder("chasni_critter_seahorse_a"),
CritterCommon.MakeCritter("chasni_critter_seahorse_a",
        {speed=3.5,flying=true, aurabuff="chasni_critter_seahorse_a_aura_buff", aurafind=seahorse_aurafind, ev="rider"},
        {
            dmg     = 1,
            range   = 6,
            cd      = 60,
            mincd   = 12,
            proj    = "chasni_critter_seahorse_proj",
        },
        {
            spellpower = 5,
            spellpowerincrease = 1,
            passivepower = 1, -- percentage
            passivepowerincrease = 1,
            spellcd = 240,
            minspellcd = 80,
            canfn = seahorse_cancastfn,
            spellfn = seahorse_spellfn,
        },
        {walkpre="swim_swim_1_0_pre", walkloop="swim_swim_1_0_loop", walkpst="swim_swim_1_0_pst", atk="eat_pst", cast="poop"},
        {bank="seahorse", walk_pre="walk_pre", }
),
CritterCommon.MakeCritter("chasni_critter_seahorse_b",
        {speed=4.5,flying=true, aurabuff="chasni_critter_seahorse_b_aura_buff", aurafind=seahorse_aurafind},
        {
            dmg     = 7,
            range   = 6,
            cd      = 40,
            mincd   = 3,
            delay   = 0.4,
            proj    = "chasni_critter_seahorse_proj",
        },
        {
            spellpower = 10,
            spellpowerincrease = 1,
            passivepower = 5, -- percentage
            passivepowerincrease = 1,
            spellcd = 120,
            minspellcd = 40,
            canfn = seahorse_cancastfn,
            spellfn = seahorse_spellfn,
        },
        {walkpre="swim_swim_1_0_pre", walkloop="swim_swim_1_0_loop", atk="eat_pst_reversed", cast="poop"},
        {bank="seahorse", walk_pre="walk_pre", attack_pre="attack_b" }
),
--endregion
--region SNAIL
CritterCommon.MakeBuilder("chasni_critter_snail_a"),
CritterCommon.MakeCritter("chasni_critter_snail_a",
        {speed=1, cannotattack=true, aurabuff="chasni_critter_snail_a_aura_buff", aurafind=CritterCommon.AllyTargeting, ev="celestialchampion"},
        {
            dmg     = 0,
            range   = 1,
            cd      = 0,
            mincd   = 0,
        },
        {
            passivepower = 1, -- percentage
            passivepowerincrease = 1,
        },
        {walk="floor_floor_1_0_loop", hop="fall"},
        {bank="snail", walk_pre="walk_pre", }
),
CritterCommon.MakeCritter("chasni_critter_snail_b",
        {speed=1, aurabuff="chasni_critter_snail_b_aura_buff", aurafind=CritterCommon.AllyTargeting},
        {
            dmg     = 7,
            range   = 6,
            cd      = 40,
            mincd   = 3,
            proj    = "chasni_critter_snail_proj",
        },
        {
            passivepower = 15, -- percentage
            passivepowerincrease = 1,
        },
        {atk="poop", hop="fall",},
        {bank="snail", walk_pre="walk_pre", }
),
CritterCommon.MakeBuilder("chasni_critter_snail_black_a"),
CritterCommon.MakeCritter("chasni_critter_snail_black_a",
        {speed=1, cannotattack=true, aurabuff="chasni_critter_snail_black_a_aura_buff", aurafind=CritterCommon.AllyTargeting, ev="ancientguardianancientfuelweaver"},
        {
            dmg     = 0,
            range   = 1,
            cd      = 0,
            mincd   = 0,
        },
        {
            passivepower = 1, -- percentage
            passivepowerincrease = 1,
        },
        {walk="floor_floor_1_0_loop", hop="fall"},
        {bank="snail", walk_pre="walk_pre", }
),
CritterCommon.MakeCritter("chasni_critter_snail_black_b",
        {speed=1, aurabuff="chasni_critter_snail_black_b_aura_buff", aurafind=CritterCommon.AllyTargeting},
        {
            dmg     = 7,
            range   = 6,
            cd      = 40,
            mincd   = 3,
            proj    = "chasni_critter_snail_black_proj",
        },
        {
            passivepower = 15, -- percentage
            passivepowerincrease = 1,
        },
        {atk="poop", hop="fall",},
        {bank="snail", walk_pre="walk_pre", }
),
--endregion
--region TURTLE
CritterCommon.MakeBuilder("chasni_critter_turtle_a"),
CritterCommon.MakeCritter("chasni_critter_turtle_a",
        {speed=2.5,flying=true, stopcastfn=turtle_stopcastfn, cannotattack=true, casttype="cast_loop", aurabuff="chasni_critter_turtle_aura_buff", aurafind=CritterCommon.EnemyTargeting, ev="sitting", volume=0.5},
        {
            dmg     = 0,
            range   = 1,
            cd      = 0,
            mincd   = 0,
        },
        {
            spellpower = 2, -- percentage
            maxspellpower = 25,
            passivepower = 5, -- percentage
            maxpassivepower = 50,
            spellcd = 160,
            minspellcd = 60,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = turtle_spellfn,
        },
        {walk="swim_swim_1_0_loop", castpre="out_reversed", cast="out_loop", castpst="out"},
        {bank="turtle"}
),
CritterCommon.MakeCritter("chasni_critter_turtle_b",
        {speed=2,flying=true, stopcastfn=turtle_stopcastfn, casttype="cast_loop", aurabuff="chasni_critter_turtle_aura_buff", aurafind=CritterCommon.EnemyTargeting, volume=0.5},
        {
            dmg     = 7,
            range   = 10,
            cd      = 50,
            mincd   = 7,
            attackfn = turtle_attackfn,
        },
        {
            spellpower = 5, -- percentage
            maxspellpower = 70,
            passivepower = 10, -- percentage
            maxpassivepower = 70,
            spellcd = 80,
            minspellcd = 20,
            canfn = CritterCommon.CanSpellOnCombat,
            spellfn = turtle_spellfn,
        },
        {walkpre="swim_swim_1_0_pre", walkloop="swim_swim_1_0_loop", walkpst="swim_swim_1_0_pst", atk="eat_pre_reversed", castpre="shearing_pre", cast="shearing_loop", castpst="shearing_pst"},
        {bank="turtle"}
),
--endregion
--region SQUID
CritterCommon.MakeBuilder("chasni_critter_squid_a"),
CritterCommon.MakeCritter(
        "chasni_critter_squid_a",
        {speed=3.5,nosleep=true, flying=true, aurabuff="chasni_critter_squid_aura_buff", passiveaurarange=true,ev="oceanfish"},
        {
            dmg     = 3,
            range   = 7,
            cd      = 40,
            mincd   = 7,
            delay   = 0.9,
            attackfn = squid_a_attack,
        },
        {
            spellpower = 1,
            spellpowerincrease = 0.1,
            passivepower = 3,
            passivepowerincrease = 0.1,
            spellcd = 240,
            minspellcd = 60,
            delay   = 0.2,
            canfn = squid_cancastfn,
            spellfn = squid_spellfn,
        },
        {walkpre="swim_swim_1_0_pre", walkloop="swim_swim_1_0_loop", walkpst="swim_swim_1_0_pst", atk="poop", cast="incubator_idle_loop", },
        {bank="squid",}
),
CritterCommon.MakeCritter(
        "chasni_critter_squid_b",
        {speed=3,nosleep=true, flying=true, aurabuff="chasni_critter_squid_aura_buff", passiveaurarange=true},
        {
            dmg     = 6,
            range   = 10,
            cd      = 30,
            mincd   = 4,
            delay   = 1,
            attackfn = squid_b_attackfn,
        },
        {
            spellpower = 10,
            spellpowerincrease = 0.2,
            passivepower = 4,
            passivepowerincrease = 0.1,
            spellcd = 80,
            minspellcd = 40,
            canfn = squid_cancastfn,
            spellfn = squid_spellfn,
        },
        {walk="swim_swim_1_0_loop", atkpre="drink_pre", atk="drink_loop", atkpst="drink_pst", cast="excited_loop", },
        {bank="squid", attack="attack_b"}
),
--endregion
--region BOT
CritterCommon.MakeBuilder("chasni_critter_bot"),
CritterCommon.MakeCritter("chasni_critter_bot",
        {speed=3.5, flying=true, onaccepttradefn=bot_onaccepttradefn, bluememoryfn=CLIENT_TriggerFX, aurabuff="chasni_critter_bot_aura_buff"},
        {
            dmg     = 5,
            range   = 2,
            cd      = 40,
            mincd   = 7,
            attackfn = bot_attackfn,
        },
        {
            spellcd = 0,
            minspellcd = 0,
            canfn = bot_cancastfn,
            spellfn = bot_spellfn,
        },
        {walkpre="hover_hover_1_0_pre", walkloop="hover_hover_1_0_loop", walkpst="hover_hover_1_0_pst", atkpre="pickup_pre", atk="pickup_loop", atkpst="pickup_pst", cast="hit"},
        {bank="bot"}
)
--endregion
