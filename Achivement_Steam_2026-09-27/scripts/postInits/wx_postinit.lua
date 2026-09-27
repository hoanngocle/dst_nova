local UIAnim = require "widgets/uianim"

-- CC : 24 max charge module >> [Reward] expertwx1
if not chasni_getperkexcludeconfig("expertwx1") then
    local START_MAX_CIRCUIT_SLOTS = 8
    local NEW_MAX_CIRCUIT_SLOTS = 12
    AddClassPostConstruct("widgets/upgrademodulesdisplay",function(self, ...)
        for v = 0, 3 do
            for i = START_MAX_CIRCUIT_SLOTS, NEW_MAX_CIRCUIT_SLOTS do
                local chip_object = self.module_bars[v]:AddChild(UIAnim())
                chip_object:GetAnimState():SetBank("status_wx")
                chip_object:GetAnimState():SetBuild("status_wx")

                chip_object:GetAnimState():Hide("plug_on")
                chip_object:GetAnimState():Hide("glow")
                chip_object._power_hidden = true

                chip_object:Hide()

                chip_object.cooldown = chip_object:AddChild(UIAnim())
                chip_object.cooldown:GetAnimState():SetBank("status_wx")
                chip_object.cooldown:GetAnimState():SetBuild("status_wx")
                chip_object.cooldown:GetAnimState():SetMultColour(0.4, 0.4, 0.4, 0.4)

                table.insert(self.chip_objectpools[v], chip_object)
            end

            self.chip_slotsinuse[v] = 0
            self.chip_poolindexes[v] = 1
        end

        local old_UpdateMaxEnergy = self.UpdateMaxEnergy
        function self:UpdateMaxEnergy(new_level, old_level, ...)
            old_UpdateMaxEnergy(self, new_level, old_level, ...)
            if self.owner.currentexpertwx1:value() == 1 then
                self.battery_frame:GetAnimState():SetBank("chasni_status_wx")
                self.battery_frame:GetAnimState():SetBuild("chasni_status_wx")
                self.energy_backing:GetAnimState():SetBank("chasni_status_wx")
                self.energy_backing:GetAnimState():SetBuild("chasni_status_wx")
                self.energy_blinking:GetAnimState():SetBank("chasni_status_wx")
                self.energy_blinking:GetAnimState():SetBuild("chasni_status_wx")
                self.anim:GetAnimState():SetBank("chasni_status_wx")
                self.anim:GetAnimState():SetBuild("chasni_status_wx")
                self.energy_nightmare:SetPosition(0, 54)
                self.energy_nightmare:SetScale(1, 2)

                for v = 0, 3 do
                    self.module_bars[v]:GetAnimState():SetBank("chasni_status_wx")
                    self.module_bars[v]:GetAnimState():SetBuild("chasni_status_wx")
                    self.module_bars[v]:GetAnimState():Hide("frame_a")
                    self.module_bars[v]:GetAnimState():Hide("frame_b")
                    self.module_bars[v]:GetAnimState():Hide("frame_c")
                    self.module_bars[v]:GetAnimState():Hide("frame_d")
                    if v == 3  then
                        self.module_bars[v]:GetAnimState():Show("frame_a")
                        self.module_bars[v]:GetAnimState():Show("frame_b")
                        self.module_bars[v]:GetAnimState():Show("frame_c")
                        self.module_bars[v]:GetAnimState():Show("frame_d")
                    end
                    self.module_bars[v]:MoveToBack()
                end
            else
                self.battery_frame:GetAnimState():SetBank("status_wx")
                self.battery_frame:GetAnimState():SetBuild("status_wx")
                self.energy_backing:GetAnimState():SetBank("status_wx")
                self.energy_backing:GetAnimState():SetBuild("status_wx")
                self.energy_blinking:GetAnimState():SetBank("status_wx")
                self.energy_blinking:GetAnimState():SetBuild("status_wx")
                self.anim:GetAnimState():SetBank("status_wx")
                self.anim:GetAnimState():SetBuild("status_wx")
                for v = 0, 3 do
                    self.module_bars[v]:GetAnimState():SetBank("status_wx")
                    self.module_bars[v]:GetAnimState():SetBuild("status_wx")
                end
            end
        end

        local old_UpdateEnergyLevel = self.UpdateEnergyLevel
        function self:UpdateEnergyLevel(new_level, old_level, ...)
            old_UpdateEnergyLevel(self, new_level, old_level, ...)
            for i = 1, self.max_energy do
                local index = 97 + NEW_MAX_CIRCUIT_SLOTS - i
                local greenslot = "slots_green_"..string.char(index)
                if i > new_level then
                    self.anim:GetAnimState():Hide(greenslot)
                else
                    self.anim:GetAnimState():Show(greenslot)
                end

                local yellowslot = "slots_yellow_"..string.char(index)
                if i == new_level + 1 then
                    self.energy_blinking:GetAnimState():Show(yellowslot)
                else
                    self.energy_blinking:GetAnimState():Hide(yellowslot)
                end
            end
        end

        local old_UpdateSlotCount = self.UpdateSlotCount
        function self:UpdateSlotCount(new_level, old_level, ...)
            old_UpdateSlotCount(self, new_level, old_level, ...)
        end
    end)

    AddClassPostConstruct("widgets/secondarystatusdisplays",function(self, ...)

        local old_ShowModuleOwnerDisplay = self.ShowModuleOwnerDisplay
        function self:ShowModuleOwnerDisplay(...)
            self:UpdateModuleOwnerDisplayPosition()
            return old_ShowModuleOwnerDisplay(self, ...)
        end
        local old_UpdateModuleOwnerDisplayPosition = self.UpdateModuleOwnerDisplayPosition
        function self:UpdateModuleOwnerDisplayPosition(...)
            if self.owner.currentexpertwx1:value() == 1 then
                self.inst:DoTaskInTime(0.5, function()
                    self.upgrademodulesdisplay:SetPosition(self.column1, -250)
                end)
            end
            return old_UpdateModuleOwnerDisplayPosition(self, ...)
        end
    end)

    -- CC : force MAX_CIRCUIT_SLOTS to 12 because fucking upgrademodulesdisplay_inspecting ctor initiate everything at once!!???
    AddClassPostConstruct("screens/playerhud",function(self, ...)
        local old_ShowUpgradeModuleWidget = self.ShowUpgradeModuleWidget
        function self:ShowUpgradeModuleWidget(...)
            local original_MAX_CIRCUIT_SLOTS = GLOBAL.MAX_CIRCUIT_SLOTS
            GLOBAL.MAX_CIRCUIT_SLOTS = 12
            old_ShowUpgradeModuleWidget(self, ...)
            GLOBAL.MAX_CIRCUIT_SLOTS = original_MAX_CIRCUIT_SLOTS
        end
    end)

    AddClassPostConstruct("widgets/upgrademodulesdisplay_inspecting",function(self, owner, controls, ...)
        if self.owner.currentexpertwx1:value() == 1 then
            self.bg:GetAnimState():SetBank("chasni_status_wx_chest")
            self.bg:GetAnimState():SetBuild("chasni_status_wx_chest")
            self.bg:GetAnimState():Show("shadow")
            self.bg:GetAnimState():Hide("frame_5")
            self.bg:GetAnimState():PlayAnimation("xxx")
            self.bg_bars:GetAnimState():SetBank("chasni_status_wx_chest")
            self.bg_bars:GetAnimState():SetBuild("chasni_status_wx_chest")
            self.bg_bars:GetAnimState():Show("bars")
            self.bg_bars:GetAnimState():Hide("bg")
            self.bg_bars:GetAnimState():Hide("frame_5")
            self.plugs:GetAnimState():SetBank("chasni_status_wx_chest")
            self.plugs:GetAnimState():SetBuild("chasni_status_wx_chest")
            self.energy_backing:GetAnimState():SetBank("chasni_status_wx_chest")
            self.energy_backing:GetAnimState():SetBuild("chasni_status_wx_chest")
            self.energy_blinking:GetAnimState():SetBank("chasni_status_wx_chest")
            self.energy_blinking:GetAnimState():SetBuild("chasni_status_wx_chest")
            self.anim:GetAnimState():SetBank("chasni_status_wx_chest")
            self.anim:GetAnimState():SetBuild("chasni_status_wx_chest")
            self.shadow_slot:SetPosition(-100, 270, 0)
            self.energy_nightmare:SetPosition(190, -55)
            self.energy_nightmare:SetScale(1, 1 * 2.1)
            self.bg:MoveToBack()
            self.bg_bars:MoveToBack()
            self.plugs:MoveToFront()
            self.energy_backing:MoveToFront()
            self.energy_blinking:MoveToFront()
            self.anim:MoveToFront()
        else
            self.bg:GetAnimState():SetBank("status_wx_chest")
            self.bg:GetAnimState():SetBuild("status_wx_chest")
            self.bg_bars:GetAnimState():SetBank("status_wx_chest")
            self.bg_bars:GetAnimState():SetBuild("status_wx_chest")
            self.energy_backing:GetAnimState():SetBank("status_wx_chest")
            self.energy_backing:GetAnimState():SetBuild("status_wx_chest")
            self.energy_blinking:GetAnimState():SetBank("status_wx_chest")
            self.energy_blinking:GetAnimState():SetBuild("status_wx_chest")
            self.energy_backing:MoveToFront()
            self.energy_blinking:MoveToFront()
            self.anim:MoveToFront()
        end

        local old_UpdateEnergyLevel = self.UpdateEnergyLevel
        function self:UpdateEnergyLevel(new_level, old_level, ...)
            old_UpdateEnergyLevel(self, new_level, old_level, ...)
            for i = 1, self.max_energy do
                local index = 97 + NEW_MAX_CIRCUIT_SLOTS - i
                local greenslot = "slots_green_"..string.char(index)
                local alphaslot = "plug_alpha_off_"..string.char(index)
                local betaslot = "plug_beta_off_"..string.char(index)
                local gammaslot = "plug_gamma_off_"..string.char(index)
                if i > new_level then
                    self.anim:GetAnimState():Hide(greenslot)
                    self.plugs:GetAnimState():Show(alphaslot)
                    self.plugs:GetAnimState():Show(betaslot)
                    self.plugs:GetAnimState():Show(gammaslot)
                else
                    self.anim:GetAnimState():Show(greenslot)
                    self.plugs:GetAnimState():Hide(alphaslot)
                    self.plugs:GetAnimState():Hide(betaslot)
                    self.plugs:GetAnimState():Hide(gammaslot)
                end

                local yellowslot = "slots_yellow_"..string.char(index)
                if i == new_level + 1 then
                    self.energy_blinking:GetAnimState():Show(yellowslot)
                else
                    self.energy_blinking:GetAnimState():Hide(yellowslot)
                end
            end
        end

        if self.owner.wx78_classified then
            self:UpdateEnergyLevel(self.owner.wx78_classified.currentenergylevel:value(), 0, true)
        end
    end)

    TUNING.WX78_MOVESPEED_CHIPBOOSTS = {0.00, 0.25, 0.40, 0.50, 0.60, 0.70, 0.85, 1, 1, 1.25, 1.5, 1.75, 2}

    AddPrefabPostInit("wx78_classified",function(inst)
        for i, name in pairs(CIRCUIT_BARS_LOOKUP) do
            for j = START_MAX_CIRCUIT_SLOTS, NEW_MAX_CIRCUIT_SLOTS do
                inst._activatedmods[i][j] = false
                inst.upgrademodulebars[i][j] = net_smallbyte(inst.GUID, "wx78.upgrademodulebars"..i.."mods"..j, "upgrademoduleslistdirty")
            end
        end
    end)

    AddComponentPostInit("upgrademoduleowner", function(self)
        local old_SetMaxCharge = self.SetMaxCharge
        function self:SetMaxCharge(max_charge, ...)
            if self.inst.components.allachivcoin and self.inst.components.allachivcoin.expertwx1 and max_charge ~= NEW_MAX_CIRCUIT_SLOTS then
                self.inst._chasni_originalmaxchargelevel = max_charge
                return
            end
            return old_SetMaxCharge(self, max_charge, ...)
        end
    end)

    if TheNet:GetIsServer() then
        AddPrefabPostInit("wx78",function(inst)
            local old_GetModulesData = inst.GetModulesData

            local function _GetModulesData(_inst, ...)
                local data = old_GetModulesData(_inst, ...)
                local newdata = {}

                for bartype, modules in pairs(data) do
                    newdata[bartype] = {}

                    for i, v in ipairs(modules) do
                        table.insert(newdata[bartype], v)
                    end

                    while #newdata[bartype] < NEW_MAX_CIRCUIT_SLOTS do
                        table.insert(newdata[bartype], 0)
                    end
                end

                return newdata
            end
            inst.GetModulesData = _GetModulesData
        end)
    end
end

-- CC : remove module didnt reduce finiteuses >> [Reward] expertwx2
if not chasni_getperkexcludeconfig("expertwx2") then
    if TheNet:GetIsServer() then
        AddPrefabPostInit("wx78",function(inst)
            inst:DoTaskInTime(.1,function()
                local old_OnUpgradeModuleRemoved = inst.components.upgrademoduleowner.onmoduleremoved
                local function _OnUpgradeModuleRemoved(_inst, moduleent)
                    local notrepaired = true
                    if _inst.components.allachivcoin.expertwx2 and (moduleent.components.finiteuses == nil or moduleent.components.finiteuses:GetUses() == 1) then
                        notrepaired = false
                        moduleent.components.finiteuses:Repair(1)
                    end
                    old_OnUpgradeModuleRemoved(_inst, moduleent)
                    if notrepaired then
                        _inst:DoTaskInTime(.1,function()
                            if _inst.components.allachivcoin.expertwx2 then moduleent.components.finiteuses:Repair(1) end
                        end)
                    end
                end
                inst.components.upgrademoduleowner.onmoduleremoved = _OnUpgradeModuleRemoved
            end)
        end)
    end
end
