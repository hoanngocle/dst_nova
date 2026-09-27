GLOBAL.setmetatable(env,{__index=function(_,k) return GLOBAL.rawget(GLOBAL,k) end})

require "functions/helperfunctions"

local UIAnim = require("widgets/uianim")

-- CC : Pango ACTION POOP
AddAction("PANGO_POOP", "Đi vệ sinh", function(act)
    if act.doer.pango_poop then
        act.doer.pango_poop(act.doer)
        return true
    end
end)

-- CC : Hulk robot ACTION MERGE
AddAction("HULK_MERGE", "Hợp nhất robot", function(act)
    if act.doer.domerge then
        act.doer.domerge(act)
        return true
    end
end)

-- CC : overide ACTION PLAY_HORN anim
AddStategraphPostInit("wilson", function(sg)
    if sg.states["play_horn"] then
        local _play_horn_onenter = sg.states["play_horn"].onenter
        sg.states["play_horn"].onenter = function(inst, ...)
            _play_horn_onenter(inst, ...)
            local act = inst:GetBufferedAction()
            if act and act.invobject and act.invobject.hornbuild then
                inst.AnimState:OverrideSymbol("horn01", act.invobject.hornbuild or "horn", act.invobject.hornsymbol or "horn01")
            end
        end
    end
end)

-- CC : overide ACTION USE_FAN anim
AddStategraphPostInit("wilson", function(sg)
    if sg.states["use_fan"] then
        local _use_fan_onenter = sg.states["use_fan"].onenter
        sg.states["use_fan"].onenter = function(inst, ...)
            _use_fan_onenter(inst, ...)
            local act = inst:GetBufferedAction()
            if act and act.invobject and act.invobject.fanbuild then
                local src_symbol = act.invobject.components.fan and act.invobject.components.fan.overridesymbol or "swap_fan"
                inst.AnimState:OverrideSymbol("fan01", act.invobject.fanbuild or "fan", act.invobject.fansymbol or src_symbol)
            end
        end
    end
end)

-- CC : overide ACTION PLAY_BELL anim
AddStategraphPostInit("wilson", function(sg)
    if sg.states["play_bell"] then
        local _play_bell_onenter = sg.states["play_bell"].onenter
        sg.states["play_bell"].onenter = function(inst, ...)
            _play_bell_onenter(inst, ...)
            local act = inst:GetBufferedAction()
            if act and act.invobject and act.invobject.bellbuild then
                inst.AnimState:OverrideSymbol("bell01", act.invobject.bellbuild or "bell", act.invobject.bellsymbol or "bell01")
            end
        end
    end
end)

--CC : monkey queen get_item if cocoontreeseed
AddStategraphPostInit("monkeyqueen", function(sg)
    if sg.states["getitem"] then
        local _getitem_onenter = sg.states["getitem"].onenter
        sg.states["getitem"].onenter = function(inst, data, ...)
            _getitem_onenter(inst, data, ...)
            if data and data.item and data.item.prefab == "chasni_cocoontreeseed" then
                inst.sg.statemem.item = data.item
            end
        end

        local _old_animover = sg.states.getitem.events.animover.fn
        sg.states.getitem.events.animover.fn = function(inst, ...)
            if inst.sg.statemem.item and inst.sg.statemem.item.prefab == "chasni_cocoontreeseed" then
                local loot = SpawnPrefab("tinkertower_blueprint")
                if loot then
                    inst.components.lootdropper:FlingItem(loot)
                    loot:AddTag("nosteal")
                end
                inst.sg:GoToState("happy",{say="MONKEY_QUEEN_HAPPY"})
            else
                _old_animover(inst, ...)
            end
        end
    end
end)

--CC : pig king get_item if woodenpigstatue
if TheNet:GetIsServer() then
    local function launchitem(item, angle)
        local speed = math.random() * 4 + 2
        angle = (angle + math.random() * 60 - 30) * DEGREES
        item.Physics:SetVel(speed * math.cos(angle), math.random() * 2 + 8, speed * math.sin(angle))
    end
    AddPrefabPostInit("pigking", function(inst)
        if inst.components.trader then
            local old_OnAccept = inst.components.trader.onaccept
            inst.components.trader:SetOnAccept(function(inst, giver, item, ...)
                if item.prefab == "chasni_woodenpigstatue" then
                    local x, y, z = inst.Transform:GetWorldPosition()
                    y = 4.5

                    local angle
                    if giver and giver:IsValid() then
                        angle = 180 - giver:GetAngleToPoint(x, 0, z)
                    else
                        local down = TheCamera:GetDownVec()
                        angle = math.atan2(down.z, down.x) / DEGREES
                    end

                    for k = 1, math.random(1, 2) do
                        local bossdrop = chasni_boss_drop[math.random(1,#chasni_boss_drop)]
                        local drop = chasni_spawnprefab(bossdrop, x, y, z)
                        launchitem(drop, angle)
                    end
                end
                if old_OnAccept then
                    return old_OnAccept(inst, giver, item, ...)
                end
            end)
        end
    end)
end

-- CC : poison shenanigans : add playerpoison, dungrelated poisoners and anti-venom >> [Global] playerpoison (Thanks IA)
AddClassPostConstruct("screens/playerhud",function(inst)
    local PlayerPoisonOver = require("widgets/playerpoisonover")
    local fn = inst.CreateOverlays
    function inst:CreateOverlays(owner)
        fn(self, owner)
        self.playerpoisonover = self.overlayroot:AddChild(PlayerPoisonOver(owner))
    end
end)
local function OnPlayerPoisonOverDirty(inst)
    if inst._parent and inst._parent.HUD then
        if inst.playerpoisonover:value() then
            inst._parent.HUD.playerpoisonover:Flash()
        end
    end
end
AddPrefabPostInit("player_classified", function(inst)
    inst.playerpoisonover = GLOBAL.net_bool(inst.GUID, "poison.playerpoisonover", "playerpoisonoverdirty")
    inst:ListenForEvent("playerpoisonoverdirty", OnPlayerPoisonOverDirty)
end)
if TheNet:GetIsServer() then
    AddPlayerPostInit(function(inst)
        if inst.prefab ~= "wx78" then
            inst:AddComponent("playerpoisonable")
        end
    end)
end

-- CC : poison shenanigans : add corrupted child spawner >> [Global] child spawner
AddComponentPostInit("childspawner",function(self)
    local oldSpawnChild = self.SpawnChild
    function self:SpawnChild(target, prefab, radius, ...)
        if self.corruptable == true and TheWorld.components.dungpileregistry and TheWorld.components.dungpileregistry:IsActive() then
            prefab = self.corruptedchild
        end
        return oldSpawnChild(self,target, prefab, radius, ...)
    end
    function self:SetCorruptedChild(prefab)
        self.corruptable = true
        self.corruptedchild = prefab
    end
end)
if TheNet:GetIsServer() then
    AddPrefabPostInit("spiderden", function(inst)
        if inst.components.childspawner then
            inst.components.childspawner:SetCorruptedChild("chasni_spider_poison")
        end
    end)
    AddPrefabPostInit("pond", function(inst)
        if inst.components.childspawner then
            inst.components.childspawner:SetCorruptedChild("chasni_frog_poison")
        end
    end)
    AddPrefabPostInit("pond_mos", function(inst)
        if inst.components.childspawner then
            inst.components.childspawner:SetCorruptedChild("chasni_mosquito_poison")
        end
    end)
end

-- CC : poison shenanigans : add poison cure >> [Global] antidote items
if TheNet:GetIsServer() then
    AddPrefabPostInit("mandrakesoup", function(inst)
        if inst.components.edible then
            local old_OnEatenFn = inst.components.edible.oneaten
            inst.components.edible:SetOnEatenFn(function(inst, eater, ...)
                if old_OnEatenFn then
                    old_OnEatenFn(inst, eater, ...)
                end
                if eater.components.playerpoisonable then
                    eater.components.playerpoisonable:WearOff()
                end
            end)
        end
    end)
    AddPrefabPostInit("leafymeatsouffle", function(inst)
        if inst.components.edible then
            local old_OnEatenFn = inst.components.edible.oneaten
            inst.components.edible:SetOnEatenFn(function(inst, eater, ...)
                if old_OnEatenFn then
                    old_OnEatenFn(inst, eater, ...)
                end
                if eater.components.playerpoisonable then
                    if math.random() < 0.5 then
                        eater.components.playerpoisonable:WearOff()
                    end
                end
            end)
        end
    end)
end

-- CC : upgraded farmplot : autoplant grower >> [RoG] grower component
AddComponentPostInit("grower",function(self)
    local oldRemoveCrop = self.RemoveCrop
    function self:RemoveCrop(crop, ...)
        oldRemoveCrop(self, crop, ...)
        if self.autoplant then
            self.inst:DoTaskInTime(5, function()
                local item = SpawnPrefab(self.autoplantprefab or "seeds")
                local x, y, z = self.inst.Transform:GetWorldPosition()
                local player = FindClosestPlayer(x, y, z)
                self:PlantItem(item, player)
            end)
        end
    end
end)

-- CC : upgraded_shovel casting name and animation >> [RoG] upgraded_shovel stategraphs
AddStategraphState("wilson", State {
    name = "shoveldig_pre",
    tags = { },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("shovel_pre")
    end,
    events = {
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg.statemem.digging = true
                inst.sg:GoToState("shoveldig")
            end
        end),
    },
})
AddStategraphState("wilson", State {
    name = "shoveldig",
    tags = { },
    onenter = function(inst)
        inst.AnimState:PlayAnimation("shovel_loop")
    end,
    timeline = {
        TimeEvent(15 * FRAMES, function(inst)
            inst.sg:RemoveStateTag("predig")
            inst:RemoveTag("predig")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
            inst:PerformBufferedAction()
        end),
        TimeEvent(35 * FRAMES, function(inst)
            if inst.components.playercontroller and
                    inst.components.playercontroller:IsAnyOfControlsPressed(
                            CONTROL_SECONDARY,
                            CONTROL_ACTION,
                            CONTROL_CONTROLLER_ACTION) and
                    inst.sg.statemem.action and
                    inst.sg.statemem.action:IsValid() and
                    inst.sg.statemem.action.target and
                    inst.sg.statemem.action.target.components.workable and
                    inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                    inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action, true) and
                    CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                inst.sg.statemem.action.options.no_predict_fastforward = true
                inst:ClearBufferedAction()
                inst:PushBufferedAction(inst.sg.statemem.action)
            end
        end),
    },
    events = {
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.AnimState:PlayAnimation("shovel_pst")
                inst.sg:GoToState("idle", true)
            end
        end),
    },
})

