local States = {}
local Router = require "nyx/input"

local function ServerState()
    return State{
        name = "nyx_skill_cast",
        tags = {"doing", "busy", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
            inst:PerformBufferedAction()
            local fox = inst.components.nyx_blink
            if inst.sg.currentstate.name == "nyx_skill_cast"
                and fox ~= nil and fox.IsActive ~= nil and fox:IsActive() then
                inst.sg:SetTimeout(0.5)
            elseif inst.sg.currentstate.name == "nyx_skill_cast" then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            local fox = inst.components.nyx_blink
            if fox ~= nil and fox.IsActive ~= nil and fox:IsActive() then
                fox:Stop("state_timeout")
            end
            if inst.sg.currentstate.name == "nyx_skill_cast" then
                inst.sg:GoToState("idle")
            end
        end,

        onexit = function(inst)
            local fox = inst.components.nyx_blink
            if fox ~= nil and fox.IsActive ~= nil and fox:IsActive() then
                fox:Stop("state_interrupted")
            end
        end,
    }
end

local function ClientState()
    return State{
        name = "nyx_skill_cast",
        tags = {"doing", "busy", "canrotate"},
        server_states = {"nyx_skill_cast"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk_lag", false)
            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(3)
        end,

        onupdate = function(inst)
            if inst.sg:ServerStateMatches() then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    }
end

local function WrapCastAOE(sg)
    local handler = sg.actionhandlers[ACTIONS.CASTAOE]
    if handler == nil or handler._nyx_skillpanel_wrapped then return end
    local original = handler.deststate
    handler.deststate = function(inst, action)
        if Router.CanEnterNativeCast(inst, action) then
            if action.invobject._nyx_selected_skill == 'bean_soldiers' then
                return 'xd_wmz_sdcb'
            end
            return "nyx_skill_cast"
        end
        if type(original) == "function" then
            return original(inst, action)
        end
        return original
    end
    handler._nyx_skillpanel_wrapped = true
end

function States.Install(deps)
    deps.add_state("wilson", ServerState())
    deps.add_state("wilson_client", ClientState())
    deps.add_postinit("wilson", WrapCastAOE)
    deps.add_postinit("wilson_client", WrapCastAOE)
    deps.add_action_handler("wilson",
        ActionHandler(ACTIONS.NYX_BLINK, "nyx_skill_cast"))
    deps.add_action_handler("wilson_client",
        ActionHandler(ACTIONS.NYX_BLINK, "nyx_skill_cast"))
end

return States
