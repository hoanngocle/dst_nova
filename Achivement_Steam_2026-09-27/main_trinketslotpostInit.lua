GLOBAL.setmetatable(env,{__index=function(_,k) return GLOBAL.rawget(GLOBAL,k) end})
require "functions/helperfunctions"

-- CC : add double hooking to "fishingrod" Reel >> [Perk] Trinket Slot > Trinket_7 || Ball and Cup
AddComponentPostInit("fishingrod", function(self)
    local oldReel = self.Reel
    function self:Reel(...)
        local trinket = chasni_getequippedtrinket(self.fisherman)
        if trinket and trinket.prefab == "trinket_7" then
            local fishprefab = self.hookedfish and self.hookedfish.prefab
            if fishprefab then
                local dupefish = SpawnPrefab(fishprefab)
                dupefish.entity:Hide()
                local spawnPos = self.fisherman:GetPosition()
                local offset = spawnPos - self.target:GetPosition()
                spawnPos = spawnPos + offset:GetNormalized()
                if dupefish.Physics then
                    dupefish.Physics:SetActive(true)
                    dupefish.Physics:Teleport(spawnPos:Get())
                else
                    dupefish.Transform:SetPosition(spawnPos:Get())
                end
                self.fisherman:ListenForEvent("fishingcollect", function(inst, data)
                    dupefish.entity:Show()
                    if dupefish.DynamicShadow then
                        dupefish.DynamicShadow:Enable(true)
                    end
                end)
            end
        end
        return oldReel(self, ...)
    end
end)

-- CC : add not use finiteuse for instrument to "finiteuses" OnUsedAsItem >> [Perk] Trinket Slot > Trinket_2 || Fake Kazoo
AddComponentPostInit("finiteuses", function(self)
    local oldOnUsedAsItem = self.OnUsedAsItem
    function self:OnUsedAsItem(action, doer, target, ...)
        if self.inst.components.instrument then
            local trinket = chasni_getequippedtrinket(doer)
            if trinket and trinket.prefab == "trinket_2" then
                local stacksize = chasni_gettrinketpoint(trinket, 0.06, 0.66)
                if math.random() < stacksize then
                    return 0
                end
            end
        end
        return oldOnUsedAsItem(self, action, doer, target, ...)
    end
end)

-- CC : add "hitchance" for playerlightningtarget >> [Perk] Trinket Slot > Trinket_6 || Frazzled Wires
AddComponentPostInit("playerlightningtarget", function(self)
    local _GetHitChance = self.GetHitChance
    function self:GetHitChance(...)
        local normalhitchance = _GetHitChance(self, ...)
        local trinket = chasni_getequippedtrinket(self.inst)
        if trinket and trinket.prefab == "trinket_6" then
            local stacksize = chasni_gettrinketpoint(trinket,  0.1, 1)
            return normalhitchance + stacksize
        end
        return normalhitchance
    end
end)

