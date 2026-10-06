package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path
local containers = {params={}, MAXITEMSLOTS=12}
package.preload.containers=function() return containers end
function Vector3(x,y,z) return {x=x,y=y,z=z} end
TheWorld={ismastersim=true}
TheNet={IsDedicated=function() return false end}
local now=1
function GetTime() return now end
local prefab_hook, rpc, ui_hook
package.preload['widgets/hh_ui/hh_equip_ui']=function() return {} end
local api={
    AddPrefabPostInit=function(name,fn) assert(name=='nyx'); prefab_hook=fn end,
    AddModRPCHandler=function(namespace,name,fn)
        if name=='CLOSE_GEM_STORAGE' then return end
        assert(namespace=='NYX' and name=='GEM_STORAGE'); rpc=fn
    end,
    AddComponentPostInit=function(name,fn) assert(name=='inventory' and type(fn)=='function') end,
    AddClassPostConstruct=function(path,fn)
        if path=='screens/playerhud' then return end
        require(path) -- Match Klei: optional third-party widgets are required immediately.
        assert(path=='widgets/hh_ui/hh_equip_ui'); ui_hook=fn
    end,
}
require('nyx/gem_storage').Install(api)
assert(containers.MAXITEMSLOTS==36)
assert(containers.params.nyx_gem_storage.widget.animbank=='xd_ui_6x6',
    'must reuse Da Bao Cac UI')
local added
prefab_hook({AddComponent=function(_,name) added=name end})
assert(added=='nyx_gem_storage')
added=nil; TheWorld.ismastersim=false
prefab_hook({AddComponent=function(_,name) added=name end})
assert(added==nil,'storage component is server-only')
TheWorld.ismastersim=true
local toggles=0
local player={prefab='nyx',components={nyx_gem_storage={Toggle=function() toggles=toggles+1 end}}}
rpc(player); rpc(player)
assert(toggles==1,'throttle repeated RPCs')
now=2; rpc(player)
assert(toggles==2)
rpc(nil); rpc({prefab='wilson',components=player.components})
assert(toggles==2,'other characters cannot trigger storage')
local killed=0
local function button() return {Kill=function() killed=killed+1 end} end
local panel={hh_put_in=button(),hh_disassembly_btn=button(),other=button()}
ui_hook({owner={prefab='wilson'},hh_main=panel})
assert(killed==0,'do not alter other character UI')
ui_hook({owner=player,hh_main=panel})
assert(killed==2 and panel.hh_put_in==nil and panel.hh_disassembly_btn==nil)
assert(panel.other~=nil,'only remove requested two buttons')
package.loaded['widgets/hh_ui/hh_equip_ui']=nil
package.preload['widgets/hh_ui/hh_equip_ui']=nil
local installed,err=pcall(require('nyx/gem_storage').Install,api)
assert(installed,'Nyx must load without Solo Leveling: '..tostring(err))

function Asset(kind,path) return {kind,path} end
function Prefab(name,fn) return {name=name,fn=fn} end
local removed=0
function CreateEntity()
    local inst={entity={},components={},replica={container={WidgetSetup=function(_,name)
        assert(name=='nyx_gem_storage') end}}}
    function inst.entity:AddTransform() end
    function inst.entity:AddNetwork() end
    function inst.entity:SetPristine() end
    function inst:AddTag() end
    function inst:AddComponent(name)
        assert(name=='container')
        self.components.container={slots={},
            WidgetSetup=function(_,id) assert(id=='nyx_gem_storage') end,
            Open=function(self,doer) self.opener=doer end,
            Close=function(self) self.opener=nil end,
        }
    end
    return inst
end
local prefab=dofile('Nyx_Steam_2026-09-27/scripts/prefabs/nyx_gem_storage.lua')
local box=prefab.fn()
local owner={HasTag=function() return false end}
box.nyx_owner=owner
box.components.container:Open({HasTag=function() return false end})
assert(box.components.container.opener==nil,'another player cannot open private storage')
box.components.container:Open(owner)
assert(box.components.container.opener==owner)
box.components.container.slots[1]={Remove=function() removed=removed+1 end}
box.components.container.slots[36]={Remove=function() removed=removed+1 end}
box:OnRemoveEntity()
assert(removed==2 and box.components.container.opener==nil)
TheWorld.ismastersim=false
local client=prefab.fn()
assert(client.components.container==nil and client.OnEntityReplicated~=nil)
client:OnEntityReplicated()
print('gem_storage_integration_test: ok')
