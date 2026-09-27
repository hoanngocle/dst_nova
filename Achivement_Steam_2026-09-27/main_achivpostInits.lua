GLOBAL.setmetatable(env,{__index=function(_,k) return GLOBAL.rawget(GLOBAL,k) end})

require "functions/helperfunctions"

-- CC : add "lightning" achievement counter >> [Achievement] HURT Get hit by lightning
AddComponentPostInit("playerlightningtarget", function(self)
    local _DoStrike = self.DoStrike
    function self:DoStrike(...)
        _DoStrike(self, ...)
        if self.inst and self.inst.components.allachivevent then
            self.inst.components.allachivevent:CheckAchievement(self.inst, "lightning")
        end
        if self.inst.chasni_playerlighningstruck then
            self.inst.chasni_playerlighningstruck()
        end
    end
end)

-- CC : add all work achievement and XP for waxwell shadowworker || book_voker
if TheNet:GetIsServer() then
    AddPrefabPostInit("shadowworker", function(inst)
        inst:ListenForEvent("finishedwork", function(i, data)
            if inst.components.follower then
                local leader = inst.components.follower.leader
                if leader and leader.components.allachivevent then
                    if data.action then
                        if data.action == ACTIONS.CHOP then
                            leader.components.allachivevent:CountAchievement(leader, "chopmaster")
                        end
                        if data.action == ACTIONS.DIG and data.target:HasTag("stump") then
                            leader.components.allachivevent:CountAchievement(leader, "chopmaster")
                        end
                        if data.action == ACTIONS.MINE then
                            leader.components.allachivevent:CountAchievement(leader, "minemaster")
                        end
                    end
                end
                if leader and leader.components.levelsystem then
                    if _G.WORKXP ~= true then return end
                    leader.components.levelsystem:xpDoDelta(2, leader)
                end
            end
        end)
        -- book_voker
        inst:ListenForEvent("working", function(i, data)
            if inst.components.follower then
                local leader = inst.components.follower.leader
                if leader and leader.components.inventory and leader.components.inventory:EquipHasTag("book_voker") and leader.components.allachivcoin then
                    local workable = data.target and data.target.components.workable
                    if workable and workable.workleft > 0 then
                        if (leader.components.allachivcoin.minefaster and workable.action == ACTIONS.MINE) or (leader.components.allachivcoin.chopfaster and workable.action == ACTIONS.CHOP) then
                            inst:DoTaskInTime(0.1, function()
                                workable:Destroy(inst)
                            end)
                        end
                    end
                end
            end
        end)
    end)
end

-- CC : add "plantmaster" achievement counter >> [Achievement] Work Plant in farm
-- CC : add xp to Planting Farm >> [LevelSystem]
local function DoFarmCheck(seed, planter)
    if planter and planter.components.allachivevent then
        planter.components.allachivevent:CountAchievement(planter, "plantmaster")
    end
    if planter and planter.components.levelsystem then
        if _G.PLANTXP == true then
            local xpmult = seed.prefab == "seeds" and 5 or 15
            local trinket = chasni_getequippedtrinket(planter)
            if trinket and trinket.prefab == "trinket_chasni_11" then
                local stacksize = chasni_gettrinketpoint(trinket,  1, 20)
                xpmult = xpmult + stacksize
            end

            if planter.prefab == "wormwood" then
                xpmult = xpmult * 5
            end
            planter.components.levelsystem:xpDoDelta(xpmult, planter, false, true)
        end
    end
end
AddComponentPostInit("farmplantable", function(farmplantable)
    local _Plant = farmplantable.Plant
    farmplantable.Plant = function(self, target, planter, ...)
        local seedprefab = self.inst.prefab
        DoFarmCheck(self.inst, planter)

        local result = _Plant(self, target, planter, ...)
        if result and planter and planter.components.allachivevent then
            planter:PushEvent("nova_plant_seed", { prefab = seedprefab })
        end
        return result
    end
end)
-- CC : add xp to Planting Farm as deployable >> [LevelSystem]
AddComponentPostInit("deployable", function(deployable)
    local _Deploy = deployable.Deploy
    deployable.Deploy = function(self, pt, deployer, rot, ...)
        local isfarm = self.inst:HasTag("deployedfarmplant")
        local seedprefab = self.inst.prefab
        if isfarm then
            DoFarmCheck(self.inst, deployer)
        end

        local result = _Deploy(self, pt, deployer, rot, ...)
        if result and isfarm and deployer and deployer.components.allachivevent then
            deployer:PushEvent("nova_plant_seed", { prefab = seedprefab })
        end
        return result
    end
end)

