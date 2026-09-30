test('registered RPC validates live gate and server state before transition',function()
 local a=require('support/dst_mock').Install();GLOBAL=_G;modname='HamNgucTuTien';ThePlayer=nil
 local rpc;ACTIONS={};Action=function(t)return t end;ActionHandler=function()return {} end
 AddAction=function(v) ACTIONS[v.id]=v end;AddPlayerPostInit=function()end
 AddComponentAction=function()end;AddStategraphActionHandler=function()end
 AddModRPCHandler=function(_,_,fn)rpc=fn end
 dofile('HamNgucTuTien/main/hn_actions.lua')
 local gate=a.entity('hn_dungeon_gate');local p=a.player();local moves=0
 p.sg={HasStateTag=function()return false end,GoToState=function()moves=moves+1 end}
 a.world.components.hn_dungeon_manager={IsActiveGate=function(_,g)return g==gate end,CanEnter=function()return true end}
 rpc(p,gate);assert(moves==1)
 rpc(p,a.entity('hn_dungeon_gate'));assert(moves==1)
 p.x=7;rpc(p,gate);assert(moves==1)
 p.x=0;a.world.components.hn_dungeon_manager.CanEnter=function()return false end;rpc(p,gate);assert(moves==1)
end)
