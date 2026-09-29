package.path = "TienIchTuTien_Steam_2026-09-27/scripts/?.lua;" .. package.path

local Sort = require("ttk_inventorysort")

local function item(name)
    return {name = name, prefab = name,
        components = {inventoryitem = {}}}
end

local function pack(names)
    local container = {type = "pack", slots = {}, openlist = {}}
    for i, name in ipairs(names) do container.slots[i] = item(name) end
    container.inst = {components = {}, IsValid = function() return true end,
        PushEvent = function() end}
    function container:GetNumSlots() return 2 end
    function container:CanTakeItemInSlot() return true end
    return container
end

local back = pack({"twigs", "flint"})
local body = pack({})
local inventory = {itemslots = {}, opencontainers = {}, activeitem = nil}
local sounds = {}
local player = {components = {inventory = inventory},
    SoundEmitter = {PlaySound = function(_, sound) sounds[#sounds + 1] = sound end}}
function player:IsValid() return true end
function player:HasTag(tag) return tag == "player" end
function player:PushEvent() end
inventory.inst = player
function inventory:GetNumSlots() return 2 end
function inventory:CanTakeItemInSlot() return true end
function inventory:GetOverflowContainer() return body end
function inventory:GetEquippedItem(slot)
    if slot == "BACK" then return {components = {container = back}} end
    if slot == "BODY" then return {components = {container = body}} end
end

local rpc, keydown, bound_key, sent
local G = {
    EQUIPSLOTS = {BACK = "BACK", BODY = "BODY"},
    GetTime = function() return 1 end,
    KEY_J = 106,
    TheNet = {IsDedicated = function() return false end},
    TheInput = {AddKeyDownHandler = function(_, key, fn) bound_key, keydown = key, fn end},
    TheFrontEnd = {GetActiveScreen = function() return {name = "HUD"} end},
    TheWorld = {ismastersim = false},
    ThePlayer = player,
}
local env = {GLOBAL = G, modname = "testsort", MOD_RPC = {testsort = {ttk_sort_inventory = 1}},
    AddModRPCHandler = function(_, _, fn) rpc = fn end,
    SendModRPCToServer = function(_, category) sent = category end}
Sort.Install(env)
assert(bound_key == G.KEY_J, 'inventory sorting should bind J')

rpc(player)
assert(back.slots[1].prefab == "flint" and back.slots[2].prefab == "twigs",
    "the equipped BACK pack must sort even when overflow points to BODY")
assert(#sounds == 0, "server-side sorting should not emit Fun Mode sound")

keydown()
assert(sent == "resources", "remote key press sends its backpack preference")
assert(#sounds == 0, "Auto Sort does not play Fun Mode sound on key press")

print("inventorysort_test: ok")