AddPrefabPostInit("cave_exit", function(inst) inst:AddTag("cavehole") end)
AddPrefabPostInit("cave_entrance_open", function(inst) inst:AddTag("cavehole") end)

-- CC : upgraded_minerhat armor components : get percentages logic | [RoG] upgraded minerhat
AddComponentPostInit("armor", function(self)
    local oldGetPercent = self.GetPercent
    function self:GetPercent(...)
        if self.inst:HasTag("chasni_hidearmorpctg") and self.inst.components.fueled then
            return self.inst.components.fueled:GetPercent()
        end
        return oldGetPercent(self, ...)
    end
end)

-- CC : upgraded_boomerang itemtile boomstack and spirit logic [RoG] upgraded_boomerang || soulamulet
AddClassPostConstruct("widgets/itemtile", function(self)
    local _SetPercent = self.SetPercent
    function self:SetPercent(percent, ...)
        _SetPercent(self, percent, ...)
        if self.item.boomstack then
            if self.percent then
                local boomstacks = self.item.boomstack:value()
                if boomstacks > 999 then
                    self.percent:SetSize(36)
                    self.percent:SetString("999+")
                else
                    self.percent:SetSize(42)
                    self.percent:SetString(tostring(boomstacks))
                end
            end
        elseif self.item.spirit then
            if self.percent then
                local spirits = self.item.spirit:value()
                if spirits > 999 then
                    self.percent:SetSize(36)
                    self.percent:SetString("999+")
                else
                    self.percent:SetSize(42)
                    self.percent:SetString(tostring(spirits))
                end
            end
        end
    end
    self.item:ListenForEvent("boomstackdirty", function(inst, data)
        if inst.boomstack then
            self:SetPercent(self.item.boomstack:value()/100)
        end
    end, self.item)
    self.item:ListenForEvent("spiritdirty", function(inst, data)
        if inst.spirit then
            self:SetPercent(self.item.spirit:value()/100)
        end
    end, self.item)
    self:Refresh()
end)

-- CC : remove soul overloading >> [RoG] soulamulet
if TheNet:GetIsServer() then
    AddPrefabPostInit("wortox", function(inst)
        local oldCheckForOverload = inst.CheckForOverload
        inst.CheckForOverload = function(...)
            if inst:HasTag("soulamulet") then
                return
            end
            return oldCheckForOverload(...)
        end
    end)
end

-- CC : add stopper to oar row components | [RoG] oar components oar_stopper
AddComponentPostInit("oar", function(self)
    local oldRow = self.Row
    function self:Row(doer, pos, ...)
        if self.stopper == true then
            local platform = doer:GetCurrentPlatform()
            local boat_physics = platform.components.boatphysics
            if boat_physics == nil then return end
            if boat_physics:GetVelocity() < 0.1 then return end
            local x, z, force = VecUtil_NormalAndLength(boat_physics.velocity_x, boat_physics.velocity_z)
            boat_physics:ApplyRowForce(-x, -z, boat_physics:GetVelocity(), boat_physics:GetMaxVelocity())
            boat_physics:CloseAllSails()
            local anchors = TheSim:FindEntities(pos.x,pos.y,pos.z, 10, {"anchor_raised"})
            for _,anchor in ipairs(anchors) do
                if anchor.components.anchor and anchor:GetCurrentPlatform() == platform then
                    anchor.components.anchor:StartLoweringAnchor()
                end
            end

            doer:PushEvent("rowing")
            return
        end
        return oldRow(self, doer, pos, ...)
    end
end)

-- CC : upgraded_treasurechest : add treasurechest skin to upgraded treasure chest >> [RoG] upgraded treasure chest
_G.PREFAB_SKINS["upgraded_treasurechest"] = PREFAB_SKINS["treasurechest"]
_G.PREFAB_SKINS_IDS["upgraded_treasurechest"] = PREFAB_SKINS_IDS["treasurechest"]
-- CC : upgraded_treasurechest : add treasurechest_upgraded skin to upgraded treasure chest >> [RoG] upgraded treasure chest
if TheNet:GetIsServer() then
    AddPrefabPostInit("reskin_tool", function(inst)
        local old_spell = inst.components.spellcaster.spell
        inst.components.spellcaster:SetSpellFn(function(tool, target, pos, caster, ...)
            if target and target.prefab == "upgraded_treasurechest" then
                local x, y, z = caster.Transform:GetWorldPosition()
                target._chestupgrade_stacksize = target:GetDistanceSqToPoint(x, y, z) < 16
            end
            if old_spell then
                return old_spell(tool, target, pos, caster, ...)
            end
        end)
    end)
end

-- CC : upgraded_icebox : add icebox skin to upgraded ice box >> [RoG] upgraded ice box
_G.PREFAB_SKINS["upgraded_icebox"] = PREFAB_SKINS["icebox"]
_G.PREFAB_SKINS_IDS["upgraded_icebox"] = PREFAB_SKINS_IDS["icebox"]

-- CC : golden klaussackkey : handle using golden klausackkey to normal one >> [RoG] add exception to normal sack
if TheNet:GetIsServer() then
    AddPrefabPostInit("klaus_sack", function(inst)
        local old_onusekeyfn = inst.components.klaussacklock.onusekeyfn
        inst.components.klaussacklock:SetOnUseKey(function(_inst, key, doer, ...)
            if key.prefab == "chasni_klaussackkey" then return false end
            if old_onusekeyfn then
                return old_onusekeyfn(_inst, key, doer, ...)
            end
        end)
    end)
end

-- CC : health components : reverse hot and cold damage | [RoG] upgraded_amulet upgraded_blueamulet
AddComponentPostInit("health", function(self)
    local oldDoDelta = self.DoDelta
    function self:DoDelta(amount, overtime, cause, ...)
        if cause and cause == "hot" and self.inst:HasTag("chasni_heathealing") and amount < 0 then
            amount = amount * -1
        elseif cause and cause == "cold" and self.inst:HasTag("chasni_freezehealing") and amount < 0 then
            amount = amount * -1
        end
        return oldDoDelta(self, amount, overtime, cause, ...)
    end
end)

-- CC : ancient herald army >> [RoG] remove shadowthrall lootdropper
if TheNet:GetIsServer() then
    SetSharedLootTable("chasni_empty", {
        { "nightmarefuel",	0.5 },
        { "voidcloth",		0.2 },
        { "horrorfuel",		0.2 },
    })
    local function shadowthrallinit(inst)
        local old_OnSave = inst.OnSave
        inst.OnSave = function(inst, data, ...)
            data.ancient_army = inst.ancient_army or false
            if old_OnSave then
                old_OnSave(inst, data, ...)
            end
        end

        local old_OnLoad = inst.OnLoad
        inst.OnLoad = function(inst, data, ...)
            if data.ancient_army == true then
                inst.ancient_army = true
                if inst.components.lootdropper then
                    inst.components.lootdropper:SetChanceLootTable("chasni_shadowthrall")
                end
                if inst.components.health then
                    inst.components.health:SetMaxHealth(inst.components.health.maxhealth * 0.5)
                end
            end
            if old_OnLoad then
                old_OnLoad(inst, data, ...)
            end
        end
    end
    AddPrefabPostInit("shadowthrall_hands", shadowthrallinit)
    AddPrefabPostInit("shadowthrall_horns", shadowthrallinit)
    AddPrefabPostInit("shadowthrall_wings", shadowthrallinit)
