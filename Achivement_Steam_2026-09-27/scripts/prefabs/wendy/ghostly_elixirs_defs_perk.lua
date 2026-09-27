local CHASNILUNAR_DAMAGE = chasni_getitemconfig("elixir", "LDMG") or 10
local CHASNILUNAR_DURATION = chasni_getitemconfig("elixir", "LDUR") or 60 * 16
local SHADOW_DURATION = chasni_getitemconfig("elixir", "SDUR") or 60 * 16
local SHADOW_PLAYER_HEAL = chasni_getitemconfig("elixir", "SHEAL") or 5
local TEMPERATURE_DURATION = chasni_getitemconfig("elixir", "TDUR") or 60 * 16
local TEMPERATURE_ELECTRIC_DAMAGE = chasni_getitemconfig("elixir", "TDAM") or 10
local SLOW_DURATION = chasni_getitemconfig("elixir", "SLDUR") or 60 * 16
local SLOW_SLOW = chasni_getitemconfig("elixir", "SSLW") or 0.5

local function spawnGestaltCommon(inst, target, leader)
    if not target:HasTag("epic") and math.random() < 0.2 then
        return
    end

    if chasni_isValidVictim(target) then
        local x, y, z = target.Transform:GetWorldPosition()
        local gestalt = SpawnPrefab("alterguardianhat_projectile")
        local r = GetRandomMinMax(3, 5)
        local delta_angle = GetRandomMinMax(-90, 90)
        local angle = (inst:GetAngleToPoint(x, y, z) + delta_angle) * DEGREES

        gestalt.Transform:SetPosition(x + r * math.cos(angle), y, z + r * -math.sin(angle))
        gestalt:ForceFacePoint(x, y, z)
        gestalt:SetTargetPosition(Vector3(x, y, z))
        gestalt.components.follower:SetLeader(leader or inst)
    end
end

local function spawngestalt(inst, data)
    spawnGestaltCommon(inst, data.target, inst)
end

local function spawngestaltPlayer(inst, data)
    if inst.components.ghostlybond and inst.components.ghostlybond.ghost then
        spawnGestaltCommon(inst, data.target, inst.components.ghostlybond.ghost)
    end
end

local function shadowHeal(inst, data)
    local buff = inst:GetDebuff("elixir_buff")
    if buff and buff.prefab == "ghostlyelixir_chasnishadow_buff" and data.target and chasni_isValidVictim(data.target) then
        local pos = Vector3(inst.Transform:GetWorldPosition())
        local ents = FindPlayersInRange(pos.x,pos.y,pos.z, 6, true)
        for k,v in pairs(ents) do
            if v.components.health then
                v.components.health:DoDelta(0.1)
            end
        end
    end
end

local function shadowHealPlayer(inst, data)
    local buff = inst:GetDebuff("elixir_buff")
    if buff and buff.prefab == "ghostlyelixir_chasnishadow_buff" and data.target and chasni_isValidVictim(data.target) then
        if inst.components.ghostlybond and inst.components.ghostlybond.ghost then
            local abigail = inst.components.ghostlybond.ghost
            if abigail.components.health then
                abigail.components.health:DoDelta(SHADOW_PLAYER_HEAL)
            end
        end
    end
end

local BLOOM_CHOICES = { ["stalker_bulb"] = .5, ["stalker_bulb_double"] = .5, ["stalker_berry"] = .5, ["stalker_fern"] = 8.5, }
local STALKERBLOOM_TAGS = { "stalkerbloom" }
local function DoPlantBloom(inst)
    local x, _, z = inst.Transform:GetWorldPosition()
    local map = TheWorld.Map
    local offset = FindValidPositionByFan(
            math.random() * PI,
            math.random(),
            1,
            function(offset)
                local x1 = x + offset.x
                local z1 = z + offset.z
                return map:IsPassableAtPoint(x1, 0, z1)
                        and map:IsDeployPointClear(Vector3(x1, 0, z1), nil, 1)
                        and #TheSim:FindEntities(x1, 0, z1, 2.5, STALKERBLOOM_TAGS) < 4
            end
    )

    if offset then
        SpawnPrefab(weighted_random_choice(BLOOM_CHOICES)).Transform:SetPosition(x + offset.x, 0, z + offset.z)
    end
end

local function OnStartBlooming(inst)
    inst._bloomtask = inst:DoPeriodicTask(9 * FRAMES, DoPlantBloom, 2 * FRAMES)
end

