-- QA-only: regression checks exercise real stategraph update/event ordering.
local G=GLOBAL or _G
G.setfenv(1,G)
local failed=0
local function check(name,fn)
    local ok,err=xpcall(fn,tostring)
    if not ok then failed=failed+1 end
    print(ok and 'HN_REG_PASS' or 'HN_REG_FAIL',name,err or '')
end
TheWorld:DoTaskInTime(3,function()
    local m=TheWorld.components.hn_dungeon_manager
    assert(m and m:FindArena());m:CancelRunTasks();m.state='IN_PROGRESS';m.is_cleared=false
    local x,z=m.dungeon_center_x,m.dungeon_center_z
    local target=SpawnPrefab('pigman');target:StopBrain();target.entity:SetCanSleep(false)
    target:AddTag('player');target:AddTag('in_hn_dungeon');m.players_in_dungeon[target]=true
    target.Transform:SetPosition(x+8,0,z+3);target.components.health:SetInvincible(true)
    local hits=0
    target.components.combat.GetAttacked=function() hits=hits+1 end
    local function boss()
        local e=SpawnPrefab('hn_minotau');e:StopBrain();e.entity:SetCanSleep(false)
        m:Track(e);m.monsters[e]=true;e.Transform:SetPosition(x+3,0,z+3)
        require('hn_dungeon/combat').ApplyStats(e,1.5,true)
        e.components.combat:SetTarget(target)
        return e
    end
    local e=boss();e.sg:GoToState('charge',3)
    e:DoTaskInTime(2*FRAMES,function()
        check('charge survives buffered locomote events',function() assert(e.sg.currentstate.name=='charge',e.sg.currentstate.name) end)
    end)
    e:DoTaskInTime(.2,function()
        check('charge actually moves in arena',function() assert(e:GetDistanceSqToPoint(x+3,0,z+3)>.1) end)
        m.monsters[e]=nil;e:Remove()
        local small=boss();small.sg:GoToState('charge_small')
        small:DoTaskInTime(2*FRAMES,function()
            check('gore survives buffered locomote events',function() assert(small.sg.currentstate.name=='charge_small',small.sg.currentstate.name) end)
            m.monsters[small]=nil;small:Remove()
        end)
    end)
    TheWorld:DoTaskInTime(.6,function()
        hits=0
        local tele=boss();tele.sg:GoToState('teleport_post',1)
        tele:DoTaskInTime(1.4,function()
            check('teleport landing deals damage before leaving state',function() assert(hits>0,'no landing hit') end)
            m.monsters[tele]=nil;tele:Remove()
            m.players_in_dungeon={};m:Reset('regression');target:Remove()
            print('HN_REG_DONE',failed)
        end)
    end)
end)
