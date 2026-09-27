require "behaviours/follow"
require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/panic"
require "behaviours/chaseandattack"
require "behaviours/doaction"

local BrainCommon = require("brains/braincommon")

local TARGET_FOLLOW_DIST = 4
local MAX_FOLLOW_DIST = 4.5

local function GetOwner(inst)
    return inst.components.follower and inst.components.follower:GetLeader()
end

local function KeepFaceTargetFn(inst, target)
    return GetOwner(inst) == target
end

-------------------------------------------------------------------------------
-- Combat Helpers

local function CanAttack(inst)
    return (inst.attack_cd == nil or GetTime() >= inst.attack_cd) and inst._cannotattack ~= true
end

local function CanCast(inst)
    local now = GetTime()

    -- Casting is currently blocked.
    if inst.CanCast == nil or not inst:CanCast() then
        -- Save the remaining cooldown once.
        if inst._castdelaytime == nil and inst.spell_cd ~= nil then
            inst._castdelaytime = math.max(0, inst.spell_cd - now)
        end

        return false
    end

    -- Casting became available again.
    -- Resume the paused cooldown.
    if inst._castdelaytime ~= nil then
        inst.spell_cd = now + inst._castdelaytime
        inst._castdelaytime = nil
    end

    -- No cooldown.
    if inst.spell_cd == nil then
        return true
    end

    -- Cooldown expired?
    return now >= inst.spell_cd
end

-------------------------------------------------------------------------------
--- Minigames

local function WatchingMinigame(inst)
    local owner = GetOwner(inst)
    return (owner ~= nil and owner.components.minigame_participator ~= nil)
            and owner.components.minigame_participator:GetMinigame()
            or nil
end

local function WatchingMinigame_MinDist(inst)
    local minigame = WatchingMinigame(inst)
    return minigame ~= nil and minigame.components.minigame.watchdist_min or 0
end

local function WatchingMinigame_TargetDist(inst)
    local minigame = WatchingMinigame(inst)
    return minigame ~= nil and minigame.components.minigame.watchdist_target or 0
end

local function WatchingMinigame_MaxDist(inst)
    local minigame = WatchingMinigame(inst)
    return minigame ~= nil and minigame.components.minigame.watchdist_max or 0
end

-------------------------------------------------------------------------------
--- Pickups (bee)
local function CanHarvest(owner, item)
    local itemprefab = item.components.harvestable and item.components.harvestable.product
    return itemprefab and item.components.harvestable and item.components.harvestable:CanHarvest() and owner.components.inventory:Has(itemprefab, 1)
end
local function CanPick(owner, item)
    local itemprefab = item.components.pickable and item.components.pickable.product
    return itemprefab and item.components.pickable and item.components.pickable:CanBePicked() and not item.components.pickable.use_lootdropper_for_product and owner.components.inventory:Has(itemprefab, 1)
end
local function IsValidItem(owner, item)
    if item == nil or not item:IsValid() then
        return false
    end

    if item.components.health ~= nil or item:HasTag("structure") then
        return false
    end

    if owner.components.inventory:Has(item.prefab, 1) then
        return true
    end

    if CanHarvest(owner, item) or CanPick(owner, item) then
        return true
    end

    return false
end
local function FindOwnerItem(inst)
    local owner = GetOwner(inst)
    if owner == nil or owner.components.inventory == nil then
        return nil
    end

    return FindEntity(inst, 10, function(item)
        return IsValidItem(owner, item)
    end, nil, { "INLIMBO", "NOCLICK", "catchable" })
end
local function GoToItem(inst)
    if inst.targetitem then
        inst.components.locomotor:GoToEntity(inst.targetitem)
    end
end
local function DoTheItem(inst)
    if inst.anim.pick then
        inst.sg:GoToState("pre_idle", inst.anim.pick)
        inst.SoundEmitter:PlaySound(inst:getSound("pick"))
    end
    inst.targetitem = nil
end

-------------------------------------------------------------------------------
-- Brain

local CrittersBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function CrittersBrain:OnStart()
    local watch_game = WhileNode(
            function() return WatchingMinigame(self.inst) end,
            "Watching Game",
            PriorityNode({
                Follow(self.inst, WatchingMinigame, WatchingMinigame_MinDist, WatchingMinigame_TargetDist, WatchingMinigame_MaxDist),
                RunAway(self.inst, "minigame_participator", 5, 7),
                FaceEntity(self.inst, WatchingMinigame, WatchingMinigame),
            }, 0.1)
    )

    local root = PriorityNode({
        -----------------------------------------------------------------------
        -- Cast Spell

        WhileNode(
                function()
                    return CanCast(self.inst) and not self.inst.sg:HasStateTag("busy")
                end,
                "Cast Spell",
                ActionNode(function()
                    local state = self.inst.casttype or "cast"
                    self.inst.sg:GoToState(state, self.inst.components.combat.target)
                end)
        ),
        -----------------------------------------------------------------------
        -- Attack
        WhileNode(
                function()
                    return self.inst.components.combat ~= nil and self.inst.components.combat.target ~= nil
                end,
                "Has Combat Target",
                PriorityNode({
                    WhileNode(
                            function()
                                return CanAttack(self.inst) and not self.inst.sg:HasStateTag("busy")
                            end,
                            "Attack",
                            ChaseAndAttack(self.inst, 100)
                    ),

                }, 0.25)
        ),
        -----------------------------------------------------------------------
        -- Owner Logic

        WhileNode(
                function() return GetOwner(self.inst) end,
                "Has Owner",
                PriorityNode({
                    watch_game,
                    WhileNode(
                            function()
                                if self.inst.prefab == "chasni_critter_bee_a" or self.inst.prefab == "chasni_critter_bee_b" then
                                    self.inst.targetitem = FindOwnerItem(self.inst)
                                    return self.inst.targetitem ~= nil
                                end
                                return false
                            end,
                            "Fetch Item",
                            SequenceNode({
                                ActionNode(function()
                                    self.inst.targetitem = FindOwnerItem(self.inst)
                                end),
                                WhileNode(
                                        function()
                                            local item = self.inst.targetitem
                                            return item ~= nil and item:IsValid()
                                        end,
                                        "MoveToItem",
                                        ActionNode(function()
                                            GoToItem(self.inst)
                                        end)
                                ),
                                ActionNode(function()
                                    local owner = GetOwner(self.inst)
                                    local item = self.inst.targetitem

                                    if not IsValidItem(owner, item) then
                                        self.inst.targetitem = nil
                                        return false
                                    end
                                    if not owner or not item or not item:IsValid() then
                                        return false
                                    end
                                    local x, y, z = item.Transform:GetWorldPosition()
                                    local distsq = self.inst:GetDistanceSqToPoint(x, y, z)

                                    if distsq > 1.5 then
                                        return false
                                    end

                                    if item.components.pickable and item.components.pickable:CanBePicked() then
                                        DoTheItem(self.inst)
                                        item.components.pickable:Pick(owner)
                                        return true
                                    end

                                    if item.components.harvestable and item.components.harvestable:CanHarvest() then
                                        DoTheItem(self.inst)
                                        item.components.harvestable:Harvest(owner)
                                        return true
                                    end

                                    if owner.components.inventory and item.components.inventoryitem then
                                        DoTheItem(self.inst)
                                        owner.components.inventory:GiveItem(item)
                                        return true
                                    end

                                    self.inst.targetitem = nil
                                    return false
                                end, "pickup action")
                            })
                    ),
                    Follow(
                            self.inst,
                            function() return GetOwner(self.inst) end,
                            0,
                            TARGET_FOLLOW_DIST,
                            MAX_FOLLOW_DIST
                    ),
                    FailIfRunningDecorator(
                            FaceEntity(
                                    self.inst,
                                    GetOwner,
                                    KeepFaceTargetFn
                            )
                    ),

                    StandStill(self.inst),
                })
        ),

        -----------------------------------------------------------------------

        StandStill(self.inst),

    }, .25)

    self.bt = BT(self.inst, root)
end

return CrittersBrain