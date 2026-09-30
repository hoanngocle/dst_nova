-- QA only: execute from a separate test mod, never imported by modmain.lua.
local G=GLOBAL or _G
G.setfenv(1,G)
local function check(name,fn)
    local ok,err=xpcall(fn,debug.traceback)
    print(ok and 'HN_QA_PASS' or 'HN_QA_FAIL',name,err or '')
    return ok
end
local function start()
    local m=TheWorld.components.hn_dungeon_manager
    if not m then print('HN_QA_CAVES',TheWorld:HasTag('cave'));return end
    assert(m:FindArena(),'missing arena')
    print('HN_QA_ARENA',m.dungeon_center_x,m.dungeon_center_z)
    local x,z=m.dungeon_center_x,m.dungeon_center_z
    local spawned={}
    local function spawn(n)
        local e=assert(SpawnPrefab(n),'missing '..n);e.Transform:SetPosition(x+5,0,z+5);spawned[#spawned+1]=e;return e
    end
    local names={'hn_dungeon_gate','hn_recovery_bag','hn_treasure_rock','hn_dungeon_spider','hn_dungeon_pig','hn_dungeon_firehound','hn_dungeon_icehound','hn_dungeon_snowhound','hn_dungeon_lightninghound','hn_dungeon_horrorhound','hn_hound_glacial_proj','hn_hound_lightning','hn_sharkboi','hn_igris','hn_beru','hn_shark_ice_fx','hn_shark_ice_start_fx','hn_corpse_igris','hn_corpse_beru'}
    for _,n in ipairs(names) do check('spawn '..n,function() local e=spawn(n);assert(e:IsValid());e:Remove() end) end
    check('gate mainland',function() local gx,gz=m:FindMainlandGatePoint(true);assert(gx and m:IsValidGatePoint(gx,gz,true));print('HN_QA_GATE_POINT',gx,gz) end)
    local target=spawn('pigman');target:AddTag('player');target:AddTag('in_hn_dungeon');target.components.health:SetInvincible(true)
    target:StopBrain();target.Transform:SetPosition(x+3,0,z+3)
    local cases={
        {'hn_igris','attack1'},{'hn_igris','relentless_dash_1'},{'hn_igris','attack_rotate_pre'},{'hn_igris','attack_around'},{'hn_igris','shadow_blink_pre'},
        {'hn_beru','attack1'},{'hn_beru','attack_jump_pre'},{'hn_beru','strong'},{'hn_beru','pig_control'},
        {'hn_sharkboi','attack1'},{'hn_sharkboi','attack2'},{'hn_sharkboi','attack3'},{'hn_sharkboi','ice_summon'},
    }
    for i,c in ipairs(cases) do
        TheWorld:DoTaskInTime(i*8,function()
            check('skill '..c[1]..'/'..c[2],function()
                local e=spawn(c[1]);e:StopBrain();e.entity:SetCanSleep(false)
                require('hn_dungeon/combat').ApplyStats(e,1.5,true)
                e.components.combat:SetTarget(target);e.sg:GoToState(c[2],target)
                e:DoTaskInTime(7,function() if e:IsValid() then e:Remove() end end)
            end)
        end)
    end
    TheWorld:DoTaskInTime((#cases+1)*8,function()
        for _,e in ipairs(spawned) do if e:IsValid() then e:Remove() end end
        print('HN_QA_DONE')
    end)
end
TheWorld:DoTaskInTime(3,start)
