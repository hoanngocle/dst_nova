-- Adapted from Solo Leveling 2.2.7 / Saikuno.
local function HHDungeonTransitionCleanup(inst)
    inst:RemoveTag("hn_dungeon_transition")
    inst.AnimState:SetMultColour(1, 1, 1, 1)
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:Enable(true)
    end
end

AddStategraphState(
    "wilson",
    State {
        name = "hn_dungeon_migrate",
        tags = {"doing", "busy", "nopredict", "nomorph", "nodangle", "nointerrupt"},
        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst:AddTag("hn_dungeon_transition")
            inst.sg.statemem.mode = data ~= nil and data.mode or nil
            inst.sg.statemem.gate = data ~= nil and data.gate or nil
            inst.sg.statemem.heavy = inst.components.inventory:IsHeavyLifting()
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
            end
            inst.AnimState:PlayAnimation(inst.sg.statemem.heavy and "heavy_item_hat" or "pickup")
        end,
        events = {
            EventHandler("animover", function(inst)
                if not inst.AnimState:AnimDone() or inst.sg.statemem.transition_started then
                    return
                end
                inst.sg.statemem.transition_started = true

                local departfx = SpawnPrefab("spawn_fx_medium_static")
                if departfx ~= nil then
                    departfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
                if inst.components.colourtweener ~= nil then
                    inst.components.colourtweener:StartTween({0, 0, 0, 1}, 13 * FRAMES)
                else
                    inst.AnimState:SetMultColour(0, 0, 0, 1)
                end

                inst.sg.statemem.movetask = inst:DoTaskInTime(13 * FRAMES, function(player)
                    player.sg.statemem.movetask = nil
                    local manager = TheWorld.components.hn_dungeon_manager
                    local moved = false
                    if manager ~= nil then
                        if player.sg.statemem.mode == "enter" then
                            moved = require("hn_dungeon/entry").CanRequest(player, player.sg.statemem.gate, manager, true) and manager:EnterDungeon(player) == true
                        elseif player.sg.statemem.mode == "leave" then
                            moved = manager:LeaveDungeon(player, "dungeon_exit") == true
                            if moved and player.components.hn_dungeon_cooldown ~= nil then
                                player.components.hn_dungeon_cooldown:StartTimer(8 * 60)
                            end
                        end
                    end
                    player.sg.statemem.moved = moved

                    if moved then
                        local arrivefx = SpawnPrefab("spawn_fx_medium_static")
                        if arrivefx ~= nil then
                            arrivefx.entity:SetParent(player.entity)
                        end
                    end
                    player.sg.statemem.fadeintask = player:DoTaskInTime(6 * FRAMES, function(player)
                        player.sg.statemem.fadeintask = nil
                        if player.components.colourtweener ~= nil then
                            player.components.colourtweener:StartTween({1, 1, 1, 1}, 19 * FRAMES)
                        else
                            player.AnimState:SetMultColour(1, 1, 1, 1)
                        end
                        player.sg.statemem.finishtask = player:DoTaskInTime(19 * FRAMES, function(player)
                            player.sg.statemem.finishtask = nil
                            player.sg.statemem.completed = true
                            HHDungeonTransitionCleanup(player)
                            player.sg:GoToState("idle")
                        end)
                    end)
                end)
            end),
        },
        onexit = function(inst)
            for _, taskname in ipairs({"movetask", "fadeintask", "finishtask"}) do
                local task = inst.sg.statemem[taskname]
                if task ~= nil then
                    task:Cancel()
                    inst.sg.statemem[taskname] = nil
                end
            end
            HHDungeonTransitionCleanup(inst)
        end,
    }
)

AddStategraphState(
    "wilson_client",
    State {
        name = "hn_dungeon_migrate",
        tags = {"doing", "busy", "pausepredict", "nomorph", "nodangle"},
        server_states = {"hn_dungeon_migrate"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickup")
        end,
        onupdate = function(inst)
            inst.entity:FlattenMovementPrediction()
        end,
    }
)

