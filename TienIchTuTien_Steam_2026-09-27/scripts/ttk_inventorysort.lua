-- Adapted from DJPaul's Sort Inventory 1.9d, Paul Gibbs (DJPaul).
-- CC BY-NC-SA 4.0; see licenses/DJPaul-Sort-Inventory-license.txt.
-- Sort carried storage with the inventory, while nearby chests stay separate.
local M = {}
local resources = {}
local categories = {light = 2, tools = 3, weapons = 4, food = 5,
    armour = 6, resources = 7, misc = 8}
for _, name in ipairs({"twigs", "nightmarefuel", "rope", "goldnugget", "boards",
    "silk", "papyrus", "cutgrass", "thulecite", "cutstone", "flint", "log",
    "livinglog", "pigskin", "thulecite_pieces", "rocks", "nitre"}) do
    resources[name] = true
end

local function number(value)
    return type(value) == "number" and value == value and value or 0
end

local function rank(item, hurt, lights, maxlights)
    local c = item.components
    if c.inventoryitem.canonlygoinpocket then return 1, 0, false end
    if c.armor then return 6, number(c.armor:GetPercent()), false end
    if c.edible and (c.perishable or c.edible.foodtype == "GEARS") then
        return 5, number(hurt and c.edible.healthvalue or c.edible.hungervalue), false
    end
    if c.fueled and (c.lighter or item:HasTag("light")) then
        return lights < maxlights and 2 or 8, number(c.fueled:GetPercent()), true
    end
    if resources[item.prefab] then return 7, 0, false end
    if c.equippable and c.finiteuses and (c.tool or c.terraformer) then
        return 3, number(c.finiteuses:GetUses()), false
    end
    -- Do not call GetDamage(player, nil): modded weapons may require a target.
    if c.weapon then return 4, number(c.weapon.damage), false end
    return 8, 0, false
end

local function busy(c)
    if c.itemslots then
        return c.activeitem ~= nil or c.inst:HasTag("playerghost")
    end
    for player in pairs(c.openlist or {}) do
        local inv = player.components.inventory
        if inv and inv.activeitem then return true end
    end
    return false
end

local function eligible(c)
    return c.inst:IsValid() and not c.readonlycontainer and not c.usespecificslotsforitems
        and c:GetNumSlots() > (c.inst.prefab == "xd_luoshen_huaxia" and 0 or 1)
        and ((c.itemslots ~= nil and c.inst:HasTag("player"))
            or (c.itemslots == nil and (c.type == "chest" or c.type == "pack"
                or c.inst.prefab == "xd_luoshen_huaxia")))
end

local function before(a, b)
    if a.group ~= b.group then return a.group < b.group end
    local byname = a.group == 3 or a.group == 7 or a.group == 8
    if byname and a.name ~= b.name then return a.name < b.name end
    if a.value ~= b.value then return a.value > b.value end
    if a.name ~= b.name then return a.name < b.name end
    return a.slot < b.slot
end

