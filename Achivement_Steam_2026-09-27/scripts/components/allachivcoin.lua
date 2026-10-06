require "functions/helperfunctions"
local perkfuncs = require "functions/perkfunctions"
local removedperks = require "constants/removedperks"
local attributecaps = require "constants/attributecaps"
local globalperkstate = require "functions/globalperkstate"

-- Each attribute upgrade costs at most 5 stars, including its first purchase.
-- Existing attribute level limits still apply.
local ATTRIBUTE_COST_CAP = 5

local function GetAttributeCost(perk, amount)
    return math.min(ATTRIBUTE_COST_CAP, perk.cost + math.floor(amount / perk.multi))
end

local allachivcoin = Class(
        function(self, inst)
            self.inst = inst
            self.coinamount = 0
            self.starsspent = 0
            for perkname, perk in pairs(perk_lists) do
                if perk.single ~= true then
                    if perk.multi then
                        self[perkname .."amount"] = 0
                        self[perkname .."cost"] = GetAttributeCost(perk, 0)
                    else
                        self[perkname] = false
                    end
                end
            end

            self.fishtimemin = 4
            self.fishtimemax = 40
        end,
        nil,
        perkfuncs.getperkfunction()
)

function allachivcoin:OnSave()
    removedperks.clearGlobal(TUNING.ACH)
    local data = {
        coinamount = self.coinamount,
        starsspent = self.starsspent,
    }
    for perkname, perk in pairs(perk_lists) do
        if perk.single ~= true then
            if perk.multi then
                data[perkname .."amount"] = self[perkname .."amount"]
            elseif perk.global then
                data[perkname] = TUNING.ACH[perkname] or 0
            else
                data[perkname] = self[perkname]
            end
        end
    end
    return data
end

function allachivcoin:OnLoad(data)
    data = data or {}
    globalperkstate.Initialize()
    local globalperks = TheWorld and TheWorld.components and TheWorld.components.chasni_globalperks
    if globalperks then globalperks:RecoverPlayer(data) end
    removedperks.clearGlobal(TUNING.ACH)
    self.coinamount = data.coinamount or 0
    self.starsspent = data.starsspent or 0

    for perkname, perk in pairs(perk_lists) do
        if perk.single ~= true then
            if perk.multi then
                self[perkname .."amount"] = data[perkname .."amount"] or 0
                self[perkname .."cost"] = GetAttributeCost(perk, self[perkname .."amount"])
            elseif perk.global then
                self[perkname] = TUNING.ACH[perkname] or 0
            else
                self[perkname] = data[perkname] or false
            end
        end
    end
    for perkname, cap in pairs(attributecaps) do
        local amount = self[perkname .. "amount"]
        if amount > cap then
            local perk = perk_lists[perkname]
            local refund = removedperks.refundMulti(amount, perk.cost, perk.multi)
                - removedperks.refundMulti(cap, perk.cost, perk.multi)
            self.coinamount = self.coinamount + refund
            self.starsspent = math.max(0, self.starsspent - refund)
            self[perkname .. "amount"] = cap
            self[perkname .. "cost"] = GetAttributeCost(perk, cap)
        end
    end
    for perkname, cost in pairs(removedperks.costs) do
        if data[perkname] then
            self.coinamount = self.coinamount + cost
            self.starsspent = math.max(0, self.starsspent - cost)
        end
        self[perkname] = false
    end
    for perkname, details in pairs(removedperks.multi) do
        local refund = removedperks.refundMulti(data[perkname .. "amount"], details.cost, details.multi)
        self.coinamount = self.coinamount + refund
        self.starsspent = math.max(0, self.starsspent - refund)
        self[perkname .. "amount"] = 0
        self[perkname .. "cost"] = details.cost
    end
    for perkname in pairs(removedperks.global) do
        self[perkname] = 0
    end
end

function allachivcoin:ongetcoin(inst)
    inst.SoundEmitter:PlaySound("dontstarve/HUD/research_available")
end

function allachivcoin:cantgetcoin(inst)
    inst.SoundEmitter:PlaySound("dontstarve/HUD/click_negative")
end

function allachivcoin:coinDoDelta(value)
    self.coinamount = self.coinamount + value
end

function allachivcoin:addtag(inst, check, tag)
    if check and inst:HasTag(tag) ~= true then
        inst:AddTag(tag)
    end
