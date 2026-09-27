local M = {}

function M.WrapStategraph(sg, actions)
    for _, action in ipairs(actions) do
        local handler = sg.actionhandlers ~= nil and sg.actionhandlers[action] or nil
        if handler ~= nil then
            local previous = handler.deststate
            handler.deststate = function(inst, act, ...)
                local state = type(previous) == "function"
                    and previous(inst, act, ...) or previous
                local prefab = act ~= nil and act.target ~= nil and act.target.prefab or nil
                if inst._tbc_solo_fast_act and state == "dolongaction"
                    and prefab ~= "junk_pile" and prefab ~= "junk_pile_big"
                    and prefab ~= "junk_pile_side" then
                    return "doshortaction"
                end
                return state
            end
        end
    end
end

return M
