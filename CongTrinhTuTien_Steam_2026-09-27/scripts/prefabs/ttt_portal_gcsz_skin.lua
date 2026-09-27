local portal_skin = require("ttt_portal_skin")

return CreatePrefabSkin("ttt_portal_gcsz", {
    base_prefab = "homesign",
    type = "item",
    rarity = "Loyal",
    skin_tags = { "CRAFTABLE" },
    build_name_override = "ttt_portal_gcsz",
    assets = {
        Asset("ANIM", "anim/ttt_portal_gcsz.zip"),
        Asset("ATLAS", "images/inventoryimages/ttt_portal_gcsz.xml"),
        Asset("IMAGE", "images/inventoryimages/ttt_portal_gcsz.tex"),
    },
    init_fn = function(inst) portal_skin.Apply(inst, "ttt_portal_gcsz") end,
})
