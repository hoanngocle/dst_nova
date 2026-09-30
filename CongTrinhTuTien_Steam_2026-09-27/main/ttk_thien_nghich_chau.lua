-- Tu Tien owns the prefab, interiors, teleportation and saved room positions.
-- Keep the old Nyx recipe ID and shared use tag for existing saves/mod versions.
local G = GLOBAL
local use_tag = 'nyx_use_xd_wangmazi'

for _, prefab in G.ipairs({'nyx', 'xd_wangmazi'}) do
    AddPrefabPostInit(prefab, function(inst)
        inst:AddTag(use_tag)
    end)
end

AddPrefabPostInit('xd_wmz_tnz', function(inst)
    -- This field is read by the original action picker on both client and server.
    if inst.xd_use_needtag == 'xd_wangmazi' then
        inst.xd_use_needtag = use_tag
    end
end)

local recipe = 'nyx_xd_wmz_tnz'
if G.AllRecipes[recipe] == nil then
    G.STRINGS.NAMES.NYX_XD_WMZ_TNZ = 'Thiên Nghịch Châu'
    G.STRINGS.RECIPE_DESC.NYX_XD_WMZ_TNZ = 'Không gian riêng để Nyx nghỉ ngơi và hồi phục.'
    AddCharacterRecipe(recipe, {
        G.Ingredient('xd_fs', 1),
        G.Ingredient('xd_lingshi3', 3),
        G.Ingredient('ttk_huyen_tinh_thuong_pham', 2),
        G.Ingredient('purplegem', 3),
    }, G.TECH.NONE, {
        product = 'xd_wmz_tnz',
        -- Tu Tien loads later; resolve its registered inventory atlas when shown.
        image = 'xd_wmz_tnz.tex',
        numtogive = 1,
        builder_tag = 'nyx_crafter',
    }, {})
end
