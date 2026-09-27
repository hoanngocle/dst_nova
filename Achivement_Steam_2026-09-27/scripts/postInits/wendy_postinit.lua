-- CC : update elixir logic >> [Reward] expertwendy1
if not chasni_getperkexcludeconfig("expertwendy1") then
    -- CC : unlimited duration elixir >> [Reward] expertwendy1
    if TheNet:GetIsServer() then
        local function commonElixirBuffInit(inst)
            local debuff = inst.components.debuff
            local timer = inst.components.timer
            if not debuff or not timer then return end

            local function IsExpertWendy1(_, target)
                local link = target._playerlink
                return link
                        and link.components.ghostlybond
                        and link.components.allachivcoin
                        and link.components.allachivcoin.expertwendy1
            end

            local function StopDecay()
                timer:StopTimer("decay")
            end

            local function ShouldStop(_inst, target)
                if IsExpertWendy1(_inst, target) then
                    StopDecay()
                    _inst.expertwendy1 = true
                else
                    _inst.expertwendy1 = false
                end
            end

            if not timer._expertwendypatched then
                timer._expertwendypatched = true

                local oldStart  = timer.StartTimer
                timer.StartTimer = function(self, name, duration)
                    local retval = oldStart(self, name, duration)
                    if name == "decay" and self.inst.expertwendy1 then
                        StopDecay()
                    end
                    return retval
                end

                local oldResume   = timer.ResumeTimer
                timer.ResumeTimer = function(self, name)
                    local retval = oldResume(self, name)
                    if name == "decay" and self.inst.expertwendy1 then
                        StopDecay()
                    end
                    return retval
                end
            end

            local oldOnAttached = debuff.onattachedfn
            debuff:SetAttachedFn(function(_inst, target, ...)
                local retval = oldOnAttached and oldOnAttached(_inst, target, ...) or nil
                ShouldStop(_inst, target)
                _inst:DoTaskInTime(3 ,function()
                    ShouldStop(_inst, target)
                end)
                return retval
            end)

            local oldOnExtended = debuff.onextendedfn
            debuff:SetExtendedFn(function(_inst, target, ...)
                local retval = oldOnExtended and oldOnExtended(_inst, target, ...) or nil
                ShouldStop(_inst, target)
                _inst:DoTaskInTime(3 ,function()
                    ShouldStop(_inst, target)
                end)
                return retval
            end)
        end

        AddPrefabPostInitAny(function(inst)
            if inst.prefab:match("^ghostlyelixir_.+_buff$") then
                commonElixirBuffInit(inst)
            end
        end)
    end

    -- CC : stronger elixirs >> [Reward] expertwendy1
    if TheNet:GetIsServer() then
        AddPrefabPostInit("ghostlyelixir_fastregen", function(inst)
            if not inst.potion_tunings then
                return
            end
            local old_tick_fn = inst.potion_tunings.TICK_FN
            inst.potion_tunings.TICK_FN = function(self, target, ...)
                if old_tick_fn then
                    old_tick_fn(self, target, ...)
                end
                if target._playerlink and target._playerlink.components.ghostlybond then
                    local wendycomp = target._playerlink.components
                    if wendycomp.allachivcoin and wendycomp.allachivcoin.expertwendy1 == true then
                        local increment =  wendycomp.levelsystem and wendycomp.levelsystem.healthlevelmax > 0 and wendycomp.levelsystem.healthlevelmax / 20 or 0
                        target.components.health:DoDelta(increment)
                    end
                end
            end
        end)
        AddPrefabPostInit("ghostlyelixir_retaliation", function(inst)
            if not inst.potion_tunings then
                return
            end
            local old_onapply_fn = inst.potion_tunings.ONAPPLY
            inst.potion_tunings.ONAPPLY = function(self, target, ...)
                if old_onapply_fn then
                    old_onapply_fn(self, target, ...)
                end
                if target._playerlink and target._playerlink.components.ghostlybond then
                    local wendycomp = target._playerlink.components
                    if wendycomp.allachivcoin and wendycomp.allachivcoin.expertwendy1 == true then
                        if target._UpdateGhostlyBondLevel then
                            target._UpdateGhostlyBondLevel(target, target._playerlink.components.ghostlybond.bondlevel)
                        end
                    end
                end
            end

            local old_ondetach_fn = inst.potion_tunings.ONDETACH
            inst.potion_tunings.ONDETACH = function(self, target, ...)
                if old_ondetach_fn then
                    old_ondetach_fn(self, target, ...)
                end
                if target._playerlink and target._playerlink.components.ghostlybond then
                    if target._on_ghostlybond_level_change then
                        local level = target._playerlink.components.ghostlybond.bondlevel
                        target._on_ghostlybond_level_change(target, {ghost = target, level = level, prev_level = level, isloading = true})
                    end
                end
            end
        end)
        AddPrefabPostInit("ghostlyelixir_speed", function(inst)
            if not inst.potion_tunings then
                return
            end
            local old_onapply_fn = inst.potion_tunings.ONAPPLY
            inst.potion_tunings.ONAPPLY = function(self, target, ...)
                if old_onapply_fn then
                    old_onapply_fn(self, target, ...)
                end
                if target._playerlink and target._playerlink.components.ghostlybond then
                    local wendycomp = target._playerlink.components
                    if wendycomp.allachivcoin and wendycomp.allachivcoin.expertwendy1 == true then
                        if target._speedelixir_light == nil or not target._speedelixir_light:IsValid() then
                            target._speedelixir_light = SpawnPrefab("ghostlyelixir_speed_light")
                        end
                        target._speedelixir_light.entity:SetParent(target.entity)
                    end
                end
            end

            local old_ondetach_fn = inst.potion_tunings.ONDETACH
            inst.potion_tunings.ONDETACH = function(self, target, ...)
                if old_ondetach_fn then
                    old_ondetach_fn(self, target, ...)
                end
                if target._playerlink and target._playerlink.components.ghostlybond then
                    if target._speedelixir_light then
                        if target._speedelixir_light:IsValid() then
                            target._speedelixir_light:Remove()
                        end
                        target._speedelixir_light = nil
                    end
                end
            end
        end)
    end

    -- CC : stronger vex_debuf on ghostlyelixir_attack >> [Reward] expertwendy1
    if TheNet:GetIsServer() then
        AddPrefabPostInit("abigail", function(inst)
            local function new_ApplyDebuff(_inst, data)
                local wendycomp = _inst._playerlink.components
                if wendycomp.allachivcoin and wendycomp.allachivcoin.expertwendy1 == true then
                    local elixir_buff = _inst:GetDebuff("elixir_buff")
                    if elixir_buff and elixir_buff.prefab == "ghostlyelixir_attack_buff" then
                        local target = data and data.target
                        if target then
                            target:AddDebuff("abigail_vex_debuff_perk", "abigail_vex_debuff")
                            local debuff = target:GetDebuff("abigail_vex_debuff_perk")
                            target.components.combat.externaldamagetakenmultipliers:RemoveModifier(debuff)
                            target.components.combat.externaldamagetakenmultipliers:SetModifier(debuff, 1.3)
                        end
                    end
                end
            end
            inst:ListenForEvent("onareaattackother", new_ApplyDebuff)
        end)
    end

    -- CC : increased health on ghostlyelixir_retaliation >> [Reward] expertwendy1
    if TheNet:GetIsServer() then
        AddPrefabPostInit("abigail", function(inst)
            local function new_UpdateGhostlyBondLevel(_inst, level)
                local wendycomp = _inst._playerlink.components
                if wendycomp.allachivcoin and wendycomp.allachivcoin.expertwendy1 == true then
                    local elixir_buff = _inst:GetDebuff("elixir_buff")
                    if elixir_buff and elixir_buff.prefab == "ghostlyelixir_retaliation_buff" then
                        local max_health = level == 3 and TUNING.ABIGAIL_HEALTH_LEVEL3 * 2
                                or level == 2 and TUNING.ABIGAIL_HEALTH_LEVEL2 * 2
                                or TUNING.ABIGAIL_HEALTH_LEVEL1 * 2

                        local health = _inst.components.health
                        if health then
                            if health:IsDead() then
                                health.maxhealth = max_health
                            else
                                chasni_setMaxHealth(health, max_health)
                            end

                            if _inst._playerlink and _inst._playerlink.components.pethealthbar then
                                _inst._playerlink.components.pethealthbar:SetMaxHealth(max_health)
                            end
                        end
                    end
                end
            end

            local old_LinkToPlayer = inst.LinkToPlayer
            local function _LinkToPlayer(_inst, player, ...)
                old_LinkToPlayer(_inst, player, ...)
                new_UpdateGhostlyBondLevel(_inst, player.components.ghostlybond.bondlevel)
            end
            local old_on_ghostlybond_level_change = inst._on_ghostlybond_level_change
            local function _on_ghostlybond_level_change(_inst, player, data, ...)
                old_on_ghostlybond_level_change(player, data, ...)
                new_UpdateGhostlyBondLevel(_inst, data.level)
            end

            inst._on_ghostlybond_level_change = function(player, data, ...) _on_ghostlybond_level_change(inst, player, data, ...) end
            inst.LinkToPlayer = _LinkToPlayer
            inst._UpdateGhostlyBondLevel = new_UpdateGhostlyBondLevel
        end)
    end
