GLOBAL.setmetatable(env,{__index=function(_,k) return GLOBAL.rawget(GLOBAL,k) end})

require "functions/helperfunctions"
local SpDamageUtil = require("components/spdamageutil")
local UpvalueHacker = require "functions/upvaluehacker"

-- CC : handle playertagging >> [GLOBAL] Player tagging
local function HasCraftedCritter(inst, crittername)
    if inst.craftedcritter then
        local str = inst.craftedcritter:value()
        if not str or str == "" then return false end
        for name in string.gmatch(str, "[^,]+") do
            if name == crittername then
                return true
            end
        end
    end
    return false
end
local CHASNI_TAGS =
{
    inherentshadowdominance = true,     -- chasni_shadow_monster_chip
    shadowdominance = true,             -- chasni_shadow_monster_chip
    moonstormevent_detector = true,     -- chasni_moon_soul_chip
    wet = true,                         -- water_spear, chasni_critter_fish_wet_a
}
local function IsTrackedChasniTag(tag)
    return tag ~= nil and CHASNI_TAGS[tag]
end
local function chasnigettag(inst, tag)
    if string.sub(tag, 1, 6) == "expert" then
        return inst["current"..tag] and inst["current"..tag]:value() == 1
    end
    local chartagpattern = "chasni_(.+)"
    if string.match(tag, chartagpattern) == inst.prefab then
        return true
    end

    local buildertagpattern = "chasni_builder_(.+)"
    local buildertag = string.match(tag, buildertagpattern)
    if buildertag then
        return inst["current"..buildertag] and inst["current"..buildertag]:value() == 1
    end

    -- CC : ser have built >> [Perk] duppercritter
    local craftedcrittertagpattern = "^chasni_critter_(.*)_builder_free$"
    local craftedcrittertag = string.match(tag, craftedcrittertagpattern)
    if craftedcrittertag then
        return chasnigettag(inst, "chasni_builder_duppercritter") and HasCraftedCritter(inst, craftedcrittertag)
    end

    -- CC : add stronggrip version "enchantmemento_trinket_39" >> [Perk] Trinket Slot > Trinket_39 || Lone Glove
    if tag == "stronggrip" and inst:HasTag("enchantmemento_trinket_39") then
        return true
    end

    -- CC : pig_house returned is sieastahut if not on cave or isday >> [Perk] Trinket Slot > trinket_chasni_7 || Post Card of the Royal Palace
    if tag == "siestahut" and inst:HasTag("pig_house") then
        return not TheWorld:HasTag("cave") and TheWorld.state.isday
    end

    -- CC : allow build planted carrot >> [Perk] groundedscream || chesspiece_carrat_stone
    if tag == "cz_chesspiece_carrat_stone" then
        return inst:HasTag("player") and chasni_checkifgroundedexists("chesspiece_carrat_stone")
    end

    -- CC : prevent heated beefalo target >> [Perk] groundedscream || chesspiece_beefalo_marble
    if tag == "cz_chesspiece_beefalo_marble" then
        return inst:HasTag("player") and chasni_checkifgroundedexists("chesspiece_beefalo_marble")
    end

    -- CC : allow to sleep in rabbit house >> [Perk] groundedscream || chesspiece_manrabbit_moonglass
    if tag == "cz_chesspiece_manrabbit_moonglass" then
        return inst:HasTag("player") and chasni_checkifgroundedexists("chesspiece_manrabbit_moonglass")
    end

    -- CC : allow build glowberry >> [Perk] groundedscream || chesspiece_yots_marble
    if tag == "cz_chesspiece_yots_marble" then
        return inst:HasTag("player") and chasni_checkifgroundedexists("chesspiece_yots_marble")
    end

    return false
end
AddPrefabPostInitAny(function(inst)
    local _HasTag = inst.HasTag
    inst.HasTag = function(_inst, tag, ...)
        return _HasTag(_inst, tag, ...) or chasnigettag(_inst, tag)
    end
    local _HasTags = inst.HasTags
    inst.HasTags = function(_inst, ...)
        local filteredArgs = {}

        for i = 1, select("#", ...) do
            local _tag = select(i, ...)
            if type(_tag) == "string" then
                if not chasnigettag(_inst, _tag) then
                    table.insert(filteredArgs, _tag)
                end
            elseif type(_tag) == "table" then
                local nestedtable = _inst:HasTags(unpack(_tag))
                if nestedtable == false then
                    return false
                end
            else
                return _HasTags(_inst, ...)
            end
        end
        if #filteredArgs == 0 then
            return true
        end
        return _HasTags(_inst, unpack(filteredArgs))
    end
    inst.HasAllTags = inst.HasTags

    local _HasOneOfTags = inst.HasOneOfTags
    inst.HasOneOfTags = function(_inst, ...)
        for i = 1, select("#", ...) do
            local _tag = select(i, ...)
            if type(_tag) == "string" then
                if chasnigettag(_inst, _tag) then
                    return true
                end
            elseif type(_tag) == "table" then
                return _inst:HasOneOfTags(unpack(_tag))
            end
        end
        return _HasOneOfTags(_inst, ...)
    end
    inst.HasAnyTag = inst.HasOneOfTags

    local _AddTag = inst.AddTag
    inst.AddTag = function(_inst, tag, ...)
        if IsTrackedChasniTag(tag) then
            _inst._oritag = _inst._oritag or {}
            if tag and _inst._oritag then
                _inst._oritag[tag] = true
            end
        end

        return _AddTag(_inst, tag, ...)
    end

    local _RemoveTag = inst.RemoveTag
    inst.RemoveTag = function(_inst, tag, ...)
        if IsTrackedChasniTag(tag) then
            _inst._oritag = _inst._oritag or {}
            if tag and _inst._oritag then
                _inst._oritag[tag] = nil
            end
            if _inst._forcetag == nil then
                _inst._forcetag = {}
            end
            if tag and _inst._forcetag and _inst._forcetag[tag] then
                return
            end
        end
        return _RemoveTag(_inst, tag, ...)
    end

    inst.Chasni_AddTag  = function(_inst, tag, ...)
        _inst._forcetag = _inst._forcetag or {}
        if tag and _inst._forcetag then
            _inst._forcetag[tag] = true
        end
        return _AddTag(_inst, tag, ...)
    end

    inst.Chasni_RemoveTag  = function(_inst, tag, ...)
        _inst._forcetag = _inst._forcetag or {}
        if tag and _inst._forcetag then
            _inst._forcetag[tag] = nil
        end
        if tag and _inst._oritag and _inst._oritag[tag] then
            return
        end
        return _RemoveTag(_inst, tag, ...)
    end

    local _HasTag = inst.HasTag
    inst.HasTag = function(_inst, tag, ...)
        return _HasTag(_inst, tag, ...) or chasnigettag(_inst, tag)
    end
end)

-- CC : give killing xp and achievement count to player and follower >> [GLOBAL] XP and ACHIEVEMENT KILL EVENT
if TheNet:GetIsServer() then
    local function killevent_postinit(inst)
        inst:ListenForEvent("killed", function(killer, data)
            local victim = data.victim
            if victim then
                chasni_checkkilllevel(victim)
                chasni_checkslayachievement(killer, victim)
            end
        end)
    end
    local follower_prefabs = {
        "shadowtentacle",
        "abigail", "bernie_big", "bernie_active",
        "shadowworker", "shadowprotector", "shadowduelist",
        "mermprotector", "chasni_fluffy",
    }

    for _, v in ipairs(follower_prefabs) do
        AddPrefabPostInit(v, killevent_postinit)
    end
end

