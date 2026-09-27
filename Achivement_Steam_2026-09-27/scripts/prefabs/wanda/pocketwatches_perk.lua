require "functions/helperfunctions"
require "functions/deconstructionhelperfunctions"

local assets =
{
    pocketwatch_bloom = {
        Asset("ANIM", "anim/pocketwatch_bloom.zip"),
        Asset("ATLAS", "images/inventoryimages/pocketwatch_bloom.xml"),
        Asset("IMAGE", "images/inventoryimages/pocketwatch_bloom.tex"),
    },
    pocketwatch_burnt = {
        Asset("ANIM", "anim/pocketwatch_burnt.zip"),
        Asset("ATLAS", "images/inventoryimages/pocketwatch_burnt.xml"),
        Asset("IMAGE", "images/inventoryimages/pocketwatch_burnt.tex"),
    },
    pocketwatch_corrupt = {
        Asset("ANIM", "anim/pocketwatch_corrupt.zip"),
        Asset("ATLAS", "images/inventoryimages/pocketwatch_corrupt.xml"),
        Asset("IMAGE", "images/inventoryimages/pocketwatch_corrupt.tex"),
    },
    pocketwatch_deconstruct = {
        Asset("ANIM", "anim/pocketwatch_deconstruct.zip"),
        Asset("ATLAS", "images/inventoryimages/pocketwatch_deconstruct.xml"),
        Asset("IMAGE", "images/inventoryimages/pocketwatch_deconstruct.tex"),
    },
    pocketwatch_repair = {
        Asset("ANIM", "anim/pocketwatch_repair.zip"),
        Asset("ATLAS", "images/inventoryimages/pocketwatch_repair.xml"),
        Asset("IMAGE", "images/inventoryimages/pocketwatch_repair.tex"),
    },
    pocketwatch_refresher = {
        Asset("ANIM", "anim/pocketwatch_refresher.zip"),
        Asset("ATLAS", "images/inventoryimages/pocketwatch_refresher.xml"),
        Asset("IMAGE", "images/inventoryimages/pocketwatch_refresher.tex"),
    },
    pocketwatch_multiverse = {
        Asset("ANIM", "anim/pocketwatch_multiverse.zip"),
        Asset("ATLAS", "images/inventoryimages/pocketwatch_multiverse.xml"),
        Asset("IMAGE", "images/inventoryimages/pocketwatch_multiverse.tex"),
    },
}

local prefabs =
{
    "pocketwatch_cast_fx",
    "pocketwatch_cast_fx_mount",
}

local PocketWatchCommon = require "prefabs/pocketwatch_common"
local MOUNTED_CAST_TAGS = {"pocketwatch_mountedcast"}

------------------------------ BLOOM ------------------------------
local BLOOM_COOLDOWN = chasni_getitemconfig("pocketwatch_bloom", "CD") or 30
local function DoFertilise(ent)
    local orig_pos = ent:GetPosition()
    local inst = SpawnPrefab(ent.prefab)
    ent:Remove()
    local fx = SpawnPrefab("explode_reskin")
    if fx then
        fx.Transform:SetPosition(orig_pos:Get())
    end
    if inst then
        inst.Transform:SetPosition(orig_pos:Get())
    end
end

local function CanTarget_NeedFertilizer(target)
    return target:HasTag("withered") or target:HasTag("barren")
end

local function Bloom_DoCastSpell(inst, doer, target)
    if inst.components.pocketwatch.inactive then
        if CanTarget_NeedFertilizer(target) then
            DoFertilise(target)
            inst.components.rechargeable:Discharge(BLOOM_COOLDOWN)
            return true
        end
    end

    if doer.components.talker then
        doer.components.talker:Say(GetString(doer, "CHASNI_POCKETWATCH_BLOOM_FAIL"))
    end
    return false, "FERTILIZE_FAILED"
end

local function Bloom_CanTarget(inst, doer, target)
    return target and (CanTarget_NeedFertilizer(target))
end

local function bloomfn()
    local inst = PocketWatchCommon.common_fn("pocketwatch_bloom", "pocketwatch_bloom", Bloom_DoCastSpell, false, MOUNTED_CAST_TAGS)

    inst.GetActionVerb_CAST_POCKETWATCH = "FERTILIZE"
    inst.pocketwatch_CanTarget = Bloom_CanTarget

    if not TheWorld.ismastersim then
        return inst
    end

	inst.components.inventoryitem.imagename = "pocketwatch_bloom"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/pocketwatch_bloom.xml"

    inst.castfxcolour = {255 / 255, 241 / 255, 236 / 255}
    inst.components.pocketwatch.CanCastFn = Bloom_CanTarget

    return inst
