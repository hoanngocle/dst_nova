local assets =
{
    Asset("ANIM", "anim/backpack.zip"),
    Asset("ANIM", "anim/swap_krampus_sack.zip"),
    Asset("ANIM", "anim/ui_chasni_trinket_1x1.zip"),
}

local function CancelTask(inst)
    local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
    if inst._trinkettask then
        inst._trinkettask:Cancel()
        inst._trinkettask = nil
    end
    if inst._listeneractive and owner then
        owner:RemoveEventCallback(inst._listenerevent, inst._listenerfunction)
        inst._listeneractive = false
    end
    if inst._listeneractive2 and owner then
        owner:RemoveEventCallback(inst._listenerevent2, inst._listenerfunction2)
        inst._listeneractive2 = false
    end
    if inst._watchworldstateactive and owner then
        owner:StopWatchingWorldState(inst._watchworldevent, inst._watchworldfunction)
        inst._watchworldstateactive = false
    end

    if owner then
        if owner.components.locomotor  then
            owner.components.locomotor:RemoveExternalSpeedMultiplier(owner, "trinket")
        end
        if owner.components.combat  then
            owner.components.combat.externaldamagetakenmultipliers:RemoveModifier("trinket")
            owner.components.combat.externaldamagemultipliers:RemoveModifier("trinket")
        end

        if owner.components.rider and owner.components.rider:IsRiding() then
            local mount = owner.components.rider:GetMount()
            if mount and mount.components.combat then
                mount.components.combat.externaldamagemultipliers:RemoveModifier("trinket")
            end
        end

        if owner.components.luckuser then
            owner.components.luckuser:RemoveLuckSource("trinket")
        end

        if owner.components.locomotor and owner._originalfastmultiplier then
            owner.components.locomotor.fastmultiplier = owner._originalfastmultiplier
            owner._originalfastmultiplier = nil
        end

        if owner.components.sanity then
            owner.components.sanity:SetInducedInsanity("trinket", false)
        end

        if owner.components.grogginess ~= nil then
            owner.components.grogginess:RemoveImmunitySource("trinket")
        end
    end

    if inst._tag then
        inst:RemoveTag(inst._tag)
        inst._tag = nil
    end
    if owner then
        if inst._owneraddedtag then
            owner:RemoveTag(inst._owneraddedtag)
            inst._owneraddedtag = nil
        end
        if inst._ownerremovedtag then
            owner:AddTag(inst._ownerremovedtag)
            inst._ownerremovedtag = nil
        end
        if inst._owneraddedcomponent then
            owner:RemoveComponent(inst._owneraddedcomponent)
            inst._owneraddedcomponent = nil
        end
        if inst._ownerremovedcomponent then
            owner:AddComponent(inst._ownerremovedcomponent)
            inst._ownerremovedcomponent = nil
        end
    end

    local monkeyqueen = TheWorld.components.piratespawner and TheWorld.components.piratespawner.queen
    if monkeyqueen and monkeyqueen._affectedbylicenseplate then
        if monkeyqueen.components.timer:TimerExists("right_of_passage") then
            monkeyqueen.components.timer:SetTimeLeft("right_of_passage", 1)
        end
        monkeyqueen._affectedbylicenseplate = nil
    end
end

local function onequip(inst, owner)
    inst._owner = owner
    inst.components.container:Close(owner)
    inst.components.container:Open(owner)
end
local function onunequip(inst, owner)
    CancelTask(inst)
    inst.components.container:Close(owner)
end
local function OnDropped(inst)
    -- handling woodie transformation, fuck you woodie
    CancelTask(inst)
    if inst._owner and inst._owner.components.trinketowner then
        inst._owner.components.trinketowner:UpdateInventory(true)
    end
    inst.components.container:DropEverything()
    inst:Remove()
end

local function gettrinketprefab(inst)
    local prefabassociation = cz_trinkets.modded_trinkets[inst.prefab] and chasni_gettrinketassociation(inst)
    return prefabassociation and prefabassociation[1] or inst.prefab or nil
end

