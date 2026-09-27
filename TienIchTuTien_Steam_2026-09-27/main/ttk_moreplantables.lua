-- Selected planting features adapted from More Plantables - DST (Morback et al.).
local G = GLOBAL
local TUNING = G.TUNING
local SpawnPrefab = G.SpawnPrefab

PrefabFiles = PrefabFiles or {}
for _, prefab in ipairs({"asporen", "mushtree_sapling", "mushroots", "moreplantables_placer"}) do
    PrefabFiles[#PrefabFiles + 1] = prefab
end

local plantables = {}
local EVIL_FLOWER_REGROW_TIMER = "ttk_evil_flower_regrow"
local EVIL_FLOWER_REGROW_TIME = 2 * TUNING.TOTAL_DAY_TIME

local function MakeEvilFlowerRegrowable(flower)
    if flower._ttk_regrowing_evil_flower then return end
    local pickable = flower.components.pickable
    if pickable == nil then return end

    flower._ttk_regrowing_evil_flower = true
    pickable.remove_when_picked = false
    pickable.baseregentime = nil -- The timer keeps the delay at two full days, including spring.

    local original_onpicked = pickable.onpickedfn
    pickable.onpickedfn = function(inst, picker, loot)
        if original_onpicked ~= nil then original_onpicked(inst, picker, loot) end
        inst.AnimState:SetMultColour(0.45, 0.45, 0.45, 1)
        inst.components.timer:StartTimer(EVIL_FLOWER_REGROW_TIMER, EVIL_FLOWER_REGROW_TIME)
    end
end

local function add(plant, spawn, spacing, sounds, afterdeploy)
    plantables[#plantables + 1] = {
        plant = plant,
        spawn = spawn,
        spacing = spacing or G.DEPLOYSPACING.LESS,
        sounds = sounds,
        afterdeploy = afterdeploy,
    }
end

if GetModConfigData("mp_plantseeds") then
    add("seeds", "planted_flower", G.DEPLOYSPACING.LESS,
        {"dontstarve/wilson/pickup_plants"})
end
if GetModConfigData("mp_plantnightmarefuel") then
    add("nightmarefuel", "flower_evil", G.DEPLOYSPACING.LESS, nil,
        function(planted, deployer)
            MakeEvilFlowerRegrowable(planted)
            if deployer ~= nil and deployer.components.sanity ~= nil then
                deployer.components.sanity:DoDelta(-TUNING.SANITY_TINY)
            end
        end)

    AddPrefabPostInit("flower_evil", function(inst)
        if not G.TheWorld.ismastersim then return end
        if inst.components.timer == nil then inst:AddComponent("timer") end
        inst:ListenForEvent("timerdone", function(flower, data)
            if flower._ttk_regrowing_evil_flower and data.name == EVIL_FLOWER_REGROW_TIMER then
                flower.components.pickable:Regen()
                flower.AnimState:SetMultColour(1, 1, 1, 1)
            end
        end)

        local original_save = inst.OnSave
        inst.OnSave = function(flower, data)
            local refs = original_save ~= nil and original_save(flower, data) or nil
            if flower._ttk_regrowing_evil_flower then
                data.ttk_regrowing_evil_flower = true
            end
            return refs
        end

        local original_load = inst.OnLoad
        inst.OnLoad = function(flower, data)
            if original_load ~= nil then original_load(flower, data) end
            if data ~= nil and data.ttk_regrowing_evil_flower then
                MakeEvilFlowerRegrowable(flower)
                if not flower.components.pickable:CanBePicked() then
                    flower.AnimState:SetMultColour(0.45, 0.45, 0.45, 1)
                end
            end
        end
    end)
end
if GetModConfigData("mp_plantdurianseeds") then
    add("durian_seeds", "mandrake_planted", G.DEPLOYSPACING.LESS,
        {"dontstarve/creatures/mandrake/plant_dirt", "dontstarve/creatures/mandrake/plant"})
end
if GetModConfigData("mp_plantpomegranateseeds") then
    add("pomegranate_seeds", "berrybush", G.DEPLOYSPACING.LESS,
        {"dontstarve/creatures/mandrake/plant_dirt"},
        function(planted) planted.components.pickable:OnTransplant() end)
end
if GetModConfigData("mp_plantcutreeds") then
    add("cutreeds", "reeds", G.DEPLOYSPACING.LESS,
        {"dontstarve/wilson/pickup_reeds"},
        function(planted) planted.components.pickable:OnTransplant() end)
end
if GetModConfigData("mp_plantlightbulb") then
    add("lightbulb", function()
        local roll = math.random()
        return roll > 1 / 3 and "flower_cave"
            or roll > 0.1 and "flower_cave_double"
            or "flower_cave_triple"
    end, G.DEPLOYSPACING.LESS, {"dontstarve/wilson/pickup_reeds"},
        function(planted) planted.components.pickable:OnTransplant() end)
end
if GetModConfigData("mp_plantbeefalowool") then
    add("beefalowool", "tallbirdnest", G.DEPLOYSPACING.DEFAULT,
        {"dontstarve/creatures/tallbird/scratch_ground"},
        function(planted)
            planted.components.childspawner.timetonextspawn =
                G.GetRandomWithVariance(TUNING.TOTAL_DAY_TIME * 3, TUNING.TOTAL_DAY_TIME)
            planted.components.pickable:MakeEmpty()
        end)
end

for _, data in ipairs(plantables) do
    AddPrefabPostInit(data.plant, function(inst)
        inst:AddTag("deployedplant")
        inst.overridedeployplacername = "common/" .. data.plant .. "_placer"
        local original_can_deploy = inst._custom_candeploy_fn
        if original_can_deploy ~= nil then
            inst._custom_candeploy_fn = function(item, point, mouseover, deployer, rotation)
                if deployer ~= nil and deployer:HasTag("plantkin") then
                    return original_can_deploy(item, point, mouseover, deployer, rotation)
                end
                return G.TheWorld.Map:CanDeployPlantAtPoint(point, item)
            end
        end
        if not G.TheWorld.ismastersim then return end

        local deployable = inst.components.deployable
        if deployable == nil then
            inst:AddComponent("deployable")
            deployable = inst.components.deployable
        end
        local original_tag = deployable.restrictedtag
        local original_deploy = deployable.ondeploy
        deployable.restrictedtag = nil
        deployable:SetDeployMode(original_can_deploy ~= nil and G.DEPLOYMODE.CUSTOM or G.DEPLOYMODE.PLANT)
        deployable:SetDeploySpacing(data.spacing)
        deployable.ondeploy = function(item, point, deployer)
            if original_tag ~= nil and deployer ~= nil and deployer:HasTag(original_tag) and original_deploy ~= nil then
                return original_deploy(item, point, deployer)
            end
            local prefab = type(data.spawn) == "function" and data.spawn() or data.spawn
            local planted = SpawnPrefab(prefab)
            if planted == nil then return end
            planted.Transform:SetPosition(point.x, point.y, point.z)
            item.components.stackable:Get():Remove()
            if data.afterdeploy ~= nil then
                data.afterdeploy(planted, deployer)
            end
            if data.sounds ~= nil then
                if planted.SoundEmitter == nil then
                    planted.entity:AddSoundEmitter()
                end
                for _, sound in ipairs(data.sounds) do
                    planted.SoundEmitter:PlaySound(sound)
                end
            end
        end
    end)
end

-- Transplanted reeds start empty; the optional shovel action returns cut reeds.
if GetModConfigData("mp_plantcutreeds") or GetModConfigData("digreeds") then
    AddPrefabPostInit("reeds", function(inst)
        if not G.TheWorld.ismastersim then return end
        inst.components.pickable.ontransplantfn = function(reed)
            reed.components.pickable:MakeEmpty()
        end
        if not GetModConfigData("digreeds") then return end
        if inst.components.lootdropper == nil then inst:AddComponent("lootdropper") end
        if inst.components.workable == nil then inst:AddComponent("workable") end
        inst.components.workable:SetWorkAction(G.ACTIONS.DIG)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(function(reed)
            if reed.components.pickable:CanBePicked() then
                reed.components.lootdropper:SpawnLootPrefab("cutreeds")
            end
            reed.components.lootdropper:SpawnLootPrefab("cutreeds")
            reed:Remove()
        end)
    end)
end

-- Light flowers can be replanted and dug up after being planted from bulbs.
if GetModConfigData("mp_plantlightbulb") then
    for _, flower in ipairs({
        {name = "flower_cave", bulbs = 1},
        {name = "flower_cave_double", bulbs = 2},
        {name = "flower_cave_triple", bulbs = 3},
    }) do
        AddPrefabPostInit(flower.name, function(inst)
            if not G.TheWorld.ismastersim then return end
            inst.components.pickable.ontransplantfn = function(item)
                item.components.pickable:MakeEmpty()
            end
            if inst.components.lootdropper == nil then inst:AddComponent("lootdropper") end
            if inst.components.workable == nil then inst:AddComponent("workable") end
            inst.components.workable:SetWorkAction(G.ACTIONS.DIG)
            inst.components.workable:SetWorkLeft(1)
            inst.components.workable:SetOnFinishCallback(function(item)
                if item.components.pickable:CanBePicked() then
                    for _ = 1, flower.bulbs do
                        item.components.lootdropper:SpawnLootPrefab("lightbulb")
                    end
                end
                item.components.lootdropper:SpawnLootPrefab("foliage")
                item:Remove()
            end)
        end)
    end
end

if GetModConfigData("happyflowers") then
    AddPrefabPostInit("flower", function(inst)
        if not G.TheWorld.ismastersim then return end
        if inst.components.sanityaura == nil then inst:AddComponent("sanityaura") end
        inst.components.sanityaura.aura = TUNING.SANITYAURA_TINY
    end)
end
if GetModConfigData("happybutterflys") then
    AddPrefabPostInit("butterfly", function(inst)
        if not G.TheWorld.ismastersim then return end
        if inst.components.sanityaura == nil then inst:AddComponent("sanityaura") end
        inst.components.sanityaura.aura = TUNING.SANITYAURA_SMALL
    end)
end

if GetModConfigData("mp_asporen") then
    for _, tree in ipairs({
        {name = "mushtree_tall", chance = 0.75},
        {name = "mushtree_medium", chance = 0.5},
        {name = "mushtree_small", chance = 0.25},
    }) do
        AddPrefabPostInit(tree.name, function(inst)
            if not G.TheWorld.ismastersim then return end
            inst.components.lootdropper:AddChanceLoot("asporen", 1)
            inst.components.lootdropper:AddChanceLoot("asporen", tree.chance)
        end)
    end
end

if GetModConfigData("mp_mushroots") then
    for _, color in ipairs({"red", "blue", "green"}) do
        AddPrefabPostInit(color .. "_mushroom", function(inst)
            if not G.TheWorld.ismastersim then return end
            inst.components.pickable.ontransplantfn = function(mushroom)
                mushroom.components.pickable:MakeEmpty()
            end
            inst.components.workable:SetOnFinishCallback(function(mushroom)
                if mushroom.components.pickable:CanBePicked() then
                    mushroom.components.lootdropper:SpawnLootPrefab(color .. "_cap")
                end
                mushroom.components.lootdropper:SpawnLootPrefab(color .. "_mushroot")
                mushroom:Remove()
            end)
        end)
    end
end