end
function allachivcoin:addmatchingtag(inst, perk)
    self:addtag(inst, self[perk], perk)
end

-- # ATTRIBUTE
function allachivcoin:pickperk1(inst, perk)
    if removedperks.isRemoved(perk) then
        self:cantgetcoin(inst)
        return false
    end
    if attributecaps[perk] and self[perk .. "amount"] >= attributecaps[perk] then
        self:cantgetcoin(inst)
        return false
    end
    if self.coinamount >= self[perk.."cost"] then
        self[perk.."amount"] = self[perk.."amount"] + 1

        self:coinDoDelta(-self[perk.."cost"])
        self.starsspent = self.starsspent + self[perk.."cost"]
        self[perk.."cost"] = GetAttributeCost(perk_lists[perk], self[perk.."amount"])
        self:ongetcoin(inst)
        if self[perk.."fn"] then
            self[perk.."fn"](self, inst)
        end
        return true
    end
    self:cantgetcoin(inst)
    return false
end
function allachivcoin:speedupfn(inst)
    local spd = 1 + allachiv_coindata["speedup"] * self.speedupamount
    inst.components.locomotor:SetExternalSpeedMultiplier(inst,"speedPerk", spd)
end
function allachivcoin:absorbuppick(inst)
    local currentAbsorbAdd = inst.components.combat.externaldamagetakenmultipliers:CalculateModifierFromSource("absorbPerk")
    if currentAbsorbAdd > 0.5 then
        return self:pickperk1(inst, "absorbup")
    end
    self:cantgetcoin(inst)
end
function allachivcoin:absorbupfn(inst)
    local abs = allachiv_coindata["absorbup"] * self.absorbupamount
    inst.components.combat.externaldamagetakenmultipliers:SetModifier("absorbPerk", 1 - abs)
end
function allachivcoin:damageupfn(inst)
    local dmg = 1 + allachiv_coindata["damageup"] * self.damageupamount
    inst.components.combat.externaldamagemultipliers:SetModifier("damagePerk", dmg)
end
function allachivcoin:planarabsorbupfn(inst)
    if self.planarabsorbupamount > 0 then
        local abs = allachiv_coindata["planarabsorbup"] * self.planarabsorbupamount
        if inst.components.planardefense then
            inst.components.planardefense:AddBonus(inst, abs, "planarAbsorbPerk")
        end
    end
end
function allachivcoin:planardamageupfn(inst)
    if self.planardamageupamount > 0 then
        local dmg = allachiv_coindata["planardamageup"] * self.planardamageupamount
        if inst.components.planardamage then
            inst.components.planardamage:AddBonus(inst, dmg, "planarDamagePerk")
        end
    end
end
function allachivcoin:criticaluppick(inst)
    if allachiv_coindata["criticalup"] * self.criticalupamount <= 0.5 then
        return self:pickperk1(inst, "criticalup")
    end
    self:cantgetcoin(inst)
end
function allachivcoin:lifestealupfn(inst)
    if self.lifestealupamount > 0 then
        if inst.lifestealuplistener == true then
            return
        end
        inst.lifestealuplistener = true
        inst:ListenForEvent("onhitother", function(_inst, data)
            if self.lifestealupamount > 0 and data.damageresolved > 0 and _inst.components.health and not _inst.components.health:IsDead() and chasni_isLifeDrainable(data.target) then
                _inst.components.health:DoDelta(data.damageresolved*allachiv_coindata["lifestealup"] * self.lifestealupamount, false, "lifestealup")
            end
        end)
    end