-- CC : add "feedlivinglog" achievement checker >> [Achievement] Food Tormented Scream
if TheNet:GetIsServer() then
    AddPrefabPostInit("livinglog", function(inst)
        inst:ListenForEvent("oneaten", function(_, data)
            if data.eater and data.eater.prefab == "cookiecutter" then
                local player, distsq = data.eater:GetNearestPlayer(true)
                if distsq and distsq < 20 and player and player.components.allachivevent then
                    player.components.allachivevent:CheckAchievement(player, "feedlivinglog")
                end
            end
        end)
    end)
end

-- CC : add "cookmaster" achievement counter to COOK ACTION >> [Achievement] WORK : Cook X times
-- CC : add "foodwarly" achievement list check to COOK ACTION >> [Achievement] MISC : Cook warly food
-- CC : add "cookfaster" perk to COOK ACTION >> [Perk] Instant Cook
-- CC : add xp to COOK ACTION >> [LevelSystem]
-- CC : add "trinket_21" increase xp on COOK ACTION >> [Perk] Trinket Slot > Trinket_21 || Beaten Beater
-- CC : add "chesspiece_hornucopia_stone" increase xp on COOK ACTION >> [Perk] groundedscream || Carved Hornucopia
local old_cook_fn = ACTIONS.COOK.fn
ACTIONS.COOK.fn = function(act, ...)
    local result = old_cook_fn(act)
    local stewer = act.target.components.stewer
    if result and stewer then
        if act.doer and stewer.product then
            act.doer:PushEvent("nova_cookedproduct", { product = stewer.product, cooker = act.target.prefab })
        end
        local allachivevent = act.doer.components.allachivevent
        if allachivevent then
            allachivevent:CountAchievement(act.doer, "cookmaster")

            -- foodwarly
            if allachivevent.foodwarly ~= true and stewer.product then
                allachivevent:RemoveListAchievement(act.doer, "foodwarly", stewer.product)
            end
        end

        if act.doer and act.doer.components.levelsystem then
            if _G.COOKXP == true then
                local xpmult = 6
                if act.doer.components.trinketowner then
                    local trinket = chasni_getequippedtrinket(act.doer)
                    if trinket and trinket.prefab == "trinket_21" then
                        local stacksize = chasni_gettrinketpoint(trinket, 2, 24)
                        xpmult = xpmult + stacksize
                    end
                end
                if chasni_checkifgroundedexists("chesspiece_hornucopia_stone") then
                    xpmult = xpmult * 2
                end
                if act.doer.prefab == "warly" then
                    xpmult = xpmult * 5
                end
                act.doer.components.levelsystem:xpDoDelta(xpmult, act.doer, false, true)
            end
        end

        local allachivcoin = act.doer.components.allachivcoin
        if allachivcoin and allachivcoin.cookfaster and stewer.task then
            local fn = stewer.task.fn
            stewer.task:Cancel()
            fn(act.target, stewer)
        end
    end
    return result
end

-- CC : add "honeymaster" achievement counter >> [Achievement] Work Harvest beebox
if TheNet:GetIsServer() then
    AddPrefabPostInit("beebox", function(inst)
        local old_onharvest = inst.components.harvestable.onharvestfn
        inst.components.harvestable:SetOnHarvestFn(function(inst, picker, produce, ...)
            if picker and picker.components.allachivevent and produce >= inst.components.harvestable.maxproduce then
                picker.components.allachivevent:CountAchievement(picker, "honeymaster")
            end
            return old_onharvest(inst, picker, produce, ...)
        end)
    end)
end

-- CC : add "jerkymaster" achievement counter >> [Achievement] Work Harvest drying rack
AddComponentPostInit("dryingrack", function(self)
    local _OnLoseItem = self.OnLoseItem
    self.OnLoseItem = function(self, item, slot, ...)
        if not item:HasTag("dryable") then
            local harvester, distsq = self.inst:GetNearestPlayer(true)
            if distsq and distsq < 10 and harvester and harvester.components.allachivevent then
                harvester.components.allachivevent:CountAchievement(harvester, "jerkymaster")
            end 
        end
        return _OnLoseItem(self, item, slot, ...)
    end
end)

