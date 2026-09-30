local M={}
function M.CanTeleport(player,fx,fz,tx,tz)
    local manager=TheWorld and TheWorld.components.hn_dungeon_manager
    if not manager then return true end
    local from=manager:IsPointInsideDungeon(fx,fz);local to=manager:IsPointInsideDungeon(tx,tz)
    if not from and not to then return true end
    if from~=to then return false,'Không thể dịch chuyển qua ranh giới Hầm Ngục.' end
    if not TheWorld.Map:IsPassableAtPoint(tx,0,tz) or not TheWorld.Pathfinder:IsClear(fx,0,fz,tx,0,tz) then
        return false,'Không thể dịch chuyển qua tường Hầm Ngục.'
    end
    return true
end
function M.DenyTravel(player)
    if player and player:HasTag('in_hn_dungeon') then
        if player.components and player.components.talker then player.components.talker:Say('Hãy dùng lối ra Hầm Ngục.') end
        return true
    end
    return false
end
return M