local function temperatureAttack(inst, data)
    local buff = inst:GetDebuff("elixir_buff")
    if buff and buff.prefab == "ghostlyelixir_temperature_buff" then
        local target = data and data.target
        if target then
            if TheWorld.state.isspring then
                if target.components.combat then
                    target.components.combat:GetAttacked(inst, TEMPERATURE_ELECTRIC_DAMAGE, nil, "electric")
                end
            elseif TheWorld.state.issummer then
                if target.components.burnable and not target.components.burnable:IsBurning() then
                    if target.components.burnable.canlight or target.components.combat ~= nil then
                        target.components.burnable:Ignite(true, inst)
                    end
                end
            elseif TheWorld.state.iswinter then
                inst:DoTaskInTime(0.1, function()
                    if target and target:IsValid() and target.components.freezable and target:IsValid() then
                        target.components.freezable:AddColdness(1)
                        target.components.freezable:SpawnShatterFX()
                    end
                end)
            end
        end
    end
end

local elixir_defs =
{
    ghostlyelixir_chasnilunar =
    {
        ONAPPLY = function(inst, target)
            inst:AddComponent("sanityaura")
            inst.components.sanityaura.aurafn = function (inst_, observer)
                return observer.prefab == "wendy" and TUNING.SANITYAURA_MED or TUNING.SANITYAURA_SMALL
            end

            if target.components.combat then
                target.components.combat.externaldamagemultipliers:SetModifier("ghostlyelixir_chasnilunar", 0)
                if target.components.planardamage then
                    target.components.planardamage:AddBonus(inst, CHASNILUNAR_DAMAGE, "ghostlyelixir_chasnilunar")
                end
            end

            if target.components.aura then
                target._originalauraradius = target.components.aura.radius
                target.components.aura.radius = 3
            end

            target:ListenForEvent("onareaattackother", spawngestalt)
            target:AddTag("ghostlyelixir_chasnilunar")
        end,
        ONDETACH = function(inst, target)
            if target.components.combat then
                target.components.combat.externaldamagemultipliers:RemoveModifier("ghostlyelixir_chasnilunar")
                if target.components.planardamage then
                    target.components.planardamage:RemoveBonus(inst, CHASNILUNAR_DAMAGE, "ghostlyelixir_chasnilunar")
                end
            end

            if target.components.aura and target._originalauraradius then
                target.components.aura.radius = target._originalauraradius
            end

            target:RemoveEventCallback("onareaattackother", spawngestalt)
            target:RemoveTag("ghostlyelixir_chasnilunar")
        end,
        DURATION = CHASNILUNAR_DURATION,
        fx = "ghostlyelixir_chasnilunar_fx",
        dripfx = "ghostlyelixir_chasnilunar_dripfx",
        FLOATER = {"small", 0.15, 0.55},
        skill_modifier_long_duration = true,

        --PLAYER CONTENT
        DURATION_PLAYER = CHASNILUNAR_DURATION,
        ONAPPLY_PLAYER = function(inst, target)
            inst:AddComponent("sanityaura")
            inst.components.sanityaura.aurafn = function (inst_, observer)
                return observer.prefab == "wendy" and TUNING.SANITYAURA_MED or TUNING.SANITYAURA_SMALL
            end

            target:ListenForEvent("onhitother", spawngestaltPlayer)
            target:AddTag("chasni_gestaltprotection")
        end,
        ONDETACH_PLAYER = function(inst, target)
            target:RemoveEventCallback("onhitother", spawngestaltPlayer)
            target:RemoveTag("chasni_gestaltprotection")
        end,
        fx_player = "ghostlyelixir_chasnilunar_fx",
        dripfx_player = "ghostlyelixir_chasnilunar_dripfx",
    },
    ghostlyelixir_chasnishadow =
    {
        ONAPPLY = function(inst, target)
            inst:AddComponent("sanityaura")
            inst.components.sanityaura.aurafn = function (inst_, observer)
                return observer.prefab == "wendy" and -TUNING.SANITYAURA_SMALL or -TUNING.SANITYAURA_MED
            end

            if target._bloomtask == nil then
                target._bloomtask = target:DoTaskInTime(0, OnStartBlooming)
            end

            target:ListenForEvent("onareaattackother", shadowHeal)
        end,
        TICK_RATE = 20,
        TICK_FN = function(inst, target)
            target.SoundEmitter:PlaySound("dontstarve/ghost/ghost_girl_howl_LP", "howl")
            local pos = Vector3(target.Transform:GetWorldPosition())
            chasni_spawnprefab("blackfx_ring", pos.x, pos.y, pos.z)
            local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 12, {"shadowcreature"})
            target:DoTaskInTime(.2,function()
                for i, v in ipairs(ents) do
                    if v.components.health and not v.components.health:IsDead() and v.components.combat then
                        v.components.combat:GetAttacked(target, v.components.health.currenthealth)
                    end
                end
            end)
        end,
        ONDETACH = function(inst, target)
            if target._bloomtask then
                target._bloomtask:Cancel()
                target._bloomtask = nil
            end

            target:RemoveEventCallback("onareaattackother", shadowHeal)
        end,
        DURATION = SHADOW_DURATION,
        fx = "ghostlyelixir_chasnishadow_fx",
        dripfx = "ghostlyelixir_chasnishadow_dripfx",
        FLOATER = {"small", 0.15, 0.55},
        skill_modifier_long_duration = true,

        --PLAYER CONTENT
        DURATION_PLAYER = SHADOW_DURATION,
        ONAPPLY_PLAYER = function(inst, target)
            inst:AddComponent("sanityaura")
            inst.components.sanityaura.aurafn = function (inst_, observer)
                return observer.prefab == "wendy" and -TUNING.SANITYAURA_SMALL or -TUNING.SANITYAURA_MED
            end

            target:ListenForEvent("onhitother", shadowHealPlayer)
        end,
        ONDETACH_PLAYER = function(inst, target)
            target:RemoveEventCallback("onhitother", shadowHealPlayer)
        end,
        fx_player = "ghostlyelixir_chasnishadow_fx",
        dripfx_player = "ghostlyelixir_chasnishadow_dripfx",
    },
    ghostlyelixir_temperature =
    {
        ONAPPLY = function(inst, target) end,
        TICK_RATE = 20,
        TICK_FN = function(inst, target)
            local pos = Vector3(target.Transform:GetWorldPosition())
            local ents = FindPlayersInRange(pos.x, pos.y, pos.z, 16, true)
            for i, v in ipairs(ents) do
                if v.components.moisture then v.components.moisture:SetMoistureLevel(0) end
                if v.components.temperature then v.components.temperature:SetTemperature(TUNING.BOOK_TEMPERATURE_AMOUNT) end
                chasni_spawnprefab("ghostlyelixir_temperature_dripfx", 0, 0, 0, 1, 1, 1, v.entity)
            end
        end,
        ONDETACH = function(inst, target) end,
        DURATION = TEMPERATURE_DURATION,
        fx = "ghostlyelixir_temperature_fx",
        dripfx = "ghostlyelixir_temperature_dripfx",
        FLOATER = {"small", 0.15, 0.55},
        skill_modifier_long_duration = true,

        --PLAYER CONTENT
        DURATION_PLAYER = SHADOW_DURATION,
        ONAPPLY_PLAYER = function(inst, target)
            target:ListenForEvent("onhitother", temperatureAttack)
        end,
        ONDETACH_PLAYER = function(inst, target)
            target:RemoveEventCallback("onhitother", temperatureAttack)
        end,
        fx_player = "ghostlyelixir_temperature_fx",
        dripfx_player = "ghostlyelixir_temperature_dripfx",
    },
    ghostlyelixir_slow =
    {
        ONAPPLY = function(inst, target) end,
        TICK_RATE = 5,
        TICK_FN = function(inst, target)
            local pos = Vector3(target.Transform:GetWorldPosition())
            local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 16, {"locomotor"}, {"FX", "INLIMBO", "notarget", "noattack", "invisible", "player", "companion", "notaunt"})
            for i, v in ipairs(ents) do
                if v.components.locomotor and v ~= target then
                    v.components.locomotor:SetExternalSpeedMultiplier(v, "ghostlyelixir_slow", SLOW_SLOW)
                    v:DoTaskInTime(5.5, function()
                        v.components.locomotor:RemoveExternalSpeedMultiplier(v, "ghostlyelixir_slow")
                    end)
                    chasni_spawnprefab("ghostlyelixir_slow_dripfx", 0, 0,  0, 1, 1, 1, v.entity)
                end
            end
        end,
        ONDETACH = function(inst, target) end,
        DURATION = SLOW_DURATION,
        fx = "ghostlyelixir_slow_fx",
        dripfx = "ghostlyelixir_slow_dripfx",
        FLOATER = {"small", 0.15, 0.55},
        skill_modifier_long_duration = true,

        --PLAYER CONTENT
        DURATION_PLAYER = SLOW_DURATION,
        ONAPPLY_PLAYER = function(inst, target)
            target:AddTag("ghostlyelixir_slow")
        end,
        ONDETACH_PLAYER = function(inst, target)
            target:RemoveTag("ghostlyelixir_slow")
        end,
        fx_player = "ghostlyelixir_slow_fx",
        dripfx_player = "ghostlyelixir_slow_dripfx",
    },
}

return { elixir_defs = elixir_defs }