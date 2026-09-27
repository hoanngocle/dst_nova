local AURA_TICK = 0.5

local BuffAura = Class(function(self, inst)
    self.inst = inst
    self.auras = {}

    self.onstartfn = nil
    self.onstopfn = nil
end)

----------------------------------------------------------
-- Aura Management
----------------------------------------------------------

function BuffAura:AddAura(name, buffname, radius, findfn)
    self.auras[name] =
    {
        buffname = buffname,
        radius = radius or 4,
        findfn = findfn,
    }
end

function BuffAura:RemoveAura(name)
    self.auras[name] = nil
end

function BuffAura:GetAura(name)
    return self.auras[name]
end

function BuffAura:SetAuraRadius(name, radius)
    local aura = self.auras[name]
    if aura then
        aura.radius = radius
    end
end

function BuffAura:SetAuraFindFn(name, findfn)
    local aura = self.auras[name]
    if aura then
        aura.findfn = findfn
    end
end

----------------------------------------------------------
-- Callbacks
----------------------------------------------------------

function BuffAura:SetOnStartFn(fn)
    self.onstartfn = fn
end

function BuffAura:SetOnStopFn(fn)
    self.onstopfn = fn
end

----------------------------------------------------------
-- Aura Control
----------------------------------------------------------

function BuffAura:StartAura()
    if self.aura_task == nil then
        self.aura_task = self.inst:DoPeriodicTask(AURA_TICK, function()
            self:GiveAuras()
        end)
    end
    if self.onstartfn then
        self.onstartfn(self.inst)
    end
end

function BuffAura:StopAura()
    if self.aura_task then
        self.aura_task:Cancel()
        self.aura_task = nil
    end
    if self.onstopfn then
        self.onstopfn(self.inst)
    end
end

----------------------------------------------------------
-- Internal
----------------------------------------------------------

local function FindTargets(inst, aura)
    local x, y, z = inst.Transform:GetWorldPosition()
    local radius = FunctionOrValue(aura.radius, inst) or 0

    if aura.findfn then
        return aura.findfn(x, y, z, radius, inst)
    end

    return FindPlayersInRange(x, y, z, radius, true)
end

function BuffAura:GiveAuras()
    for _, aura in pairs(self.auras) do
        local targets = FindTargets(self.inst, aura)

        for _, target in ipairs(targets) do
            target:AddDebuff(aura.buffname, aura.buffname, { source = self.inst })
        end
    end
end

return BuffAura