-- CC : set dest action into lunge for fire_spear and shovel dig for shovel and book for voker_book and panning for fryingpan >> [Reward] expertwillow3 & shovel & voker_book
AddStategraphPostInit("wilson", function(inst)
    local deststate = inst.actionhandlers[ACTIONS.CASTSPELL].deststate
    inst.actionhandlers[ACTIONS.CASTSPELL].deststate = function(_inst, action, ...)
        if action.invobject:HasTag("fire_spear") then
            return "combat_lunge_start"
        end
        if action.invobject:HasTag("castspell_shovel") then
            return "shoveldig_pre"
        end
        if action.invobject:HasTag("book_voker") then
            return "book"
        end
        if action.invobject:HasTag("castspell_fryingpan") then
            return "pan_start"
        end
        if type(deststate) == "string" then
            return deststate
        else
            return deststate(_inst, action, ...)
        end
    end
end)
AddStategraphPostInit("wilson_client", function(inst)
    local deststate = inst.actionhandlers[ACTIONS.CASTSPELL].deststate
    inst.actionhandlers[ACTIONS.CASTSPELL].deststate = function(_inst, action, ...)
        if action.invobject:HasTag("fire_spear") then
            return "combat_lunge_start"
        end
        if action.invobject:HasTag("castspell_shovel") then
            return "shoveldig_pre"
        end
        if action.invobject:HasTag("book_voker") then
            return "book"
        end
        if action.invobject:HasTag("castspell_fryingpan") then
            return "pan_start"
        end
        if type(deststate) == "string" then
            return deststate
        else
            return deststate(_inst, action, ...)
        end
    end
end)