end

-- CC : pollinator components : Pollinate logic to max target | [RoG] snapdragon flower
AddComponentPostInit("pollinator", function(self)
    local oldPollinate = self.Pollinate
    function self:Pollinate(flower, ...)
        if flower and flower:HasTag("snapdragon_flower") then
            for i = #self.flowers, self.collectcount do
                table.insert(self.flowers, flower)
            end
            self.target = nil
        end
        return oldPollinate(self, flower, ...)
    end
end)

-- CC : add negative efficiency to mightydumbbell | [RoG] mightydumbbell components dumbbell_tinker
AddComponentPostInit("mightydumbbell", function(self)
    local oldCheckEfficiency = self.CheckEfficiency
    function self:CheckEfficiency(doer, ...)
        if self.negativeefficiency then
            if self.strongman then
                local mightiness = self.strongman.components.mightiness
                if mightiness then
                    local efficiency = self.efficiency_mighty
                    if mightiness.current < TUNING.WIMPY_THRESHOLD then
                        efficiency = self.efficiency_wimpy
                    elseif mightiness.current < TUNING.MIGHTY_THRESHOLD then
                        efficiency = self.efficiency_normal
                    end
                    mightiness:SetRateScale(RATE_SCALE.DECREASE_MED)
                    return efficiency
                end
            end
            return 0
        else
            return oldCheckEfficiency(self, doer, ...)
        end
    end
end)

-- CC : add onliftfn calling to dumbbelllifter | [RoG] dumbbelllifter components dumbbell_tinker
AddComponentPostInit("dumbbelllifter", function(self)
    local oldLift = self.Lift
    function self:Lift(...)
        local returnval = oldLift(self, ...)
        if returnval and self.dumbbell and self.dumbbell:IsValid() and self.dumbbell.components.mightydumbbell and self.dumbbell.components.mightydumbbell.onliftfn then
            self.dumbbell.components.mightydumbbell.onliftfn(self.dumbbell)
        end
        return returnval
    end
end)

-- CC : dont consume book_voker on read >> [RoG] book_voker
AddComponentPostInit("book", function(self)
    local oldConsumeUse = self.ConsumeUse
    function self:ConsumeUse(...)
        if self.inst and self.inst.prefab == "chasni_book_voker" then
            return
        end
        return oldConsumeUse(self, ...)
    end
end)

-- CC : waxwell onspawn : upgraded shadowworker onspawn when using book_voker >> [RoG] book_voker
if TheNet:GetIsServer() then
    AddPrefabPostInit("waxwell", function(inst)
        if inst.components.petleash then
            local old_onspawnfn = inst.components.petleash.onspawnfn
            inst.components.petleash:SetOnSpawnFn(function(_inst, pet, ...)
                if old_onspawnfn then
                    old_onspawnfn(_inst, pet, ...)
                end
                if _inst.components.inventory and _inst.components.inventory:EquipHasTag("book_voker") and _inst.components.levelsystem then
                    if pet.components.combat and _inst.components.levelsystem.damagelevelamount > 0 then
                        local dmg = 1 + _inst.components.levelsystem.damagelevelamount * damageGain
                        pet.components.combat.externaldamagemultipliers:SetModifier("damageUpgrade_shadow", dmg)
                    end
                    if pet.components.locomotor and _inst.components.levelsystem.speedlevelamount > 0 then
                        local spd = 1 + _inst.components.levelsystem.speedlevelamount * speedGain
                        pet.components.locomotor:SetExternalSpeedMultiplier(pet,"speedUpgrade_shadow", spd)
                    end
                    if pet.components.health and _inst.components.levelsystem.healthlevelamount > 0 then
                        local hp = _inst.components.levelsystem.healthlevelamount * healthGain
                        pet.components.health.maxhealth = pet.components.health.maxhealth + hp
                    end
                end
            end)
        end
    end)
end

-- CC : player inst.OnNewSpawn : change spawn location when using gemportal >> [RoG] chasni_gemportal
if TheNet:GetIsServer() then
    AddPlayerPostInit(function(inst)
        local oldOnNewSpawn = inst.OnNewSpawn
        function inst:OnNewSpawn(...)
            if DespawnData[inst.userid] then
                inst:DoTaskInTime(0, function()
                    local despawndata = DespawnData[inst.userid]
                    inst.Transform:SetPosition(despawndata.x, despawndata.y, despawndata.z)
                    DespawnData[inst.userid] = nil
                end)
            end
            return oldOnNewSpawn and oldOnNewSpawn(inst,...)
        end
    end)
end

-- CC : watchpaint : give wanda watch new colours watchpaint >> [RoG] watchpaint
if TheNet:GetIsServer() then
    local function pocketwatchcolour_postInit(inst, texid)
        local old_OnSave = inst.OnSave
        inst._chasni_tex = texid
        inst.ChasniChangeColour = function(self, tex, colour)
            self._chasni_colour = colour or self._chasni_colour
            self._chasni_tex = tex or self._chasni_tex
            if self.components.inventoryitem then
                if self._chasni_colour and self._chasni_tex then
                    self.components.inventoryitem.imagename = self._chasni_colour..self._chasni_tex
                    self.components.inventoryitem.atlasname = "images/inventoryimages/watches_colour.xml"
                else
                    self.components.inventoryitem.imagename = nil
                    self.components.inventoryitem.atlasname = nil
                end
            end
        end

        inst.OnSave = function(self, data, ...)
            data._chasni_colour = self._chasni_colour or nil
            if old_OnSave then
                old_OnSave(self, data, ...)
            end
        end

        local old_OnLoad = inst.OnLoad
        inst.OnLoad = function(self, data, ...)
            if data and data._chasni_colour then
                self._chasni_colour = data._chasni_colour
                self:ChasniChangeColour(self._chasni_tex, self._chasni_colour)
            end
            if old_OnLoad then
                old_OnLoad(self, data, ...)
            end
        end
    end
    AddPrefabPostInit("pocketwatch_recall", function(inst) pocketwatchcolour_postInit(inst, "2")  end)
    AddPrefabPostInit("pocketwatch_portal", function(inst) pocketwatchcolour_postInit(inst, "1")  end)
end

-- CC : readingglasses : make reading faster
AddStategraphState("wilson", State {
    name = "chasni_book_repeatcast_fast",
    onenter = function(inst)
        inst.sg:GoToState("chasni_book_fast", true)
    end,
})
local function OnRemoveCleanupTargetFX(inst)
    if inst.sg.statemem.targetfx.KillFX ~= nil then
        inst.sg.statemem.targetfx:RemoveEventCallback("onremove", OnRemoveCleanupTargetFX, inst)
        inst.sg.statemem.targetfx:KillFX()
    else
        inst.sg.statemem.targetfx:Remove()
    end