end
function allachivcoin:fireflylightupfn(inst)
    if inst._fireflylight then inst._fireflylight:Remove() end
    if self.fireflylightupamount > 0 then
        inst._fireflylight = SpawnPrefab("minerhatlight")
        inst._fireflylight.Light:SetRadius(self.fireflylightupamount*allachiv_coindata["fireflylightup"])
        inst._fireflylight.Light:SetFalloff(.8)
        inst._fireflylight.Light:SetIntensity(.6)
        inst._fireflylight.Light:SetColour(255/255,255/255,255/255)
        inst._fireflylight.entity:SetParent(inst.entity)
        if TheWorld.components.worldstate.data.isday then
            inst._fireflylight.Light:SetIntensity(0)
            inst._fireflylight.Light:Enable(false)
        end
        inst:WatchWorldState("startday", function()
            for i=1, 100 do
                inst:DoTaskInTime(i/25, function()
                    if inst._fireflylight and inst._fireflylight.Light then
                        inst._fireflylight.Light:SetIntensity(.5-i/100*.5)
                    end
                end)
            end
            inst:DoTaskInTime(4, function() inst._fireflylight.Light:Enable(false) end)
        end)
        inst:WatchWorldState("startdusk", function()
            if inst._fireflylight and inst._fireflylight.Light then
                inst._fireflylight.Light:Enable(true)
                for i=1, 100 do
                    inst:DoTaskInTime(i/25, function()
                        if inst._fireflylight and inst._fireflylight.Light then
                            inst._fireflylight.Light:SetIntensity(i/100*.5)
                        end
                    end)
                end
            end
        end)
    end
end
function allachivcoin:scaleupfn(inst)
    if self.scaleupamount > 0 then
        inst:ApplyScale("achievementScale", 1 + allachiv_coindata["scaleup"] * self.scaleupamount)
    end
end
function allachivcoin:repairitemupfn(inst)
    if self.repairitemupamount > 0 then
        if inst.repairitemtask then
            inst.repairitemtask:Cancel()
            inst.repairitemtask = nil
        end
        inst.repairitemtask = inst:DoPeriodicTask(1, function()
            if self.repairitemupamount > 0 then
                local inventory = inst.components.inventory
                if inventory then
                    for k, v in pairs(inventory.equipslots) do
                        if not v:HasTag("charges_percentage") and not chasni_isMagicItem(v.prefab) then
                            local repairamount = allachiv_coindata["repairitemup"] * self.repairitemupamount
                            if v.components.finiteuses then
                                local p = v.components.finiteuses:GetPercent()
                                p = math.min(p + repairamount, 1.0)
                                v.components.finiteuses:SetPercent(p)
                            end
                            if v.components.armor then
                                local p = v.components.armor:GetPercent()
                                p = math.min(p + repairamount, 1.0)
                                v.components.armor:SetPercent(p)
                            end
                            if v.components.fueled then
                                local p = v.components.fueled:GetPercent()
                                p = math.min(p + repairamount, 1.0)
                                v.components.fueled:SetPercent(p)
                            end
                        end
                    end
                end
            end
        end)
    end
end
function allachivcoin:repairmagiupfn(inst)
    if self.repairmagiupamount > 0 then
        if inst.repairmagitask then
            inst.repairmagitask:Cancel()
            inst.repairmagitask = nil
        end
        inst.repairmagitask = inst:DoPeriodicTask(1, function() 
            if self.repairmagiupamount > 0 then
                local inventory = inst.components.inventory
                if inventory then
                    for k, v in pairs(inventory.equipslots) do
                        if not v:HasTag("charges_percentage") and chasni_isMagicItem(v.prefab) then
                            local repairamount = allachiv_coindata["repairmagiup"] * self.repairmagiupamount
                            if v.components.finiteuses then
                                local p = v.components.finiteuses:GetPercent()
                                p = math.min(p + repairamount, 1.0)
                                v.components.finiteuses:SetPercent(p)
                            end
                            if v.components.armor then
                                local p = v.components.armor:GetPercent()
                                p = math.min(p + repairamount, 1.0)
                                v.components.armor:SetPercent(p)
                            end
                            if v.components.fueled then
                                local p = v.components.fueled:GetPercent()
                                p = math.min(p + repairamount, 1.0)
                                v.components.fueled:SetPercent(p)
                            end
                        end
                    end
                end
            end
        end)
    end
end
function allachivcoin:repairfoodupfn(inst)
    if self.repairfoodupamount > 0 then
        if inst.repairfoodtask then
            inst.repairfoodtask:Cancel()
            inst.repairfoodtask = nil
        end
        inst.repairfoodtask = inst:DoPeriodicTask(1, function()
            if self.repairfoodupamount > 0 then
                local repairamount = (allachiv_coindata["repairfoodup"] * self.repairfoodupamount)
                for k,v in pairs(inst.components.inventory.itemslots) do
                    if v and v.components.perishable then
                        v.components.perishable:AddTime(repairamount)
                    end
                end
                for k,v in pairs(inst.components.inventory.equipslots) do
                    if v and v.components.perishable then
                        v.components.perishable:AddTime(repairamount)
                    end
                end
            end
        end)
    end
