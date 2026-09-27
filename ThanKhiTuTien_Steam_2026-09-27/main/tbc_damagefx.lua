local G = GLOBAL
local tonumber, type, tostring = G.tonumber, G.type, G.tostring
local math, ipairs, table = G.math, G.ipairs, G.table
local Style = require("tbc_damage_style")
local DURATION = tonumber(GetModConfigData("damagefx_duration")) or 2.6
local SPREAD = tonumber(GetModConfigData("damagefx_spread")) or 1.5
local RPC_NAME = "show_damage"

if AddClientModRPCHandler ~= nil then
    AddClientModRPCHandler(modname, RPC_NAME, function(x, y, z, amount, kind, critical, index, count)
        local player = G.ThePlayer
        local hud = player ~= nil and player.HUD or nil
        if hud == nil or hud.popupstats_root == nil or type(amount) ~= "number" or amount <= 0 then
            return
        end
        local Popup = require("widgets/tbc_damage_popup")
        local label = tostring(math.floor(amount * 10 + .5) / 10)
        if label:sub(-2) == ".0" then label = label:sub(1, -3) end
        if critical then label = label .. "!" end
        hud.popupstats_root:AddChild(Popup(label, kind, critical == true,
            G.Vector3(x, y, z), DURATION, SPREAD, index, count))
    end)
end

local function Broadcast(target, amount, kind, critical, index, count)
    if G.AllPlayers == nil or SendModRPCToClient == nil
        or CLIENT_MOD_RPC == nil or CLIENT_MOD_RPC[modname] == nil then return end
    local rpc = CLIENT_MOD_RPC[modname][RPC_NAME]
    if rpc == nil then return end
    local x, y, z = target.Transform:GetWorldPosition()
    for _, player in ipairs(G.AllPlayers) do
        if player.userid ~= nil and player:IsValid()
            and player:GetDistanceSqToPoint(x, y, z) <= 2500 then
            SendModRPCToClient(rpc, player.userid, x, y, z, amount, kind, critical,
                index or 1, count or 1)
        end
    end
end

local function OnCritical(inst, data)
    if data ~= nil and data.target ~= nil then
        local last = inst._tbc_damagefx_last_hit
        if last ~= nil and last.target == data.target then last.critical = true end
    else
        inst._tbc_damagefx_crit_tokens = (inst._tbc_damagefx_crit_tokens or 0) + 1
        inst:DoTaskInTime(0, function(attacker)
            attacker._tbc_damagefx_crit_tokens = 0
        end)
    end
end

local function OnAttacked(inst, data)
    if type(data) ~= "table" then return end
    local amount = tonumber(data.damageresolved)
    if amount == nil or amount <= 0 then return end
    local pending = inst._tbc_damagefx_health_queue
    if pending ~= nil then
        for _, health_hit in ipairs(pending) do
            if not health_hit.combat and math.abs(health_hit.amount - amount) < .11 then
                health_hit.combat = true
                break
            end
        end
    end
    local attacker = data.attacker
    local record = {
        target = inst,
        parts = Style.Parts(data, amount),
        critical = false,
    }
    if attacker ~= nil then
        local tokens = attacker._tbc_damagefx_crit_tokens or 0
        if tokens > 0 then
            record.critical = true
            attacker._tbc_damagefx_crit_tokens = tokens - 1
        end
        attacker._tbc_damagefx_last_hit = record
    end
    inst:DoTaskInTime(0, function(target)
        if target:IsValid() then
            for index, part in ipairs(record.parts) do
                Broadcast(target, part.amount, part.kind,
                    record.critical and index == 1, index, #record.parts)
            end
        end
        if attacker ~= nil and attacker._tbc_damagefx_last_hit == record then
            attacker._tbc_damagefx_last_hit = nil
        end
    end)
end

local function OnHealthDelta(inst, data)
    if type(data) ~= "table" or type(data.amount) ~= "number"
        or data.amount >= 0 then return end
    local health = inst.components ~= nil and inst.components.health or nil
    local amount = health ~= nil and type(data.oldpercent) == "number"
        and type(data.newpercent) == "number"
        and (data.oldpercent - data.newpercent) * health.maxhealth
        or -data.amount
    if amount <= 0 then return end
    local record = {
        amount = amount,
        kind = Style.Classify({ stimuli = data.cause, weapon = data.afflicter }),
        combat = false,
    }
    local queue = inst._tbc_damagefx_health_queue or {}
    queue[#queue + 1] = record
    inst._tbc_damagefx_health_queue = queue
    inst:DoTaskInTime(0, function(target)
        if target:IsValid() and not record.combat then
            Broadcast(target, record.amount, record.kind, false)
        end
        for i, item in ipairs(queue) do
            if item == record then
                table.remove(queue, i)
                break
            end
        end
    end)
end

AddComponentPostInit("health", function(component)
    if G.TheWorld ~= nil and G.TheWorld.ismastersim then
        component.inst:ListenForEvent("healthdelta", OnHealthDelta)
    end
end)

AddComponentPostInit("combat", function(component)
    if G.TheWorld == nil or not G.TheWorld.ismastersim then return end
    local inst = component.inst
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("chasni_docriticalhit", OnCritical)
    inst:ListenForEvent("tbc_docriticalhit", OnCritical)
end)