-- CC : GLOBAL POSTINIT : COMBAT HELPER |
-- expertwx4 taskskillwilson crabstaff_ice expertwicker3 expertwillow4 expertworm2 expertwonk1 expertwx2
-- expertwaxwell2 expertwalter4 supercritter trinketslot expertwaxwell4 expertwoodie3  
-- expertwalter3 expertwarly4 taskskillworm expertwinona2 taskskillwurt taskskillwortox new_crabking_claw expertwendy2 criticalup criticaldmgup
AddComponentPostInit("combat", function(self)
    local oldGetAttacked = self.GetAttacked
    function self:GetAttacked(attacker, damage, weapon, stimuli, spdamage, ...)
        local attackerperk = attacker and attacker.components.allachivcoin
        local defenderperk = self.inst and self.inst.components.allachivcoin
        --region NO ATTACK LOGIC (not dodge, but just not do anything)
        -- expertwaxwell4 shadowrealm
        if self.inst:HasDebuff("shadowrealm_buff") or (attacker and attacker:HasDebuff("shadowrealm_buff")) then
            chasni_spawnprefab("shadow_puff_large_back", 0, -0.1, 0, 1, 1, 1, self.inst.entity)
            chasni_spawnprefab("shadow_puff_large_front", 0, 0.1, 0, 1, 1, 1, self.inst.entity)
            return false
        end
        -- expertwonk1
        if self.inst.burrowing == true then
            return false
        end
        --endregion

        local damageredirecttarget = self.redirectdamagefn ~= nil and self.redirectdamagefn(self.inst, attacker, damage, weapon, stimuli, spdamage, ...) or nil
        if damageredirecttarget then
            return oldGetAttacked(self, attacker, damage, weapon, stimuli, spdamage, ...)
        end

        --region MISS CHANCE LOGIC
        local dodgechance = self.inst.dodgechance or 0
        local spawnpoof = true
        local dodging = false

        -- inventory dodgegear || slipscraft, hell_hat, hell_armor
        if self.inst.components.inventory then
            self.inst.components.inventory:ForEachEquipment(function(item)
                if item.chasni_dodgechancegear then
                    dodgechance = 1 - (1 - dodgechance) * (1 - item.chasni_dodgechancegear)
                end
                if item.chasni_dodgechancegearfn then
                    dodgechance = 1 - (1 - dodgechance) * (1 - item:chasni_dodgechancegearfn())
                end
            end)
        end
        -- leader's inventory dodgegear || slipscraft
        local leader = self.inst.components.follower and self.inst.components.follower:GetLeader()
        if leader and leader:HasTag("sharedodgegeartofollower") and leader.components.inventory then
            leader.components.inventory:ForEachEquipment(function(item)
                if item.chasni_dodgechancegear then
                    dodgechance = 1 - (1 - dodgechance) * (1 - (item.chasni_dodgechancegear))
                end
                if item.chasni_dodgechancegearfn then
                    dodgechance = 1 - (1 - dodgechance) * (1 - (item:chasni_dodgechancegearfn()))
                end
            end)
        end
        -- expertwalter3 >>>> 40%
        if self.inst.components.inventory and self.inst.components.inventory:EquipHasTag("adventure_hat") and self.inst.components.rider and self.inst.components.rider:IsRiding() then
            dodgechance = 1 - ((1 - dodgechance) * (1 - 0.4))
        end
        -- expertwoodie3 >>>> 90%
        if defenderperk and defenderperk.expertwoodie3 and self.inst:HasTag("weregoose") then
            dodgechance = 1 - ((1 - dodgechance) * (1 - 0.9))
        end
        -- expertwarly4 >>>> 70%
        if self.inst:HasDebuff("chasni_kimchibuff") then
            dodgechance = 1 - ((1 - dodgechance) * (1 - 0.7))
        end
        -- expertwendy2 >>>> 30%
        if self.inst:HasTag("ghostlyelixir_slow") then
            dodgechance = 1 - ((1 - dodgechance) * (1 - 0.3))
        end
        -- expertwx2 >>>> 30% wx78module_light
        if attacker and attacker._chasni_wx78module_light_blind then
            dodgechance = 1 - ((1 - dodgechance) * (1 - 0.3))
        end
        -- expertwx2 >>>> 20%+ wx78module_spin
        if self.inst.components.allachivcoin and self.inst.components.allachivcoin.expertwx2 and self.inst.sg and self.inst.sg:HasStateTag("spinning") and self.inst.chasni_module_counter_wx78module_spin and self.inst.chasni_module_counter_wx78module_spin > 0 then
            local chance = 0.2 * self.inst.chasni_module_counter_wx78module_spin
            dodgechance = 1 - ((1 - dodgechance) * (1 - chance))
        end
        -- duppercritter >>>> X%+ chasni_critter_seal
        if self.inst and self.inst:HasDebuff("critter_seal_buff") and self.inst._sealmisschance and self.inst._sealmisschance > 0 then
            dodgechance = 1 - ((1 - dodgechance) * (1 - (self.inst._sealmisschance / 100)))
        end
        -- groundedscream >>>> 50% chesspiece_manrabbit_marble
        if self.inst and self.inst.prefab == "bunnyman" and self.inst.components.follower and self.inst.components.follower:GetLeader() and self.inst.components.follower:GetLeader():HasTag("player") and chasni_checkifgroundedexists("chesspiece_manrabbit_marble") then
            dodgechance = 1 - ((1 - dodgechance) * (1 - 0.5))
        end
        -- groundedscream >>>> 50% chesspiece_clayhound_marble
        if self.inst and self.inst:HasTag("hound") and self.inst.components.follower and self.inst.components.follower:GetLeader() and self.inst.components.follower:GetLeader():HasTag("player") and chasni_checkifgroundedexists("chesspiece_clayhound_marble") then
            dodgechance = 1 - ((1 - dodgechance) * (1 - 0.5))
        end
        -- Dodgechancer component >>>> not yet used
        if self.inst and self.inst.components.chasnidodgechancer then
            local dodgechancerchance = self.inst.components.chasnidodgechancer:CalculateDodge()
            dodgechance = 1 - ((1 - dodgechance) * (1 - dodgechancerchance))
        end

        if dodgechance > 0 and math.random() < dodgechance then
            dodging = true
        end
        --endregion

        --region MISS CHANCE LOGIC [WITH RESIDUAL EFFECT]
        -- expertwinona2 || chasni_banner_miss (remove the buff)
        if not dodging then
            if self.inst.chasni_banner_missfxtask then
                self.inst.chasni_banner_missfxtask:Cancel()
                self.inst.chasni_banner_missfxtask = nil

                if self.inst.chasni_banner_misstask then
                    self.inst.chasni_banner_misstask:Cancel()
                    self.inst.chasni_banner_misstask = nil
                end

                local misscd = self.inst.components.allachivcoin and self.inst.components.allachivcoin.expertwinona2 and 30 or 120
                self.inst.chasni_banner_misstask = self.inst:DoTaskInTime(misscd, function()
                    self.inst.chasni_banner_missfxtask = self.inst:DoPeriodicTask(3, function()
                        chasni_spawnprefab("chasni_music_fx", 0,0,0,1,1,1, self.inst.entity)
                    end)
                    if self.inst.chasni_banner_misstask then
                        self.inst.chasni_banner_misstask:Cancel()
                        self.inst.chasni_banner_misstask = nil
                    end
                end)
                dodging = true
            end
        end
        -- trinketslot || trinket_chasni_8 (remove the item) || Can of Silly String
        if not dodging then
            if self.inst then
                local trinket = chasni_getequippedtrinket(self.inst)
                if trinket and trinket.prefab == "trinket_chasni_8" and trinket.components.stackable then
                    trinket.components.stackable:Get():Remove()
                    chasni_spawnprefab("pillowfight_confetti_fx", 0, 0.1, 0, 1, 1, 1, self.inst.entity)
                    spawnpoof = false
                    dodging = true
                end
            end
        end
        --endregion

        if dodging then
            if spawnpoof then
                chasni_spawnprefab("sand_puff_large_back", 0, -0.1, 0, 1, 1, 1, self.inst.entity)
                chasni_spawnprefab("sand_puff_large_front", 0, 0, 0, 1, 1, 1, self.inst.entity)
            end
            damage, spdamage = 0, nil
            self.inst:PushEvent("chasni_dododge",  {attacker=attacker})
            return oldGetAttacked(self, attacker, damage, weapon, stimuli, spdamage, ...)
        end

        --region DAMAGE MULT LOGIC
        --<<< to 0 | normal >>> CRITICAL HIT
        --region CRITICAL LOGIC
        local critchance = 0
        local critdamage = 1

        -- guaranteecrit || chasni_critter_raptor || duppercritter
        if attacker and attacker:HasDebuff("critter_raptor_buff") then
            critchance = 1
            attacker:RemoveDebuff("critter_raptor_buff")
        end
        -- perk criticalup criticaldmgup
        if attackerperk then
            if attackerperk.criticalupamount > 0 then
                critchance = 1 - ((1 - critchance) * (1 - allachiv_coindata["criticalup"] * attackerperk.criticalupamount))
            end
            if attackerperk.criticaldmgupamount > 0 then
                critdamage = critdamage + (allachiv_coindata["criticaldmgup"] * attackerperk.criticaldmgupamount)
            end
        end
        -- inventory critchancegear, critdamagegear || hell_hat, hell_armor
        if attacker and attacker.components.inventory then
            attacker.components.inventory:ForEachEquipment(function(item)
                if item.chasni_critchancegear then
                    critchance = 1 - (1 - critchance) * (1 - item.chasni_critchancegear)
                end
                if item.chasni_critchancegearfn then
                    critchance = 1 - (1 - critchance) * (1 - item:chasni_critchancegearfn())
                end

                if item.chasni_critdamagegear then
                    critdamage = critdamage + item.chasni_critdamagegear
                end
                if item.chasni_critdamagegearfn then
                    critdamage = critdamage + item:chasni_critdamagegearfn()
                end
            end)
        end
        -- chasni_critter_atops orangegem >>>> add critical damage || duppercritter
        if attacker and attacker.components.petleash and attacker.components.inventory then
            local  ATOPS_ORANGEGEM_MULT = 0.001
            local pet = attacker.components.petleash:GetChasniCritter()
            if chasni_ispetname(pet, "atops") then
                local has, orangegemcount = attacker.components.inventory:Has("orangegem", 1)
                if has and orangegemcount > 0 then
                    critdamage = critdamage + (orangegemcount * ATOPS_ORANGEGEM_MULT)
                end
                local has2, opalpreciousgemcount = attacker.components.inventory:Has("opalpreciousgem", 1)
                if has2 and opalpreciousgemcount > 0 then
                    critdamage = critdamage + (opalpreciousgemcount * ATOPS_ORANGEGEM_MULT)
                end
            end

        end
        -- chasni_critter_seal >>>> add critical damage || duppercritter
        if attacker and attacker:HasDebuff("chasni_critter_raptor_aura_buff") then
            local debuff = attacker:GetDebuff("chasni_critter_raptor_aura_buff")
            local cdmg = debuff and debuff.critdamage and debuff.critdamage > 0 and debuff.critdamage / 100 or 0
            critdamage = critdamage + cdmg
        end
        -- chesspiece_moon_marble  >>>> 30% chance x 30% damage on fullmoon || groundedscream
        if TheWorld.state.isfullmoon and attacker and attacker:HasTag("player") and chasni_checkifgroundedexists("chesspiece_moon_marble") then
            critchance = 1 - ((1 - critchance) * (1 - 0.30))
            critdamage = critdamage + 0.30
        end
        -- chesspiece_manrabbit_marble  >>>> 50% chance x 50% damage to follower bunnyman || groundedscream
        if attacker and attacker.prefab == "bunnyman" and attacker.components.follower and attacker.components.follower:GetLeader() and attacker.components.follower:GetLeader():HasTag("player") and chasni_checkifgroundedexists("chesspiece_manrabbit_marble") then
            critchance = 1 - ((1 - critchance) * (1 - 0.50))
            critdamage = critdamage + 0.50
        end

        -- chesspiece_clayhound_marble  >>>> 30% chance x 30% damage to follower hound || groundedscream
        if attacker and attacker:HasTag("hound") and attacker.components.follower and attacker.components.follower:GetLeader() and attacker.components.follower:GetLeader():HasTag("player") and chasni_checkifgroundedexists("chesspiece_clayhound_marble") then
            critchance = 1 - ((1 - critchance) * (1 - 0.50))
            critdamage = critdamage + 0.50
        end

        -- Critchancer component >>>> not yet used
        if attacker and attacker.components.chasnicritchancer then
            local critchancerdamage, critchancerchance = attacker.components.chasnicritchancer:CalculateCrit()
            critchance = 1 - ((1 - critchance) * (1 - critchancerchance))
            critdamage = critdamage + critchancerdamage
        end

        -- [[ DOCRITICAL ]] --
        if damage and damage >= 0 and attacker and critdamage > 1 and critchance > 0 and math.random() < critchance then
            damage = damage * critdamage
            chasni_spawnprefab("chasni_attackfx3", nil, nil, nil,0.6, 0.6, 0.6, nil, nil, attacker, self.inst)

            if attacker.SoundEmitter then
                attacker.SoundEmitter:PlaySound("dontstarve/common/whip_large", nil, 0.3)
            end
            attacker:PushEvent("chasni_docriticalhit")
        end
        --endregion
        --<<< to 0 | planar >>> supercritter critter_lamb 
        if defenderperk and defenderperk.supercritter and self.inst:HasTag("_supercritter_critter_lamb") then
            spdamage = nil
        end
        --<<< to 0 | planar >>> new_crabking_claw 
        if self.inst:HasTag("chasni_planarimune") then
            spdamage = nil
        end
        --<<< to 0 | normal >>> new_crabking_claw 
        if self.inst:HasTag("chasni_planaronly") then
            damage = 0
        end
        --<<< mult | alldmg >>> expertwaxwell2
        if defenderperk and defenderperk.expertwaxwell2 and attacker then
            if attacker:HasTag("shadow_aligned") then
                damage = damage * 0.25
                spdamage = chasni_transformcombatdamage(spdamage, 0.25, 0)
            end
            if attacker:HasTag("lunar_aligned") then
                damage = damage * 1.25
                spdamage = chasni_transformcombatdamage(spdamage, 1.25, 0)
            end
        end
        if attackerperk and attackerperk.expertwaxwell2 then
            if self.inst:HasTag("shadow_aligned") then
                damage = damage * 1.75
                spdamage = chasni_transformcombatdamage(spdamage, 1.75, 0)
            end
            if self.inst:HasTag("lunar_aligned") then
                damage = damage * .75
                spdamage = chasni_transformcombatdamage(spdamage, 0.75, 0)
            end
        end
        --<<< mult | alldmg >>> supercritter critter_lunarmothling
        if attackerperk and attackerperk.supercritter then
            if attacker:HasTag("_supercritter_critter_lunarmothling") then
                if self.inst:HasTag("shadow_aligned") then
                    damage = damage * 2
                    spdamage = chasni_transformcombatdamage(spdamage, 2, 0)
                end
            end
        end
        if defenderperk and defenderperk.supercritter then
            if self.inst:HasTag("_supercritter_critter_lunarmothling") then
                if attacker and attacker:HasTag("shadow_aligned") then
                    damage = damage * 0.5
                    spdamage = chasni_transformcombatdamage(spdamage, 0.5, 0)
                end
            end
        end
        --<<< mult | alldmg >>> chasni_critter_snail chasni_critter_snail_black || duppercritter
        local aura_buffs =
        {
            {
                debuff = "chasni_critter_snail_a_aura_buff",
                tag = "shadow_aligned",
                defend_mult = 0.9,
            },
            {
                debuff = "chasni_critter_snail_b_aura_buff",
                tag = "shadow_aligned",
                defend_mult = 0.5,
            },
            {
                debuff = "chasni_critter_snail_black_a_aura_buff",
                tag = "lunar_aligned",
                defend_mult = 0.9,
            },
            {
                debuff = "chasni_critter_snail_black_b_aura_buff",
                tag = "lunar_aligned",
                defend_mult = 0.5,
            },
        }
        for _, data in ipairs(aura_buffs) do
            if self.inst:HasDebuff(data.debuff) and attacker and attacker:HasTag(data.tag) then
                damage = damage * data.defend_mult
                spdamage = chasni_transformcombatdamage(spdamage, data.defend_mult, 0)
            end

            if attacker and attacker:HasDebuff(data.debuff) and self.inst:HasTag(data.tag) then
                local debuff = attacker:GetDebuff(data.debuff)
                local mult = 1
                if debuff ~= nil and debuff.mult ~= nil and debuff.mult > 0 then
                    mult = 1 + debuff.mult / 100
                end
                damage = damage * mult
                spdamage = chasni_transformcombatdamage(spdamage, mult, 0)
            end
        end
        --<<< mult | planar >>> expertwalter4 
        if self.inst:HasTag("slingshotammo_lunar") then
            spdamage = chasni_transformcombatdamage(spdamage, 2, 0)
        end
        --<<< mult | planar >>> expertwarly4 
        if attacker and attacker:HasDebuff("chasni_balutbuff") then
            spdamage = chasni_transformcombatdamage(spdamage, 2, 0)
        end
        --<<< mult | normal >>> trinketslot trinket_33 Spider Ring 
        if self.inst:HasTag("spider") and attacker then
            local trinket = chasni_getequippedtrinket(attacker)
            if trinket and trinket.prefab == "trinket_33" then
                local stacksize = chasni_gettrinketpoint(trinket, 0.2, 2)
                damage = damage * (1 + stacksize)
            end
        end
        --<<< mult | normal >>> groundedscream
        if TheWorld.components.groundedregistry then
            local grounded = TheWorld.components.groundedregistry
            if attacker and attacker:HasTag("player") then
                local keys = chasni_getGroundedChesspieceKeys(self.inst, "stone", true)
                for _, key in ipairs(keys) do
                    if grounded:Exist(key) then
                        damage = damage * 1.5
                        break
                    end
                end
            end
            if self.inst:HasTag("player") and attacker then
                local keys = chasni_getGroundedChesspieceKeys(attacker, "stone", true)
                for _, key in ipairs(keys) do
                    if grounded:Exist(key) then
                        damage = damage * 0.5
                        break
                    end
                end
            end
        end
        --endregion

        --region DAMAGE MULT LOGIC [WITH RESIDUAL EFFECT]
        --<<< mult | normal WITH RESIDUAL >>>  crabstaff_ice
        if not block and self.inst:HasTag("_coldembraced") then
            if damage and damage > 0 then
                self.inst._coldembracetotaldamage = (self.inst._coldembracetotaldamage or 0) + damage
                damage = 0
            end
        end
        --endregion

        if (damage == 0 or damage == nil) and spdamage == nil then
            return oldGetAttacked(self, attacker, damage, weapon, stimuli, spdamage, ...)
        end

        --region DAMAGE ADD LOGIC
        --<<< add | normal >>> soulamulet 
        if attacker and attacker._soulamulet_spiritdamage and attacker._soulamulet_spiritdamage > 0 then
            damage = damage + attacker._soulamulet_spiritdamage
        end
        --<<< add | normal >>> chasni_critter_atops redgem || duppercritter
        if attacker and attacker.components.petleash and attacker.components.inventory then
            local  ATOPS_REDGEM_MULT = 0.5
            local pet = attacker.components.petleash:GetChasniCritter()
            if chasni_ispetname(pet, "atops") then
                local has, redgemcount = attacker.components.inventory:Has("redgem", 1)
                if has and redgemcount > 0 then
                    damage = damage + (redgemcount * ATOPS_REDGEM_MULT)
                end
                local has2, opalpreciousgemcount = attacker.components.inventory:Has("opalpreciousgem", 1)
                if has2 and opalpreciousgemcount > 0 then
                    damage = damage + (opalpreciousgemcount * ATOPS_REDGEM_MULT)
                end
            end
        end
        --<<< sub | normal >>> expertwx4 
        if self.inst._shadow_shield_chips and self.inst._shadow_shield_chips > 0 then
            local reduction = (CHASNI_CIRCUIT_SHADOW_SHIELD_DAMAGE_BLOCK  * self.inst._shadow_shield_chips) + (CHASNI_CIRCUIT_SHADOW_SHIELD_DAMAGE_BLOCK_INCREMENT * self.inst._shadow_shield_chips  * self.inst._shadow_shield_chips) - CHASNI_CIRCUIT_SHADOW_SHIELD_BASE_DAMAGE_BLOCK
            damage = (damage > 1 and reduction > 0 and math.max(1, damage - reduction)) or damage
            if self.inst.components.sanity then
                self.inst.components.sanity:DoDelta(self.inst._shadow_shield_chips * self.inst._shadow_shield_chips * CHASNI_CIRCUIT_SHADOW_SHIELD_SANITY)
            end
        end
        --endregion

        --region DAMAGE BLOCK LOGIC
        local block = false
        local dosound = true
        -- expertworm2
        if not block and self.inst:HasDebuff("wormwood_poop_shield_buff") then
            block = true
        end
        -- rog : hulkhat
        if not block and self.inst:HasDebuff("hulkhat_shield_buff") then
            block = true
        end
        -- duppercritter : chasni_critter_crab
        if not block and self.inst:HasDebuff("chasni_critter_crab_shield_buff") then
            self.inst:RemoveDebuff("chasni_critter_crab_shield_buff")
            block = true
        end
        --endregion

        --region DAMAGE BLOCK LOGIC [WITH RESIDUAL EFFECT]
        -- expertwicker3 >>>> block have shield value
        if not block and self.inst:HasTag("chasniForceShield") then
            local spdamageamount = SpDamageUtil.ApplySpDefense(self.inst, spdamage)
            local totaldamage = damage + SpDamageUtil.CalcTotalDamage(spdamageamount)
            if self.inst.forceshield_counter and self.inst.chasniForceShield_fx_task and totaldamage > 0 then
                self.inst.forceshield_counter = self.inst.forceshield_counter - math.ceil(totaldamage/100)
                block = true
            end
        end
        -- expertwarly4 >>>> block redirected to sanity
        if not block and self.inst:HasDebuff("chasni_mooncakebuff") then
            local spdamageamount = SpDamageUtil.ApplySpDefense(self.inst, spdamage)
            local totaldamage = damage + SpDamageUtil.CalcTotalDamage(spdamageamount)
            if totaldamage > 0 and self.inst.components.sanity then
                self.inst.components.sanity:DoDelta(-totaldamage * 0.3)
                block = true
            end
        end
        -- expertwillow4 >>>> block is 1 time use
        if not block and self.inst:HasDebuff("flame_guard_buff") then
            if self.inst.components.debuffable then
                self.inst.components.debuffable:RemoveDebuff("flame_guard_buff")
                block = true
            end
        end
        --endregion

        if block then
            if dosound and self.inst.SoundEmitter and not self.inst:IsInLimbo() then
                self.inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_forcefield_armour_sharp")
            end
            self.inst:PushEvent("chasni_blocked", { attacker = attacker })
            damage, spdamage = 0, nil
            return oldGetAttacked(self, attacker, damage, weapon, stimuli, spdamage, ...)
        end

        --region DAMAGE REWORK LOGIC
        -- new_crabking_claw (rework : do no damage, but reduce health)
        local new_crabking_claw_reworked = false
        if self.inst:HasTag("crabking_claw_water") and not (stimuli == "electric" or (weapon and weapon.components.weapon and weapon.components.weapon.stimuli == "electric"))then
            new_crabking_claw_reworked = true
        elseif self.inst:HasTag("crabking_claw_ice") and not ((self.inst.components.burnable and self.inst.components.burnable:IsBurning()) or (attacker and attacker.components.burnable and attacker.components.burnable:IsBurning())) then
            new_crabking_claw_reworked = true
        elseif self.inst:HasTag("crabking_claw_electric") and not (self.inst:HasTag("wet") or (self.inst.components.moisture and self.inst.components.moisture:IsWet()) or (attacker and attacker:HasTag("wet")) or (attacker and attacker.components.moisture and attacker.components.moisture:IsWet())) then
            new_crabking_claw_reworked = true
        elseif self.inst:HasTag("crabking_claw_fire") and not ((self.inst.components.freezable and self.inst.components.freezable:IsFrozen()) or (attacker and attacker:HasTag("frostbitten"))) then
            new_crabking_claw_reworked = true
        end
        if new_crabking_claw_reworked then
            if self.inst.SoundEmitter then
                self.inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_forcefield_armour_sharp")
            end
            damage, spdamage = 0, nil
            return oldGetAttacked(self, attacker, damage, weapon, stimuli, spdamage, ...)
        end
        local new_crabking_claw_planar_reworked = false
        if self.inst:HasTag("crabking_claw_lunar") and not (attacker and attacker.components.sanity and attacker.components.sanity:GetPercent() > 0.7) then
            new_crabking_claw_planar_reworked = true
        elseif self.inst:HasTag("crabking_claw_shadow") and not (attacker and attacker.components.sanity and attacker.components.sanity:GetPercent() < 0.3) then
            new_crabking_claw_planar_reworked = true
        end
        if new_crabking_claw_planar_reworked then
            if self.inst.SoundEmitter then
                self.inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_forcefield_armour_sharp")
            end
            damage, spdamage = 0, nil
            return oldGetAttacked(self, attacker, damage, weapon, stimuli, spdamage, ...)
        end
        --endregion

        return oldGetAttacked(self, attacker, damage, weapon, stimuli, spdamage, ...)
    end
end)