end
AddStategraphState("wilson", State {
    name = "chasni_book_fast",
    tags = { "doing", "busy" },
    onenter = function(inst, repeatcast)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("action_uniqueitem_pre")

        local book = inst.bufferedaction ~= nil and (inst.bufferedaction.target or inst.bufferedaction.invobject) or nil
        if book ~= nil then
            inst.components.inventory:ReturnActiveActionItem(book)
            if book.components.spellbook ~= nil and book.components.spellbook:HasSpellFn() then
            elseif book.components.aoetargeting ~= nil then
                inst.sg.statemem.targetfx = book.components.aoetargeting:SpawnTargetFXAt(inst.bufferedaction:GetDynamicActionPoint())
                if inst.sg.statemem.targetfx ~= nil then
                    inst.sg.statemem.targetfx:ListenForEvent("onremove", OnRemoveCleanupTargetFX, inst)
                end
            end
        end

        local fxname = book ~= nil and book:HasTag("shadowmagic") and "waxwell_book_fx" or "book_fx"
        if inst.components.rider:IsRiding() then
            fxname = fxname.."_mount"
        end
        inst.sg.statemem.book_fx = SpawnPrefab(fxname)
        inst.sg.statemem.book_fx.entity:SetParent(inst.entity)

        if repeatcast then
            local t = inst.AnimState:GetCurrentAnimationNumFrames()
            inst.sg.statemem.book_fx.AnimState:SetFrame(t + 6)
            inst.sg.statemem.not_interrupted = true
            inst.sg:GoToState("chasni_book2_fast", {
                book_fx = inst.sg.statemem.book_fx,
                targetfx = inst.sg.statemem.targetfx,
                repeatcast = true,
            })
        end
    end,

    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg.statemem.not_interrupted = true
                inst.sg:GoToState("chasni_book2_fast", {
                    book_fx = inst.sg.statemem.book_fx,
                    targetfx = inst.sg.statemem.targetfx,
                })
            end
        end),
    },
})
AddStategraphState("wilson", State {
    name = "chasni_book2_fast",
    tags = { "doing", "busy" },
    timeline =
    {
        TimeEvent(6 * FRAMES, function(inst)
            local function fn19()
                inst.SoundEmitter:PlaySound("dontstarve/common/use_book_light")

                if inst.sg.statemem.earlycast then
                    if inst.sg.statemem.fx_shadow ~= nil then
                        if inst.sg.statemem.fx_shadow:IsValid() then
                            local x, y, z = inst.sg.statemem.fx_shadow.Transform:GetWorldPosition()
                            inst.sg.statemem.fx_shadow.entity:SetParent(nil)
                            inst.sg.statemem.fx_shadow.Transform:SetPosition(x, y, z)
                            inst.sg.statemem.fx_shadow.Transform:SetRotation(inst.Transform:GetRotation())
                        end
                        inst.sg.statemem.fx_shadow = nil
                    end
                    inst.SoundEmitter:PlaySound(inst.sg.statemem.castsound)
                    if not inst:PerformBufferedAction() then
                        inst.sg.statemem.canrepeatcast = false
                        inst:RemoveTag("canrepeatcast")
                    end
                end
            end
            if inst.sg.statemem.repeatcast then
                fn19()
            else
                inst.sg.statemem.fn19 = fn19
            end
        end),
        TimeEvent(9 * FRAMES, function(inst)
            if inst.sg.statemem.fn19 ~= nil then
                inst.sg.statemem.fn19()
                inst.sg.statemem.fn19 = nil
            end
        end),
        TimeEvent(9 * FRAMES, function(inst)
            if inst.sg.statemem.repeatcast and inst.sg.statemem.canrepeatcast then
                inst:AddTag("canrepeatcast")
            end
        end),
        TimeEvent(12 * FRAMES, function(inst)
            if not inst.sg.statemem.repeatcast and inst.sg.statemem.canrepeatcast then
                inst:AddTag("canrepeatcast")
            end
        end),
        TimeEvent(12 * FRAMES, function(inst)
            local function fn30()
                if inst.sg.statemem.fx_shadow ~= nil then
                    if inst.sg.statemem.fx_shadow:IsValid() then
                        local x, y, z = inst.sg.statemem.fx_shadow.Transform:GetWorldPosition()
                        inst.sg.statemem.fx_shadow.entity:SetParent(nil)
                        inst.sg.statemem.fx_shadow.Transform:SetPosition(x, y, z)
                        inst.sg.statemem.fx_shadow.Transform:SetRotation(inst.Transform:GetRotation())
                    end
                    inst.sg.statemem.fx_shadow = nil --Don't cancel anymore
                end
            end
            if inst.sg.statemem.repeatcast then
                fn30()
            else
                inst.sg.statemem.fn30 = fn30
            end
        end),
        TimeEvent(15 * FRAMES, function(inst)
            if inst.sg.statemem.fn30 ~= nil then
                inst.sg.statemem.fn30()
                inst.sg.statemem.fn30 = nil
            end
        end),
        TimeEvent(22 * FRAMES, function(inst)
            local function fn50()
                if inst.sg.statemem.targetfx ~= nil then
                    if inst.sg.statemem.targetfx:IsValid() then
                        OnRemoveCleanupTargetFX(inst)
                    end
                    inst.sg.statemem.targetfx = nil
                end

                local book_fx = inst.sg.statemem.book_fx
                if book_fx ~= nil then
                    if book_fx:IsValid() then
                        local x, y, z = book_fx.Transform:GetWorldPosition()
                        book_fx.entity:SetParent(nil)
                        book_fx.Transform:SetPosition(x, y, z)
                        book_fx.Transform:SetRotation(inst.Transform:GetRotation())
                    else
                        book_fx = nil
                    end
                    inst.sg.statemem.book_fx = nil --Don't cancel anymore
                end

                if not inst.sg.statemem.earlycast then
                    inst.SoundEmitter:PlaySound(inst.sg.statemem.castsound)
                    inst.sg:RemoveStateTag("busy")
                    if not inst:PerformBufferedAction() then
                        if book_fx ~= nil then
                            book_fx:PushEvent("fail_fx", inst)
                        end
                        inst.sg.statemem.canrepeatcast = false
                        inst:RemoveTag("canrepeatcast")
                    end
                end
            end
            if inst.sg.statemem.repeatcast then
                fn50()
            else
                inst.sg.statemem.fn50 = fn50
            end
        end),
        TimeEvent(25 * FRAMES, function(inst)
            if inst.sg.statemem.fn50 ~= nil then
                inst.sg.statemem.fn50()
                inst.sg.statemem.fn50 = nil
            end
        end),
        TimeEvent(22 * FRAMES, function(inst)
            if inst.sg.statemem.repeatcast then
                inst.SoundEmitter:PlaySound("dontstarve/common/use_book_close")
            end
        end),
        TimeEvent(25 * FRAMES, function(inst)
            if not inst.sg.statemem.repeatcast then
                inst.SoundEmitter:PlaySound("dontstarve/common/use_book_close")
            end
        end),
        TimeEvent(23 * FRAMES, function(inst)
            if inst.sg.statemem.repeatcast then
                inst.sg:RemoveStateTag("busy")
                inst:RemoveTag("canrepeatcast")
            end
        end),
        TimeEvent(26 * FRAMES, function(inst)
            if not inst.sg.statemem.repeatcast then
                inst.sg:RemoveStateTag("busy")
                inst:RemoveTag("canrepeatcast")
            end
        end),
    },
})
AddStategraphPostInit("wilson", function(sg)
    sg.states["chasni_book_fast"].onexit = sg.states["book"].onexit
    sg.states["chasni_book2_fast"].events = sg.states["book2"].events
    local book2onenter = sg.states["book2"].onenter
    local book2onexit = sg.states["book2"].onexit
    sg.states["chasni_book2_fast"].onenter = function(inst, ...)
        book2onenter(inst, ...)
        inst.AnimState:SetDeltaTimeMultiplier(2)
    end
    sg.states["chasni_book2_fast"].onexit = function(inst, ...)
        book2onexit(inst, ...)
        inst.AnimState:SetDeltaTimeMultiplier(1)
    end

    local readdeststate = sg.actionhandlers[ACTIONS.READ].deststate
    sg.actionhandlers[ACTIONS.READ].deststate = function(inst, action, ...)
        local dest
        if type(readdeststate) == "string" then
            dest = readdeststate
        else
            dest = readdeststate(inst, action, ...)
        end

        if dest == "book" and inst and inst:HasTag("chasni_fastreader") then
            return "chasni_book_fast"
        end
        return dest
    end
    local castaoedeststate = sg.actionhandlers[ACTIONS.CASTAOE].deststate
    sg.actionhandlers[ACTIONS.CASTAOE].deststate = function(inst, action, ...)
        local dest
        if type(castaoedeststate) == "string" then
            dest = castaoedeststate
        else
            dest = castaoedeststate(inst, action, ...)
        end

        if dest == "book" and inst and inst:HasTag("chasni_fastreader") then
            return "chasni_book_fast"
        end
        if dest == "book_repeatcast" and inst and inst:HasTag("chasni_fastreader") then
            return "chasni_book_repeatcast_fast"
        end
        return dest
    end
    local castspellbookdeststate = sg.actionhandlers[ACTIONS.CAST_SPELLBOOK].deststate
    sg.actionhandlers[ACTIONS.CAST_SPELLBOOK].deststate = function(inst, action, ...)
        local dest
        if type(castspellbookdeststate) == "string" then
            dest = castspellbookdeststate
        else
            dest = castspellbookdeststate(inst, action, ...)
        end

        if dest == "book" and inst and inst:HasTag("chasni_fastreader") then
            return "chasni_book_fast"
        end
        return dest
    end
end)

