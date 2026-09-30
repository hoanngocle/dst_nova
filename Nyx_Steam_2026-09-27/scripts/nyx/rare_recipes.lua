-- Replacement recipes for character items Nyx can use without complex native skills.
-- Upper mystic crystals are supplied by Than Khi Tu Tien.
-- Each row: product, one boss drop, upper spirit stones, upper mystic crystals, gem, gems.
local RECIPES = {
    {'xd_chenpingan_ygl', 'bearger_fur', 5, 3, 'orangegem', 4},
    {'xd_chenpingan_ygp', 'shroom_skin', 5, 3, 'purplegem', 4},
    {'xd_htz_fjfb', 'shroom_skin', 3, 2, 'purplegem', 3},
    {'xd_htz_qzj', 'dragon_scales', 8, 5, 'redgem', 6},
    {'xd_luoshen_krss', 'shadowheart', 9, 5, 'purplegem', 6},
    {'xd_luoshen_yin', 'shroom_skin', 3, 2, 'purplegem', 3},
    {'xd_wmz_kjb', 'shadowheart', 4, 3, 'purplegem', 4},
    {'xd_wmz_xsj', 'shadowheart', 9, 5, 'purplegem', 6},
    {'xd_wmz_zhf', 'shadowheart', 7, 4, 'purplegem', 5},
}

local M = {}

function M.Register(api)
    local G = api.GLOBAL
    local count = 0
    for _, recipe in ipairs(RECIPES) do
        local product, boss, stones, crystals, gem, gems = recipe[1], recipe[2], recipe[3], recipe[4], recipe[5], recipe[6]
        local alias = 'nyx_' .. product
        if G.AllRecipes == nil or G.AllRecipes[alias] == nil then
            local atlas = 'images/inventoryimages/' .. product .. '.xml'
            G.STRINGS.NAMES[string.upper(alias)] = G.STRINGS.NAMES[string.upper(product)] or product
            G.STRINGS.RECIPE_DESC[string.upper(alias)] = 'Chế tạo vật phẩm của nhân vật khác cho Nyx.'
            api.AddCharacterRecipe(alias, {
                G.Ingredient(boss, 1),
                G.Ingredient('xd_lingshi3', stones, 'images/inventoryimages/xd_lingshi3.xml', nil, 'xd_lingshi3.tex'),
                G.Ingredient('ttk_huyen_tinh_thuong_pham', crystals),
                G.Ingredient(gem, gems),
            }, G.TECH.NONE, {
                product = product,
                atlas = atlas,
                image = product .. '.tex',
                numtogive = 1,
                builder_tag = 'nyx_crafter',
            }, {})
            count = count + 1
        end
    end
    return count
end

return M
