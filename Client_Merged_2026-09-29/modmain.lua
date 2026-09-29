-- Keep each upstream mod in its own Lua chunk. Their file-local variables stay
-- separate, while the mod environment still exposes the DST hooks they install.
local merged_assets = {}
local merged_prefabs = {}
local sources = {
    "sources/auto_walking.lua",
    "sources/observer_camera.lua",
    "sources/extended_map_icons.lua",
    "sources/geometric_drop.lua",
    "sources/geometric_placement.lua",
}

for _, path in ipairs(sources) do
    Assets = {}
    PrefabFiles = {}
    modimport(path)
    for _, asset in ipairs(Assets) do
        merged_assets[#merged_assets + 1] = asset
    end
    for _, prefab in ipairs(PrefabFiles) do
        merged_prefabs[#merged_prefabs + 1] = prefab
    end
end

Assets = merged_assets
PrefabFiles = merged_prefabs
