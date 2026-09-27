-- Copy selected Tu Tiên recipes after that mod registers them. Never replace a source recipe.
local M = {}
local SELECTED = {
    'xd_htz_tlz', 'xd_htz_sjcx', 'xd_htz_xyzzl',
    'turf_jingweitile', 'xd_jingwei_hat',
    'wall_luoshen_item', 'fence_luoshen_item', 'fence_gate_luoshen_item',
    'xd_luoshen_jihuaze',
    'xd_luoshen_huazhong', 'xd_luoshen_huaxia',
    'xd_qwsk', 'xd_sudaji_redlantern', 'xd_sudaji_ywfh',
    'xd_yunxiao_hyjditem', 'xd_yunxiao_hyjdyqd',
    'xd_yunxiao_portable_spicer', 'xd_yunxiao_ymsz',
}
local FEATHERS = {
    {'crow', 'feather_crow'},
    {'robin', 'feather_robin'},
    {'winter', 'feather_robin_winter'},
}
local CONFIG_FIELDS = {
    'nameoverride', 'description', 'layeredimagefn', 'imagefn', 'fxover',
    'placer', 'min_spacing', 'testfn', 'overridecandeployrecipeatpointfn',
    'canbuild', 'nounlock', 'numtogive', 'override_numtogive_fn',
    'forward_ingredients', 'sg_state', 'build_mode', 'build_distance',
    'no_deconstruction', 'decon_ignores_finiteuses', 'require_special_event',
    'always_allow_buffered_placer', 'dropitem', 'actionstr',
    'recipedisplaynamefn', 'hint_msg', 'force_hint', 'manufactured',
    'station_tag', 'limitedamount', 'getlimitedrecipecount',
}

local function CopyTable(original)
    local copy = {}
    for key, value in pairs(original or {}) do copy[key] = value end
    return copy
end

local function CopyIngredient(original)
    return setmetatable(CopyTable(original), getmetatable(original))
end

local function Ingredients(recipe)
    local result = {}
    for _, group in ipairs({recipe.ingredients, recipe.character_ingredients, recipe.tech_ingredients}) do
        for _, ingredient in ipairs(group or {}) do
            result[#result + 1] = CopyIngredient(ingredient)
        end
    end
    return result
end

local function SourceRecipe(all, product)
    if all[product] ~= nil then return all[product] end
    local match
    for name, recipe in pairs(all) do
        if name:sub(1, 4) ~= 'nyx_' and recipe.product == product then
            if match ~= nil then return nil end -- ambiguous; do not clone an arbitrary recipe
            match = recipe
        end
    end
    return match
end

local function Filters(all, source_name)
    local result = {}
    for key, filter in pairs(all or {}) do
        if key ~= 'CHARACTER' and type(filter) == 'table' and type(filter.recipes) == 'table' then
            for _, name in ipairs(filter.recipes) do
                if name == source_name then
                    result[#result + 1] = filter.name or key
                    break
                end
            end
        end
    end
    table.sort(result)
    return result
end
local function RegisterFromSource(api, G, product, source)
    local alias = 'nyx_' .. product
    local config = {}
    for _, field in ipairs(CONFIG_FIELDS) do config[field] = source[field] end
    config.product = source.product or product
    config.image = source.image
    config.atlas = source.atlas
    config.builder_tag = 'nyx_crafter'
    G.STRINGS.NAMES[string.upper(alias)] = G.STRINGS.NAMES[string.upper(product)] or product
    G.STRINGS.RECIPE_DESC[string.upper(alias)] = G.STRINGS.RECIPE_DESC[string.upper(product)] or ''
    api.AddCharacterRecipe(alias, Ingredients(source), CopyTable(source.level), config,
        Filters(G.CRAFTING_FILTERS, source.name or product))
end

function M.Register(api)
    local G = api.GLOBAL
    local registered, missing = 0, {}
    for _, product in ipairs(SELECTED) do
        local alias = 'nyx_' .. product
        local source = SourceRecipe(G.AllRecipes or {}, product)
        if source == nil or source.builder_skill ~= nil then
            missing[#missing + 1] = product
        elseif G.AllRecipes[alias] == nil then
            RegisterFromSource(api, G, product, source)
            registered = registered + 1
        end
    end
    local mume_product = 'xd_chenpingan_mumefruit'
    local mume_alias = 'nyx_' .. mume_product
    if G.AllRecipes[mume_alias] == nil then
        local source = SourceRecipe(G.AllRecipes or {}, mume_product)
        if source and source.builder_skill == nil then
            RegisterFromSource(api, G, mume_product, source)
        else
            G.STRINGS.NAMES[string.upper(mume_alias)] = G.STRINGS.NAMES.XD_CHENPINGAN_MUMEFRUIT or 'Thanh Mai'
            G.STRINGS.RECIPE_DESC[string.upper(mume_alias)] = 'Gieo Thanh Mai để cây non lớn thành cây trưởng thành.'
            api.AddCharacterRecipe(mume_alias, {
                G.Ingredient('pomegranate', 1),
                G.Ingredient('twigs', 4),
                G.Ingredient('xd_lingshi2', 1),
            }, CopyTable(G.TECH.NONE), {
                product = mume_product,
                image = 'xd_chenpingan_mumefruit.tex',
                atlas = 'images/inventoryimages/xd_chenpingan_mumefruit.xml',
                numtogive = 1,
                builder_tag = 'nyx_crafter',
            }, {})
        end
        registered = registered + 1
    end
    local xuanyu = SourceRecipe(G.AllRecipes or {}, 'xd_xuanyu')
    if xuanyu == nil or xuanyu.builder_skill ~= nil then
        missing[#missing + 1] = 'xd_xuanyu'
    else
        for _, feather in ipairs(FEATHERS) do
            local alias = 'nyx_xuanyu_' .. feather[1]
            if G.AllRecipes[alias] == nil then
                G.STRINGS.NAMES[string.upper(alias)] = G.STRINGS.NAMES.XD_XUANYU or 'Huyền Vũ'
                G.STRINGS.RECIPE_DESC[string.upper(alias)] = 'Đổi 2 lông chim cùng loại lấy 1 Huyền Vũ.'
                api.AddCharacterRecipe(alias, {G.Ingredient(feather[2], 2)}, CopyTable(G.TECH.NONE), {
                    product = 'xd_xuanyu',
                    image = xuanyu.image,
                    imagefn = xuanyu.imagefn,
                    atlas = xuanyu.atlas,
                    numtogive = 1,
                    builder_tag = 'nyx_crafter',
                }, {})
                registered = registered + 1
            end
        end
    end
    return registered, missing
end

return M
