local brain = require("brains/chasni_crittersbrain")

local WAKE_TO_FOLLOW_DISTANCE = 6
local SLEEP_NEAR_LEADER_DISTANCE = 5
local LEVEL_CONSTANT = 50

local function IsLeaderSleeping(inst)
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    return leader and leader:HasTag("sleeping")
end

local function ShouldWakeUp(inst)
    return (DefaultWakeTest(inst) and not IsLeaderSleeping(inst)) or not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE)
end

local function ShouldSleep(inst)
    return (DefaultSleepTest(inst) or IsLeaderSleeping(inst)) and inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE)
end
-------------------------------------------------------------------------------
-- BOT FUNCTION
-------------------------------------------------------------------------------
local function ResetBotBank(inst)
    inst.AnimState:SetBank("chasni_critter_bot_"..(inst.memorycolor or "white"))
    inst.AnimState:SetBuild("chasni_critter_bot_"..(inst.memorycolor or "white"))
end

local function GetMemoryColor(item)
    return item.prefab:match("^chasni_memorycard_(.+)$")
end

local function AbleToAcceptTest(inst, item, giver)
    if inst.sg and inst.sg:HasStateTag("busy") then
        return false
    end

    return GetMemoryColor(item) ~= nil
end

local function AcceptTest(inst, item, giver)
    return GetMemoryColor(item) ~= nil
end

local function OnGetItemFromPlayer(inst, giver, item)
    local color = GetMemoryColor(item)
    if color then
        inst.memorycolor = color
        inst:ResetBotBank()

        if inst.OnAcceptTradeFn then
            inst:OnAcceptTradeFn()
        end
    end
end
-------------------------------------------------------------------------------

local function EquipWeapon(inst)
    inst:AddComponent("inventory")
    if inst.components.inventory ~= nil and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local weapon = CreateEntity()
        weapon.entity:AddTransform()
        weapon:AddComponent("weapon")
        weapon.components.weapon:SetDamage(inst.components.combat.defaultdamage)
        weapon.components.weapon:SetRange(inst.components.combat.attackrange, inst.components.combat.attackrange+5)
        weapon.components.weapon:SetProjectile(inst.atk_data and inst.atk_data.proj or "bishop_charge_fix")
        weapon:AddComponent("inventoryitem")
        weapon.persists = false
        weapon.components.inventoryitem:SetOnDroppedFn(inst.Remove)
        weapon:AddComponent("equippable")
        weapon:AddTag("nosteal")

        inst.components.inventory:Equip(weapon)
    end
end

