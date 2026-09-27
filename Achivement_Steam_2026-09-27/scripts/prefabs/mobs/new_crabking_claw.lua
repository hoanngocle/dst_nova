local brain = require "brains/chasni_crabkingclawbrain"

SetSharedLootTable("chasni_crabking_clawwater", {
    { "chasni_crab_waterorgan",	    0.1 },
})
SetSharedLootTable("chasni_crabking_clawice", {
    { "chasni_crab_iceorgan",	    0.1 },
})
SetSharedLootTable("chasni_crabking_clawfire", {
    { "chasni_crab_fireorgan",	    0.1 },
})
SetSharedLootTable("chasni_crabking_clawelectric", {
    { "chasni_crab_electricorgan",	0.1 },
})
SetSharedLootTable("chasni_crabking_clawlunar", {
    { "chasni_crab_lunarorgan",	    0.1 },
})
SetSharedLootTable("chasni_crabking_clawshadow", {
    { "chasni_crab_shadoworgan",	0.1 },
})

local GESTALTTARGET_DURATION = chasni_getmobconfig("chasni_ckc", "LUNDUR") or 5
local MINDCONTROLLER_DURATION = chasni_getmobconfig("chasni_ckc", "SHADUR") or 4
local function FireCastSpell(inst)
    local player, distsq = inst:GetNearestPlayer(true)
    if distsq and distsq < 400 then
        player:AddDebuff("ckc_fire_debuff", "ckc_fire_debuff")
    end
end
local function WaterCastSpell(inst)
    local player, distsq = inst:GetNearestPlayer(true)
    if distsq and distsq < 400 then
        player:AddDebuff("ckc_water_debuff", "ckc_water_debuff")
    end
end
local function IceCastSpell(inst)
    local player, distsq = inst:GetNearestPlayer(true)
    if distsq and distsq < 400 then
        player:AddDebuff("ckc_ice_debuff", "ckc_ice_debuff")
    end
end
local function ElectricCastSpell(inst)
    local player, distsq = inst:GetNearestPlayer(true)
    if distsq and distsq < 400 then
        player:AddDebuff("ckc_electric_debuff", "ckc_electric_debuff")
    end
end
local function ShadowCastSpell(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, 20, true)
    for _, player in ipairs(players) do
        if not player.components.health:IsDead() and not player:HasTag("playerghost") then
            if player._shadowckctask then
                player._shadowckctask:Cancel()
                player._shadowckctask = nil
            end
            player._shadowckctask = player:DoTaskInTime(MINDCONTROLLER_DURATION, function()
                if player._shadowckcperiodictask then
                    player._shadowckcperiodictask:Cancel()
                    player._shadowckcperiodictask = nil
                end
            end)
            if player._shadowckcperiodictask == nil then
                player._shadowckcperiodictask = player:DoPeriodicTask(0.1, function()
                    if not player.components.health:IsDead() and not player:HasTag("playerghost") then
                        player:AddDebuff("mindcontroller", "mindcontroller")
                    else
                        if player._shadowckcperiodictask then
                            player._shadowckcperiodictask:Cancel()
                            player._shadowckcperiodictask = nil
                        end
                    end
                end)
            end
        end
    end