end

-- CC : new elixir >> [Reward] expertwendy2
if not chasni_getperkexcludeconfig("expertwendy2") then
    -- CC : add new ghostly elixir icon (components.pethealthbar:GetDebugString()) >> [Reward] expertwendy2 
    AddClassPostConstruct("widgets/statusdisplays", function(inst)
        if inst.pethealthbadge and inst.pethealthbadge.SetBuildForSymbol then
            inst.pethealthbadge:SetBuildForSymbol("chasni_abigail_vial_ui", 1716335378) -- lunar
            inst.pethealthbadge:SetBuildForSymbol("chasni_abigail_vial_ui", 3070386716) -- shadow
            inst.pethealthbadge:SetBuildForSymbol("chasni_abigail_vial_ui", 368241122) -- temp
            inst.pethealthbadge:SetBuildForSymbol("chasni_abigail_vial_ui", 692729517) -- slow
        end
        if inst.heart and inst.heart.SetBuildForSymbol then
            inst.heart:SetBuildForSymbol("chasni_abigail_vial_ui", 1716335378) -- lunar
            inst.heart:SetBuildForSymbol("chasni_abigail_vial_ui", 3070386716) -- shadow
            inst.heart:SetBuildForSymbol("chasni_abigail_vial_ui", 368241122) -- temp
            inst.heart:SetBuildForSymbol("chasni_abigail_vial_ui", 692729517) -- slow
        end
    end)

    -- CC : add ghostly elixir swap animation on drink and on apply to flowers >> [Reward] expertwendy2
    local chasni_elixir_type = {
        chasnilunar = true,
        chasnishadow = true,
        temperature = true,
        slow = true,
    }
    AddStategraphPostInit("wilson", function(sg)
        local function ModifyElixirBuild(inst, elixir_type)
            local build = "ghostly_elixirs"
            if chasni_elixir_type[elixir_type] then
                build = "chasni_ghostly_elixirs"
            end
            inst.AnimState:OverrideSymbol("ghostly_elixirs_swap", build, "ghostly_elixirs_" .. elixir_type .. "_swap")
        end

        local old_applyelixir_onenter = sg.states["applyelixir"].onenter
        sg.states["applyelixir"].onenter = function(inst)
            old_applyelixir_onenter(inst)
            if inst.sg.statemem.action then
                local invobject = inst.sg.statemem.action.invobject
                if invobject and invobject.elixir_buff_type then
                    ModifyElixirBuild(inst, invobject.elixir_buff_type)
                end
            end
        end

        local old_drinkelixir_onenter = sg.states["drinkelixir"].onenter
        sg.states["drinkelixir"].onenter = function(inst)
            old_drinkelixir_onenter(inst)
            if inst.sg.statemem.action then
                local invobject = inst.sg.statemem.action.invobject
                if invobject and invobject.elixir_buff_type then
                    ModifyElixirBuild(inst, invobject.elixir_buff_type)
                end
            end
        end
    end)
    AddStategraphPostInit("wilson_client", function(sg)
        local function ModifyElixirBuild(inst, elixir_type)
            local build = "ghostly_elixirs"
            if chasni_elixir_type[elixir_type] then
                build = "chasni_ghostly_elixirs"
            end
            inst.AnimState:OverrideSymbol("ghostly_elixirs_swap", build, "ghostly_elixirs_" .. elixir_type .. "_swap")
        end

        local old_applyelixir_onenter = sg.states["applyelixir"].onenter
        sg.states["applyelixir"].onenter = function(inst)
            old_applyelixir_onenter(inst)
            local buffaction = inst:GetBufferedAction()
            if buffaction and buffaction.invobject and buffaction.invobject.elixir_buff_type then
                ModifyElixirBuild(inst, buffaction.invobject.elixir_buff_type)
            end
        end

        local old_drinkelixir_onenter = sg.states["drinkelixir"].onenter
        sg.states["drinkelixir"].onenter = function(inst)
            old_drinkelixir_onenter(inst)
            local buffaction = inst:GetBufferedAction()
            if buffaction and buffaction.invobject and buffaction.invobject.elixir_buff_type then
                ModifyElixirBuild(inst, buffaction.invobject.elixir_buff_type)
            end
        end
    end)