-- CC : PERIODIC : add heal task on combat with partner >> [Perk] Trinket Slot > Trinket_4 Trinket_13 || Gnomes
local COMBAT_TIMEOUT = 5
local function taskGnome(inst)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and (trinket.prefab == "trinket_4" or trinket.prefab == "trinket_13") then
        if inst.components.combat and inst.components.health and not inst.components.health:IsDead() and inst.components.sanity then
            local timeout_time = GetTime() - COMBAT_TIMEOUT
            local attack_time = math.max(inst.components.combat.laststartattacktime or -5, inst.components.combat.lastdoattacktime or -5)
            if attack_time < timeout_time then
                return
            end

            local targettrinket = trinket.prefab == "trinket_4" and "trinket_13" or "trinket_4"
            local gnomecount = 0
            local pos = Vector3(inst.Transform:GetWorldPosition())
            local ents = FindPlayersInRange(pos.x,pos.y,pos.z, 12)
            for i, v in ipairs(ents) do
                local othertrinket = chasni_getequippedtrinket(v)
                if othertrinket == targettrinket then
                    local otherattack_time = math.max(v.components.combat.lastwasattackedtime or -6, v.components.combat.lastdoattacktime or -6)
                    if otherattack_time >= timeout_time then
                        local stacksize = chasni_gettrinketpoint(trinket,  0.2, 5)
                        gnomecount = gnomecount + stacksize
                    end
                end
            end
            inst.components.sanity:DoDelta(gnomecount)
            inst.components.health:DoDelta(gnomecount)
        end
    end
end

-- CC : PERIODIC : remove inst and get gears >> [Perk] Trinket Slot > Trinket_11 || Lying Robot
local DISSASAMBLE_TIME = 0.5 * TUNING.TOTAL_DAY_TIME
local GEAR_COUNT_MIN = 3
local GEAR_COUNT_MAX = 8
local function taskRobot(inst)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_11" and trinket.components.stackable then
        trinket.components.stackable:Get():Remove()
        chasni_giveItem(inst, "gears", math.random(GEAR_COUNT_MIN, GEAR_COUNT_MAX))
    end
end

-- CC : LISTENER : give more marbles on "finishedwork" marbletree >> [Perk] Trinket Slot > trinket_1 || Melty Marbles
local MARBLE_COUNT_MIN = 1
local MARBLE_COUNT_MAX = 5
local function listenerMarbles(inst, data)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_1" and trinket.components.stackable and not trinket.components.stackable:IsFull() then
        if data and data.target and (data.target.prefab == "marbletree" or data.target.prefab == "marbleshrub") then
            local stacksize = trinket.components.stackable:StackSize()
            local stackgained = math.random(MARBLE_COUNT_MIN, MARBLE_COUNT_MAX)
            trinket.components.stackable:SetStackSize(stacksize + stackgained)
        end
    end
end

-- CC : LISTENER : gain hunger on "killed" smallcreature >> [Perk] Trinket Slot > trinket_10 || Second-hand Dentures
local function listenerDenture(inst, data)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_10" and trinket.components.stackable then
        if data and data.victim and data.victim:HasTag("smallcreature") and inst.components.hunger then
            local stacksize = chasni_gettrinketpoint(trinket,  0.4, 10)
            inst.components.hunger:DoDelta(stacksize)
        end
    end
end

-- CC : PERIODIC : give and remove ExternalSpeedMultiplier periodically >> [Perk] Trinket Slot > Trinket_5 || Tiny Rocketship
local BASE_SPEED_BOOST = 1.8
local BOOST_BUFFER_MIN = 30
local BOOST_BUFFER_MAX = 60
local BOOST_DURATION_MIN = 10
local BOOST_DURATION_MAX = 20
local function taskRockets(inst)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_5" and inst.components.locomotor then
        local stacksize = chasni_gettrinketpoint(trinket,  0.01, 0.4)
        chasni_spawnprefab("firework_fx", 0,0,0,1,1,1, inst.entity)
        inst.components.locomotor:SetExternalSpeedMultiplier(inst, "trinket", BASE_SPEED_BOOST + stacksize)
        if inst._trinkettask then
            inst._trinkettask:Cancel()
            inst._trinkettask = nil
        end
        inst._trinkettask = inst:DoTaskInTime(math.random(BOOST_DURATION_MIN, BOOST_DURATION_MAX), function()
            inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "trinket")
            if inst._trinkettask then
                inst._trinkettask:Cancel()
                inst._trinkettask = nil
            end
            inst._trinkettask = inst:DoTaskInTime(math.random(BOOST_BUFFER_MIN, BOOST_BUFFER_MAX), taskRockets)
        end)
    end
