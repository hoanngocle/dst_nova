package.path='ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;'..package.path
local Defs=require('tbc_elixir/defs')
local Install=require('tbc_elixir/install')
local callbacks,recipes,atlases={},{},{}
local G={STRINGS={NAMES={},RECIPE_DESC={}},TECH={MAGIC_THREE={magic=3}},ACTIONS={},
    GetInventoryItemAtlas=function(image) return 'native/'..image..'.xml' end,
    Ingredient=function(id,count,atlas,_,image) return {id=id,count=count,atlas=atlas,image=image} end}
local env={AddComponentPostInit=function(name,fn) callbacks[name]=fn end,
    AddPlayerPostInit=function(fn) callbacks.player=fn end,
    RegisterInventoryItemAtlas=function(atlas,image) atlases[atlas]=image end,
    AddRecipe2=function(id,ingredients,tech,config,filters)
        assert(not recipes[id]); recipes[id]={ingredients=ingredients,tech=tech,config=config,filters=filters}
    end}
Install.Install(env,G)
local allowed={xd_qlr=true,xd_fs=true,dragon_scales=true,royal_jelly=true,
    deerclops_eyeball=true,bearger_fur=true,goose_feather=true}
local count=0
for _,key in ipairs(Defs.ORDER) do
    local row=Defs.BY_KEY[key]; local recipe=assert(recipes[row.prefab])
    assert(recipe.tech==G.TECH.MAGIC_THREE and recipe.config.numtogive==1)
    assert(atlases[row.atlas]==row.icon..'.tex' and recipe.config.image==row.icon..'.tex')
    assert(allowed[recipe.ingredients[1].id],'main ingredient is verified DST or Tu Tien boss loot')
    assert(G.STRINGS.NAMES[row.prefab:upper()]==row.name)
    assert(io.open('ThanKhiTuTien_Steam_2026-09-27/'..row.atlas,'rb'))
    assert(io.open('ThanKhiTuTien_Steam_2026-09-27/images/potions/'..row.icon..'.tex','rb'))
    count=count+1
end
for _,key in ipairs(Defs.ORDER) do
    local recipe=recipes[Defs.BY_KEY[key].prefab]
    for _,ingredient in ipairs(recipe.ingredients) do
        local id=ingredient.id
        if id:sub(1,3)=='xd_' then
            assert(ingredient.atlas=='images/inventoryimages/'..id..'.xml',
                key..': custom ingredient must use its inventory atlas: '..id)
            assert(ingredient.image==id..'.tex',key..': custom ingredient image mismatch: '..id)
        else
            assert(ingredient.atlas==nil and ingredient.image==nil,
                key..': native ingredient should use its game icon: '..id)
        end
    end
end
assert(count==6 and callbacks.eater and callbacks.playeractionpicker and callbacks.health and callbacks.xd_htz_lq)
assert(io.open('ThanKhiTuTien_Steam_2026-09-27/anim/hh_dungeon_potions.zip','rb'))
-- Execute the real prefab factory against a minimal engine surface.
local factories={}
function Asset(...) return {...} end
function Prefab(id,fn,assets) factories[id]=fn; return {id=id,assets=assets} end
TheWorld={ismastersim=true}; TUNING={STACK_SIZE_SMALLITEM=40}; FOODTYPE={GOODIES='goodies',MEAT='meat'}
unpack=unpack or table.unpack
function MakeInventoryPhysics() end
function MakeInventoryFloatable() end
function MakeHauntableLaunch() end
function CreateEntity()
    local e={components={},entity={},AnimState={},tags={}}
    for _,method in ipairs({'AddTransform','AddAnimState','AddNetwork','SetPristine'}) do e.entity[method]=function() end end
    for _,method in ipairs({'SetBank','SetBuild','PlayAnimation'}) do e.AnimState[method]=function(self,v) self[method..'_value']=v end end
    function e:AddTag(tag) self.tags[tag]=true end
    function e:AddComponent(name)
        self.components[name]={}
        if name=='edible' then self.components[name].SetOnEatenFn=function(self,fn) self.oneaten=fn end end
    end
    return e
end
assert(loadfile('ThanKhiTuTien_Steam_2026-09-27/scripts/prefabs/tbc_elixirs.lua'))()
local used={}
local viewer={components={tbc_elixir_progress={Consume=function(_,key) used[#used+1]=key end}},
    GetTbcElixirCount=function() return 7 end}
for _,key in ipairs(Defs.ORDER) do
    local row=Defs.BY_KEY[key]; local e=factories[row.prefab]()
    assert(e.AnimState.PlayAnimation_value==row.anim)
    assert(e.components.edible.healthvalue==0 and e.components.edible.sanityvalue==0 and e.components.edible.hungervalue==0)
    assert(e.components.inspectable.descriptionfn(e,viewer):find('7/10',1,true))
    e.components.edible.oneaten(e,viewer)
    assert(used[#used]==key,'each prefab absorbs its own key')
end
TheWorld.ismastersim=false
assert(next(factories.tbc_elixir_power().components)==nil,'clients do not own edible/server components')
print('elixir_registration_test: six recipes, assets, prefab factories and client boundary passed')
