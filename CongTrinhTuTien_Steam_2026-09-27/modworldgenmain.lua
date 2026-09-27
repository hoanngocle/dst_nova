GLOBAL.setmetatable(env, {__index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end})

local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")

------------------------------------------------------------------------------------

local GROUND_OCEAN_COLOR = -- Color for the main island ground tiles
{
    primary_color =         {  0,   0,   0,  25 },
    secondary_color =       { 0,  20,  33,  0 },
    secondary_color_dusk =  { 0,  20,  33,  80 },
    minimap_color =         { 46,  32,  18,  64 },
}

local registered_ids = GLOBAL.rawget(GLOBAL, "CONGTRINHTUTIEN_CARPET_TILE_IDS")
if registered_ids == nil then
registered_ids = {}
for i = 1, 15 do
    local tile_name = "PY_CARPET"..tostring(i)
    AddTile(
        tile_name, --tile_name 1
        "LAND", --tile_range 2
        { --tile_data 3
            ground_name = "py_carpet"..tostring(i),
        },
        { --ground_tile_def 4
            name = "py_carpet.tex",
            atlas = "py_carpet.xml",
            noise_texture = "py_carpet"..tostring(i).."_noise.tex",
            runsound = "dontstarve/movement/run_dirt",
            walksound = "dontstarve/movement/walk_dirt",
            snowsound = "dontstarve/movement/run_ice",
            mudsound = "dontstarve/movement/run_mud",
            colors = GROUND_OCEAN_COLOR
        },
        { --minimap_tile_def 5
            name = "py_carpet.tex",
            atlas = "py_carpet.xml",
            noise_texture = "py_carpet"..tostring(i).."_noise.tex"
        },
        { --turf_def 6
            name = "py_carpet"..tostring(i),
            anim = "carpet"..tostring(i),
            bank_build = "py_turf"
        }
    )
    registered_ids[tile_name] = GLOBAL.WORLD_TILES[tile_name]
    ChangeTileRenderOrder(GLOBAL.WORLD_TILES[tile_name], GLOBAL.WORLD_TILES.CARPET)
    ChangeMiniMapTileRenderOrder(GLOBAL.WORLD_TILES[tile_name], GLOBAL.WORLD_TILES.CARPET)
end
GLOBAL.rawset(GLOBAL, "CONGTRINHTUTIEN_CARPET_TILE_IDS", registered_ids)
else
    for i = 1, 15 do
        local tile_name = "PY_CARPET"..tostring(i)
        assert(GLOBAL.WORLD_TILES[tile_name] == registered_ids[tile_name],
            "Carpet tile ID changed during frontend reload: "..tile_name)
    end
end
