-- CC : add "teleportedoverride" to target >> [Perk] Trinket Slot > Trinket_4 Trinket_13 || Gnomes
if TheNet:GetIsServer() then
    AddPrefabPostInit("telestaff", function(inst)
        inst._chasni_originalspell = inst.components.spellcaster and inst.components.spellcaster.spell
        inst.components.spellcaster:SetSpellFn(function(inst, target, pos, caster, ...)
            local returnval
            local changed = false
            local trinket = chasni_getequippedtrinket(caster)
            if trinket and (trinket.prefab == "trinket_4" or trinket.prefab == "trinket_13") then
                target = target or caster
                if target.components.teleportedoverride == nil then
                    local targettrinket = trinket.prefab == "trinket_4" and "trinket_13" or "trinket_4"
                    local foundothertrinket = false
                    local defaultteletarget = target:GetPosition()
                    for i, v in ipairs(AllPlayers) do
                        local othertrinket = chasni_getequippedtrinket(v)
                        if othertrinket == targettrinket then
                            foundothertrinket = true
                            defaultteletarget = v:GetPosition()
                            break
                        end
                    end
                    if foundothertrinket then
                        target:AddComponent("teleportedoverride")
                        target.components.teleportedoverride:SetDestPositionFn(function(t, ...)
                            local targets = {}
                            for i, v in ipairs(AllPlayers) do
                                local othertrinket = chasni_getequippedtrinket(v)
                                if othertrinket == targettrinket then
                                    local pt = v:GetPosition()
                                    table.insert(targets, pt)
                                end
                            end
                            if #targets > 0 then
                                return targets[math.random(#targets)]
                            end
                            return defaultteletarget
                        end)
                        changed = true
                    end
                end
            end
            if inst._chasni_originalspell then
                returnval = inst._chasni_originalspell(inst, target, pos, caster, ...)
            end

            if changed then
                target:RemoveComponent("teleportedoverride")
            end
            return returnval
        end)
    end)
end

-- CC : add push event on leak to "boatleak" SetState and listener for auto repair to player >> [Perk] Trinket Slot > Trinket_8 || Hardened Rubber Bung
AddComponentPostInit("boatleak", function(self)
    local _SetState = self.SetState
    function self:SetState(state, skip_open, ...)
        if self.boat and state == "small_leak" or state == "med_leak" then
            if self.boat.components.walkableplatform then
                for k in pairs(self.boat.components.walkableplatform:GetPlayersOnPlatform()) do
                    if k:IsValid() then
                        k:PushEvent("chasni_leak_spawned_on_boat", { leak = self.inst })
                    end
                end
            end
        end
        return _SetState(self, state, skip_open, ...)
    end
end)

-- CC : give xp to "sewing_kit" onsewn >> [Perk] Trinket Slot > Trinket_9 || Mismatched Buttons
if TheNet:GetIsServer() then
    AddPrefabPostInit("sewing_kit", function(inst)
        if inst.components.sewing then
            local _onswen = inst.components.sewing.onsewn
            inst.components.sewing.onsewn = function(inst, target, doer, ...)
                local trinket = chasni_getequippedtrinket(doer)
                if trinket and trinket.prefab == "trinket_9" then
                    if doer.components.levelsystem then
                        local stacksize = chasni_gettrinketpoint(trinket,  10, 1000)
                        doer.components.levelsystem:xpDoDelta(math.random(1, stacksize), doer, false, true)
                    end
                end
                return _onswen(inst, target, doer, ...)
            end
        end
    end)
end

-- CC : remove negative aura from "sanityaura" >> [Perk] Trinket Slot > Trinket_25 || Air Unfreshener
AddComponentPostInit("sanityaura", function(self)
    local _GetAura = self.GetAura
    function self:GetAura(observer, ...)
        local defaultaura = _GetAura(self, observer, ...)
        local trinket = chasni_getequippedtrinket(observer)
        if trinket and trinket.prefab == "trinket_25" and defaultaura < 0 then
            defaultaura = 0
        end
        return defaultaura
    end
end)

-- CC : add hunger value on "edible" GetHunger >> [Perk] Trinket Slot > Trinket_17 || Bent Spork
AddComponentPostInit("edible", function(self)
    local _GetHunger = self.GetHunger
    function self:GetHunger(eater, ...)
        local defaulthunger = _GetHunger(self, eater, ...)
        local trinket = chasni_getequippedtrinket(eater)
        if trinket and trinket.prefab == "trinket_17" and defaulthunger > 0 then
            local stacksize = chasni_gettrinketpoint(trinket,  1, 15)
            defaulthunger = stacksize + defaulthunger
        end
        return defaulthunger
    end
end)
-- CC : add "extra_arrive_dist" to PICK PICKUP and COMBINESTACK actions >> [Perk] Trinket Slot > Trinket_20 || Back Scratcher
local function UpdateExtraArriveDist(action, trinketname)
    if not action.extra_arrive_dist then
        action.extra_arrive_dist = function() return 0 end
    end
    local _old_extra_arrive_dist = action.extra_arrive_dist
    local function ExtraArriveDist(doer, dest, ...)
        local defaultdist = _old_extra_arrive_dist(doer, dest, ...)
        local trinket = chasni_getequippedtrinket(doer)
        if trinket and trinket.prefab == trinketname then
            local stacksize = chasni_gettrinketpoint(trinket, 1, 20)
            return defaultdist + stacksize
        end
        return defaultdist
    end
    action.extra_arrive_dist = ExtraArriveDist
end
UpdateExtraArriveDist(GLOBAL.ACTIONS.PICK, "trinket_20")
UpdateExtraArriveDist(GLOBAL.ACTIONS.PICKUP, "trinket_20")
UpdateExtraArriveDist(GLOBAL.ACTIONS.COMBINESTACK, "trinket_20")
UpdateExtraArriveDist(GLOBAL.ACTIONS.GIVE, "trinket_20")
UpdateExtraArriveDist(GLOBAL.ACTIONS.GIVETOPLAYER, "trinket_20")
UpdateExtraArriveDist(GLOBAL.ACTIONS.GIVEALLTOPLAYER, "trinket_20")
UpdateExtraArriveDist(GLOBAL.ACTIONS.FEEDPLAYER, "trinket_20")
UpdateExtraArriveDist(GLOBAL.ACTIONS.COOK, "trinket_20")
UpdateExtraArriveDist(GLOBAL.ACTIONS.ADDFUEL, "trinket_20")
UpdateExtraArriveDist(GLOBAL.ACTIONS.ADDWETFUEL, "trinket_20")
UpdateExtraArriveDist(GLOBAL.ACTIONS.LIGHT, "trinket_20")
UpdateExtraArriveDist(GLOBAL.ACTIONS.EXTINGUISH, "trinket_20")
UpdateExtraArriveDist(GLOBAL.ACTIONS.HARVEST, "trinket_20")

-- CC : add "extra_arrive_dist" to Basic actions >> [Perk] Trinket Slot > trinket_38 || Binoculars
UpdateExtraArriveDist(GLOBAL.ACTIONS.CASTSPELL, "trinket_38")
UpdateExtraArriveDist(GLOBAL.ACTIONS.CAST_POCKETWATCH, "trinket_38")
UpdateExtraArriveDist(GLOBAL.ACTIONS.START_CHANNELCAST, "trinket_38")
UpdateExtraArriveDist(GLOBAL.ACTIONS.CASTSUMMON, "trinket_38")
UpdateExtraArriveDist(GLOBAL.ACTIONS.CASTAOE, "trinket_38")
UpdateExtraArriveDist(GLOBAL.ACTIONS.CAST_SPELLBOOK, "trinket_38")
UpdateExtraArriveDist(GLOBAL.ACTIONS.USESPELLBOOK, "trinket_38")
UpdateExtraArriveDist(GLOBAL.ACTIONS.CHOP, "trinket_38")
UpdateExtraArriveDist(GLOBAL.ACTIONS.MINE, "trinket_38")
UpdateExtraArriveDist(GLOBAL.ACTIONS.DIG, "trinket_38")
UpdateExtraArriveDist(GLOBAL.ACTIONS.NET, "trinket_38")
UpdateExtraArriveDist(GLOBAL.ACTIONS.HAMMER, "trinket_38")
UpdateExtraArriveDist(GLOBAL.ACTIONS.TERRAFORM, "trinket_38")
UpdateExtraArriveDist(GLOBAL.ACTIONS.TILL, "trinket_38")
UpdateExtraArriveDist(GLOBAL.ACTIONS.ROW_FAIL, "trinket_38")
UpdateExtraArriveDist(GLOBAL.ACTIONS.ROW, "trinket_38")
UpdateExtraArriveDist(GLOBAL.ACTIONS.PLAY, "trinket_38")

-- CC : change sanity reduction in "staffsanity" >> [Perk] Trinket Slot > Trinket_15 Trinket_16 || Bishops
AddComponentPostInit("staffsanity", function(self)
    local _DoCastingDelta = self.DoCastingDelta
    self.DoCastingDelta = function(self, amount, ...)
        local trinket = chasni_getequippedtrinket(self.inst)
        if amount < 0 and trinket then
            if trinket.prefab == "trinket_15" then
                amount = amount * -1
            elseif trinket.prefab == "trinket_16" then
                amount = amount * 2
            end
        end
        return _DoCastingDelta(self, amount, ...)
    end
end)
if TheNet:GetIsServer() then
    AddPlayerPostInit(function(inst)
        inst:DoTaskInTime(.1,function()
            if not inst.components.staffsanity then
                inst:AddComponent("staffsanity")
                inst.components.staffsanity:SetMultiplier(1)
            end
        end)
    end)
end

-- CC : set Use to 0 in "finiteuses" >> [Perk] Trinket Slot > Trinket_16 || Black Bishop
AddComponentPostInit("finiteuses", function(self)
    local _Use = self.Use
    self.Use = function(self, num)
        if chasni_isMagicItem(self.inst.prefab) then
            local owner = self.inst and self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner()
            if owner then
                local trinket = chasni_getequippedtrinket(owner)
                if num > 0 and trinket and trinket.prefab == "trinket_16" then
                    if math.random() < 0.25 then
                        trinket.components.stackable:Get():Remove()
                    end
                    num = 0
                end
            end
        end
        return _Use(self, num)
    end
end)

-- CC : wall full heal "onrepaired" >> [Perk] Trinket Slot > Trinket_28 || White Rook
if TheNet:GetIsServer() then
    AddPrefabPostInitAny(function(inst)
        if inst and inst:HasTag("wall") and string.sub(inst.prefab, 1, 5) == "wall_" then
            if inst.components.repairable then
                local old_onrepaired = inst.components.repairable.onrepaired
                inst.components.repairable.onrepaired = function(inst, doer, repair_item, ...)
                    old_onrepaired(inst, doer, repair_item, ...)
                    local trinket = chasni_getequippedtrinket(doer)
                    if trinket and trinket.prefab == "trinket_28" then
                        inst.components.health:SetPercent(1)
                    end
                end
            end
        end
    end)
end

-- CC : set wall workleft to 0 when worked >> [Perk] Trinket Slot > Trinket_29 || Black Rook
if TheNet:GetIsServer() then
    AddPlayerPostInit(function(inst)
        inst:ListenForEvent("working", function(i, data)
            local trinket = chasni_getequippedtrinket(inst)
            if trinket and trinket.prefab == "trinket_29" and data.target and data.target:HasTag("wall") and string.sub(data.target.prefab, 1, 5) == "wall_" then
                local workable = data.target.components.workable
                if workable and workable.workleft > 0 then
                    inst:DoTaskInTime(0.1, function()
                        workable:Destroy(inst)
                    end)
                end
                if inst.components.sanity then
                    local stacksize = chasni_gettrinketpoint(trinket,  5, 40)
                    inst.components.sanity:DoDelta(stacksize)
                end
            end
        end)
    end)
end

-- CC : set wall workleft to 0 when worked >> [Perk] Trinket Slot > Trinket_19 || Unbalanced Top
if TheNet:GetIsServer() then
    local GEM_CHANCE =
    {
        yellowgem = 0.08,
        orangegem = 0.08,
        greengem = 0.08,
        purplegem = 0.15,
        redgem = 0.3,
        bluegem = 0.3,
        opalpreciousgem = 0.01,
    }
    AddPlayerPostInit(function(inst)
        inst:ListenForEvent("finishedwork", function(i, data)
            local trinket = chasni_getequippedtrinket(inst)
            if trinket and trinket.prefab == "trinket_19" and data.target then
                if data.action == ACTIONS.MINE then
                    local stacksize = chasni_gettrinketpoint(trinket,  0.04, 1)
                    if math.random() < stacksize then
                        local product = weighted_random_choice(GEM_CHANCE)
                        local prd = SpawnPrefab(product)
                        local pt = Vector3(data.target.Transform:GetWorldPosition()) + Vector3(0,2,0)
                        prd.Transform:SetPosition(pt:Get())
                        local down = TheCamera:GetDownVec()
                        local angle = math.atan2(down.z, down.x) + (math.random()*60)*DEGREES
                        prd.Physics:SetVel(math.cos(angle), math.random(), math.sin(angle))
                    end
                end
            end
        end)
    end)
end

-- CC : Open container while riding >> [Perk] Trinket Slot > trinket_26 || Potato Cup
AddComponentAction("SCENE", "container", function(inst, doer, actions, right)
    if not table.contains(actions, ACTIONS.RUMMAGE) then
        local isridingwithtrinket = doer.replica.rider and doer.replica.rider:IsRiding() and doer:HasTag("enchantmemento_trinket_26")
        if not inst:HasTag("burnt")
                and inst.replica.container:CanBeOpened()
                and doer.replica.inventory
                and (not inst:HasTag("oceantrawler") or not inst:HasTag("trawler_lowered"))
                and ((not (doer.replica.rider and doer.replica.rider:IsRiding())) or isridingwithtrinket) then
            table.insert(actions, ACTIONS.RUMMAGE)
        end
    end
end)

-- CC : add honey_trail slow resistant >> [Perk] Trinket Slot > Trinket_23 || Shoehorn
AddComponentPostInit("locomotor", function(locomotor)
    local _PushTempGroundSpeedMultiplier = locomotor.PushTempGroundSpeedMultiplier
    function locomotor:PushTempGroundSpeedMultiplier(...)
        if locomotor.inst:HasTag("enchantmemento_trinket_23") then
            return
        end
        return _PushTempGroundSpeedMultiplier(locomotor, ...)
    end
end)

-- CC : set Cursable IsCursable to false >> [Perk] Trinket Slot > trinket_34 || Monkey Paw
AddComponentPostInit("cursable", function(cursable)
    local _IsCursable = cursable.IsCursable
    function cursable:IsCursable(item, ...)
        if item.prefab == "cursed_monkey_token" then
            local trinket = chasni_getequippedtrinket(cursable.inst)
            if trinket and trinket.prefab == "trinket_34" then
                return false
            end
        end
        return _IsCursable(cursable, item, ...)
    end
end)

-- CC : share healer Heal >> [Perk] Trinket Slot > trinket_35 || Empty Elixir
AddComponentPostInit("healer", function(healer)
    local _Heal = healer.Heal
    function healer:Heal(target, doer, ...)
        local retval = _Heal(healer, target, doer, ...)
        if target == doer then
            local trinket = chasni_getequippedtrinket(target)
            if trinket and trinket.prefab == "trinket_35" then
                local pos = Vector3(target.Transform:GetWorldPosition())
                local ents = FindPlayersInRange(pos.x,pos.y,pos.z, 7, true)
                for _, v in pairs(ents) do
                    if v ~= target and v.components.health then
                        local stacksize = chasni_gettrinketpoint(trinket, 0.05, 0.75)
                        local sharedheal = healer.health * (0.25 + stacksize)
                        v.components.health:DoDelta(sharedheal, false, trinket.prefab)
                    end
                end
            end
        end
        return retval
    end
end)

-- CC : set Cursable IsCursable to false >> [Perk] Trinket Slot > trinket_40 || Snail Scale
AddComponentPostInit("weighable", function(weighable)
    local _SetPlayerAsOwner = weighable.SetPlayerAsOwner
    function weighable:SetPlayerAsOwner(owner, ...)
        local retval = _SetPlayerAsOwner(weighable, owner, ...)
        local trinket = chasni_getequippedtrinket(owner)
        if trinket and trinket.prefab == "trinket_40" then
            local stacksize = chasni_gettrinketpoint(trinket, 0.025, 1)
            weighable:SetWeight(Lerp(weighable.min_weight, weighable.max_weight, stacksize + (1 - stacksize) * math.random()))
        end
        return retval
    end
end)

-- CC : give more multiplier to FuelMaster BonusMult >> [Perk] Trinket Slot > trinket_41 || Goop Canister
AddComponentPostInit("fuelmaster", function(fuelmaster)
    local _GetBonusMult = fuelmaster.GetBonusMult
    function fuelmaster:GetBonusMult(...)
        local retval = _GetBonusMult(fuelmaster, ...)
        local trinket = chasni_getequippedtrinket(fuelmaster.inst)
        if trinket and trinket.prefab == "trinket_41" then
            local stacksize = chasni_gettrinketpoint(trinket, 0.5, 9)
            retval = retval * (1 + stacksize)
        end
        return retval
    end
end)

if TheNet:GetIsServer() then
    AddPlayerPostInit(function(inst)
        inst:DoTaskInTime(.1,function()
            if not inst.components.fuelmaster then
                inst:AddComponent("fuelmaster")
            end
        end)
    end)
end

-- CC : trinketslot container HUD placement
local ContainerWidget = require("widgets/containerwidget")
local _Open = ContainerWidget.Open
function ContainerWidget:Open(container, doer, ...)
    local widget = container.replica.container:GetWidget()
    _Open(self, container, doer, ...)
    if doer and widget.animbank == "ui_chasni_trinket_1x1" then
        self:SetHAnchor(ANCHOR_LEFT)
        self:SetVAnchor(ANCHOR_TOP)
        local mainbutton = ThePlayer and ThePlayer.HUD and ThePlayer.HUD.controls
                and ThePlayer.HUD.controls.uiachievement
                and ThePlayer.HUD.controls.uiachievement.mainbutton

        local pos = mainbutton and mainbutton:GetPosition()
        if pos then
            local w, _ = TheSim:GetScreenSize()
            local scale_factor = w / 2560
            local size = (64 * scale_factor) / 2
            self:SetPosition(pos.x - size, pos.y - size, 0)
            self:SetScale(1 * scale_factor,1 * scale_factor)
        end
    end
end

-- CC : instantly unfreeze >> [Perk] Trinket Slot > trinket_46 || Broken Hairdryer
if TheNet:GetIsServer() then
    AddPlayerPostInit(function(inst)
        inst:ListenForEvent("freeze", function(inst_)
            if inst_.components.freezable then
                local trinket = chasni_getequippedtrinket(inst_)
                if trinket and trinket.prefab == "trinket_46" and inst_.components.freezable:IsFrozen() then
                    inst_:DoTaskInTime(0.5, function(inst__)
                        inst__.components.freezable:Unfreeze()
                    end)
                end
            end
        end)
    end)
end
---------------------------------------------------------------------------------------------------------
--- DLC Trinkets
---------------------------------------------------------------------------------------------------------
-- CC : force stack DLC trinkets >> [Perk] Trinket Slot
local FORCE_STACK_NAMES = {
    ["Old Boot"] = true,
    ["Sea Worther"] = true,
    ["Sextant"] = true,
    ["Soaked Candle"] = true,
    ["Tiny Rocketship"] = true,
    ["Toy Boat"] = true,
    ["Ancient Vase"] = true,
    ["Brain Cloud Pill"] = true,
    ["Broken AAC Device"] = true,
    ["License Plate"] = true,
    ["One True Earring"] = true,
    ["Orange Soda"] = true,
    ["Ukulele"] = true,
    ["Voodoo Doll"] = true,
    ["Wine Bottle Candle"] = true,
    ["Queen Malfalfa"] = true,
    ["Post Card of the Royal Palace"] = true,
    ["Can of Silly String"] = true,
}
AddComponentPostInit("stackable", function(stackable)
    local _CanStackWith = stackable.CanStackWith
    function stackable:CanStackWith(item, ...)
        if item and self.inst then
            if chasni_gettrinketassociation(self.inst, item) then
                return true
            end
        end
        return _CanStackWith(stackable, item, ...)
    end
end)
AddClassPostConstruct("components/stackable_replica", function(self)
    local _CanStackWith = self.CanStackWith
    function self:CanStackWith(item, ...)
        if item and self.inst then
            if chasni_gettrinketassociation(self.inst, item) then
                return true
            end
        end
        return _CanStackWith(self, item, ...)
    end
end)

-- CC : spread projectile Throw >> [Perk] Trinket Slot > trinket_chasni_16 || Sextant
local function ShootSpreadProjectile(inst, target, angleoffset, projectilecomp)
    local x, y, z = inst.Transform:GetWorldPosition()
    local tx, ty, tz = target.Transform:GetWorldPosition()
    local dir = Vector3(tx - x, 0, tz - z):GetNormalized()
    local angle = math.atan2(dir.z, dir.x) + angleoffset * DEGREES
    local distance = projectilecomp.range or 8
    local targetpos = Vector3(x + math.cos(angle) * distance, 0, z + math.sin(angle) * distance)
    local proj = chasni_spawnprefab(projectilecomp.inst.prefab,x, y, z)
    if proj and proj.components.projectile then
        proj.components.projectile.cz_norepeat = true
        proj.components.projectile.has_damage_set = true
        local wpn = inst.components.combat and inst.components.combat:GetWeapon() or nil
        local dmg = inst.components.combat and inst.components.combat:CalcDamage(target, wpn) or 999
        proj.components.projectile:Chasni_AimedThrow(inst, inst, targetpos, dmg, true)
    end
end
AddComponentPostInit("projectile", function(self)
    local old_Throw = self.Throw
    function self:Throw(owner, target, attacker, ...)
        local retval = old_Throw(self, owner, target, attacker, ...)
        if target then
            local player = (owner and owner:HasTag("player") and owner) or (attacker and attacker:HasTag("player") and attacker)
            if player and self.inst and self.inst.components.inventoryitem == nil and self.inst.prefab ~= "voidcloth_boomerang_proj" then
                local trinket = chasni_getequippedtrinket(player)
                if trinket and trinket.prefab == "trinket_chasni_16" then
                    ShootSpreadProjectile(player, target, -30, self)
                    ShootSpreadProjectile(player, target, 30, self)
                end
            end
        end
        return retval
    end
end)

-- CC : force right_of_passage timer on monkeyqueen >> [Perk] Trinket Slot > trinket_chasni_12 || License Plate
local MonkeyQueen = require("prefabs/monkeyqueen")
local UpvalueHacker = require "functions/upvaluehacker"
local old_ontimerdone = UpvalueHacker.GetUpvalue(MonkeyQueen.fn, "ontimerdone")
local function HasMonkeyImmunePlayer()
    for _, v in ipairs(AllPlayers) do
        local trinket = chasni_getequippedtrinket(v)
        if trinket and trinket.prefab == "trinket_chasni_12" then
            return true
        end
    end
    return false
end
local function new_ontimerdone(inst, data)
    if data and data.name == "right_of_passage" then
        inst._hasnaturalstart = nil
        if HasMonkeyImmunePlayer() then
            inst.components.timer:StartTimer("right_of_passage", TUNING.TOTAL_DAY_TIME)
            return
        end
    end

    return old_ontimerdone(inst, data)
end
UpvalueHacker.SetUpvalue(MonkeyQueen.fn, new_ontimerdone, "ontimerdone")

-- CC : auto revive beefalo that died >> [Perk] Trinket Slot > trinket_chasni_4 || One True Earring
if TheNet:GetIsServer() then
    AddPrefabPostInit("beefalo", function(inst)
        if inst.ShouldKeepCorpse then
            local old_ShouldKeepCorpse = inst.ShouldKeepCorpse
            inst.ShouldKeepCorpse = function(_inst, ...)
                local retval = old_ShouldKeepCorpse(_inst, ...)
                local leader = _inst._cz_beefaloprevleader
                local owner = leader and leader.components.inventoryitem and leader.components.inventoryitem:GetGrandOwner() or nil
                if retval == false and owner then
                    local trinket = chasni_getequippedtrinket(owner)
                    if trinket and trinket.prefab == "trinket_chasni_4" and _inst.OnRevived then
                        _inst:DoTaskInTime(0.1, function()
                            trinket.components.stackable:Get():Remove()
                            _inst:OnRevived()
                            _inst._cz_beefaloprevleader = nil
                        end)
                        return true
                    end
                end
                return retval
            end

            if inst.components.follower then
                local old_SetLeader = inst.components.follower.SetLeader
                inst.components.follower.SetLeader = function(followercomp, leader, ...)
                    if followercomp and followercomp.inst then
                        local isdead = followercomp.inst.components.health and followercomp.inst.components.health:IsDead()
                        if leader == nil and followercomp.leader and isdead then
                            followercomp.inst._cz_beefaloprevleader = followercomp.leader
                        end
                    end
                    return old_SetLeader(followercomp, leader, ...)
                end
            end
        end
    end)
end

-- CC : give pigman follower when give trinkets >> [Perk] Trinket Slot > trinket_chasni_5 || Queen Malfalfa
if TheNet:GetIsServer() then
    local function GetSpawnPoint(pt)
        local theta = math.random() * TWOPI
        local offset = FindWalkableOffset(pt, theta, 30, 12, true)
        return offset and (pt + offset) or nil
    end
    AddPrefabPostInit("pigking", function(inst)
        local _OnGivenItem = inst.components.trader.onaccept
        inst.components.trader.onaccept = function(_inst, giver, item, ...)
            local trinket = giver and chasni_getequippedtrinket(giver)
            if trinket and trinket.prefab == "trinket_chasni_5" then
                if item.prefab:find("trinket", 1, true) or cz_trinkets.modded_trinkets[item.prefab] then
                    local pt = giver:GetPosition()
                    local spawn_pt = GetSpawnPoint(pt)
                    if spawn_pt then
                        local pigman = SpawnPrefab("pigman")
                        if pigman then
                            pigman.Physics:Teleport(spawn_pt:Get())
                            pigman:FacePoint(pt:Get())
                            if pigman.components.follower then
                                pigman.components.follower:SetLeader(giver)
                            end
                        end
                    end
                end
            end
            return _OnGivenItem(inst, giver, item, ...)
        end
    end)
end

-- CC : can sleep on pighouse >> [Perk] Trinket Slot > enchantmemento_trinket_chasni_7 || Post Card of the Royal Palace
local COMPONENT_ACTIONS = UpvalueHacker.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
local SCENE = COMPONENT_ACTIONS.SCENE
local Scene_sleepingbag = SCENE.sleepingbag
function SCENE.sleepingbag(inst, doer, actions, ...)
    if inst:HasTag("pig_house") and (not doer:HasTag("enchantmemento_trinket_chasni_7") or not inst:HasTag("enchantmemento_trinket_chasni_7_sleepable")) then
        return
    end
    Scene_sleepingbag(inst, doer, actions, ...)
end
if TheNet:GetIsServer() then
    AddPrefabPostInit("pighouse", function(inst)
        if inst.components.sleepingbag == nil then
            inst:AddComponent("sleepingbag")
        end
        inst.components.sleepingbag.health_tick = TUNING.SLEEP_HEALTH_PER_TICK
        inst.components.sleepingbag.sanity_tick = TUNING.SLEEP_SANITY_PER_TICK
        inst.components.sleepingbag.hunger_tick = TUNING.SLEEP_HUNGER_PER_TICK
        inst.components.sleepingbag.chasni_canalwayssleep = true

        local Old_onoccupied = inst.components.spawner.onoccupied
        inst.components.spawner.onoccupied = function(...)
            if inst.components.sleepingbag then
                inst.components.sleepingbag:DoWakeUp()
            end
            inst:RemoveTag("enchantmemento_trinket_chasni_7_sleepable")
            return Old_onoccupied(...)
        end
        local Old_onvacate = inst.components.spawner.onvacate
        inst.components.spawner.onvacate = function(...)
            inst:AddTag("enchantmemento_trinket_chasni_7_sleepable")
            return Old_onvacate(...)
        end
        if not inst.components.spawner:IsOccupied() then
            inst:AddTag("enchantmemento_trinket_chasni_7_sleepable")
        end
        inst:AddTag("tent")
    end)
end
AddComponentPostInit("sleepingbag", function(self)
    local oldGetSleepPhase = self.GetSleepPhase
    function self:GetSleepPhase(...)
        if self.chasni_canalwayssleep then
            return TheWorld.state.phase
        end
        return oldGetSleepPhase(self, ...)
    end
end)

-- CC : redirect attack to nearest player >> [Perk] Trinket Slot > enchantmemento_trinket_chasni_10 || Voodoo Doll
AddComponentPostInit("combat", function(self)
    local oldGetAttacked = self.GetAttacked
    function self:GetAttacked(attacker, damage, weapon, stimuli, spdamage, ...)
        local old_redirectdamagefn = self.redirectdamagefn or nil
        local isnotredirected = self.redirectdamagefn == nil or self.redirectdamagefn(self.inst, attacker, damage, weapon, stimuli, spdamage, ...) == nil
        if self.inst and isnotredirected then
            local trinket = chasni_getequippedtrinket(self.inst)
            if trinket and trinket.prefab == "trinket_chasni_10" then
                self.redirectdamagefn = function(inst, _attacker)
                    local nearest = nil
                    local nearestDistSq = math.huge
                    for _, p in ipairs(AllPlayers) do
                        if p ~= inst and p ~= _attacker and p:IsValid() and p.components.health and not p.components.health:IsDead() and not p:HasTag("playerghost") then
                            local dsq = inst:GetDistanceSqToInst(p)
                            if dsq < nearestDistSq then
                                nearestDistSq = dsq
                                nearest = p
                            end
                        end
                    end

                    return nearest
                end
            end
        end
        local retval = oldGetAttacked(self, attacker, damage, weapon, stimuli, spdamage, ...)
        self.redirectdamagefn = old_redirectdamagefn
        return retval
    end
end)

-- CC : add warp back states >> [Perk] Trinket Slot > enchantmemento_trinket_chasni_20 || Floppy Disc
AddStategraphState("wilson", State{
    name = "chasni_warpback_pre",
    tags = { "busy" },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("pocketwatch_warp_pre")
    end,
    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("chasni_warpback")
            end
        end),
    },
})
AddStategraphState("wilson", State{
    name = "chasni_warpback",
    tags = { "busy", "pausepredict", "nodangle", "nomorph", "jumping" },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("pocketwatch_warp")
        if inst.components.playercontroller then
            inst.components.playercontroller:RemotePausePrediction()
        end
        inst.sg.statemem.cz_stafffx = SpawnPrefab("pocketwatch_warpback_fx")
        inst.sg.statemem.cz_stafffx.entity:SetParent(inst.entity)
        inst.sg.statemem.cz_stafffx:SetUp({ 1, 1, 1 })
    end,

    timeline =
    {
        TimeEvent(4 * FRAMES, function(inst)
            inst.sg:AddStateTag("noattack")
            inst.components.health:SetInvincible(true)
            inst.DynamicShadow:Enable(false)
        end),

        TimeEvent(4 * FRAMES, function(inst)
            local warpback_data = inst.cz_warpdata
            local x, y, z = inst.Transform:GetWorldPosition()
            if VecUtil_DistSq(x, z, warpback_data.dest_x, warpback_data.dest_z) > 30*30 then
                inst.sg.statemem.cz_snap_camera = true
                inst:ScreenFade(false, 0.5)
            end
        end),
    },
    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                if inst.sg.statemem.cz_stafffx ~= nil then
                    inst.sg.statemem.cz_stafffx.entity:SetParent(nil)
                    inst.sg.statemem.cz_stafffx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                    inst.sg.statemem.cz_stafffx = nil
                end
                if inst.sg.statemem.cz_snap_camera then
                    inst.sg.statemem.cz_snap_camera = nil
                    inst.sg.statemem.cz_queued_snap_camera = true
                end
                local data = shallowcopy(inst.sg.statemem)
                inst.sg.statemem.cz_portaljumping = true
                inst.sg:GoToState("chasni_warpback_pst", data)
            end
        end),
    },
    onexit = function(inst)
        if inst.sg.statemem.cz_snap_camera then
            inst:SnapCamera()
            inst:ScreenFade(true, 0.5)
        end
        if inst.sg.statemem.cz_stafffx ~= nil and inst.sg.statemem.cz_stafffx:IsValid() then
            inst.sg.statemem.cz_stafffx:Remove()
        end
        if not inst.sg.statemem.cz_portaljumping then
            inst.AnimState:ClearOverrideSymbol("watchprop")
            inst.components.health:SetInvincible(false)
            inst.DynamicShadow:Enable(true)
        end
    end,
})
AddStategraphState("wilson", State{
    name = "chasni_warpback_pst",
    tags = { "busy", "nopredict", "nomorph", "noattack", "nointerrupt", "jumping" },
    onenter = function(inst, data)
        inst.sg.statemem.cz_isphysicstoggle = true
        inst.Physics:SetCollisionMask(COLLISION.GROUND)
        inst.components.locomotor:Stop()
        inst.DynamicShadow:Enable(false)
        inst.components.health:SetInvincible(true)

        inst.AnimState:PlayAnimation("pocketwatch_warp_pst")

        if data.queued_snap_camera then
            inst:SnapCamera()
            inst:ScreenFade(true, 0.5)
        end

        local warpback_data = inst.cz_warpdata
        if warpback_data ~= nil then
            inst.Physics:Teleport(warpback_data.dest_x, warpback_data.dest_y, warpback_data.dest_z)

            local fx = SpawnPrefab("pocketwatch_warpbackout_fx")
            fx.Transform:SetPosition(warpback_data.dest_x, warpback_data.dest_y, warpback_data.dest_z)
            fx:SetUp({ 1, 1, 1 })
        end
        if inst.components.chasnipositionalwarp then
            inst.components.chasnipositionalwarp:GetHistoryPosition(true)
        end

    end,
    timeline =
    {
        TimeEvent(3 * FRAMES, function(inst)
            inst.DynamicShadow:Enable(true)
            inst.sg.statemem.cz_isphysicstoggle = nil
            inst.Physics:SetCollisionMask(COLLISION.WORLD, COLLISION.OBSTACLES, COLLISION.SMALLOBSTACLES, COLLISION.CHARACTERS, COLLISION.GIANTS)
        end),
        TimeEvent(4 * FRAMES, function(inst)
            inst.components.health:SetInvincible(false)
            inst.sg:RemoveStateTag("jumping")
            inst.sg:RemoveStateTag("nomorph")
            inst.sg:RemoveStateTag("nointerrupt")
            inst.sg:RemoveStateTag("noattack")
            inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
        end),
        TimeEvent(9 * FRAMES, function(inst)
            inst.sg:RemoveStateTag("busy")
            inst.sg:RemoveStateTag("nopredict")
            inst.sg:AddStateTag("idle")
        end),
    },
    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },
    onexit = function(inst)
        inst.components.health:SetInvincible(false)
        inst.DynamicShadow:Enable(true)
        if inst.sg.statemem.cz_isphysicstoggle then
            inst.sg.statemem.cz_isphysicstoggle = nil
            inst.Physics:SetCollisionMask(COLLISION.WORLD, COLLISION.OBSTACLES, COLLISION.SMALLOBSTACLES, COLLISION.CHARACTERS, COLLISION.GIANTS)
        end
    end,
})

