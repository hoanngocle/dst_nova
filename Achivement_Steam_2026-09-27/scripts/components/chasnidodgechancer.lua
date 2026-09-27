local ChasniDodgeChancer = Class(function(self, inst)
    self.inst = inst
    self.dodges = {}
end)

function ChasniDodgeChancer:AddDodge(name, chance, persist)
    self.dodges[name] = {
        chance  = chance,
        persist = persist or false
    }
end

function ChasniDodgeChancer:RemoveDodge(name)
    self.dodges[name] = nil
end

----------------------------------------------------------
-- Public
----------------------------------------------------------

function ChasniDodgeChancer:CalculateDodge()
    if not self.dodges or next(self.dodges) == nil then
        return 0
    end
    local chance = 0
    for _, dodge in pairs(self.dodges) do
        if dodge.chance then
            chance = 1 - ((1 - chance) * (1 - dodge.chance))
        end
    end
    return chance
end

return ChasniDodgeChancer