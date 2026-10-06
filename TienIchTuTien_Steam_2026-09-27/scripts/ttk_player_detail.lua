-- Target-independent attack preview and authoritative running speed.
-- Does not roll critical hits or apply enemy armour/alignment modifiers.
local M = {}
local function Number(v)
    return type(v) == "number" and v == v and math.abs(v) < math.huge and v or nil
end
local function Format(v)
    return string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "")
end

function M.Measure(player, source)
    local components = player.components or {}
    local combat, loco = components.combat, components.locomotor
    if combat == nil then return nil end -- Clients use the server snapshot.
    local weapon = combat:GetWeapon()
    local stats = {armed = weapon ~= nil}
    local base
    if weapon ~= nil and weapon.components.weapon ~= nil then
        local w = weapon.components.weapon
        if w.GetDamage ~= nil then
            local ok, value = pcall(w.GetDamage, w, player, nil)
            if ok then base = Number(value) end
        end
        if base == nil then base = Number(w.damage) end
    else
        base = Number(combat.defaultdamage)
        local rider = components.rider
        if rider ~= nil and rider:IsRiding() then
            local mount = rider:GetMount()
            if mount ~= nil and mount.components.combat ~= nil then
                combat = mount.components.combat
                base = Number(combat.defaultdamage)
                stats.mounted = true
            end
            local saddle = rider:GetSaddle()
            if base ~= nil and saddle ~= nil and saddle.components.saddler ~= nil then
                base = base + saddle.components.saddler:GetBonusDamage()
            end
        end
    end
    if base ~= nil then
        local external = combat.externaldamagemultipliers
        stats.damage = Number(base * (combat.damagemultiplier or 1)
            * (external ~= nil and external:Get() or 1) + (combat.damagebonus or 0))
        stats.base_damage = stats.damage
    end
    if loco ~= nil then stats.speed = Number(loco:GetRunSpeed()) end
    local source_item = weapon ~= nil
        and (weapon._tbc_source_item or weapon._source_weapon or weapon) or nil
    local upgrade = source_item ~= nil and source_item.components ~= nil
        and source_item.components.tbc_upgrade or nil
    if upgrade ~= nil and upgrade.IsWeaponMilestone ~= nil
        and upgrade:IsWeaponMilestone() and (upgrade.level or 0) > 0 then
        stats.strengthen_level = upgrade.level
    end
    if source ~= nil then
        if source.combat_stats ~= nil then
            local combat_stats = source.combat_stats(player, weapon)
            if combat_stats ~= nil then
                stats.crit_rate = Number(combat_stats.crit_rate)
                stats.crit_damage = Number(200 + (combat_stats.crit_effect or 0))
                stats.pierce_percent = Number(combat_stats.pierce)
            end
        end
        if source.flat_pierce ~= nil then
            stats.flat_pierce = Number(source.flat_pierce(player, weapon,
                stats.strengthen_level))
        end
        if source.preview_attack ~= nil and stats.damage ~= nil then
            local ok, preview = pcall(source.preview_attack, player, weapon, stats.damage)
            if ok and type(preview) == "table" then
                stats.attack_preview = preview
                stats.damage = Number(preview.total_damage) or Number(preview.damage)
                    or stats.damage
            end
        end
    end
    return stats
end

function M.Encode(stats)
    if stats == nil then return "" end
    return (stats.armed and "w" or stats.mounted and "m" or "u") .. ";"
        .. (stats.damage ~= nil and Format(stats.damage) or "") .. ";"
        .. (stats.speed ~= nil and Format(stats.speed) or "")
        .. ";" .. (stats.crit_rate ~= nil and Format(stats.crit_rate) or "")
        .. ";" .. (stats.crit_damage ~= nil and Format(stats.crit_damage) or "")
        .. ";" .. (stats.pierce_percent ~= nil and Format(stats.pierce_percent) or "")
        .. ";" .. (stats.flat_pierce ~= nil and Format(stats.flat_pierce) or "")
end