-- CC : add pushevent on instantsong >> [Perk] Trinket Slot > enchantmemento_trinket_chasni_23 || #1 Battlesongs Fan
local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end
local function GetHoundSpawnPoint(pt, radius_override)
    if radius_override == nil then
        radius_override = 30
    end
    if TheWorld.has_ocean then
        local function OceanSpawnPoint(offset)
            local x = pt.x + offset.x
            local y = pt.y + offset.y
            local z = pt.z + offset.z
            return TheWorld.Map:IsAboveGroundAtPoint(x, y, z, true) and NoHoles(pt)
        end

        local offset = FindValidPositionByFan(math.random() * TWOPI, radius_override, 12, OceanSpawnPoint)
        if offset ~= nil then
            offset.x = offset.x + pt.x
            offset.z = offset.z + pt.z
            return offset
        end
    else
        if not TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then
            pt = FindNearbyLand(pt, 1) or pt
        end
        local offset = FindWalkableOffset(pt, math.random() * TWOPI, radius_override, 12, true, true, NoHoles)
        if offset ~= nil then
            offset.x = offset.x + pt.x
            offset.z = offset.z + pt.z
            return offset
        end
    end
end
AddComponentPostInit("singinginspiration", function(self)
    local oldOnAddInstantSong = self.OnAddInstantSong
    function self:OnAddInstantSong(songdata, ...)
        if self.inst then
            local trinket = chasni_getequippedtrinket(self.inst)
            if trinket and trinket.prefab == "trinket_chasni_23" then
                local pt = self.inst:GetPosition()
                local spawn_pt = GetHoundSpawnPoint(pt)

                if spawn_pt then
                    local hound = SpawnPrefab("hound")
                    if hound then
                        hound.Physics:Teleport(spawn_pt:Get())
                        hound:FacePoint(pt:Get())
                        if hound.components.follower then
                            hound.components.follower:SetLeader(self.inst)
                        end
                        if hound.AnimState then
                            hound.AnimState:SetBuild("hound_ice_ocean")
                            hound.AnimState:SetMultColour(1, .3, .1, 1)
                        end
                        if hound.components.eater then
                            hound.components.eater:SetDiet({ "CZ_NO_EAT" }, { "CZ_NO_EAT" })
                        end
                        if hound.components.combat then
                            hound.components.combat:SetRetargetFunction(10, function() return end)
                        end
                        hound:RemoveTag("hostile")
                        hound.persists = false

                        local stacksize = chasni_gettrinketpoint(trinket,  0.3, 6)
                        local damagemult = 1 + stacksize
                        hound.components.combat.externaldamagemultipliers:SetModifier("trinket", damagemult)
                        hound.components.combat.externaldamagetakenmultipliers:SetModifier("absorbPerk", 0.5)
                    end
                end
            end
        end
        return oldOnAddInstantSong(self, songdata, ...)
    end
end)