local function MakeCritter(name, data, attk, spel, anm, snd)
    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
    }
    if name == "chasni_critter_bot" then
        assets =
        {
            Asset("ANIM", "anim/"..name.."_white.zip"),
            Asset("ANIM", "anim/"..name.."_blue.zip"),
            Asset("ANIM", "anim/"..name.."_red.zip"),
            Asset("ANIM", "anim/"..name.."_green.zip"),
            Asset("ANIM", "anim/"..name.."_brown.zip"),
            Asset("ANIM", "anim/"..name.."_yellow.zip"),
            Asset("ANIM", "anim/"..name.."_pink.zip"),
            Asset("ANIM", "anim/chasni_barrier.zip"),
        }
    end

    local KEEPTARGET_RANGE = 15
    local function KeepTargetFn(inst, target)
        return chasni_basickeeptarget(inst, target, KEEPTARGET_RANGE)
    end
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddNetwork()

        inst.DynamicShadow:SetSize(1, .5)
        inst.Transform:SetTwoFaced()
        inst.Transform:SetScale(1.6, 1.6, 1.6)

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle_loop")

        if data and data.flying then
            inst.entity:AddPhysics()
            inst.Physics:SetMass(1)
            inst.Physics:SetFriction(0)
            inst.Physics:SetDamping(5)
            inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
            inst.Physics:SetCollisionMask(TheWorld:CanFlyingCrossBarriers() and COLLISION.GROUND or COLLISION.WORLD, COLLISION.FLYERS, COLLISION.CHARACTERS)
            inst.Physics:SetCapsule(.5, 1)

            inst:AddTag("flying")
            inst:AddTag("ignorewalkableplatformdrowning")

            MakeInventoryFloatable(inst)
        else
            MakeCharacterPhysics(inst, 1, .5)
        end

        inst.Physics:SetDontRemoveOnSleep(true) -- critters dont really go do entitysleep as it triggers a teleport to near the owner, so no point in hitting the physics engine.

        inst:AddTag("chasni_critter")
        inst:AddTag("companion")
        inst:AddTag("notraptrigger")
        inst:AddTag("noauradamage")
        inst:AddTag("NOBLOCK")
        inst:AddTag("trader")

        if data.tag then
            inst:AddTag(data.tag)
        end

        inst:AddComponent("spawnfader")

        if name == "chasni_critter_bot" then
            inst.triggerfx = net_event(inst.GUID, "chasni_critter_bot.triggerfx")

            inst:AddTag("cooker")

            inst:AddComponent("raindome")
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            if name == "chasni_critter_bot" then
                inst.OnEntityReplicated = function(_inst)
                    _inst.replica.container:WidgetSetup("chester")
                end

                inst:DoTaskInTime(0, inst.ListenForEvent, "chasni_critter_bot.triggerfx", data.bluememoryfn)
            end
            return inst
        end

        inst.atk_data = attk
        inst.spl_data = spel
        inst.anim = anm
        inst.sound = snd
        inst.critterdata = data

        inst:AddComponent("inspectable")

        inst:AddComponent("follower")
        inst.components.follower:KeepLeaderOnAttacked()
        inst.components.follower.keepdeadleader = true
        inst.components.follower.keepleaderduringminigame = true

        inst:AddComponent("knownlocations")

        if data and data.havewater then
            inst:AddComponent("wateryprotection")
            inst.components.wateryprotection.addwetness = 10
            inst.components.wateryprotection.protection_dist = TUNING.TRIDENT.SPELL.RADIUS * 0.7
        end
        if data and data.haveinventory then
            inst:AddComponent("inventory")
            inst.components.inventory.maxslots = data.haveinventory
        end
        if data and data.haveground then
            inst:AddComponent("groundpounder")
            inst.components.groundpounder.destroyer = false
            inst.components.groundpounder.damageRings = 2
            inst.components.groundpounder.destructionRings = 1
            inst.components.groundpounder.platformPushingRings = 1
            inst.components.groundpounder.numRings = 2
            inst.components.groundpounder.noTags = { "FX", "NOCLICK", "DECOR", "INLIMBO", "grubarmy" }
            inst.components.groundpounder.groundpoundringfx = "smallfx_ring"
        end
        if data and data.activatefn then
            inst:AddComponent("activatable")
            inst.components.activatable.OnActivate = data.activatefn
            inst.components.activatable.inactive = false
            inst.components.activatable.quickaction = true
        end

        inst:AddComponent("combat")
        if inst.atk_data then
            inst.components.combat:SetDefaultDamage(inst.atk_data.dmg)
            inst.components.combat:SetRange(inst.atk_data.range)
            inst.components.combat:SetAttackPeriod(1)
            inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
        end
        if data and data.planardamage then
            inst:AddComponent("planardamage")
            inst.components.planardamage:SetBaseDamage(data.planardamage)
        end
        if data and data.aurabuff then
            inst:AddComponent("buffaura")
            inst.components.buffaura:AddAura(data.aurabuff, data.aurabuff, function(_inst)
                return data.passiveaurarange and (_inst:CanCast() and _inst:calculatePassiveValue() or 0) or 8
            end)
            inst:DoTaskInTime(0, function()
                inst.components.buffaura:StartAura()
            end)
            if data.aurafind then
                inst.components.buffaura:SetAuraFindFn(data.aurabuff, data.aurafind)
            end
        end
        if data and data.sanityaura then
            inst:AddComponent("sanityaura")
            local sign = data.sanityaura == "positive" and 1/1000 or -1/1000
            inst.components.sanityaura.aurafn = function(_inst, observer)
                return ((_inst.calculatePassiveValue and _inst:calculatePassiveValue()) or 0) * sign
            end
        end
        --if data == nil or data.nosleep ~= true then
        --    inst:AddComponent("sleeper")
        --    inst.components.sleeper:SetResistance(3)
        --    inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
        --    inst.components.sleeper:SetSleepTest(ShouldSleep)
        --    inst.components.sleeper:SetWakeTest(ShouldWakeUp)
        --end

        inst:AddComponent("locomotor")
        inst.components.locomotor:EnableGroundSpeedMultiplier(data and data.flying)
        inst.components.locomotor:SetTriggersCreep(false)
        inst.components.locomotor.softstop = true
        inst.components.locomotor.walkspeed = data.speed or 3
        if data and data.flying then
            inst.components.locomotor.pathcaps = { allowocean = true }
        end
        if data and not data.flying then
            inst.components.locomotor:SetAllowPlatformHopping(true)

            inst:AddComponent("embarker")
            inst.components.embarker.embark_speed = inst.components.locomotor.walkspeed
        end

        inst:AddComponent("timer")

        if name == "chasni_critter_bot" then
            inst:AddComponent("container")
            inst.components.container:WidgetSetup("chester")
            inst.components.container.skipclosesnd = true
            inst.components.container.skipopensnd = true

            inst:AddComponent("trader")
            inst.components.trader.acceptnontradable = true
            inst.components.trader:SetAbleToAcceptTest(AbleToAcceptTest)
            inst.components.trader:SetAcceptTest(AcceptTest)
            inst.components.trader.onaccept = OnGetItemFromPlayer
            inst.OnAcceptTradeFn = data.onaccepttradefn

            inst.components.raindome:SetRadius(TUNING.VOIDCLOTH_UMBRELLA_DOME_RADIUS)

            inst:AddComponent("cooker")
            inst.components.cooker.oncookfn = function(_inst, product, chef)
                if product.components.perishable then
                    product.components.perishable:SetPercent(1)
                end
            end

            inst.ResetBotBank = ResetBotBank
            inst:ResetBotBank()
        end

        if inst.atk_data and inst.atk_data.proj then
            EquipWeapon(inst)
        end

        if inst.atk_data and inst.atk_data.attackfn then
            inst.attackfn = inst.atk_data.attackfn
        end
        inst.DoAttack = function(_inst, target)
            if _inst.attackfn then
                inst:DoTaskInTime(_inst.atk_data and _inst.atk_data.delay or 0, function()
                    _inst.SoundEmitter:PlaySound(_inst.sound and _inst.sound.attackbank or _inst:getSound("attack"), nil, data.volume)
                    _inst:attackfn(target)
                end)
            else
                _inst.SoundEmitter:PlaySound(_inst:getSound("attack_pre"), nil, data.volume)
                inst:DoTaskInTime(_inst.atk_data and _inst.atk_data.delay or 0, function()
                    _inst.SoundEmitter:PlaySound(_inst.sound and _inst.sound.attackbank or _inst:getSound("attack"), nil, data.volume)
                    _inst.components.combat:DoAttack(target)
                end)
            end

            _inst.attack_cd = GetTime() + (inst.calculateAttackCD and inst:calculateAttackCD() or 5)
        end
        if inst.spl_data then
            inst.spellfn = inst.spl_data.spellfn
        end
        inst.CastSpell = function(_inst)
            if _inst.spellfn then
                if not _inst._alternateform then
                    _inst.blobfx = chasni_spawnprefab("bloblight_fx", 0, 0, 0, 0.5, 0.5, 0.5, _inst.entity)
                    _inst.stafflight = chasni_spawnprefab("staff_castinglight_small", 0, 0, 0, 1, 1, 1, _inst.entity)
                    _inst.stafflight:SetUp({ 1, 1, 1 }, 1, .33)
                    _inst.SoundEmitter:PlaySound(_inst:getSound("cast"), nil, data.volume)
                else
                    _inst.SoundEmitter:PlaySound(_inst:getSound("cast_alternate"), nil, data.volume)
                end
                _inst:spellfn()
            end
            _inst.spell_cd = GetTime() + (_inst.spl_data and _inst.spl_data.spellcd or 5)
        end
        inst.CanCast = inst.spl_data and inst.spl_data.canfn or function()
            return false
        end

        inst.calculateAttackCD = function(_inst)
            local basecooldown = _inst.atk_data and _inst.atk_data.cd or 0
            local mincooldown = _inst.atk_data and _inst.atk_data.mincd or 0
            local leader = _inst.components.follower and _inst.components.follower:GetLeader()
            local levelstat = leader and leader.components.levelsystem and leader.components.levelsystem.petattackspeedlevelamount or 0

            -- modifiers
            local mult = 1
            if _inst:HasDebuff("chasni_didgerizoo_buff") then
                mult = 0.5
            end

            return (mincooldown + ((basecooldown - mincooldown) * LEVEL_CONSTANT / (LEVEL_CONSTANT + levelstat)) * mult)
        end
        inst.calculateSpellCD = function(_inst)
            local basecooldown = _inst.spl_data and _inst.spl_data.spellcd or 0
            local mincooldown = _inst.spl_data and _inst.spl_data.minspellcd or 0
            local leader = _inst.components.follower and _inst.components.follower:GetLeader()
            local levelstat = leader and leader.components.levelsystem and leader.components.levelsystem.petcooldownlevelamount or 0
            return mincooldown + ((basecooldown - mincooldown) * LEVEL_CONSTANT / (LEVEL_CONSTANT + levelstat))
        end
        inst.calculateSpellValue = function(_inst)
            local basevalue = _inst.spl_data and _inst.spl_data.spellpower or 0
            local leader = _inst.components.follower and _inst.components.follower:GetLeader()
            local levelstat = leader and leader.components.levelsystem and leader.components.levelsystem.petspelllevelamount or 0

            local maxpower = _inst.spl_data and _inst.spl_data.maxspellpower
            local increasevalue = _inst.spl_data and _inst.spl_data.spellpowerincrease
            if maxpower then
                return basevalue + ((maxpower - basevalue) * levelstat / (LEVEL_CONSTANT + levelstat))
            elseif increasevalue then
                return basevalue + (increasevalue * levelstat)
            end
            return 0
        end
        inst.calculatePassiveValue = function(_inst)
            local basevalue = _inst.spl_data and _inst.spl_data.passivepower or 0
            local leader = _inst.components.follower and _inst.components.follower:GetLeader()
            local levelstat = leader and leader.components.levelsystem and leader.components.levelsystem.petpassivelevelamount or 0

            local maxpower = _inst.spl_data and _inst.spl_data.maxpassivepower
            local increasevalue = _inst.spl_data and _inst.spl_data.passivepowerincrease
            if maxpower then
                return basevalue + ((maxpower - basevalue) * levelstat / (LEVEL_CONSTANT + levelstat))
            elseif increasevalue then
                return basevalue + (increasevalue * levelstat)
            end
            return 0
        end
        inst.canEvolve = function(_inst)
            if _inst.evolve then
                local leader = _inst.components.follower and _inst.components.follower:GetLeader()
                if leader and leader.components.allachivevent and (leader.components.allachivevent[data.ev] or leader.components.allachivevent.completeamount > 0) then
                    return true
                end
            end
            return false
        end
        if data.ev then
            inst.evolve = function(_inst)
                local leader = _inst.components.follower and _inst.components.follower:GetLeader()
                if leader then
                    local pt = _inst:GetPosition()
                    local function AToB(str)
                        return str:gsub("_a$", "_b")
                    end
                    leader.components.petleash:SpawnPetAt(pt.x, 0, pt.z, AToB(_inst.prefab))
                end
            end
        end

        inst.getSound = function(_inst, soundname, default, force)
            return "chasni_critter/chasni_critter/" .. (_inst.sound.bank or "") .. "/" .. (force or _inst.sound[soundname] or _inst.sound[default] or default or soundname)
        end
        if data and data.loopsound then
            inst.SoundEmitter:PlaySound(inst:getSound(nil, nil, data.loopsound), "loop")
            inst.SoundEmitter:SetVolume("loop", .8)
        end
        if data and data.cannotattack then
            inst._cannotattack = true
        end
        if data and data.onhitother then
            inst:ListenForEvent("onhitother", data.onhitother)
        end
        if data and data.casttype then
            inst.casttype = data.casttype
        end
        if data and data.stopcastfn then
            inst.stopCast = data.stopcastfn
        end

        inst.spell_cd = GetTime() + inst:calculateSpellCD()

        inst:SetBrain(brain)
        inst:SetStateGraph("SGCZchasni_critter")

        inst:ListenForEvent("onhitother", function(_inst, _data)
            local leader = inst.components.follower and inst.components.follower:GetLeader()
            if leader and _data and _data.target and _data.target.components.combat and not _data.target.components.combat:TargetIs(leader) and _data.target.components.combat:CanTarget(leader) then
                _data.target.components.combat:SetTarget(leader)
            end
        end)

        inst:ListenForEvent("killed", function(killer, _data)
            local victim = _data.victim
            if victim then
                chasni_checkkilllevel(victim)
                chasni_checkslayachievement(killer, victim)
            end
        end)

        inst.OnSave = function(_inst, _data)
            if _inst._castdelaytime ~= nil then
                _data.spell_cd_remaining = _inst._castdelaytime
            elseif _inst.spell_cd ~= nil then
                _data.spell_cd_remaining = math.max(0, _inst.spell_cd - GetTime())
            end
            if _inst.attack_cd then
                _data.attack_cd_remaining = math.max(0, _inst.attack_cd - GetTime())
            end
            if _inst.memorycolor then
                _data.memorycolor = _inst.memorycolor
            end
        end
        inst.OnLoad = function(_inst, _data)
            if _data then
                _inst.spell_cd = GetTime() + (_data.spell_cd_remaining or 0)
                _inst.attack_cd = GetTime() + (_data.attack_cd_remaining or 0)
                _inst.memorycolor = _data and _data.memorycolor or "white"
                if _inst.OnAcceptTradeFn then
                    _inst:OnAcceptTradeFn()
                end
                if _inst.ResetBotBank then
                    _inst:ResetBotBank()
                end
            end
        end

        return inst
    end

    return Prefab(name, fn, assets)
