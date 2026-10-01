local Combat=require('hn_dungeon/combat')
local T=require('hn_dungeon/minotau_tuning')
local M={}
function M.IsActive(owner)
    if not TheWorld.ismastersim or not owner or not owner:IsValid() then return false end
    local m=owner.hn_dungeon_manager
    return m~=nil and m.state=='IN_PROGRESS' and not m.is_cleared
        and owner.hn_dungeon_run_epoch==m.run_epoch and m.monsters[owner]==true
        and owner.components.health~=nil and not owner.components.health:IsDead()
end
function M.IsInside(owner,x,z)
    local m=owner.hn_dungeon_manager
    return m~=nil and m:IsPointInsideDungeon(x,z)
        and TheWorld.Map:IsPassableAtPoint(x,0,z)
end
function M.CanTarget(owner,target)
    if not M.IsActive(owner) or not Combat:CanHitTarget(owner,target) or not Combat:NotIsDead(target) then return false end
    local player=target:HasTag('player') and target or (target.components.follower and target.components.follower.leader)
    local x,_,z=target.Transform:GetWorldPosition()
    return player~=nil and owner.hn_dungeon_manager.players_in_dungeon[player]~=nil
        and owner.hn_dungeon_manager.players_in_dungeon[player]~=false and M.IsInside(owner,x,z)
end
function M.Hit(owner,target,multiplier)
    if not M.CanTarget(owner,target) or not target.components.combat then return false end
    local damage,special=owner.components.combat:CalcDamage(target)
    multiplier=multiplier or 1
    if special then local scaled={};for k,v in pairs(special) do scaled[k]=v*multiplier end;special=scaled end
    target.components.combat:GetAttacked(owner,(damage or 0)*multiplier,nil,nil,special)
    return true
end
function M.FireHit(owner,target)
    if not M.CanTarget(owner,target) then return false end
    owner.hn_fire_hits=owner.hn_fire_hits or setmetatable({},{__mode='k'})
    local now=GetTime()
    if (owner.hn_fire_hits[target] or -math.huge)>now then return false end
    owner.hn_fire_hits[target]=now+1
    return M.Hit(owner,target,T.FIRE_MULTIPLIER)
end
function M.Area(owner,pos,radius,multiplier,fire,hitlist)
    if not M.IsActive(owner) then return end
    for _,target in ipairs(TheSim:FindEntities(pos.x,0,pos.z,radius,{'_combat'},{'INLIMBO','FX','playerghost'})) do
        if not hitlist or not hitlist[target] then
            local hit=fire and M.FireHit(owner,target) or (not fire and M.Hit(owner,target,multiplier))
            if hit and hitlist then hitlist[target]=true end
        end
    end
end
function M.Spawn(owner,prefab,pos)
    if not M.IsActive(owner) then return end
    pos=pos or owner:GetPosition()
    if not M.IsInside(owner,pos.x,pos.z) then return end
    local fx=SpawnPrefab(prefab)
    if not fx then return end
    fx.persists=false;fx.hn_boss_owner=owner
    owner.hn_dungeon_manager:Track(fx)
    fx.Transform:SetPosition(pos.x,0,pos.z)
    local function remove() if fx:IsValid() then fx:Remove() end end
    fx:ListenForEvent('death',remove,owner)
    fx:ListenForEvent('onremove',remove,owner)
    fx:DoPeriodicTask(.25,function() if not M.IsActive(owner) then remove() end end)
    return fx
end
function M.SafePoint(owner,pos)
    if not pos or not M.IsInside(owner,pos.x,pos.z) then return false end
    local x,_,z=owner.Transform:GetWorldPosition()
    return TheWorld.Pathfinder~=nil and TheWorld.Pathfinder:IsClear(x,0,z,pos.x,0,pos.z)
end
function M.SpawnShockwaves(owner)
    local waves,hitlist={},{}
    local origin=owner:GetPosition()
    -- Four cardinal rays begin outside the owner, as in the source. A cast
    -- shares a hit set so adjacent rays cannot multiply damage on one target.
    for i=1,4 do
        local angle=(i-1)*math.pi/2
        local dir={x=math.cos(angle),z=math.sin(angle)}
        local pos={x=origin.x+dir.x*3,z=origin.z+dir.z*3}
        if M.SafePoint(owner,pos) then
            local wave=M.Spawn(owner,'hn_minotau_deadlyshockwave',pos)
            if wave then
                wave.hn_dir=dir;wave.hn_hitlist=hitlist
                waves[#waves+1]=wave
            end
        end
    end
    return waves
end
return M
