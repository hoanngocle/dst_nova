local ChasniCritChancer = Class(function(self, inst)
    self.inst = inst
    self.crits = {}
end)

function ChasniCritChancer:AddCrit(name, chance, damage, persist)
    self.crits[name] = {
        chance  = chance,
        damage  = damage,
        persist = persist or false
    }
end

function ChasniCritChancer:RemoveCrit(name)
    self.crits[name] = nil
end

----------------------------------------------------------
-- Public
----------------------------------------------------------

function ChasniCritChancer:CalculateCrit()
    if not self.crits or next(self.crits) == nil then
        return 0, 0
    end
    local totaldamage = 0
    local chance = 0
    for _, crit in pairs(self.crits) do
        if crit.damage then
            totaldamage = totaldamage + crit.damage
        end
        if crit.chance then
            chance = 1 - ((1 - chance) * (1 - crit.chance))
        end
    end
    return totaldamage, chance
end

return ChasniCritChancer