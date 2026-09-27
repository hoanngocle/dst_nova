-- Observe successful actions after other mods have registered their actions.
-- Tu Tien's machine implementation is encrypted, so its public action target
-- is the only integration point available without changing that mod.
local _G = GLOBAL
local function pack(...) return { n = _G.select("#", ...), ... } end

AddPrefabPostInit("xd_choujiangji", function(machine)
    if not _G.TheWorld.ismastersim then return end
    local trader = machine.components.trader
    if trader and trader.AcceptGift then
        local accept = trader.AcceptGift
        trader.AcceptGift = function(self, giver, item, ...)
            local result = accept(self, giver, item, ...)
            if result and giver and giver.components.allachivevent then
                giver:PushEvent("nova_slotmachine_spin", { machine = machine.GUID })
            end
            return result
        end
    end
end)

AddSimPostInit(function()
    if not _G.TheNet:GetIsServer() then return end
    for name, action in pairs(_G.ACTIONS) do
        local original = action.fn
        local farm_action = name == "TILL" or name == "WATER" or name == "FERTILIZE"
        local machine_action = type(name) == "string" and
            (name == "ACTIVATE" or string.find(name, "CHOU") or string.find(name, "SPIN")
                or string.find(name, "DRAW") or string.find(name, "GACHA") or string.find(name, "LOTTERY"))
        if type(original) == "function" and (farm_action or machine_action) then
            action.fn = function(act, ...)
                local machine = machine_action and act.target and act.target.prefab == "xd_choujiangji"
                local player = act.doer
                local results = pack(original(act, ...))
                if results[1] and player and player.components.allachivevent then
                    if machine then
                        player:PushEvent("nova_slotmachine_spin", { machine = act.target.GUID })
                    end
                    if farm_action then
                        player:PushEvent("nova_farm_action", { action = name })
                    end
                end
                return _G.unpack(results, 1, results.n)
            end
        end
    end
end)
