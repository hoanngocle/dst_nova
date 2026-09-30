local function setup()
    local a=require('support/dst_mock').Install()
    a.exit=SpawnPrefab('hn_dungeon_exit');a.exit.Transform:SetPosition(100,0,100)
    local Manager=require('components/hn_dungeon_manager')
    a.m=Manager(a.world);a.world.components.hn_dungeon_manager=a.m
    a.m.FindMainlandGatePoint=function() return 10,20 end
    a.m.IsValidGatePoint=function() return true end
    a.advance(1)
    return a
end
test('gate readiness needs arena and required rewards',function()
    local a=setup();assert(a.m.state=='READY' and a.m.active_gate:IsValid())
    local first=a.m.active_gate;a.m:TrySpawnGate();assert(a.m.active_gate==first)
    local p=a.player();assert(a.m:CanEnter(p))
    Prefabs.xd_lingshi1=nil;assert(not a.m:CanEnter(p))
end)
test('spawn queue reaches ten enemies and repeated death cannot advance twice',function()
    local a=setup();local spawn=SpawnPrefab
    SpawnPrefab=function(name)
        local e=spawn(name)
        e.components.health={maxhealth=100,SetMaxHealth=function(self,n) self.maxhealth=n end,IsDead=function() return false end}
        e.components.combat={SetKeepTargetFunction=function() end,SetRetargetFunction=function() end}
        e.components.lootdropper={GenerateLoot=function() return {} end,DropLoot=function() end}
        return e
    end
    local p=a.player();a.m:Enter(p);a.advance(27)
    local mobs={};for mob in pairs(a.m.monsters) do mobs[#mobs+1]=mob end
    assert(#mobs==10 and a.m.pending_spawns==0)
    for _,mob in ipairs(mobs) do mob:PushEvent('death');mob:PushEvent('death') end
    assert(a.m.wave_finishing and next(a.m.monsters)==nil)
    local starts=0;a.m.StartWave=function() starts=starts+1 end;a.advance(10);assert(starts==1)
end)
test('entry starts first wave after five seconds and closes late admission',function()
    local a=setup();local p=a.player();local started={}
    a.m.StartWave=function(self,n) self.current_wave=n;started[#started+1]=n end
    assert(a.m:Enter(p));assert(p:HasTag('in_hn_dungeon') and p.x==100)
    a.advance(4.9);assert(#started==0);a.advance(.1);assert(started[1]==1)
    a.m.current_wave=2;assert(not a.m:CanEnter(a.player()))
end)
test('reset invalidates pending spawns and returns players',function()
    local a=setup();local p=a.player();local old=a.m.run_epoch
    a.m:Enter(p);a.m:Fail('test')
    assert(a.m.run_epoch>old and a.m.state=='COOLDOWN')
    assert(p.x==10 and p.z==20 and not p:HasTag('in_hn_dungeon'))
    a.advance(6);assert(a.m.current_wave==0 and next(a.m.monsters)==nil)
    a.advance(474);assert(a.m.state=='READY')
end)
test('last player leaving ends failed attempt, with cooldown',function()
    local a=setup();local p=a.player();a.m:Enter(p)
    assert(a.m:Leave(p,'dungeon_exit'));assert(a.m.state=='COOLDOWN')
    assert(p.components.hn_dungeon_cooldown:GetTime()==480)
end)
test('save during combat aborts on load and recovers offline player position',function()
    local a=setup();local p=a.player();a.m:Enter(p)
    local saved=a.m:OnSave();assert(saved.version==1)
    local b=setup();b.m:OnLoad(saved);local reconnect=b.player();reconnect.Transform:SetPosition(100,0,100)
    b.world:PushEvent('ms_playerjoined',reconnect);b.advance(1)
    assert(b.m.state=='COOLDOWN' and reconnect.x==10 and reconnect.z==20)
end)
test('wave boundary uses ten regular enemies and hard boss pool',function()
    local waves=require('hn_dungeon/waves')
    assert(#waves.Get(1,5,math.random).prefabs==10)
    local soft=waves.Get(5,5,math.random);assert(soft.is_boss and soft.multiplier==1)
    local hard=waves.Get(6,6,function() return 1 end)
    assert(hard.is_boss and hard.multiplier==1.5 and hard.prefabs[1]=='hn_sharkboi')
end)
test('companion tokens in nested inventory refuse entry without changing ownership',function()
    local a=setup();local p=a.player();local token=a.entity('chester_eyebone');local backpack=a.entity('backpack')
    backpack.components.container={slots={token}};p.components.inventory={itemslots={},equipslots={body=backpack}}
    assert(not a.m:CanEnter(p));assert(token:IsValid() and backpack.components.container.slots[1]==token)
end)
