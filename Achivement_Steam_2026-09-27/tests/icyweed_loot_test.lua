package.path = 'Achivement_Steam_2026-09-27/scripts/?.lua;' .. package.path
local file = io.open('Achivement_Steam_2026-09-27/scripts/constants/icyweedloot.lua')
assert(file, 'approved icyweed loot table is missing')
file:close()
local Data = require('constants/icyweedloot')
local Loot = require('functions/icyweedloot')
local groups, total, ids = {}, 0, {}
local forbidden = {ice=true, rocks=true, flint=true, nitre=true, security_pulse_cage=true,
    moonglass_charged=true, moonstorm_static_item=true, gelblob_bottle=true, hh_effect_stone=true,
    nn_magicpaper=true, wb_strengthen_strengthen_protectpaper=true}
for _, row in ipairs(Data.rows) do
    assert(not forbidden[row.prefab] and not row.prefab:match('^trinket'))
    assert(not ids[row.prefab], 'duplicate bonus ID')
    ids[row.prefab] = true
    assert(row.weight > 0 and row.weight == math.floor(row.weight))
    assert(row.min >= 1 and row.max >= row.min and row.max <= 8)
    groups[row.group] = (groups[row.group] or 0) + row.weight
    total = total + row.weight
end
assert(total == 1000 and groups.tutien == 250 and groups.solo == 550 and groups.dst == 200)
local function yes() return true end
local pool = Loot.PreparePool(yes, yes)
local function sequence(values)
    local index = 0
    return function(lo, hi)
        index = index + 1
        local value = assert(values[index], 'unexpected RNG call')
        assert(value >= lo and value <= hi, 'invalid test draw')
        return value
    end
end
-- Each endpoint in the 1..1000 range selects the expected row, inclusive.
local start = 1
for _, row in ipairs(Data.rows) do
    for _, point in ipairs({start, start + row.weight - 1}) do
        for _, amount in ipairs({row.min, row.max}) do
            local draws = {2, point}
            if row.min ~= row.max then draws[#draws+1] = amount end
            draws[#draws+1] = point
            if row.min ~= row.max then draws[#draws+1] = amount end
            local rewards = Loot.Roll(pool, sequence(draws))
            assert(#rewards == 3 and rewards[1].prefab == 'xd_lingshi1' and rewards[1].amount == 2)
            assert(rewards[2].prefab == row.prefab and rewards[2].amount == amount)
            assert(rewards[3].prefab == row.prefab and rewards[3].amount == amount)
        end
    end
    start = start + row.weight
end
local unsupported = Loot.PreparePool(function(id) return id ~= 'hh_essence' end,
    function(id) return id ~= 'xd_lc_hsc_seed' end)
assert(unsupported.total == 1000)
assert(unsupported.rows[1].prefab == 'xd_lingshi1' and unsupported.rows[1].weight == 100)
assert(unsupported.rows[7].prefab == 'xd_lingshi1' and unsupported.rows[7].weight == 200)
assert(unsupported.rows[6].prefab == 'xd_lingshi2' and unsupported.rows[6].weight == 5)
local vanilla = Loot.PreparePool(function(id) return id == 'goldnugget' end, yes)
assert(vanilla.guaranteed.prefab == 'goldnugget' and vanilla.guaranteed.min == 1 and vanilla.guaranteed.max == 2)
assert(vanilla.rows[1].prefab == 'goldnugget' and vanilla.rows[1].max == 2)
-- Persistence is validated and copied, not passed through by reference.
local rewards = Loot.Roll(pool, sequence({4, 250, 1000}))
local saved = {version=1, rewards=rewards}
local loaded = assert(Loot.NormalizeSaved(saved))
assert(loaded[1].amount == 4 and loaded[2].prefab == 'xd_lingshi2' and loaded[3].prefab == 'voidcloth')
loaded[1].amount = 1
assert(rewards[1].amount == 4)
for _, invalid in ipairs({{version=9,rewards=rewards}, {version=1,rewards={}},
    {version=1,rewards={{prefab='axe',amount=1},{prefab='goldnugget',amount=1},{prefab='goldnugget',amount=1}}},
    {version=1,rewards={{prefab='xd_lingshi1',amount=0},{prefab='goldnugget',amount=1},{prefab='goldnugget',amount=1}}},
    {version=1,rewards={{prefab='xd_lingshi1',amount=1.5},{prefab='goldnugget',amount=1},{prefab='goldnugget',amount=1}}}}) do
    assert(Loot.NormalizeSaved(invalid) == nil)
end
-- Fixed seed simulation: bounded rewards and observable economic output.
math.randomseed(4102026)
for _, count in ipairs({100,1000,100000}) do
    local amounts = {}
    for _ = 1, count do
        local rolled = Loot.Roll(pool, math.random)
        assert(#rolled == 3 and rolled[1].amount >= 2 and rolled[1].amount <= 4)
        for _, reward in ipairs(rolled) do
            amounts[reward.prefab] = (amounts[reward.prefab] or 0) + reward.amount
        end
    end
    print('ICYWEED_SIM',count,'ha',amounts.xd_lingshi1,'trung',amounts.xd_lingshi2 or 0,
        'solo',amounts.hh_essence or 0,'huyen_ha',amounts.ttk_huyen_tinh_ha_pham or 0)
    if count == 100000 then
        assert(math.abs(amounts.xd_lingshi1/count - 3.325) < .03)
        assert(math.abs(amounts.hh_essence/count - .6) < .02)
        assert(math.abs(amounts.xd_lingshi2/count - .01) < .002)
    end
end
print('PASS icyweed loot: weights, all RNG boundaries, fallback, save validation and simulation')
