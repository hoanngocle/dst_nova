local G = GLOBAL

table.insert(PrefabFiles, "nova_treasure_scroll")
table.insert(PrefabFiles, "nova_treasure_site")

AddMinimapAtlas("images/hh_icon/hh_items.xml")
RegisterInventoryItemAtlas(
    "images/vat_pham_inventory_so_1.xml",
    "tam_bao_quyen_truc_inventory.tex"
)

G.STRINGS.NAMES.NOVA_TREASURE_SCROLL = "Tầm Bảo Quyển Trục"
G.STRINGS.CHARACTERS.GENERIC.DESCRIBE.NOVA_TREASURE_SCROLL = "Chỉ tới một kho báu bí mật."
G.STRINGS.NAMES.NOVA_TREASURE_SITE = "Kho Báu"
G.STRINGS.CHARACTERS.GENERIC.DESCRIBE.NOVA_TREASURE_SITE = "Dùng xẻng đào lên."
G.STRINGS.RECIPE_DESC.NOVA_TREASURE_SCROLL_A = "Chỉ vị trí chính xác của kho báu."
G.STRINGS.RECIPE_DESC.NOVA_TREASURE_SCROLL_B = "Chỉ vị trí chính xác của kho báu."

local function RecipeOptions()
    return {
        no_deconstruction = true,
        product = "nova_treasure_scroll",
        numtogive = 1,
        atlas = "images/vat_pham_inventory_so_1.xml",
        image = "tam_bao_quyen_truc_inventory.tex",
    }
end

AddRecipe2(
    "nova_treasure_scroll_a",
    { G.Ingredient("stinger", 40) },
    G.TECH.NONE,
    RecipeOptions(),
    { "MODS", "REFINE" }
)
AddRecipe2(
    "nova_treasure_scroll_b",
    { G.Ingredient("silk", 40), G.Ingredient("spidergland", 20) },
    G.TECH.NONE,
    RecipeOptions(),
    { "MODS", "REFINE" }
)

local open = G.Action({ priority = 5, mount_valid = false })
open.id = "NOVA_TREASURE_OPEN"
open.str = "Mở"
open.rmb = true
open.fn = function(act)
    local scroll = act.invobject
    return scroll ~= nil
        and act.doer ~= nil
        and scroll.OpenTreasure ~= nil
        and scroll:OpenTreasure(act.doer)
end
AddAction(open)

AddComponentAction("INVENTORY", "inventoryitem", function(item, doer, actions)
    if item:HasTag("nova_treasure_scroll")
        and doer:HasTag("player")
        and not doer:HasTag("playerghost")
    then
        actions[#actions + 1] = G.ACTIONS.NOVA_TREASURE_OPEN
    end
end)
AddStategraphActionHandler("wilson", G.ActionHandler(G.ACTIONS.NOVA_TREASURE_OPEN, "dolongaction"))
AddStategraphActionHandler("wilson_client", G.ActionHandler(G.ACTIONS.NOVA_TREASURE_OPEN, "dolongaction"))