end

-- CC : LISTENER : give speed boost while mounting >> [Perk] Trinket Slot > trinket_30 || White Knight
local function listenerWKnightOn(inst, data)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_30" then
        if inst.components.locomotor then
            local stacksize = chasni_gettrinketpoint(trinket,  0.08, 1.2)
            inst.components.locomotor:SetExternalSpeedMultiplier(inst, "trinket", 1 + stacksize)
        end
    end
end
local function listenerWKnightOff(inst, data)
    if inst.components.locomotor then
        inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "trinket")
    end
end

-- CC : LISTENER : give damage boost while mounting >> [Perk] Trinket Slot > trinket_31 || Black Knight
local function listenerBKnightOn(inst, data)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_31" then
        if data and data.target and data.target.components.combat then
            local stacksize = chasni_gettrinketpoint(trinket,  0.1, 2)
            data.target.components.combat.externaldamagemultipliers:SetModifier("trinket", 1 + stacksize)
        end
    end
end
local function listenerBKnightOff(inst, data)
    if data and data.target and data.target.components.combat then
        data.target.components.combat.externaldamagemultipliers:RemoveModifier("trinket")
    end
end

-- CC : PERIODIC : befriend nearby catcoon >> [Perk] Trinket Slot > Trinket_22 || Frayed Yarn
local RANGE = 8
local FOLLOWER_ONEOF_TAGS = {"catcoon"}
local FOLLOWER_CANT_TAGS = {"werepig", "player"}
local function taskYarn(inst)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_22" then
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z, RANGE, nil, FOLLOWER_CANT_TAGS, FOLLOWER_ONEOF_TAGS)
        local stacksize = chasni_gettrinketpoint(trinket,  1, 1000)
        for k,v in pairs(ents) do
            if v.components.follower and not v.components.follower.leader and not inst.components.leader:IsFollower(v) and inst.components.leader.numfollowers < stacksize then
                if v:HasTag("catcoon") then
                    inst.components.leader:AddFollower(v)
                end
            end
        end

        for k,v in pairs(inst.components.leader.followers) do
            if k.components.follower and k:HasTag("catcoon") then
                k.components.follower:AddLoyaltyTime(3)
                if k.components.health then
                    k.components.health:SetPercent(1)
                end
            end
        end
    end
end

-- CC : LISTENER : damage refliect on "attacked" and "blocked" >> [Perk] Trinket Slot > trinket_32 || Cubic Zirkonia Ball
local function listenerZirkoniaBall(inst, data)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_32" then
        if (data and data.damageresolved and data.attacker and not data.redirected) then
            local stacksize = chasni_gettrinketpoint(trinket,  0.1, 3.3)
            if data.attacker.components.health and not data.attacker.components.health:IsDead() and data.attacker.components.combat then
                data.attacker.components.combat:GetAttacked(inst, data.damageresolved * stacksize)
            end
        end
    end
end

-- CC : WATCHWORLD : change damage multiplier based on phase >> [Perk] Trinket Slot > trinket_36 || Faux Fangs
local function watchWorldFauxFangs(inst)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_36" then
        if inst.components.combat then
            local stacksize = chasni_gettrinketpoint(trinket,  0.03, 0.69)
            local bonusdamage = 0.3 + stacksize
            local damagemult = (TheWorld.state.phase == "night" and 1 + bonusdamage) or (TheWorld.state.phase == "day" and 1 - bonusdamage) or 1
            inst.components.combat.externaldamagemultipliers:SetModifier("trinket", damagemult)
        end
    end
end

-- CC : LISTENER : chance instakill onhitother shadow creature >> [Perk] Trinket Slot > trinket_37 || Broken Stake
local function listenerBrokenStake(inst, data)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_37" then
        if data and data.target and data.target.components.health and data.target:HasTag("shadowcreature") then
            local stacksize = chasni_gettrinketpoint(trinket,  0.04, 0.8)
            if math.random() < stacksize then
                data.target.components.health:Kill()
            end
        end
    end