-- CC : add "flowermaster" achievement counter >> [Achievement] Work Plant butterfly
if TheNet:GetIsServer() then
    AddPrefabPostInit("butterfly", function(inst)
        local old_ondeploy = inst.components.deployable.ondeploy
        inst.components.deployable.ondeploy = function(inst, pt, deployer, ...)
            if deployer and deployer.components.allachivevent then
                deployer.components.allachivevent:CountAchievement(deployer, "flowermaster")
            end
            return old_ondeploy(inst, pt, deployer, ...)
        end
    end)
end

-- CC : add "fertilize" achievement counter >> [Achievement] Work Fertilize
AddComponentPostInit("fertilizer", function(self)
    local _OnApplied = self.OnApplied
    self.OnApplied = function(self, doer, target, ...)
        _OnApplied(self, doer, target, ...)
        if doer and doer.components.allachivevent then
            doer.components.allachivevent:CountAchievement(doer, "fertilizemaster")
        end
    end
end)

-- CC : add "fertilize big tree" achievement counter >> [Achievement] Work Fertilize big tree
AddComponentPostInit("treegrowthsolution", function(self)
    local _GrowTarget = self.GrowTarget
    self.GrowTarget = function(self, target, ...)
        local doer = self.inst.components.inventoryitem:GetGrandOwner()
        local returnval = _GrowTarget(self, target, ...)
        if returnval and target and target.prefab == "oceantree" and doer and doer.components.allachivevent then
            doer.components.allachivevent:CountAchievement(doer, "fertilizebigmaster")
        end
        return returnval
    end
end)

-- CC : add "wallmaster" achievement counter >> [Achievement] Work Build and Upgrade Wall
if TheNet:GetIsServer() then
    AddPrefabPostInitAny(function(inst)
        if inst and inst:HasTag("wallbuilder") and string.sub(inst.prefab, 1, 5) == "wall_" then
            if inst.components.deployable then
                local old_ondeploy = inst.components.deployable.ondeploy
                inst.components.deployable.ondeploy = function(inst, pt, deployer, ...)
                    if deployer.components.allachivevent then
                        deployer.components.allachivevent:CountAchievement(deployer, "wallmaster")
                    end
                    if old_ondeploy then
                        old_ondeploy(inst, pt, deployer, ...)
                    end
                end
            end
        end
    end)
end
if TheNet:GetIsServer() then
    AddPrefabPostInitAny(function(inst)
        if inst and inst:HasTag("wall") and string.sub(inst.prefab, 1, 5) == "wall_" then
            if inst.components.repairable then
                local old_onrepaired = inst.components.repairable.onrepaired
                inst.components.repairable.onrepaired = function(inst, doer, repair_item, ...)
                    if doer.components.allachivevent then
                        doer.components.allachivevent:CountAchievement(doer, "wallmaster")
                    end
                    if old_onrepaired then
                        old_onrepaired(inst, doer, repair_item, ...)
                    end
                end
            end
        end
    end)
end

-- CC : add "tumbleweed" achievement counter >> [Achievement] Work Pick tumbleweed
if TheNet:GetIsServer() then
    AddPrefabPostInit("tumbleweed", function(inst)
        local old_onpicked = inst.components.pickable.onpickedfn
        inst.components.pickable.onpickedfn = function(inst, picker, ...)
            if picker and picker.components.allachivevent then
                picker.components.allachivevent:CountAchievement(picker, "picktumbleweed")
            end
            return old_onpicked(inst, picker, ...)
        end
    end)
end

-- CC : add "equipingkrampussack" achievement checker >> [Achievement] Have equipingkrampussack
if TheNet:GetIsServer() then
    AddPrefabPostInit("krampus_sack", function(inst)
        local _onequipfn = inst.components.equippable.onequipfn
        inst.components.equippable:SetOnEquip(function(inst, owner, ...)
            _onequipfn(inst, owner, ...)
            if owner.components.allachivevent then
                owner.components.allachivevent:CheckAchievement(owner, "equipingkrampussack")
            end
        end)
    end)
end

