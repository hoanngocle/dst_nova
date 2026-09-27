require "prefabutil"

local ASPOREN_GROWTIME = {base=TUNING.TOTAL_DAY_TIME*4, random=TUNING.TOTAL_DAY_TIME}

local function plant(inst, growtime)
    local sapling = SpawnPrefab(inst._spawn_prefab or "mushtree_sapling")
    sapling:StartGrowing()
    sapling.Transform:SetPosition(inst.Transform:GetWorldPosition())
    sapling.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")
    inst:Remove()
end

local function ondeploy(inst, pt, deployer)
    inst = inst.components.stackable:Get()
    inst.Physics:Teleport(pt:Get())
    local timeToGrow = GetRandomWithVariance(ASPOREN_GROWTIME.base, ASPOREN_GROWTIME.random)
    plant(inst, timeToGrow)
end

local function OnLoad(inst, data)
    if data ~= nil and data.growtime ~= nil then
        plant(inst, data.growtime)
    end
end

local cones = {}

local function addcone(name, spawn_prefab, bank, build, anim)
    local assets =
    {
        Asset("ATLAS", "images/inventoryimages/asporen.xml"),
        Asset("IMAGE", "images/inventoryimages/asporen.tex"),
        Asset("ANIM", "anim/"..build..".zip"),
    }
    if bank ~= build then
        table.insert(assets, Asset("ANIM", "anim/"..bank..".zip"))
    end

    local prefabs =
    {
        spawn_prefab or "mushtree_sapling",
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("cattoy")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst._spawn_prefab = spawn_prefab

        inst:AddComponent("tradable")

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inspectable")
        -- inst.components.inspectable.getstatus = describe

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/asporen.xml"

        MakeHauntableLaunchAndIgnite(inst)

        inst:AddComponent("deployable")
        inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
        inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)
        inst.components.deployable.ondeploy = ondeploy

        -- inst.displaynamefn = displaynamefn

        -- This is left in for "save file upgrading", June 3 2015. We can remove it after some time.
        inst.OnLoad = OnLoad

        return inst
    end

    table.insert(cones, Prefab("common/inventory/"..name, fn, assets, prefabs))
    table.insert(cones, MakePlacer("common/"..name.."_placer", bank, build, anim))
end

STRINGS.NAMES.ASPOREN = "Asporen"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ASPOREN = "It's a acorn covered in fungus, gross." 

addcone("asporen", "mushtree_sapling", "pinecone", "asporen", "idle_planted")

return unpack(cones)

--[[
local function describe(inst)
    if inst.growtime then
        return "PLANTED"
    end
end

local function displaynamefn(inst)
    if inst.growtime then
        return STRINGS.NAMES.ASPOREN_SAPLING
    end
    return STRINGS.NAMES.ASPOREN
end

local function OnSave(inst, data)
    if inst.growtime then
        data.growtime = inst.growtime - GetTime()
    end
end

local function OnLoad(inst, data)
    if data and data.growtime then
        plant(inst, data.growtime)
    end
end

]]