end
local function LunarCastSpell(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, 20, true)
    for _, player in ipairs(players) do
        if not player.components.health:IsDead() and not player:HasTag("playerghost") then
            if player._lunarckctask then
                player._lunarckctask:Cancel()
                player._lunarckctask = nil
            end
            player._lunarckctask = player:DoTaskInTime(GESTALTTARGET_DURATION, function()
                if player._lunarckcperiodictask then
                    player._lunarckcperiodictask:Cancel()
                    player._lunarckcperiodictask = nil
                end
            end)
            if player._lunarckcperiodictask == nil then
                player._lunarckcperiodictask = player:DoPeriodicTask(1, function()
                    if not player.components.health:IsDead() and not player:HasTag("playerghost") then
                        local gestalt = SpawnPrefab("largeguard_alterguardian_projectile")
                        local px, py, pz = player.Transform:GetWorldPosition()
                        local radius = GetRandomMinMax(3, 5)
                        local angle = (player:GetAngleToPoint(px, py, pz) + GetRandomMinMax(-90, 90)) * DEGREES
                        gestalt.Transform:SetPosition(px + radius * math.cos(angle), py, pz + radius * -math.sin(angle))
                        gestalt:ForceFacePoint(px, py, pz)
                        gestalt:SetTargetPosition(Vector3(px, py, pz))
                    else
                        if player._lunarckcperiodictask then
                            player._lunarckcperiodictask:Cancel()
                            player._lunarckcperiodictask = nil
                        end
                    end
                end)
            end
        end
    end
end

local DAMAGE = {
    fire     = chasni_getmobconfig("chasni_crabclaw", "DMGF") or 34,
    water    = chasni_getmobconfig("chasni_crabclaw", "DMGW") or 34,
    ice      = chasni_getmobconfig("chasni_crabclaw", "DMGI") or 34,
    electric = chasni_getmobconfig("chasni_crabclaw", "DMGE") or 34,
    shadow   = chasni_getmobconfig("chasni_crabclaw", "DMGS") or 34,
    lunar    = chasni_getmobconfig("chasni_crabclaw", "DMGL") or 34,
}

