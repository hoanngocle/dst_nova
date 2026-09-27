local assets =
{
    Asset("ANIM", "anim/fire_rock.zip"),
    Asset("ATLAS", "images/inventoryimages/fire_rock.xml"),
}

local HEAT = chasni_getitemconfig("fire_rock", "HEAT") or 5
local function HeatFn(inst, observer)
    return HEAT * inst.components.stackable:StackSize()
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("fire_rock")
    inst.AnimState:SetBuild("fire_rock")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)

    inst:AddTag("heatrock")
    inst:AddTag("HASHEATER")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetSinks(true)
    inst.components.inventoryitem.imagename = "fire_rock"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/fire_rock.xml"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("heater")
    inst.components.heater.heatfn = HeatFn
    inst.components.heater.carriedheatfn = HeatFn

    return inst
end

return Prefab("fire_rock", fn, assets)