-- CC : add "daywalker" and "daywalker2" achievement checker >> [Achievement] Slay Werepigs
if TheNet:GetIsServer() then
    local function ModifyDaywalker(prefab, achname)
        AddPrefabPostInit(prefab, function(inst)
            local _MakeDefeated = inst.MakeDefeated
            inst.MakeDefeated = function(inst_, ...)
                local players = chasni_getassistplayers(inst_)
                for _, v in pairs(players) do
                    v.components.allachivevent[achname] = true
                    if v.components.allachivevent.werepigs1 and v.components.allachivevent.werepigs2 and not v.components.allachivevent.werepigs then
                        v.components.allachivevent:CheckAchievement(v, "werepigs")
                    end
                end
                return _MakeDefeated(inst_, ...)
            end
        end)
    end
    ModifyDaywalker("daywalker", "werepigs1")
    ModifyDaywalker("daywalker2", "werepigs2")
end

-- CC : add "pigkingtrading" achievement counter >> [Achievement] Trader
if TheNet:GetIsServer() then
    AddPrefabPostInit("pigking", function(self)
        local _OnGivenItem = self.components.trader.onaccept
        self.components.trader.onaccept = function(inst, giver, item, ...)
            if item.prefab:find("trinket", 1, true) ~= nil or cz_trinkets.modded_trinkets[item.prefab] then
                if giver.components.allachivevent then
                    giver.components.allachivevent:CountAchievement(giver, "pigkingtrading")
                end
            end
            return _OnGivenItem(inst, giver, item, ...)
        end
    end)
end

-- CC : add "icetrading" achievement counter >> [Achievement] Trader but Cold
if TheNet:GetIsServer() then
    local function addtradingcounter(inst)
        if inst.components.trader then
            local _onaccept = inst.components.trader.onaccept
            inst.components.trader.onaccept = function(inst, giver, item, ...)
                if item.components.weighable and item.components.weighable:GetWeightPercent() >= TUNING.WEIGHABLE_HEAVY_WEIGHT_PERCENT then
                    if giver.components.allachivevent then
                        giver.components.allachivevent:CountAchievement(giver, "icetrading")
                    end
                end
                return _onaccept and _onaccept(inst, giver, item, ...) or nil
            end
        end
    end

    AddPrefabPostInit("sharkboi", function(inst)
        local _MakeTrader = inst.MakeTrader
        inst.MakeTrader = function(inst, ...)
            local returnval = _MakeTrader and _MakeTrader(inst, ...) or nil
            addtradingcounter(inst)
            return returnval
        end
        addtradingcounter(inst)
    end)
end

-- CC : add "pearltrading" achievement counter >> [Achievement] She Sells Seashells
if TheNet:GetIsServer() then
    AddPrefabPostInit("hermitcrab", function(self)
        local _onaccept = self.components.trader.onaccept
        self.components.trader.onaccept = function(inst, giver, item, ...)
            if not item:HasTag("oceanfish") then
                if giver.components.allachivevent then
                    giver.components.allachivevent:CountAchievement(giver, "pearltrading")
                end
            end
            return _onaccept and _onaccept(inst, giver, item, ...) or nil
        end
    end)
end

-- CC : add "wagstafftrading" achievement counter >> [Achievement] Reliable Assistant
if TheNet:GetIsServer() then
    AddPrefabPostInit("wagstaff_npc", function(self)
        local _onaccept = self.components.trader.onaccept
        self.components.trader.onaccept = function(inst, giver, item, ...)
            if giver.components.allachivevent then
                giver.components.allachivevent:CountAchievement(giver, "wagstafftrading")
            end
            return _onaccept and _onaccept(inst, giver, item, ...) or nil
        end
    end)
end

-- CC : add checker of nearby floating player on start floating >> [Achievement] Talk Skinny Deep
AddComponentPostInit("playerfloater", function(self)
    local _AutoDeploy = self.AutoDeploy
    self.AutoDeploy = function(_self, player, ...)
        local returnval = _AutoDeploy(_self, player, ...)
        if player and player.components.allachivevent then
            local single = true
            local pos = Vector3(player.Transform:GetWorldPosition())
            local ents = FindPlayersInRange(pos.x,pos.y,pos.z, 15, true)
            for k,v in pairs(ents) do
                if v ~= player and v.sg and v.sg:HasStateTag("floating") and v.components.allachivevent then
                    v.components.allachivevent:CheckAchievement(v, "floatparty")
                    single = false
                end
            end
            if single == false then
                player.components.allachivevent:CheckAchievement(player, "floatparty")
            end
        end
        return returnval
    end
end)

