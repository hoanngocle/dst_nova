-- Run from the mod directory: lua tests/geometric_drop_test.lua
local function new_fixture()
    local spawned = {}
    local function new_placer()
        local placer = { valid = true, visible = false }
        function placer:IsValid() return self.valid end
        function placer:Show() self.visible = true end
        function placer:Hide() self.visible = false end
        placer.AnimState = { PlayAnimation = function() end }
        placer.Transform = {
            SetScale = function() end,
            SetPosition = function(_, x, y, z)
                if not placer.valid then error("SetPosition on removed placer") end
                placer.position = { x = x, y = y, z = z }
            end,
        }
        spawned[#spawned + 1] = placer
        return placer
    end

    local active_item = { replica = { inventoryitem = {} } }
    local key_up = {}
    local icon = { visible = true }
    local invbar = { hovertile = { image = icon } }
    function invbar:SetHoverTileHideModifier(source, hidden)
        assert(source == "geometric_drop")
        self.hidden = hidden
        icon.visible = not hidden
    end
    local inventory = { GetActiveItem = function() return active_item end }
    local player = {
        HUD = { HasInputFocus = function() return false end, controls = { inv = invbar } },
        replica = { inventory = inventory },
    }
    local input = {
        GetWorldPosition = function() return { x = 8, y = 0, z = 12 } end,
        GetWorldEntityUnderMouse = function() return nil end,
        IsControlPressed = function(_, control) return control == 1 end,
        AddKeyUpHandler = function(_, key, fn) key_up[key] = fn end,
        AddKeyDownHandler = function() end,
    }
    local global = {
        TheNet = { IsDedicated = function() return false end },
        TheInput = input,
        ThePlayer = player,
        TheWorld = {},
        SpawnPrefab = new_placer,
        BufferedAction = function() return {} end,
        ACTIONS = { DROP = { code = 1 } },
        CONTROL_FORCE_STACK = 1,
        rawget = rawget,
        KEY_H = 104,
        KEY_BACKSLASH = 92,
    }
    local callback
    local configs = {
        PLACERS_START_VISIBLE = true,
        DEFAULT_DROP_RESOLUTION = 2,
        DEFAULT_DROP_OFFSET = 1,
        DEFAULT_MODE = "grid",
        TOGGLE_ENABLED_KEY = "KEY_H",
    }
    local env = setmetatable({
        GLOBAL = global,
        Asset = function() return {} end,
        GetModConfigData = function(name) return configs[name] end,
        AddComponentPostInit = function(name, fn)
            if name == "playercontroller" then callback = fn end
        end,
        AddClassPostConstruct = function() end,
        TheFrontEnd = { GetActiveScreen = function() return { name = "HUD" } end },
    }, { __index = _G })
    local chunk = assert(loadfile("sources/geometric_drop.lua", "t", env))
    chunk()
    local controller = {
        GetLeftMouseAction = function() return nil end,
        OnLeftClick = function() end,
        OnUpdate = function() end,
    }
    callback(controller)
    return {
        controller = controller,
        spawned = spawned,
        icon = icon,
        invbar = invbar,
        key_up = key_up,
        set_active_item = function(item) active_item = item end,
    }
end

local function test_restores_picked_origin_after_placer_removal()
    local f = new_fixture()
    f.controller:OnUpdate(0)
    assert(f.key_up[104] == nil, 'legacy H must not remain bound')
    f.key_up[92]() -- Control+backslash picks the grid origin.
    local old_origin = f.spawned[10]
    assert(old_origin.position.x == 8.5)
    old_origin.valid = false
    f.controller:OnUpdate(0)
    local new_origin = f.spawned[#f.spawned]
    assert(new_origin.position ~= nil and new_origin.position.x == 8.5,
        "recreated origin placer must keep the picked origin")
end

local function test_replaces_removed_placer_before_positioning()
    local f = new_fixture()
    f.controller:OnUpdate(0)
    local removed = f.spawned[6] -- adjacent placer [4]
    removed.valid = false
    f.controller:OnUpdate(0)
    assert(#f.spawned > 10, "removed placer was not recreated")
    assert(f.spawned[#f.spawned].position ~= nil, "the replacement must receive a position")
end

local function test_keeps_cursor_icon_visible_while_dropping()
    local f = new_fixture()
    f.controller:OnUpdate(0)
    assert(f.icon.visible == true, "active drop item should remain visible on the cursor")
    assert(f.invbar.hidden == nil, "Geometric Drop should not change cursor visibility")
    f.set_active_item(nil)
    f.controller:OnUpdate(0)
    assert(f.icon.visible == true, "cursor icon should stay visible after dropping")
end

local function test_does_not_override_placement_cursor_visibility()
    local f = new_fixture()
    f.controller.placer = {}
    f.icon.visible = false -- Geometric Placement already hid it.
    f.controller:OnUpdate(0)
    assert(f.icon.visible == false, "drop cursor handling must leave placement visibility alone")
end

test_replaces_removed_placer_before_positioning()
test_restores_picked_origin_after_placer_removal()
test_keeps_cursor_icon_visible_while_dropping()
test_does_not_override_placement_cursor_visibility()
print("geometric_drop_test: passed")
