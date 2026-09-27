local M = {}

local function Number(value)
    return tonumber(value) or 0
end

local function Clamp(value, low, high)
    return math.max(low, math.min(high, Number(value)))
end

-- Solo: a critical hit is x(2 + criticalHitEffect/100); armor pierce is
-- calculated from normal damage before the critical multiplier and caps at 40%.
M.BASE = { crit_rate = 10, crit_effect = 0, pierce = 10 }

function M.Stats(base, bonus)
    base = base or M.BASE
    bonus = bonus or {}
    return {
        crit_rate = Clamp(Number(base.crit_rate) + Number(bonus.crit_rate), 0, 100),
        crit_effect = math.max(0, Number(base.crit_effect) + Number(bonus.crit_effect)),
        pierce = Clamp(Number(base.pierce) + Number(bonus.pierce), 0, 40),
    }
end

function M.RollCrit(damage, stats, rng)
    rng = rng or math.random
    if Number(damage) <= 0 or rng() >= stats.crit_rate / 100 then
        return damage, false
    end
    return damage * (2 + stats.crit_effect / 100), true
end

function M.PierceDamage(damage, stats)
    return math.max(0, Number(damage)) * stats.pierce / 100
end

return M
