local TechTree = require("techtree")

-- CC : add bonus tech tree for produce perk >> [Perk] Produce ancientstation lunarcraft pearlcraft rabbitkingcraft carpentercraft crittercraft eventcraft carnivalcraft
if not chasni_getperkexcludeconfig("ancientstation", "lunarcraft", "pearlcraft", "rabbitkingcraft", "carpentercraft", "crittercraft", "eventcraft", "carnivalcraft") then
    AddComponentPostInit("builder", function(self)
        local _EvaluateTechTrees = self.EvaluateTechTrees
        function self:EvaluateTechTrees(...)
            _EvaluateTechTrees(self, ...)
            local ancientbonus = self.inst.currentancientstation and self.inst.currentancientstation:value() == 1 and 4 or nil
            if ancientbonus then
                self.accessible_tech_trees["ANCIENT"] = (self.accessible_tech_trees["ANCIENT"] or 0) + ancientbonus
                self.accessible_tech_trees_no_temp["ANCIENT"] = (self.accessible_tech_trees_no_temp["ANCIENT"] or 0) + ancientbonus
            end

            local celestialbonus = self.inst.currentlunarcraft and self.inst.currentlunarcraft:value() == 1 and 4 or nil
            if celestialbonus then
                self.accessible_tech_trees["CELESTIAL"] = (self.accessible_tech_trees["CELESTIAL"] or 0) + celestialbonus
                self.accessible_tech_trees_no_temp["CELESTIAL"] = (self.accessible_tech_trees_no_temp["CELESTIAL"] or 0) + celestialbonus
            end

            local pearlbonus = self.inst.currentpearlcraft and self.inst.currentpearlcraft:value() == 1 and 4 or nil
            if pearlbonus then
                self.accessible_tech_trees["HERMITCRABSHOP"] = (self.accessible_tech_trees["HERMITCRABSHOP"] or 0) + pearlbonus
                self.accessible_tech_trees_no_temp["HERMITCRABSHOP"] = (self.accessible_tech_trees_no_temp["HERMITCRABSHOP"] or 0) + pearlbonus
            end

            local rabbitkingbonus = self.inst.currentrabbitkingcraft and self.inst.currentrabbitkingcraft:value() == 1 and 4 or nil
            if rabbitkingbonus then
                self.accessible_tech_trees["RABBITKINGSHOP"] = (self.accessible_tech_trees["RABBITKINGSHOP"] or 0) + rabbitkingbonus
                self.accessible_tech_trees_no_temp["RABBITKINGSHOP"] = (self.accessible_tech_trees_no_temp["RABBITKINGSHOP"] or 0) + rabbitkingbonus
            end

            local carpentrybonus = self.inst.currentcarpentercraft and self.inst.currentcarpentercraft:value() == 1 and 4 or nil
            if carpentrybonus then
                self.accessible_tech_trees["CARPENTRY"] = (self.accessible_tech_trees["CARPENTRY"] or 0) + carpentrybonus
                self.accessible_tech_trees_no_temp["CARPENTRY"] = (self.accessible_tech_trees_no_temp["CARPENTRY"] or 0) + carpentrybonus
            end

            local petcritterbonus = self.inst.currentcrittercraft and self.inst.currentcrittercraft:value() == 1 and 4 or nil
            if petcritterbonus then
                self.accessible_tech_trees["ORPHANAGE"] = (self.accessible_tech_trees["ORPHANAGE"] or 0) + petcritterbonus
                self.accessible_tech_trees_no_temp["ORPHANAGE"] = (self.accessible_tech_trees_no_temp["ORPHANAGE"] or 0) + petcritterbonus
            end

            local eventbonus = self.inst.currenteventcraft and self.inst.currenteventcraft:value() == 1 and 4 or nil
            if eventbonus then
                for i, tech in ipairs(TechTree.AVAILABLE_TECH) do
                    if string.sub(tech, -8) == "OFFERING" then
                        self.accessible_tech_trees[tech] = (self.accessible_tech_trees[tech] or 0) + eventbonus
                        self.accessible_tech_trees_no_temp[tech] = (self.accessible_tech_trees_no_temp[tech] or 0) + eventbonus
                    end
                end
            end

            local carnivalbonus = self.inst.currentcarnivalcraft and self.inst.currentcarnivalcraft:value() == 1 and 4 or nil
            if carnivalbonus then
                self.accessible_tech_trees["CARNIVAL_PRIZESHOP"] = (self.accessible_tech_trees["CARNIVAL_PRIZESHOP"] or 0) + carnivalbonus
                self.accessible_tech_trees_no_temp["CARNIVAL_PRIZESHOP"] = (self.accessible_tech_trees_no_temp["CARNIVAL_PRIZESHOP"] or 0) + carnivalbonus
                self.accessible_tech_trees["CARNIVAL_HOSTSHOP"] = (self.accessible_tech_trees["CARNIVAL_HOSTSHOP"] or 0) + carnivalbonus
                self.accessible_tech_trees_no_temp["CARNIVAL_HOSTSHOP"] = (self.accessible_tech_trees_no_temp["CARNIVAL_HOSTSHOP"] or 0) + carnivalbonus
            end

            self.inst.replica.builder:SetTechTrees(self.accessible_tech_trees)
            self.inst:PushEvent("techtreechange", { level = self.accessible_tech_trees })
        end
    end)
end
