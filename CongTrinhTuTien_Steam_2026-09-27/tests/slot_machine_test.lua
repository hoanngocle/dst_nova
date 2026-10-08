package.path = 'CongTrinhTuTien_Steam_2026-09-27/scripts/?.lua;' .. package.path
local file = io.open('CongTrinhTuTien_Steam_2026-09-27/scripts/components/nova_slotmachine.lua','r')
assert(file, 'machine must persist a payment receipt before playing the spin animation')
file:close()
function Class(fn)
    local c={};c.__index=c
    return setmetatable(c,{__call=function(_,...) local x=setmetatable({},c);fn(x,...);return x end})
end
local spawned, tasks = {}, {}
TheWorld={ismastersim=true,Map={IsPassableAtPoint=function()return true end,
    IsOceanAtPoint=function()return false end,IsPointNearHole=function()return false end,
    IsGroundTargetBlocked=function()return false end}}
TheSim={FindEntities=function()return {} end}
TUNING={HH_TREASURE_BOSS_EXP={}}
Prefabs=setmetatable({},{__index=function()return true end})
AllPlayers={}
function Vector3(x,y,z)return {x=x,y=y,z=z,Get=function()return x,y,z end} end
function SpawnPrefab(id)
    if id=='BROKEN' then return nil end
    local e={prefab=id,components={},Transform={SetPosition=function()end},valid=true}
    function e:IsValid()return self.valid end
    function e:Remove()self.valid=false end
    function e:HasTag()return false end
    function e:DoTaskInTime(_,fn)tasks[#tasks+1]=function()fn(self)end end
    spawned[#spawned+1]=e;return e
end
local function machine()
    return {components={},Transform={GetWorldPosition=function()return 0,0,0 end},
        GetPosition=function()return Vector3(0,0,0)end,
        IsValid=function()return true end,DoTaskInTime=function(_,_,fn)tasks[#tasks+1]=fn;return{Cancel=function()end}end,
        sg={GoToState=function()end},PushEvent=function()end}
end
local C=require('components/nova_slotmachine')
local m=machine();local c=C(m)
local giver={userid='test',IsValid=function()return true end,HasTag=function()return false end}
local payment={prefab='xd_lingshi1',components={stackable={stacksize=60}}}
assert(c:CanAccept(payment,giver))
assert(not c:CanAccept({prefab='xd_lingshi1',components={stackable={stacksize=59}}},giver))
c:Begin(giver,payment,60)
assert(c.pending and m.busy)
assert(not c:CanAccept(payment,giver),'busy machine must reject a second payment')
local save=c:OnSave();assert(save.pending.cost==60)
local c2=C(machine());c2:OnLoad(save)
assert(c2.pending,'load must retain the receipt until refund succeeds')
c2:Refund()
local count=#spawned
c2:Refund();assert(#spawned==count,'refund exactly once')
c.pending.bundle={id='bad_test',items={{prefab='BROKEN',count=1}}}
c:Complete()
assert(not c.pending and not m.busy,'failed payout refunds and unlocks')
local after=#spawned;c:Complete();assert(#spawned==after,'duplicate animation callback pays nothing')
for _,throws in ipairs({false,true}) do
    c.pending={key='good',bundle={id='callback',name='callback',items={{prefab='reward',count=1}}},points={Vector3(0,0,0)}}
    m.PushEvent=function()c:Complete();if throws then error('external listener failed') end end
    local before=#spawned
    pcall(c.Complete,c)
    assert(#spawned==before+1 and not c.pending,'commit before reentrant or failing external callbacks')
end
local core=require('nova_slot_core')
local adapter=require('nova_slot_spawn')
local deer
local ok=core.SpawnBundle({items={{prefab='klaus',count=1}}},function(id)
    local e=SpawnPrefab(id)
    e.components.commander={AddSoldier=function()end}
    e.SpawnDeer=function()
        deer=SpawnPrefab('deer_red');e.components.commander:AddSoldier(deer)
        error('second deer failed')
    end
    return e
end,function(e,item,index,track)adapter.Configure(e,item,Vector3(0,0,0),giver,track)end)
assert(not ok and deer and not deer:IsValid(),'rollback must remove Klaus children created before failure')
print('slot machine: payment gates, interrupted spin refund, payout failure, duplicate callbacks passed')
