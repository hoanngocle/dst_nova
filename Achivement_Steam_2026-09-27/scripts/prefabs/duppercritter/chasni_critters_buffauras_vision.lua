local BuffAura = require "prefabs/buffaura_common"

local NIGHTVISION_COLOURCUBES =
{
    day = "images/colour_cubes/quagmire_cc.tex",
    dusk = "images/colour_cubes/quagmire_cc.tex",
    night = "images/colour_cubes/quagmire_cc.tex",
    full_moon = "images/colour_cubes/quagmire_cc.tex",
}

local AMBIENT_COLOURS =
{
    default = { colour = Vector3(255/255, 200/255, 180/255) },
}

local function MakeNightVisionBuff(buffname, ambient_colours, conditionfn)
    local function buff_OnEnabledDirty(inst)
        if ThePlayer and inst.entity:GetParent() == ThePlayer and ThePlayer.components.playervision then
            if inst._enabled:value() then
                ThePlayer.components.playervision:PushForcedNightVision(inst, 1, NIGHTVISION_COLOURCUBES, true, ambient_colours)
            else
                ThePlayer.components.playervision:PopForcedNightVision(inst)
            end
        end
    end

    local function fn()
        local buffdata =
        {
            ONATTACH = function(inst, target)
                local enabled = conditionfn(inst, target)
                if enabled then
                    if target.components.playervision then
                        target.components.playervision:PushForcedNightVision(inst, 1, NIGHTVISION_COLOURCUBES, true, ambient_colours)
                    end
                    inst._enabled:set(enabled)
                end
            end,

            TICK_FN = function(inst, target)
                local enabled = conditionfn(inst, target)
                if enabled and not inst._enabled:value() then
                    if target.components.playervision then
                        target.components.playervision:PushForcedNightVision(inst, 1, NIGHTVISION_COLOURCUBES, true, ambient_colours)
                    end
                    inst._enabled:set(true)
                elseif not enabled and inst._enabled:value() then
                    if target.components.playervision then
                        target.components.playervision:PopForcedNightVision(inst)
                    end
                    inst._enabled:set(false)
                end
            end,

            ONDETACH = function(inst, target)
                if target and target:IsValid() then
                    if target.components.playervision then
                        target.components.playervision:PopForcedNightVision(inst)
                    end
                    inst._enabled:set(false)
                end
                inst:DoTaskInTime(10 * FRAMES, inst.Remove)
            end,
        }

        local inst = BuffAura.persist_fn(buffdata)

        inst._enabled = net_bool(inst.GUID, buffname .. "._enabled", "enableddirty")
        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            inst:ListenForEvent("enableddirty", buff_OnEnabledDirty)
            return inst
        end

        return inst
    end

    return Prefab(buffname, fn)
end

return
MakeNightVisionBuff("chasni_critter_squid_aura_buff", AMBIENT_COLOURS, function(inst, target)
    return not TheWorld:HasTag("cave") and not target:IsOnValidGround()
end),
MakeNightVisionBuff("chasni_critter_driller_aura_buff", AMBIENT_COLOURS, function(inst, target)
    return TheWorld:HasTag("cave")
end)