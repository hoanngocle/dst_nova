local assets =
{
    Asset("ANIM", "anim/upgraded_farmplot.zip"),
    Asset("ATLAS", "images/inventoryimages/upgraded_farmplot.xml"),
}

local prefabs =
{
    "plant_normal",
    "collapse_small",
}

local function onhammered(inst, worker)
    if inst.components.grower then
        inst.components.grower:Reset()
    end
    if inst.components.lootdropper then
        inst.components.lootdropper:DropLoot()
    end
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function OnBuilt(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/farm_basic_craft")
    local item = SpawnPrefab(inst.components.grower.autoplantprefab or "seeds")
    local x, y, z = inst.Transform:GetWorldPosition()
    local player = FindClosestPlayer(x, y, z)
    inst.components.grower:PlantItem(item, player)
end

local function plot(level)
    return function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst:AddTag("structure")

        inst.AnimState:SetBank("upgraded_farmplot")
        inst.AnimState:SetBuild("upgraded_farmplot")
        inst.AnimState:PlayAnimation("full")
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)

        inst.level = level
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst.components.inspectable.nameoverride = "FARMPLOT"

        inst:AddComponent("grower")
        inst.components.grower.level = level
        inst.components.grower.onplantfn = function() inst.SoundEmitter:PlaySound("dontstarve/wilson/plant_seeds") end
        inst.components.grower.croppoints = { Vector3(0, 0, 0) }
        inst.components.grower.growrate = 0.5
        inst.components.grower.max_cycles_left = 20
        inst.components.grower.cycles_left = inst.components.grower.max_cycles_left
        inst.components.grower.autoplant = true
        inst.components.grower.autoplantprefab = "seeds"

        inst:AddComponent("savedrotation")
        inst:AddComponent("lootdropper")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(2)
        inst.components.workable:SetOnFinishCallback(onhammered)

        inst:ListenForEvent("onbuilt", OnBuilt)

        return inst
    end
end

return
Prefab("upgraded_farmplot", plot(2), assets, prefabs),
MakePlacer("upgraded_farmplot_placer", "upgraded_farmplot", "upgraded_farmplot", "full")
