"""Check unlimited revival and crafting with the real DST Hauntable component."""
from pathlib import Path
from zipfile import ZipFile
import sys
import re
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT.parent.parent/'dst_wiki/.superpowers/luoshen-runtime'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime(unpack_returned_tuples=True)
with ZipFile("C:/Program Files (x86)/Steam/steamapps/common/Don't Starve Together/data/databundles/scripts.zip") as z:
    lua.execute(z.read('scripts/class.lua').decode())
    lua.globals().Hauntable=lua.execute(z.read('scripts/components/hauntable.lua').decode())
    standard=z.read('scripts/standardcomponents.lua').decode()
    make_hauntable=re.search(r'^function MakeHauntable\(.*?(?=^function )',standard,re.M|re.S)
    assert make_hauntable is not None
lua.execute('''
function noop() end
function api() return setmetatable({}, {__index=function() return noop end}) end
package.preload.prefabutil=function() return {} end
function Asset(...) return {...} end
function Prefab(name,fn,assets) return {name=name,fn=fn,assets=assets} end
function MakePlacer(name,bank,build,anim) return {name=name,bank=bank,build=build,anim=anim} end
function MakeSnowCoveredPristine() end
function MakeSnowCovered() end
function MakeObstaclePhysics() end
TUNING={HAUNT_INSTANT_REZ=999,HAUNT_COOLDOWN_MEDIUM=1,HAUNT_COOLDOWN_SMALL=1}
TheWorld={ismastersim=true,events=0,PushEvent=function(self,name) assert(name=='ms_sendlightningstrike');self.events=self.events+1 end}
function CreateEntity()
 local e={entity=api(),AnimState=api(),MiniMapEntity=api(),components={},tags={}}
 function e:AddTag(t) self.tags[t]=true end
 function e:RemoveTag(t) self.tags[t]=nil end
 function e:AddOrRemoveTag(t,b) self.tags[t]=b end
 function e:HasTag(t) return self.tags[t] end
 function e:IsValid() return not self.removed end
 function e:GetPosition() return {} end
 function e:Remove() self.removed=true end
 function e:StartUpdatingComponent() end
 function e:PushEvent() end
 function e:AddComponent(n)
  self.components[n]=n=='hauntable' and Hauntable(self) or api()
 end
 return e
end
''')
lua.execute(make_hauntable.group(0))
assert (ROOT/'scripts/prefabs/ttk_fsct.lua').is_file(), 'Luân Hồi Đài prefab has not been transferred'
prefab,placer=lua.execute((ROOT/'scripts/prefabs/ttk_fsct.lua').read_text(encoding='utf-8'))
lua.globals().altar=prefab
lua.execute('''
local inst=altar.fn()
assert(inst.components.finiteuses==nil and inst.components.timer==nil)
assert(inst.components.hauntable.cooldown==0 and inst:HasTag('structure'))
local ghost=CreateEntity(); ghost:AddTag('playerghost'); ghost.revived=0
function ghost:PushEvent(name,data)
 assert(name=='respawnfromghost' and data.source==inst); self.revived=self.revived+1
end
for i=1,20 do inst.components.hauntable:DoHaunt(ghost) end
assert(ghost.revived==20 and TheWorld.events==20 and not inst.removed)
inst.components.hauntable:DoHaunt(CreateEntity())
inst.components.hauntable:DoHaunt(nil)
local removed=CreateEntity(); removed:AddTag('playerghost'); removed:Remove()
inst.components.hauntable:DoHaunt(removed)
assert(TheWorld.events==20)
local another=CreateEntity(); another:AddTag('playerghost'); another.revived=0
function another:PushEvent(name,data)
 assert(name=='respawnfromghost' and data.source==inst); self.revived=self.revived+1
end
inst.components.hauntable:DoHaunt(another)
assert(another.revived==1 and TheWorld.events==21)
TheWorld.ismastersim=false
local client=altar.fn(); assert(client.components.hauntable==nil)
GLOBAL=_G; PrefabFiles={}; Assets={}; STRINGS={NAMES={},RECIPE_DESC={},CHARACTERS={GENERIC={DESCRIBE={}}}}
TECH={SCIENCE_TWO=2}; Ingredient=function(n,c) return {n,c} end
RegisterInventoryItemAtlas=noop; AddMinimapAtlas=noop
AddRecipe2=function(name,ingredients,tech,config,filters)
 assert(name=='ttk_fsct' and tech==2 and config.builder_tag==nil)
 assert(config.placer=='ttk_fsct_placer' and #ingredients==4)
 assert(ingredients[1][1]=='cutstone' and ingredients[1][2]==10)
 assert(ingredients[2][1]=='goldnugget' and ingredients[2][2]==6)
 assert(ingredients[3][1]=='reviver' and ingredients[3][2]==2)
 assert(ingredients[4][1]=='xd_lingshi3' and ingredients[4][2]==2)
 assert(filters[1]=='STRUCTURES' and filters[2]=='MAGIC')
end
''')
lua.execute((ROOT/'main/ttk_fsct.lua').read_text(encoding='utf-8'))
assert placer.name=='ttk_fsct_placer'
assert 'main/ttk_fsct.lua' in (ROOT/'modmain.lua').read_text(encoding='utf-8')
for relative in ['main/ttk_fsct.lua', 'scripts/prefabs/ttk_fsct.lua',
                 'anim/ttk_fsct.zip', 'images/map_icons/ttk_fsct.xml',
                 'images/map_icons/ttk_fsct.tex']:
    assert (ROOT/relative).is_file(), relative
    assert '"'+relative+'"' in (ROOT/'modmain.lua').read_text(encoding='utf-8'), relative+' missing from manifest'
with ZipFile(ROOT/'anim/ttk_fsct.zip') as archive:
    assert archive.testzip() is None
    assert {'anim.bin','build.bin','atlas-0.tex'} <= set(archive.namelist())
for p in ROOT.rglob('*.lua'): lua.execute('assert(loadstring(...))',p.read_text(encoding='utf-8-sig'))
print('PASS: 20 consecutive haunts, ghost-only revival, no charges/timer, client boundary, craft recipe, placer, registration and Lua syntax')
