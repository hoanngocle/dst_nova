local removed = {
    costs = {
        trinketowner = 15,
        supercritter = 20,
        itemcleaner = 5,
        blueprintextractor = 15,
        itemmerger = 5,
        trinketcraft = 15,
        clustercraft = 20,
        multicraft = 5,
    },
    multi = {
        healthregenup = { cost = 3, multi = 10 },
        hungerrateup = { cost = 2, multi = 10 },
        sanityregenup = { cost = 3, multi = 10 },
        repairitemup = { cost = 25, multi = 100 },
        repairmagiup = { cost = 20, multi = 100 },
        repairfoodup = { cost = 15, multi = 100 },
        krampussackup = { cost = 3, multi = 100 },
    },
    global = {
        eternalicebox = 90,
        easybeef = 40,
        stackinfinite = 100,
        insightinfinite = 70,
    },
}

function removed.isRemoved(name)
    return removed.costs[name] ~= nil or removed.multi[name] ~= nil or removed.global[name] ~= nil
end

function removed.refundMulti(count, cost, multi)
    count = type(count) == "number" and math.max(0, math.floor(count)) or 0
    local full = math.floor(count / multi)
    local remainder = count % multi
    return cost * count + multi * full * (full - 1) / 2 + remainder * full
end

function removed.clearGlobal(data)
    if data then
        for name in pairs(removed.global) do
            data[name] = 0
        end
    end
end

function removed.apply(tuning)
    tuning.CHASNI_CONFIG = tuning.CHASNI_CONFIG or {}
    tuning.CHASNI_CONFIG.HIDEPERK = tuning.CHASNI_CONFIG.HIDEPERK or {}
    for _, group in ipairs({ removed.costs, removed.multi, removed.global }) do
        for name in pairs(group) do
            tuning.CHASNI_CONFIG.HIDEPERK[string.upper(name)] = true
        end
    end
    removed.clearGlobal(tuning.ACH)
end

return removed
