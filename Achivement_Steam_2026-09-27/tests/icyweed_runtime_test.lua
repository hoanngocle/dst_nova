package.path = 'Achivement_Steam_2026-09-27/scripts/?.lua;' .. package.path
local Data = require('constants/icyweedloot')
local registry, spawned, failed, nonstack, maximum = {}, {}, {}, {}, {}
Prefabs = registry
for _, row in ipairs(Data.rows) do registry[row.prefab] = {} end
local clients, rngcalls = false, 0
local printed, original_print = {}, print
print=function(...)
    local values={...};printed[#printed+1]=table.concat(values,' ');original_print(...)
end
TheWorld = {ismastersim=true, components={}}
FRAMES, TUNING = 1/30, {HAUNT_CHANCE_OCCASIONAL=1}
Asset = function() end
Prefab = function(name, fn) return {name=name,fn=fn} end
MakeCharacterPhysics = function() end
MakeSmallPropagator = function(inst) inst.components.propagator = {} end
GetRandomWithVariance = function(value) return value end
math.clamp = function(v,lo,hi) return math.max(lo,math.min(v,hi)) end
local stub = setmetatable({}, {__index=function() return function() end end})
function CreateEntity()
    local inst = {components={}, tasks={}, events={}, valid=true, entity=setmetatable({IsAwake=function() return true end},{__index=stub})}
    inst.Transform = setmetatable({GetWorldPosition=function() return 12,0,15 end,
        SetPosition=function(_,x,y,z) inst.position={x,y,z} end}, {__index=stub})
    inst.AnimState, inst.SoundEmitter, inst.DynamicShadow = stub,stub,stub
    function inst:AddComponent(name)
        self.components[name] = setmetatable({}, {__index=stub})
        if name == 'hauntable' then self.components[name].SetOnHauntFn=function(c,fn) c.onhaunt=fn end end
    end
    function inst:AddTag() end
    function inst:PushEvent(name) self.events[name] = (self.events[name] or 0)+1 end
    function inst:ListenForEvent() end
    function inst:RemoveEventCallback() end
    function inst:Remove() self.valid=false end
    function inst:IsValid() return self.valid end
    function inst:DoTaskInTime(_,fn) self.tasks[#self.tasks+1]=fn; return {Cancel=function() end} end
    return inst
end
local function Item(id)
    local inst=CreateEntity(); inst.prefab=id
    if id ~= 'chasni_icyweedbreakfx' and not nonstack[id] then
        local stack={inst=inst,size=1,maxsize=maximum[id] or 40}
        function stack:GetMaxSize() return self.maxsize end
        function stack:StackSize() return self.size end
        function stack:SetStackSize(n) assert(n<=self.maxsize);self.size=n end
        function stack:CanStackWith(other) return other.prefab==id and other.components.stackable ~= nil end
        function stack:Put(other)
            local sum=self.size+other.components.stackable.size
            self.size=math.min(sum,self.maxsize)
            if sum<=self.maxsize then other:Remove();return nil end
            other.components.stackable.size=sum-self.maxsize;return other
        end
        inst.components.stackable=stack
        inst.components.inventoryitem={ondropfn=function(item) item.dropped=(item.dropped or 0)+1 end}
    end
    spawned[#spawned+1]=inst
    return inst
end
SpawnPrefab=function(id)
    if failed[id] then return nil end
    if not registry[id] and id~='chasni_icyweedbreakfx' then return nil end
    return Item(id)
end
local original_random=math.random
math.random=function(lo,hi)
    rngcalls=rngcalls+1
    if lo then return lo end
    return .25
end
local function Factory()
    local prefab=dofile('Achivement_Steam_2026-09-27/scripts/prefabs/icyweed.lua')
    assert(prefab.name=='chasni_icyweed')
    return prefab.fn
end
local factory=Factory()
local function New(rewards)
    local inst=factory()
    assert(type(inst.OnSave)=='function', 'icyweed loot must persist across restart')
    if rewards then inst:OnLoad({icyweed_loot={version=1,rewards=rewards}}) end
    return inst
end
local function Rewards(id,amount)
    return {{prefab=id,amount=amount},{prefab=id,amount=amount},{prefab=id,amount=amount}}
end
local function Drops()
    local items, count={},0
    for _, item in ipairs(spawned) do
        if item.valid and item.dropped then
            items[#items+1]=item
            count=count+item.components.stackable:StackSize()
            assert(item.dropped==1 and item.position[1]==12 and item.position[3]==15)
        end
    end
    return items,count
end
local saved_rewards={{prefab='xd_lingshi1',amount=4},{prefab='xd_lingshi1',amount=8},{prefab='xd_lingshi1',amount=8}}
local inst=New(saved_rewards)
local before=rngcalls
for _,task in ipairs(inst.tasks) do task(inst) end
local data={};inst:OnSave(data)
assert(rngcalls==before, 'load must not reroll saved rewards')
assert(data.icyweed_loot.rewards[3].amount==8)
local reloaded=New(data.icyweed_loot.rewards)
spawned={}
reloaded.components.pickable.onpickedfn(reloaded,nil)
local items,count=Drops();assert(#items==1 and count==20, 'merge three rewards into one compatible stack')
local number=#spawned
reloaded.components.pickable.onpickedfn(reloaded,{})
reloaded.components.hauntable.onhaunt(reloaded,nil)
assert(#spawned==number, 'pick/haunt cannot grant twice')
maximum.xd_lingshi1=5
factory=Factory(); inst=New(saved_rewards);spawned={}
inst.components.pickable.onpickedfn(inst,nil)
items,count=Drops();assert(#items==4 and count==20, 'split by live stack cap without losing units')
maximum.xd_lingshi1=nil
-- Removed or nonstack prefab is replaced on redemption, with no extra RNG.
for _, kind in ipairs({'missing','nonstack','spawnfailed'}) do
    factory=Factory();inst=New(Rewards('hh_essence',2));spawned={}
    if kind=='missing' then registry.hh_essence=nil end
    if kind=='nonstack' then nonstack.hh_essence=true end
    if kind=='spawnfailed' then failed.hh_essence=true end
    before=rngcalls
    inst.components.pickable.onpickedfn(inst,nil)
    items,count=Drops();assert(#items==1 and count==6 and items[1].prefab=='xd_lingshi1',kind..' fallback')
    assert(rngcalls==before, 'redemption fallback is deterministic')
    registry.hh_essence={};nonstack.hh_essence=nil;failed.hh_essence=nil
end
-- Definition changes invalidate support cache without restarting the mod.
factory=Factory();inst=New(Rewards('hh_essence',2));inst.components.pickable.onpickedfn(inst,nil)
registry.hh_essence={};nonstack.hh_essence=true
inst=New(Rewards('hh_essence',2));spawned={};inst.components.pickable.onpickedfn(inst,nil)
items,count=Drops();assert(count==6 and items[1].prefab=='xd_lingshi1')
nonstack.hh_essence=nil;registry.hh_essence={}
-- Final fallback is bounded even when every spawn fails.
registry.xd_lingshi1=nil
factory=Factory();inst=New(Rewards('xd_lingshi1',4));spawned={};inst.components.pickable.onpickedfn(inst,nil)
items,count=Drops();assert(count==6 and items[1].prefab=='goldnugget')
local warning_count=0
for _, message in ipairs(printed) do
    if message:find('xd_lingshi1 unavailable',1,true) then warning_count=warning_count+1 end
end
assert(warning_count==1,'missing required Tu Tien currency must warn once')
failed.goldnugget=true
inst=New(Rewards('xd_lingshi1',4));spawned={};inst.components.pickable.onpickedfn(inst,nil)
assert(#spawned<=1,'all-failed fallback must terminate')
failed.goldnugget=nil;registry.xd_lingshi1={}
-- Legacy world has no loot data: rolls once, retains it on repeated save.
factory=Factory();inst=New();inst:OnLoad({});local legacy={};inst:OnSave(legacy)
before=rngcalls;local again={};inst:OnSave(again)
assert(rngcalls==before and #again.icyweed_loot.rewards==3)
local spent=New();spent:OnLoad({icyweed_claimed=true,icyweed_loot=legacy.icyweed_loot})
spawned={};spent.components.pickable.onpickedfn(spent,nil);assert(#spawned==0)
-- Client construction must not probe, roll or install reward callbacks.
TheWorld.ismastersim=false;spawned={};before=rngcalls
local client=factory();assert(#spawned==0 and rngcalls==before and client.OnSave==nil)
math.random=original_random
print=original_print
print('PASS icyweed runtime: actual prefab, merge/split, fallback, save/load, idempotency, haunt and client')
