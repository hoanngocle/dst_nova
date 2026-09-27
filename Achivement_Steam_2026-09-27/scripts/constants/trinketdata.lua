local MODDED_TRINKETS = {
    sunken_boat_trinket_4 = true,                                               -- Sea Worther
    kyno_earring = true, earring = true,                                        -- One True Earring
    trinket_giftshop_1 = true, trinket_ham_1 = true,                            -- Queen Malfalfa
    trinket_giftshop_3 = true, trinket_ham_3 = true,                            -- Post Card of the Royal
    trinket_giftshop_4 = true,                                                  -- Can of Silly String
    trinket_ia_13 = true, kyno_sodacan = true, trinket_sw_13 = true,            -- Orange Soda
    trinket_ia_14 = true, trinket_sw_14 = true,                                 -- Voodoo Doll
    trinket_ia_15 = true, trinket_sw_15 = true,                                 -- Ukulele
    trinket_ia_16 = true, trinket_sw_16 = true,                                 -- License Plate
    sunken_boat_trinket_5 = true, trinket_ia_17 = true, trinket_sw_17 = true,   -- Old Boot
    trinket_ia_18 = true, trinket_sw_18 = true,                                 -- Ancient Vase
    trinket_ia_19 = true, trinket_sw_19 = true,                                 -- Brain Cloud Pill
    sunken_boat_trinket_1 = true, trinket_ia_20 = true, trinket_sw_20 = true,   -- Sextant
    sunken_boat_trinket_2 = true, trinket_ia_21 = true, trinket_sw_21 = true,   -- Toy Boat
    trinket_ia_22 = true, trinket_sw_22 = true,                                 -- Wine Bottle Candle
    sunken_boat_trinket_3 = true,                                               -- Soaked Candle
    trinket_ia_23 = true, trinket_sw_23 = true,                                 -- Broken AAC Device
}
local TRINKET_ASSOC = {
    ["trinket_chasni_3"]   = { "sunken_boat_trinket_4", },
    ["trinket_chasni_4"]   = { "kyno_earring", "earring", },
    ["trinket_chasni_5"]   = { "trinket_giftshop_1", "trinket_ham_1", },
    ["trinket_chasni_7"]   = { "trinket_giftshop_3", "trinket_ham_3", },
    ["trinket_chasni_8"]   = { "trinket_giftshop_4", },
    ["trinket_chasni_9"]   = { "trinket_ia_13", "kyno_sodacan", "trinket_sw_13", },
    ["trinket_chasni_10"]  = { "trinket_ia_14", "trinket_sw_14", },
    ["trinket_chasni_11"]  = { "trinket_ia_15", "trinket_sw_15", },
    ["trinket_chasni_12"]  = { "trinket_ia_16", "trinket_sw_16", },
    ["trinket_chasni_13"]  = { "sunken_boat_trinket_5", "trinket_ia_17", "trinket_sw_17", },
    ["trinket_chasni_14"]  = { "trinket_ia_18", "trinket_sw_18", },
    ["trinket_chasni_15"]  = { "trinket_ia_19", "trinket_sw_19", },
    ["trinket_chasni_16"]  = { "sunken_boat_trinket_1", "trinket_ia_20", "trinket_sw_20", },
    ["trinket_chasni_17"]  = { "sunken_boat_trinket_2", "trinket_ia_21", "trinket_sw_21", },
    ["trinket_chasni_18a"] = { "trinket_ia_22", "trinket_sw_22", },
    ["trinket_chasni_18b"] = { "sunken_boat_trinket_3", },
    ["trinket_chasni_19"]  = { "trinket_ia_23", "trinket_sw_23", },
}
local CHASNI_TRINKET_ASSOC = {}
for cz, others in pairs(TRINKET_ASSOC) do
    CHASNI_TRINKET_ASSOC[cz] = others
    for _, prefab in ipairs(others) do
        CHASNI_TRINKET_ASSOC[prefab] = { cz }
    end
end
return {
    modded_trinkets = MODDED_TRINKETS,
    trinket_association = CHASNI_TRINKET_ASSOC
} 