end

-------------------------------------------------------------------------------
local function builder_onbuilt(inst, builder)
    local theta = math.random() * TWOPI
    local pt = builder:GetPosition()
    local radius = 1
    local offset = FindWalkableOffset(pt, theta, radius, 6, true)
    if offset ~= nil then
        pt.x = pt.x + offset.x
        pt.z = pt.z + offset.z
    end
    builder.components.petleash:SpawnPetAt(pt.x, 0, pt.z, inst.pettype, inst.linked_skinname)
    inst:Remove()
end

local function MakeBuilder(prefab)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()

        inst:AddTag("CLASSIFIED")

        --[[Non-networked entity]]
        inst.persists = false

        --Auto-remove if not spawned by builder
        inst:DoTaskInTime(0, inst.Remove)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.pettype = prefab
        inst.OnBuiltFn = builder_onbuilt

        return inst
    end

    return Prefab(prefab.."_builder", fn, nil, { prefab })
end
-------------------------------------------------------------------------------
local function OnCombat(inst)
    return inst.components.combat and inst.components.combat.target ~= nil
end
local function OffCombat(inst)
    return inst.components.combat and inst.components.combat.target == nil
end
local function NoSpell(inst)
    return false
end
local function AlwaysSpell(inst)
    return true
end
-------------------------------------------------------------------------------
local function AllyTargeting(x, y, z, radius, inst)
    local targets = {}
    local players = FindPlayersInRange(x, y, z, radius, true)
    for _, player in ipairs(players) do
        table.insert(targets, player)
    end

    local ents = TheSim:FindEntities(x, y, z, radius, nil, { "FX", "INLIMBO", "notarget", "noattack", "invisible", "player"})
    for _, v in ipairs(ents) do
        if chasni_friendpet(v) or chasni_ownpet(v, inst) then
            table.insert(targets, v)
        end
    end

    return targets