end

------------------------------ BURNT ------------------------------ 
local BURNT_COOLDOWN = chasni_getitemconfig("pocketwatch_burnt", "CD") or 600
local function DoRepairBurnt(owner, ent)
    local orig_pos = ent:GetPosition()
    local prefab = ent.prefab
    local skinname = ent.skinname
    ent:Remove()

    local inst = SpawnPrefab(prefab, skinname, nil, owner.userid)
    if inst then
        inst.Transform:SetPosition(orig_pos:Get())
        inst:PushEvent("onbuilt", { builder = owner.userid })
    end
end

local function CanTarget_Burned(target)
    return target:HasTag("burnt") and target:HasTag("structure")
end

local function Burnt_DoCastSpell(inst, doer, target)
    if inst.components.pocketwatch.inactive then
        if CanTarget_Burned(target) then
            DoRepairBurnt(doer, target)
            inst.components.rechargeable:Discharge(BURNT_COOLDOWN)
            return true
        end
    end

    if doer.components.talker then
        doer.components.talker:Say(GetString(doer, "CHASNI_POCKETWATCH_BURNT_FAIL"))
    end
    return false, "REBUILD_FAILED"
end

local function Burnt_CanTarget(inst, doer, target)
    return target and (CanTarget_Burned(target))
end

local function burntfn()
    local inst = PocketWatchCommon.common_fn("pocketwatch_burnt", "pocketwatch_burnt", Burnt_DoCastSpell, false, MOUNTED_CAST_TAGS)

    inst.GetActionVerb_CAST_POCKETWATCH = "REBUILD"
    inst.pocketwatch_CanTarget = Burnt_CanTarget

    if not TheWorld.ismastersim then
        return inst
    end

	inst.components.inventoryitem.imagename = "pocketwatch_burnt"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/pocketwatch_burnt.xml"

    inst.castfxcolour = {255 / 255, 241 / 255, 236 / 255}
    inst.components.pocketwatch.CanCastFn = Burnt_CanTarget

    return inst
end

------------------------------ CORRUPT ------------------------------ 
local CORRUPT_DURATION = chasni_getitemconfig("pocketwatch_corrupt", "DUR") or 12
local CORRUPT_COOLDOWN = chasni_getitemconfig("pocketwatch_corrupt", "CD") or 900
local CORRUPT_SELF_DAMAGE = chasni_getitemconfig("pocketwatch_corrupt", "DMG") or 40
local function UnCorrupt(inst, force)
    if inst.AnimState then
        if not force then
            inst:RemoveTag("corrupted")
        end
        inst.AnimState:Resume()
        if not inst:HasTag("corrupted") then
            inst:RestartBrain()
        end

        if inst.Physics then
            inst.Physics:SetActive(true)
        end
        if inst.sg then
            inst.sg:Start()
        end
        if inst.uncorrupttask then
            inst.uncorrupttask:Cancel()
            inst.uncorrupttask = nil
            inst.uncorrupttask = nil
        end

        if inst.components.health then
            inst.components.health.externalabsorbmodifiers:RemoveModifier("pocketwatch_corrupt")
        end

        inst:ClearBufferedAction()
    end
end

local function DoCorrupt(inst, owner, ent)
    local x, y, z = owner.Transform:GetWorldPosition()
    local range = 16
    local duration = CORRUPT_DURATION
    chasni_spawnprefab("reticuleaoeshadowtarget_6", x, y, z, 1.6, 1.6, 1.6, nil, CORRUPT_DURATION)
    chasni_spawnprefab("shadow_teleport_out", x, y, z, 3, 3, 3)
    local task = inst:DoPeriodicTask(0.5, function()
        local targets = TheSim:FindEntities(x, y, z, range)
        for i, target in ipairs(targets) do
            if target.prefab ~= "wanda" then
                if target.AnimState and not target:HasTag("corrupted") then
                    local tx, ty, tz = target.Transform:GetWorldPosition()
                    chasni_spawnprefab("tophat_using_shadow_fx", tx, ty, tz, nil, nil, nil, nil, duration)

                    target:AddTag("corrupted")
                    target.AnimState:Pause()
                    if target.components.combat then target.components.combat:SetTarget(nil) end
                    if target.brain then target.brain:Stop() end
                    if target.Physics then target.Physics:SetActive(false) end
                    if target.components.locomotor then target.components.locomotor:Stop() end
                    if target.sg then target.sg:Stop() end
                    target:ClearBufferedAction()

                    target.nosound = target:DoPeriodicTask(0,function ()
                        if target and target.SoundEmitter then target.SoundEmitter:KillAllSounds() end
                    end)
                    target:DoTaskInTime(duration,function()
                        if target.nosound then target.nosound:Cancel() target.nosound = nil end
                    end)

                    if target.components.health then
                        target.components.health.externalabsorbmodifiers:SetModifier("pocketwatch_corrupt", 0.5)
                    end

                    target.uncorrupttask = target:DoTaskInTime(duration,function() UnCorrupt(target) end)
                    target:ListenForEvent("minhealth", function(inst) UnCorrupt(target, true) end)
                    inst:ListenForEvent("onremove", function(obj) UnCorrupt(target, true) end)
                end
            end
        end
        duration = duration - 0.5
    end)
    inst:DoTaskInTime(CORRUPT_DURATION, function()
        chasni_spawnprefab("shadow_teleport_in", x, y, z, 3, 3, 3)
        if task then
            task:Cancel()
            task = nil
        end
    end)
