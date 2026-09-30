package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path

local expected = {
    'xd_chenpingan_ygl', 'xd_chenpingan_ygp',
    'xd_htz_fjfb', 'xd_htz_qzj',
    'xd_luoshen_krss', 'xd_luoshen_yin',
    'xd_wmz_kjb', 'xd_wmz_xsj', 'xd_wmz_zhf',
}
local excluded = {
    'xd_wmz_tnz', -- owned by Cong Trinh Tu Tien
    'xd_chenpingan_bd', 'xd_chenpingan_cm', 'xd_chenpingan_kcd', 'xd_chenpingan_xb',
    'xd_htz_qzxy', 'xd_luoshen_dinghunxianglu',
    'xd_jingwei_fan', 'xd_jingwei_zzql', 'xd_sly', 'xd_sj_tej',
    'xd_sj_by_builder', 'xd_sj_tlsq', 'xd_sj_xsydz',
    'xd_sudaji_mxrg', 'xd_wukong_jgb',
    'xd_yunxiao_fgfq', 'xd_yunxiao_fls', 'xd_yunxiao_fysz', 'xd_yunxiao_jjj',
}
local bosses = {
    bearger_fur=true, deerclops_eyeball=true, dragon_scales=true,
    malbatross_beak=true, minotaurhorn=true, shadowheart=true, shroom_skin=true,
}
local gems = {
    bluegem=true, greengem=true, orangegem=true, purplegem=true,
    redgem=true, yellowgem=true,
}
local calls = {}
local G = {
    AllRecipes={}, TECH={NONE={}}, STRINGS={NAMES={}, RECIPE_DESC={}},
    Ingredient=function(prefab, amount, atlas, _, image)
        -- DST resolves an explicit atlas immediately. Thần Khí loads after Nyx.
        assert(atlas ~= 'images/inventoryimages/ttk_huyen_tinh_thuong_pham.xml',
            'crystal atlas is unavailable while Nyx registers recipes')
        return {prefab=prefab, amount=amount, atlas=atlas, image=image}
    end,
}
local api = {
    GLOBAL=G,
    AddCharacterRecipe=function(name, ingredients, tech, config)
        assert(calls[name] == nil, 'duplicate recipe: '..name)
        calls[name] = {ingredients=ingredients, tech=tech, config=config}
        G.AllRecipes[name] = calls[name]
    end,
}
local register = require('nyx/rare_recipes').Register
assert(register(api) == 9)
local expected_names = {}
for _, product in ipairs(expected) do
    local name = 'nyx_' .. product
    expected_names[name] = true
    local recipe = assert(calls[name], 'missing recipe: '..name)
    assert(recipe.config.product == product)
    assert(recipe.config.builder_tag == 'nyx_crafter')
    assert(recipe.config.numtogive == 1)
    assert(recipe.tech == G.TECH.NONE)
    assert(#recipe.ingredients == 4, 'ingredient count: '..name)
    local boss, stone, crystal, gem = table.unpack(recipe.ingredients)
    assert(bosses[boss.prefab] and boss.amount == 1, 'boss item: '..name)
    assert(stone.prefab == 'xd_lingshi3' and stone.amount >= 2, 'spirit stone: '..name)
    assert(crystal.prefab == 'ttk_huyen_tinh_thuong_pham' and crystal.amount >= 1, 'mystic crystal: '..name)
    assert(gems[gem.prefab] and gem.amount >= 2, 'gem: '..name)
end
for name in pairs(calls) do assert(expected_names[name], 'unexpected recipe: '..name) end
for _, product in ipairs(excluded) do
    assert(calls['nyx_' .. product] == nil, 'excluded recipe: '..product)
end
assert(register(api) == 0, 'registration must not duplicate existing recipes')
print('rare recipes: 9 unique recipes; Thien Nghich Chau belongs to Cong Trinh')