function M.Read(player, source)
    if player == nil then return nil end
    if player.HasTag ~= nil and player:HasTag("playerghost") then return nil end
    local snapshot = player._ttk_player_detail
    if (player.components or {}).combat ~= nil then return M.Measure(player, source) end
    local raw = snapshot ~= nil and snapshot:value() or ""
    local mode, damage, speed, crit_rate, crit_damage, pierce_percent, flat_pierce =
        raw:match("^([wmu]);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*)$")
    if mode == nil then
        mode, damage, speed = raw:match("^([wmu]);([^;]*);([^;]*);%d+$")
        if mode == nil then
            mode, damage, speed = raw:match("^([wmu]);([^;]*);([^;]*)$")
        end
    end
    if mode == nil then return nil end
    return {armed=mode=="w", mounted=mode=="m", damage=tonumber(damage),
        speed=tonumber(speed), crit_rate=tonumber(crit_rate),
        crit_damage=tonumber(crit_damage), pierce_percent=tonumber(pierce_percent),
        flat_pierce=tonumber(flat_pierce)}
end

local function DamageRow(row)
    local key = row[1]
    return key == "伤害" or key == "Sát thương" or key == "Sát thương:"
        or type(key) == "string" and (key:find("Sát thương:",1,true)==1
            or key:find("Sát thương tay không:",1,true)==1
            or key:find("Sát thương cơ bản (vũ khí):",1,true)==1
            or key:find("Sát thương cơ bản (thú cưỡi):",1,true)==1)
end

function M.IsPlayerData(data)
    if type(data) ~= "table" or type(data.str) ~= "table" then return false end
    for _, row in ipairs(data.str) do
        if type(row) == "table" and (row[1] == "修仙境界"
            or row[1] == "Cảnh giới tu tiên") then return true end
    end
    return false
end

function M.Augment(data, stats)
    local result = {}
    for k,v in pairs(data) do result[k]=v end
    result.str = {}
    local pierce_bonus = stats.flat_pierce or 0
    local pierce_added = false
    local function Speed()
        if stats.speed ~= nil and #result.str < 40 then
            result.str[#result.str+1] = {"Tốc chạy: " .. Format(stats.speed)}
        end
        for _, entry in ipairs({
            {"Tỷ lệ bạo kích", stats.crit_rate},
            {"Sát thương bạo kích", stats.crit_damage},
            {"Tỷ lệ xuyên giáp", stats.pierce_percent},
        }) do
            if entry[2] ~= nil and #result.str < 40 then
                result.str[#result.str + 1] = {entry[1] .. ": " .. Format(entry[2]) .. "%"}
            end
        end
    end
    local added = false
    for _, row in ipairs(data.str) do
        local copy = {}
        for k,v in pairs(row) do copy[k]=v end
        if DamageRow(row) then
            if not added then
                result.str[#result.str+1] = {"ATK tổng (trước giáp): " ..
                    (stats.damage ~= nil and Format(stats.damage) or "Tùy mục tiêu")}
                Speed()
                added = true
            end
        elseif pierce_bonus > 0 and type(row[1]) == "string"
            and row[1]:find("Sát thương xuyên giáp", 1, true) ~= nil then
            local base = tonumber(row[2])
                or tonumber(row[1]:match("([%d%.]+)%s*$"))
            if base ~= nil then
                copy = {"Sát thương xuyên giáp: " .. Format(base + pierce_bonus)
                    .. " (+" .. Format(pierce_bonus) .. " từ vũ khí)"}
                pierce_added = true
            end
            result.str[#result.str + 1] = copy
        elseif type(row[1]) ~= "string" or row[1]:find("Tốc chạy:",1,true) ~= 1 then
            result.str[#result.str+1] = copy
        end
    end
    if not added then Speed() end
    if pierce_bonus > 0 and not pierce_added and #result.str < 40 then
        result.str[#result.str + 1] = {"Sát thương xuyên giáp từ vũ khí: +"
            .. Format(pierce_bonus)}
    end
    return result
end

function M.Attach(player, G)
    if player._ttk_player_detail ~= nil then return end
    player._ttk_player_detail = G.net_string(player.GUID, "ttk.player_detail", "ttk_player_detail_dirty")
    if not G.TheWorld.ismastersim then return end
    local previous
    local function Sync()
        local ok, stats = pcall(M.Read, player, G.TTK_EQUIPMENT_DETAIL_SOURCE)
        local encoded = ok and M.Encode(stats) or ""
        if encoded ~= previous then player._ttk_player_detail:set(encoded); previous=encoded end
    end
    player:DoPeriodicTask(.5, Sync, 0)
    player:ListenForEvent("equip", function() player:DoTaskInTime(0, Sync) end)
    player:ListenForEvent("unequip", function() player:DoTaskInTime(0, Sync) end)
end

return M