end

local function Corrupt_DoCastSpell(inst, doer, target)
    if inst.components.pocketwatch.inactive then
        DoCorrupt(inst, doer, target)
        inst.components.rechargeable:Discharge(CORRUPT_COOLDOWN)
        local health = doer.components.health
        if health and not health:IsDead() then
            health:DoDelta(CORRUPT_SELF_DAMAGE, true, inst.prefab)
        end
        return true
    end

    if doer.components.talker then
        doer.components.talker:Say(GetString(doer, "CHASNI_POCKETWATCH_REPAIR_FAIL"))
    end
    return false, "REPAIR_FAILED"
end

local function corruptfn()
    local inst = PocketWatchCommon.common_fn("pocketwatch_corrupt", "pocketwatch_corrupt", Corrupt_DoCastSpell, true, MOUNTED_CAST_TAGS)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.inventoryitem.imagename = "pocketwatch_corrupt"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/pocketwatch_corrupt.xml"

    inst.castfxcolour = {255 / 255, 241 / 255, 236 / 255}
    return inst
end

------------------------------ DECONSTRUCT ------------------------------ 
local DECONSTRUCT_COOLDOWN = chasni_getitemconfig("pocketwatch_deconstruct", "CD") or 180

local function DoDisassemble(target, caster)
    chasni_DoDisasemble(target, caster)
end

local function CanTarget_Disassemble(target)
    local recipe = AllRecipes[target.prefab]
    return not (recipe == nil or FunctionOrValue(recipe.no_deconstruction, target) or FunctionOrValue(recipe.placer, target) or FunctionOrValue(recipe.builder_tag, target))
end

local function Deconstruct_DoCastSpell(inst, doer, target)
    if inst.components.pocketwatch.inactive then
        if CanTarget_Disassemble(target) then
            DoDisassemble(target, doer)
            inst.components.rechargeable:Discharge(DECONSTRUCT_COOLDOWN)
            return true
        end
    end

    if doer.components.talker then
        doer.components.talker:Say(GetString(doer, "CHASNI_POCKETWATCH_DECONSTRUCT_FAIL"))
    end
    return false, "DECONSTRUCT_FAILED"
end

local function Deconstruct_CanTarget(inst, doer, target)
    return target and (CanTarget_Disassemble(target))
end

local function deconstructfn()
    local inst = PocketWatchCommon.common_fn("pocketwatch_deconstruct", "pocketwatch_deconstruct", Deconstruct_DoCastSpell, false, MOUNTED_CAST_TAGS)

    inst.GetActionVerb_CAST_POCKETWATCH = "DECONSTRUCT"
    inst.pocketwatch_CanTarget = Deconstruct_CanTarget

    if not TheWorld.ismastersim then
        return inst
    end

	inst.components.inventoryitem.imagename = "pocketwatch_deconstruct"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/pocketwatch_deconstruct.xml"

    inst.castfxcolour = {255 / 255, 241 / 255, 236 / 255}
    inst.components.pocketwatch.CanCastFn = Deconstruct_CanTarget

    return inst
end

------------------------------ REPAIR ------------------------------ 
local REPAIR_COOLDOWN = chasni_getitemconfig("pocketwatch_repair", "CD") or 120
local function DoRepair(inst, owner, ent)
    local x, y, z = owner.Transform:GetWorldPosition()
    local range = 12
    local leaks = TheSim:FindEntities(x, y, z, range, {"boat_leak"})
    for i, v in ipairs(leaks) do
        if v.components.boatleak then
            if v:HasTag("boat_leak") then
                v.AnimState:PlayAnimation("leak_small_pst")
                v:DoTaskInTime(0.4, function(inst)
                    v.components.boatleak:SetState("repaired_treegrowth")
                end)
            end
        end
    end
