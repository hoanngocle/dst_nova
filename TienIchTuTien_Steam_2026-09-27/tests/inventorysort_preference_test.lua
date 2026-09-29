package.path = "TienIchTuTien_Steam_2026-09-27/scripts/?.lua;" .. package.path

local Sort = require("ttk_inventorysort")

local function item(prefab)
    local inventoryitem = {cangoincontainer = true}
    function inventoryitem:OnRemoved() self.owner = nil end
    function inventoryitem:OnPutInInventory(owner) self.owner = owner end
    return {prefab = prefab, name = prefab, components = {inventoryitem = inventoryitem}}
end

local function storage(slots, size, type_name)
    local c = {slots = slots, size = size, type = type_name, openlist = {}}
    function c:GetNumSlots() return self.size end
    function c:CanTakeItemInSlot(obj, slot)
        return obj.components.inventoryitem.cangoincontainer and slot <= self.size
    end
    function c:RemoveItemBySlot(slot)
        local obj = self.slots[slot]
        self.slots[slot] = nil
        if obj then obj.components.inventoryitem.owner = nil end
        return obj
    end
    function c:GiveItem(obj, slot)
        if not self:CanTakeItemInSlot(obj, slot) or self.slots[slot] then return false end
        self.slots[slot] = obj
        obj.components.inventoryitem.owner = self.inst
        return true
    end
    function c:IsOpenedBy() return true end
    return c
end

local function scenario(box_size, box_items, inventory_items, carried, category, requested, prepare)
    local huaxia = item("xd_luoshen_huaxia")
    local box = storage(box_items, box_size, "flower_box")
    box.inst = huaxia
    huaxia.components.container = box
    local inventory_slots = {}
    if carried ~= false then inventory_slots[#inventory_slots + 1] = huaxia end
    for _, obj in ipairs(inventory_items) do inventory_slots[#inventory_slots + 1] = obj end
    local inv = storage(inventory_slots, 5)
    inv.itemslots = inv.slots
    inv.inst = {components = {inventory = inv, health = {GetPercent = function() return 1 end}}}
    local player = inv.inst
    function player:IsValid() return true end
    function player:HasTag(tag) return tag == "player" end
    function player:PushEvent() end
    function huaxia:IsValid() return true end
    function huaxia:PushEvent() end
    for _, obj in pairs(inv.itemslots) do obj.components.inventoryitem.owner = player end
    for _, obj in pairs(box.slots) do obj.components.inventoryitem.owner = huaxia end
    function inv:GetOverflowContainer() return nil end
    function inv:GetEquippedItem() return nil end
    inv.opencontainers = {[huaxia] = true}
    if prepare then prepare(box) end

    local rpc
    local G = {GetTime = function() return 1 end,
        EQUIPSLOTS = {BACK = "BACK", BODY = "BODY"},
        TheNet = {IsDedicated = function() return true end}}
    Sort.Install({GLOBAL = G, modname = "testsort",
        AddModRPCHandler = function(_, _, fn) rpc = fn end},
        {backpackCategory = category or "resources"})
    rpc(player, requested)
    return inv, box, huaxia
end

local inv, box, huaxia = scenario(2, {item("apple"), item("twigs")},
    {item("flint"), item("axe")})
assert(inv.itemslots[1] == huaxia, "the Hua Xia item stays in its inventory slot")
assert(box.slots[1].prefab == "flint" and box.slots[2].prefab == "twigs",
    "configured resources move into the Hua Xia even with a custom container type")
assert(inv.itemslots[2].prefab == "apple" and inv.itemslots[3].prefab == "axe",
    "displaced non-resource items return to inventory")
assert(box.slots[1].components.inventoryitem.owner == huaxia
    and inv.itemslots[2].components.inventoryitem.owner == inv.inst,
    "moved items belong to their new storage")

local full_inv, full_box = scenario(1, {item("twigs")},
    {item("flint"), item("apple")})
assert(full_box.slots[1].prefab == "flint", "preferred item takes the available Hua Xia slot")
assert(full_inv.itemslots[2].prefab == "twigs", "overflow resource stays in inventory")
assert(full_inv.itemslots[3].prefab == "apple", "no item is dropped when Hua Xia is full")

local ground_inv, ground_box = scenario(2, {item("apple")},
    {item("flint"), item("twigs")}, false)
assert(ground_box.slots[1].prefab == "flint" and ground_box.slots[2].prefab == "twigs",
    "an opened Hua Xia is used even when it is not carried")
assert(ground_inv.itemslots[1].prefab == "apple",
    "the opened Hua Xia gives displaced items back to inventory")

local restricted = item("cursed")
restricted.components.inventoryitem.cangoincontainer = false
local restricted_inv, restricted_box, restricted_huaxia = scenario(2,
    {restricted}, {item("flint"), item("apple")})
assert(restricted_inv.itemslots[1] == restricted_huaxia
    and restricted_inv.itemslots[2].prefab == "flint"
    and restricted_box.slots[1] == restricted,
    "an impossible placement leaves both storages untouched")

local spear = item("spear")
spear.components.weapon = {damage = 34}
local weapon_inv, weapon_box = scenario(1, {item("flint")},
    {spear}, true, "resources", "weapons")
assert(weapon_box.slots[1] == spear and weapon_inv.itemslots[2].prefab == "flint",
    "the player's selected category is honored by the server")

local no_pref_inv, no_pref_box = scenario(2, {item("twigs")},
    {item("flint")}, true, "none")
assert(no_pref_inv.itemslots[2].prefab == "flint"
    and no_pref_inv.itemslots[3].prefab == "twigs"
    and no_pref_box.slots[1] == nil,
    "without a preferred category, items fill inventory before Hua Xia")

local stacked = item("twigs")
stacked.components.stackable = {StackSize = function() return 2 end}
local stack_inv, stack_box = scenario(2, {}, {stacked}, true, "resources", nil,
    function(bag) bag.acceptsstacks = false end)
assert(stack_inv.itemslots[2] == stacked and stack_box.slots[1] == nil,
    "a stack is not put into a non-stacking Hua Xia")

local overstacked = item("oversized")
overstacked.components.stackable = {IsOverStacked = function() return true end}
local over_inv, over_box, over_huaxia = scenario(1, {overstacked},
    {item("flint")}, true, "resources", nil,
    function(bag) bag.infinitestacksize = true end)
assert(over_inv.itemslots[1] == over_huaxia and over_inv.itemslots[2].prefab == "flint"
    and over_box.slots[1] == overstacked,
    "an oversized infinite stack never escapes into normal inventory")

local function twigstack()
    local obj = item("twigs")
    local stack = {count = 1}
    function stack:StackSize() return self.count end
    function stack:IsFull() return false end
    function stack:CanStackWith(other) return other.prefab == "twigs" end
    function stack:Put(other)
        self.count = self.count + other.components.stackable.count
        return nil
    end
    obj.components.stackable = stack
    return obj
end
local _, merged_box = scenario(2, {twigstack()}, {twigstack()})
assert(merged_box.slots[1].components.stackable:StackSize() == 2
    and merged_box.slots[2] == nil,
    "matching resource stacks merge after being routed into Hua Xia")

print("inventorysort_preference_test: ok")