end

-- CC : LISTENER : gain hunger on "killed" smallcreature >> [Perk] Trinket Slot > trinket_42 || Toy Cobra
local function listenerCobra(inst, data)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_42" then
        if data and data.victim and data.victim:HasTag("smallcreature") and inst.components.health then
            local stacksize = chasni_gettrinketpoint(trinket,  0.2, 5)
            inst.components.health:DoDelta(stacksize)
        end
    end
end

-- CC : LISTENER : chance instakill onhitother swimming creature >> [Perk] Trinket Slot > trinket_43 || Crocodile Toy
local function listenerCrocodile(inst, data)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_43" then
        if data and data.target and data.target.components.health and data.target:HasTag("swimming") then
            local stacksize = chasni_gettrinketpoint(trinket,  0.1, 1)
            if math.random() < stacksize then
                data.target.components.health:Kill()
            end
        end
    end
end

-- CC : LISTENER : avoid death on minhealth >> [Perk] Trinket Slot > trinket_44 || Broken Terrarium
local function listenerTerrarium(inst, data)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_44" then
        inst.components.health.currenthealth = 0.1
        trinket.components.stackable:Get():Remove()
        chasni_spawnprefab("superjump_fx", 0,0,0, 1, 1, 1, inst.entity)
    end
end

-- CC : LISTENER : auto repair "chasni_leak_spawned_on_boat" >> [Perk] Trinket Slot > trinket_8 || Hardened Rubber Bung
local function listenerRubberBung(inst, data)local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_8" then
        local stacksize = chasni_gettrinketpoint(trinket,  0.5, 5)
        local waittime = 5.5 - stacksize
        data.leak:DoTaskInTime(waittime, function(_inst)
            _inst.AnimState:PlayAnimation("leak_small_pst")
            _inst:DoTaskInTime(0.4, function(__inst)
                __inst.components.boatleak:SetState("repaired")
            end)
        end)
    end
end

-- CC : LISTENER : auto stop burning and smoldering "chasni_onsmoldering_nearby", "chasni_onburning_nearby" >> [Perk] trinket_chasni_18a / trinket_chasni_18b || Wine Bottle Candle / Soaked Candle
local function listenerCandles(inst, data)
    local trinket = chasni_getequippedtrinket(inst)
    local trinketname = trinket and gettrinketprefab(trinket)
    if trinketname and (trinketname == "trinket_chasni_18a" or trinketname == "trinket_chasni_18b") then
        if data and data.item and data.item.components.burnable then
            data.item:DoTaskInTime(0.5, function(_inst)
                if _inst.components.burnable:IsBurning() then
                    _inst.components.burnable:Extinguish()
                elseif _inst.components.burnable:IsSmoldering() then
                    _inst.components.burnable:StopSmoldering()
                end
            end)
        end
    end
end

-- CC : LISTENER : Remove stack on "attacked" >> [Perk] Trinket Slot > trinket_chasni_14 || Ancient Vase
local function listenerAncientVase(inst, data)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_chasni_14" then
        trinket.components.stackable:Get():Remove()
        chasni_spawnprefab("coconut_chunks", 0,0,0, 1, 1, 1, inst.entity)
        inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/glass_break")
    end
end

-- CC : PERIODIC : give and remove ExternalSpeedMultiplier periodically >> [Perk] Trinket Slot > trinket_chasni_9 || Orange Soda
local SODA_BASE_SPEED_BOOST = 1.5
local SODA_BOOST_BUFFER_MIN = 15
local SODA_BOOST_BUFFER_MAX = 30
local SODA_BOOST_DURATION_MIN = 5
local SODA_BOOST_DURATION_MAX = 10
local function taskSoda(inst)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_chasni_9" and inst.components.locomotor then
        local stacksize = chasni_gettrinketpoint(trinket,  0.01, 0.4)
        chasni_spawnprefab("chasni_green_bubble_mid_buff_fx", 0,0,0,1,1,1, inst.entity)
        inst.components.locomotor:SetExternalSpeedMultiplier(inst, "trinket", SODA_BASE_SPEED_BOOST + stacksize)
        if inst._trinkettask then
            inst._trinkettask:Cancel()
            inst._trinkettask = nil
        end
        inst._trinkettask = inst:DoTaskInTime(math.random(SODA_BOOST_DURATION_MIN, SODA_BOOST_DURATION_MAX), function()
            inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "trinket")
            if inst._trinkettask then
                inst._trinkettask:Cancel()
                inst._trinkettask = nil
            end
            inst._trinkettask = inst:DoTaskInTime(math.random(SODA_BOOST_BUFFER_MIN, SODA_BOOST_BUFFER_MAX), taskSoda)
        end)
    end
