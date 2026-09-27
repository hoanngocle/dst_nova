local function MakePlans(name, targets, constuctionname)
    local assets =
    {
        Asset("ANIM", "anim/pondstruction_plans.zip"),
        Asset("ATLAS", "images/inventoryimages/pondstruction_plans.xml"),
    }
    local prefabs =
    {
        name,
    }

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst)

        inst.AnimState:SetBank("pondstruction_plans")
        inst.AnimState:SetBuild("pondstruction_plans")
        inst.AnimState:PlayAnimation("idle")

        for i, v in ipairs(targets) do
            inst:AddTag(v.."_plans")
        end
        inst:AddTag("donotautopick")

        inst.constructionname = constuctionname

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst.components.inspectable.nameoverride = "construction_plans"

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = "pondstruction_plans"
        inst.components.inventoryitem.atlasname = "images/inventoryimages/pondstruction_plans.xml"

        inst:AddComponent("constructionplans")
        for i, v in ipairs(targets) do
            inst.components.constructionplans:AddTargetPrefab(v, name)
        end

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        MakeHauntableLaunch(inst)

        return inst
    end

    return Prefab(name.."_plans", fn, assets, prefabs)
end

-- UPGRADED_POND
local function pondstructionOnConstructed(plans, constructedstructure)
    constructedstructure.originalpond = plans.originalpond
end
local function pondstructionOnSave(inst, data)
    data.originalpond = inst.originalpond
end
local function pondstructionOnLoad(inst, data)
    if data ~= nil then
        inst.originalpond = data.originalpond
    end
end
--

local function MakeConstruction(name, target, callbacks)
    local assets =
    {
        Asset("ANIM", "anim/pondstruction.zip"),
    }
    local function OnConstructed(inst, doer)
        local concluded = true
        for _, v in ipairs(CONSTRUCTION_PLANS[inst.prefab] or {}) do
            if inst.components.constructionsite:GetMaterialCount(v.type) < v.amount then
                concluded = false
                break
            end
        end

        if concluded then
            local constructedstructure = ReplacePrefab(inst, target)
            if callbacks and callbacks.constructed and constructedstructure then
                callbacks.constructed(inst, constructedstructure)
            end
        end
    end

    local function onhammered_common(inst, worker)
        inst.components.lootdropper:DropLoot()
        local fx = SpawnPrefab("collapse_big")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("wood")
    end

    local function onhammered_construction(inst, worker)
        onhammered_common(inst, worker)
        if inst.components.constructionsite ~= nil then
            inst.components.constructionsite:DropAllMaterials()
        end
        if inst.originalpond then
            ReplacePrefab(inst, inst.originalpond)
        else
            inst:Remove()
        end
    end

    local function onhit_construction(inst, worker)
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", true)
        inst.components.constructionsite:ForceStopConstruction()
    end

    local function onconstruction_built(inst)
        PreventCharacterCollisionsWithPlacedObjects(inst)
        inst.AnimState:PlayAnimation("place")
        inst.AnimState:PushAnimation("idle", true)
    end

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("pondstruction")
        inst.AnimState:SetBuild("pondstruction")
        inst.AnimState:PlayAnimation("idle", true)

        inst:SetPhysicsRadiusOverride(1.5)
        MakeObstaclePhysics(inst, inst.physicsradiusoverride)

        inst:AddTag("constructionsite")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        MakeHauntableWork(inst)
        local constructionsite = inst:AddComponent("constructionsite")
        constructionsite:SetConstructionPrefab("construction_container")
        constructionsite:SetOnConstructedFn(OnConstructed)

        inst:AddComponent("inspectable")
        inst:AddComponent("lootdropper")

        local workable = inst:AddComponent("workable")
        workable:SetWorkAction(ACTIONS.HAMMER)
        workable:SetWorkLeft(4)
        workable:SetOnFinishCallback(onhammered_construction)
        workable:SetOnWorkCallback(onhit_construction)

        inst:ListenForEvent("onbuilt", onconstruction_built)

        local emptypond = chasni_spawnprefab("upgraded_pond_empty")
        emptypond.entity:SetParent(inst.entity)

        if callbacks then
            inst.OnSave = callbacks.save
            inst.OnLoad = callbacks.load
        end

        return inst
    end

    return Prefab(name, fn, assets)
end

return
MakePlans("pondstruction", { "pond", "pond_mos", "pond_cave" }, "upgraded_pond"),
MakeConstruction("pondstruction", "upgraded_pond",{constructed = pondstructionOnConstructed, save = pondstructionOnSave, load = pondstructionOnLoad})