end
function allachivcoin:krampussackupfn(inst)
    if self.krampussackupamount > 0 then
        if inst.krampussackuplistener == true then
            return
        end
        inst.krampussackuplistener = true
        inst:ListenForEvent("onhitother", function(inst, data)
            local target = data.target
            if inst.components.allachivcoin.krampussackupamount > 0 and target.prefab == "krampus" and target._krampussackdropup ~= true then
                target._krampussackdropup = true
                target.components.lootdropper:AddChanceLoot("krampus_sack", allachiv_coindata["krampussackup"] * inst.components.allachivcoin.krampussackupamount)
            end
        end)
    end
end

-- # ABILITY
function allachivcoin:pickperk3(inst, perk)
    if removedperks.isRemoved(perk) then
        self:cantgetcoin(inst)
        return false
    end
    local cost = perk_lists[perk].cost
    if self[perk] ~= true and self.coinamount >= cost then
        if self[perk.."prefn"] then
            self[perk.."prefn"](self, inst)
        end
        self[perk] = true
        self.starsspent = self.starsspent + cost
        self:coinDoDelta(-cost)
        if self[perk.."fn"] then
            self[perk.."fn"](self, inst)
        end
        self:ongetcoin(inst)
        return true
    end
    self:cantgetcoin(inst)
    return false
end
function allachivcoin:nomoistprefn(inst)
    if inst.components.moisture then
        inst.components.moisture:SetMoistureLevel(0)
        if inst.components.moisture.forcedrysources == nil then
            inst.components.moisture.rate = 0
            inst.components.moisture.ratescale = RATE_SCALE.NEUTRAL
            inst.components.moisture:SetMoistureLevel(0)
            inst.components.moisture.inst:StopUpdatingComponent(inst.components.moisture)
            inst.components.moisture.inst:StartUpdatingComponent(inst.components.moisture)
        else
            return
        end
    end
end
function allachivcoin:fastworkerfn(inst) self:addtag(inst, self.fastworker, "fastbuilder") end
function allachivcoin:minefasterfn(inst)
    if self.minefaster then
        inst:ListenForEvent("working", function(inst, data)
            local workable = data.target and data.target.components.workable
            if self.minefaster and workable and workable.action == ACTIONS.MINE and workable.workleft > 0 then
                inst:DoTaskInTime(0.1, function()
                    workable:Destroy(inst)
                end)
            end
        end)
    end
end
function allachivcoin:chopfasterfn(inst)
    if self.chopfaster then
        inst:ListenForEvent("working", function(inst, data)
            local workable = data.target and data.target.components.workable
            if self.chopfaster and workable and workable.action == ACTIONS.CHOP and workable.workleft > 0 then
                inst:DoTaskInTime(0.1, function()
                    workable:Destroy(inst)
                end)
            end
        end)
    end
end
function allachivcoin:fishfasterfn(inst)
    if self.fishfaster then
        local fishingrod = inst.components.inventory
                and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).components.fishingrod
        if fishingrod then
            self.fishtimemin = fishingrod.minwaittime
            self.fishtimemax = fishingrod.maxwaittime
            fishingrod:SetWaitTimes(1, 1)
        end
        inst:ListenForEvent("equip", function(inst, data)
            if  self.fishfaster and data.item and data.item.components.fishingrod then
                self.fishtimemin = data.item.components.fishingrod.minwaittime
                self.fishtimemax = data.item.components.fishingrod.maxwaittime
                data.item.components.fishingrod:SetWaitTimes(1, 1)
            end
        end)
        inst:ListenForEvent("unequip", function(inst, data)
            if self.fishfaster and data.item and data.item.components.fishingrod then
                data.item.components.fishingrod:SetWaitTimes(self.fishtimemin, self.fishtimemax)
            end
        end)
    end
end
function allachivcoin:trinketownerfn(inst)
    if self.trinketowner then
        if inst and inst.components.trinketowner then
            inst.components.trinketowner:UpdateInventory()
        end
    end
