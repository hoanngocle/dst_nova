-- Run from the repository root with Lua 5.4+.
local module_path = 'CongTrinhTuTien_Steam_2026-09-27/main/ttk_thien_nghich_chau.lua'
local function Install(existing)
    local hooks, recipes = {}, {}
    local G = {
        ipairs=ipairs,
        AllRecipes=existing or {}, TECH={NONE={}},
        STRINGS={NAMES={}, RECIPE_DESC={}},
        Ingredient=function(name, amount, atlas)
            assert(atlas == nil, 'source atlases may not be registered yet')
            return {name=name, amount=amount}
        end,
    }
    local env = {
        GLOBAL=G,
        AddPrefabPostInit=function(name, fn) hooks[name]=fn end,
        AddCharacterRecipe=function(name, ingredients, tech, config)
            assert(config.atlas == nil, 'recipe atlas must resolve after lower-priority Tu Tien loads')
            assert(G.AllRecipes[name] == nil, 'duplicate recipe')
            recipes[name]={ingredients=ingredients, tech=tech, config=config}
            G.AllRecipes[name]=recipes[name]
        end,
    }
    local file = io.open(module_path, 'r')
    assert(file, 'Cong Trinh must own the Thien Nghich Chau integration')
    file:close()
    assert(loadfile(module_path, 't', env))()
    return hooks, recipes, G
end

local hooks, recipes, G = Install()
local recipe = assert(recipes.nyx_xd_wmz_tnz, 'preserve the existing recipe ID')
assert(recipe.config.product == 'xd_wmz_tnz', 'spawn the original prefab')
assert(recipe.config.builder_tag == 'nyx_crafter', 'Nyx-only crafting')
assert(recipe.config.numtogive == 1 and recipe.tech == G.TECH.NONE)
local expected = {{'xd_fs',1},{'xd_lingshi3',3},{'ttk_huyen_tinh_thuong_pham',2},{'purplegem',3}}
for i, entry in ipairs(expected) do
    assert(recipe.ingredients[i].name == entry[1] and recipe.ingredients[i].amount == entry[2],
        'use Phoenix Marrow and preserve the remaining ingredient cost')
end
assert(#recipe.ingredients == #expected)

local function Player(prefab)
    local inst = {prefab=prefab, tags={}}
    function inst:AddTag(tag) self.tags[tag]=true end
    function inst:HasTag(tag) return self.tags[tag] == true end
    if hooks[prefab] then hooks[prefab](inst) end
    return inst
end
-- Hooks must work with client replicas too: no components or TheWorld required.
local nyx, wangmazi, wilson = Player('nyx'), Player('xd_wangmazi'), Player('wilson')
local original_onuse = function() end
local original_save = function() end
local item = {
    xd_use_needtag='xd_wangmazi',
    components={xd_use_inventory={onusefn=original_onuse}}, OnSave=original_save,
}
hooks.xd_wmz_tnz(item)
assert(nyx:HasTag(item.xd_use_needtag) and wangmazi:HasTag(item.xd_use_needtag))
assert(not wilson:HasTag(item.xd_use_needtag), 'do not unlock unrelated characters')
assert(not nyx:HasTag('xd_wangmazi'), 'do not enable unrelated Wang Mazi skills')
assert(item.components.xd_use_inventory.onusefn == original_onuse and item.OnSave == original_save,
    'room entry and save behavior remain owned by Tu Tien')
local client_item={xd_use_needtag='xd_wangmazi'}
hooks.xd_wmz_tnz(client_item)
assert(nyx:HasTag(client_item.xd_use_needtag), 'client action picker must accept Nyx')
local custom_item={xd_use_needtag='another_mod_gate'}
hooks.xd_wmz_tnz(custom_item)
assert(custom_item.xd_use_needtag == 'another_mod_gate')
hooks.xd_wmz_tnz(item)
assert(nyx:HasTag(item.xd_use_needtag), 'repeated hook must remain usable')
local _, duplicate = Install({nyx_xd_wmz_tnz=recipe})
assert(next(duplicate) == nil, 'compatible with an older Nyx recipe registration')
print('Thien Nghich Chau: source prefab, recipe cost, client/server gates and old recipe compatibility passed')