-- CC : add checker of pearl on BathingPool:AddOccupant >> [Achievement] Talk Pool Party
AddComponentPostInit("bathingpool", function(self)
    local _AddOccupant = self.AddOccupant
    self.AddOccupant = function(_self, ent, ...)
        local returnval = _AddOccupant(self, ent, ...)
        if ent and ent.components.allachivevent then
            local havepearl = false
            local function CheckPearl(inst, _ent)
                if _ent and _ent.prefab == "hermitcrab" then
                    havepearl = true
                end
            end
            _self:ForEachOccupant(CheckPearl)
            if havepearl then
                ent.components.allachivevent:CheckAchievement(ent, "pearlparty")
            end
        elseif ent and ent.prefab == "hermitcrab" then
            local function CheckAchievement(inst, _ent)
                if _ent and _ent.components.allachivevent then
                    _ent.components.allachivevent:CheckAchievement(_ent, "pearlparty")
                end
            end
            _self:ForEachOccupant(CheckAchievement)
        end
        return returnval
    end
end)

-- CC : add "feedwebber" achievement counter >> [Achievement] Food Switcherdoodle
if TheNet:GetIsServer() then
    local function spiderinit(inst)
        inst:ListenForEvent("mutate", function(inst)
            if inst.mutator_giver then
                local feeder = inst.mutator_giver
                local newspider = inst.mutation_target
                feeder.components.allachivevent:RemoveListAchievement(feeder, "feedwebber", newspider)
            end
        end)
    end
    AddPrefabPostInit("spider", spiderinit)
    AddPrefabPostInit("spider_hider", spiderinit)
    AddPrefabPostInit("spider_warrior", spiderinit)
    AddPrefabPostInit("spider_spitter", spiderinit)
    AddPrefabPostInit("spider_dropper", spiderinit)
    AddPrefabPostInit("spider_moon", spiderinit)
    AddPrefabPostInit("spider_healer", spiderinit)
    AddPrefabPostInit("spider_water", spiderinit)
end

-- CC : add "bernie" achievement checker >> [Achievement] Transform Bernie
if TheNet:GetIsServer() then
    AddPrefabPostInit("bernie_active", function(inst)
        local oldGoBig = inst.GoBig
        inst.GoBig = function(inst, ...)
            if inst._leader == nil then
                local rangesq = 30 * 30
                local x, y, z = inst.Transform:GetWorldPosition()
                local my_platform = inst:GetCurrentPlatform()
                for i, v in ipairs(AllPlayers) do
                    if v.components.sanity:IsCrazy() and v.entity:IsVisible() and my_platform == v:GetCurrentPlatform() then
                        local distsq = v:GetDistanceSqToPoint(x, y, z)
                        if distsq < rangesq then
                            rangesq = distsq
                            inst._leader = v
                        end
                    end
                end
            end
            if inst._leader and inst._leader:GetDisplayName() then
                if inst._leader.components.allachivevent then
                    inst._leader.components.allachivevent:CheckAchievement(inst._leader, "bernie")
                end
            end
            oldGoBig(inst, ...)
        end
    end)
end

-- CC : add "dodgecharlie" achievement counter >> [Achievement] Dodge Charlie
if TheNet:GetIsServer() then
    AddPrefabPostInit("winona", function(inst)
        inst:ListenForEvent("resistedgrue", function(inst)
            if inst and inst.components.allachivevent then
                inst.components.allachivevent:CountAchievement(inst, "dodgecharlie")
            end
        end)
    end)
end

-- CC : add "vilewormwood" achievement counter >> [Achievement] Vile Wormwood
if TheNet:GetIsServer() then
    AddPrefabPostInit("wormwood", function(inst)
        inst:ListenForEvent("plantkilled", function(src, data)
            if data.doer then
                local distsq = inst:GetDistanceSqToPoint(data.pos)
                if distsq < 100 then
                    if data.doer and data.doer.components.allachivevent then
                        data.doer.components.allachivevent:CountAchievement(data.doer, "vilewormwood")
                    end
                end
            end
        end, TheWorld)
    end)
end

-- CC : add waterbaloon achievement counter >> [Achievement] Vile waterbaloon
if TheNet:GetIsServer() then
    AddPrefabPostInit("waterballoon", function(inst)
        if inst.components.complexprojectile then
            local old_onhitfn = inst.components.complexprojectile.onhitfn
            inst.components.complexprojectile:SetOnHit(function (_inst, attacker, target, ...)
                if attacker and attacker.components.allachivevent and not attacker.components.allachivevent.waterballoon then
                    if attacker:HasTag("player") then
                        local pos = Vector3(_inst.Transform:GetWorldPosition())
                        local ents = FindPlayersInRange(pos.x,pos.y,pos.z, 2, true)
                        for k,v in pairs(ents) do
                            if attacker and attacker.components.allachivevent then
                                attacker.components.allachivevent:CountAchievement(attacker, "waterballoon")
                            end
                        end
                    end
                end
                old_onhitfn(_inst, attacker, target, ...)
            end)
        end
    end)
