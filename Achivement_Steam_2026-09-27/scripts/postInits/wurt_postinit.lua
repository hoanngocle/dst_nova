-- CC : add mermprotectorspawner >> [Reward] expertwurt2, basic wurt max stats changing
if TheNet:GetIsServer() then
    AddPrefabPostInit("wurt", function(inst)
        inst:AddComponent("mermprotectorspawner")
        inst:ListenForEvent("onmermkingcreated_anywhere", function()
            inst:DoTaskInTime(1.1, function()
                if inst.components.levelsystem then
                    inst.components.levelsystem:resetbasestat()
                end
            end)
        end, TheWorld)
        inst:ListenForEvent("onmermkingdestroyed_anywhere", function()
            inst:DoTaskInTime(1.1, function()
                if inst.components.levelsystem then
                    inst.components.levelsystem:resetbasestat()
                end
            end)
        end, TheWorld)
    end)
end
