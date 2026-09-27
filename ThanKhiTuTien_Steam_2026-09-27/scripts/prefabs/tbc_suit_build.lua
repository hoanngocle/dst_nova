local assets = {
    Asset("ANIM", "anim/hh_suit_build.zip"),
    Asset("ATLAS", "images/hh_icon/hh_suit_build.xml"),
    Asset("IMAGE", "images/hh_icon/hh_suit_build.tex"),
}

local function ReturnItems(inst)
    local owner = inst.tbc_owner
    local container = inst.components ~= nil and inst.components.container or nil
    if container == nil then return end
    for slot = 1, container:GetNumSlots() do
        local item = container:RemoveItemBySlot(slot)
        if item ~= nil then
            local inventory = owner ~= nil and owner:IsValid()
                and owner.components ~= nil and owner.components.inventory or nil
            if inventory ~= nil then
                inventory:GiveItem(item)
            else
                local x, y, z = inst.Transform:GetWorldPosition()
                item.Transform:SetPosition(x, y, z)
            end
        end
    end
    inst.tbc_owner = nil
end

local function OnHammered(inst)
    if inst.components.container ~= nil then inst.components.container:DropEverything() end
    local fx = SpawnPrefab("collapse_small")
    if fx ~= nil then
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("stone")
    end
    inst:Remove()
end

local function MakeStation()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    MakeObstaclePhysics(inst, .4)
    inst.AnimState:SetBank("hh_suit_build")
    inst.AnimState:SetBuild("hh_suit_build")
    inst.AnimState:PlayAnimation("idle", true)
    inst.MiniMapEntity:SetIcon("hh_suit_build.tex")
    inst.MiniMapEntity:SetPriority(5)
    inst:AddTag("structure")
    inst:AddTag("tbc_suit_build")
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end
    inst.tbc_station = inst
    inst:AddComponent("inspectable")
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("tbc_suit_build")
    inst.components.container.onopenfn = function(station, data)
        station.tbc_owner = data ~= nil and data.doer or nil
    end
    inst.components.container.onclosefn = ReturnItems
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    return inst
end

return Prefab("tbc_suit_build", MakeStation, assets, {"collapse_small"}),
    MakePlacer("tbc_suit_build_placer", "hh_suit_build", "hh_suit_build", "idle")
