local Multis = {}

local function MakeMulti(item)
    local function onbuilt(_, builder)
        if builder.components.moisture ~= nil then
            chasni_giveItem(builder, item.prefab, item.numtogive)
        end
    end

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false
        inst.OnBuiltFn = onbuilt

        return inst
    end

    table.insert(Multis, Prefab(item.prefab.."_multi_cz", fn))
end

local multiitem =
{
    { prefab = "boards", numtogive = 50, },
    { prefab = "papyrus", numtogive = 50, },
    { prefab = "cutstone", numtogive = 50, },
    { prefab = "rope", numtogive = 50, },
    { prefab = "wall_hay_item", numtogive = 200, },
    { prefab = "wall_wood_item", numtogive = 400, },
    { prefab = "wall_stone_item", numtogive = 300, },
    { prefab = "wall_ruins_item", numtogive = 300, },
    { prefab = "wall_scrap_item", numtogive = 200, },
    { prefab = "wall_dreadstone_item", numtogive = 200, },
    { prefab = "wall_moonrock_item", numtogive = 200, },
    { prefab = "fence_item", numtogive = 200, },
    { prefab = "turf_forest", numtogive = 200, },
    { prefab = "turf_grass", numtogive = 200, },
    { prefab = "turf_marsh", numtogive = 200, },
    { prefab = "turf_rocky", numtogive = 200, },
    { prefab = "turf_savanna", numtogive = 200, },
    { prefab = "turf_mud", numtogive = 200, },
    { prefab = "turf_sinkhole", numtogive = 200, },
    { prefab = "turf_fungus", numtogive = 200, },
    { prefab = "turf_fungus_red", numtogive = 200, },
    { prefab = "turf_fungus_green", numtogive = 200, },
    { prefab = "turf_underrock", numtogive = 200, },
    { prefab = "turf_cave", numtogive = 200, },
    { prefab = "turf_woodfloor", numtogive = 200, },
    { prefab = "turf_road", numtogive = 200, },
    { prefab = "turf_carpetfloor", numtogive = 200, },
    { prefab = "turf_checkerfloor", numtogive = 200, },
    { prefab = "turf_deciduous", numtogive = 200, },
    { prefab = "turf_desertdirt", numtogive = 200, },
    { prefab = "turf_beard_rug", numtogive = 200, },
    { prefab = "turf_dragonfly", numtogive = 200, },
    { prefab = "turf_pebblebeach", numtogive = 200, },
    { prefab = "turf_shellbeach", numtogive = 200, },
    { prefab = "turf_meteor", numtogive = 200, },
    { prefab = "turf_fungus_moon", numtogive = 200, },
    { prefab = "turf_archive", numtogive = 200, },
    { prefab = "turf_ruinsbrick", numtogive = 200, },
    { prefab = "turf_ruinsbrick_glow", numtogive = 200, },
    { prefab = "turf_ruinstiles", numtogive = 200, },
    { prefab = "turf_ruinstiles_glow", numtogive = 200, },
    { prefab = "turf_ruinstrim", numtogive = 200, },
    { prefab = "turf_ruinstrim_glow", numtogive = 200, },
    { prefab = "turf_mosaic_grey", numtogive = 200, },
    { prefab = "turf_mosaic_red", numtogive = 200, },
    { prefab = "turf_mosaic_blue", numtogive = 200, },
    { prefab = "turf_carpetfloor2", numtogive = 200, },
    { prefab = "turf_monkey_ground", numtogive = 200, },
    { prefab = "turf_cotl_gold", numtogive = 200, },
    { prefab = "turf_cotl_brick", numtogive = 200, },
    { prefab = "dock_kit", numtogive = 200, },
    { prefab = "cannonball_rock_item", numtogive = 200, },
    { prefab = "gunpowder", numtogive = 50, },
    { prefab = "blowdart_pipe", numtogive = 50, },
    { prefab = "blowdart_fire", numtogive = 50, },
    { prefab = "blowdart_yellow", numtogive = 50, },
    { prefab = "blowdart_sleep", numtogive = 50, },
    { prefab = "bandage", numtogive = 50, },
    { prefab = "healingsalve", numtogive = 50, },
    { prefab = "dock_woodposts_item", numtogive = 50, },
    { prefab = "boatpatch", numtogive = 50, },
}

for _, v in ipairs(multiitem) do
    MakeMulti(v)
end

return unpack(Multis)