end

local function Repair_DoCastSpell(inst, doer, target)
    if inst.components.pocketwatch.inactive then
        DoRepair(inst, doer, target)
        inst.components.rechargeable:Discharge(REPAIR_COOLDOWN)
        return true
    end

    if doer.components.talker then
        doer.components.talker:Say(GetString(doer, "CHASNI_POCKETWATCH_REPAIR_FAIL"))
    end
    return false, "REPAIR_FAILED"
end

local function repairfn()
    local inst = PocketWatchCommon.common_fn("pocketwatch_repair", "pocketwatch_repair", Repair_DoCastSpell, true, MOUNTED_CAST_TAGS)

    if not TheWorld.ismastersim then
        return inst
    end

	inst.components.inventoryitem.imagename = "pocketwatch_repair"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/pocketwatch_repair.xml"

    inst.castfxcolour = {255 / 255, 241 / 255, 236 / 255}
    return inst
end
------------------------------ REFRESHER ------------------------------ 
local REFRESHER_COOLDOWN = chasni_getitemconfig("pocketwatch_refresher", "CD") or 300
local function HaveRechargeable(item)
    return item:HasTag("rechargeable") and not item:HasTag("pocketwatch")
end

local function DoRefresher(inst, owner, ent)
    local x, y, z = owner.Transform:GetWorldPosition()
    local range = 12
    local players = FindPlayersInRange(x, y, z, range)
    for i, v in ipairs(players) do
        if v.components.inventory then
            local items = v.components.inventory:FindItems(HaveRechargeable)
            for _, item in ipairs(items) do
                if item.components.rechargeable then
                    item.components.rechargeable:SetPercent(1)
                end
            end
        end
    end
end

local function Refresher_DoCastSpell(inst, doer, target)
    if inst.components.pocketwatch.inactive then
        DoRefresher(inst, doer, target)
        inst.components.rechargeable:Discharge(REFRESHER_COOLDOWN)
        return true
    end

    if doer.components.talker then
        doer.components.talker:Say(GetString(doer, "CHASNI_POCKETWATCH_REFRESHER_FAIL"))
    end
    return false, "REFRESHER_FAILED"
end

local function refresherfn()
    local inst = PocketWatchCommon.common_fn("pocketwatch_refresher", "pocketwatch_refresher", Refresher_DoCastSpell, true, MOUNTED_CAST_TAGS)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.inventoryitem.imagename = "pocketwatch_refresher"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/pocketwatch_refresher.xml"

    inst.castfxcolour = {255 / 255, 241 / 255, 236 / 255}
    return inst
end
------------------------------ MULTIVERSE ------------------------------ 
local MULTIVERSE_COOLDOWN = chasni_getitemconfig("pocketwatch_multiverse", "CD") or 5
local function TryGetNormalClone(inst, timebreak)
    if (inst.components.sanity and inst.components.sanity:IsEnlightened()) or (math.random(800,1250) > timebreak) then
        inst._timebreak = (timebreak + 200) + GetTime()
        return "wanda_clone_normal"
    end
    inst._timebreak = (timebreak + 50) + GetTime()
    return "wanda_clone_evil"
end
local function TryGetChopperClone(inst, timebreak)
    if (inst.components.sanity and inst.components.sanity:IsEnlightened()) or (math.random(500,1000) > timebreak) then
        inst._timebreak = (timebreak + 250) + GetTime()
        return "wanda_clone_chopper"
    end
    return TryGetNormalClone(inst, timebreak)
end
local function TryGetMinerClone(inst, timebreak)
    if (inst.components.sanity and inst.components.sanity:IsEnlightened()) or (math.random(500,1000) > timebreak) then
        inst._timebreak = (timebreak + 250) + GetTime()
        return "wanda_clone_miner"
    end
    return TryGetNormalClone(inst, timebreak)
end
local function TryGetWorkerClone(inst, timebreak)
    if (inst.components.sanity and inst.components.sanity:IsEnlightened()) or (math.random(300,750) > timebreak) then
        inst._timebreak = (timebreak + 300) + GetTime()
        return "wanda_clone_worker"
    end
    if math.random() < 0.5 then
        return TryGetChopperClone(inst, timebreak)
    end
    return TryGetMinerClone(inst, timebreak)
