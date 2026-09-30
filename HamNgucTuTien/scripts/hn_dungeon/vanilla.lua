local M={}
-- The stock death state creates a second reward chest outside lootdropper.
function M.PatchMinotaurDeath(state)
    local old=state.onenter
    state.onenter=function(inst)
        if not inst.hn_is_dungeon_boss then return old(inst) end
        inst.components.locomotor:StopMoving();inst.AnimState:PlayAnimation('death')
        inst.persists=false;inst:DropDeathLoot();inst:AddTag('NOCLICK')
    end
end
function M.TrackSummons(monster,manager,epoch)
    local function track(child)
        if not child or not child:IsValid() then return end
        if manager.run_epoch~=epoch then child:Remove();return end
        manager:Track(child,epoch);child.hn_summon=true
        require('hn_dungeon/combat').ApplyStats(child,1,false)
        if child.components.lootdropper then child.components.lootdropper.DropLoot=function() end end
        M.TrackSummons(child,manager,epoch)
    end
    local leader=monster.components.leader
    if leader and not leader.hn_wrapped then
        leader.hn_wrapped=true;local old=leader.AddFollower
        leader.AddFollower=function(self,child,...) local result=old(self,child,...);track(child);return result end
    end
    local spawner=monster.components.childspawner
    if spawner and not spawner.hn_wrapped then
        spawner.hn_wrapped=true;local old=spawner.DoSpawnChild
        spawner.DoSpawnChild=function(self,...) local child=old(self,...);track(child);return child end
    end
end
return M