end
local function EnemyTargeting(x, y, z, radius, inst)
    local targets = {}
    local ents = TheSim:FindEntities(x, y, z, radius, nil, { "FX", "INLIMBO", "notarget", "noattack", "invisible", "player"})
    for _, v in ipairs(ents) do
        if not chasni_friendpet(v) and not chasni_ownpet(v, inst) then
            table.insert(targets, v)
        end
    end

    return targets
end
local function StopCastLoop(inst)
    local castpstanim = inst.anim and (inst._alternateform and inst.anim.castpst2 or (not inst._alternateform and inst.anim.castpst))
    if castpstanim then
        inst.sg:GoToState("pre_idle", castpstanim)
    else
        inst.sg:GoToState("idle")
    end
end

--local animi = {
--    idle = "idle_loop", 
--    death = "death", 
--    walkpre = "hover_hover_1_0_pre", 
--    walkloop = "hover_hover_1_0_loop", 
--    walkpst = "hover_hover_1_0_pst", 
--    walk = "floor_floor_1_0_loop", 
--    hoppre = "floor_floor_1_0_pre", hoploop = "floor_floor_1_0_loop", hoppst = "floor_floor_1_0_pst", 
--    hop = "drown_loop", 
--    sink = "drown_loop",
--    sink = "drown_loop",
--    sleeppre = "grooming_pre", sleeploop = "grooming_loop", sleeppst = "grooming_pst", 
--    atkpre = "pollinate_pre", atk = "pollinate_loop", atkpst = "pollinate_pst", 
--    castpre = "mining_pre", 
--    cast = "mining_loop", 
--    castpst = "mining_pst",
--    dmg = 5, range = 1, cd = 5, 
--    spellcd = 10, fn = OnCombat,
--}

return {
    MakeBuilder = MakeBuilder,
    MakeCritter = MakeCritter,
    CanSpellOffCombat = OffCombat,
    CanSpellOnCombat = OnCombat,
    CannotSpell = NoSpell,
    AlwaysSpell = AlwaysSpell,
    AllyTargeting = AllyTargeting,
    EnemyTargeting = EnemyTargeting,
    StopCastLoop = StopCastLoop,
}