end
local function TryGetFighterClone(inst, timebreak)
    if (inst.components.sanity and inst.components.sanity:IsEnlightened()) or (math.random(150,500) > timebreak) then
        inst._timebreak = (timebreak + 350) + GetTime()
        return "wanda_clone_fighter"
    end
    if math.random() < 0.5 then
        return TryGetChopperClone(inst, timebreak)
    end
    return TryGetMinerClone(inst, timebreak)
end
local function GetCloneType(inst, handequipment)
    local timebreak = inst._timebreak and (inst._timebreak - GetTime()) or 0
    if handequipment then
        if handequipment.components.tool then
            local canchop = handequipment.components.tool:CanDoAction(ACTIONS.CHOP)
            local canmine = handequipment.components.tool:CanDoAction(ACTIONS.MINE)
            if canchop and canmine then
                return TryGetWorkerClone(inst, timebreak)
            end
            if canchop then
                return TryGetChopperClone(inst, timebreak)
            end
            if canmine then
                return TryGetMinerClone(inst, timebreak)
            end
        end
        if handequipment.prefab == "pocketwatch_weapon" then
            return TryGetFighterClone(inst, timebreak)
        end
    end
    return TryGetNormalClone(inst, timebreak)
end

local function SpawnClones(caster)
    local pt = caster:GetPosition()
    local clonecount = 3
    local num_fails = 0
    local positions = {}
    for _ = 1, clonecount do
        local theta = math.random() * 2 * PI
        local radius = math.random(1, 5)
        local result_offset = FindValidPositionByFan(theta, radius, 8, function(offset)
            local pos = pt + offset
            return #TheSim:FindEntities(pos.x, 0, pos.z, 1, nil, { "INLIMBO", "FX" }) <= 0 and TheWorld.Map:IsPassableAtPoint(pos:Get()) and TheWorld.Map:IsDeployPointClear(pos, nil, 1)
        end)
        if result_offset then table.insert(positions, {x = pt.x + result_offset.x, z = pt.z + result_offset.z}) else num_fails = num_fails + 1 end
    end

    if num_fails >= clonecount then return end
    caster:StartThread(function()
        for i, pos in ipairs(positions) do
            local handequipment = caster.components.inventory and caster.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
            local cloneprefab = GetCloneType(caster, handequipment)
            local clone = chasni_spawnprefab(cloneprefab, pos.x, 0, pos.z)
            chasni_spawnprefab("pocketwatch_portal_exit_fx", pos.x, 4, pos.z)
            if clone then
                clone:CopySkin(caster)
                if clone.components.combat and clone.components.combat:TargetIs(caster) then
                    clone.components.combat:SetTarget(nil)
                end
                if cloneprefab ~= "wanda_clone_evil" and clone.components.follower and caster.components.leader then
                    caster:PushEvent("makefriend")
                    caster.components.leader:AddFollower(clone)
                end
            end
            Sleep(1)
        end
    end)
end
local function DoMultiverse(inst, owner, ent)
    SpawnClones(owner)
end

local function Multiverse_DoCastSpell(inst, doer, target)
    if inst.components.pocketwatch.inactive then
        DoMultiverse(inst, doer, target)
        inst.components.rechargeable:Discharge(MULTIVERSE_COOLDOWN)
        return true
    end

    if doer.components.talker then
        doer.components.talker:Say(GetString(doer, "CHASNI_POCKETWATCH_MULTIVERSE_FAIL"))
    end
    return false, "MULTIVERSE_FAILED"
end

local function multiversefn()
    local inst = PocketWatchCommon.common_fn("pocketwatch_multiverse", "pocketwatch_multiverse", Multiverse_DoCastSpell, true, MOUNTED_CAST_TAGS)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.inventoryitem.imagename = "pocketwatch_multiverse"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/pocketwatch_multiverse.xml"

    inst.castfxcolour = {255 / 255, 241 / 255, 236 / 255}
    return inst
end

return
Prefab("chasni_pocketwatch_bloom", bloomfn, assets.pocketwatch_bloom, prefabs),
Prefab("chasni_pocketwatch_burnt", burntfn, assets.pocketwatch_burnt, prefabs),
Prefab("chasni_pocketwatch_corrupt", corruptfn, assets.pocketwatch_corrupt, prefabs),
Prefab("chasni_pocketwatch_deconstruct", deconstructfn, assets.pocketwatch_deconstruct, prefabs),
Prefab("chasni_pocketwatch_repair", repairfn, assets.pocketwatch_repair, prefabs),
Prefab("chasni_pocketwatch_refresher", refresherfn, assets.pocketwatch_refresher, prefabs),
Prefab("chasni_pocketwatch_multiverse", multiversefn, assets.pocketwatch_multiverse, prefabs)
