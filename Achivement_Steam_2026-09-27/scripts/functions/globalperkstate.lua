local removed = require "constants/removedperks"
local State = {}

function State.Normalize(value)
    if value == true or value == 1 then return 1 end
    if value == -1 then return -1 end
    if value == false or value == 0 then return 0 end
end

function State.Initialize()
    TUNING.ACH = TUNING.ACH or { chasni_ganteng = 0 }
    for name, perk in pairs(perk_lists) do
        if perk.global and State.Normalize(TUNING.ACH[name]) == nil then
            TUNING.ACH[name] = 0
        end
    end
    removed.clearGlobal(TUNING.ACH)
end

function State.SaveLegacy()
    State.Initialize()
    TheSim:SetPersistentString("chasni_perk_global.json", json.encode(TUNING.ACH), false)
end

function State.Set(name, value)
    State.Initialize()
    local component = TheWorld and TheWorld.components and TheWorld.components.chasni_globalperks
    if component then
        component:Set(name, value)
    else
        TUNING.ACH[name] = value
        State.SaveLegacy()
    end
end

return State