end
function allachivcoin:buildcheaperfn(inst)
    if self.buildcheaper then
        inst.components.builder.ingredientmod = .5
        if inst.components.inventory then
            for k,v in pairs(inst.components.inventory.equipslots) do
                if v.prefab == "greenamulet" then
                    inst.components.builder.ingredientmod = .25
                end
            end
        end
    end
    if inst.buildcheaperlistener == true then
        return
    end
    inst.buildcheaperlistener = true
    inst:ListenForEvent("equip", function(inst, data)
        if self.buildcheaper and data.item and data.item.prefab == "greenamulet" then
            inst.components.builder.ingredientmod = .25
        end
    end)
    inst:ListenForEvent("unequip", function(inst, data)
        if self.buildcheaper and data.item and data.item.prefab == "greenamulet" then
            inst.components.builder.ingredientmod = .5
        end
    end)
end
function allachivcoin:doublepickfn(inst)
    if self.doublepick then
        if inst.doublepicklistener == true then
            return
        end
        inst.doublepicklistener = true
        inst:ListenForEvent("picksomething", function(inst, data)
            if inst.components.allachivcoin.doublepick and data.object and data.object.components.pickable and not data.object.components.trader then
                if data.object.components.pickable.product then
                    local item = SpawnPrefab(data.object.components.pickable.product)
                    if item.components.stackable then
                        item.components.stackable:SetStackSize(data.object.components.pickable.numtoharvest)
                    end
                    inst.components.inventory:GiveItem(item, nil, data.object:GetPosition())
                end
            end
        end)
    end
end
function allachivcoin:doubledropfn(inst)
    if self.doubledrop then
        if inst.doubledroplistener == true then
            return
        end
        inst.doubledroplistener = true
        inst:ListenForEvent("killed", function(inst, data)
            if inst.components.allachivcoin.doubledrop and data.victim.components.lootdropper then
                if chasni_isValidVictim(data.victim) then
                    data.victim.components.lootdropper:DropLoot()
                end
            end
        end)
    end
end
function allachivcoin:doubleworkdropfn(inst)
    if self.doubleworkdrop then
        if inst.doubleworkdroplistener == true then
            return
        end
        inst.doubleworkdroplistener = true
        inst:ListenForEvent("finishedwork", function(inst, data)
            if inst.components.allachivcoin.doubleworkdrop and data.target.components.lootdropper then
                if data.action == ACTIONS.MINE or data.action == ACTIONS.CHOP or data.action == ACTIONS.DIG then
                    if data.target:HasTag("tree") or data.target:HasTag("boulder") or data.target:HasTag("stump") then
                        data.target.components.lootdropper:DropLoot()
                    end
                end
            end
        end)
    end
end
function allachivcoin:warlycheffn(inst)
    if self.warlychef then
        if inst:HasTag("professionalchef") ~= true then
            inst:AddTag("professionalchef")
        end
    end
end

-- # EXPERTISE
function allachivcoin:pickperk4(inst, perk, expert)
    if inst.prefab == expert then
        self:pickperk3(inst, perk)
        return
    end
    self:cantgetcoin(inst)
end
function allachivcoin:expertwilson1fn(inst) self:addtag(inst, self.expertwilson1, FOODTYPE.MOONEYE.."_eater") end
function allachivcoin:expertwoodie2fn(inst) self:addtag(inst, self.expertwoodie2, FOODTYPE.WOOD.."_eater") end
function allachivcoin:expertwurt2fn(inst)
    if self.expertwurt2 then
        inst:DoTaskInTime(2,function()
            local mermprotectorspawner = inst.components.mermprotectorspawner
            if mermprotectorspawner then
                if inst.components.leader and not inst.components.leader:IsBeingFollowedBy("mermprotector") then
                    local spawntime = math.max(mermprotectorspawner.protectorRespawnTime and (mermprotectorspawner.protectorRespawnTime - GetTime()) or 1, 1)
                    inst:DoTaskInTime(spawntime, function()
                        mermprotectorspawner:SpawnProtector()
                    end)
                end
            end
        end)
    end
end
function allachivcoin:expertwx1fn(inst)
    if self.expertwx1 and inst.components.upgrademoduleowner then
        inst:DoTaskInTime(0.5, function()
            inst.components.upgrademoduleowner:SetMaxCharge(12)
            local function CheckCircuitSlotStatesInBody(item, player)
                if item.CheckCircuitSlotStatesFrom then
                    item:CheckCircuitSlotStatesFrom(player)
                end
            end
            if TheWorld.components.linkeditemmanager then
                TheWorld.components.linkeditemmanager:ForEachLinkedItemForPlayerOfPrefab(inst, "wx78_backupbody", CheckCircuitSlotStatesInBody)
            end
        end)
    end
