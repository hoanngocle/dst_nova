local assets = {Asset('ANIM', 'anim/xd_ui_6x6.zip')}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst:AddTag('CLASSIFIED')
    inst:AddTag('NOCLICK')
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(box)
            box.replica.container:WidgetSetup('nyx_gem_storage')
        end
        return inst
    end
    inst.persists = false
    inst:AddComponent('container')
    local container = inst.components.container
    container:WidgetSetup('nyx_gem_storage')
    local open = container.Open
    container.Open = function(self, doer)
        if doer == nil or doer ~= inst.nyx_owner or doer:HasTag('playerghost') then return end
        return open(self, doer)
    end
    inst.OnRemoveEntity = function(box)
        box.components.container:Close()
        -- Contents have already been serialized by the owning character.
        -- Remove transient item entities without dropping or duplicating them.
        for _, item in pairs(box.components.container.slots) do item:Remove() end
    end
    return inst
end

return Prefab('nyx_gem_storage', fn, assets)
