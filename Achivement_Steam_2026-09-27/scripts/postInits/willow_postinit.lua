-- CC : new lunge >> [Reward] expertwillow3
if not chasni_getperkexcludeconfig("expertwillow3") then
    local function OnHitLunge(doer, target)
        if doer.components.combat:CanTarget(target) then
            doer.components.combat:DoAttack(target, nil, nil)
        end
    end

    local function Lunging(comp, doer, startingpos, targetpos)
        local doer_combat = doer.components.combat
        doer_combat:EnableAreaDamage(false)

        local p1 = { x = startingpos.x, y = startingpos.z }
        local p2 = { x = targetpos.x, y = targetpos.z }
        local dx, dy = p2.x - p1.x, p2.y - p1.y
        local dist = dx * dx + dy * dy
        local toskip = {}
        local pv = {}
        local r, cx, cy
        if dist > 0 then
            dist = math.sqrt(dist)
            r = (dist + doer_combat.hitrange * 0.5 + 3) * 0.5
            dx, dy = dx / dist, dy / dist
            cx, cy = p1.x + dx * r, p1.y + dy * r

            doer_combat.ignorehitrange = true

            local c_hit_targets = TheSim:FindEntities(cx, 0, cy, r, nil)
            for _, hit_target in ipairs(c_hit_targets) do
                toskip[hit_target] = true
                if hit_target ~= doer and hit_target:IsValid() and not hit_target:IsInLimbo()
                        and not (hit_target.components.health and hit_target.components.health:IsDead()) then
                    pv.x, pv._, pv.y = hit_target.Transform:GetWorldPosition()
                    local vrange = 1 + hit_target:GetPhysicsRadius(0.5)
                    if DistPointToSegmentXYSq(pv, p1, p2) < vrange * vrange then
                        OnHitLunge(doer, hit_target)
                    end
                end
            end

            doer_combat.ignorehitrange = false
        end

        local angle = (doer.Transform:GetRotation() + 90) * DEGREES
        local p3 = { x = p2.x + doer_combat.hitrange * math.sin(angle), y = p2.y + doer_combat.hitrange * math.cos(angle) }
        local p2_hit_targets = TheSim:FindEntities(p2.x, 0, p2.y, doer_combat.hitrange + 3, nil)
        for _, hit_target in ipairs(p2_hit_targets) do
            if not toskip[hit_target] and hit_target:IsValid() and not hit_target:IsInLimbo()
                    and not (hit_target.components.health and hit_target.components.health:IsDead()) then
                pv.x, pv._, pv.y = hit_target.Transform:GetWorldPosition()
                local vradius = hit_target:GetPhysicsRadius(0.5)
                local vrange = doer_combat.hitrange + vradius
                if distsq(pv.x, pv.y, p2.x, p2.y) < vrange * vrange then
                    vrange = 1 + vradius
                    if DistPointToSegmentXYSq(pv, p2, p3) < vrange * vrange then
                        OnHitLunge(doer, hit_target)
                    end
                end
            end
        end

        doer_combat:EnableAreaDamage(true)

        -- FX trail ----------------------------------------------------------------
        if dist <= 0 then
            local fx = SpawnPrefab("halloween_firepuff_1")
            fx.Transform:SetPosition(p2.x, 0, p2.y)
        else
            dist = math.floor(dist / 1)
            dx = dx * 1
            dy = dy * 1

            for i = 0, dist do
                if i == 0 then
                    p2.x = p2.x - dx * 0.25
                    p2.y = p2.y - dy * 0.25
                elseif i == 1 then
                    p2.x = p2.x - dx * 0.75
                    p2.y = p2.y - dy * 0.75
                else
                    p2.x = p2.x - dx
                    p2.y = p2.y - dy
                end

                local fx = SpawnPrefab("halloween_firepuff_1")
                fx.Transform:SetPosition(p2.x, 0, p2.y)
                local k = (dist > 0 and math.max(0, 1 - i / dist)) or 0
                k = 1 - k * k
                if fx.FastForward then
                    fx:FastForward(0.4 * k)
                end
                if fx.SetMotion then
                    k = 1 + k * 2
                    fx:SetMotion(k * dx, 0, k * dy)
                end
            end
        end
    end

    AddComponentPostInit("aoeweapon_lunge", function(self)
        local oldDoLunge = self.DoLunge
        function self:DoLunge(doer, startingpos, targetpos, ...)
            if self.chasni_lunge then
                Lunging(self, doer, startingpos, targetpos)
                self.inst.components.rechargeable:Discharge(self.chasni_cooldown)
                return true
            end
            return oldDoLunge(self, doer, startingpos, targetpos, ...)
        end
    end)