-- CC : GLOBAL POSTINIT : ADD PUSH EVENT ON DODGE ATTACK | AttackDodger
AddComponentPostInit("attackdodger", function(self)
    local _Dodge = self.Dodge
    function self:Dodge(attacker, ...)
        self.inst:PushEvent("chasni_dododge",  {attacker=attacker})
        return _Dodge(self, attacker, ...)
    end
end)

-- CC : GLOBAL POSTINIT : AURACHANGE | expertworm1
if not chasni_getperkexcludeconfig("expertworm1") then
    AddComponentPostInit("aura", function(self)
        local _OnTick = self.OnTick
        function self:OnTick(...)
            _OnTick(self, ...)

            -- heal to player
            if self.healing then
                local x, y, z = self.inst.Transform:GetWorldPosition()
                local ents = FindPlayersInRange(x, y, z, self.radius, true)
                for _,v in pairs(ents) do
                    if v.components.health and v.components.sanity then
                        v.components.sanity:DoDelta(self.healing)
                        v.components.health:DoDelta(self.healing)
                    end
                end
            end

            if self.auraname == "nature" then
                local x, y, z = self.inst.Transform:GetWorldPosition()
                local ents = FindPlayersInRange(x, y, z, self.radius, true)
                for _,v in pairs(ents) do
                    if v.components.inventory then
                        local headgear = v.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD)
                        if headgear and headgear.prefab == "hell_hat" and headgear.Evolve then
                            headgear:Evolve(5)
                        end
                        local bodygear = v.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.BODY)
                        if bodygear and bodygear.prefab == "hell_armor" and bodygear.Evolve then
                            bodygear:Evolve(5)
                        end
                    end
                end
            end
        end
    end)