end

-- CC : PERIODIC : tend nearby plants >> [Perk] Trinket Slot > trinket_chasni_11 || Lying Robot
local TEND_TICK_TIME = 1
local function taskUkulele(inst)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_chasni_11" then
        local ix, iy, iz = inst.Transform:GetWorldPosition()
        local nearby_tendable_plants = TheSim:FindEntities(ix, iy, iz, 8, {"tendable_farmplant"})
        for _, tendable_plant in pairs(nearby_tendable_plants) do
            tendable_plant.components.farmplanttendable:TendTo(inst)
        end
    end
end

-- CC : LISTENER : warp back onhitother >> [Perk] Trinket Slot > trinket_chasni_20 || Floppy Disc
local function listenerFloppyDisc(inst, data)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_chasni_20" then
        if inst.components.chasnipositionalwarp then
            local tx, ty, tz = inst.components.chasnipositionalwarp:GetHistoryPosition(false)
            if tx ~= nil then
                --inst.components.rechargeable:Discharge(TUNING.POCKETWATCH_WARP_COOLDOWN)
                inst.cz_warpdata = {dest_x = tx, dest_y = ty, dest_z = tz}
                inst.sg:GoToState("chasni_warpback")
            end
        end
    end
end

-- CC : LISTENER : spawn moonbutterfly on builditem >> [Perk] Trinket Slot > trinket_chasni_20 || Framed Dead Spritter
local function listenerSpritter(inst, data)
    local trinket = chasni_getequippedtrinket(inst)
    if trinket and trinket.prefab == "trinket_chasni_24" then
        if data and data.recipe and data.recipe.name then
            if CRAFTING_FILTERS and CRAFTING_FILTERS.MODS and CRAFTING_FILTERS.MODS.default_sort_values and CRAFTING_FILTERS.MODS.default_sort_values[data.recipe.name] then
                local x, y, z = inst.Transform:GetWorldPosition()
                local butterfly = chasni_spawnprefab("moonbutterfly", x, y, z)
                if butterfly and butterfly.components.lootdropper then
                    butterfly.components.lootdropper:AddChanceLoot("butter", 0.1)
                end
            end
        end
    end
end

