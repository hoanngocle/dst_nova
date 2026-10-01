-- QA-only harness. Run in an isolated offline cluster through hn_extraqa.
local G=GLOBAL or _G
G.setfenv(1,G)
local failed=0
local function check(name,fn)
    local ok,err=xpcall(fn,debug.traceback)
    if not ok then failed=failed+1 end
    print(ok and 'HN_EXTRA_PASS' or 'HN_EXTRA_FAIL',name,err or '')
end
TheWorld:DoTaskInTime(3,function()
    local m=TheWorld.components.hn_dungeon_manager
    assert(m and m:FindArena(),'missing arena')
    m:CancelRunTasks();m.state='IN_PROGRESS';m.current_wave=6;m.max_waves=6;m.is_cleared=false
    local x,z=m.dungeon_center_x,m.dungeon_center_z
    local H=require('hn_dungeon/boss_hazards')
    local spawned={}
    local function spawn(name,boss)
        local e=assert(SpawnPrefab(name),name);spawned[#spawned+1]=e
        e.Transform:SetPosition(x+3,0,z+3);e.entity:SetCanSleep(false)
        if boss then
            m:Track(e);m.monsters[e]=true
            require('hn_dungeon/combat').ApplyStats(e,1.5,true)
            e:StopBrain()
        end
        return e
    end
    local target=spawn('pigman');target:StopBrain();target:AddTag('player');target:AddTag('in_hn_dungeon')
    target.components.health:SetInvincible(true);m.players_in_dungeon[target]=true
    local guardian
    local clears=0
    local rewards=require('hn_dungeon/rewards')
    local originalClear=rewards.GrantClear
    rewards.GrantClear=function(...)
        clears=clears+1
        if Prefabs.xd_lingshi1 then return originalClear(...) end
        -- Standalone harness has no Tu Tien items; full-stack run uses real rewards.
    end
    check('real prefab health floor and one phase transition',function()
        guardian=spawn('hn_minotau',true)
        guardian.hn_is_dungeon_boss=true
        guardian:ListenForEvent('death',function() m:OnMonsterDeath(guardian) end)
        guardian.components.health:DoDelta(-1e12)
        assert(not guardian.components.health:IsDead() and guardian.components.hn_boss_phases.phase=='transitioning')
        assert(m.monsters[guardian] and not m.is_cleared and clears==0)
    end)
    TheWorld:DoTaskInTime(5,function()
        check('phase two scaled maxhealth and final death exactly once',function()
            assert(guardian.components.hn_boss_phases.phase==2 and guardian.nightmare)
            assert(guardian.components.health.currenthealth==guardian.components.health.maxhealth)
            local deaths=0;guardian:ListenForEvent('death',function() deaths=deaths+1 end)
            guardian.components.health:DoDelta(-1e12);guardian.components.health:DoDelta(-1e12)
            assert(guardian.components.health:IsDead() and deaths==1)
            m:OnMonsterDeath(guardian)
            assert(clears==1 and m.is_cleared,'reward before phase two or duplicate reward')
            m.monsters[guardian]=nil;guardian:Remove()
            m:CancelRunTasks();m.is_cleared=false;m.wave_finishing=false
        end)
    end)
    TheWorld:DoTaskInTime(6,function()
        check('real combat damage and overlapping fire use current owner multipliers once',function()
            local owner=spawn('hn_minotau',true)
            local original=target.components.combat.GetAttacked
            local hits={}
            target.components.combat.GetAttacked=function(_,source,damage) assert(source==owner);hits[#hits+1]=damage end
            local base=owner.components.combat:CalcDamage(target)
            H.Hit(owner,target,1);H.Hit(owner,target,1.5)
            H.FireHit(owner,target);H.FireHit(owner,target);H.FireHit(owner,target)
            target.components.combat.GetAttacked=original
            assert(#hits==3 and hits[1]==base and hits[2]==base*1.5 and hits[3]==base*.15)
            print('HN_EXTRA_DAMAGE',base,owner.components.health.maxhealth)
            m.monsters[owner]=nil;owner:Remove()
        end)
        check('wall lifetime and no farmable components',function()
            local owner=spawn('hn_dual_wield_pig',true)
            local wall=assert(H.Spawn(owner,'hn_boss_moonrock_wall',{x=x+8,z=z+8}))
            assert(not wall.persists and not wall.components.lootdropper and not wall.components.workable)
            TheWorld:DoTaskInTime(4.2,function()
                check('wall removed after four seconds',function() assert(not wall:IsValid()) end)
                m.monsters[owner]=nil;owner:Remove()
            end)
        end)
    end)
    local cases={
        {'hn_beetle_pig','attack1'},{'hn_beetle_pig','attack_jump_pre'},{'hn_beetle_pig','strong'},{'hn_beetle_pig','pig_control'},
        {'hn_dual_wield_pig','attack1'},{'hn_dual_wield_pig','attack_rotate_pre'},{'hn_dual_wield_pig','attack_around'},
        {'hn_minotau','groundpound'},{'hn_minotau','charge_start'},{'hn_minotau','charge_small'},
        {'hn_minotau','slam_start',2},{'hn_minotau','ringoffire'},{'hn_minotau','teleport_start',3},
    }
    for i,c in ipairs(cases) do
        TheWorld:DoTaskInTime(6+i*4,function()
            check('skill '..c[1]..'/'..c[2],function()
                local e=spawn(c[1],true);e.components.combat:SetTarget(target)
                if e.ActivateNightmareMode then e:ActivateNightmareMode() end
                e.sg:GoToState(c[2],c[3] or (c[1]~='hn_minotau' and target or nil))
                e:DoTaskInTime(3.8,function()
                    check('removal '..c[1]..'/'..c[2],function()
                        m.monsters[e]=nil;e:Remove()
                        for _,fx in pairs(Ents) do assert(fx.hn_boss_owner~=e or not fx:IsValid(),'orphaned hazard') end
                    end)
                end)
            end)
        end)
    end
    TheWorld:DoTaskInTime(64,function()
        check('guardian reset during transition removes callbacks and hazards',function()
            local e=spawn('hn_minotau',true);e.components.health:DoDelta(-1e12)
            H.Spawn(e,'hn_minotau_shadowblaze',e:GetPosition())
            m.players_in_dungeon={};m:Reset('extra_qa')
            assert(not e:IsValid())
        end)
    end)
    TheWorld:DoTaskInTime(70,function()
        check('no live hazard after reset',function()
            for _,e in pairs(Ents) do assert(not e.hn_boss_owner or not e:IsValid(),'hazard remained') end
        end)
        for _,e in ipairs(spawned) do if e:IsValid() then e:Remove() end end
        print('HN_EXTRA_DONE',failed)
        rewards.GrantClear=originalClear
    end)
end)
