local defs=require('hn_dungeon/reward_defs')
local M={}
function M.Roll(kind,tier,rng,prefab_exists)
    local result={};rng=rng or math.random;prefab_exists=prefab_exists or function(n) return Prefabs[n]~=nil end
    if kind=='monster' and rng()>=.5 then return result end
    for _,v in ipairs(assert(defs[tier][kind])) do
        local name,amount=v.prefab,v.count
        if not prefab_exists(name) then
            assert(v.fallback and prefab_exists('xd_lingshi1'),'missing required Tu Tien reward '..name)
            name='xd_lingshi1';amount=amount*v.fallback
        end
        result[#result+1]={prefab=name,count=amount}
    end
    return result
end
function M.SpawnLoot(manager,entries,pos,container)
    for _,entry in ipairs(entries) do
        local left=entry.count
        while left>0 do
            local item=SpawnPrefab(entry.prefab)
            if not item then error('Cannot spawn dungeon reward: '..entry.prefab) end
            local stack=item.components.stackable
            local amount=stack and math.min(left,stack.maxsize) or 1
            if stack then stack:SetStackSize(amount) end
            left=left-amount
            if manager then manager:Track(item) end
            item.Transform:SetPosition(pos.x,0,pos.z)
            if container then container:GiveItem(item,nil,nil,true) end
        end
    end
end
function M.Monster(manager,monster)
    if monster.hn_rewarded or monster.hn_is_dungeon_boss or monster.hn_summon then return end
    monster.hn_rewarded=true
    local pos=monster:GetPosition();local tier=manager.max_waves>=6 and 2 or 1
    if math.random()<.5 then M.SpawnLoot(manager,monster.hn_vanilla_loot or {},pos) end
    M.SpawnLoot(manager,M.Roll('monster',tier),pos)
end
function M.GrantClear(manager,run_id,pos)
    if manager.run_epoch~=run_id or not manager.is_cleared or manager.rewarded_run==run_id then return false end
    manager.rewarded_run=run_id
    local chest=SpawnPrefab('minotaurchest')
    if not chest then error('Missing dungeon reward chest') end
    manager:Track(chest);chest.Transform:SetPosition(pos.x,0,pos.z)
    local tier=manager.max_waves>=6 and 2 or 1
    M.SpawnLoot(manager,M.Roll('boss',tier),pos,chest.components.container)
    M.SpawnLoot(manager,manager.boss_vanilla_loot or {},pos,chest.components.container)
    for i=1,(tier==2 and 12 or 6) do
        manager:Schedule(i*.5,function()
            for _=1,50 do
                local angle=math.random()*2*math.pi;local distance=5+math.random()*30
                local x=manager.dungeon_center_x+math.cos(angle)*distance
                local z=manager.dungeon_center_z+math.sin(angle)*distance
                if TheWorld.Map:IsPassableAtPoint(x,0,z) and #TheSim:FindEntities(x,0,z,2.5,nil,{'FX','NOCLICK','DECOR'})==0 then
                    local rock=SpawnPrefab('hn_treasure_rock');if not rock then error('Missing dungeon mineral') end
                    manager:Track(rock);rock.hn_reward_tier=tier;rock.Transform:SetPosition(x,0,z);break
                end
            end
        end)
    end
    return true
end
return M