end

-- CC : add "pipspook" achievement counter >> [Achievement] Misc Help Pipspook
if TheNet:GetIsServer() then
    AddPrefabPostInit("smallghost", function(inst)
        local oldPickupToy = inst.PickupToy
        inst.PickupToy = function(_inst, toy, ...)
            local pos = Vector3(toy.Transform:GetWorldPosition())
            local ents = FindPlayersInRange(pos.x,pos.y,pos.z, 15, true)
            for k,v in pairs(ents) do
                if v.prefab == "wendy" then
                    if v and v.components.allachivevent then
                        v.components.allachivevent:CountAchievement(v, "pipspook")
                    end
                end
            end
            oldPickupToy(_inst, toy, ...)
        end
    end)
end

-- CC : add "sewing" achievement checker >> [Achievement] Misc Sew things
AddComponentPostInit("sewing", function(self)
    local _DoSewing = self.DoSewing
    self.DoSewing = function(self, target, doer, ...)
        local returnval = _DoSewing(self, target, doer, ...)
        if returnval and doer and doer.components.allachivevent then
            doer.components.allachivevent:CheckAchievement(doer, "sewing")
        end
        return returnval
    end
end)

-- CC : add "sittable" achievement checker >> [Achievement] Misc Sit
AddComponentPostInit("sittable", function(self)
    local _SetOccupier = self.SetOccupier
    self.SetOccupier = function(self, occupier, ...)
        _SetOccupier(self, occupier, ...)
        if occupier and occupier.components.allachivevent then
            occupier.components.allachivevent:CheckAchievement(occupier, "sitting")
        end
    end
end)

-- CC : add "cotlfirepit" achievement checker >> [Achievement] Misc COTL
if TheNet:GetIsServer() then
    AddPrefabPostInit("rabbit", function(inst)
        local old_oncooked = inst.components.cookable.oncooked
        inst.components.cookable.oncooked = function(inst, cooker, chef, ...)
            old_oncooked(inst, cooker, chef, ...)
            if cooker and cooker.prefab == "cotl_tabernacle_level3" and chef and chef.components.allachivevent then
                chef.components.allachivevent:CheckAchievement(chef, "sacrificecotl")
            end
        end
    end)
end

-- CC : add "hitstagehand" achievement checker >> [Achievement] Misc COTL
if TheNet:GetIsServer() then
    AddPrefabPostInit("stagehand", function(inst)
        if inst.components.workable then
            local old_onwork = inst.components.workable.onwork
            inst.components.workable:SetOnWorkCallback(function(inst, worker, ...)
                if inst.sg and inst.sg.mem and worker and worker.components.allachivevent then
                    if inst.sg.mem.hits_left and inst.sg.mem.hits_left <= 1 and worker and worker.components.allachivevent then
                        worker.components.allachivevent:CheckAchievement(worker, "hitstagehand")
                    end
                end
                return old_onwork and old_onwork(inst, worker, ...) or nil
            end)
        end
    end)
end

