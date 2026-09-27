local ProxCheck = Class(function(self, inst)
    self.inst = inst
    self.range = 2
    self.checkinterval = .2
    self.proxfn = nil
    self.testfn = nil
    self.enabled = false
    self.task = nil

    self:StartChecking()
end)

local function DoTest(inst)
    local c = inst.components.proxcheck
    if c.enabled and not inst:HasTag("INLIMBO") then
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z, c.range, nil, {"INLIMBO", "shadowcreature"}, {"animal", "character", "player", "locomotor"})

        for i = #ents, 1, -1 do
            if ents[i] == inst or (c.testfn and not c.testfn(ents[i])) then
                table.remove(ents, i)
            end
        end

        if #ents > 0 then
            if c.proxfn then
                for i, ent in ipairs(ents)do
                    c.proxfn(inst, ent)
                end
            end
        end
    end
end

function ProxCheck:OnSave()
    local data = { enabled = self.enabled }
    return data
end

function ProxCheck:OnLoad(data)
    self.enabled = data.enabled or false
end

function ProxCheck:SetEnabled(enabled)
    self.enabled = enabled
end

function ProxCheck:forcetest()
    DoTest(self.inst)
end

function ProxCheck:StartChecking()
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
    self.task = self.inst:DoPeriodicTask(self.checkinterval, DoTest)
end

function ProxCheck:OnEntitySleep()
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
end

function ProxCheck:OnEntityWake()
    self:StartChecking()
end

function ProxCheck:OnRemoveEntity()
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
end

return ProxCheck