-- CC : watchpaint : Spawn paint_fx when doing dolongaction
AddStategraphPostInit("wilson", function(sg)
    if sg.states["dolongaction"] then
        if sg.states["dolongaction"] then
            local _dolongaction_onenter = sg.states["dolongaction"].onenter
            sg.states["dolongaction"].onenter = function(inst, ...)
                _dolongaction_onenter(inst, ...)
                if inst and inst.components.inventory and inst.components.inventory:EquipHasTag("watchpaint") then
                    inst._paintingfx = chasni_spawnprefab("paintfx", 0, 1, 0, 1, 1, 1, inst.entity)
                    inst.components.inventory:ForEachEquipment(function(item)
                        item:RemoveTag("watchpaint")
                    end)
                end
            end
        end

        local _dolongaction_onexit = sg.states["dolongaction"].onexit
        sg.states["dolongaction"].onexit = function(inst, ...)
            _dolongaction_onexit(inst, ...)
            if inst._paintingfx then
                inst._paintingfx:RemoveFX()
            end
        end
    end
end)

-- CC : CRABQUEEN FUNCTIONS
local LIGHTNINGSTRIKE_TAGS = { "crabking_claw_water" }
if TheNet:GetIsServer() then
    AddComponentPostInit("weather", function(self)
        local Chasni_OnSendLightningStrike = function(src, target)
            local pos = Vector3(target.Transform:GetWorldPosition())
            local ckc_water = TheSim:FindEntities(pos.x, pos.y, pos.z, 8, LIGHTNINGSTRIKE_TAGS)
            local blockers
            for _, v in pairs(ckc_water) do
                local is_blocker = v.components.lightningblocker
                if is_blocker then
                    if blockers == nil then
                        blockers = {v}
                    else
                        table.insert(blockers, v)
                    end
                end
            end

            local x, y, z = target.Transform:GetWorldPosition()
            chasni_spawnprefab("thunder", x, y, z)
            if blockers then
                for _, blocker in ipairs(blockers) do
                    blocker.components.lightningblocker:DoLightningStrike(pos)
                    local bx, by, bz = blocker.Transform:GetWorldPosition()
                    chasni_spawnprefab("lightning", bx, by, bz)
                end
            end
            for i, v in ipairs(AllPlayers) do
                local distsq = v:GetDistanceSqToPoint(x, y, z)
                if distsq > 36 and v.components.health and not v.components.health:IsDead() then
                    if v.components.playerlightningtarget then
                        v.components.playerlightningtarget:DoStrike()
                    end
                    local px, py, pz = v.Transform:GetWorldPosition()
                    chasni_spawnprefab("lightning", px, py, pz)
                end
            end
        end

        self.inst:ListenForEvent("chasni_ms_sendlightningstrike", Chasni_OnSendLightningStrike, TheWorld)
    end)
end

local ARMTIME = { 0, 0.25, 0.1, 0.2, 0.15, 0.3, }
local ARM_COUNT = 6
local CRABQUEEN_HEALTH = 10000
local CRABQUEENCLAW_HEALTH = 200
local CRABQUEENCLAW_CAST_COOLDOWN = 20
local function removearm(inst,armpos)
    inst.components.timer:StartTimer("claw_regen_delay"..armpos, TUNING.CRABKING_CLAW_RESPAWN_DELAY)
end
local function hasValidArm(inst)
    if inst:HasTag("chasni_crabqueen") then
        for i=1, ARM_COUNT do
            if inst.arms and inst.arms[i] and inst.arms[i].prefab and inst.arms[i]:IsValid() then
                return true
            end
        end
    end
    return false
end
local function OnTimerDone(inst, data)
    if data.name == "chasni_cast_cooldown" then
        inst.wantstofreeze = true
    end
end
if TheNet:GetIsServer() then
    AddPrefabPostInit("crabking", function(inst)
        inst._chasni_damagecap = -1
        inst.hasValidArm = hasValidArm

        inst:ListenForEvent("activate", function()
            if inst:HasTag("chasni_crabqueen") then
                inst.components.timer:StartTimer("heal_cooldown", 10000000)
                inst:AddTag("fireimmune")
                inst:DoTaskInTime(1, inst.SpawnClawArms)
                inst.components.health:SetMaxHealth(CRABQUEEN_HEALTH)
                inst:ListenForEvent("timerdone", OnTimerDone)
                inst.components.timer:StartTimer("chasni_cast_cooldown", CRABQUEENCLAW_CAST_COOLDOWN)
            end
        end)

        inst.temp_EndCastSpell = inst.EndCastSpell
        inst.EndCastSpell = function(...)
            if inst:HasTag("chasni_crabqueen") then
                if inst.components.timer:TimerExists("spell_cooldown") then
                    inst.components.timer:SetTimeLeft("spell_cooldown", TUNING.CRABKING_CAST_DELAY)
                else
                    inst.components.timer:StartTimer("spell_cooldown", TUNING.CRABKING_CAST_DELAY)
                end

                if inst.wavetask ~= nil then
                    inst.wavetask:Cancel()
                    inst.wavetask = nil
                end

                if inst.geysers and #inst.geysers > 0 then
                    for i=#inst.geysers,1,-1 do
                        local geyser = inst.geysers[i]
                        geyser:Remove()
                        inst.geysers[i] = nil
                    end
                end

                inst.wantstofreeze = nil

                return
            end
            return inst.temp_EndCastSpell(...)
        end

        inst.temp_StartCastSpell = inst.StartCastSpell
        inst.StartCastSpell = function(...)
            if inst:HasTag("chasni_crabqueen") then
                if inst.components.timer:TimerExists("chasni_cast_cooldown") then
                    return
                end

                if inst.geysers and #inst.geysers > 0 then
                    for i=#inst.geysers,1,-1 do
                        local geyser = inst.geysers[i]
                        geyser:Remove()
                        inst.geysers[i] = nil
                    end
                end

                if not inst.hasValidArm(inst) then
                    inst:SpawnClawArms()
                else
                    local activearm = {}
                    for i, arm in ipairs(inst.arms) do
                        if arm:IsValid() and arm.prefab and not arm.sg:HasStateTag("clampped") and arm.sg:HasState("chasni_castspell_pre") then
                            table.insert(activearm, arm)
                        end
                    end
                    if #activearm > 0 then
                        local arm = activearm[math.random(1,#activearm)]
                        if arm and arm:IsValid() and arm.prefab and not arm.sg:HasStateTag("clampped") and arm.sg:HasState("chasni_castspell_pre") then
                            arm.sg:GoToState("chasni_castspell_pre")
                        end
                    end
                end
                if inst.components.timer:TimerExists("chasni_cast_cooldown") then
                    inst.components.timer:SetTimeLeft("chasni_cast_cooldown", CRABQUEENCLAW_CAST_COOLDOWN)
                else
                    inst.components.timer:StartTimer("chasni_cast_cooldown", CRABQUEENCLAW_CAST_COOLDOWN)
                end
                if inst.components.timer:TimerExists("do_end_cast") then
                    inst.components.timer:SetTimeLeft("do_end_cast", 2)
                else
                    inst.components.timer:StartTimer("do_end_cast", 2)
                end
                return
            end
            return inst.temp_StartCastSpell(...)
        end

        inst.temp_SpawnClawArms = inst.SpawnClawArms
        inst.SpawnClawArms = function(...)
            if inst:HasTag("chasni_crabqueen") then
                if not inst.arms then
                    inst.arms = {}
                end
                for i=1, ARM_COUNT do
                    if not inst.arms[i] or not inst.arms[i].prefab or not inst.arms[i]:IsValid() then
                        inst:DoTaskInTime(ARMTIME[i%#ARMTIME+1],function() inst.DoSpawnArm(inst,i)end)
                    end
                end
                return
            end
            return inst.temp_SpawnClawArms(...)
        end

        inst.temp_DoSpawnArm = inst.DoSpawnArm
        inst.DoSpawnArm = function(inst, armpos, fx, ...)
            if inst:HasTag("chasni_crabqueen") then
                if inst.arms == nil then
                    return
                end
                local theta = armpos*(2*PI/ARM_COUNT)
                local radius = 8
                local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))

                local pos = Vector3(inst.Transform:GetWorldPosition()) + offset
                local boat =  TheWorld.Map:GetPlatformAtPoint(pos.x, pos.z)
                local tries = 0
                while boat and tries < 5 do
                    if boat then
                        pos = Vector3(boat.Transform:GetWorldPosition())
                        theta = math.random()*2*PI
                        radius = 5
                        offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
                        pos = pos + offset
                    end
                    boat =  TheWorld.Map:GetPlatformAtPoint(pos.x, pos.z)
                    tries = tries + 1
                end
                if not boat then
                    local gems = inst.gemcount or inst.countgems and inst:countgems() or { red = 1, blue = 1, green = 1, yellow = 1, purple = 1, orange = 1 }
                    local totalgems = gems.red + gems.blue + gems.green + gems.yellow + gems.purple + gems.orange + 12
                    local clawchance =
                    {
                        chasni_firecrabking_claw = (gems.red + 2) / totalgems,
                        chasni_icecrabking_claw = (gems.blue + 2) / totalgems,
                        chasni_watercrabking_claw = (gems.orange + 2) / totalgems,
                        chasni_electriccrabking_claw = (gems.yellow + 2) / totalgems,
                        chasni_shadowcrabking_claw = (gems.purple + 2) / totalgems,
                        chasni_lunarcrabking_claw = (gems.green + 2) / totalgems,
                    }
                    local clawprefab = weighted_random_choice(clawchance)

                    local arm = SpawnPrefab(clawprefab)
                    arm.Transform:SetPosition(pos.x, 0, pos.z)
                    arm.armpos = armpos
                    inst.arms[armpos] = arm
                    local health = CRABQUEENCLAW_HEALTH
                    arm.components.health:SetMaxHealth(health)
                    arm.components.health:SetCurrentHealth(health)
                    arm._crabking = inst
                    arm:PushEvent("emerge")

                    local function death_event()
                        removearm(inst, armpos)
                        inst:RemoveEventCallback("death", death_event, arm)
                    end
                    inst:ListenForEvent("death", death_event, arm)
                end
                return
            end
            return inst.temp_DoSpawnArm(inst, armpos, fx, ...)
        end

        inst.temp_SpawnCannons = inst.SpawnCannons
        inst.SpawnCannons = function(...)
            if inst:HasTag("chasni_crabqueen") then
                return
            end
            return inst.temp_SpawnCannons(...)
        end

        inst.temp_SetDamagedArt = inst.SetDamagedArt
        inst.SetDamagedArt = function(...)
            if inst:HasTag("chasni_crabqueen") then
                return
            end
            return inst.temp_SetDamagedArt(...)
        end

        inst.temp_SetRepairedArt = inst.SetRepairedArt
        inst.SetRepairedArt = function(...)
            if inst:HasTag("chasni_crabqueen") then
                return
            end
            return inst.temp_SetRepairedArt(...)
        end
    end)
end

-- CC : add new state for crabking, transform || chasni_windconch
local crabking_states = {
    State {
        name = "chasni_transform_pre",
        tags ={ "idle", "canrotate", "noattack", "inert", "canwxscan" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("disappear")
        end,
        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("chasni_transform_post")
                inst.AnimState:AddOverrideBuild("crab_king_winter_build")
                inst.AnimState:SetBuild("crab_king_winter_build")
            end)
        },
    },
    State {
        name = "chasni_transform_post",
        tags ={ "idle", "canrotate", "noattack", "inert", "canwxscan" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("reappear")
        end,
        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("inert")
            end)
        },
    },
}
for _, state in pairs(crabking_states) do
    AddStategraphState("crabking", state)
