-- Achievement's public extension point for its one authoritative crit roll.
local Combat = require("tbc_combat")
local Provider = Class(function(self, inst)
    self.inst = inst
end)

function Provider:CalculateCrit()
    local stats = Combat.StatsForOwner(self.inst)
    return 1 + stats.crit_effect / 100, stats.crit_rate / 100
end

return Provider
