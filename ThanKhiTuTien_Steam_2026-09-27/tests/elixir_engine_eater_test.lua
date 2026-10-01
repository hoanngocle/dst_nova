-- Real DST Eater implementation, with fixture food/entity surfaces.
package.path='ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;'..package.path
dofile(assert(os.getenv('DST_TEST_SCRIPTS'))..'/class.lua')
local source=assert(os.getenv('DST_EATER_SOURCE'),'set DST_EATER_SOURCE to DST components/eater.lua')
FOODGROUP={OMNI={name='OMNI',types={'goodies'}}}
GetTime=function() return 10 end
local Eater=assert(loadfile(source))()
local Install=require('tbc_elixir/install')
local key,count,healed='power',9,0
local p={components={},HasTag=function() return false end,AddTag=function() end,RemoveTag=function() end,PushEvent=function() end}
p.components.tbc_elixir_progress={CanConsume=function() return key=='health' or count<10 end,
    Consume=function() if count<10 then count=count+1 else healed=healed+100 end end}
local eater=Eater(p); eater.eatwholestack=true
Install.WrapEater(eater)
local function food(prefab)
    local f={prefab=prefab,components={},stack=5,HasTag=function() return true end}
    f.components.edible={healthvalue=0,sanityvalue=0,
        OnEaten=function() p.components.tbc_elixir_progress:Consume(key) end,
        HandleEatRemove=function(_,whole) assert(not whole); f.stack=f.stack-1 end}
    return f
end
local f=food('tbc_elixir_power')
assert(eater:Eat(f) and count==10 and f.stack==4)
assert(not eater:Eat(f) and count==10 and f.stack==4,'real Eater blocks use11 before consuming')
assert(eater.eatwholestack==true,'restore whole-stack setting')
key='health'; f=food('tbc_elixir_health')
assert(eater:Eat(f) and count==10 and f.stack==4 and healed==100,'recovery with real Eater')
print('elixir_engine_eater_test: real DST eating and item-removal path passed')
