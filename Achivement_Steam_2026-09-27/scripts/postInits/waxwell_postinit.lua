-- CC : setItems Spellbook changes || adding new spell >> [Reward] expertwaxwell4
if not chasni_getperkexcludeconfig("expertwaxwell4") then
    local SHADOW_HEAL_DRB = -36 -- 5% of 720
    local SHADOW_LIGHT_DRB = -72 -- 10% of 720
    local SHADOW_INVULNERABILITY_DRB = -108 -- 15% of 720
    local SHADOW_ACHIEVEMENT_DRB = -180 -- 25% of 720
    local function ShadowHealSpellFn(inst, doer)
        if inst.components.fueled:IsEmpty() then
            return false, "NO_FUEL"
        elseif doer.components.health and inst.components.fueled and doer.components.sanity then
            local heal = doer.components.health:GetMaxWithPenalty() - doer.components.health.currenthealth
            if heal > doer.components.sanity.current then
                chasni_retalk(doer, "ANNOUNCE_CHASNI_NOT_ENOUGH_SANITY")
                return false, "NOT_ENOUGH_SANITY"
            end
            doer.components.health:DoDelta(heal)
            doer.components.sanity:DoDelta(-heal)
            inst.components.fueled:DoDelta(SHADOW_HEAL_DRB, doer)
            return true
        end

        return false
    end
    local function ShadowLightSpellFn(inst, doer)
        if inst.components.fueled:IsEmpty() then
            return false, "NO_FUEL"
        end
        local light = SpawnPrefab("shadowwisp")
        local pos = Vector3(inst.Transform:GetWorldPosition())
        light.Transform:SetPosition(pos:Get())
        doer.components.leader:AddFollower(light)
        inst.components.fueled:DoDelta(SHADOW_LIGHT_DRB, doer)
        return true
    end
    local function ShadowInvulnerableSpellFn(inst, doer, pos)
        if inst.components.fueled:IsEmpty() then
            return false, "NO_FUEL"
        end
        local realm = SpawnPrefab("shadowrealm")
        realm.Transform:SetPosition(pos:Get())
        inst.components.fueled:DoDelta(SHADOW_INVULNERABILITY_DRB, doer)
        return true
    end
    local function ShadowAchievistSpellFn(inst, doer, pos)
        if inst.components.fueled:IsEmpty() then
            return false, "NO_FUEL"
        end
        local tottem = SpawnPrefab("shadowtottem")
        tottem.Transform:SetPosition(pos:Get())
        inst.components.fueled:DoDelta(SHADOW_ACHIEVEMENT_DRB, doer)
        return true
    end

    local function has_item_with_label(items, label)
        for _, item in ipairs(items) do
            if item.label == label then
                return true
            end
        end
        return false
    end

    local EXPERT_WAXWELL4_SPELL =
    {
        {
            label = STRINGS.WAXWELL_SPELL_HEAL,
            onselect = function(inst)
                inst.components.spellbook:SetSpellName(STRINGS.WAXWELL_SPELL_HEAL)
                inst.components.aoetargeting:SetShouldRepeatCastFn(nil)
                if TheWorld.ismastersim then
                    inst.components.spellbook:SetSpellFn(ShadowHealSpellFn)
                end
            end,
            execute = chasni_StartInstantCasting,
            atlas = "images/inventoryimages/chasni_spell_icons.xml",
            normal = "shadow_heal.tex",
            widget_scale = .6,
            hit_radius = 50,
        },
        {
            label = STRINGS.WAXWELL_SPELL_LIGHT,
            onselect = function(inst)
                inst.components.spellbook:SetSpellName(STRINGS.WAXWELL_SPELL_LIGHT)
                inst.components.aoetargeting:SetShouldRepeatCastFn(nil)
                if TheWorld.ismastersim then
                    inst.components.spellbook:SetSpellFn(ShadowLightSpellFn)
                end
            end,
            execute = chasni_StartInstantCasting,
            atlas = "images/inventoryimages/chasni_spell_icons.xml",
            normal = "shadow_wisp.tex",
            widget_scale = .6,
            hit_radius = 50,
        },
        {
            label = STRINGS.WAXWELL_SPELL_INVULNERABILITY,
            onselect = function(inst)
                inst.components.spellbook:SetSpellName(STRINGS.WAXWELL_SPELL_INVULNERABILITY)
                inst.components.aoetargeting:SetDeployRadius(5)
                inst.components.aoetargeting:SetShouldRepeatCastFn(nil)
                inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoe_1_6"
                inst.components.aoetargeting.reticule.pingprefab = "reticuleaoeping_1_6"
                if TheWorld.ismastersim then
                    inst.components.aoetargeting:SetTargetFX("reticuleaoesummontarget_1")
                    inst.components.aoespell:SetSpellFn(ShadowInvulnerableSpellFn)
                    inst.components.spellbook:SetSpellFn(nil)
                end
            end,
            execute = chasni_StartAOETargeting,
            atlas = "images/inventoryimages/chasni_spell_icons.xml",
            normal = "shadow_invulnerability.tex",
            widget_scale = .6,
            hit_radius = 50,
        },
        {
            label = STRINGS.WAXWELL_SPELL_ACHIEVEMENT,
            onselect = function(inst)
                inst.components.spellbook:SetSpellName(STRINGS.WAXWELL_SPELL_ACHIEVEMENT)
                inst.components.aoetargeting:SetDeployRadius(5)
                inst.components.aoetargeting:SetShouldRepeatCastFn(nil)
                inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoe_1_6"
                inst.components.aoetargeting.reticule.pingprefab = "reticuleaoeping_1_6"
                if TheWorld.ismastersim then
                    inst.components.aoetargeting:SetTargetFX("reticuleaoesummontarget_1")
                    inst.components.aoespell:SetSpellFn(ShadowAchievistSpellFn)
                    inst.components.spellbook:SetSpellFn(nil)
                end
            end,
            execute = chasni_StartAOETargeting,
            atlas = "images/inventoryimages/chasni_spell_icons.xml",
            normal = "shadow_achievist.tex",
            widget_scale = .6,
            hit_radius = 50,
        },
    }

    AddComponentPostInit("spellbook", function(self)
        local oldSetItems = self.SetItems
        function self:SetItems(items, ...)
            local returnval = oldSetItems(self, items, ...)
            self.inst:DoTaskInTime(.6, function()
                if self.inst and self.inst.prefab == "waxwelljournal" then
                    local ownerlocal = self.inst.replica.inventoryitem and self.inst.replica.inventoryitem:IsGrandOwner(ThePlayer) and ThePlayer
                    local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner()
                    if (owner and owner.components.allachivcoin and owner.components.allachivcoin.expertwaxwell4) or (ownerlocal and ownerlocal.currentexpertwaxwell4:value() == 1) then
                        if self.items == nil then
                            self.items = {}
                        end
                        for _, v in ipairs(EXPERT_WAXWELL4_SPELL) do
                            if not has_item_with_label(self.items, v.label) then
                                table.insert(self.items, v)
                            end
                        end
                    end
                end
            end)
            return returnval
        end
    end)
end
