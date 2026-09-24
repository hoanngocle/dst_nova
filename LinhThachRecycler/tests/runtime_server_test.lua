local pricing = require("nova_lingshi_pricing")

local passed = 0

local function check(condition, message)
    if not condition then
        error("[LTR TEST] " .. message)
    end
    passed = passed + 1
end

local function mock_item(prefab, options)
    options = options or {}
    local components = {}

    if options.count ~= nil then
        components.stackable = {
            StackSize = function()
                return options.count
            end,
        }
    end
    if options.percent ~= nil then
        components.finiteuses = {
            GetPercent = function()
                return options.percent
            end,
        }
    end
    if options.nested then
        components.container = {
            IsEmpty = function()
                return false
            end,
        }
    end

    return {
        prefab = prefab,
        components = components,
        IsValid = function()
            return true
        end,
        HasTag = function(_, tag)
            return options.irreplaceable and tag == "irreplaceable"
        end,
    }
end

local function quote(prefab, options)
    return pricing.GetItemQuote(mock_item(prefab, options), {})
end

check(quote("cutgrass", { count = 2 }).units == 2, "two grass must equal one stone")
check(quote("xd_baihu_skin").units == 24, "curated Tu Tien rare value must apply")
check(quote("gears", { count = 4, percent = 0.5 }).units == 12,
    "durability must be applied before stack multiplication")
check(not quote("xd_lingshi1").accepted, "currency must be rejected")
check(not quote("eye_bone").accepted, "protected items must be rejected")
check(not quote("backpack", { nested = true }).accepted, "non-empty containers must be rejected")
check(not pricing.GetItemQuote(mock_item("rope"), {
        exploit = {
            product = "rope",
            numtogive = 2,
            ingredients = {
                { type = "cutgrass", amount = 1 },
            },
        },
    }).accepted,
    "profitable multi-output recipes must be rejected")

local actor = { userid = "ltr-runtime-test" }

local grass_machine = SpawnPrefab("nova_lingshi_recycler")
local grass = SpawnPrefab("cutgrass")
grass.components.stackable:SetStackSize(2)
check(grass_machine.components.container:GiveItem(grass, 1, nil, false),
    "machine must accept a grass stack")
check(grass_machine:TryRefine(actor) and grass_machine._balance_units == 2,
    "refining two grass must credit exactly one stone")

local confirmation_machine = SpawnPrefab("nova_lingshi_recycler")
local rare = SpawnPrefab("deerclops_eyeball")
check(confirmation_machine.components.container:GiveItem(rare, 1, nil, false),
    "machine must accept a rare item")
check(not confirmation_machine:TryRefine(actor)
        and confirmation_machine._balance_units == 0
        and confirmation_machine.components.container:GetItemInSlot(1) == rare
        and confirmation_machine._nova_confirm:value(),
    "first high-value action must arm confirmation without consuming")
local revision_item = SpawnPrefab("cutgrass")
check(confirmation_machine.components.container:GiveItem(revision_item, 2, nil, false)
        and not confirmation_machine._nova_confirm:value()
        and confirmation_machine.components.container:GetItemInSlot(1) == rare,
    "slot changes must invalidate a pending confirmation")
local removed_revision_item = confirmation_machine.components.container:RemoveItemBySlot(2)
removed_revision_item:Remove()
check(not confirmation_machine:TryRefine(actor)
        and confirmation_machine._balance_units == 0
        and confirmation_machine.components.container:GetItemInSlot(1) == rare,
    "changed contents must require a fresh first confirmation")
check(confirmation_machine:TryRefine(actor)
        and confirmation_machine._balance_units == 20
        and confirmation_machine.components.container:GetItemInSlot(1) == nil,
    "second matching action must consume and credit the rare item")

local rejected_machine = SpawnPrefab("nova_lingshi_recycler")
local currency = SpawnPrefab("xd_lingshi1")
local accepted_grass = SpawnPrefab("cutgrass")
check(rejected_machine.components.container:GiveItem(currency, 1, nil, false)
        and rejected_machine.components.container:GiveItem(accepted_grass, 2, nil, false),
    "machine must accept mixed test inputs")
check(rejected_machine:TryRefine(actor)
        and rejected_machine._balance_units == 1
        and rejected_machine.components.container:GetItemInSlot(1) == currency
        and rejected_machine.components.container:GetItemInSlot(2) == nil,
    "refine must consume accepted slots and leave rejected slots untouched")

local save_data = {}
rejected_machine._balance_units = 3
rejected_machine.OnSave(rejected_machine, save_data)
local loaded_machine = SpawnPrefab("nova_lingshi_recycler")
loaded_machine.OnLoad(loaded_machine, save_data)
check(loaded_machine._balance_units == 3, "save/load must preserve fractional credit")

local full_machine = SpawnPrefab("nova_lingshi_recycler")
full_machine._balance_units = 2
local rejected_stone = nil
local fake_inventory = {
    ignorefull = false,
    GiveItem = function(_, stone)
        rejected_stone = stone
        return nil
    end,
}
check(not full_machine:TryWithdraw({ components = { inventory = fake_inventory } })
        and full_machine._balance_units == 2
        and fake_inventory.ignorefull == false
        and rejected_stone ~= nil
        and not rejected_stone:IsValid(),
    "full inventory must keep credit, restore flags, and remove rejected spawn")

local delivery_machine = SpawnPrefab("nova_lingshi_recycler")
delivery_machine._balance_units = 5
local delivered = 0
local accepting_inventory = {
    ignorefull = false,
    GiveItem = function(_, stone)
        delivered = delivered + 1
        stone:Remove()
        return 1
    end,
}
check(delivery_machine:TryWithdraw({ components = { inventory = accepting_inventory } })
        and delivered == 2
        and delivery_machine._balance_units == 1
        and accepting_inventory.ignorefull == false,
    "successful withdrawal must charge only delivered stones and keep fractional remainder")

grass_machine:Remove()
confirmation_machine:Remove()
rejected_machine:Remove()
loaded_machine:Remove()
full_machine:Remove()
delivery_machine:Remove()

print("[LTR TEST] PASS " .. tostring(passed) .. " runtime assertions")
