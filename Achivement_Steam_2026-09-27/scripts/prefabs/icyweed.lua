local Loot = require("functions/icyweedloot")
local LootData = require("constants/icyweedloot")

local assets =
{
    Asset("ANIM", "anim/tumbleweed_icy.zip"),
}

local prefabs =
{
    "splash_sink",
    "chasni_icyweedbreakfx",
    "goldnugget",
    "saltrock",
    "moonrocknugget",
    "moonglass",
    "gears",
    "lunarplant_husk",
    "dreadstone",
    "thulecite",
    "purebrilliance",
    "horrorfuel",
    "voidcloth",
    "wagpunk_bits",
}

-- Optional mod prefabs are resolved from the live registry, never hard dependencies.
local support_cache, warnings = {}, {}
local function WarnOnce(key, message)
    if not warnings[key] then
        warnings[key] = true
        print("[Achievement icyweed] " .. message)
    end
end

local function SafeSpawn(prefab)
    local ok, item = pcall(SpawnPrefab, prefab)
    if ok and item ~= nil then return item end
    WarnOnce("spawn:" .. prefab, "Could not spawn " .. prefab .. "; using fallback")
end

local function StackLimit(item)
    local stack = item.components and item.components.stackable
    if stack == nil then return nil end
    local maximum = stack.GetMaxSize and stack:GetMaxSize() or stack.maxsize
    if type(maximum) ~= "number" or maximum < 1 or maximum ~= maximum then return nil end
    return math.floor(maximum)
end

local function Exists(prefab)
    local exists = Prefabs ~= nil and Prefabs[prefab] ~= nil
    if not exists and prefab == LootData.fallback.prefab then
        WarnOnce("missing:tutien", "xd_lingshi1 unavailable; required Tu Tien dependency missing, using goldnugget")
    end
    return exists
end

local function StackSupported(prefab)
    local definition = Prefabs and Prefabs[prefab]
    local cached = support_cache[prefab]
    if cached ~= nil and cached.definition == definition then return cached.supported end
    local supported = false
    if definition ~= nil then
        local item = SafeSpawn(prefab)
        if item ~= nil then
            supported = StackLimit(item) ~= nil
            item:Remove()
        end
    end
    support_cache[prefab] = {definition = definition, supported = supported}
    if not supported then WarnOnce("unsupported:" .. prefab, prefab .. " unavailable or not stackable; using fallback") end
    return supported
end

local function EnsureLoot(inst)
    if inst.loot == nil then
        inst.loot = Loot.Roll(Loot.PreparePool(Exists, StackSupported))
    end
end

local function Fallback(prefab, amount)
    local row = LootData.fallback
    if prefab == row.prefab or not Exists(row.prefab) or not StackSupported(row.prefab) then
        row = LootData.emergency
    end
    -- Keep replacement quantities deterministic across save/load and mod changes.
    return row.prefab, math.clamp(amount, row.min, row.max)
end