end
AddStategraphPostInit("crabking", function(sg)
    if sg.states["cast_loop"] then
        local _cast_loop_onenter = sg.states["cast_loop"].onenter
        sg.states["cast_loop"].onenter = function(inst, ...)
            if inst:HasTag("chasni_crabqueen") and inst.sg.statemem then
                inst:StartCastSpell(inst.dofreezecast)
                inst.SoundEmitter:PlaySound("hookline_2/creatures/boss/crabking/magic_LP","crabmagic")
                inst.AnimState:PlayAnimation("cast_blue_loop")
                inst.SoundEmitter:SetParameter("crabmagic", "intensity", 0)
                inst.sg.statemem.elapsedtime = 0
                inst.sg.statemem.wavetime = 100
            else
                _cast_loop_onenter(inst, ...)
            end
        end
    end
end)

-- CC : add new state for crabking_ckaw, castspell 
local crabkingclaw_states = {
    State {
        name = "chasni_castspell_pre",
        tags ={ "busy", "canrotate" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("sleep_pre")
            if inst.castfx then
                local x, y, z = inst.Transform:GetWorldPosition()
                chasni_spawnprefab(inst.castfx, x, y + 1, z)
            end
        end,
        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("chasni_castspell_post")
            end)
        },
    },

    State {
        name = "chasni_castspell_post",
        tags ={ "busy", "canrotate" },
        onenter = function(inst)
            inst.AnimState:PlayAnimation("sleep_pst")
            if inst.spell then
                inst:spell()
            end
        end,
        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end)
        },
    },

    State {
        name = "shot_pre",
        tags = { "attack", "busy" },
        onenter = function(inst, target)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("sleep_pre")
            inst.sg.statemem.target = target
        end,
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("shot_pst", inst.sg.statemem.target)
            end)
        },
    },

    State {
        name = "shot_pst",
        tags = { "attack", "busy" },
        onenter = function(inst, target)
            inst.AnimState:PlayAnimation("sleep_pst")
            inst.sg.statemem.target = target
        end,
        timeline = {
            TimeEvent(4*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end)
        },
        onexit = function(inst)
            inst.components.timer:StopTimer("attack_cd")
            inst.components.timer:StartTimer("attack_cd", 15 + math.random()*5)
        end,
    }
}
for _, state in pairs(crabkingclaw_states) do
    AddStategraphState("crabkingclaw", state)
end

-- CC : add frostbitten overlay
local HealthBadge = require("widgets/healthbadge")
local _OnUpdate = HealthBadge.OnUpdate
function HealthBadge:OnUpdate(...)
    _OnUpdate(self, ...)
    local frostbitten = self.owner:HasTag("frostbitten")
    if self._frostbitten ~= frostbitten then
        self._frostbitten = frostbitten
        if frostbitten then
            self.frostbittenoverlay:GetAnimState():PlayAnimation("activate")
            self.frostbittenoverlay:GetAnimState():PushAnimation("idle", true)
            self.frostbittenoverlay:Show()
        else
            self.frostbittenoverlay:GetAnimState():PlayAnimation("deactivate")
        end
    end
end
AddClassPostConstruct("widgets/healthbadge",function(self)
    self.frostbittenoverlay = self.underNumber:AddChild(UIAnim())
    self.frostbittenoverlay:GetAnimState():SetBank("frostbitten")
    self.frostbittenoverlay:GetAnimState():SetBuild("frostbitten_overlay")
    self.frostbittenoverlay:GetAnimState():PlayAnimation("deactivate")
    self.frostbittenoverlay:GetAnimState():AnimateWhilePaused(false)
    self.frostbittenoverlay.inst:ListenForEvent("animover", function(inst)
        if inst.AnimState:IsCurrentAnimation("deactivate") then
            inst.widget:Hide()
        end
    end)
    self.frostbittenoverlay:SetClickable(false)
    self.frostbittenoverlay:Hide()
    self._frostbitten = false
end)

-- CC : add frostbitten prevent heal
AddComponentPostInit("health", function(Health)
    local OldDoDelta = Health.DoDelta
    Health.DoDelta = function(self, amount, ...)
        if self.inst:HasTag("frostbitten") and amount > 0 then
            amount = 0
        end
        return OldDoDelta(self, amount, ...)
    end
end)

-- CC : staffcrab_dark ACTIONS.TOSS_MAP to spellcasting >> [Reward] expertwalter3
local function ActionCanSpellCastMap(act)
    if act.doer and act.invobject and act.invobject.CanSpellCastOnMap then
        return act.invobject:CanSpellCastOnMap(act.doer)
    end
    return false
end
local old_tossmap_fn = ACTIONS.TOSS_MAP.fn
ACTIONS.TOSS_MAP.fn = function(act)
    if act.invobject and act.invobject:HasTag("mapcasting") and ActionCanSpellCastMap(act) then
        act.from_map = true
        return ACTIONS.CASTSPELL.fn(act)
    end
    return old_tossmap_fn(act)
end
local tossmap_stroverridefn = ACTIONS.TOSS_MAP.stroverridefn
local tossmap_strfn = ACTIONS.TOSS_MAP.strfn
ACTIONS.TOSS_MAP.stroverridefn = function(act)
    if act.invobject and act.invobject:HasTag("mapcasting") then
        return STRINGS.ACTIONS.CASTSPELL_MAP
    end
    if tossmap_stroverridefn then
        return tossmap_stroverridefn(act)
    end
    if tossmap_strfn then
        return nil
    end
    return ACTIONS.TOSS_MAP.STRINGS
end
local old_castspell_fn = ACTIONS.CASTSPELL.fn
ACTIONS.CASTSPELL.fn = function(act)
    if act.from_map then
        act.doer:CloseMinimap()
    end
    return old_castspell_fn(act)
end