-- CC : add "onputininventory" listener for Have achievement checker >> [Achievement] Have
local function OnPutInInventory(inst, owner, achievement_key, items)
    local allachiv = owner.components.allachivevent
    if allachiv and not allachiv[achievement_key] then
        local counts = {}
        local has_all = true

        for _, item in ipairs(items) do
            local has, count = owner.components.inventory:Has(item, ach_lists[achievement_key].current or 1)
            counts[#counts + 1] = count
            has_all = has_all and has
        end

        if ach_lists[achievement_key].current then
            local min_count = #counts > 0 and math.min(unpack(counts)) or 0
            allachiv[achievement_key .. "amount"] = math.min(min_count, ach_lists[achievement_key].current)
        end
        if has_all then
            allachiv:CheckAchievement(owner, achievement_key)
        end
    end
end

if TheNet:GetIsServer() then
    local function SetupPrefabHave(prefab, achievement_key, items)
        AddPrefabPostInit(prefab, function(inst)
            if inst.components.inventoryitem then
                local old_OnPutInInventoryFn = inst.components.inventoryitem.onputininventoryfn
                inst.components.inventoryitem:SetOnPutInInventoryFn(function(inst_, owner, ...)
                    local delay = achievement_key == "cursedtrinket" and 3 or 0
                    inst_:DoTaskInTime(delay, function()
                        OnPutInInventory(inst_, owner, achievement_key, items)
                    end)
                    if old_OnPutInInventoryFn then
                        return old_OnPutInInventoryFn(inst_, owner, ...)
                    end
                end)
            end
        end)
    end

    local spore_items = {"spore_small", "spore_medium", "spore_tall"}
    for _, item in ipairs(spore_items) do
        SetupPrefabHave(item, "spore", spore_items)
    end

    local cursed_items = {"cursed_monkey_token"}
    for _, item in ipairs(cursed_items) do
        SetupPrefabHave(item, "cursedtrinket", cursed_items)
    end

    local rabbit_items = {"rabbitking_lucky"}
    for _, item in ipairs(rabbit_items) do
        SetupPrefabHave(item, "luckyrabbit", rabbit_items)
    end
end

-- CC : add "darkheart" achievement counter >> [Achievement] HAVE Possessed Shadow Atrium
AddComponentPostInit("trap", function(self)
    local _Harvest = self.Harvest
    function self:Harvest(doer, ...)
        local allachiv = doer and doer.components.allachivevent
        if allachiv and allachiv.darkheart ~= true then
            if self.lootprefabs ~= nil then
                for i, v in ipairs(self.lootprefabs) do
                    if v == "shadowheart_infused" then
                        doer.components.allachivevent:CheckAchievement(doer, "darkheart")
                        break
                    end
                end
            end
        end
        return _Harvest(self, doer, ...)
    end
end)

-- CC : add "oceanfish" achievement counter >> [Achievement] HAVE Fish different oceanfish
AddComponentPostInit("oceanfishingrod", function(self)
    local _CatchFish = self.CatchFish
    function self:CatchFish(...)
        local allachivevent = self.fisher and self.fisher.components.allachivevent
        if allachivevent and allachivevent.oceanfish ~= true and self.target and self.target.components.oceanfishable then
            allachivevent:AddListAchievement(self.fisher, "oceanfish", self.target.prefab)
        end
        return _CatchFish(self, ...)
    end
end)

-- CC : add "havebird" achievement counter >> [Achievement] HAVE Bird different birds
AddComponentPostInit("occupiable", function(occupiable)
    local _Occupy = occupiable.Occupy
    function occupiable:Occupy(occupier, ...)
        local retval = _Occupy(self, occupier, ...)
        if occupier:HasTag("bird") and occupier.components.occupier and occupier.components.occupier:GetOwner() and occupier.components.occupier:GetOwner():HasTag("cage") then
            local player, distsq = self.inst:GetNearestPlayer(true)
            if distsq and distsq < 20 and player and player.components.allachivevent then
                player.components.allachivevent:RemoveListAchievement(player, "havebird", occupier.prefab)
            end
        end
        return retval
    end
end)

-- CC : add "aquarium" achievement checker >> [Achievement] Misc Functional Aquarium
if TheNet:GetIsServer() then
    AddPrefabPostInit("gelblob_storage", function(inst)
        if inst.components.inventoryitemholder then
            local old_onitemgivenfn = inst.components.inventoryitemholder.onitemgivenfn
            inst.components.inventoryitemholder:SetOnItemGivenFn(function(inst_, item, giver, ...)
                if giver and giver.components.allachivevent and item and ((item.prefab == "oceanfish_small_8_inv" and TheWorld.state.iswinter) or (item.prefab == "oceanfish_medium_8_inv" and TheWorld.state.issummer)) then
                    giver.components.allachivevent:CheckAchievement(giver, "aquarium")
                end
                if old_onitemgivenfn then
                    return old_onitemgivenfn(inst_, item, giver, ...)
                end
            end)
        end
    end)
end

-- CC : add "minemoon" achievement checker >> [Achievement] Misc Moon Mine
if TheNet:GetIsServer() then
    AddPlayerPostInit(function(inst)
        inst:ListenForEvent("finishedwork", function(_inst, data)
            if _inst.components.allachivevent and data.action == ACTIONS.MINE and data.target and data.target.prefab == "hotspring" then
                _inst.components.allachivevent:CountAchievement(_inst, "minemoon")
            end
        end)
    end)
end