end

-- CC : GLOBAL POSTINIT : NONHAND WEAPON (headweapon) >> [Reward] expertwebber3 || chasni_gogglesshoot
if not chasni_getperkexcludeconfig("expertwebber3", "bosshunting") then
    AddComponentPostInit("combat", function(self)
        local oldGetWeapon = self.GetWeapon
        function self:GetWeapon(...)
            local headitem = nil
            if self.inst.components.inventory then
                local item = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
                headitem = item and item:HasTag("headweapon") and item.components.weapon
                        and not (self.inst.components.rider and self.inst.components.rider:IsRiding())
                        and item or nil
            end
            return headitem or oldGetWeapon(self, ...)
        end
    end)

    AddClassPostConstruct("components/combat_replica", function(self)
        local oldGetWeapon = self.GetWeapon
        function self:GetWeapon(...)
            local headitem
            if self.inst.components.combat == nil and self.inst.replica.inventory then
                local item = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
                headitem = item and item:HasTag("headweapon") and not (self.inst.replica.rider and self.inst.replica.rider:IsRiding()) and item or nil
            end
            return headitem or oldGetWeapon(self, ...)
        end
    end)

    AddStategraphState("wilson", State {
        name = "headattack",
        tags = {"attack", "notalking", "abouttoattack"},
        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            local target = buffaction and buffaction.target or nil
            inst.components.combat:SetTarget(target)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            local equip = (inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)) or
                    (inst.replica and inst.replica.inventory and inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD))
            if equip and equip:HasTag("googleweapon") then
                inst.AnimState:PlayAnimation("goggle_fast")
            else
                inst.AnimState:PlayAnimation("idle_shiver_pre")
            end
            if inst.sg.prevstate == inst.sg.currentstate then
                inst.sg.statemem.chained = true
                inst.AnimState:SetTime(5 * FRAMES)
            end

            if equip and equip:HasTag("googleweapon") then
                inst.AnimState:PushAnimation("goggle_fast_pst", false)
            else
                inst.AnimState:PushAnimation("idle_shiver_pst", false)
            end

            inst.sg:SetTimeout(math.max((inst.sg.statemem.chained and 14 or 18) * FRAMES, inst.components.combat.min_attack_period + .5 * FRAMES))

            if target and target:IsValid() then
                inst:FacePoint(target.Transform:GetWorldPosition())
                inst.sg.statemem.attacktarget = target
            end

            if (equip and equip.projectiledelay or 0) > 0 then
                inst.sg.statemem.projectiledelay = (inst.sg.statemem.chained and 9 or 14) * FRAMES - equip.projectiledelay
                if inst.sg.statemem.projectiledelay <= 0 then
                    inst.sg.statemem.projectiledelay = nil
                end
            end
        end,
        onupdate = function(inst, dt)
            if (inst.sg.statemem.projectiledelay or 0) > 0 then
                inst.sg.statemem.projectiledelay = inst.sg.statemem.projectiledelay - dt
                if inst.sg.statemem.projectiledelay <= 0 then
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end
        end,
        timeline =
        {
            TimeEvent(9 * FRAMES, function(inst)
                if inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
            TimeEvent(14 * FRAMES, function(inst)
                if not inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                    if inst.components.moisture:GetMoisture() > 0 then
                        local equip = (inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)) or
                                (inst.replica and inst.replica.inventory and inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD))
                        if equip and equip:HasTag("googleweapon") then
                            inst.components.combat:GetAttacked(nil, 50, nil, "electric")
                        end
                    end
                end
            end),
        },
        ontimeout = function(inst)
            inst.sg:RemoveStateTag("attack")
            inst.sg:AddStateTag("idle")
        end,
        events =
        {
            EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        onexit = function(inst)
            inst.components.combat:SetTarget(nil)
            if inst.sg:HasStateTag("abouttoattack") then
                inst.components.combat:CancelAttack()
            end
        end,
    })
    AddStategraphState("wilson", State {
        name = "headattack_post",
        tags = {"investigating", "working"},
        onenter = function(inst)
            local equip = (inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)) or
                    (inst.replica and inst.replica.inventory and inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD))
            if equip and equip:HasTag("googleweapon") then
                inst.AnimState:PlayAnimation("goggle_fast_pst")
            else
                inst.AnimState:PlayAnimation("idle_shiver_pst")
            end
        end,
        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    })

    AddStategraphState("wilson_client", State {
        name = "headattack",
        tags = { "attack", "notalking", "abouttoattack" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            local equip = (inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)) or
                    (inst.replica and inst.replica.inventory and inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD))
            if equip and equip:HasTag("googleweapon") then
                inst.AnimState:PlayAnimation("goggle_fast")
            else
                inst.AnimState:PlayAnimation("idle_shiver_pre")
            end
            if inst.sg.prevstate == inst.sg.currentstate then
                inst.sg.statemem.chained = true
                inst.AnimState:SetTime(5 * FRAMES)
            end

            if equip and equip:HasTag("googleweapon") then
                inst.AnimState:PushAnimation("goggle_fast_pst", false)
            else
                inst.AnimState:PushAnimation("idle_shiver_pst", false)
            end

            if inst.replica.combat then
                inst.replica.combat:StartAttack()
                inst.sg:SetTimeout(math.max((inst.sg.statemem.chained and 14 or 18) * FRAMES, inst.replica.combat:MinAttackPeriod() + .5 * FRAMES))
            end

            local buffaction = inst:GetBufferedAction()
            if buffaction then
                inst:PerformPreviewBufferedAction()
                if buffaction.target and buffaction.target:IsValid() then
                    inst:FacePoint(buffaction.target:GetPosition())
                    inst.sg.statemem.attacktarget = buffaction.target
                end
            end
            if (equip.projectiledelay or 0) > 0 then
                inst.sg.statemem.projectiledelay = (inst.sg.statemem.chained and 9 or 14) * FRAMES - equip.projectiledelay
                if inst.sg.statemem.projectiledelay <= 0 then
                    inst.sg.statemem.projectiledelay = nil
                end
            end
        end,
        onupdate = function(inst, dt)
            if (inst.sg.statemem.projectiledelay or 0) > 0 then
                inst.sg.statemem.projectiledelay = inst.sg.statemem.projectiledelay - dt
                if inst.sg.statemem.projectiledelay <= 0 then
                    inst:ClearBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end
        end,
        timeline =
        {
            TimeEvent(9 * FRAMES, function(inst)
                if inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                    inst:ClearBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
            TimeEvent(14 * FRAMES, function(inst)
                if not inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                    inst:ClearBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
        },
        ontimeout = function(inst)
            inst.sg:RemoveStateTag("attack")
            inst.sg:AddStateTag("idle")
        end,
        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
        onexit = function(inst)
            if inst.sg:HasStateTag("abouttoattack") and inst.replica.combat then
                inst.replica.combat:CancelAttack()
            end
        end,
    })
    AddStategraphState("wilson_client", State {
        name = "headattack_post",
        tags = {"investigating", "working"},
        onenter = function(inst)
            local equip = (inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)) or
                    (inst.replica and inst.replica.inventory and inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD))
            if equip and equip:HasTag("googleweapon") then
                inst.AnimState:PlayAnimation("goggle_fast_pst")
            else
                inst.AnimState:PlayAnimation("idle_shiver_pst")
            end
        end,
        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    })

    AddStategraphPostInit("wilson", function(inst)
        local _attack_actionhandler = inst.actionhandlers[ACTIONS.ATTACK].deststate
        inst.actionhandlers[ACTIONS.ATTACK].deststate = function(_inst, action, ...)
            if not (_inst.sg:HasStateTag("attack") and action.target == _inst.sg.statemem.attacktarget or _inst.components.health:IsDead()) then
                local weapon = _inst.components.combat and _inst.components.combat:GetWeapon() or nil
                if weapon and weapon:HasTag("headweapon") then
                    return "headattack"
                end
            end
            return _attack_actionhandler(_inst, action, ...)
        end
    end)

    AddStategraphPostInit("wilson_client", function(inst)
        local _attack_actionhandler = inst.actionhandlers[ACTIONS.ATTACK].deststate
        inst.actionhandlers[ACTIONS.ATTACK].deststate = function(_inst, action, ...)
            if not (_inst.sg:HasStateTag("attack") and action.target == _inst.sg.statemem.attacktarget or _inst.replica.health:IsDead()) then
                local equip = _inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or _inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
                if equip and equip:HasTag("headweapon") then
                    return "headattack"
                end
            end
            return _attack_actionhandler(_inst, action, ...)
        end
    end)
