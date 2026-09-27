local function ReturnAll(inst)
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
            elseif owner ~= nil and owner:IsValid() then
                local x, y, z = owner.Transform:GetWorldPosition()
                item.Transform:SetPosition(x, y, z)
            else
                local x, y, z = inst.Transform:GetWorldPosition()
                item.Transform:SetPosition(x, y, z)
            end
        end
    end
end

local function MakeBox()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(box)
            box.replica.container:WidgetSetup("tbc_equipment_box")
        end
        return inst
    end
    inst.persists = false
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("tbc_equipment_box")
    inst.components.container.onclosefn = ReturnAll
    inst.OnRemoveEntity = ReturnAll
    return inst
end

return Prefab("tbc_equipment_box", MakeBox)