local function SpawnReward(row, items)
    local prefab, remaining = row.prefab, row.amount
    if not Exists(prefab) or not StackSupported(prefab) then
        prefab, remaining = Fallback(prefab, remaining)
    end
    while remaining > 0 do
        local item = SafeSpawn(prefab)
        local limit = item and StackLimit(item)
        if limit == nil then
            if item ~= nil then item:Remove() end
            if prefab == LootData.emergency.prefab then
                WarnOnce("lost:" .. prefab, "Even goldnugget fallback failed; could not deliver reward")
                return
            end
            prefab, remaining = Fallback(prefab, remaining)
        else
            local amount = math.min(remaining, limit)
            item.components.stackable:SetStackSize(amount)
            remaining = remaining - amount
            for _, existing in ipairs(items) do
                if item == nil then break end
                local stack = existing.components.stackable
                if existing.prefab == item.prefab and stack:StackSize() < StackLimit(existing)
                    and stack:CanStackWith(item) then
                    item = stack:Put(item)
                end
            end
            if item ~= nil then items[#items + 1] = item end
        end
    end
end

local ANGLE_VARIANCE = 10
local SFX_COOLDOWN = 5

local function onplayerprox(inst)
    if not inst.last_prox_sfx_time or (GetTime() - inst.last_prox_sfx_time > SFX_COOLDOWN) then
       inst.last_prox_sfx_time = GetTime()
       inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_choir")
    end
end

local function CheckGround(inst)
    if not inst:IsOnValidGround() then
        SpawnPrefab("splash_sink").Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst:PushEvent("detachchild")
        inst:Remove()
    end
end

local function startmoving(inst)
    inst.AnimState:PushAnimation("move_loop", true)
    inst.bouncepretask = inst:DoTaskInTime(10*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_bounce")
        inst.bouncetask = inst:DoPeriodicTask(24*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_bounce")
            CheckGround(inst)
        end)
    end)
    inst.components.blowinwind:Start()
    inst:RemoveEventCallback("animover", startmoving)
end

local function onpickup(inst, picker)
    if inst.loot_claimed then return true end
    inst.loot_claimed = true
    EnsureLoot(inst)
    inst:PushEvent("detachchild")
    local x, y, z = inst.Transform:GetWorldPosition()
    local items = {}
    for _, row in ipairs(inst.loot) do SpawnReward(row, items) end
    for _, item in ipairs(items) do
        item.Transform:SetPosition(x, y, z)
        if item.components.inventoryitem and item.components.inventoryitem.ondropfn then
            item.components.inventoryitem.ondropfn(item)
        end
    end
    local fx = SafeSpawn("chasni_icyweedbreakfx")
    if fx ~= nil then fx.Transform:SetPosition(x, y, z) end

    return true --This makes the inventoryitem component not actually give the tumbleweed to the player
end

local function OnSave(inst, data)
    EnsureLoot(inst)
    data.icyweed_loot = {version = LootData.version, rewards = inst.loot}
    data.icyweed_claimed = inst.loot_claimed or nil
end

local function OnLoad(inst, data)
    inst.loot = Loot.NormalizeSaved(data and data.icyweed_loot)
    if data and data.icyweed_claimed then
        inst.loot_claimed = true
        inst:Remove()
    end
end

local function DoDirectionChange(inst, data)
    if not inst.entity:IsAwake() then return end
    if data and data.angle and data.velocity and inst.components.blowinwind then
        if inst.angle == nil then
            inst.angle = math.clamp(GetRandomWithVariance(data.angle, ANGLE_VARIANCE), 0, 360)
            inst.components.blowinwind:Start(inst.angle, data.velocity)
        else
            inst.angle = math.clamp(GetRandomWithVariance(data.angle, ANGLE_VARIANCE), 0, 360)
            inst.components.blowinwind:ChangeDirection(inst.angle, data.velocity)
        end
    end
end

local function CancelRunningTasks(inst)
    if inst.bouncepretask then
       inst.bouncepretask:Cancel()
        inst.bouncepretask = nil
    end
    if inst.bouncetask then
        inst.bouncetask:Cancel()
        inst.bouncetask = nil
    end
    if inst.restartmovementtask then
        inst.restartmovementtask:Cancel()
        inst.restartmovementtask = nil
    end
    if inst.bouncepst1 then
       inst.bouncepst1:Cancel()
        inst.bouncepst1 = nil
    end
    if inst.bouncepst2 then
        inst.bouncepst2:Cancel()
        inst.bouncepst2 = nil
    end
end

local function OnEntityWake(inst)
    inst.AnimState:PlayAnimation("move_loop", true)
    inst.bouncepretask = inst:DoTaskInTime(10*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_bounce")
        inst.bouncetask = inst:DoPeriodicTask(24*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_bounce")
            CheckGround(inst)
        end)
    end)
end

local function OnLongAction(inst)
    inst.Physics:Stop()
    inst.components.blowinwind:Stop()
    inst:RemoveEventCallback("animover", startmoving)

    CancelRunningTasks(inst)
    inst.AnimState:PlayAnimation("move_pst")
    inst.bouncepst1 = inst:DoTaskInTime(4*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_bounce")
        inst.bouncepst1 = nil
    end)
    inst.bouncepst2 = inst:DoTaskInTime(10*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tumbleweed_bounce")
        inst.bouncepst2 = nil
    end)
    inst.AnimState:PushAnimation("idle", true)
    inst.restartmovementtask = inst:DoTaskInTime(math.random(2,6), function(inst)
        if inst and inst.components.blowinwind then
            inst.AnimState:PlayAnimation("move_pre")
            inst.restartmovementtask = nil
            inst:ListenForEvent("animover", startmoving)
        end
    end)
end

local function burntfxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBuild("tumbleweed_icy")
    inst.AnimState:SetBank("tumbleweed_icy")
    inst.AnimState:PlayAnimation("break")

    inst:AddTag("FX")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
    inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + FRAMES, inst.Remove)

    return inst
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()
    inst.DynamicShadow:SetSize(1.7, .8)

    inst.AnimState:SetBuild("tumbleweed_icy")
    inst.AnimState:SetBank("tumbleweed_icy")
    inst.AnimState:PlayAnimation("move_loop", true)

    MakeCharacterPhysics(inst, .5, 1)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.scrapbook_anim = "idle"

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetTriggersCreep(false)

    inst:AddComponent("blowinwind")
    inst.components.blowinwind.soundPath = "dontstarve_DLC001/common/tumbleweed_roll"
    inst.components.blowinwind.soundName = "tumbleweed_roll"
    inst.components.blowinwind.soundParameter = "speed"
    inst.angle = (TheWorld and TheWorld.components.worldwind) and TheWorld.components.worldwind:GetWindAngle() or nil
    inst:ListenForEvent("windchange", function(world, data)
        DoDirectionChange(inst, data)
    end, TheWorld)
    if inst.angle then
        inst.angle = math.clamp(GetRandomWithVariance(inst.angle, ANGLE_VARIANCE), 0, 360)
        inst.components.blowinwind:Start(inst.angle)
    else
        inst.components.blowinwind:StartSoundLoop()
    end

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetOnPlayerNear(onplayerprox)
    inst.components.playerprox:SetDist(5,10)

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_sticks"
    inst.components.pickable.onpickedfn = onpickup
	inst.components.pickable.remove_when_picked = true
    inst.components.pickable.canbepicked = true

    inst:ListenForEvent("startlongaction", OnLongAction)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    -- Load restores saved loot before this task executes; legacy weeds roll once.
    inst:DoTaskInTime(0, EnsureLoot)

    MakeSmallPropagator(inst)
    inst.components.propagator.flashpoint = 5 + math.random()*3

    inst.OnEntityWake = OnEntityWake
    inst.OnEntitySleep = CancelRunningTasks

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        if math.random() < TUNING.HAUNT_CHANCE_OCCASIONAL then
            onpickup(inst, nil)
			inst:Remove()
        end
        return true
    end)

    return inst
end

return Prefab("chasni_icyweed", fn, assets, prefabs),
    Prefab("chasni_icyweedbreakfx", burntfxfn, assets)
