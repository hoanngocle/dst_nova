local G = GLOBAL

local function IsTreasureChest(inst)
    if inst == nil or not inst:IsValid() then
        return false
    end

    if inst.prefab == "treasurechest" or inst.prefab == "upgraded_treasurechest" then
        return true
    end

    local names = G.STRINGS and G.STRINGS.NAMES
    local name = names and names[string.upper(inst.prefab or "")]
    return type(name) == "string" and string.lower(name) == "hòm kho báu"
end

AddModRPCHandler(modname, "ttk_close_treasurechest", function(player, chest)
    if player == nil or chest == nil or not IsTreasureChest(chest) then
        return
    end

    local container = chest.components.container
    if container ~= nil and container:IsOpenedBy(player) then
        container:Close(player)
    end
end)

if not G.TheNet:IsDedicated() then
    AddClassPostConstruct("screens/playerhud", function(self)
        local OnControl = self.OnControl

        self.OnControl = function(hud, control, down, ...)
            if control == G.CONTROL_PAUSE and not down and not G.TheInput:ControllerAttached()
                and hud.shown and hud.controls ~= nil and hud.controls.containers ~= nil
            then
                for chest, widget in pairs(hud.controls.containers) do
                    if widget ~= nil and widget.isopen and IsTreasureChest(chest) then
                        if G.TheWorld ~= nil and G.TheWorld.ismastersim then
                            local container = chest.components.container
                            if container ~= nil and container:IsOpenedBy(hud.owner) then
                                container:Close(hud.owner)
                            end
                        else
                            G.SendModRPCToServer(G.GetModRPC(modname, "ttk_close_treasurechest"), chest)
                            chest.replica.container:Close()
                        end
                        return true
                    end
                end
            end

            return OnControl(hud, control, down, ...)
        end
    end)
end