end

-- CC : GLOBAL POSTINIT : CHANNEL SONG >> [Reward] expertwathg2
if not chasni_getperkexcludeconfig("expertwathg2") then
    AddStategraphPostInit("wilson", function(inst)
        local deststate = inst.actionhandlers[ACTIONS.SING].deststate
        inst.actionhandlers[ACTIONS.SING].deststate = function(_inst, action, ...)
            if action.invobject:HasTag("channeling_song") then
                return "sing_pre_channeling"
            end
            if type(deststate) == "string" then
                return deststate
            else
                return deststate(_inst, action, ...)
            end
        end
    end)

    AddStategraphState("wilson", State {
        name = "sing_pre_channeling",
        tags = { "doing", "busy", "canrotate" },
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("sing_pre", false)
        end,
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    local buffaction = inst:GetBufferedAction()
                    local songdata = buffaction and buffaction.invobject.songdata or nil
                    local singinginspiration = inst.components.singinginspiration

                    if singinginspiration and songdata then
                        if singinginspiration:CanAddSong(songdata, buffaction.invobject) then
                            inst.sg:GoToState("sing_channeling")
                        else
                            inst.sg:GoToState("cantsing")
                        end
                    else
                        inst.sg:GoToState("idle")
                    end
                end
            end),
        },
    })

    AddStategraphState("wilson", State {
        name = "sing_channeling",
        tags = { "canrotate", "channeling_sing" },
        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            local songdata = buffaction and buffaction.invobject.songdata or nil

            if songdata then
                inst.AnimState:PushAnimation("sing_loop", true)
                inst.SoundEmitter:PlaySound(songdata.SOUND or ("dontstarve_DLC001/characters/wathgrithr/sing"), "sing_channeling")
                inst._channelingsong = songdata.SOUND
            end
        end,
        timeline =
        {
            TimeEvent(24 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
            TimeEvent(7.5, function(inst)
                if inst._channelingsong then
                    inst.SoundEmitter:PlaySound(inst._channelingsong .. "_loop" or ("dontstarve_DLC001/characters/wathgrithr/sing"), "sing_channeling_loop")
                end
            end),
        },
        onexit = function(inst)
            inst.SoundEmitter:KillSound("sing_channeling")
            inst.SoundEmitter:KillSound("sing_channeling_loop")
            if inst._songchannelingtask then
                inst._songchannelingtask:Cancel()
                inst._songchannelingtask = nil
            end
            if inst._songchannelingendfunction then
                inst._songchannelingendfunction(inst)
                inst._songchannelingendfunction = nil
            end
        end,
    })

    AddStategraphState("wilson_client", State {
        name = "sing_pre_channeling",
        tags = {"busy"},
        onenter = function(inst)
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("sing_pre", false)
            inst.AnimState:PushAnimation("sing_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(2)
        end,
        onupdate = function(inst)
            if inst.sg:ServerStateMatches() then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,
        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    })
end

-- CC : change "turnoff" action wording >> [Reward] expertwebber2 expertworm1 || fluffyhouse  healingward
local turnoff_stroverridefn = ACTIONS.TURNOFF.stroverridefn
local turnoff_strfn = ACTIONS.TURNOFF.strfn
ACTIONS.TURNOFF.stroverridefn = function(act)
    if act.target and act.target:HasTag("fluffyhouse") then
        return STRINGS.ACTIONS.CALLFLUFFY
    end
    if act.target and act.target:HasTag("healingward") then
        return STRINGS.ACTIONS.CALLHEALINGWARD
    end
    if turnoff_stroverridefn then
        return turnoff_stroverridefn(act)
    end
    if turnoff_strfn then
        return nil
    end
    return ACTIONS.TURNOFF.STRINGS
end

-- CC : set dest action into dolongaction >> [Reward] expertwebber3 || watchpaint
if not chasni_getperkexcludeconfig("expertwebber3", "bosshunting") then
    AddStategraphPostInit("wilson", function(inst)
        local deststate = inst.actionhandlers[ACTIONS.CAST_SPELLBOOK].deststate
        inst.actionhandlers[ACTIONS.CAST_SPELLBOOK].deststate = function(_inst, action, ...)
            if action.invobject:HasTag("webbermask") then
                return "dolongaction"
            end
            if action.invobject:HasTag("watchpaint") then
                return "dolongaction"
            end
            if type(deststate) == "string" then
                return deststate
            else
                return deststate(_inst, action, ...)
            end
        end
    end)

    -- CC : change spell wording >> [Reward] expertwebber3 || watchpaint
    local usesspellbook_stroverridefn = ACTIONS.USESPELLBOOK.stroverridefn
    local usesspellbook_strfn = ACTIONS.USESPELLBOOK.strfn
    ACTIONS.USESPELLBOOK.stroverridefn = function(act)
        if act.invobject and act.invobject:HasTag("webbermask") then
            return STRINGS.ACTIONS.WEBBERMASKING
        end
        if act.invobject and act.invobject:HasTag("watchpaintbrush") then
            return STRINGS.ACTIONS.CHASNI_PAINT
        end
        if usesspellbook_stroverridefn then
            return usesspellbook_stroverridefn(act)
        end
        if usesspellbook_strfn then
            return nil
        end
        return ACTIONS.USESPELLBOOK.STRINGS
    end
end

-- CC : remove widgets/ui things if immune to cold and heat || upgraded_amulets upgraded_blueamulets fire_armor >> [Global] expertwillow3
if not chasni_getperkexcludeconfig("expertwillow3", "bosshunting") then
    AddComponentPostInit("temperature",function(self)
        -- >>>> this still unused
        local oldIsFreezing = self.IsFreezing
        function self:IsFreezing(...)
            local inventory = self.inst.replica.inventory or self.inst.components.inventory
            if inventory and inventory:EquipHasTag("chasni_coldimune") then
                return false
            end
            return oldIsFreezing(self,...)
        end
        local oldIsOverheating = self.IsOverheating
        function self:IsOverheating(...)
            local inventory = self.inst.replica.inventory or self.inst.components.inventory
            if inventory and inventory:EquipHasTag("chasni_heatimune") then
                return false
            end
            return oldIsOverheating(self,...)
        end
    end)
    AddPlayerPostInit(function(inst)
        local oldIsFreezing = inst.IsFreezing
        function inst:IsFreezing(...)
            local inventory = inst.replica.inventory or inst.components.inventory
            if (inventory and inventory:EquipHasTag("chasni_coldimune") or inst:HasTag("chasni_freezehealing")) then
                return false
            end
            return oldIsFreezing(inst,...)
        end
        local oldIsOverheating = inst.IsOverheating
        function inst:IsOverheating(...)
            local inventory = inst.replica.inventory or inst.components.inventory
            if (inventory and inventory:EquipHasTag("chasni_heatimune") or inst:HasTag("chasni_heathealing"))then
                return false
            end
            return oldIsOverheating(inst,...)
        end
    end)

    -- CC : remove heatover overlay || fire_armor >> [Global] expertwillow3
    local HeatOver = require("widgets/heatover")
    local _OnHeatChange = HeatOver.OnHeatChange
    function HeatOver:OnHeatChange(...)
        local inventory = self.owner.replica.inventory or self.owner.components.inventory
        if inventory and inventory:EquipHasTag("chasni_heatimune") then
            return
        end

        return _OnHeatChange(self, ...)
    end
    -- CC : remove iceover overlay || ???? >> [???] ????
    -- >>>> this still unused
    local IceOver = require("widgets/iceover")
    local _OnIceChange = IceOver.OnIceChange
    function IceOver:OnIceChange(...)
        local inventory = self.owner.replica.inventory or self.owner.components.inventory
        if inventory and inventory:EquipHasTag("chasni_coldimune") then
            return
        end

        return _OnIceChange(self, ...)
    end
end

-- CC : GLOBAL POSTINIT : ARMOR ABSORBTIONFN | [Global] crocodog backpack
if not chasni_getperkexcludeconfig("bosshunting") then
    AddComponentPostInit("armor", function(self)
        local oldGetAbsorption = self.GetAbsorption
        function self:GetAbsorption(attacker, weapon, ...)
            local absorption = oldGetAbsorption(self, attacker, weapon, ...)
            if absorption and self.cz_absorb_fn then
                return self.cz_absorb_fn(self.inst, attacker)
            end
            return oldGetAbsorption(self, attacker, weapon, ...)
        end
    end)
end

-- CC : GLOBAL POSTINIT : HEALER HEAL with rechargeable | [Global] medicalkit
if not chasni_getperkexcludeconfig("bosshunting") then
    AddComponentPostInit("healer", function(self)
        local oldHeal = self.Heal
        function self:Heal(target, ...)
            if self.rechargeablecooldown then
                if target.components.health and self.inst.components.rechargeable and self.inst.components.rechargeable:IsCharged() then
                    target.components.health:DoDelta(self.health, self.overtime or false, self.inst.prefab)
                    if self.onhealfn then
                        self.onhealfn(self.inst, target)
                    end
                    self.inst.components.rechargeable:Discharge(self.rechargeablecooldown)
                    return true
                end
                return false
            else
                return oldHeal(self, target, ...)
            end
        end
    end)
end

-- CC : GLOBAL POSTINIT : SEWING Repair with rechargeable | [Global] chasni_repairkit
if not chasni_getperkexcludeconfig("bosshunting") then
    AddComponentPostInit("sewing", function(self)
        local oldDoSewing = self.DoSewing
        function self:DoSewing(target, doer, ...)
            if self.inst.components.rechargeable and not self.inst.components.rechargeable:IsCharged() then
                return false
            end

            local return_val = oldDoSewing(self, target, doer, ...)
            if self.inst:HasTag("sew_any") and not target:HasTag("charges_percentage") then
                if target.components.finiteuses then
                    target.components.finiteuses:SetPercent(1)
                end
                if target.components.armor then
                    target.components.armor:SetPercent(1)
                end
                if target.components.fueled then
                    target.components.fueled:SetPercent(1)
                end
                if not return_val then
                    return_val = true

                    if self.onsewn then
                        self.onsewn(self.inst, target, doer)
                    end
                end
            end
            if self.rechargeablecooldown and return_val then
                self.inst.components.rechargeable:Discharge(self.rechargeablecooldown)
            end
            return return_val
        end
    end)
    -- CC : GLOBAL POSTINIT : SEWING Repair all item | [Global] chasni_repairkit
    local old_sew_fn = ACTIONS.SEW.fn
    ACTIONS.SEW.fn = function(act)
        if act.target and
                act.invobject and
                act.invobject:HasTag("sew_any") and
                (act.target.components.fueled or act.target.components.finiteuses or act.target.components.armor) and
                not act.target:HasTag("charges_percentage") and
                act.invobject.components.sewing then
            return act.invobject.components.sewing:DoSewing(act.target, act.doer)
        end
        return old_sew_fn(act)
    end

    AddComponentAction("USEITEM", "sewing", function(inst, doer, target, actions)
        if inst:HasTag("sew_any") and not target:HasTag("charges_percentage") and not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding() and not (target.replica.inventoryitem ~= nil and target.replica.inventoryitem:IsGrandOwner(doer))) then
            table.insert(actions, ACTIONS.SEW)
        end
    end)
end

-- CC : GLOBAL POSTINIT : ToggleableItem:CanInteract >> [Reward] ROG hulkhat
if not chasni_getperkexcludeconfig("bosshunting") then
    AddComponentPostInit("toggleableitem", function(self)
        local oldCanInteract = self.CanInteract
        function self:CanInteract(...)
            if self.inst:HasTag("chasni_cannot_toggleable") then
                return false
            end
            return oldCanInteract(self, ...)
        end
    end)

    local COMPONENT_ACTIONS = UpvalueHacker.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
    local INVENTORY = COMPONENT_ACTIONS.INVENTORY
    local Inventory_toggleableitem = INVENTORY.toggleableitem
    function INVENTORY.toggleableitem(inst, ...)
        if not inst:HasTag("chasni_cannot_toggleable") then
            Inventory_toggleableitem(inst, ...)
        end
    end
end

-- CC : alter (rope amount and anyammount) in inventory for crafting ("getcraftingingredient" and "has") >> [Perk] Trinket Slot > Trinket_3 || Gord's Knot || upgraded_greenamulet || expertwinona1 | crafterchest
local invaliditems = { "opalpreciousgem", "yellowgem", "redgem", "greengem", "purplegem", "orangegem", "bluegem", }
AddComponentPostInit("inventory", function(self)
    local _GetCraftingIngredient = self.GetCraftingIngredient
    function self:GetCraftingIngredient(item, amount, ...)
        local trinket = chasni_getequippedtrinket(self.inst)
        if trinket and trinket.prefab == "trinket_3" and item == "rope" then
            local stacksize = chasni_gettrinketpoint(trinket,  0.5, 10)
            amount = math.max(amount - math.floor(stacksize), 0)
        end

        local invaliditem = chasni_findprefab(invaliditems, item) or chasni_isMagicItem(item)
        if self:EquipHasTag("upgraded_greenamulet") and not invaliditem then
            amount = 0
        end

        local retval = _GetCraftingIngredient(self, item, amount, ...)
        if self.crafterchest then
            local amountneeded = amount
            local test = 0
            for _, v in pairs(retval) do
                test = test+1
                amountneeded = amountneeded - v
            end

            if amountneeded > 0 then
                local total_num_found = 0
                for k, v in pairs(self.crafterchest) do
                    if k and v and k:IsValid() then
                        local container = k.components.container or k.components.inventory
                        if container and not container.excludefromcrafting then
                            for i, j in pairs(container:GetCraftingIngredient(item, amountneeded - total_num_found, true)) do
                                retval[i] = j
                                total_num_found = total_num_found + j
                            end
                        end
                        if total_num_found >= amountneeded then
                            return retval
                        end
                    end
                end
            end
        end

        return retval
    end

    local _Has = self.Has
    function self:Has(prefab, amount, checkallcontainers, ...)
        local has, count = _Has(self, prefab, amount, checkallcontainers, ...)
        local trinket = chasni_getequippedtrinket(self.inst)
        if trinket and trinket.prefab == "trinket_3" and prefab == "rope" then
            local stacksize = chasni_gettrinketpoint(trinket,  0.5, 10)
            count = count + math.floor(stacksize)
            has = count >= amount
        end

        local invaliditem = chasni_findprefab(invaliditems, prefab) or chasni_isMagicItem(prefab)
        if self:EquipHasTag("upgraded_greenamulet") and not invaliditem then
            count = amount
            has = true
        end

        if self.crafterchest and checkallcontainers then
            for k, v in pairs(self.crafterchest) do
                if k and v and k:IsValid() then
                    if k.crafterchestitems and not (self.opencontainers and self.opencontainers[k]) then
                        count = count + (k.crafterchestitems[prefab] or 0)
                        has = count >= amount
                    end
                else
                    self:UnregisterCrafterChest(k)
                end
            end
        end

        return has, count
    end

end)
AddClassPostConstruct("components/inventory_replica", function(inst)
    local oldHas = inst.Has
    function inst:Has(prefab, amount, checkallcontainers, ...)
        local has, count = oldHas(inst, prefab, amount, checkallcontainers, ...)
        local trinketslot = inst:GetEquippedItem(EQUIPSLOTS.CHASNI_TRINKET_CONTAINERS)
        if trinketslot then
            local trinket = trinketslot.replica and trinketslot.replica.container and trinketslot.replica.container:GetItemInSlot(1)
            if trinket and trinket.prefab == "trinket_3" and prefab == "rope"then
                local stacksize = math.min((trinket.replica.stackable and trinket.replica.stackable:StackSize() or 1) * 0.5, 10)
                count = count + math.floor(stacksize)
                has = count >= amount
            end
        end

        local invaliditem = chasni_findprefab(invaliditems, prefab) or chasni_isMagicItem(prefab)
        if inst:EquipHasTag("upgraded_greenamulet") and not invaliditem then
            count = amount
            has = true
        end

        if inst.crafterchest and checkallcontainers then
            for k, v in pairs(inst.crafterchest) do
                if k and v and k:IsValid() then
                    local opencontainers = self:GetOpenContainers()
                    if k.crafterchestitems and not (opencontainers and opencontainers[k]) then
                        local container = k.replica.container or k.replica.inventory
                        if container and not container.excludefromcrafting and k.crafterchestitems then
                            count = count + (k.crafterchestitems[prefab] or 0)
                            has = count >= amount
                        end
                    end
                else
                    inst:UnregisterCrafterChest(k)
                end
            end
        end

        return has, count
    end
end)

-- CC : GLOBAL POSTINIT : Health:DoDelta || max damage taken per hit >> [Reward] ROG crabking
if not chasni_getperkexcludeconfig("bosshunting") then
    AddComponentPostInit("health", function(self)
        local _DoDelta = self.DoDelta
        function self:DoDelta(amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)

            -- crabking
            local hasValidArm = self.inst.hasValidArm and self.inst.hasValidArm(self.inst) or false

            if self.inst:HasTag("chasni_damagecap")         -- generics
                    or hasValidArm                          -- crabking
            then
                if self.inst._chasni_damagecap and amount < self.inst._chasni_damagecap and not self._ignore_maxdamagetakenperhit then
                    amount = self.inst._chasni_damagecap
                end
            end
            return _DoDelta(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
        end
    end)
end

-- CC : add pushevent when readingbook >> [Achievement] "seasonaltask" PushEvent Reader:Read || [RoG] readingglasses
AddComponentPostInit("reader", function(self)
    local _Read = self.Read
    function self:Read(book, ...)
        local success, reason = _Read(self, book, ...)
        self.inst:PushEvent("chasni_readbook", { book = book, success = success })
        return success, reason
    end
end)

---- CC : container not autoclose || trinket_26 : on riding, chestaff : on away >>  [Perk] Trinket Slot > Trinket_26 || Potato Cup || chestaff
AddComponentPostInit("container", function(self)
    local _OnUpdate = self.OnUpdate
    function self:OnUpdate(dt, ...)
        local removedopener = {}
        if self.opencount ~= 0 then
            for opener, _ in pairs(self.openlist) do
                local isridingwithtrinket = opener.components.rider and opener.components.rider:IsRiding() and opener:HasTag("enchantmemento_trinket_26")
                if isridingwithtrinket and opener:IsNear(self.inst, 3) and CanEntitySeeTarget(opener, self.inst) then
                    self.openlist[opener] = nil
                    removedopener[opener] = true
                end
            end
        end
        local retval = _OnUpdate(self, dt, ...)
        for opener, _ in pairs(removedopener) do
            self.openlist[opener] = true
        end

        return retval
    end
end)

-- CC : changing display name >>  [RoG] crabstaff_shadow || crabking
if not chasni_getperkexcludeconfig("bosshunting") then
    local _GetAdjectivedName = EntityScript.GetAdjectivedName
    function EntityScript:GetAdjectivedName(...)
        return self:HasTag("crabstaff_shadow_portal") and STRINGS.NAMES.CRABSTAFF_SHADOW_PORTAL
                or self:HasTag("chasni_crabqueen") and STRINGS.NAMES.CRABQUEEN
                or _GetAdjectivedName(self, ...)
    end
end

-- CC : change "tentacle" RETARGET_CANT_TAGS >> [Perk] Trinket Slot > Trinket_12 || Dessicated Tentacle
if not chasni_getperkexcludeconfig("trinketowner") then
    AddSimPostInit(function()
        if GLOBAL.Prefabs["tentacle"] then
            local _RETARGET_CANT_TAGS = UpvalueHacker.GetUpvalue(GLOBAL.Prefabs.tentacle.fn, "retargetfn", "RETARGET_CANT_TAGS")
            table.insert(_RETARGET_CANT_TAGS, "enchantmemento_trinket_12")
            table.insert(_RETARGET_CANT_TAGS, "chasni_tentacleimmune")
        end
    end)
end

