local M={}
function M.Run(manager)
    local roots={}
    for _,e in pairs(Ents or {}) do
        local owned=e.components and e.components.hn_owned
        if owned and owned.run_id and not owned.claimed and e:IsValid() and not e:HasTag('player') then roots[#roots+1]=e end
    end
    for _,e in ipairs(roots) do
        if e:IsValid() and e.parent==nil then
            local item=e.components.inventoryitem
            if not item or not item:IsHeld() then
                require('hn_dungeon/recovery').RescueContainer(e,manager)
                e:Remove()
            end
        end
    end
    manager.run_entities={};manager.monsters={};manager.pending_spawns=0
end
return M
