package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path

local progression = require('nyx/progression')

local milestones = {
    {9, 6, 20},
    {10, 6, 20},
    {19, 6, 20},
    {20, 6.5, 30},
    {30, 7, 40},
    {40, 7.5, 50},
    {49, 7.5, 50},
    {50, 8.5, 60},
    {60, 9, 70},
    {69, 9, 70},
    {70, 10, 80},
    {80, 10.5, 90},
    {90, 11, 100},
    {99, 11, 100},
    {100, 12, nil},
    {110, 12, nil},
}

for _, case in ipairs(milestones) do
    local level, radius, next_level = case[1], case[2], case[3]
    assert(progression.Radius(level) == radius,
        ('level %d radius: expected %s, got %s'):format(level, radius, progression.Radius(level)))
    assert(progression.NextRadiusLevel(level) == next_level,
        ('level %d next increase: expected %s, got %s'):format(
            level, tostring(next_level), tostring(progression.NextRadiusLevel(level))))
end

assert(progression.GatherTier(10) == 1, 'level 10 is gather tier 1')
assert(progression.GatherTier(19) == 1, 'tier advances only every ten levels')
assert(progression.GatherTier(50) == 5, 'level 50 is gather tier 5')
assert(progression.GatherTier(100) == 10, 'level 100 is gather tier 10')

print('gather radius: all level milestones verified')

local defs=require('nyx/skilldefs')
local costs={{10,20},{19,20},{20,18},{29,18},{30,16},{40,14},
    {50,12},{60,10},{70,8},{79,8},{80,6},{90,6},{99,6},{100,6},{110,6}}
for _,case in ipairs(costs) do
    assert(progression.GatherCost(case[1])==case[2], 'gather cost at level '..case[1])
    assert(progression.SkillCost(defs.Get('purple_gather'),case[1])==case[2])
end
assert(progression.SkillCost(defs.Get('triflame_fan'),100)==20,'combat cost stops at half')
local reductions={
    {'absolute_domain',1,30},{'absolute_domain',10,20},{'absolute_domain',20,15},
    {'triflame_fan',9,40},{'triflame_fan',10,30},{'triflame_fan',20,20},
    {'yellow_river',100,20},{'eternal_night',10,40},{'eternal_night',20,30},
    {'eternal_night',30,25},{'spirit_sword',10,70},{'spirit_sword',20,60},
    {'spirit_sword',30,50},{'spirit_sword',40,40},{'spirit_sword',100,40},
    {'bean_soldiers',100,0},{'purple_eye',100,0},{'moon_wings',100,0},
}
for _,case in ipairs(reductions) do
    assert(progression.SkillCost(defs.Get(case[1]),case[2])==case[3],case[1]..' cost at '..case[2])
end
assert(progression.ReducedCost(10,1)==10 and progression.ReducedCost(10,10)==5)
local Casting=require('nyx/casting')
for _,case in ipairs(costs) do
    local level,mana,spent,refund,fail=case[1],case[2],nil,nil,false
    local port={clock=function() return 0 end,
        read=function() return {ready=true,level=level,current=mana,realm_rank=0} end,
        alive=function() return true end,valid=function() return true end,
        spend=function(n) spent=n; mana=mana-n; return true end,
        refund=function(n) refund=n;mana=mana+n end,
        prepare=function()
            if fail then level=100 end
            return {Start=function() return not fail end,Cancel=function() end}
        end}
    local controller=Casting.New(port)
    assert(controller:Request('purple_gather',{x=0,z=0},1),'cast with exact reduced cost')
    assert(spent==case[2] and mana==0)
    mana,spent=case[2]-1,nil
    assert(not Casting.New(port):Request('purple_gather',{x=0,z=0},1),'reject insufficient mana')
    assert(spent==nil,'no spend before mana validation')
    mana,fail=case[2],true
    assert(not Casting.New(port):Request('purple_gather',{x=0,z=0},1),'failed effect is refunded')
    assert(refund==case[2] and mana==case[2],'refund exactly charged cost despite level change')
end
print('gather cost: milestones, exact/insufficient mana and refunds verified (mock)')

-- Exercise the real delayed blink component with mocked engine surfaces.
local Common=require('util/nyx_blink_common')
Class=function(ctor)
    local class={};class.__index=class
    return setmetatable(class,{__call=function(_,inst)
        local self=setmetatable({},class);ctor(self,inst);return self
    end})
end
GetTime=function() return 0 end
TheWorld={ismastersim=true}
local activate,continue,validate,find=Common.CanActivate,Common.CanContinueCast,Common.ValidateDestination,Common.FindTargetsAlongPath
Common.CanActivate=function() return true end
Common.CanContinueCast=function() return true end
Common.ValidateDestination=function() return true end
Common.FindTargetsAlongPath=function() return {} end
local Blink=require('components/nyx_blink')
local function makeBlink(level,mana,teleportError)
    local resource={current=mana,DoDelta=function(self,n) self.current=self.current+n end}
    local inst={components={levelsystem={level=level},xd_htz_lq=resource},
        Transform={GetWorldPosition=function() return 0,0,0 end},
        Physics={Teleport=function() if teleportError then error('mock teleport failure') end end},
        ListenForEvent=function() end,AddTag=function() end,RemoveTag=function() end,
        DoTaskInTime=function() return {Cancel=function() end} end}
    local blink=Blink(inst)
    blink._SpawnLightningFx=function() end;blink._DamagePath=function() end
    return blink,inst,resource
end
math.atan2=math.atan2 or math.atan
RADIANS=180/math.pi
for _,case in ipairs({{1,10},{9,10},{10,5},{20,5},{100,5}}) do
    local blink,inst,mana=makeBlink(case[1],case[2])
    assert(blink:CastAt(2,3),'blink exact reduced mana at '..case[1])
    inst.components.levelsystem.level=100
    blink:_ResolveCast(2,3)
    assert(mana.current==0,'blink spends the validated cost despite level change')
    assert(blink.cast_cost==nil and not blink.active,'blink clears charged cost after finish')
    local failed,_,remaining=makeBlink(case[1],case[2],true)
    assert(failed:CastAt(2,3));failed:_ResolveCast(2,3)
    assert(remaining.current==case[2],'failed teleport refunds exact reduced cost')
    local insufficient=makeBlink(case[1],case[2]-1)
    assert(not insufficient:CastAt(2,3),'blink rejects insufficient reduced mana')
end
Common.CanActivate,Common.CanContinueCast,Common.ValidateDestination,Common.FindTargetsAlongPath=activate,continue,validate,find
print('blink cost: reduced mana, delayed level change and exact refunds verified (mock)')
