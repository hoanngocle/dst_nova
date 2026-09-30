local M={}
local tokens={chester_eyebone=true,hutch_fishbowl=true,glommerflower=true}
function M.HasToken(container,seen)
    if not container then return false end
    seen=seen or {}
    for _,slots in ipairs({container.itemslots or container.slots or {},container.equipslots or {},{container.activeitem}}) do
        for _,item in pairs(slots) do
            if not seen[item] then
                seen[item]=true
                if tokens[item.prefab] or M.HasToken(item.components.container,seen) then return true end
            end
        end
    end
    return false
end
return M
