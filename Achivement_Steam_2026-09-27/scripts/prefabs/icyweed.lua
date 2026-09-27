local assets =
{
    Asset("ANIM", "anim/tumbleweed_icy.zip"),
}

local prefabs =
{
    "splash_sink",
    "chasni_icyweedbreakfx",
    "ice",
    "rocks",
    "flint",
    "saltrock",
    "nitre",
    "lunarplant_husk",
    "moonstorm_spark",
    "moonglass_charged",
    "security_pulse_cage",
    "dreadstone",
    "thulecite",
    "purebrilliance",
    "horrorfuel",
    "voidcloth",
    "wagpunk_bits",
    "moonstorm_static_item",
    "moonstorm_spark",
    "gelblob_bottle",
}

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
    inst:PushEvent("detachchild")
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(inst.loot) do
        local item = SpawnPrefab(v)
        item.Transform:SetPosition(x, y, z)
        if item.components.inventoryitem and item.components.inventoryitem.ondropfn then
            item.components.inventoryitem.ondropfn(item)
        end
    end
    SpawnPrefab("chasni_icyweedbreakfx").Transform:SetPosition(x, y, z)

    return true --This makes the inventoryitem component not actually give the tumbleweed to the player
end

local function MakeLoot(inst)
    local possible_loot =
    {
        {chance = 70,    item = "ice"},
        {chance = 30,    item = "rocks"},
        {chance = 30,    item = "flint"},
        {chance = 20,    item = "saltrock"},
        {chance = 20,    item = "nitre"},
        {chance = 14,    item = "goldnugget"},
        {chance = 10,    item = "trinket"},

        {chance = 8,     item = "moonrocknugget"},
        {chance = 8,     item = "moonglass"},
        {chance = 8,     item = "thulecite"},
        {chance = 6,     item = "gears"},
        {chance = 5,     item = "dreadstone"},
        {chance = 5,     item = "horrorfuel"},
        {chance = 4,    item = "wagpunk_bits"},

        {chance = 3,    item = "lunarplant_husk"},
        {chance = 3,    item = "moonglass_charged"},
        {chance = 3,    item = "purebrilliance"},
        {chance = 3,    item = "voidcloth"},
        {chance = 2,    item = "moonstorm_static_item"},
        {chance = 2,    item = "gelblob_bottle"},
        {chance = 1,    item = "security_pulse_cage"},
    }

    local totalchance = 0
    for m, n in ipairs(possible_loot) do
        totalchance = totalchance + n.chance
    end

    inst.loot = {}
    local next_loot, next_chance
    local num_loots = 3
    while num_loots > 0 do
        next_chance = math.random()*totalchance
        next_loot = nil
        for _, n in ipairs(possible_loot) do
            next_chance = next_chance - n.chance
            if next_chance <= 0 then
                next_loot = n.item
                break
            end
        end
        if next_loot then
            if next_loot == "trinket" then
                next_loot = "trinket_" .. math.random(1, 46)
            end
            table.insert(inst.loot, next_loot)
            num_loots = num_loots - 1
        end
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

    MakeLoot(inst)

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
