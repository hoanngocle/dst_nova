-- Run from the mod directory: lua tests/merge_test.lua
local imports = {}
local env = setmetatable({}, { __index = _G })
-- Match the mod environment: assignments in imported files affect this table.
env.modimport = function(path)
    local file = assert(io.open(path, "rb"), "missing source: " .. path)
    file:close()
    imports[#imports + 1] = path
    env.Assets = { path .. ":asset" }
    env.PrefabFiles = { path .. ":prefab" }
end
assert(loadfile("modmain.lua", "t", env))()
assert(#imports == 5, "all five mod sources must be loaded")
assert(#env.Assets == 5, "assets from earlier sources were lost")
assert(#env.PrefabFiles == 5, "prefab registrations from earlier sources were lost")

-- DST evaluates modinfo in a restricted environment without Lua helpers like ipairs.
local info = { locale = "en", folder_name = "Client_Merged_2026-09-29" }
assert(loadfile("modinfo.lua", "t", info))()
assert(info.name == "Tiện Ích Client", "mod name should match the owner's Vietnamese mod style")
assert(info.author == "Nyx", "mod author should match the owner's mod metadata")
assert(info.description:find("★ Tự động đi bộ", 1, true), "Vietnamese feature list is missing")
assert(info.client_only_mod == true, "merged mod must stay client only")
assert(info.icon_atlas == "modicon.xml" and info.icon == "modicon.tex",
    "mod info must use the supplied artwork")
local atlas = assert(io.open(info.icon_atlas, "rb"))
local xml = atlas:read("*a")
atlas:close()
assert(xml:find('Texture filename="modicon.tex"', 1, true))
local texture = assert(io.open(info.icon, "rb"))
assert(texture:read(4) == "KTEX", "icon must be a DST texture")
texture:close()
assert(#info.configuration_options == 63, "map icon settings should be hidden from the menu")
local names = {}
local headings = {}
for _, option in ipairs(info.configuration_options) do
    if option.name == "" then
        headings[option.label] = true
    else
        assert(not names[option.name], "duplicate config key: " .. option.name)
        names[option.name] = option
    end
end
for _, key in ipairs({ "UI_DISPLAY", "OBC_INITIAL_VIEW_MODE", "DEFAULT_MODE", "HIDECURSOR" }) do
    assert(names[key], "missing configuration option: " .. key)
end
for _, key in ipairs({ "chester_eyebone", "creature_persistent_icons", "persistent_icons", "flower" }) do
    assert(not names[key], "map icon setting should be hidden: " .. key)
end
for _, title in ipairs({ "Tự động đi bộ", "Camera quan sát", "Thả vật phẩm theo lưới", "Đặt công trình theo lưới" }) do
    assert(headings[title], "missing Vietnamese section: " .. title)
end
assert(not headings["Biểu tượng bản đồ"], "map icon section should be hidden")
assert(names.DEFAULT_MODE.label == "Chế độ thả vật phẩm")
assert(names.HIDECURSOR.label == "Ẩn hình vật phẩm trên chuột")
print("merge_test: passed")