end

-- CC : setItems Spellbook changes || adding new spell >> [Reward] expertwillow4
if not chasni_getperkexcludeconfig("expertwillow4") then

    local function CheckStackSize(inst, doer, cost)
        return doer.replica.inventory and doer.replica.inventory:Has(inst.prefab, cost)
    end

    local function ReticuleFireRemnantTargetFn()
        return Vector3(ThePlayer.entity:LocalToWorldSpace(10, 0.001, 0))
    end

    local function TryFireRemnant(inst, doer, pos)
        if CheckStackSize(inst, doer, 3) then
            local clone = SpawnPrefab("fire_clone")
            if doer._fireclones == nil then
                doer._fireclones = {}
            end
            table.insert(doer._fireclones, clone)
            clone:CopySkin(doer)
            clone._owner = doer
            clone.Transform:SetPosition(pos.x,pos.y,pos.z)
            clone.components.burnable:Ignite(true, doer)
            return true
        end
        return false
    end

    local function FireRemnantSpellFn(inst, doer, pos)
        if not CheckStackSize(inst, doer, 3) then
            return false, "NOT_ENOUGH_EMBERS"
        elseif TryFireRemnant(inst, doer, pos) then
            doer.components.inventory:ConsumeByName(inst.prefab, 3)
            return true
        end
        return false
    end

    local function TryFireBlink(inst, doer, pos)
        if CheckStackSize(inst, doer, 0) then
            if doer._fireclones and #doer._fireclones > 0 then
                local dist = math.huge
                local target = doer._fireclones[1]
                for _, clone in pairs(doer._fireclones) do
                    local distsq = doer:GetDistanceSqToPoint(clone:GetPosition())
                    if dist > distsq then
                        target = clone
                        dist = distsq
                    end
                end
                local targetposition = target:GetPosition()
                doer.Transform:SetPosition(targetposition.x, 0, targetposition.z)
                target.components.burnable:Extinguish()

                doer:DoTaskInTime(0.05, function(_doer)
                    local x, y, z = _doer.Transform:GetWorldPosition()
                    chasni_spawnprefab("orangefx_ring", x, y, z, 0.3, 0.3, 0.3)
                    _doer:DoTaskInTime(0.2, function(__doer)
                        local ents = TheSim:FindEntities(x, 0, z, 4, {"_combat", "_health"}, chasni_TAG_NOATTACK)
                        for _, ent in pairs(ents) do
                            if ent and ent ~= __doer and ent.components.health and not ent.components.health:IsDead() and ent.components.combat then
                                ent.components.combat:GetAttacked(__doer, 25)
                            end
                        end
                    end)
                end)
                return true
            end
            chasni_retalk(doer, "ANNOUNCE_CHASNI_NO_EMBER")
            return false, "NO_REMNANT"
        end
        return false
    end

    local function FireBlinkSpellFn(inst, doer, pos)
        if not CheckStackSize(inst, doer, 0) then
            return false, "NOT_ENOUGH_EMBERS"
        elseif TryFireBlink(inst, doer, pos) then
            return true
        end
        return false
    end

    local function TryFireTeleport(inst, doer, pos)
        if CheckStackSize(inst, doer, 0) then
            if doer._fireclones and #doer._fireclones > 0 then
                local dist = 0
                local target = doer._fireclones[1]
                for _, clone in pairs(doer._fireclones) do
                    local distsq = doer:GetDistanceSqToPoint(clone:GetPosition())
                    if dist < distsq then
                        target = clone
                        dist = distsq
                    end
                end
                local targetposition = target:GetPosition()
                doer.Transform:SetPosition(targetposition.x, 0, targetposition.z)
                target.components.burnable:Extinguish()
                doer:DoTaskInTime(0.05, function(_doer)
                    if not _doer:HasTag("playerghost") then
                        if _doer.components.health then
                            _doer.components.health:DoDelta(25)
                            chasni_spawnprefab("spider_heal_target_fx", 0, 0, 0, 1, 1, 1, _doer.entity)
                        end
                    end
                end)
                return true
            end
            chasni_retalk(doer, "ANNOUNCE_CHASNI_NO_EMBER")
            return false, "NO_REMNANT"
        end
        return false
    end

    local function FireTeleportSpellFn(inst, doer, pos)
        if not CheckStackSize(inst, doer, 0) then
            return false, "NOT_ENOUGH_EMBERS"
        elseif TryFireTeleport(inst, doer, pos) then
            return true
        end
        return false
    end

    local function TryFireShield(inst, doer, pos)
        if CheckStackSize(inst, doer, 2) then
            doer.components.debuffable:AddDebuff("flame_guard_buff", "flame_guard_buff")
            return true
        end
        return false
    end

    local function FireShieldSpellFn(inst, doer, pos)
        if not CheckStackSize(inst, doer, 2) then
            return false, "NOT_ENOUGH_EMBERS"
        elseif TryFireShield(inst, doer, pos) then
            doer.components.inventory:ConsumeByName(inst.prefab, 2)
            return true
        end
        return false
    end

    local EXPERT_WILLOW4_SPELL =
    {
        {
            label = STRINGS.WILLOW_SPELL_REMNANT,
            onselect = function(inst)
                inst.components.spellbook:SetSpellName(STRINGS.WILLOW_SPELL_REMNANT)
                inst.components.aoetargeting:SetDeployRadius(0)
                inst.components.aoetargeting:SetShouldRepeatCastFn(nil)
                inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoefiretarget_1"
                inst.components.aoetargeting.reticule.pingprefab = "reticuleaoefiretarget_1ping"

                inst.components.aoetargeting.reticule.mousetargetfn = nil
                inst.components.aoetargeting.reticule.updatepositionfn = nil
                inst.components.aoetargeting.reticule.targetfn = ReticuleFireRemnantTargetFn

                if TheWorld.ismastersim then
                    inst.components.aoetargeting:SetTargetFX("reticuleaoefiretarget_1")
                    inst.components.aoespell:SetSpellFn(FireRemnantSpellFn)
                    inst.components.spellbook:SetSpellFn(nil)
                end
            end,
            execute = chasni_StartAOETargeting,
            bank = "chasni_spell_icons_willow",
            build = "chasni_spell_icons_willow",
            anims =
            {
                idle = { anim = "fire_remnant" },
                focus = { anim = "fire_remnant_focus", loop = true },
                down = { anim = "fire_remnant_pressed" },
            },
            widget_scale = 0.6,
        },
        {
            label = STRINGS.WILLOW_SPELL_BLINK,
            onselect = function(inst)
                inst.components.spellbook:SetSpellName(STRINGS.WILLOW_SPELL_BLINK)
                inst.components.aoetargeting:SetDeployRadius(0)
                inst.components.aoetargeting:SetShouldRepeatCastFn(nil)
                inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoefiretarget_1"
                inst.components.aoetargeting.reticule.pingprefab = "reticuleaoefiretarget_1ping"

                inst.components.aoetargeting.reticule.mousetargetfn = chasni_single_reticule_mouse_target_function
                inst.components.aoetargeting.reticule.targetfn = chasni_single_reticule_target_function
                inst.components.aoetargeting.reticule.updatepositionfn = chasni_single_reticule_update_position_function

                if TheWorld.ismastersim then
                    inst.components.aoetargeting:SetTargetFX("reticuleaoefiretarget_1")
                    inst.components.aoespell:SetSpellFn(FireBlinkSpellFn)
                    inst.components.spellbook:SetSpellFn(nil)
                end
            end,
            execute = chasni_StartAOETargeting,
            bank = "chasni_spell_icons_willow",
            build = "chasni_spell_icons_willow",
            anims =
            {
                idle = { anim = "fire_blink" },
                focus = { anim = "fire_blink_focus", loop = true },
                down = { anim = "fire_blink_pressed" },
            },
            widget_scale = 0.6,
        },
        {
            label = STRINGS.WILLOW_SPELL_TELEPORT,
            onselect = function(inst)
                inst.components.spellbook:SetSpellName(STRINGS.WILLOW_SPELL_TELEPORT)
                inst.components.aoetargeting:SetDeployRadius(0)
                inst.components.aoetargeting:SetShouldRepeatCastFn(nil)
                inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoefiretarget_1"
                inst.components.aoetargeting.reticule.pingprefab = "reticuleaoefiretarget_1ping"

                inst.components.aoetargeting.reticule.mousetargetfn = chasni_single_reticule_mouse_target_function
                inst.components.aoetargeting.reticule.targetfn = chasni_single_reticule_target_function
                inst.components.aoetargeting.reticule.updatepositionfn = chasni_single_reticule_update_position_function

                if TheWorld.ismastersim then
                    inst.components.aoetargeting:SetTargetFX("reticuleaoefiretarget_1")
                    inst.components.aoespell:SetSpellFn(FireTeleportSpellFn)
                    inst.components.spellbook:SetSpellFn(nil)
                end
            end,
            execute = chasni_StartAOETargeting,
            bank = "chasni_spell_icons_willow",
            build = "chasni_spell_icons_willow",
            anims =
            {
                idle = { anim = "fire_teleport" },
                focus = { anim = "fire_teleport_focus", loop = true },
                down = { anim = "fire_teleport_pressed" },
            },
            widget_scale = 0.6,
        },
        {
            label = STRINGS.WILLOW_SPELL_SHIELD,
            onselect = function(inst)
                inst.components.spellbook:SetSpellName(STRINGS.WILLOW_SPELL_SHIELD)
                inst.components.aoetargeting:SetDeployRadius(0)
                inst.components.aoetargeting:SetShouldRepeatCastFn(nil)
                inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoefiretarget_1"
                inst.components.aoetargeting.reticule.pingprefab = "reticuleaoefiretarget_1ping"

                inst.components.aoetargeting.reticule.mousetargetfn = chasni_single_reticule_mouse_target_function
                inst.components.aoetargeting.reticule.targetfn = chasni_single_reticule_target_function
                inst.components.aoetargeting.reticule.updatepositionfn = chasni_single_reticule_update_position_function

                if TheWorld.ismastersim then
                    inst.components.aoetargeting:SetTargetFX("reticuleaoefiretarget_1")
                    inst.components.aoespell:SetSpellFn(FireShieldSpellFn)
                    inst.components.spellbook:SetSpellFn(nil)
                end
            end,
            execute = chasni_StartAOETargeting,
            bank = "chasni_spell_icons_willow",
            build = "chasni_spell_icons_willow",
            anims =
            {
                idle = { anim = "fire_shield" },
                focus = { anim = "fire_shield_focus", loop = true },
                down = { anim = "fire_shield_pressed" },
            },
            widget_scale = 0.6,
        },
    }

    AddComponentPostInit("spellbook", function(self)
        local oldSetItems = self.SetItems
        function self:SetItems(items, ...)
            local returnval = oldSetItems(self, items, ...)
            if self.inst and self.inst.prefab == "willow_ember" then
                local ownerlocal = self.inst.replica.inventoryitem and self.inst.replica.inventoryitem:IsGrandOwner(ThePlayer) and ThePlayer
                local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner()
                if (owner and owner.components.allachivcoin and owner.components.allachivcoin.expertwillow4) or (ownerlocal and ownerlocal.currentexpertwillow4:value() == 1) then
                    if self.items == nil then
                        self.items = {}
                    end
                    for _, v in pairs(EXPERT_WILLOW4_SPELL) do
                        table.insert(self.items, v)
                    end
                    self:SetFocusRadius(150)
                    self:SetRadius(150)
                end
            end
            return returnval
        end
    end)
end
