local assets =
{
    Asset("ANIM", "anim/goldenklausbag.zip"),
}

local prefabs =
{
    "chasni_klaus",
    "boneshard",
    "gift",

    --loot
    "charcoal",
    "goldnugget",
    "deerclops_eyeball",
    "dragon_scales",
    "bearger_fur",
    "royal_jelly",
    "shroom_skin",
    "minotaurhorn",
    "townportaltalisman",
    "milkywhites",
    "malbatross_feather",
    "malbatross_beak",
    "chasni_wargfant_tooth",
    "chasni_wargfant_fur",
    "chasni_grub_jaw",
    "chasni_grub_skull",
    "chasni_pangolden_scale",
    "chasni_crocodog_skin",
    "chasni_cocoontreeseed",
    "chasni_quas_feather",
    "chasni_slipstor_fur",
    "chasni_snapdragon_petal",
    "dug_trap_flytrap",
    "chasni_snapdragon_seed",
    "chasni_exort_feather",
    "chasni_palmtreeguard_log",
    "chasni_hippo_skin",
    "chasni_hippo_antler",
    "mandrake",
}
local giant_loot1 =
{
    "deerclops_eyeball",
    "dragon_scales",
    "bearger_fur",
    "royal_jelly",
    "shroom_skin",
    "minotaurhorn",
    "townportaltalisman",
    "milkywhites",
    "malbatross_feather",
    "malbatross_beak",
    
}

local giant_loot2 =
{
    "chasni_wargfant_tooth",
    "chasni_wargfant_fur",
    "chasni_grub_jaw",
    "chasni_grub_skull",
    "chasni_pangolden_scale",
    "chasni_crocodog_skin",
    "chasni_cocoontreeseed",
}

local giant_loot3 =
{
    "chasni_quas_feather",
    "chasni_slipstor_fur",
    "chasni_snapdragon_petal",
    "dug_trap_flytrap",
    "chasni_snapdragon_seed",
    "chasni_exort_feather",
    "chasni_palmtreeguard_log",
    "chasni_hippo_skin",
    "chasni_hippo_antler",
    "mandrake",
}

local giant_loot4 =
{
    "goldnugget",
    "charcoal",
}

local function RollKlausLoot()
    local items = {}
    table.insert(items, giant_loot1[math.random(#giant_loot1)])
    table.insert(items, giant_loot2[math.random(#giant_loot2)])
    table.insert(items, giant_loot3[math.random(#giant_loot3)])
    table.insert(items, giant_loot4[math.random(#giant_loot4)])
    return items
end

local function GetKlausLoots()
    local loot = {}
    table.insert(loot, RollKlausLoot())
    table.insert(loot, RollKlausLoot())
    table.insert(loot, RollKlausLoot())
    table.insert(loot, RollKlausLoot())
    return loot
end


local function DropBundle(inst, items)
    for i, v in ipairs(items) do
        if type(v) == "string" then
            items[i] = SpawnPrefab(v)
        else
            items[i] = SpawnPrefab(v[1])
            items[i].components.stackable:SetStackSize(v[2])
        end
    end

    local bundle = SpawnPrefab("gift")
    bundle.components.unwrappable:WrapItems(items)
    for i, v in ipairs(items) do
        v:Remove()
    end
    inst.components.lootdropper:FlingItem(bundle)
end

local function onuseklauskey(inst, key, doer)
    if key.components.klaussackkey == nil then
        return false
    elseif key.prefab == "chasni_klaussackkey" then
        inst.AnimState:PlayAnimation("open")
        inst.SoundEmitter:PlaySound("dontstarve/creatures/together/klaus/chain_foley")
        inst.SoundEmitter:PlaySound("dontstarve/creatures/together/klaus/lock_break")

        for i, items in ipairs(GetKlausLoots()) do
            DropBundle(inst, items)
        end

        inst.persists = false
        inst:AddTag("NOCLICK")
        inst:DoTaskInTime(1, ErodeAway)

        inst:RemoveComponent("klaussacklock")
        return true, nil, true
    elseif key.prefab ~= "klaussackkey" then
        LaunchAt(SpawnPrefab("boneshard"), inst, doer, .2, 1, 1)

        inst.AnimState:PlayAnimation("jiggle")
        inst.AnimState:PushAnimation("idle", false)
        inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/chain")

        local pos = inst:GetPosition()
        local minplayers = math.huge
        local spawnx, spawnz
        FindWalkableOffset(pos,
            math.random() * 2 * PI, 33, 16, true, true,
            function(pt)
                local count = #FindPlayersInRangeSq(pt.x, pt.y, pt.z, 625)
                if count < minplayers then
                    minplayers = count
                    spawnx, spawnz = pt.x, pt.z
                    return count <= 0
                end
                return false
            end)

        if spawnx == nil then
            local offset = FindWalkableOffset(pos, math.random() * 2 * PI, 3, 8, false, true)
            if offset then
                spawnx, spawnz = pos.x + offset.x, pos.z + offset.z
            end
        end

        local klaus = SpawnPrefab("chasni_klaus")
        klaus.Transform:SetPosition(spawnx or pos.x, 0, spawnz or pos.z)
        klaus.components.knownlocations:RememberLocation("spawnpoint", pos, false)
        klaus.components.spawnfader:FadeIn()

        return false, "WRONGKEY", true
    end
    return false
end

local function OnSave(inst, data)
    data.despawnday = inst.despawnday
end

local function OnLoad(inst, data)
    if data then
        inst.despawnday = data.despawnday or 0
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:DoTaskInTime(1, function()
        MakeSmallObstaclePhysics(inst, 1)
    end)
    inst.AnimState:SetBank("goldenklausbag")
    inst.AnimState:SetBuild("goldenklausbag")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("klaussacklock")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("klaussacklock")
    inst.components.klaussacklock:SetOnUseKey(onuseklauskey)

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("chasni_klaus_sack", fn, assets, prefabs)