local function ItemGet(inst, data)
    if data and data.item then
        local prefabname = gettrinketprefab(data.item)
        ---------------------------[[ GNOME ]]------------------------------
        if (prefabname == "trinket_4" or prefabname == "trinket_13") then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                inst._trinkettask = owner:DoPeriodicTask(1, taskGnome)
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ ROBOT ]]------------------------------
        if prefabname == "trinket_11" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                inst._trinkettask = owner:DoPeriodicTask(DISSASAMBLE_TIME, taskRobot)
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        --------------------------[[ MARBLES ]]------------------------------
        if prefabname == "trinket_1" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                inst._listenerfunction = listenerMarbles
                inst._listenerevent = "finishedwork"
                owner:ListenForEvent(inst._listenerevent, inst._listenerfunction)
                inst._listeneractive = true
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        --------------------------[[ DENTURE ]]------------------------------
        if prefabname == "trinket_10" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                inst._listenerfunction = listenerDenture
                inst._listenerevent = "killed"
                owner:ListenForEvent(inst._listenerevent, inst._listenerfunction)
                inst._listeneractive = true
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        --------------------------[[ ROCKETS ]]------------------------------
        if prefabname == "trinket_5" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                inst._trinkettask = owner:DoTaskInTime(math.random(BOOST_BUFFER_MIN, BOOST_BUFFER_MAX), taskRockets)
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ HANGER ]]------------------------------
        if prefabname == "trinket_27" then
            CancelTask(inst)
            inst._tag = "bramble_resistant"
            inst:AddTag(inst._tag)
        end
        ----------------------------[[ TROJAN ]]--------------------------------
        if prefabname == "trinket_18" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                local addtag = "cz_animallover"
                inst._owneraddedtag = not owner:HasTag(addtag) and addtag or nil
                if inst._owneraddedtag then
                    owner:AddTag(inst._owneraddedtag)
                end

                local removetag = "scarytoprey"
                inst._ownerremovedtag = owner:HasTag(removetag) and removetag or nil
                if inst._ownerremovedtag then
                    owner:RemoveTag(inst._ownerremovedtag)
                end
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ----------------------------[[ JAR ]]--------------------------------
        if prefabname == "trinket_24" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                if owner.components.luckuser and data.item.stackable then
                    local stacksize = chasni_gettrinketpoint(data.item,  0.2, 5)
                    owner.components.luckuser:SetLuckSource(stacksize, "trinket")
                end
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        --------------------------[[ WKNIGHT ]]------------------------------
        if prefabname == "trinket_30" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                if owner.components.rider then
                    inst._listenerfunction = listenerWKnightOn
                    inst._listenerevent = "mounted"
                    owner:ListenForEvent(inst._listenerevent, inst._listenerfunction)
                    inst._listeneractive = true

                    inst._listenerfunction2 = listenerWKnightOff
                    inst._listenerevent2 = "dismounted"
                    owner:ListenForEvent(inst._listenerevent2, inst._listenerfunction2)
                    inst._listeneractive2 = true
                    if owner.components.rider:IsRiding() then
                        listenerWKnightOn(owner, {target = owner.components.rider:GetMount()})
                    end
                end
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        --------------------------[[ BKNIGHT ]]------------------------------
        if prefabname == "trinket_31" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                if owner.components.rider then
                    inst._listenerfunction = listenerBKnightOn
                    inst._listenerevent = "mounted"
                    owner:ListenForEvent(inst._listenerevent, inst._listenerfunction)
                    inst._listeneractive = true

                    inst._listenerfunction2 = listenerBKnightOff
                    inst._listenerevent2 = "dismounted"
                    owner:ListenForEvent(inst._listenerevent2, inst._listenerfunction2)
                    inst._listeneractive2 = true
                    if owner.components.rider:IsRiding() then
                        listenerBKnightOn(owner, {target = owner.components.rider:GetMount()})
                    end
                end
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ----------------------------[[ YARN ]]-------------------------------
        if prefabname == "trinket_22" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                inst._trinkettask = owner:DoPeriodicTask(3, taskYarn)
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ SHOE ]]--------------------------------
        if prefabname == "trinket_23" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                local removecomponent = "slipperyfeet"
                inst._ownerremovedcomponent = owner.components[removecomponent] and removecomponent or nil
                if inst._ownerremovedcomponent then
                    owner:RemoveComponent(inst._ownerremovedcomponent)
                end

                local addtag = "enchantmemento_trinket_23"
                inst._owneraddedtag = not owner:HasTag(addtag) and addtag or nil
                if inst._owneraddedtag then
                    owner:AddTag(inst._owneraddedtag)
                end
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ POTATO ]]-------------------------------
        if prefabname == "trinket_26" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                local addtag = "enchantmemento_trinket_26"
                inst._owneraddedtag = not owner:HasTag(addtag) and addtag or nil
                if inst._owneraddedtag then
                    owner:AddTag(inst._owneraddedtag)
                end
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Cubic Zirkonia Ball ]]-------------------------------
        if prefabname == "trinket_32" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                if owner.components.combat then
                    owner.components.combat.externaldamagetakenmultipliers:SetModifier("trinket", 2)
                end
                inst._listenerfunction = listenerZirkoniaBall
                inst._listenerevent = "blocked"
                owner:ListenForEvent(inst._listenerevent, inst._listenerfunction)
                inst._listeneractive = true

                inst._listenerfunction2 = listenerZirkoniaBall
                inst._listenerevent2 = "attacked"
                owner:ListenForEvent(inst._listenerevent2, inst._listenerfunction2)
                inst._listeneractive2 = true
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Faux Fangs ]]-------------------------------
        if prefabname == "trinket_36" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                watchWorldFauxFangs(owner)
                inst._watchworldfunction = watchWorldFauxFangs
                inst._watchworldevent = "phase"
                owner:WatchWorldState(inst._watchworldevent, inst._watchworldfunction)
                inst._watchworldstateactive = true
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Broken Stake ]]-------------------------------
        if prefabname == "trinket_37" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                inst._listenerfunction = listenerBrokenStake
                inst._listenerevent = "onhitother"
                owner:ListenForEvent(inst._listenerevent, inst._listenerfunction)
                inst._listeneractive = true
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        --------------------------[[ TOY COBRA ]]------------------------------
        if prefabname == "trinket_42" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                inst._listenerfunction = listenerCobra
                inst._listenerevent = "killed"
                owner:ListenForEvent(inst._listenerevent, inst._listenerfunction)
                inst._listeneractive = true
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Crocodile Toy ]]-------------------------------
        if prefabname == "trinket_43" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                inst._listenerfunction = listenerCrocodile
                inst._listenerevent = "onhitother"
                owner:ListenForEvent(inst._listenerevent, inst._listenerfunction)
                inst._listeneractive = true
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Broken Terrarium ]]-------------------------------
        if prefabname == "trinket_44" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                inst._listenerfunction = listenerTerrarium
                inst._listenerevent = "minhealth"
                owner:ListenForEvent(inst._listenerevent, inst._listenerfunction)
                inst._listeneractive = true
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Lone Glove ]]-------------------------------
        if prefabname == "trinket_39" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                local addtag = "enchantmemento_trinket_39"
                inst._owneraddedtag = not owner:HasTag(addtag) and addtag or nil
                if inst._owneraddedtag then
                    owner:AddTag(inst._owneraddedtag)
                end
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Dessicated Tentacle ]]-------------------------------
        if prefabname == "trinket_12" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                local addtag = "enchantmemento_trinket_12"
                inst._owneraddedtag = not owner:HasTag(addtag) and addtag or nil
                if inst._owneraddedtag then
                    owner:AddTag(inst._owneraddedtag)
                end
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Hardened Rubber Bung ]]-------------------------------
        if prefabname == "trinket_8" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                inst._listenerfunction = listenerRubberBung
                inst._listenerevent = "chasni_leak_spawned_on_boat"
                owner:ListenForEvent(inst._listenerevent, inst._listenerfunction)
                inst._listeneractive = true
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Candles ]]-------------------------------
        if prefabname == "trinket_chasni_18a" or prefabname == "trinket_chasni_18b" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then 
                inst._listenerfunction = listenerCandles
                inst._listenerevent = "chasni_onsmoldering_nearby"
                owner:ListenForEvent(inst._listenerevent, inst._listenerfunction)
                inst._listeneractive = true

                inst._listenerfunction2 = listenerCandles
                inst._listenerevent2 = "chasni_onburning_nearby"
                owner:ListenForEvent(inst._listenerevent2, inst._listenerfunction2)
                inst._listeneractive2 = true
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Old Boot ]]-------------------------------
        if prefabname == "trinket_chasni_13" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                if owner.components.locomotor then
                    owner._originalfastmultiplier = owner.components.locomotor.fastmultiplier
                    local stacksize = chasni_gettrinketpoint(data.item,  0.1, 1.7)
                    owner.components.locomotor.fastmultiplier = 1.3 + stacksize
                end
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Ancient Vase ]]-------------------------------
        if prefabname == "trinket_chasni_14" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                if owner.components.combat then
                    local stacksize = chasni_gettrinketpoint(data.item,  0.05, 2)
                    local damagemult = 1 + stacksize
                    owner.components.combat.externaldamagemultipliers:SetModifier("trinket", damagemult)
                    inst._listenerfunction = listenerAncientVase
                    inst._listenerevent = "attacked"
                    owner:ListenForEvent(inst._listenerevent, inst._listenerfunction)
                    inst._listeneractive = true
                end
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Brain Cloud Pill ]]-------------------------------
        if prefabname == "trinket_chasni_15" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                if owner.components.sanity then
                    owner.components.sanity:SetInducedInsanity("trinket", true)
                end
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ License Plate ]]-------------------------------
        if prefabname == "trinket_chasni_12" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                local monkeyqueen = TheWorld.components.piratespawner and TheWorld.components.piratespawner.queen
                if monkeyqueen then
                    monkeyqueen._affectedbylicenseplate = true
                    if monkeyqueen.components.timer:TimerExists("right_of_passage") then
                        monkeyqueen.components.timer:SetTimeLeft("right_of_passage", TUNING.TOTAL_DAY_TIME)
                    else
                        monkeyqueen.components.timer:StartTimer("right_of_passage", TUNING.TOTAL_DAY_TIME)
                    end
                end
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Post Card ]]--------------------------------
        if prefabname == "trinket_chasni_7" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                local addtag = "enchantmemento_trinket_chasni_7"
                inst._owneraddedtag = not owner:HasTag(addtag) and addtag or nil
                if inst._owneraddedtag then
                    owner:AddTag(inst._owneraddedtag)
                end
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        --------------------------[[ Orange Soda ]]------------------------------
        if prefabname == "trinket_chasni_9" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                inst._trinkettask = owner:DoTaskInTime(math.random(SODA_BOOST_BUFFER_MIN, SODA_BOOST_BUFFER_MAX), taskSoda)
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Ukulele ]]------------------------------
        if prefabname == "trinket_chasni_11" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                inst._trinkettask = owner:DoPeriodicTask(TEND_TICK_TIME, taskUkulele)
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Floppy Disc ]]--------------------------------
        if prefabname == "trinket_chasni_20" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                local addedcomponent = "chasnipositionalwarp"
                inst._owneraddedcomponent = not owner.components[addedcomponent] and addedcomponent or nil
                if inst._owneraddedcomponent then
                    local comp = owner:AddComponent(inst._owneraddedcomponent)
                    comp:EnableMarker(false)
                    comp:SetMarker("pocketwatch_warp_marker")
                end

                inst._listenerfunction = listenerFloppyDisc
                inst._listenerevent = "onhitother"
                owner:ListenForEvent(inst._listenerevent, inst._listenerfunction)
                inst._listeneractive = true
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Dev Mug ]]--------------------------------
        if prefabname == "trinket_chasni_21" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                if owner.components.grogginess then
                    owner.components.grogginess:AddImmunitySource("trinket")
                end
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Toy Boat ]]--------------------------------
        if prefabname == "trinket_chasni_17" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                local addtag = "enchantmemento_trinket_chasni_17"
                inst._owneraddedtag = not owner:HasTag(addtag) and addtag or nil
                if inst._owneraddedtag then
                    owner:AddTag(inst._owneraddedtag)
                end
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
        ---------------------------[[ Framed Dead Spritter ]]--------------------------------
        if prefabname == "trinket_chasni_24" then
            CancelTask(inst)
            local owner = inst._owner or inst.components.inventoryitem:GetGrandOwner()
            if owner then
                inst._listenerfunction = listenerSpritter
                inst._listenerevent = "builditem"
                owner:ListenForEvent(inst._listenerevent, inst._listenerfunction)
                inst._listeneractive = true

                inst._listenerfunction2 = listenerSpritter
                inst._listenerevent2 = "buildstructure"
                owner:ListenForEvent(inst._listenerevent2, inst._listenerfunction2)
                inst._listeneractive2 = true
            else
                inst:DoTaskInTime(.3,function() ItemGet(inst, data) end)
            end
        end
    end
end

local function ItemLose(inst)
    CancelTask(inst)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("backpack1")
    inst.AnimState:SetBuild("swap_krampus_sack")
    inst.AnimState:PlayAnimation("anim")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
    inst.components.inventoryitem.keepondeath = true

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.CHASNI_TRINKET_CONTAINERS
    inst.components.equippable:SetPreventUnequipping(true)
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("trinketslot")
    inst.components.container.skipopensnd = true
    inst.components.container.skipclosesnd = true
    inst.components.container.stay_open_on_hide = true

    inst:ListenForEvent("itemget", ItemGet)
    inst:ListenForEvent("gotnewitem", ItemGet)
    inst:ListenForEvent("stacksizechange", ItemGet)
    inst:ListenForEvent("itemlose", ItemLose)
    inst:ListenForEvent("ondropped", OnDropped)
    inst:Hide()

    return inst
end

return Prefab("trinketslot", fn, assets)