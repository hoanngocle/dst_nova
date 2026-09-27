local M = {}

M.COLOURS = {
    normal = { 1, .34, .28, 1 },
    true_damage = { 1, 1, 1, 1 },
    burn = { 1, .88, .18, 1 },
    metal = { 1, .85, .43, 1 },
    wood = { .35, .88, .55, 1 },
    water = { .35, .72, 1, 1 },
    fire = { 1, .43, .16, 1 },
    earth = { .92, .76, .38, 1 },
    lightning = { .75, .53, 1, 1 },
    ice = { .55, .9, 1, 1 },
    poison = { .65, .9, .28, 1 },
    shadow = { .72, .47, .88, 1 },
    lunar = { .87, .87, 1, 1 },
    planar = { .82, .78, 1, 1 },
}

local BY_INDEX = { "metal", "wood", "water", "fire", "earth", "lightning" }
local BY_WEAPON = {
    ttk_votuongkiem = "metal",
    ttk_thanhtrucphongvankiem = "wood",
    ttk_phanthienkiem = "fire",
    ttk_tienkiem = "earth",
    ttk_makiem = "lightning",
    ttk_tinhlakiem = "water",
}

local function FromWord(value)
    if type(value) ~= "string" then return nil end
    value = string.lower(value)
    if value:find("pierce", 1, true) or value:find("true", 1, true)
        or value:find("chuan", 1, true) or value:find("pure", 1, true)
        or value:find("ignore_armor", 1, true) then return "true_damage" end
    if value:find("burn", 1, true) or value:find("scorch", 1, true)
        or value:find("thieudot", 1, true) then return "burn" end
    if value:find("lightning", 1, true) or value:find("electric", 1, true)
        or value:find("thunder", 1, true) or value:find("loi", 1, true) then return "lightning" end
    if value:find("poison", 1, true) or value:find("venom", 1, true) then return "poison" end
    if value:find("frost", 1, true) or value:find("cold", 1, true)
        or value:find("ice", 1, true) or value:find("bang", 1, true) then return "ice" end
    if value:find("fire", 1, true)
        or value:find("flame", 1, true) or value:find("hoa", 1, true) then return "fire" end
    if value:find("water", 1, true) or value:find("thuy", 1, true) then return "water" end
    if value:find("wood", 1, true) or value:find("moc", 1, true) then return "wood" end
    if value:find("earth", 1, true) or value:find("tho", 1, true) then return "earth" end
    if value:find("metal", 1, true) or value:find("kim", 1, true) then return "metal" end
    if value:find("shadow", 1, true) or value:find("dark", 1, true) then return "shadow" end
    if value:find("lunar", 1, true) or value:find("moon", 1, true) then return "lunar" end
    if value:find("planar", 1, true) then return "planar" end
    return nil
end

local function EquippedWeapon(data)
    local attacker = data.attacker
    local inventory = attacker ~= nil and attacker.components ~= nil
        and attacker.components.inventory or nil
    return inventory ~= nil and inventory.GetEquippedItem ~= nil
        and inventory:GetEquippedItem(EQUIPSLOTS ~= nil and EQUIPSLOTS.HANDS or nil)
        or nil
end

local function WeaponKind(source)
    if type(source) ~= "table" then return nil end
    local kind = BY_WEAPON[source.prefab] or FromWord(source.prefab)
    if kind ~= nil then return kind end
    local element = source._element or source._element_index or source.ttk_element
    if type(element) == "number" then return BY_INDEX[element] end
    return FromWord(element)
end

function M.PrimaryKind(data)
    if type(data) ~= "table" then return "normal" end
    if data.ttk_damage_kind ~= nil then
        local kind = FromWord(data.ttk_damage_kind)
        if kind ~= nil then return kind end
    end
    local kind = FromWord(data.stimuli)
    if kind ~= nil then return kind end
    return WeaponKind(data.weapon) or WeaponKind(EquippedWeapon(data)) or "normal"
end

function M.Classify(data)
    local kind = M.PrimaryKind(data)
    if kind ~= "normal" then return kind end
    if type(data) == "table" and type(data.spdamage) == "table" then
        for key, amount in pairs(data.spdamage) do
            if type(amount) == "number" and amount > 0 then
                kind = FromWord(key)
                if kind ~= nil then return kind end
            end
        end
    end
    return "normal"
end

function M.ExtraKind(data)
    if type(data) ~= "table" then return "normal" end
    local explicit = FromWord(data.ttk_damage_kind)
    if explicit ~= nil then return explicit end
    local stimuli = type(data.stimuli) == "string" and string.lower(data.stimuli) or ""
    local is_extra = stimuli:find("auxiliary", 1, true)
        or stimuli:find("affix", 1, true)
        or stimuli:find("burn", 1, true)
        or stimuli:find("poison", 1, true)
        or stimuli:find("dot", 1, true)
        or stimuli:find("pierce", 1, true)
        or stimuli:find("true", 1, true)
    if not is_extra then return M.PrimaryKind(data) end
    local kind = FromWord(stimuli)
    if kind ~= nil then return kind end
    return WeaponKind(data.weapon) or WeaponKind(EquippedWeapon(data)) or "normal"
end

-- Keep the displayed parts proportional to the actual health loss after defense.
function M.Parts(data, total)
    local specials = {}
    local special_total = 0
    if type(data.spdamage) == "table" then
        for key, value in pairs(data.spdamage) do
            local kind = FromWord(key)
            if type(value) == "number" and value > 0 and kind ~= nil then
                specials[#specials + 1] = {kind = kind, amount = value}
                special_total = special_total + value
            end
        end
    end
    if special_total == 0 then
        return {{kind = M.ExtraKind(data), amount = total}}
    end
    table.sort(specials, function(a, b) return a.kind < b.kind end)
    local raw_total = type(data.damage) == "number" and data.damage or total
    local factor = raw_total > 0 and math.min(1, total / raw_total) or 1
    local extra = math.min(total, special_total * factor)
    local base = total - extra
    local parts = {}
    if base > .05 then
        parts[#parts + 1] = {kind = M.ExtraKind(data), amount = base}
    end
    local remaining = extra
    for index, entry in ipairs(specials) do
        local amount = index == #specials and remaining
            or math.min(remaining, entry.amount * factor)
        if amount > .05 then
            parts[#parts + 1] = {kind = entry.kind, amount = amount}
        end
        remaining = remaining - amount
    end
    return parts
end

return M