end

-- CC : update sisturn logic >> [Reward] expertwendy3
if not chasni_getperkexcludeconfig("expertwendy3") then
    -- CC : wendy invincibility >> [Reward] expertwendy3
    if TheNet:GetIsServer() then
        AddPrefabPostInit("wendy", function(inst)
            inst:ListenForEvent("minhealth", function(player, data)
                if player.components.allachivcoin and player.components.allachivcoin.expertwendy3
                        and TheWorld.components.sisturnregistry and TheWorld.components.sisturnregistry:IsActive()
                        and player.components.health.currenthealth <= 0 and data.afflicter and data.afflicter:HasTag("epic")
                then
                    player.components.health.currenthealth = 0.1
                    chasni_spawnprefab("superjump_fx", 0,0,0, 1, 1, 1, inst.entity)
                end
            end)
        end)
    end

    -- CC : sisturn revive >> [Reward] expertwendy3
    if TheNet:GetIsServer() then
        AddPrefabPostInit("sisturn", function(inst)
            local function Revive_OnHaunt(inst, haunter)
                if inst.components.container and inst.components.container:IsFull() then
                    if haunter.components.allachivcoin and haunter.components.allachivcoin.expertwendy3 then
                        local announcement_string = haunter:GetDisplayName().." "..STRINGS.UI.HUD.REZ_ANNOUNCEMENT.." sisturn."
                        TheNet:AnnounceResurrect(announcement_string, haunter.entity)
                        haunter:PushEvent("respawnfromghost", { source = inst, user = haunter })
                    end
                end
            end

            if inst.components.hauntable == nil then
                inst:AddComponent("hauntable")
            end
            inst.components.hauntable:SetOnHauntFn(Revive_OnHaunt)
        end)
    end

    -- CC : sisturn registry tweak >> [Reward] expertwendy3
    AddComponentPostInit("sisturnregistry", function(comp)
        comp.FindSisturn = function(self, x, z, near, ...)
            local dist
            local targetsisturn
            if self.globalsisturn == nil then
                self.globalsisturn = {}
            end
            for sisturn, status in pairs(self.globalsisturn) do
                if status then
                    local newdist = sisturn:GetDistanceSqToPoint(x, 0, z)
                    if dist == nil then
                        dist = newdist
                        targetsisturn = sisturn
                    else
                        if near and dist > newdist then
                            dist = newdist
                            targetsisturn = sisturn
                        elseif not near and dist < newdist then
                            dist = newdist
                            targetsisturn = sisturn
                        end
                    end
                end
            end
            return targetsisturn
        end

        local old_Register = comp.Register
        comp.Register = function(self, sisturn, ...)
            if old_Register then
                old_Register(self, sisturn, ...)
            end
            if self.globalsisturn == nil then
                self.globalsisturn = {}
            end
            if sisturn and self.globalsisturn[sisturn] then
                return
            end

            self.globalsisturn[sisturn] = false
        end

        local Global_OnUpdateSisturnState = function(self, data)
            if self.components.sisturnregistry.globalsisturn == nil then
                self.components.sisturnregistry.globalsisturn = {}
            end
            self.components.sisturnregistry.globalsisturn[data.inst] = data.is_active == true
        end
        comp.inst:ListenForEvent("ms_updatesisturnstate", Global_OnUpdateSisturnState)
    end)
end

