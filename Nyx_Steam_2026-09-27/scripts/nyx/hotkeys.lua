local Router = require('nyx/input')

local M = {}
local bindings = {
    {key = KEY_G, id = 'absolute_domain'},
    {key = KEY_T, id = 'triflame_fan'},
    {key = KEY_H, id = 'yellow_river'},
    {key = KEY_R, id = 'purple_gather'},
    {key = KEY_F1, id = 'purple_eye'},
    {key = KEY_F2, id = 'moon_wings'},
}

function M.Install(input, get_frontend, get_player)
    local function activate(id)
        Router.ActivateSkill(get_player(), get_frontend(), id)
    end
    for _, binding in ipairs(bindings) do
        local id = binding.id
        input:AddKeyDownHandler(binding.key, function() activate(id) end)
    end
end

return M
