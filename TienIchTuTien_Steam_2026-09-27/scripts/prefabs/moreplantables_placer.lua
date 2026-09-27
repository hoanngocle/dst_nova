require "prefabutil"

local folder = KnownModIndex:GetModActualName("Tiện Ích Tu Tiên")
local placers = {}

local function add(config, name, bank, build, animation)
    if GetModConfigData(config, folder) then
        placers[#placers + 1] = MakePlacer(name, bank, build, animation)
    end
end

add("mp_plantseeds", "common/seeds_placer", "flowers", "flowers", "f1")
add("mp_plantnightmarefuel", "common/nightmarefuel_placer", "flowers_evil", "flowers_evil", "f1")
add("mp_plantdurianseeds", "common/durian_seeds_placer", "mandrake", "mandrake", "ground")
add("mp_plantpomegranateseeds", "common/pomegranate_seeds_placer", "berrybush", "berrybush", "idle_dead")
add("mp_plantcutreeds", "common/cutreeds_placer", "grass", "reeds", "idle")
add("mp_plantlightbulb", "common/lightbulb_placer", "bulb_plant_single", "bulb_plant_single", "idle")
add("mp_plantbeefalowool", "common/beefalowool_placer", "egg", "tallbird_egg", "nest")

return unpack(placers)
