local M={}
function M.Attach(fx,owner)
    if not fx or not owner or fx._nyx_lifecycle_owner then return fx end
    fx._nyx_lifecycle_owner=owner
    local function remove() if fx:IsValid() then fx:Remove() end end
    for _,event in ipairs({'death','ms_becameghost','onremove'}) do fx:ListenForEvent(event,remove,owner) end
    return fx
end
return M
