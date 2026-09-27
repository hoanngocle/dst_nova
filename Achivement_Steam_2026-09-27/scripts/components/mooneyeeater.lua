local ediblemooneyes = {
    "redmooneye",
    "bluemooneye",
    "greenmooneye",
    "yellowmooneye",
    "orangemooneye",
    "purplemooneye",
}

local defaulteatencount = { redmooneye = 0, greenmooneye = 0, bluemooneye = 0, yellowmooneye = 0, orangemooneye = 0, purplemooneye = 0, }

local mooneyeeater = Class(function(self, inst)
    self.inst = inst
    self.eatencount = shallowcopy(defaulteatencount)
end)

function mooneyeeater:OnSave()
    local data = { eatencount = self.eatencount, }
    return data
end

function mooneyeeater:OnLoad(data)
    if data then
        self.eatencount = data.eatencount and shallowcopy(data.eatencount) or shallowcopy(defaulteatencount)
        self:ReloadStats()
    end
end

function mooneyeeater:OnEatmooneyefn(prefab, count)
    self.eatencount[prefab] = self.eatencount[prefab] + count
    self["Eat"..prefab.."fn"](self, count)
end

function mooneyeeater:Eatredmooneyefn(count)
    if count <= 0 then return end
    local amount = self.inst.components.health.maxhealth + (1.5 * count)
    chasni_setMaxHealth(self.inst.components.health, amount)
end

function mooneyeeater:Eatbluemooneyefn(count)
    if count <= 0 then return end
    local amount = self.inst.components.hunger.max + (1.5 * count)
    chasni_setMaxHunger(self.inst.components.hunger, amount)
end

function mooneyeeater:Eatpurplemooneyefn(count)
    if count <= 0 then return end
    local amount = self.inst.components.sanity.max + (2 * count)
    chasni_setMaxSanity(self.inst.components.sanity, amount)
end

function mooneyeeater:Eatyellowmooneyefn(count)
    if count <= 0 then return end
    local inc = count
    local healthamount = self.inst.components.health.maxhealth + inc
    chasni_setMaxHealth(self.inst.components.health, healthamount)
    local hungeramount = self.inst.components.hunger.max + inc
    chasni_setMaxHunger(self.inst.components.hunger, hungeramount)
    local sanityamount = self.inst.components.sanity.max + inc
    chasni_setMaxSanity(self.inst.components.sanity, sanityamount)
end

function mooneyeeater:Eatgreenmooneyefn(count)
    if count <= 0 then return end
    local dmg = self.inst.components.combat.externaldamagemultipliers:CalculateModifierFromSource("greenmooneye") + (count * 0.003)
    self.inst.components.combat.externaldamagemultipliers:RemoveModifier("greenmooneye")
    self.inst.components.combat.externaldamagemultipliers:SetModifier("greenmooneye", dmg)
end

function mooneyeeater:Eatorangemooneyefn(count)
    if count <= 0 then return end
    local spd = self.inst.components.locomotor:GetExternalSpeedMultiplier(self.inst, "orangemooneye") + (count * 0.003)
    self.inst.components.locomotor:RemoveExternalSpeedMultiplier(self.inst, "orangemooneye")
    self.inst.components.locomotor:SetExternalSpeedMultiplier(self.inst, "orangemooneye", spd)
end

function mooneyeeater:ReloadStats()
    for _, me in pairs(ediblemooneyes) do
        if self.eatencount[me] then
            self["Eat"..me.."fn"](self, self.eatencount[me])
        end
    end
end

function mooneyeeater:AddStats(gemcount)
    for _, me in pairs(ediblemooneyes) do
        if gemcount[me] then
            self:OnEatmooneyefn(me, gemcount[me])
        end
    end
end

function mooneyeeater:Uneatredmooneyefn(count)
    if count <= 0 then return end
    local amount = self.inst.components.health.maxhealth - (1.5 * count)
    chasni_setMaxHealth(self.inst.components.health, amount)
end

function mooneyeeater:Uneatbluemooneyefn(count)
    if count <= 0 then return end
    local amount = self.inst.components.hunger.max - (1.5 * count)
    chasni_setMaxHunger(self.inst.components.hunger, amount)
end

function mooneyeeater:Uneatpurplemooneyefn(count)
    if count <= 0 then return end
    local amount = self.inst.components.sanity.max - (2 * count)
    chasni_setMaxSanity(self.inst.components.sanity, amount)
end

function mooneyeeater:Uneatyellowmooneyefn(count)
    if count <= 0 then return end
    local dec = count
    local healthamount = self.inst.components.health.maxhealth - dec
    chasni_setMaxHealth(self.inst.components.health, healthamount)
    local hungeramount = self.inst.components.hunger.max - dec
    chasni_setMaxHunger(self.inst.components.hunger, hungeramount)
    local sanityamount = self.inst.components.sanity.max - dec
    chasni_setMaxSanity(self.inst.components.sanity, sanityamount)
end

function mooneyeeater:Uneatgreenmooneyefn(count)
    if count <= 0 then return end
    self.inst.components.combat.externaldamagemultipliers:RemoveModifier("greenmooneye")
end

function mooneyeeater:Uneatorangemooneyefn(count)
    if count <= 0 then return end
    self.inst.components.locomotor:RemoveExternalSpeedMultiplier(self.inst, "orangemooneye")
end

function mooneyeeater:RemoveStats()
    for _, me in pairs(ediblemooneyes) do
        if self.eatencount[me] then
            self["Uneat"..me.."fn"](self, self.eatencount[me])
        end
    end
    self.eatencount = shallowcopy(defaulteatencount)
end

return mooneyeeater