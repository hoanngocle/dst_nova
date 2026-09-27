local M = {}
function M.Install(api)
    local G = api.GLOBAL
    local tuning, strings = G.TUNING, G.STRINGS
    tuning.NYX_HEALTH, tuning.NYX_HUNGER, tuning.NYX_SANITY = 125, 125, 200
    -- Selection preview only. nyx.lua already grants these once on a new spawn.
    for _, items in pairs(tuning.GAMEMODE_STARTING_ITEMS) do
        items.NYX = {'xd_luoshen_krss', 'xd_wmz_zhf'}
    end
    for _, prefab in ipairs({'xd_luoshen_krss', 'xd_wmz_zhf'}) do
        tuning.STARTING_ITEM_IMAGE_OVERRIDE[prefab] = {
            atlas = 'images/inventoryimages/'..prefab..'.xml', image = prefab..'.tex',
        }
    end
    for _, prefab in ipairs({'xd_wmz_zhf', 'xd_wmz_zhf_ground'}) do
        strings.NAMES[string.upper(prefab)] = 'Vạn Linh Phiên'
        api.AddPrefabPostInit(prefab, function(inst)
            -- Also survives the localization mod replacing the shared name table.
            inst.displaynamefn = function() return 'Vạn Linh Phiên' end
        end)
    end
    if G.TheNet:IsDedicated() then return end
    G.require('characterutil')
    local original = G.SetHeroNameTexture_Gold
    G.SetHeroNameTexture_Gold = function(widget, character)
        local result = original(widget, character)
        if character == 'nyx' then
            if widget._nyx_original_name_scale == nil then
                local scale = widget:GetScale()
                widget._nyx_original_name_scale = {scale.x, scale.y, scale.z}
            end
            local scale = widget._nyx_original_name_scale
            widget:SetScale(scale[1] * .45, scale[2] * .45, scale[3])
        elseif widget._nyx_original_name_scale ~= nil then
            widget:SetScale(unpack(widget._nyx_original_name_scale))
            widget._nyx_original_name_scale = nil
        end
        return result
    end
end
return M
