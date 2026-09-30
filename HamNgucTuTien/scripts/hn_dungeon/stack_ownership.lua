-- DST merges stacks without sending onputininventory to the survivor.
-- A mixed stack is preserved in full: never discard a player's units.
local M={}
function M.Wrap(stack)
    if stack.hn_ownership_wrapped then return end
    stack.hn_ownership_wrapped=true
    local put,get=stack.Put,stack.Get
    stack.Put=function(self,item,...)
        local target=self.inst.components.hn_owned
        local source=item and item.components.hn_owned
        local preserve=target and target.run_id and (not source or not source.run_id or source.claimed or source.run_id~=target.run_id)
        local before=self.stacksize
        local result=put(self,item,...)
        if preserve and self.stacksize>before then target.claimed=true end
        return result
    end
    stack.Get=function(self,...)
        local source=self.inst.components.hn_owned
        local result=get(self,...)
        if result and result~=self.inst and source and (source.run_id or source.claimed) then
            if not result.components.hn_owned then result:AddComponent('hn_owned') end
            local target=result.components.hn_owned
            target.run_id=source.run_id
            target.claimed=target.claimed or source.claimed
        end
        return result
    end
end
return M