AddStategraphPostInit("wilson", function(sg)
    local _deststate = sg.actionhandlers[ACTIONS.TOSS_MAP].deststate
    sg.actionhandlers[ACTIONS.TOSS_MAP].deststate = function(inst, action, ...)
        if action.invobject and action.invobject:HasTag("mapcasting") then
            return "castspell"
        end
        if type(_deststate) == "string" then
            return _deststate
        else
            return _deststate(inst, action, ...)
        end
    end
end)
AddStategraphPostInit("wilson_client", function(sg)
    local _deststate = sg.actionhandlers[ACTIONS.TOSS_MAP].deststate
    sg.actionhandlers[ACTIONS.TOSS_MAP].deststate = function(inst, action, ...)
        if action.invobject and action.invobject:HasTag("mapcasting") then
            return "castspell"
        end
        if type(_deststate) == "string" then
            return _deststate
        else
            return _deststate(inst, action, ...)
        end
    end
end)

ACTIONS_MAP_REMAP[ACTIONS.CASTSPELL.code] = function(act, targetpos, ...)
    if act.doer == nil or act.invobject == nil then
        return nil
    end

    local min_dist = act.invobject.map_remap_min_dist
    local max_dist = act.invobject.map_remap_max_dist
    if min_dist or max_dist then
        local x, y, z = act.doer.Transform:GetWorldPosition()
        local dx, dz = targetpos.x - x, targetpos.z - z
        if dx == 0 and dz == 0 then
            dx = 1
        end
        local dist = math.sqrt(dx * dx + dz * dz)
        if min_dist and dist <= min_dist then
            targetpos.x = x + dx * (min_dist / dist)
            targetpos.z = z + dz * (min_dist / dist)
        elseif max_dist and dist >= max_dist then
            targetpos.x = x + dx * (max_dist / dist)
            targetpos.z = z + dz * (max_dist / dist)
        end
    end

    if TheWorld.Map:IsOceanTileAtPoint(targetpos.x, targetpos.y, targetpos.z) or not TheWorld.Map:IsVisualGroundAtPoint(targetpos.x, targetpos.y, targetpos.z) then
        return nil
    end

    local act_remap = BufferedAction(act.doer, nil, ACTIONS.TOSS_MAP, act.invobject, targetpos)
    if not ActionCanSpellCastMap(act_remap) then
        return nil
    end
    return act_remap
end

-- CC : crabstaff_ice frozen coldembrace state >> [RoG] crabstaff_ice stategraphs
AddStategraphState("wilson", State {
    name = "coldembrace",
    tags = { "busy", "frozen", "nopredict", "nodangle", "coldembrace" },
    onenter = function(inst)
        inst:AddTag("_coldembraced")
        if inst.components.pinnable ~= nil and inst.components.pinnable:IsStuck() then
            inst.components.pinnable:Unstick()
        end
        if inst.components.inventory:IsHeavyLifting() then
            inst.components.inventory:DropItem(inst.components.inventory:Unequip(GLOBAL.EQUIPSLOTS.BODY), true, true)
        end
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()

        inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
        inst.AnimState:PlayAnimation("frozen")
        inst.SoundEmitter:PlaySound("winterwyvern/winterwyvern/cold_embrace", "coldembrace", 0.3)

        inst.components.inventory:Hide()
        inst:PushEvent("ms_closepopups")
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:EnableMapControls(false)
            inst.components.playercontroller:Enable(false)
        end
    end,
    ontimeout = function(inst)
        inst.sg:GoToState("idle")
    end,
    onexit = function(inst)
        inst:RemoveTag("_coldembraced")
        inst.SoundEmitter:KillSound("coldembrace")
        inst.SoundEmitter:PlaySound("winterwyvern/winterwyvern/splinter_blast", nil, 0.3)
        inst.components.inventory:Show()
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:EnableMapControls(true)
            inst.components.playercontroller:Enable(true)
        end
        inst.AnimState:ClearOverrideSymbol("swap_frozen")
    end,
})

AddComponentPostInit("projectile", function(self)
    self.aimed_throw = false

    local old_SetLaunchOffset = self.SetLaunchOffset
    function self:SetLaunchOffset(offset, ...)
        old_SetLaunchOffset(self, offset, ...)
        self.base_launch_offset = offset
    end

    function self:UpdateLaunchOffset()
        if self.base_launch_offset then
            local scale = self.attacker and self.attacker.components.scaler and self.attacker.components.scaler.scale or 1

            self.launchoffset = Vector3(self.base_launch_offset.x * scale, self.base_launch_offset.y * scale, self.base_launch_offset.z * scale)
        end
    end

    function self:Chasni_AimedThrow(owner, attacker, target_pos, damage, is_alt)
        self.owner = owner
        self.attacker = attacker or owner
        self.damage = damage
        self.is_alt = is_alt
        self.start = owner:GetPosition()
        self.start_pos = owner:GetPosition()
        self.last_position = self.start_pos
        self.dest = target_pos
        self.aimed_throw = true

        if attacker and self.launchoffset then
            self:UpdateLaunchOffset()
            local x, y, z = self.inst.Transform:GetWorldPosition()
            local facing_angle = attacker.Transform:GetRotation() * _G.DEGREES
            self.inst.Transform:SetPosition(x + self.launchoffset.x * math.cos(facing_angle), y + self.launchoffset.y, z - self.launchoffset.x * math.sin(facing_angle))
        end

        self:RotateToTarget(self.dest)
        self.inst.Physics:SetMotorVel(self.speed, 0, 0)
        self.inst:StartUpdatingComponent(self)
        self.inst:PushEvent("onthrown", { thrower = attacker })
        if self.onthrown then
            self.onthrown(self.inst, attacker, target_pos)
        end
    end

    -- Copied from projectile
    local function StopTrackingDelayOwner(self)
        if self.delayowner ~= nil then
            self.inst:RemoveEventCallback("onremove", self._ondelaycancel, self.delayowner)
            self.inst:RemoveEventCallback("newstate", self._ondelaycancel, self.delayowner)
            self.delayowner = nil
        end
    end

    local old_Miss = self.Miss
    function self:Miss(target, ...)
        StopTrackingDelayOwner(self)
        old_Miss(self, target, ...)
    end

    function self:HitTarget(target)
        self.hit_targets = self.hit_targets or {}
        if not self.no_damage then
            if self.aimed_throw and self.attacker and self.owner and self.owner.components.weapon and not self.hit_targets[target] then
                if self.attacker:IsValid() and not self.cz_norepeat then
                    self.attacker.components.combat:DoAttack(target, self.owner, self.inst, self.stimuli, nil, self.damage)
                else
                    target.components.combat:GetAttacked(self.attacker, self.damage, self.owner.components.weapon, self.stimuli)
                end
                self.hit_targets[target] = true
            elseif self.attacker and self.attacker.components.combat and not self.hit_targets[target] then
                if self.attacker:IsValid() and not self.cz_norepeat then
                    self.attacker.components.combat:DoAttack(target)
                else
                    target.components.combat:GetAttacked(self.attacker, self.damage)
                end
                self.hit_targets[target] = true
            end
        end
        if self.onhit then
            self.onhit(self.inst, self.attacker, target)
        end
    end

    local old_Stop = self.Stop
    function self:Stop(...)
        old_Stop(self, ...)
        self.aimed_throw = false
    end

    local function CheckForTargets(_self)
        local current_pos = _self.inst:GetPosition()
        current_pos.y = 0
        local valid_targets = {}
        local target = nil
        local x, y, z = current_pos:Get()
        local ents = TheSim:FindEntities(x, y, z, 3, nil, { "FX", "INLIMBO", "notarget", "noattack", "invisible", "player"})
        for _,ent in ipairs(ents) do
            if ent.entity:IsValid() and ent.entity:IsVisible() and ent.components.health and not ent.components.health:IsDead() and not (ent == _self.attacker or ent == _self.owner) and ent.components.combat then
                local hit_range = ent:GetPhysicsRadius(0) + _self.hitdist
                local current_range = _G.distsq(current_pos, ent:GetPosition())
                if hit_range > current_range then
                    table.insert(valid_targets, {target = ent, hit_range = hit_range, current_range = current_range})
                end
            end
        end
        for _,data in pairs(valid_targets) do
            if not target or data.current_range - data.hit_range < target.range then
                target = {ent = data.target, range = data.current_range - data.hit_range}
                break
            end
        end
        if target and target.ent then
            _self:HitTarget(target.ent)
        end
    end

    self.distance_traveled = 0
    local old_OnUpdate = self.OnUpdate
    function self:OnUpdate(dt, ...)
        if self.aimed_throw then
            local current_pos = self.inst:GetPosition()
            current_pos.y = 0
            if self.aimed_throw and self.range and _G.distsq(self.start, current_pos) > self.range * self.range then
                self:Miss()
            else
                CheckForTargets(self)
            end
        else
            old_OnUpdate(self, dt, ...)
        end
    end
end)