-- CC : increase floating speed >> [Perk] Trinket Slot > trinket_chasni_17 || Toy Boat
local function FloatSpeedPostInit(sg)
    local old = sg.states.float.onupdate
    sg.states.float.onupdate = function(inst)
        old(inst)
        if (inst.sg.statemem.swimming or inst.sg:HasStateTag("floating_predict_move")) and inst:HasTag("enchantmemento_trinket_chasni_17") then
            local vx, vy, vz = inst.Physics:GetMotorVel()
            inst.Physics:SetMotorVel(vx * 10, vy, vz)
        end
    end
end

AddStategraphPostInit("wilson", FloatSpeedPostInit)
AddStategraphPostInit("wilson_client", FloatSpeedPostInit)

-- CC : add push event When smoldering and burning started and listener for auto extinguish to player on "burnable" >> [Perk] Trinket Slot > Trinket_8 || Hardened Rubber Bung
AddComponentPostInit("burnable", function(self)
    local _StartWildfire = self.StartWildfire
    function self:StartWildfire(...)
        if not (self.burning or self.smoldering or self.inst:HasTag("fireimmune")) then
            local x, y, z = self.inst.Transform:GetWorldPosition()
            local players = FindPlayersInRange(x, y, z, 15)
            for _, player in ipairs(players) do
                if player:IsValid() then
                    player:PushEvent("chasni_onsmoldering_nearby", { item = self.inst })
                end
            end
        end
        return _StartWildfire(self, ...)
    end

    local _Ignite = self.Ignite
    function self:Ignite(...)
        if not (self.burning or self.inst:HasTag("fireimmune")) then
            local x, y, z = self.inst.Transform:GetWorldPosition()
            local players = FindPlayersInRange(x, y, z, 15)
            for _, player in ipairs(players) do
                if player:IsValid() then
                    player:PushEvent("chasni_onburning_nearby", { item = self.inst })
                end
            end
        end
        return _Ignite(self, ...)
    end
end)
