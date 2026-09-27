local G = GLOBAL

modimport("main/ttk_vankiem_controls.lua")

G.STRINGS.NAMES.TTK_VANKIEMQUYTONG = "Vạn Kiếm Quy Tông"
G.STRINGS.RECIPE_DESC.TTK_VANKIEMQUYTONG =
    "Sáu phi kiếm nguyên tố hộ thân, lần lượt ngự địch."
G.STRINGS.CHARACTERS.GENERIC.DESCRIBE.TTK_VANKIEMQUYTONG =
    "Sáu kiếm bay quanh người, lần lượt lao tới quái trong tầm 24 rồi quay về."

RegisterInventoryItemAtlas(
    "images/inventoryimages/ttk_vankiemquytong.xml",
    "ttk_vankiemquytong.tex"
)

AddRecipe2("ttk_vankiemquytong", {
    G.Ingredient("ttk_votuongkiem", 1),
    G.Ingredient("ttk_thanhtrucphongvankiem", 1),
    G.Ingredient("ttk_tinhlakiem", 1),
    G.Ingredient("ttk_phanthienkiem", 1),
    G.Ingredient("ttk_tienkiem", 1),
    G.Ingredient("ttk_makiem", 1),
}, G.TECH.MAGIC_THREE, {
    atlas = "images/inventoryimages/ttk_vankiemquytong.xml",
    image = "ttk_vankiemquytong.tex",
    no_deconstruction = true,
}, { "WEAPONS", "MAGIC" })
