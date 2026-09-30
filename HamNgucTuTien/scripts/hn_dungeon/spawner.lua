local Combat=require('hn_dungeon/combat')
local M={}
local delays={0,.5,1,10,10.5,11,20,20.5,21,21.5}
local function loot(monster)
    local result={};local dropper=monster.components.lootdropper
    if dropper then
        for _,name in ipairs(dropper:GenerateLoot()) do result[#result+1]={prefab=name,count=1} end
        dropper.DropLoot=function() end
    end
    return result
end
function M.Start(manager,spec,epoch)
    manager.pending_spawns=#spec.prefabs
    for i,name in ipairs(spec.prefabs) do
        manager:Schedule(spec.is_boss and 0 or delays[i],function()
            if manager.state~='IN_PROGRESS' or manager.run_epoch~=epoch then return end
            manager.pending_spawns=manager.pending_spawns-1
            local monster=SpawnPrefab(name)
            if not monster then manager:Fail('missing_prefab_'..name);return end
            manager:Track(monster,epoch);monster.hn_is_dungeon_monster=true;monster.hn_is_dungeon_boss=spec.is_boss
            local angle=math.random()*2*math.pi;local dist=math.random()*10
            monster.Transform:SetPosition(manager.dungeon_center_x+math.cos(angle)*dist,0,manager.dungeon_center_z+math.sin(angle)*dist)
            Combat.ApplyStats(monster,spec.multiplier,spec.is_boss)
            require("hn_dungeon/vanilla").TrackSummons(monster,manager,epoch)
            monster.hn_vanilla_loot=loot(monster)
            if spec.is_boss then manager.boss_vanilla_loot=monster.hn_vanilla_loot end
            manager.monsters[monster]=true
            monster:ListenForEvent('death',function() manager:OnMonsterDeath(monster) end)
            monster:ListenForEvent('onremove',function()
                if manager.state=='IN_PROGRESS' and manager.monsters[monster] and manager.run_epoch==epoch then manager:Fail('monster_removed') end
            end)
        end)
    end
end
function M.SpawnDetached(manager,x,z,total)
    local wave=require('hn_dungeon/waves').Get(1,total)
    local monster=SpawnPrefab(wave.prefabs[math.random(#wave.prefabs)])
    if not monster then return end
    monster.Transform:SetPosition(x,0,z)
    M.ConfigureDetached(monster,total)
end
function M.ConfigureDetached(monster,total)
    if monster.hn_detached_configured then return end
    monster.hn_detached_configured=true;monster.hn_detached=true;monster.hn_detached_total=total
    Combat.ApplyStats(monster,total>=6 and 3 or 2,false)
    monster.hn_vanilla_loot=loot(monster)
    monster:ListenForEvent('death',function()
        require('hn_dungeon/rewards').Monster({max_waves=total,Track=function(_,e) return e end},monster)
    end)
end
return M
