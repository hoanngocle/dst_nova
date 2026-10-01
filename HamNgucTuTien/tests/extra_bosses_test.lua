local Mock=require('support/dst_mock')
test('high dungeons select each of six bosses uniformly; low pool unchanged',function()
    local waves=require('hn_dungeon/waves')
    local expected={'hn_sharkboi','hn_igris','hn_beru','hn_beetle_pig','hn_dual_wield_pig','hn_minotau'}
    for _,total in ipairs({6,10}) do
        for i,name in ipairs(expected) do
            local spec=waves.Get(total,total,function(n) assert(n==6);return i end)
            assert(spec.prefabs[1]==name and #spec.prefabs==1 and spec.multiplier==1.5)
        end
    end
    for i,name in ipairs({'deerclops','bearger','dragonfly','minotaur','spiderqueen','leif','warg'}) do
        local spec=waves.Get(5,5,function(n) assert(n==7);return i end)
        assert(spec.prefabs[1]==name and spec.multiplier==1)
    end
end)
local function setup()
    local api=Mock.Install()
    local owner=api.entity('hn_minotau')
    local manager={state='IN_PROGRESS',run_epoch=4,monsters={[owner]=true},players_in_dungeon={},run_entities={}}
    function manager:IsPointInsideDungeon(x,z) return x*x+z*z<40*40 end
    function manager:Track(e) self.run_entities[e]=true;e.hn_dungeon_manager=self;e.hn_dungeon_run_epoch=self.run_epoch end
    api.world.Pathfinder={IsClear=function() return true end}
    owner.hn_dungeon_manager=manager;owner.hn_dungeon_run_epoch=4
    owner.components.health={maxhealth=843750,currenthealth=1,IsDead=function(self) return self.currenthealth<=0 end,
        SetMinHealth=function(self,v) self.minhealth=v end,SetInvincible=function(self,v) self.invincible=v end,
        SetPercent=function(self,v) self.currenthealth=self.maxhealth*v end}
    owner.components.combat={CalcDamage=function() return 360 end}
    owner.sg={GoToState=function(self,s) self.state=s end}
    owner.components.locomotor={Stop=function() end}
    owner.ActivateNightmareMode=function(self) self.nightmare=true end
    return api,owner,manager
end
test('new boss definitions keep approved base stats',function()
    Asset=function() end
    package.preload['brains/hn_com_monster']=function() return {} end
    local defs=require('hn_dungeon/extra_boss_defs')
    assert(defs.hn_beetle_pig.health==25000 and defs.hn_dual_wield_pig.health==30000)
    local t=require('hn_dungeon/minotau_tuning')
    assert(t.HEALTH==25000 and t.DAMAGE==60 and t.TRANSITION_TIME==4.5)
end)
test('guardian phase floor ignores duplicate events and restores already scaled health once',function()
    local api,o,m=setup()
    local phase=require('components/hn_boss_phases')(o)
    o.components.hn_boss_phases=phase
    o:PushEvent('minhealth');o:PushEvent('minhealth')
    assert(phase.phase=='transitioning' and o.components.health.invincible and m.monsters[o])
    api.advance(4.5)
    assert(phase.phase==2 and o.components.health.currenthealth==843750 and o.components.health.minhealth==0)
    o.components.health.currenthealth=2;o:PushEvent('minhealth');api.advance(5)
    assert(o.components.health.currenthealth==2 and o.nightmare)
end)
test('reset during guardian transition cannot revive it',function()
    local api,o,m=setup()
    o.components.hn_boss_phases=require('components/hn_boss_phases')(o)
    o:PushEvent('minhealth');api.advance(4);m.run_epoch=5;m.state='COOLDOWN';api.advance(1)
    assert(not o.nightmare and o.components.health.currenthealth==1)
end)
test('hazards use owner scaled damage and reject outsiders structures dead owners and stale runs',function()
    local api,o,m=setup();local h=require('hn_dungeon/boss_hazards')
    local p=api.player();p:AddTag('in_hn_dungeon');m.players_in_dungeon[p]=true
    local hits={};p.components.combat={GetAttacked=function(_,source,damage) assert(source==o);hits[#hits+1]=damage end}
    assert(h.Hit(o,p,1.5));assert(hits[1]==540)
    assert(h.FireHit(o,p));assert(not h.FireHit(o,p));assert(not h.FireHit(o,p));assert(hits[2]==54)
    api.advance(1);assert(h.FireHit(o,p))
    m.players_in_dungeon[p]=nil;assert(not h.Hit(o,p,1))
    assert(not h.Hit(o,api.entity('wall'),1))
    m.players_in_dungeon[p]=true;p.x=50;assert(not h.Hit(o,p,1));p.x=0
    o.components.health.currenthealth=0;assert(not h.Hit(o,p,1));o.components.health.currenthealth=1
    m.run_epoch=5;assert(not h.Hit(o,p,1))
end)
test('hazards are tracked outside monster count and expire with owner',function()
    local api,o,m=setup();local h=require('hn_dungeon/boss_hazards')
    local fx=h.Spawn(o,'hn_test_fx',{x=0,z=0})
    assert(fx and m.run_entities[fx] and not m.monsters[fx])
    assert(not h.Spawn(o,'hn_test_fx',{x=50,z=0}))
    o:PushEvent('death');assert(not fx:IsValid())
end)
test('actual manager Track supplies the epoch used by phase and hazard guards',function()
    local api,o=setup()
    local manager=require('components/hn_dungeon_manager')(api.world)
    manager.state='IN_PROGRESS';manager.monsters[o]=true;manager:Track(o)
    assert(require('hn_dungeon/boss_hazards').IsActive(o))
    manager.run_epoch=manager.run_epoch+1
    assert(not require('hn_dungeon/boss_hazards').IsActive(o))
end)
test('a radial shockwave cast has four separated origins and one shared hit budget',function()
    local api,o,m=setup();local h=require('hn_dungeon/boss_hazards')
    local waves=h.SpawnShockwaves(o)
    assert(#waves==4)
    for _,wave in ipairs(waves) do
        assert(math.abs(wave.x*wave.x+wave.z*wave.z-9)<.0001)
        assert(wave.hn_hitlist==waves[1].hn_hitlist and m.run_entities[wave])
    end
    local p=api.player();p:AddTag('in_hn_dungeon');m.players_in_dungeon[p]=true
    local hits=0;p.components.combat={GetAttacked=function() hits=hits+1 end}
    for _,wave in ipairs(waves) do h.Area(o,p:GetPosition(),2,1,false,wave.hn_hitlist) end
    assert(hits==1)
end)
test('safe motion rejects paths crossing walls and points outside arena',function()
    local api,o=setup();local h=require('hn_dungeon/boss_hazards')
    assert(h.SafePoint(o,{x=2,z=2}))
    assert(not h.SafePoint(o,{x=50,z=2}))
    api.world.Pathfinder.IsClear=function() return false end
    assert(not h.SafePoint(o,{x=2,z=2}))
end)
test('hazards admit living registered companions and use current owner damage',function()
    local api,o,m=setup();local h=require('hn_dungeon/boss_hazards')
    local p=api.player();p:AddTag('in_hn_dungeon');m.players_in_dungeon[p]=true
    local pet=api.entity('abigail');pet.components.follower={leader=p}
    pet.components.health={IsDead=function() return false end}
    local last;pet.components.combat={GetAttacked=function(_,owner,damage) last=damage end}
    assert(h.Hit(o,pet,1) and last==360)
    o.components.combat.CalcDamage=function() return 720 end
    assert(h.Hit(o,pet,1.5) and last==1080)
    p:AddTag('playerghost');assert(not h.Hit(o,pet,1))
end)
test('real Than Khi realm update during transition does not stack dungeon scaling again',function()
    package.path='ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;'..package.path
    local scaling=require('tbc_monster_scaling')
    local api,o=setup();local health=o.components.health
    health.maxhealth=25000;health.currenthealth=25000
    health.SetMaxHealth=function(self,value) self.maxhealth=value;self.currenthealth=value end
    o.components.combat.defaultdamage=60
    o.components.combat.SetKeepTargetFunction=function() end
    o.components.combat.SetRetargetFunction=function() end
    require('hn_dungeon/combat').ApplyStats(o,1.5,true)
    scaling.ApplyMonster(o,'boss',200,0)
    assert(health.maxhealth==281250)
    o.components.hn_boss_phases=require('components/hn_boss_phases')(o)
    health.currenthealth=1;o:PushEvent('minhealth')
    scaling.ApplyMonster(o,'boss',200,12)
    api.advance(4.5)
    assert(health.maxhealth==843750 and health.currenthealth==843750)
    assert(o.components.combat.defaultdamage==240 and o.components.combat.damagemultiplier==1.5)
end)
test('pig speed buff refresh and death cleanup preserve unrelated speed modifiers',function()
    local api=Mock.Install();local pig=api.entity('hn_beetle_pig');local mods={other=1.3}
    pig.components.locomotor={SetExternalSpeedMultiplier=function(_,source,key,value) mods[key]=value end,
        RemoveExternalSpeedMultiplier=function(_,source,key) mods[key]=nil end}
    pig:AddComponent('hn_combat_effects')
    local effects=pig.components.hn_combat_effects
    effects:Apply('speed',pig,10,{multiplier=2});api.advance(9)
    effects:Apply('speed',pig,10,{multiplier=2});api.advance(2)
    assert(mods.hn_speed==2)
    pig:PushEvent('death');assert(mods.hn_speed==nil and mods.other==1.3)
    api.advance(15);assert(mods.hn_speed==nil and next(effects.effects)==nil)
end)
