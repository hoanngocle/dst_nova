local M={}
function M.CanRequest(player,gate,manager,committing)
    return player~=nil and player:IsValid() and player.sg~=nil and not player:HasTag('playerghost')
        and (committing or not player:HasTag('hn_dungeon_transition'))
        and gate~=nil and gate:IsValid() and gate.prefab=='hn_dungeon_gate'
        and player:GetDistanceSqToInst(gate)<=36 and manager~=nil
        and manager:IsActiveGate(gate) and manager:CanEnter(player)
end
return M
