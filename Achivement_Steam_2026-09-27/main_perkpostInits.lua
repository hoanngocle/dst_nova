GLOBAL.setmetatable(env,{__index=function(_,k) return GLOBAL.rawget(GLOBAL,k) end})
require "functions/helperfunctions"

-- postinit :
modimport("scripts/postInits/perk_abilities")
modimport("scripts/postInits/perk_global")
modimport("scripts/postInits/perk_produce")
modimport("scripts/postInits/chasni_critter_postinit")
modimport("scripts/postInits/chasni_grounded_postinit")


-- CC : change perk costs >> [Reward] sharestar
if TheNet:GetIsServer() then
    AddPlayerPostInit(function(inst)
        local function OnPlayerCountChanges()
            if perk_lists and perk_lists.sharestar and perk_lists.sharestar.cost then
                perk_lists.sharestar.cost = (#AllPlayers - 1)
            end
            SendModRPCToClient(GetClientModRPC("AchievementUI", "change_perk_cost"), inst, "sharestar", (#AllPlayers - 1))
        end
        inst:ListenForEvent("ms_playerjoined", OnPlayerCountChanges, TheWorld)
        inst:ListenForEvent("ms_playerleft", OnPlayerCountChanges, TheWorld)
    end)
end

-- CC : add Gestalt Protection >> [Reward] expertwendy2 ghostlyelixir_chasnilunar || expertwx4 chasni_moon_soul_chip
AddComponentPostInit("inventory", function(self)
    local _EquipHasTag = self.EquipHasTag
    self.EquipHasTag = function(_self, tag, ...)
        if tag == "gestaltprotection" and _self.inst and _self.inst.components.ghostlybond and _self.inst.components.ghostlybond.ghost and _self.inst.components.ghostlybond.ghost:HasTag("ghostlyelixir_chasnilunar") then
            return true
        end
        if tag == "gestaltprotection" and _self.inst and _self.inst:HasTag("chasni_gestaltprotection") then
            return true
        end
        return _EquipHasTag(_self, tag, ...)
    end
end)

-- CC : shield sound logic || book_shield, flame_guard_buff, wormwood_poop_shield, chasni_mooncake >> [Reward] expertwicker3 expertwillow4 expertwarly4 expertworm2
AddComponentPostInit("combat", function(Combat)
    local OldGetImpactSound = Combat.GetImpactSound
    Combat.GetImpactSound = function(self, target, weapon, ...)
        if target and chasni_isShielded(target) then
            local weaponmod = weapon and weapon:HasTag("sharp") and "sharp" or "dull"
            return "dontstarve/impacts/impact_forcefield_armour_" .. weaponmod
        else
            return OldGetImpactSound(self, target, weapon, ...)
        end
    end
end)

-- CC : make "combat" false CanTarget || chasni_anzac, critter_puppy, trinket_chasni_3 >> [Reward] expertwarly4 supercritter trinketowner (Sea Worther)
AddComponentPostInit("combat", function(Combat)
    local oldCanTarget = Combat.CanTarget
    function Combat:CanTarget(target, ...)
        -- chasni_anzac expertwarly4
        if target and target:HasDebuff("chasni_anzacbuff") then
            return false
        end
        -- critter_puppy supercritter
        if target and target.components.allachivcoin and target.components.allachivcoin.supercritter then
            if Combat.inst:HasTag("hound") and target:HasTag("_supercritter_critter_puppy") then
                return false
            end
        end
        -- trinket_chasni_3 trinketowner
        if target and target:HasTag("steeringboat") then
            local trinket = chasni_getequippedtrinket(target)
            if trinket and trinket.prefab == "trinket_chasni_3" then
                return false
            end
        end
        return oldCanTarget(Combat, target, ...)
    end
end)
AddClassPostConstruct("components/combat_replica", function(self)
    local oldCanTarget = self.CanTarget
    function self:CanTarget(target, ...)
        -- chasni_anzac expertwarly4
        if target and target:HasDebuff("chasni_anzacbuff") then
            return false
        end
        -- critter_puppy supercritter
        if target and target.currentsupercritter and target.currentsupercritter:value() == 1 then
            if self.inst:HasTag("hound") and target:HasTag("_supercritter_critter_puppy") then
                return false
            end
        end
        return oldCanTarget(self, target, ...)
    end
end)

-- CC : force rift can or cannot be spawn >> [Perk] Global Rift Control / Intant Open Rift
AddComponentPostInit("riftspawner", function(self)
    local oldGetNextRiftPrefab = self.GetNextRiftPrefab
    function self:GetNextRiftPrefab(target, prefab, radius, ...)
        if TUNING.ACH["riftcontroller"] == 1 then
            return self.inst:HasTag("cave") and "shadowrift_portal" or "lunarrift_portal"
        elseif TUNING.ACH["riftcontroller"] == -1 then
            return nil
        end
        return oldGetNextRiftPrefab(self,target, prefab, radius, ...)
    end
end)
