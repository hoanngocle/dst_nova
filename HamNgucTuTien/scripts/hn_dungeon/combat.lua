local M={}
function M.IsValidPlayerTarget(inst,target)
    return target~=nil and target:IsValid() and target:HasTag('player') and target:HasTag('in_hn_dungeon')
        and not target:HasTag('playerghost') and target.components.health~=nil and not target.components.health:IsDead()
end
function M.IsHHType(_,v,t) return type(v)==t end
function M.HasComponents(_,inst,name) return inst~=nil and inst.components~=nil and inst.components[name]~=nil end
function M.NotIsDead(_,inst) return inst~=nil and inst:IsValid() and inst.components.health~=nil and not inst.components.health:IsDead() end
function M.CanHitTarget(_,inst,target)
    if not target or not target:IsValid() or target==inst or target:HasTag('hn_dungeon_mob') or target:HasTag('FX') or target:HasTag('INLIMBO') then return false end
    if inst.hn_detached then return M.NotIsDead(M,target) end
    if target:HasTag('player') then return M.IsValidPlayerTarget(inst,target) end
    local follower=target.components.follower
    return follower~=nil and M.IsValidPlayerTarget(inst,follower.leader)
end
function M.HHKillTask(_,inst,key) if inst[key] then inst[key]:Cancel();inst[key]=nil end end
function M.HHSay(_,inst,text) if inst.components.talker then inst.components.talker:Say(text) end end
function M.SpawnClientStrFx(_,inst,text) M:HHSay(inst,text) end
function M.ApplyStats(inst,multiplier,is_boss)
    if inst.hn_stats_applied then return end
    inst.hn_stats_applied=true;inst:AddTag('hn_dungeon_mob')
    if inst.components.health then inst.components.health:SetMaxHealth(inst.components.health.maxhealth*multiplier) end
    local combat=inst.components.combat
    if combat then
        combat.damagemultiplier=(combat.damagemultiplier or 1)*multiplier
        combat:SetKeepTargetFunction(function(monster,target) return M:CanHitTarget(monster,target) end)
        combat:SetRetargetFunction(1,function(monster)
            return FindEntity(monster,100,function(target) return M:CanHitTarget(monster,target) end,{'_combat'},{'INLIMBO','playerghost'})
        end)
    end
    if inst.prefab=='lightninggoat' and inst.SetCharged then inst:SetCharged(true) end
end
return M
