-- CC : singing inspiration delay with thunder_armor and thunder_hat >> [Reward] expertwathg1
if not chasni_getperkexcludeconfig("expertwathg1") then
    AddComponentPostInit("singinginspiration", function(self)
        local _OnUpdate = self.OnUpdate
        self.OnUpdate = function(_self, dt, ...)
            if _self.inst.components.inventory:EquipHasTag("thunder_armor") and _self.inst.components.inventory:EquipHasTag("thunder_hat") then
                _self.is_draining = false
            else
                _OnUpdate(_self, dt, ...)
            end
        end
    end)
end

-- CC : wigfrid attack speed logic >> [Reward] expertwathg2
if not chasni_getperkexcludeconfig("expertwathg2") then
    -- CC : reduce wigfrid AttackPeriod >> [Reward] expertwathg2
    AddComponentPostInit("wathgrithr", function(self)
        if self.components.combat then
            self.components.combat:SetAttackPeriod(0)
        end
    end)

    -- CC : songfolder attackspeed buff >> [Reward] expertwathg2
    local function cooldownAttack(cooldown)
        return cooldown * (0.1/TUNING.WILSON_ATTACK_PERIOD*1.5)
    end
    AddStategraphPostInit("wilson", function(sg)
        if sg.states["attack"] then
            local old_attack_onenter = sg.states["attack"].onenter
            sg.states["attack"].onenter = function(inst,...)
                if inst.components.combat and inst.prefab == "wathgrithr" and inst.components.inventory and inst.components.inventory:HasItemWithTag("fullfolder", 1)
                        and (inst.components.rider and not inst.components.rider:IsRiding())
                then
                    if inst.components.combat:InCooldown() then
                        inst.sg:RemoveStateTag("abouttoattack")
                        inst:ClearBufferedAction()
                        inst.sg:GoToState("idle", true)
                        return
                    end
                    if inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS) == nil and inst.subweapon then
                        local subweapon = inst.components.inventory:FindItem(function (v)
                            return inst.subweapon == v.prefab
                        end)
                        inst.components.inventory:Equip(subweapon)
                    end
                    inst.subweapon = inst.equipped_weapon
                    local buffaction = inst:GetBufferedAction()
                    local target = buffaction and buffaction.target or nil
                    local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    inst.components.combat:SetTarget(target)
                    inst.components.combat:StartAttack()
                    inst.components.locomotor:Stop()
                    local cooldown = inst.components.combat.min_attack_period + .5 * FRAMES
                    if equip and equip:HasTag("whip") then
                        inst.AnimState:PlayAnimation("whip_pre")
                        inst.AnimState:PushAnimation("whip", false)
                        inst.sg.statemem.iswhip = true
                        inst.SoundEmitter:PlaySound("dontstarve/common/whip_large", nil, nil, true)
                        cooldown = math.max(cooldown, 17 * FRAMES)
                    elseif equip and equip:HasTag("book") then
                        inst.AnimState:PlayAnimation("attack_book")
                        inst.sg.statemem.isbook = true
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                        cooldown = math.max(cooldown, 19 * FRAMES)
                    elseif equip and equip.components.weapon and not equip:HasTag("punch") then
                        inst.AnimState:PlayAnimation("atk_pre")
                        inst.AnimState:PushAnimation("atk", false)
                        if (equip.projectiledelay or 0) > 0 then
                            inst.sg.statemem.projectiledelay = 8 * FRAMES - equip.projectiledelay
                            if inst.sg.statemem.projectiledelay > FRAMES then
                                inst.sg.statemem.projectilesound =
                                (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                                        (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                                        "dontstarve/wilson/attack_weapon"
                            elseif inst.sg.statemem.projectiledelay <= 0 then
                                inst.sg.statemem.projectiledelay = nil
                            end
                        end
                        if inst.sg.statemem.projectilesound == nil then
                            inst.SoundEmitter:PlaySound(
                                    (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                                            (equip:HasTag("shadow") and "dontstarve/wilson/attack_nightsword") or
                                            (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                                            "dontstarve/wilson/attack_weapon",
                                    nil, nil, true
                            )
                        end
                        cooldown = math.max(cooldown, 13 * FRAMES)
                    elseif equip and (equip:HasTag("light") or equip:HasTag("nopunch")) then
                        inst.AnimState:PlayAnimation("atk_pre")
                        inst.AnimState:PushAnimation("atk", false)
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
                        cooldown = math.max(cooldown, 13 * FRAMES)
                    else
                        inst.AnimState:PlayAnimation("punch")
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                        cooldown = math.max(cooldown, 24 * FRAMES)
                    end
                    cooldown = cooldownAttack(cooldown)
                    inst.sg:SetTimeout(cooldown)

                    if target then
                        inst.components.combat:BattleCry()
                        if target:IsValid() then
                            inst:FacePoint(target:GetPosition())
                            inst.sg.statemem.attacktarget = target
                        end
                    end
                else
                    old_attack_onenter(inst,...)
                end
            end
        end
    end)

    AddStategraphPostInit("wilson_client", function(sg)
        if sg.states["attack"] then
            local old_attack_onenter = sg.states["attack"].onenter
            sg.states["attack"].onenter = function(inst,...)
                local rider = inst.replica.rider
                if inst.prefab == "wathgrithr" and inst.replica.inventory and inst.replica.inventory:HasItemWithTag("fullfolder", 1)
                        and (rider and not rider:IsRiding()) then
                    local buffaction = inst:GetBufferedAction()
                    local cooldown = 0
                    if inst.replica.combat then
                        if inst.replica.combat:InCooldown() then
                            inst.sg:RemoveStateTag("abouttoattack")
                            inst:ClearBufferedAction()
                            inst.sg:GoToState("idle", true)
                            return
                        end
                        inst.replica.combat:StartAttack()
                        cooldown = inst.replica.combat:MinAttackPeriod() + .5 * FRAMES
                    end
                    inst.components.locomotor:Stop()
                    local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    if equip and equip:HasTag("whip") then
                        inst.AnimState:PlayAnimation("whip_pre")
                        inst.AnimState:PushAnimation("whip", false)
                        inst.sg.statemem.iswhip = true
                        inst.SoundEmitter:PlaySound("dontstarve/common/whip_pre", nil, nil, true)
                        if cooldown > 0 then
                            cooldown = math.max(cooldown, 17 * FRAMES)
                        end
                    elseif equip and equip:HasTag("book") then
                        inst.AnimState:PlayAnimation("attack_book")
                        inst.sg.statemem.isbook = true
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                        if cooldown > 0 then
                            cooldown = math.max(cooldown, 19 * FRAMES)
                        end
                    elseif equip and equip:HasTag("chop_attack") and inst:HasTag("woodcutter") then
                        inst.AnimState:PlayAnimation(inst.AnimState:IsCurrentAnimation("woodie_chop_loop") and inst.AnimState:GetCurrentAnimationTime() < 7.1 * FRAMES and "woodie_chop_atk_pre" or "woodie_chop_pre")
                        inst.AnimState:PushAnimation("woodie_chop_loop", false)
                        inst.sg.statemem.ischop = true
                        cooldown = math.max(cooldown, 11 * FRAMES)
                    elseif equip and
                            equip.replica.inventoryitem and
                            equip.replica.inventoryitem:IsWeapon() and
                            not equip:HasTag("punch") then
                        inst.AnimState:PlayAnimation("atk_pre")
                        inst.AnimState:PushAnimation("atk", false)
                        if (equip.projectiledelay or 0) > 0 then
                            --V2C: Projectiles don't show in the initial delayed frames so that
                            --     when they do appear, they're already in front of the player.
                            --     Start the attack early to keep animation in sync.
                            inst.sg.statemem.projectiledelay = 8 * FRAMES - equip.projectiledelay
                            if inst.sg.statemem.projectiledelay > FRAMES then
                                inst.sg.statemem.projectilesound =
                                (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                                        (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                                        "dontstarve/wilson/attack_weapon"
                            elseif inst.sg.statemem.projectiledelay <= 0 then
                                inst.sg.statemem.projectiledelay = nil
                            end
                        end
                        if inst.sg.statemem.projectilesound == nil then
                            inst.SoundEmitter:PlaySound(
                                    (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                                            (equip:HasTag("shadow") and "dontstarve/wilson/attack_nightsword") or
                                            (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                                            "dontstarve/wilson/attack_weapon",
                                    nil, nil, true
                            )
                        end
                        if cooldown > 0 then
                            cooldown = math.max(cooldown, 13 * FRAMES)
                        end
                    elseif equip and
                            (equip:HasTag("light") or
                                    equip:HasTag("nopunch")) then
                        inst.AnimState:PlayAnimation("atk_pre")
                        inst.AnimState:PushAnimation("atk", false)
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
                        if cooldown > 0 then
                            cooldown = math.max(cooldown, 13 * FRAMES)
                        end
                    else
                        inst.AnimState:PlayAnimation("punch")
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                        if cooldown > 0 then
                            cooldown = math.max(cooldown, 24 * FRAMES)
                        end
                    end

                    if buffaction then
                        inst:PerformPreviewBufferedAction()

                        if buffaction.target and buffaction.target:IsValid() then
                            inst:FacePoint(buffaction.target:GetPosition())
                            inst.sg.statemem.attacktarget = buffaction.target
                        end
                    end

                    if cooldown > 0 then
                        cooldown = cooldownAttack(cooldown)
                        inst.sg:SetTimeout(cooldown)
                    end
                else
                    return old_attack_onenter(inst,...)
                end
            end
        end
    end)
end

-- CC : add new battlesongs >> [Reward] expertwathg2
if not chasni_getperkexcludeconfig("expertwathg2") then
    local GetBattleSongDefFromNetID = require("prefabs/wigfrid/battlesongsdefs_perk").GetBattleSongDefFromNetID

    local OnInspirationSongsDirty = function(inst, slot)
        inst:DoTaskInTime(0,function()
            if inst._parent then
                if inst.inspirationsongs[slot]:value() > 10  then
                    local song_def = GetBattleSongDefFromNetID(inst.inspirationsongs[slot]:value())
                    inst._parent:PushEvent("inspirationsongchanged", {songdata = song_def, slotnum = slot})
                end
            end
        end)
    end

    AddPrefabPostInit("player_classified",function(inst)
        if not TheWorld.ismastersim then
            inst:ListenForEvent("inspirationsong1dirty", function(_inst) OnInspirationSongsDirty(_inst, 1) end)
            inst:ListenForEvent("inspirationsong2dirty", function(_inst) OnInspirationSongsDirty(_inst, 2) end)
            inst:ListenForEvent("inspirationsong3dirty", function(_inst) OnInspirationSongsDirty(_inst, 3) end)
        end
        inst.anoinspirationsongs={
            net_smallbyte(inst.GUID, "winspiration.song1", "inspirationsong1dirty"),
            net_smallbyte(inst.GUID, "winspiration.song2", "inspirationsong2dirty"),
            net_smallbyte(inst.GUID, "winspiration.song3", "inspirationsong3dirty")
        }
        inst.inspirationsongs,inst.anoinspirationsongs=inst.anoinspirationsongs,inst.inspirationsongs
    end)

    -- CC : add new battlesongs icon item >> [Reward] expertwathg2
    local function InspirationBadgePostConstruct(self)
        local oldOnBuffChanged = self.OnBuffChanged
        function self:OnBuffChanged(num, name, ...)
            local retval = oldOnBuffChanged(self, num, name, ...)
            if name and (name == "chasni_battlesong_sailor_buff" or name == "chasni_battlesong_lightning_buff" )then
                local icon = name == "chasni_battlesong_sailor_buff" and "battlesong_healthgain_buff" or "battlesong_sanitygain_buff"
                self.buffs[num]:GetAnimState():OverrideSymbol("buff_icon"..tostring(num), "chasni_status_wathgrithr", icon)
            end
            return retval
        end
    end

    -- CC : add expertsailor multiplier || chasni_battlesong_sailor >> [Reward] expertwathg2
    AddComponentPostInit("expertsailor", function(self)
        local oldGetRowForceMultiplier = self.GetRowForceMultiplier
        function self:GetRowForceMultiplier(...)
            local multiplier = self.inst:HasDebuff("chasni_battlesong_sailor_buff") and 2 or 1
            return (oldGetRowForceMultiplier(self, ...) or 1) * multiplier
        end
        local oldGetRowExtraMaxVelocity = self.GetRowExtraMaxVelocity
        function self:GetRowExtraMaxVelocity(...)
            local multiplier = self.inst:HasDebuff("chasni_battlesong_sailor_buff") and 0.5 or 0
            return (oldGetRowExtraMaxVelocity(self, ...) or 0) + multiplier
        end
        local oldGetAnchorRaisingSpeed = self.GetAnchorRaisingSpeed
        function self:GetAnchorRaisingSpeed(...)
            local multiplier = self.inst:HasDebuff("chasni_battlesong_sailor_buff") and 2 or 1
            return (oldGetAnchorRaisingSpeed(self, ...) or 1) * multiplier
        end
        local oldGetLowerSailStrength = self.GetLowerSailStrength
        function self:GetLowerSailStrength(...)
            local multiplier = self.inst:HasDebuff("chasni_battlesong_sailor_buff") and 2 or 1
            return (oldGetLowerSailStrength(self, ...) or TUNING.DEFAULT_SAIL_BOOST_STRENGTH) * multiplier
        end
    end)

    AddClassPostConstruct("widgets/inspirationbadge", InspirationBadgePostConstruct)
end 