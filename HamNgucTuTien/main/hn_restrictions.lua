local Rules=require('hn_dungeon/restrictions')
local old=GLOBAL.IsTeleportingPermittedFromPointToPoint
GLOBAL.IsTeleportingPermittedFromPointToPoint=function(fx,fy,fz,tx,ty,tz,...)
    return Rules.CanTeleport(nil,fx,fz,tx,tz) and (not old or old(fx,fy,fz,tx,ty,tz,...))
end
do
    local ba=GLOBAL.BufferedAction
    local original=ba.IsValid
    ba.IsValid=function(self,...)
        local doer,target,action=self.doer,self.target,self.action
        local inside=doer and doer:HasTag('in_hn_dungeon')
        if inside and (action==ACTIONS.JUMPIN or action==ACTIONS.REVIVE or action==ACTIONS.RESURRECT
            or (action==ACTIONS.HAUNT and target and target.prefab=='amulet')) then return false end
        if target and target:HasTag('in_hn_dungeon') and (action==ACTIONS.REVIVE or action==ACTIONS.RESURRECT) then return false end
        return original(self,...)
    end
end
