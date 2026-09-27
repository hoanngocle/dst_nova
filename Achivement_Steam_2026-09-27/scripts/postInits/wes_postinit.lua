-- CC : rework ballon >> [Reward] expertwes2
if not chasni_getperkexcludeconfig("expertwes2") then
    if TheNet:GetIsServer() then
        AddPrefabPostInit("balloon", function(inst)
            local old_OnLoad = inst.OnLoad
            inst.OnLoad = function(_inst, data, ...)
                if data then
                    data.num = 1
                    old_OnLoad(_inst, data, ...)
                end
            end

            local function SetBalloonShape(_inst)
                _inst.balloon_num = 1
                _inst.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes2", "balloon_"..tostring(1))
                if _inst.components.inventoryitem then
                    _inst.components.inventoryitem:ChangeImageName("balloon_"..tostring(1))
                end
            end
            SetBalloonShape(inst)
        end)
    end
end
