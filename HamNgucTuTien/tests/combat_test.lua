test('boss targeting works without Solo player component and excludes outsiders',function()
    local a=require('support/dst_mock').Install();local p=a.player();p:AddTag('in_hn_dungeon')
    local boss=a.entity('hn_igris');local combat=require('hn_dungeon/combat')
    assert(combat.IsValidPlayerTarget(boss,p))
    p:RemoveTag('in_hn_dungeon');assert(not combat.IsValidPlayerTarget(boss,p))
    p:AddTag('in_hn_dungeon');p:AddTag('playerghost');assert(not combat.IsValidPlayerTarget(boss,p))
end)
test('combat scaling is applied once without replacing other modifiers',function()
    local a=require('support/dst_mock').Install();local mob=a.entity('spider')
    mob.components.health={maxhealth=100,SetMaxHealth=function(self,h) self.maxhealth=h end}
    mob.components.combat={damagemultiplier=2,SetKeepTargetFunction=function() end,SetRetargetFunction=function() end}
    local combat=require('hn_dungeon/combat');combat.ApplyStats(mob,3,false);combat.ApplyStats(mob,3,false)
    assert(mob.components.health.maxhealth==300 and mob.components.combat.damagemultiplier==6)
end)
test('Beru speed buff refreshes and removes only its source modifier',function()
    local a=require('support/dst_mock').Install();local boss=a.entity('hn_beru');local values={other=1.3}
    boss.components.locomotor={SetExternalSpeedMultiplier=function(_,src,key,v) values[key]=v end,
        RemoveExternalSpeedMultiplier=function(_,src,key) values[key]=nil end}
    boss:AddComponent('hn_combat_effects');local effects=boss.components.hn_combat_effects
    effects:Apply('speed',boss,5,{multiplier=2});assert(values.hn_speed==2)
    a.advance(4);effects:Apply('speed',boss,5,{multiplier=2});a.advance(2);assert(values.hn_speed==2)
    a.advance(3);assert(values.hn_speed==nil and values.other==1.3)
end)
test('vanilla dungeon boss hooks avoid a second chest and track summons',function()
    local a=require('support/dst_mock').Install();local vanilla=require('hn_dungeon/vanilla')
    local calls=0;local state={onenter=function() calls=calls+1 end};vanilla.PatchMinotaurDeath(state)
    local wild=a.entity('minotaur');state.onenter(wild);assert(calls==1)
    local boss=a.entity('minotaur');boss.hn_is_dungeon_boss=true
    boss.components.locomotor={StopMoving=function() end};boss.AnimState={PlayAnimation=function() end};boss.DropDeathLoot=function() end
    state.onenter(boss);assert(calls==1 and boss:HasTag('NOCLICK'))
    local tracked={};local m={run_epoch=3,Track=function(_,e) tracked[e]=true end}
    boss.components.leader={AddFollower=function() end};vanilla.TrackSummons(boss,m,3)
    local child=a.entity('hound');child.components.lootdropper={DropLoot=function() error('unowned summon loot') end}
    boss.components.leader:AddFollower(child)
    assert(tracked[child] and child.hn_summon and child:HasTag('hn_dungeon_mob'))
    child.components.lootdropper:DropLoot()
end)