-- CC : make "warf_emitter" targetable by mobs || warf_emitter >> [RoG] warf_emitter
AddComponentPostInit("combat", function(Combat)
    local oldShouldAggro = Combat.ShouldAggro
    function Combat:ShouldAggro(target, ignore_forbidden, ...)
        if target ~= nil and
                (self.shouldaggrofn == nil or self.shouldaggrofn(self.inst, target)) and
                (self.shouldavoidaggro == nil or not self.shouldavoidaggro[target]) and
                (target.components.combat == nil or target.components.combat.shouldavoidaggrofn == nil or target.components.combat.shouldavoidaggrofn(self.inst, target)) and
                --warfemitter
                (target:HasTag("warf_emitter") and not target:HasTag("noattack"))
        then
            return true
        end
        return oldShouldAggro(Combat, target, ignore_forbidden, ...)
    end
end)

-- CC : set constructionsite initialization "constructionplans" StartConstruction >> [RoG] pondstruction
AddComponentPostInit("constructionplans", function(ConstructionPlans)
    local oldStartConstruction = ConstructionPlans.StartConstruction
    function ConstructionPlans:StartConstruction(target, ...)
        local retval = oldStartConstruction(ConstructionPlans, target, ...)
        if retval and target and retval.prefab == "pondstruction" and not target:HasTag("chasni_researchproduct") then
            retval.originalpond = target.prefab
        end
        return retval
    end
end)

-- CC : give fish OverrideSymbol for "catchfish" State >> [RoG] upgraded_pond
if TheNet:GetIsServer() then
    local function oceanfish_postinit(inst)
        inst.build = "fish01" -- TODO : change to actual build
    end
    local oceanfish_prefabs = {
        "oceanfish_small_1_inv", "oceanfish_small_2_inv", "oceanfish_small_3_inv", "oceanfish_small_4_inv",
        "oceanfish_small_5_inv", "oceanfish_small_6_inv", "oceanfish_small_7_inv", "oceanfish_small_8_inv",
        "oceanfish_medium_1_inv", "oceanfish_medium_6_inv", "oceanfish_medium_7_inv", "oceanfish_medium_8_inv", "oceanfish_medium_9_inv",
    }
    for _, v in ipairs(oceanfish_prefabs) do
        AddPrefabPostInit(v, oceanfish_postinit)
    end
end

-- CC : give gofood destination tag to targets >> [RoG] warlyphone
local gofood_dest = require("constants/warlyphonedata").gofood_dest
for _, prefabname in pairs(gofood_dest) do
    AddPrefabPostInit(prefabname, function(inst)
        inst:AddTag("gofood_dest_"..prefabname)
    end)
end

-- CC : infinite fuel campfire >> [RoG] chasni_gas
if TheNet:GetIsServer() then
    AddPrefabPostInitAny(function(campfire)
        if campfire:HasTag("campfire") and campfire.components.burnable and campfire.components.fueled then
            local old_OnSave = campfire.OnSave
            campfire.OnSave = function(inst, data, ...)
                data._chasni_gas_fueled = inst._chasni_gas_fueled or false
                if old_OnSave then
                    old_OnSave(inst, data, ...)
                end
            end

            local old_OnLoad = campfire.OnLoad
            campfire.OnLoad = function(inst, data, ...)
                if data and data._chasni_gas_fueled == true then
                    inst._chasni_gas_fueled = true
                end
                if old_OnLoad then
                    old_OnLoad(inst, data, ...)
                end
            end
        end
    end)
end
AddComponentPostInit("fueled", function(fueled)
    local oldDoDelta = fueled.DoDelta
    function fueled:DoDelta(amount, doer, ...)
        if fueled and fueled.inst and fueled.inst._chasni_gas_fueled and amount < 0 then
            return
        end
        return oldDoDelta(fueled, amount, doer, ...)
    end

    local oldOnSave = fueled.OnSave
    function fueled:OnSave(...)
        local retval = oldOnSave(fueled, ...)
        if (not retval or not retval.fuel) and self.currentfuel == self.maxfuel and self.inst and self.inst._chasni_gas_fueled then
            retval = retval or {}
            retval.fuel = self.maxfuel
        end
        return retval
    end
end)

-- CC : change action turnon wording >> [Reward] warlyphone
local turnon_stroverridefn = ACTIONS.TURNON.stroverridefn
local turnon_strfn = ACTIONS.TURNON.strfn
ACTIONS.TURNON.stroverridefn = function(act)
    if act.target and act.target:HasTag("warlyphone") then
        return STRINGS.ACTIONS.PICKUP_WARLYPHONE
    end
    if turnon_stroverridefn then
        return turnon_stroverridefn(act)
    end
    if turnon_strfn then
        return nil
    end
    return ACTIONS.TURNON.STRINGS
end

-- CC : forcing techtree craft station logic >> [Reward] ROG tinkertower
AddClassPostConstruct("widgets/redux/craftingmenu_widget",function(self)
    local button_size = 38
    local filterdef = {name = "TINKER_TOWER", atlas = "images/inventoryimages/tinker_tower.xml", image = "tinker_tower.tex" }
    local w = self.filter_panel
    local filter_station = w:AddChild(self:MakeFilterButton(filterdef, button_size))
    local pt = self.crafting_station_filter:GetPosition()
    filter_station:SetPosition(pt.x, pt.y)
    self.filter_buttons[filterdef.name] = filter_station
    self.chasni_crafting_station_filter = filter_station

    local _ApplyFilters = self.ApplyFilters
    function self:ApplyFilters(...)
        local builder = self.owner ~= nil and self.owner.replica.builder or nil
        local prototyper = builder and builder:GetCurrentPrototyper()
        if builder ~= nil then
            if prototyper then
                if prototyper.prefab == "tinkertower" and (self.current_filter_name == "CRAFTING_STATION" or self._just_enter_tinkertower) then
                    self._just_enter_tinkertower = nil
                    if self.filter_buttons[self.current_filter_name] then
                        self.filter_buttons[self.current_filter_name].button:Unselect()
                    end
                    self.current_filter_name = "TINKER_TOWER"
                    if self.filter_buttons[self.current_filter_name] then
                        self.filter_buttons[self.current_filter_name].button:Select()
                    end
                elseif prototyper.prefab ~= "tinkertower" and (self.current_filter_name == "TINKER_TOWER" or self._just_out_tinkertower) then
                    self._just_out_tinkertower = nil
                    if self.previous_filter_name then
                        if self.filter_buttons[self.current_filter_name] then
                            self.filter_buttons[self.current_filter_name].button:Unselect()
                        end
                        self.current_filter_name = self.previous_filter_name
                        if self.filter_buttons[self.current_filter_name] then
                            self.filter_buttons[self.current_filter_name].button:Select()
                        end
                    end
                end
            else
                if self.current_filter_name == "TINKER_TOWER" then
                    if self.previous_filter_name then
                        if self.filter_buttons[self.current_filter_name] then
                            self.filter_buttons[self.current_filter_name].button:Unselect()
                        end
                        self.current_filter_name = self.previous_filter_name
                        if self.filter_buttons[self.current_filter_name] then
                            self.filter_buttons[self.current_filter_name].button:Select()
                        end
                    end
                end
            end
        end
        _ApplyFilters(self, ...)
    end

    local _UpdateFilterButtons = self.UpdateFilterButtons
    function self:UpdateFilterButtons(...)
        local retval = _UpdateFilterButtons(self, ...)
        local builder = self.owner ~= nil and self.owner.replica.builder or nil
        if builder ~= nil and self.chasni_crafting_station_filter then
            local prototyper = builder:GetCurrentPrototyper()
            if not builder:IsFreeBuildMode() and prototyper and prototyper.prefab == "tinkertower" then
                if not self.chasni_crafting_station_filter.shown then
                    self.chasni_crafting_station_filter:SetHoverText(STRINGS.UI.CRAFTING_FILTERS.TINKER_TOWER)
                    self.chasni_crafting_station_filter.filter_img:SetTexture("images/inventoryimages/tinker_tower.xml", "tinker_tower.tex")
                    self.chasni_crafting_station_filter.filter_img:ScaleToSize(54, 54)
                    self.chasni_crafting_station_filter:Show()
                    self.previous_filter_name = self.current_filter_name
                    self._just_out_tinkertower = nil
                    self._just_enter_tinkertower = true
                end
            else
                if self.chasni_crafting_station_filter.shown then
                    self.chasni_crafting_station_filter:Hide()
                    self._just_enter_tinkertower = nil
                    self._just_out_tinkertower = true
                end
            end
        end
        return retval
    end

    local _SelectFilter = self.SelectFilter
    function self:SelectFilter(...)
        self.previous_filter_name = nil
        return _SelectFilter(self, ...)
    end
end)