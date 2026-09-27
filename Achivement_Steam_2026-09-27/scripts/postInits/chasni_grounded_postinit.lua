local UpvalueHacker = require "functions/upvaluehacker"

-- CC : Add Chess Piece global effects >> [Perk] Global groundedscream
if not chasni_getperkexcludeconfig("groundedscream") then
    if TheNet:GetIsServer() then
        local STATUE_NAMES = { "pawn", "rook", "knight", "bishop", "muse", "formal", "hornucopia", "pipe", "deerclops", "bearger", "moosegoose", "dragonfly", "clayhound", "claywarg", "butterfly", "anchor", "moon", "carrat", "beefalo", "crabking", "malbatross", "toadstool", "stalker", "klaus", "beequeen", "antlion", "minotaur", "guardianphase3", "eyeofterror", "twinsofterror", "kitcoon", "catcoon", "manrabbit", "daywalker", "deerclops_mutated", "warg_mutated", "bearger_mutated", "yotd", "sharkboi", "wormboss", "daywalker2", "yots", "wagboss_robot", "wagboss_lunar", "yoth", "vault_pillar_guard", }
        local MATERIAL_NAMES = { "marble", "stone", "moonglass" }
        local function RegisterStatue(inst, prefabname)
            if TheWorld.components.groundedregistry == nil then
                TheWorld:AddComponent("groundedregistry")
            end
            inst._chasniprefabname = prefabname
            TheWorld.components.groundedregistry:Register(inst)
        end
        local function IsValidMaterialId(id)
            return type(id) == "number" and id >= 1 and id <= #MATERIAL_NAMES
        end
        for _, v in ipairs(STATUE_NAMES) do
            local base_prefab = "chesspiece_" .. v
            AddPrefabPostInit(base_prefab, function(inst)
                inst:DoTaskInTime(0, function()
                    if inst.materialid and IsValidMaterialId(inst.materialid) then
                        local mat_name = MATERIAL_NAMES[inst.materialid]
                        local full_name = base_prefab .. "_" .. mat_name
                        RegisterStatue(inst, full_name)
                    else
                        RegisterStatue(inst, base_prefab)
                    end
                end)
            end)

            for _, mat in ipairs({"marble", "stone", "moonglass"}) do
                local statue = base_prefab .. "_" .. mat
                AddPrefabPostInit(statue, function(inst)
                    inst:DoTaskInTime(0, function()
                        RegisterStatue(inst, statue)
                    end)
                end)
            end
        end
    end

    -- Triple oversized veggies lootdrop | Marble Carved Hornucopia
    AddComponentPostInit("lootdropper", function(lootdropper)
        local _DropLoot = lootdropper.DropLoot
        lootdropper.DropLoot = function(self, ...)
            if self.inst:HasTag("oversized_veggie") and chasni_checkifgroundedexists("chesspiece_hornucopia_marble") then
                _DropLoot(self, ...)
                _DropLoot(self, ...)
            end
            return _DropLoot(self, ...)
        end
    end)
    -- Double Stewer product | MoonGlass Carved Hornucopia
    local cooking = require("cooking")
    AddComponentPostInit("stewer", function(stewer)
        local _Harvest = stewer.Harvest
        stewer.Harvest = function(self, harvester, ...)
            if chasni_checkifgroundedexists("chesspiece_hornucopia_moonglass") then
                if self.product ~= nil then
                    local loot = SpawnPrefab(self.product)
                    if loot ~= nil then
                        local recipe = cooking.GetRecipe(self.inst.prefab, self.product)
                        local stacksize = recipe and recipe.stacksize or 1
                        if stacksize > 1 then
                            loot.components.stackable:SetStackSize(stacksize)
                        end

                        if self.spoiltime ~= nil and loot.components.perishable ~= nil then
                            local spoilpercent = self:GetTimeToSpoil() / self.spoiltime
                            loot.components.perishable:SetPercent(self.product_spoilage * spoilpercent)
                            loot.components.perishable:StartPerishing()
                        end
                        if harvester ~= nil and harvester.components.inventory ~= nil then
                            harvester.components.inventory:GiveItem(loot, nil, self.inst:GetPosition())
                        else
                            LaunchAt(loot, self.inst, nil, 1, 1)
                        end
                    end
                end
            end
            return _Harvest(self, harvester, ...)
        end
    end)

    -- Give XP when trading trinket with pig king | Stone Bubble Pipe Carving
    if TheNet:GetIsServer() then
        AddPrefabPostInit("pigking", function(self)
            local _OnGivenItem = self.components.trader.onaccept
            self.components.trader.onaccept = function(inst, giver, item, ...)
                if (item.prefab:find("trinket", 1, true) ~= nil or cz_trinkets.modded_trinkets[item.prefab]) and chasni_checkifgroundedexists("chesspiece_pipe_stone") then
                    if item.components.tradable and item.components.tradable.goldvalue > 0 and giver.components.levelsystem then
                        giver.components.levelsystem:xpDoDelta(item.components.tradable.goldvalue, giver, false, true)
                    end
                end
                return _OnGivenItem(inst, giver, item, ...)
            end
        end)
    end
    -- 20% Spawn random trinket when digging tree | Marble Bubble Pipe Carving
    if TheNet:GetIsServer() then
        AddPlayerPostInit(function(inst)
            inst:ListenForEvent("finishedwork", function(_inst, data)
                if data.action == ACTIONS.DIG and data.target:HasTag("stump") and chasni_checkifgroundedexists("chesspiece_pipe_marble") and math.random() < 0.2 then
                    chasni_giveItem(inst, PickRandomTrinket(), 1)
                end
            end)
        end)
    end

    -- Drown immunity | Stone Anchor Figure
    AddComponentPostInit("drownable", function(drownable)
        local _GetDrowningDamageTuning = drownable.GetDrowningDamageTuning
        drownable.GetDrowningDamageTuning = function(self, ...)
            if self.inst and self.inst:HasTag("player") and chasni_checkifgroundedexists("chesspiece_anchor_stone") then
                return  {}
            end
            return _GetDrowningDamageTuning(self, ...)
        end
    end)
    -- Boat immunity | Marble Anchor Figure
    AddComponentPostInit("hullhealth", function(hullhealth)
        local _GetDamageMult = hullhealth.GetDamageMult
        hullhealth.GetDamageMult = function(self, cat, ...)
            if self.inst and self.inst.prefab and chasni_checkifgroundedexists("chesspiece_anchor_marble") and cat == "collide" then
                if PrefabExists(self.inst.prefab.."_item_placer") then
                    return 0
                end
            end
            return _GetDamageMult and _GetDamageMult(self, cat, ...)
        end
    end)
    -- Dock immunity | MoonGlass Anchor Figure
    AddComponentPostInit("dockmanager", function(dockmanager)
        local _DamageDockAtTile = dockmanager.DamageDockAtTile
        dockmanager.DamageDockAtTile = function(self, tx, ty, damage, ...)
            if damage and damage > 0 and chasni_checkifgroundedexists("chesspiece_anchor_moonglass") then
                damage = 0
            end
            return _DamageDockAtTile(self, tx, ty, damage, ...)
        end
    end)

    -- Double follower loyalty, Give follower damagemult and damagetaken reduction | Stone + Marble + MoonGlass Pawn Figure
    AddComponentPostInit("follower", function(follower)
        local _AddLoyaltyTime = follower.AddLoyaltyTime
        follower.AddLoyaltyTime = function(self, time, ...)
            if self.leader and self.leader:HasTag("player") and chasni_checkifgroundedexists("chesspiece_pawn_stone") then
                time = time * 2
            end
            return _AddLoyaltyTime(self, time, ...)
        end

        local _SetLeader = follower.SetLeader
        follower.SetLeader = function(self, ...)
            local retval = _SetLeader(self, ...)
            if self.inst and self.inst.components.combat then
                if self.leader and self.leader:HasTag("player") and chasni_checkifgroundedexists("chesspiece_pawn_marble") then
                    self.inst.components.combat.externaldamagemultipliers:SetModifier("chesspiece_pawn_marble", 1.5)
                else
                    self.inst.components.combat.externaldamagemultipliers:RemoveModifier("chesspiece_pawn_marble")
                end
                if self.leader and self.leader:HasTag("player") and chasni_checkifgroundedexists("chesspiece_pawn_moonglass") then
                    self.inst.components.combat.externaldamagetakenmultipliers:SetModifier("chesspiece_pawn_moonglass", 0.5)
                else
                    self.inst.components.combat.externaldamagetakenmultipliers:RemoveModifier("chesspiece_pawn_moonglass")
                end
            end
            return retval
        end
    end)

    -- Give xp on build wall | Marble Rook Figure
    if TheNet:GetIsServer() then
        AddPrefabPostInitAny(function(inst)
            if inst and inst:HasTag("wallbuilder") and string.sub(inst.prefab, 1, 5) == "wall_" then
                if inst.components.deployable then
                    local old_ondeploy = inst.components.deployable.ondeploy
                    inst.components.deployable.ondeploy = function(_inst, pt, deployer, ...)
                        if deployer.components.levelsystem and chasni_checkifgroundedexists("chesspiece_rook_marble") then
                            deployer.components.levelsystem:xpDoDelta(5, deployer)
                        end
                        if old_ondeploy then
                            return old_ondeploy(_inst, pt, deployer, ...)
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
                    inst.components.repairable.onrepaired = function(_inst, doer, repair_item, ...)
                        if doer.components.levelsystem and chasni_checkifgroundedexists("chesspiece_rook_marble") then
                            doer.components.levelsystem:xpDoDelta(5, doer)
                        end
                        if old_onrepaired then
                            return old_onrepaired(_inst, doer, repair_item, ...)
                        end
                    end
                end
            end
        end)
    end
    -- Wall untargetable for attack | MoonGlass Rook Figure
    AddComponentPostInit("combat", function(combat)
        local _ShouldAggro = combat.ShouldAggro
        combat.ShouldAggro = function(self, target, ...)
            if self.inst and not self.inst:HasTag("player") and target and target:HasTag("wall") and chasni_checkifgroundedexists("chesspiece_rook_moonglass") then
                return false
            end
            return _ShouldAggro(self, target, ...)
        end
        local _CanAttack = combat.CanAttack
        combat.CanAttack = function(self, target, ...)
            if self.inst and not self.inst:HasTag("player") and target and target:HasTag("wall") and chasni_checkifgroundedexists("chesspiece_rook_moonglass") then
                return false
            end
            return _CanAttack(self, target, ...)
        end
    end)

    -- Gain XP equal to armor absorption | Marble Knight Figure
    AddComponentPostInit("armor", function(self)
        self.inst:ListenForEvent("armordamaged", function(armor, damage_amount)
            if chasni_checkifgroundedexists("chesspiece_knight_marble") then
                local owner = armor and armor.components.inventoryitem and armor.components.inventoryitem:GetGrandOwner()
                if owner and owner:HasTag("player") and owner.components.levelsystem then
                    owner.components.levelsystem:xpDoDelta(damage_amount * 0.1, owner)
                end
            end
        end)
    end)
    -- Reduce "armor" durability loss on TakeDamge | MoonGlass Knight Figure
    AddComponentPostInit("armor", function(Armor)
        local OldTakeDamage = Armor.TakeDamage
        Armor.TakeDamage = function(self, damage_amount, ...)
            if chasni_checkifgroundedexists("chesspiece_knight_moonglass") then
                local owner = self.inst and self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner()
                if owner and owner:HasTag("player") then
                    damage_amount = damage_amount * 0.5
                end
            end
            return OldTakeDamage(self, damage_amount, ...)
        end
    end)
    -- reduce electrocuted duration | Marble Bishop Figure
    local _CalcEntityElectrocuteDuration = CalcEntityElectrocuteDuration
    GLOBAL.CalcEntityElectrocuteDuration = function(inst, ...)
        local mult = 1
        if inst and inst:HasTag("player") and chasni_checkifgroundedexists("chesspiece_bishop_marble") then
            mult = 0.5
        end
        return (_CalcEntityElectrocuteDuration(inst, ...) * mult)
    end
    -- chance to resist electrocuted | MoonGlass Bishop Figure
    local _CanEntityBeElectrocuted = CanEntityBeElectrocuted
    GLOBAL.CanEntityBeElectrocuted = function(inst, ...)
        if inst and inst:HasTag("player") and chasni_checkifgroundedexists("chesspiece_bishop_moonglass") and math.random() < 0.25 then
            return false
        end
        return _CanEntityBeElectrocuted(inst, ...)
    end

    -- 80% grue damage resist | Stone Queenly Figure
    AddComponentPostInit("grue", function(grue)
        local OldAttack = grue.Attack
        grue.Attack = function(self, ...)
            if chasni_checkifgroundedexists("chesspiece_muse_stone") and math.random() < 0.8 then
                return nil
            end
            return OldAttack(self, ...)
        end
    end)
    -- reset touchstone on newmoon | Marble Queenly Figure
    AddComponentPostInit("touchstonetracker", function(self)
        function self:Chasni_ResetUsed()
            self.used = {}
            self.used_foreign = {}

            if self.inst.player_classified ~= nil then
                self.inst.player_classified:SetUsedTouchStones({})
            end
        end
    end)
    if TheNet:GetIsServer() then
        AddPrefabPostInit("world", function(inst)
            inst:WatchWorldState("isnewmoon", function(world, isnewmoon)
                if isnewmoon then
                    if chasni_checkifgroundedexists("chesspiece_muse_marble") then
                        for _, player in ipairs(AllPlayers) do
                            if player and player.components.touchstonetracker then
                                player.components.touchstonetracker:Chasni_ResetUsed()
                            end
                        end
                    end
                end
            end)
        end)
    end
    -- reset grave on new moon | MoonGlass Queenly Figure
    if TheNet:GetIsServer() then
        AddPrefabPostInit("mound", function(inst)
            local prefab = GLOBAL.Prefabs.mound
            if prefab then
                inst._original_onfinish = UpvalueHacker.GetUpvalue(prefab.fn, "onfinishcallback")
            end
            inst:WatchWorldState("isnewmoon", function(world, isnewmoon)
                if isnewmoon then
                    if chasni_checkifgroundedexists("chesspiece_muse_moonglass") then
                        if inst.components.workable == nil then
                            inst:AddComponent("workable")
                            inst.components.workable:SetWorkAction(ACTIONS.DIG)
                            inst.components.workable:SetWorkLeft(1)

                            if inst._original_onfinish then
                                inst.components.workable:SetOnFinishCallback(inst._original_onfinish)
                            end

                            inst.AnimState:PlayAnimation("gravedirt")
                        end
                    end
                end
            end)
        end)
    end

    -- Triple sanity reward gained | Marble Kingly Figure
    if TheNet:GetIsServer() then
        AddPrefabPostInitAny(function(inst)
            if inst.sanityreward and inst.sanityreward > 0 and inst:HasTag("shadowcreature") then
                local _onkilledbyother = inst.components.combat.onkilledbyother
                inst.components.combat.onkilledbyother = function(_inst, attacker, ...)
                    if attacker and attacker.components.sanity and _inst.sanityreward and _inst.sanityreward > 0 and chasni_checkifgroundedexists("chesspiece_formal_marble") then
                        attacker.components.sanity:DoDelta(_inst.sanityreward * 2)
                    end
                    return _onkilledbyother and _onkilledbyother(_inst, attacker, ...)
                end
            end
        end)
    end
    -- Full shadowcreature visibility | MoonGlass Kingly Figure
    if not TheNet:IsDedicated() then
        AddComponentPostInit("transparentonsanity", function(transparentonsanity, inst)
            local OldCalcaulteTargetAlpha = transparentonsanity.CalcaulteTargetAlpha
            transparentonsanity.CalcaulteTargetAlpha = function(self, ...)
                if self.inst and self.inst:HasTag("shadowcreature") and chasni_checkifgroundedexists("chesspiece_formal_moonglass") then
                    return self.most_alpha or 1
                end
                return OldCalcaulteTargetAlpha(self, ...)
            end
        end)
    end

    -- moon moth spawner | Stone Moon Moth Figure
    if TheNet:GetIsServer() then
        AddPrefabPostInit("world", function(inst)
            if inst.components.chasnimoonbutterflyspawner == nil then
                inst:AddComponent("chasnimoonbutterflyspawner")
            end
        end)
    end
    if TheNet:GetIsServer() then
        AddPrefabPostInit("moonbutterfly", function(inst)
            local spawner = TheWorld.components.chasnimoonbutterflyspawner
            if spawner == nil then
                return
            end
            inst.chasnimoonbutterflyspawner = spawner
            if inst.components.inventoryitem then
                local _onputininventoryfn = inst.components.inventoryitem.onputininventoryfn
                inst.components.inventoryitem:SetOnPutInInventoryFn(function(...)
                    if inst.chasnimoonbutterflyspawner then
                        inst.chasnimoonbutterflyspawner:StopTracking(inst)
                    end
                    return _onputininventoryfn and _onputininventoryfn(...)
                end)
            end
            if inst.components.workable then
                local _onfinish = inst.components.workable.onfinish
                inst.components.workable:SetOnFinishCallback(function(...)
                    if inst.chasnimoonbutterflyspawner then
                        inst.chasnimoonbutterflyspawner:StopTracking(inst)
                    end
                    return _onfinish and _onfinish(...)
                end)
            end
            inst:ListenForEvent("ondropped", function()
                if inst.chasnimoonbutterflyspawner then
                    inst.chasnimoonbutterflyspawner:StartTracking(inst)
                end
            end)
            inst:ListenForEvent("onremove", function()
                if inst.chasnimoonbutterflyspawner then
                    inst.chasnimoonbutterflyspawner:StopTracking(inst)
                end
            end)
            if not (inst.components.inventoryitem and inst.components.inventoryitem.owner) then
                spawner:StartTracking(inst)
            end
        end)
    end
    -- triple health regen when soaking in hotspring | Marble Moon Moth Figure
    AddComponentPostInit("health", function(health)
        local oldDoDelta = health.DoDelta
        function health:DoDelta(amount, overtime, cause, ignore_invincible, ...)
            if cause and cause == "hotspring" and chasni_checkifgroundedexists("chesspiece_butterfly_marble") then
                amount = amount * 3
            end
            return oldDoDelta(self, amount, overtime, cause, ignore_invincible, ...)
        end
    end)
    -- add driftwood_log for moontree_tall loot | MoonGlass Moon Moth Figure
    AddComponentPostInit("lootdropper", function(self)
        local oldGenerateLoot = self.GenerateLoot
        function self:GenerateLoot(...)
            local loots = oldGenerateLoot(self, ...)
            if self.chanceloottable == "moontree_tall" and chasni_checkifgroundedexists("chesspiece_butterfly_moonglass") then
                for i = 1, 3 do
                    if math.random() < 0.5 then
                        table.insert(loots, "driftwood_log")
                    end
                end
            end
            return loots
        end
    end)

    -- add moonrocknugget for boulder loot | Stone "Moon" Figure
    AddComponentPostInit("lootdropper", function(self)
        local oldGenerateLoot = self.GenerateLoot
        function self:GenerateLoot(...)
            local loots = oldGenerateLoot(self, ...)
            if self.inst and self.inst:HasTag("boulder") and chasni_checkifgroundedexists("chesspiece_moon_stone") then
                for i = 1, 3 do
                    if math.random() < 0.5 then
                        table.insert(loots, "moonrocknugget")
                    end
                end
            end
            return loots
        end
    end)
    -- force plant grow on fullmoon | MoonGlass "Moon" Figure
    if TheNet:GetIsServer() then
        local GROW_CHANCE = 0.2 local function forcePlantGrowth(ent)
            if not ent or not ent:IsValid() or ent:IsInLimbo() then
                return false
            end
            if ent.components.witherable and ent.components.witherable:IsWithered() then
                return false
            end
            if ent.components.growable then
                local growable = ent.components.growable
                if (ent:HasTag("tree") or ent:HasTag("winter_tree")) and not ent:HasTag("stump") then
                    if ent.components.simplemagicgrower then
                        ent.components.simplemagicgrower:StartGrowing()
                        return true
                    elseif growable.domagicgrowthfn then
                        growable:DoMagicGrowth()
                        return true
                    else
                        return growable:DoGrowth()
                    end
                end
            end
            if ent.components.pickable then
                local pickable = ent.components.pickable
                if pickable.FinishGrowing then
                    pickable:FinishGrowing()
                    if pickable.ConsumeCycles then
                        pickable:ConsumeCycles(1)
                    end
                    return true
                end
            end
            if ent.components.crop then
                local crop = ent.components.crop
                if crop.rate and crop.rate > 0 then
                    return crop:DoGrow(1 / crop.rate, true)
                end
            end
            if ent.components.harvestable then
                local harvestable = ent.components.harvestable
                if ent:HasTag("mushroom_farm") then
                    if harvestable.IsMagicGrowable and harvestable:IsMagicGrowable() then
                        harvestable:DoMagicGrowth()
                        return true
                    elseif harvestable.Grow then
                        return harvestable:Grow()
                    end
                end
            end
            return false
        end
        local function addFullMoonListener(self)
            local inst = self.inst
            if inst._fullmoon_growth_listener then
                return
            end
            inst._fullmoon_growth_listener = true

            inst:WatchWorldState("isfullmoon", function(world, isfullmoon)
                if isfullmoon and chasni_checkifgroundedexists("chesspiece_moon_moonglass") then
                    if math.random() <= GROW_CHANCE then
                        forcePlantGrowth(inst) 
                    end
                end
            end)
        end
        AddComponentPostInit("pickable", function(self, inst)
            addFullMoonListener(self, inst)
        end)
        AddComponentPostInit("growable", function(self, inst)
            addFullMoonListener(self, inst)
        end)
        AddComponentPostInit("crop", function(self, inst)
            addFullMoonListener(self, inst)
        end)
        AddComponentPostInit("harvestable", function(self, inst)
            addFullMoonListener(self, inst)
        end)
    end

    -- add tag to hunted for damagemult | Stone Varg Figure
    if TheNet:GetIsServer() then
        AddPrefabPostInitAny(function(inst)
            if chasni_checkifgroundedexists("chesspiece_claywarg_stone") then
                inst:ListenForEvent("spawnedforhunt", function()
                    inst:AddTag("cz_spawnedforhunt")
                end)
            end
        end)
    end
    -- increase hunter max count | Marble Varg Figure
    if TheNet:GetIsServer() then
        local function addhunterpostinit(comp)
            AddComponentPostInit(comp, function(self, inst)
                local old_GetMaxHunts = UpvalueHacker.GetUpvalue(self.OnDirtInvestigated, "GetMaxHunts")
                if not old_GetMaxHunts then
                    return
                end

                local function new_GetMaxHunts()
                    local base = old_GetMaxHunts()
                    if chasni_checkifgroundedexists("chesspiece_claywarg_marble") then
                        return base * 2
                    end
                    return base
                end
                UpvalueHacker.SetUpvalue(self.OnDirtInvestigated, new_GetMaxHunts, "GetMaxHunts")
            end)
        end
        addhunterpostinit("hunter")
        addhunterpostinit("bosshunter")
    end
    -- reduce hounded intensity by 3x | MoonGlass Hound Figure & Gilded Depths Worm Figure
    if TheNet:GetIsServer() then
        AddComponentPostInit("hounded", function(self, inst)
            local ref_func = self.OnSave
            if not ref_func then
                return
            end
            local old_attackdelayfn = UpvalueHacker.GetUpvalue(ref_func, "_attackdelayfn")
            if old_attackdelayfn then
                local function new_attackdelayfn()
                    local base, variance = old_attackdelayfn()
                    if not TheWorld:HasTag("cave") and chasni_checkifgroundedexists("chesspiece_clayhound_moonglass") then
                        base = base * 5
                    end
                    if TheWorld:HasTag("cave") and chasni_checkifgroundedexists("chesspiece_yots_moonglass") then
                        base = base * 5
                    end
                    return base, variance
                end
                UpvalueHacker.SetUpvalue(ref_func, new_attackdelayfn, "_attackdelayfn")
            end
        end)
    end

    -- cashback when cooking carrot | Marble Carrat Figure
    if TheNet:GetIsServer() then
        AddComponentPostInit("stewer", function(self, inst)
            local oldStartCooking = self.StartCooking
            function self:StartCooking(doer, ...)
                local retval = oldStartCooking(self, doer, ...)
                if doer and chasni_checkifgroundedexists("chesspiece_carrat_marble") then
                    local carrotcount = 0
                    if self.ingredient_prefabs then
                        for k,v in pairs(self.ingredient_prefabs) do
                            if v == "carrot" then
                                carrotcount = carrotcount + 1
                            end
                        end
                    end
                    if carrotcount > 1 then
                        chasni_giveItem(doer, "carrot", math.random(1, carrotcount-1))
                    end
                end
                return retval
            end
        end)
    end
    -- planted carrot regrow 4x as fast | MoonGlass Carrat Figure
    if TheNet:GetIsServer() then
        AddComponentPostInit("regrowthmanager", function(self, inst)
            local ref_func = self.SetRegrowthForType
            if not ref_func then return end

            local regrowthvalues = UpvalueHacker.GetUpvalue(ref_func, "_regrowthvalues")
            if not regrowthvalues then return end

            local carrot_data = regrowthvalues["carrot_planted"]
            if not carrot_data then return end

            local original_timemult = carrot_data.timemult

            carrot_data.timemult = function()
                local base = original_timemult and original_timemult() or 1
                if chasni_checkifgroundedexists("chesspiece_carrat_moonglass") then
                    return base * 5
                end
                return base
            end
        end)
    end

    -- beefalo not target player when in heat | Marble Beefalo Figure
    if TheNet:GetIsServer() then
        AddPrefabPostInit("beefalo", function(inst)
            local retarget_fn = inst.components.combat.retargetfn
            if not retarget_fn then return end

            local cant_tags = UpvalueHacker.GetUpvalue(retarget_fn, "RETARGET_CANT_TAGS")
            if cant_tags and not table.contains(cant_tags, "cz_chesspiece_beefalo_marble") then
                table.insert(cant_tags, "cz_chesspiece_beefalo_marble")
            end
        end)
    end
    -- 5x health regen for beefalo with rider | MoonGlass Beefalo Figure
    AddComponentPostInit("health", function(health)
        local oldDoDelta = health.DoDelta
        function health:DoDelta(amount, overtime, cause, ignore_invincible, ...)
            if self.inst and self.inst:HasTag("beefalo") and self.inst.components.rideable and self.inst.components.rideable:IsBeingRidden() and cause and cause == "regen" and chasni_checkifgroundedexists("chesspiece_beefalo_moonglass") then
                amount = amount * 5
            end
            return oldDoDelta(self, amount, overtime, cause, ignore_invincible, ...)
        end
    end)

    -- feed critter give stats to owner | Stone Kitcoon Figure
    if TheNet:GetIsServer() then
        AddPrefabPostInitAny(function(inst)
            if inst:HasTag("critter") then
                inst:ListenForEvent("oneat", function(_inst, data)
                    if chasni_checkifgroundedexists("chesspiece_kitcoon_stone") then
                        local leader = _inst.components.follower and _inst.components.follower:GetLeader()
                        local food = data.food
                        if food and data.feeder and data.feeder:HasTag("player") and leader and leader:HasTag("player") then
                            local health_delta = food.components.edible:GetHealth(leader)
                            local hunger_delta = food.components.edible:GetHunger(leader)
                            local sanity_delta = food.components.edible:GetSanity(leader)
                            if health_delta > 0 and leader.components.health then
                                leader.components.health:DoDelta(health_delta)
                            end
                            if hunger_delta > 0 and leader.components.hunger then
                                leader.components.hunger:DoDelta(hunger_delta)
                            end
                            if sanity_delta > 0 and leader.components.sanity then
                                leader.components.sanity:DoDelta(sanity_delta)
                            end
                        end
                    end
                end)
            end
        end)
    end
    -- cashback when adopt critter | Marble Kitcoon Figure
    if TheNet:GetIsServer() then
        AddPlayerPostInit(function(inst)
            local function onitemcrafted(_inst, data)
                if chasni_checkifgroundedexists("chesspiece_kitcoon_marble") then
                    if data and data.recipe and data.recipe.ingredients and _inst.components.inventory and data.recipe.name and string.find(data.recipe.name, "^critter_.*_builder$") then
                        local choices = {}
                        for _, ingredient in ipairs(data.recipe.ingredients) do
                            if ingredient.type ~= CHARACTER_INGREDIENT.HEALTH and ingredient.type ~= CHARACTER_INGREDIENT.SANITY and not ingredient.deconstruct and ingredient.amount > 0 then
                                choices[ingredient.type] = ingredient.amount
                            end
                        end
                        local cashback_item = next(choices) and weighted_random_choice(choices) or nil
                        if cashback_item then
                            chasni_giveItem(inst, cashback_item, 1)
                        end
                    end
                end
            end

            inst:ListenForEvent("builditem", onitemcrafted)
            inst:ListenForEvent("buildstructure", onitemcrafted)
        end)
    end
    -- 2x rate and double puke catcoon | Stone Catcoon Figure
    AddStategraphPostInit("catcoon", function(sg)
        local hairballState = sg.states["hairball"]
        if not hairballState then return end

        local oldOnExit = hairballState.onexit
        hairballState.onexit = function(inst)
            if chasni_checkifgroundedexists("chesspiece_catcoon_stone") then
                if not inst._doublepuke then
                    if inst.hairball_friend_interval and inst.hairball_friend_interval > 0 then
                        inst.hairball_friend_interval = 1
                    end
                    if inst.hairball_neutral_interval and inst.hairball_neutral_interval > 0 then
                        inst.hairball_neutral_interval = 1
                    end
                    inst._doublepuke = true
                else
                    if inst.hairball_friend_interval and inst.hairball_friend_interval > 0 then
                        inst.hairball_friend_interval = inst.hairball_friend_interval * 0.25
                    end
                    if inst.hairball_neutral_interval and inst.hairball_neutral_interval > 0 then
                        inst.hairball_neutral_interval = inst.hairball_neutral_interval * 0.25
                    end

                    inst._doublepuke = nil
                end
            end

            if oldOnExit then return oldOnExit(inst) end
        end
    end)
    -- chance to spawn Koi when spawning fishes | Marble Catcoon Figure
    if TheNet:GetIsServer() then
        AddComponentPostInit("schoolspawner", function(self, inst)
            local ref_func = self.SpawnSchool
            if not ref_func then
                return
            end

            local function get_upvalue(name)
                return UpvalueHacker.GetUpvalue(ref_func, name)
            end

            local GetOceanTrawlerChanceModifier = get_upvalue("GetOceanTrawlerChanceModifier")
            local testforgnarwail = get_upvalue("testforgnarwail")
            local testforshark = get_upvalue("testforshark")
            local DoSpawnFish = get_upvalue("DoSpawnFish")

            local FISH_DATA = require("prefabs/oceanfishdef")

            function self:ForceSpawnFish(schooltype, spawnpoint, target, override_spawn_offset)
                if not spawnpoint or not schooltype then
                    return 0
                end

                local schooldata = FISH_DATA.fish[schooltype]
                if not schooldata then
                    return 0
                end

                local herd = SpawnPrefab("schoolherd_" .. schooldata.prefab)
                if not herd then
                    return 0
                end
                herd.Transform:SetPosition(spawnpoint:Get())

                local schoolsize = math.random(schooldata.schoolmin, schooldata.schoolmax)
                local rotation = math.random() * 360

                local school_rand_angle = math.random() * 360
                local school_spawnpoint = spawnpoint + (override_spawn_offset
                        or FindSwimmableOffset(spawnpoint, school_rand_angle, 20, 12, nil, nil, nil, true)
                        or FindSwimmableOffset(spawnpoint, school_rand_angle, 13, 12, nil, nil, nil, true)
                        or FindSwimmableOffset(spawnpoint, school_rand_angle, 7, 12, nil, nil, nil, true)
                        or Vector3(0, 0, 0))

                local count = 0
                for i = 1, schoolsize do
                    local radius = math.sqrt(math.random()) * schooldata.schoolrange
                    local angle = math.random() * 360

                    local offset = FindSwimmableOffset(school_spawnpoint, angle, radius, 12, true, nil, nil, true)
                    if offset then
                        if count == 0 then
                            DoSpawnFish(schooldata.prefab, school_spawnpoint + offset, rotation, herd)
                        else
                            inst:DoTaskInTime(0.1 + math.random() * 1, function()
                                DoSpawnFish(schooldata.prefab, school_spawnpoint + offset, rotation, herd)
                            end)
                        end
                        count = count + 1
                    end
                end

                if count > 0 then
                    SpawnPrefab("fishschoolspawnblocker").Transform:SetPosition(spawnpoint:Get())

                    inst:PushEvent("schoolspawned", { spawnpoint = spawnpoint })

                    local tile_at_spawnpoint = TheWorld.Map:GetTileAtPoint(spawnpoint:Get())
                    if tile_at_spawnpoint == WORLD_TILES.OCEAN_SWELL or tile_at_spawnpoint == WORLD_TILES.OCEAN_ROUGH then
                        local oceantrawlerchancemodifier = GetOceanTrawlerChanceModifier(spawnpoint)
                        if testforgnarwail then
                            testforgnarwail(self, spawnpoint, oceantrawlerchancemodifier, target)
                        end
                        if testforshark then
                            testforshark(self, spawnpoint, oceantrawlerchancemodifier, target)
                        end
                    end
                else
                    herd:Remove()
                    herd = nil
                end

                return count
            end

            local oldSpawnSchool = self.SpawnSchool
            function self:SpawnSchool(...)
                local retval = oldSpawnSchool(self, ...)
                if retval and retval > 0 then
                    if chasni_checkifgroundedexists("chesspiece_catcoon_marble") and math.random() < 0.5 then
                        local fishprefab = math.random() < 0.5 and "oceanfish_medium_6" or "oceanfish_medium_7"
                        self:ForceSpawnFish(fishprefab, ...)
                    end
                end
                return retval
            end
        end)
    end
    -- + (1-P)/2 bird spawn seeds chance | MoonGlass Catcoon Figure
    AddStategraphPostInit("bird", function(sg)
        if sg.states.flyaway and sg.states.flyaway.onenter then
            local old_onenter = sg.states.flyaway.onenter
            sg.states.flyaway.onenter = function(inst)
                old_onenter(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                local found_seeds = false
                local entities = TheSim:FindEntities(x, y, z, 1)
                for _, ent in ipairs(entities) do
                    if ent.prefab == "seeds" then
                        found_seeds = true
                        break
                    end
                end
                if not found_seeds and inst.components.periodicspawner and chasni_checkifgroundedexists("chesspiece_catcoon_moonglass") and math.random() < 0.5 then
                    inst.components.periodicspawner:TrySpawn()
                end
            end
        end
    end)

    -- add hidemeats check | Stone Bunnyman Figure
    AddComponentPostInit("inventory", function(self)
        local _EquipHasTag = self.EquipHasTag
        self.EquipHasTag = function(_self, tag, ...)
            if tag == "hidesmeats" and _self.inst and _self.inst:HasTag("player") and chasni_checkifgroundedexists("chesspiece_manrabbit_stone") then
                return true
            end
            return _EquipHasTag(_self, tag, ...)
        end
    end)
    -- can sleep in rabbithouse | MoonGlass Bunnyman Figure
    local COMPONENT_ACTIONS = UpvalueHacker.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
    local SCENE = COMPONENT_ACTIONS.SCENE
    local Scene_sleepingbag = SCENE.sleepingbag
    function SCENE.sleepingbag(inst, doer, actions, ...)
        if inst.prefab == "rabbithouse" and not doer:HasTag("cz_chesspiece_manrabbit_moonglass") then
            return
        end
        Scene_sleepingbag(inst, doer, actions, ...)
    end
    if TheNet:GetIsServer() then
        AddPrefabPostInit("rabbithouse", function(inst)
            inst:AddTag("tent")
            if inst.components.sleepingbag == nil then
                inst:AddComponent("sleepingbag")
            end
            inst.components.sleepingbag.health_tick = TUNING.SLEEP_HEALTH_PER_TICK
            inst.components.sleepingbag.sanity_tick = TUNING.SLEEP_SANITY_PER_TICK
            inst.components.sleepingbag.hunger_tick = TUNING.SLEEP_HUNGER_PER_TICK
        end)
    end

    -- 50% speedmult and damagemult when burning | Stone Marble Start Tower Figure
    if TheNet:GetIsServer() then
        AddPlayerPostInit(function(inst)
            inst:ListenForEvent("onignite", function(_inst, data)
                if chasni_checkifgroundedexists("chesspiece_yotd_stone")then
                    _inst.components.locomotor:SetExternalSpeedMultiplier(_inst,"chesspiece_yotd_stone", 1.5)
                end
                if chasni_checkifgroundedexists("chesspiece_yotd_marble")then
                    _inst.components.combat.externaldamagemultipliers:SetModifier("chesspiece_yotd_marble", 1.5)
                end
            end)
            inst:ListenForEvent("onextinguish", function(_inst, data)
                _inst.components.combat.externaldamagemultipliers:RemoveModifier("chesspiece_yotd_marble")
                _inst.components.locomotor:RemoveExternalSpeedMultiplier(_inst, "chesspiece_yotd_stone")
            end)
        end)
    end
    -- 50% reduce burning damage | MoonGlass Start Tower Figure
    AddComponentPostInit("health", function(self)
        local _GetFireDamageScale = self.GetFireDamageScale
        self.GetFireDamageScale = function(_self, ...)
            local retval = _GetFireDamageScale and _GetFireDamageScale(_self, ...) or 1
            if _self.inst and _self.inst:HasTag("player") and chasni_checkifgroundedexists("chesspiece_yotd_moonglass") then
                retval = retval * 0.5
            end
            return retval
        end
    end)

    -- no sanity reduction on eat glow berry | Stone Gilded Depths Worm Figure
    if TheNet:GetIsServer() then
        local function wormlightpostinit(inst)
            if inst.components.edible then
                local getsanityfn = inst.components.edible.getsanityfn
                inst.components.edible:SetGetSanityFn(function(_inst, eater, ...)
                    local retval = getsanityfn and getsanityfn(_inst, eater, ...)
                    if ((retval and retval < 0) or retval == nil) and chasni_checkifgroundedexists("chesspiece_yots_stone") then
                        return 0
                    end
                    return retval
                end)
            end
        end
        AddPrefabPostInit("wormlight", wormlightpostinit)
        AddPrefabPostInit("wormlight_lesser", wormlightpostinit)
    end

    -- luck manipulation | Stone Marble Gilded Knight Figure
    local _GetEntityLuck = GetEntityLuck
    GLOBAL.GetEntityLuck = function(inst, ...)
        local add = 0
        if inst and inst:HasTag("player") and chasni_checkifgroundedexists("chesspiece_yoth_marble") then
            add = add + 3
        end
        if inst and inst:HasTag("player") and chasni_checkifgroundedexists("chesspiece_yoth_stone") then
            add = add - 3
        end
        return (_GetEntityLuck(inst, ...) + add)
    end
    -- double lootdropper max luck mult | MoonGlass Gilded Knight Figure
    local _LootDropperChance = GLOBAL.LuckFormulas.LootDropperChance
    local original_mult_max, mult_max_i = UpvalueHacker.GetUpvalue(_LootDropperChance, "mult_max")
    cz_last_grounded_state = nil
    GLOBAL.LuckFormulas.LootDropperChance = function(inst, chance, luck, ...)
        local grounded = chasni_checkifgroundedexists("chesspiece_yoth_moonglass")
        if grounded ~= cz_last_grounded_state then
            cz_last_grounded_state = grounded
            debug.setupvalue(_LootDropperChance, mult_max_i, grounded and original_mult_max * 2 or original_mult_max)
        end

        return _LootDropperChance(inst, chance, luck, ...)
    end
end
