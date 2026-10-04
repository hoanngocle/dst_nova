GLOBAL.setmetatable(env,{__index=function(_,k) return GLOBAL.rawget(GLOBAL,k) end})
local TutienHealthReload = require "functions/tutienhealthreload"

-- CC : health sanity hunger percentage save and load >> [Level] Level Attributes Stats
AddComponentPostInit("health", function(Health)
    local oldOnSave = Health.OnSave
    function Health:OnSave(...)
        local retval = oldOnSave(self, ...)
        if not retval then
            retval = {}
        end
        retval.chasnipercentages = self:GetPercent() ~= 1 and self:GetPercent() or nil
        return retval
    end
    local oldOnLoad = Health.OnLoad
    function Health:OnLoad(data, ...)
        local retval = oldOnLoad(self, data, ...)
        self.inst:DoTaskInTime(0, function()
            if self.inst.components.levelsystem and data and data.chasnipercentages then
                self.inst.components.levelsystem:loadHealth(self.inst, data.chasnipercentages)
            end
        end)
        if self.inst:HasTag("player") then
            self.inst:DoTaskInTime(2, function()
                if self.inst:IsValid() then
                    TutienHealthReload.Restore(self.inst, data and data.health,
                        self.inst._chasni_loaded_hunger, self.inst._chasni_loaded_sanity)
                    self.inst._chasni_loaded_hunger = nil
                    self.inst._chasni_loaded_sanity = nil
                end
            end)
        end
        return retval
    end
end)
AddComponentPostInit("hunger", function(Hunger)
    local oldOnSave = Hunger.OnSave
    function Hunger:OnSave(...)
        local retval = oldOnSave(self, ...)
        if not retval then
            retval = {}
        end
        retval.chasnipercentages = self:GetPercent() ~= 1 and self:GetPercent() or nil
        return retval
    end
    local oldOnLoad = Hunger.OnLoad
    function Hunger:OnLoad(data, ...)
        if self.inst:HasTag("player") then
            self.inst._chasni_loaded_hunger = data and data.hunger
        end
        local retval = oldOnLoad(self, data, ...)
        self.inst:DoTaskInTime(0, function()
            if self.inst.components.levelsystem and data and data.chasnipercentages then
                self.inst.components.levelsystem:loadHunger(self.inst, data.chasnipercentages)
            end
        end)
        return retval
    end
end)
AddComponentPostInit("sanity", function(Sanity)
    local oldOnSave = Sanity.OnSave
    function Sanity:OnSave(...)
        local retval = oldOnSave(self, ...)
        if self.inst.components.levelsystem then
            if not retval then
                retval = {}
            end

            retval.chasnipercentages = self:GetPercent() ~= 1 and self:GetPercent() or nil
        end
        return retval
    end
    local oldOnLoad = Sanity.OnLoad
    function Sanity:OnLoad(data, ...)
        if self.inst:HasTag("player") then
            self.inst._chasni_loaded_sanity = data and data.current
        end
        local retval = oldOnLoad(self, data, ...)
        self.inst:DoTaskInTime(0, function()
            if self.inst.components.levelsystem and data and data.chasnipercentages then
                self.inst.components.levelsystem:loadSanity(self.inst, data.chasnipercentages)
            end
        end)
        return retval
    end
end)

-- CC : add xp to Tending Farm >> [LevelSystem]
AddComponentPostInit("farmplanttendable", function(self)
    local _TendTo = self.TendTo
    self.TendTo = function(_self, doer, ...)
        if _self.tendable then
            if doer and doer.components.levelsystem then
                if _G.PLANTXP == true then
                    local xpmult = 6
                    local trinket = chasni_getequippedtrinket(planter)
                    if trinket and trinket.prefab == "trinket_chasni_11" then
                        local stacksize = chasni_gettrinketpoint(trinket,  1, 20)
                        xpmult = xpmult + stacksize
                    end

                    if doer.prefab == "wormwood" then
                        xpmult = xpmult * 5
                    end
                    doer.components.levelsystem:xpDoDelta(xpmult, doer, false, true)
                end
            end
        end
        return _TendTo(_self, doer, ...)
    end
end)
