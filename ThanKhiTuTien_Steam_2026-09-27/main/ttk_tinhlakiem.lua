local G = GLOBAL
local lingshi2 = "xd_lingshi2"
table.insert(PrefabFiles, "ttk_tinhlakiem")
G.STRINGS.NAMES.TTK_TINHLAKIEM = "Thủy Kiếm"
G.STRINGS.RECIPE_DESC.TTK_TINHLAKIEM = "Tinh quang kết kiếm, dưỡng bằng binh khí."
G.STRINGS.CHARACTERS.GENERIC.DESCRIBE.TTK_TINHLAKIEM = "100 sát thương, tầm 18, 1.000 độ bền. Tiêu thụ vũ khí khác để nạp; sát thương không đổi khi hết độ bền."
RegisterInventoryItemAtlas("images/inventoryimages/ttk_tinhlakiem.xml", "ttk_tinhlakiem.tex")
AddRecipe2("ttk_tinhlakiem", {
    G.Ingredient(lingshi2, 1,
        "images/inventoryimages/" .. lingshi2 .. ".xml", nil, lingshi2 .. ".tex"),
    G.Ingredient("bluegem", 3),
    G.Ingredient("goldnugget", 6),
}, G.TECH.SCIENCE_TWO, {
    atlas = "images/inventoryimages/ttk_tinhlakiem.xml",
    image = "ttk_tinhlakiem.tex",
    no_deconstruction = true,
}, {"WEAPONS", "MAGIC"})
