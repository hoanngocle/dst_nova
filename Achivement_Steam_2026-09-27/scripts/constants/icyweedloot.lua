local Data = {
    version = 1,
    guaranteed = { prefab = "xd_lingshi1", min = 2, max = 4 },
    fallback = { prefab = "xd_lingshi1", min = 2, max = 4 },
    emergency = { prefab = "goldnugget", min = 1, max = 2 },
    rows = {},
}

local function Add(group, prefab, weight, minimum, maximum)
    Data.rows[#Data.rows + 1] = {
        group = group, prefab = prefab, weight = weight,
        min = minimum, max = maximum or minimum,
    }
end

-- Weights sum to 1000; each icyweed rolls this table twice independently.
Add("tutien", "xd_lc_hsc_seed", 100, 1, 2)
Add("tutien", "xd_lc_qfx_seed", 40, 1)
Add("tutien", "xd_lc_cyh_seed", 40, 1)
Add("tutien", "xd_lc_lmg_seed", 40, 1)
Add("tutien", "xd_lingshi1", 25, 5, 8)
Add("tutien", "xd_lingshi2", 5, 1)

Add("solo", "hh_essence", 200, 1, 2)
Add("solo", "ttk_huyen_tinh_ha_pham", 120, 1, 2)
Add("solo", "ttk_huyen_tinh_trung_pham", 30, 1)
Add("solo", "hh_effect_tally", 90, 1)
Add("solo", "hh_remove_stone", 60, 1)
Add("solo", "ac_refreshstone", 30, 1)
Add("solo", "ad_cleanstone", 20, 1)

Add("dst", "goldnugget", 40, 1, 2)
Add("dst", "saltrock", 20, 1, 2)
Add("dst", "moonrocknugget", 20, 1)
Add("dst", "moonglass", 20, 1)
Add("dst", "thulecite", 20, 1)
Add("dst", "gears", 20, 1)
Add("dst", "dreadstone", 10, 1)
Add("dst", "wagpunk_bits", 10, 1)
Add("dst", "lunarplant_husk", 10, 1)
Add("dst", "purebrilliance", 10, 1)
Add("dst", "horrorfuel", 10, 1)
Add("dst", "voidcloth", 10, 1)

return Data