end
-- # GLOBAL
function allachivcoin:pickperk5(inst, perk)
    if removedperks.isRemoved(perk) then
        self:cantgetcoin(inst)
        return false
    end
    local cost = perk_lists[perk].cost
    if TUNING.ACH[perk] == 0 and self.coinamount >= cost then
        globalperkstate.Set(perk, 1)
        self[perk] = true
        self:coinDoDelta(-cost)
        if self[perk.."fn"] then
            self[perk.."fn"](self, inst)
        end
        self:ongetcoin(inst)
        return
    elseif TUNING.ACH[perk] == 1 and toggleableglobalperk[perk] then
        globalperkstate.Set(perk, -1)
        self[perk] = false
        self:ongetcoin(inst)
        return
    elseif TUNING.ACH[perk] == -1 then
        globalperkstate.Set(perk, 1)
        self[perk] = true
        self:ongetcoin(inst)
        return
    else
        self[perk] = true
    end
    self:cantgetcoin(inst)
end
function allachivcoin:eternalcagefn(inst)
    if TUNING.ACH["eternalcage"] == 1 then
        TUNING.PERISH_CAGE_MULT = 0
    end
end
function allachivcoin:eternaliceboxfn(inst)
    if TUNING.ACH["eternalicebox"] == 1 then
        TUNING.PERISH_FRIDGE_MULT = -1.5
        TUNING.PERISH_SALTBOX_MULT = -2
    end
end
function allachivcoin:easyfarmfn(inst)
    if TUNING.ACH["easyfarm"] == 1 then
        FARM_PLANT_STRESS = {
            NONE = 1,
            LOW = 1,
            MODERATE = 2,
            HIGH = 2,
        }
        TUNING.FARM_PLANT_KILLJOY_TOLERANCE = 4
        TUNING.FARM_PLANT_KILLJOY_RADIUS = 1
        TUNING.FARM_PLANT_SAME_FAMILY_MIN = 1
        TUNING.FARM_PLANT_DROUGHT_TOLERANCE = 0
    end
end
function allachivcoin:easybeeffn(inst)
    if TUNING.ACH["easybeef"] == 1 then
        TUNING.BEEFALO_DOMESTICATION_STARVE_OBEDIENCE = -1/(4800)
        TUNING.BEEFALO_DOMESTICATION_FEED_OBEDIENCE = 0.3
        TUNING.BEEFALO_DOMESTICATION_OVERFEED_OBEDIENCE = 0
        TUNING.BEEFALO_DOMESTICATION_ATTACKED_BY_PLAYER_OBEDIENCE = 0
        TUNING.BEEFALO_DOMESTICATION_BRUSHED_OBEDIENCE = 0.7
        TUNING.BEEFALO_DOMESTICATION_SHAVED_OBEDIENCE = 0

        TUNING.BEEFALO_DOMESTICATION_LOSE_DOMESTICATION = -1/(4800)
        TUNING.BEEFALO_DOMESTICATION_GAIN_DOMESTICATION = 1/(480)
        TUNING.BEEFALO_DOMESTICATION_OVERFEED_DOMESTICATION = 0
        TUNING.BEEFALO_DOMESTICATION_ATTACKED_DOMESTICATION = 0
        TUNING.BEEFALO_DOMESTICATION_ATTACKED_OBEDIENCE = 0
        TUNING.BEEFALO_DOMESTICATION_ATTACKED_BY_PLAYER_DOMESTICATION = 0
        TUNING.BEEFALO_DOMESTICATION_BRUSHED_DOMESTICATION = 0.3
    end
end

-- # END

