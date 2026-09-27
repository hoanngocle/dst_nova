local M = {}

function M:IsHHType(value, expected)
    return type(value) == expected
end

function M:HasComponents(inst, name)
    return inst ~= nil and inst.components ~= nil and inst.components[name] ~= nil
end

function M:NotIsDead(inst)
    return inst ~= nil and inst.IsValid ~= nil and inst:IsValid()
        and (inst.components == nil or inst.components.health == nil
            or not inst.components.health:IsDead())
end

function M:HHKillTask(inst, key)
    if inst ~= nil and inst[key] ~= nil then
        inst[key]:Cancel()
        inst[key] = nil
    end
end

function M:HHRemoveFx(inst, key)
    local fx = inst ~= nil and inst[key] or nil
    if fx ~= nil and fx.Remove ~= nil then
        fx:Remove()
        inst[key] = nil
    end
end

function M:HHClientRpc(inst, key, value)
    if inst == nil then return end
    if key == "hh_fast_act" then
        inst._tbc_solo_fast_act = value == true
    elseif key == "hh_atk_speed" then
        local speed = math.max(0, math.min(100, tonumber(value) or 0))
        local combat = inst.components ~= nil and inst.components.combat or nil
        if combat ~= nil and combat.SetAttackPeriod ~= nil
            and type(combat.min_attack_period) == "number" then
            local old = inst._tbc_solo_attack_speed or 0
            local base = combat.min_attack_period * (1 + old / 100)
            combat:SetAttackPeriod(math.max(.1, base / (1 + speed / 100)))
        end
        inst._tbc_solo_attack_speed = speed
        value = speed
    else
        error("tbc_equipment unsupported client value: " .. tostring(key))
    end
    local rpc = CLIENT_MOD_RPC ~= nil and CLIENT_MOD_RPC.ThanKhiTuTien ~= nil
        and CLIENT_MOD_RPC.ThanKhiTuTien.tbc_equipment_client_value or nil
    if rpc ~= nil and SendModRPCToClient ~= nil and inst.userid ~= nil then
        SendModRPCToClient(rpc, inst.userid, key, value)
    end
end

function M:SpawnClientStrFx(inst, value)
    -- The Solo floating-text prefab is outside the equipment dependency set.
    -- These calls are cosmetic; do not abort equipping a functional gem.
    if not self._reported_text_fx then
        print("[ThanKhiTuTien] Solo floating-text FX is unavailable; equipment effects remain active.")
        self._reported_text_fx = true
    end
end

-- Runtime bridges are installed by the owner-effect and RPC tasks. A missing
-- bridge must fail loudly; a visible success with no effect is worse.
for _, name in ipairs({"HandleSuitBuff"}) do
    M[name] = function()
        error("tbc_equipment bridge unavailable: " .. name)
    end
end

return M