local function sort(c, maxlights)
    if not eligible(c) or busy(c) then return false end
    local slots = c.itemslots or c.slots
    local movable, entries = {}, {}
    local health = c.inst.components.health
    local hurt = health ~= nil and health:GetPercent() <= 0.3
    local lights = 0
    for slot = 1, c:GetNumSlots() do
        local item = slots[slot]
        local ii = item and item.components.inventoryitem
        if item == nil or (ii ~= nil and not ii.islockedinslot
            and not (item.prefab == "xd_luoshen_huaxia" and item.components.container)) then
            movable[#movable + 1] = slot
            if item then
                local group, value, light = rank(item, hurt, lights, maxlights)
                lights = lights + (light and 1 or 0)
                entries[#entries + 1] = {item = item, slot = slot, group = group, value = value,
                    name = type(item.name) == "string" and item.name or item.prefab or ""}
            end
        end
    end
    -- Some modded chests have slot-dependent filters without usespecificslotsforitems.
    -- Validate before stacking or changing any slots; keep their layout intact.
    for _, entry in ipairs(entries) do
        for _, slot in ipairs(movable) do
            if not c:CanTakeItemInSlot(entry.item, slot) then return false end
        end
    end
    table.sort(entries, before)

    -- Stack in place using Klei's API (preserves skins, freshness and moisture).
    -- Consumed items remove themselves from the owner through OnRemoveEntity.
    local kept = {}
    for _, entry in ipairs(entries) do
        local item = entry.item
        if c.acceptsstacks ~= false and item.components.stackable then
            for _, previous in ipairs(kept) do
                local stack = previous.item.components.stackable
                if stack and not stack:IsFull() and stack:CanStackWith(item) then
                    item = stack:Put(item)
                    if item == nil then
                        if slots[entry.slot] == entry.item then
                            slots[entry.slot] = nil
                            c.inst:PushEvent("itemlose", {slot = entry.slot, prev_item = entry.item})
                        end
                        break
                    end
                end
            end
        end
        if item then kept[#kept + 1] = entry end
    end

    local changed, planned = {}, {}
    for i, slot in ipairs(movable) do
        planned[slot] = kept[i] and kept[i].item or nil
        if slots[slot] ~= planned[slot] then
            changed[#changed + 1] = {slot = slot, previous = slots[slot]}
        end
    end
    -- Permute the same table without detaching ownership or toggling infinite stacks.
    -- Replica components and Da Bao Cac's display consume itemlose/itemget events.
    for _, change in ipairs(changed) do slots[change.slot] = planned[change.slot] end
    for _, change in ipairs(changed) do
        if change.previous then
            c.inst:PushEvent("itemlose", {slot = change.slot, prev_item = change.previous})
        end
    end
    for _, change in ipairs(changed) do
        local item = planned[change.slot]
        if item then c.inst:PushEvent("itemget", {slot = change.slot, item = item}) end
    end
    return true
end

function M.Sort(c, maxlights)
    if c == nil or c._ttk_sorting then return false end
    c._ttk_sorting = true
    local ok, result = pcall(sort, c, maxlights or 2)
    c._ttk_sorting = nil
    if not ok then error(result) end
    return result
end

local function findhuaxia(inv, player)
    for inst in pairs(inv.opencontainers or {}) do
        local container = inst.components.container
        if inst.prefab == "xd_luoshen_huaxia" and container
            and container:IsOpenedBy(player) then
            return container
        end
    end
    for slot = 1, inv:GetNumSlots() do
        local item = inv.itemslots[slot]
        if item and item.prefab == "xd_luoshen_huaxia" and item.components.container then
            return item.components.container
        end
    end
    for _, item in pairs(inv.equipslots or {}) do
        if item and item.prefab == "xd_luoshen_huaxia" and item.components.container then
            return item.components.container
        end
    end
end

-- Assign every movable item before touching either storage. The Hua Xia item
-- itself and locked slots remain fixed; rejected placements abort the plan.
local function sortplayerandpack(inv, pack, maxlights, preference)
    if not eligible(inv) or not eligible(pack) or busy(inv) or busy(pack) then
        return false
    end
    local storages = {inv, pack}
    local movable = {{}, {}}
    local entries = {}
    local lights = 0
    local health = inv.inst.components.health
    local hurt = health ~= nil and health:GetPercent() <= 0.3
    for index, c in ipairs(storages) do
        local slots = c.itemslots or c.slots
        for slot = 1, c:GetNumSlots() do
            local item = slots[slot]
            local ii = item and item.components.inventoryitem
            if item == nil or (item ~= pack.inst and ii and not ii.islockedinslot) then
                movable[index][#movable[index] + 1] = slot
                if item then
                    local group, value, light = rank(item, hurt, lights, maxlights)
                    lights = lights + (light and 1 or 0)
                    entries[#entries + 1] = {item = item, slot = slot, source = index,
                        group = group, value = value,
                        name = type(item.name) == "string" and item.name or item.prefab or ""}
                end
            end
        end
    end
    table.sort(entries, before)

    local planned = {{}, {}}
    local function place(entry, index)
        local stack = entry.item.components.stackable
        if index == 2 and pack.acceptsstacks == false and stack
            and stack:StackSize() > 1 then
            return false
        end
        if index == 1 and entry.source == 2 and pack.infinitestacksize
            and stack and stack:IsOverStacked() then
            return false
        end
        for _, slot in ipairs(movable[index]) do
            if planned[index][slot] == nil
                and storages[index]:CanTakeItemInSlot(entry.item, slot) then
                planned[index][slot] = entry.item
                entry.destination = index
                return true
            end
        end
        return false
    end
    for _, entry in ipairs(entries) do
        local preferred = entry.group == categories[preference] and 2 or 1
        if not place(entry, preferred) and not place(entry, 3 - preferred) then
            return nil -- No safe layout exists; leave both storages as they are.
        end
    end

    local changed = {{}, {}}
    for index, c in ipairs(storages) do
        local slots = c.itemslots or c.slots
        for _, slot in ipairs(movable[index]) do
            if slots[slot] ~= planned[index][slot] then
                changed[index][#changed[index] + 1] = {slot = slot, previous = slots[slot]}
            end
        end
    end
    for index, c in ipairs(storages) do
        local slots = c.itemslots or c.slots
        for _, change in ipairs(changed[index]) do
            slots[change.slot] = planned[index][change.slot]
        end
    end
    for index, c in ipairs(storages) do
        for _, change in ipairs(changed[index]) do
            if change.previous then
                c.inst:PushEvent("itemlose", {slot = change.slot, prev_item = change.previous})
            end
        end
    end
    for _, entry in ipairs(entries) do
        if entry.source ~= entry.destination then
            local ii = entry.item.components.inventoryitem
            local stack = entry.item.components.stackable
            if stack and pack.infinitestacksize and entry.source == 2 then
                stack:SetIgnoreMaxSize(false)
            elseif stack and pack.infinitestacksize and entry.destination == 2 then
                stack:SetIgnoreMaxSize(true)
            end
            ii:OnRemoved()
            ii:OnPutInInventory(storages[entry.destination].inst)
            if entry.destination == 1 and entry.item.components.equippable then
                entry.item.components.equippable:ToPocket()
            end
        end
    end
    for index, c in ipairs(storages) do
        for _, change in ipairs(changed[index]) do
            local item = planned[index][change.slot]
            if item then c.inst:PushEvent("itemget", {slot = change.slot, item = item}) end
        end
    end
    return true
end

function M.Install(env, options)
    local G = env.GLOBAL
    if rawget(G, "TTK_INVENTORYSORT_INSTALLED") then return end
    rawset(G, "TTK_INVENTORYSORT_INSTALLED", true)
    options = options or {}
    local maxlights = tonumber(options.maxLights) or 2
    local preference = (options.backpackCategory == "none" or categories[options.backpackCategory])
        and options.backpackCategory or "resources"
    local function sortplayer(player, requested)
        if player == nil or not player:IsValid() or player:HasTag("playerghost") then return end
        local inv = player.components.inventory
        if inv == nil or inv.activeitem ~= nil then return end
        local now = G.GetTime()
        if player._ttk_lastsort and now - player._ttk_lastsort < 0.25 then return end
        player._ttk_lastsort = now
        local overflow = inv:GetOverflowContainer()
        local equipped = inv:GetEquippedItem(G.EQUIPSLOTS.BACK)
        local backcontainer = equipped and equipped.components.container
        local backpack = findhuaxia(inv, player) or backcontainer or overflow
        local selected = (requested == "none" or categories[requested]) and requested or preference
        for inst in pairs(inv.opencontainers or {}) do
            local c = inst.components.container
            if c and c ~= backpack and c ~= overflow and c.type ~= "pack"
                and c:IsOpenedBy(player) then
                M.Sort(c, maxlights)
            end
        end
        local combined = backpack and sortplayerandpack(inv, backpack, maxlights, selected)
        if backpack == nil or combined ~= nil then
            M.Sort(inv, maxlights)
            M.Sort(backpack, maxlights)
        end
        if overflow ~= backpack then M.Sort(overflow, maxlights) end
        if backcontainer ~= backpack and backcontainer ~= overflow then
            M.Sort(backcontainer, maxlights)
        end
    end
    env.AddModRPCHandler(env.modname, "ttk_sort_inventory", sortplayer)
    if not G.TheNet:IsDedicated() and G.TheInput then
        G.TheInput:AddKeyDownHandler(tonumber(options.keybind) or G.KEY_J, function()
            local screen = G.TheFrontEnd:GetActiveScreen()
            local player = G.ThePlayer
            if screen == nil or screen.name ~= "HUD" or player == nil
                or player:HasTag("playerghost") then return end
            if G.TheWorld.ismastersim then
                sortplayer(player)
            else
                env.SendModRPCToServer(env.MOD_RPC[env.modname].ttk_sort_inventory, preference)
            end
        end)
    end
end

return M