function allachivcoin:removecoin(inst, free)
    local resetpercentage = free and 1 or reset_refund_percentage
    self.coinamount = self.coinamount + math.ceil(self.starsspent * resetpercentage)
    self.starsspent = 0
    if reset_health_penalty and not free then
        inst.components.health:DeltaPenalty(TUNING.REVIVE_HEALTH_PENALTY)
    end
    inst.components.allachivevent.starreset = 0

    for perkname, perk in pairs(perk_lists) do
        if perk.single ~= true then
            if perk.multi then
                self[perkname .."amount"] = 0
                self[perkname .."cost"] = GetAttributeCost(perk, 0)
            else
                self[perkname] = false
            end
        end
    end
    self:resetbuff(inst)

    if inst.components.health.currenthealth > 0 and not inst.components.rider:IsRiding() and inst.sg:HasState("changeoutsidewardrobe") and (inst.components.wereness == nil or inst.components.wereness:GetPercent() == 0) then
        inst.components.locomotor:Stop()
        inst.sg:GoToState("changeoutsidewardrobe")
    end
    SpawnPrefab("shadow_despawn").Transform:SetPosition(inst.Transform:GetWorldPosition())
    SpawnPrefab("statue_transition_2").Transform:SetPosition(inst.Transform:GetWorldPosition())
end

function allachivcoin:resetbuff(inst)
    inst.components.hunger.burnratemodifiers:RemoveModifier("achievementperk")

    if inst._fireflylight then inst._fireflylight:Remove() end

    inst:ApplyScale("achievementScale", 1)

    --experts
    inst:RemoveTag(FOODTYPE.MOONEYE.."_eater")
    inst:RemoveTag(FOODTYPE.WOOD.."_eater")

    if inst.prefab ~= "winona" then
        inst:RemoveTag("fastbuilder")
    end

    if inst.prefab == "wx78" then
        local function CheckCircuitSlotStatesInBody(item, player)
            if item.CheckCircuitSlotStatesFrom then
                item:CheckCircuitSlotStatesFrom(player)
            end
        end

        local original_maxcharge = inst._chasni_originalmaxchargelevel and inst._chasni_originalmaxchargelevel or (inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated("wx78_circuitry_slot_1") and TUNING.WX78_MAXCHARGELEVEL_SKILL or TUNING.WX78_INITIAL_MAXCHARGELEVEL)
        inst.components.upgrademoduleowner:SetMaxCharge(original_maxcharge)
        inst._chasni_originalmaxchargelevel = nil
        if TheWorld.components.linkeditemmanager then
            TheWorld.components.linkeditemmanager:ForEachLinkedItemForPlayerOfPrefab(inst, "wx78_backupbody", CheckCircuitSlotStatesInBody)
        end
    end

    if inst.prefab ~= "warly" then
        inst:RemoveTag("professionalchef")
    end

    if inst and inst.components.trinketowner then
        inst.components.trinketowner:UpdateInventory(true)
    end

    if inst.components.combat then
        inst.components.combat.externaldamagetakenmultipliers:SetModifier("absorbPerk", 1)
    end
    if inst.components.combat then
        inst.components.combat.externaldamagemultipliers:SetModifier("damagePerk", 1)
    end
    if inst.components.planardefense then
        inst.components.planardefense:RemoveBonus(inst, "planarAbsorbPerk")
    end
    if inst.components.planardamage then
        inst.components.planardamage:RemoveBonus(inst, "planarDamagePerk")
    end
    if inst.components.locomotor then
        inst.components.locomotor:SetExternalSpeedMultiplier(inst,"speedPerk", 1)
    end

    inst.components.builder.ingredientmod = 1
    if inst and inst.components.inventory then
        for k,v in pairs(inst.components.inventory.equipslots) do
            if v.prefab == "greenamulet" then
                inst.components.builder.ingredientmod = .5
            end
        end
    end

    -- duppercritter
    if inst.components.petleash then
        inst.components.petleash:Chasni_DespawnPetsWithTag("chasni_critter")
    end
end

function allachivcoin:RemoveLegacyTrinketSlot(inst)
    local inventory = inst.components.inventory
    local slot = inventory and inventory:GetEquippedItem("chasni_trinket_container")
    if slot and slot.prefab == "trinketslot" then
        slot.components.container:DropEverything()
        slot:Remove()
    end
end

function allachivcoin:Init(inst)
    inst:DoTaskInTime(.1, function()
        self:RemoveLegacyTrinketSlot(inst)
        for perkname, perk in pairs(perk_lists) do
            if perk.single ~= true then
                if self[perkname .."fn"] then
                    self[perkname .."fn"](self, inst)
                end
            end
        end
    end)
end

return allachivcoin