local function MakeClaw(element, spellfn, tags, projectile)
    local assets =
    {
        Asset("ANIM", "anim/chasni_"..element.."_crab_king_claw_build.zip"),
    }
    local prefabs =
    {
        "chasni_"..element.."_crab_king_claw_fx_build",
        "chasni_crab_shadow"..element.."organ",
        "chasni_crabking_claw_"..element.."_proj",
    }
    SetSharedLootTable("chasni_crabking_claw"..element, {
        {"chasni_crab_shadow"..element.."organ",   0.2},
    })

    local function OnTimerDone(inst, data)
        if data.name == "attack_cd" then
            local x, y, z = inst.Transform:GetWorldPosition()
            local target
            if inst._element == "lunar" then
                target = inst._crabking
            else
                target = FindClosestPlayer(x, y, z)
            end
            if target and not inst.sg:HasStateTag("clampped") and not inst.sg:HasStateTag("busy") then
                inst.sg:GoToState("shot_pre", target)
            else
                inst.components.timer:StopTimer("attack_cd")
                inst.components.timer:StartTimer("attack_cd", 5)
            end
        end
    end

    local function EquipWeapon(inst)
        if inst.components.inventory and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
            local weapon = CreateEntity()
            weapon.entity:AddTransform()
            weapon:AddComponent("weapon")
            weapon.components.weapon:SetDamage(DAMAGE[inst._element] or 34)
            weapon.components.weapon:SetRange(15, 20)
            weapon.components.weapon:SetProjectile(projectile)
            if inst._element == "electric" then
                weapon.components.weapon:SetElectric()
            end

            weapon:AddComponent("inventoryitem")
            weapon.persists = false
            weapon.components.inventoryitem:SetOnDroppedFn(inst.Remove)
            weapon:AddComponent("equippable")
            weapon:AddTag("nosteal")

            inst.components.inventory:Equip(weapon)
        end
    end

    local function releaseclamp(inst, immediate)
        if inst.boat then
            if inst.boat.components.boatphysics then
                inst.boat.components.boatphysics:RemoveBoatDrag(inst)
            end

            if inst._releaseclamp then
                inst:RemoveEventCallback("onremove", inst._releaseclamp, inst.boat)
                inst._releaseclamp = nil
            end
        end
        inst.boat = nil
        inst:PushEvent("releaseclamp", {immediate = immediate} )

        if inst.clamptask then
            inst.clamptask:Cancel()
            inst.clamptask = nil
        end
    end

    local function crunchboat(inst,boat)
        inst:PushEvent("clamp_attack",boat)
        if inst.clamptask then
            inst.clamptask:Cancel()
            inst.clamptask = nil
        end
        inst.clamptask = inst:DoTaskInTime(math.random()+3,function() inst.crunchboat(inst,inst.boat) end)
    end

    local CLAMPDAMAGE_CANT_TAGS = {"flying", "shadow", "ghost", "playerghost", "FX", "NOCLICK", "DECOR", "INLIMBO"}
    local function clamp(inst)
        if inst.boat and not inst.boat.components.health:IsDead() then
            inst.boat.components.health:DoDelta(-TUNING.CRABKING_CLAW_BOATDAMAGE)
            ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.3, 0.03, 0.5, inst.boat, inst.boat:GetPhysicsRadius(4))
            local pos = Vector3(inst.Transform:GetWorldPosition())
            local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 3, nil, CLAMPDAMAGE_CANT_TAGS)

            for i, v in pairs(ents)do
                if v ~= inst and v:IsValid() and not v:IsInLimbo() then
                    if      v.components.workable and
                            v.components.workable:CanBeWorked() and
                            v.components.workable.action ~= ACTIONS.NET then
                        v.components.workable:Destroy(inst)
                    end
                    if      v.components.health and
                            not v.components.health:IsDead() and
                            inst.components.combat:CanTarget(v) then
                        inst.components.combat:DoAttack(v)
                    end
                end
            end

            ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.3, 0.03, 0.5, inst.boat, inst.boat:GetPhysicsRadius(4))

            if inst.boat.components.boatphysics then
                inst.boat.components.boatphysics:AddBoatDrag(inst)
            end
            inst._releaseclamp = function() inst:releaseclamp() end
            inst:ListenForEvent("onremove", inst._releaseclamp, inst.boat)
            inst.clamptask = inst:DoTaskInTime(math.random()+3,function() inst.crunchboat(inst,inst.boat) end)
        end
    end

    local function teleport_override_fn(inst)
        local pt = inst.components.knownlocations and inst.components.knownlocations:GetLocation("spawnpoint") or inst:GetPosition()
        local offset = FindSwimmableOffset(pt, math.random() * 2 * PI, 3, 8, true, false) or
                FindSwimmableOffset(pt, math.random() * 2 * PI, 8, 8, true, false)
        if offset then
            pt = pt + offset
        end

        return pt
    end

    local function OnTeleported(inst)
        inst:releaseclamp(true)
    end

    local function OnDead(inst)
        if inst.shadow then
            inst.shadow:Remove()
        end
        inst.releaseclamp(inst)
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeCharacterPhysics(inst, 1000, 0.1)
        inst.Transform:SetSixFaced()

        inst:AddTag("ignorewalkableplatforms")
        inst:AddTag("animal")
        inst:AddTag("scarytoprey")
        inst:AddTag("hostile")
        inst:AddTag("crabking_claw")
        inst:AddTag("soulless")

        local s  = 0.7
        inst.Transform:SetScale(s, s, s)

        inst.AnimState:SetBank("crab_claw")
        inst.AnimState:SetBuild("chasni_"..element.."_crab_king_claw_build")
        inst.AnimState:PlayAnimation("idle", true)

        --------------------------------- ADDITION ---------------------------------
        if tags then
            for _, tag in pairs(tags) do
                inst:AddTag(tag)
            end
        end
        inst._element = element
        ----------------------------------------------------------------------------

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("boatdrag")
        inst.components.boatdrag.drag = TUNING.CRABKING_ANCHOR_DRAG
        inst.components.boatdrag.forcedampening = 1
        inst.components.boatdrag.max_velocity_mod = TUNING.CRABKING_MAX_VELOCITY_MOD
        inst.components.boatdrag.sailforcemodifier = 0

        inst:AddComponent("locomotor")
        inst.components.locomotor.walkspeed = TUNING.CRABKING_CLAW_WALK_SPEED
        inst.components.locomotor.runspeed = TUNING.CRABKING_CLAW_RUN_SPEED

        inst:SetStateGraph("SGcrabkingclaw")

        inst:AddComponent("health")
        inst.components.health:SetMaxHealth(TUNING.CRABKING_CLAW_HEALTH)

        inst:AddComponent("combat")
        inst.components.combat:SetDefaultDamage(TUNING.CRABKING_CLAW_PLAYER_DAMAGE)
        inst.components.combat:SetRange(0)
        inst.components.combat.hiteffectsymbol = "claw_parts_shoulder"
        inst.components.combat:SetAttackPeriod(5)

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable("chasni_crabking_claw"..element)

        inst:AddComponent("inspectable")
        inst:AddComponent("timer")
        inst:AddComponent("knownlocations")
        inst:AddComponent("entitytracker")

        inst:SetBrain(brain)

        inst:ListenForEvent("death", OnDead)
        inst:ListenForEvent("onremove", OnDead)
        inst:ListenForEvent("entitysleep", OnEntitySleep)
        inst:ListenForEvent("entitywake", OnEntityWake)

        inst.releaseclamp = releaseclamp
        inst.clamp = clamp
        inst.crunchboat = crunchboat

        if element == "ice" then
            MakeLargeBurnableCharacter(inst, "claw_parts_forearm")
        end
        MakeHugeFreezableCharacter(inst, "claw_parts_forearm")

        inst:AddComponent("teleportedoverride")
        inst.components.teleportedoverride:SetDestPositionFn(teleport_override_fn)
        inst:ListenForEvent("teleported", OnTeleported)

        --------------------------------- ADDITION ---------------------------------
        inst:AddComponent("inventory")
        if element == "water" then
            inst:AddComponent("lightningblocker")
            inst.components.lightningblocker:SetBlockRange(6)
            inst.components.lightningblocker:SetOnLightningStrike(function(i)
                if i.components.health and not i.components.health:IsDead() then
                    i:DoTaskInTime(0.1, function()
                        chasni_spawnprefab("shock_machines_fx", 0, 0.1, 0, 2, 2, 2, i.entity)
                        i:DoTaskInTime(1, function()
                            if i.components.health and not i.components.health:IsDead() then
                                i.components.health:Kill()
                            end
                        end)
                    end)
                end
            end) 
        end

        if element == "electric" then
            inst:AddComponent("moisture")
        end

        inst.castfx = "chasni_"..element.."_crab_king_claw_fx"
        inst.spell = spellfn

        inst.components.timer:StopTimer("attack_cd")
        inst.components.timer:StartTimer("attack_cd", math.random(4, 10))

        inst:ListenForEvent("timerdone", OnTimerDone)
        EquipWeapon(inst)
        ----------------------------------------------------------------------------

        inst.shadow = inst:SpawnChild("crabking_claw_shadow")

        return inst
    end

    return Prefab("chasni_"..element.."crabking_claw", fn, assets, prefabs)
end

return
MakeClaw("fire", FireCastSpell, {"chasni_planarimune", "crabking_claw_fire"}, "chasni_crabking_claw_fire_proj"),
MakeClaw("water", WaterCastSpell, {"chasni_planarimune", "crabking_claw_water"}, "chasni_crabking_claw_water_proj"),
MakeClaw("ice", IceCastSpell, {"chasni_planarimune", "crabking_claw_ice"}, "chasni_crabking_claw_ice_proj"),
MakeClaw("electric", ElectricCastSpell, {"chasni_planarimune", "crabking_claw_electric", "lightningblocker"}, "chasni_crabking_claw_electric_proj"),
MakeClaw("shadow", ShadowCastSpell, {"chasni_planaronly", "crabking_claw_shadow"}, "chasni_crabking_claw_shadow_proj"),
MakeClaw("lunar", LunarCastSpell, {"chasni_planaronly", "crabking_claw_lunar"}, "chasni_crabking_claw_lunar_proj")
