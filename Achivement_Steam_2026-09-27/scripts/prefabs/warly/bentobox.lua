local assets =
{
    Asset("ANIM", "anim/bentobox.zip"),
    Asset("ATLAS", "images/inventoryimages/bentobox_off.xml"),
    Asset("IMAGE", "images/inventoryimages/bentobox_off.tex"),
    Asset("ATLAS", "images/inventoryimages/bentobox_on.xml"),
    Asset("IMAGE", "images/inventoryimages/bentobox_on.tex"),
}

local function setsprite(inst)
    local postfix = inst.components.chasnibox and inst.components.chasnibox.boxedprefab and "_on" or "_off"
    local imagename = "bentobox" .. postfix
    local anim = "idle" .. postfix
    inst.AnimState:PlayAnimation(anim)
    if inst.components.inventoryitem then
        inst.components.inventoryitem.imagename = imagename
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. imagename ..".xml"
    end
end

local function addediblecomponent(inst)
    if inst.components.chasnibox and inst.components.chasnibox.boxedprefab then
        inst:AddTag("pre-preparedfood") -- >>>> so warly can ate it
        inst:AddComponent("edible")
        inst.components.edible.foodtype = FOODTYPE.GOODIES
        inst.components.edible.healthvalue = inst.healthvalue
        inst.components.edible.hungervalue = inst.hungervalue
        inst.components.edible.sanityvalue = inst.sanityvalue
    end
end

local function IsBoxable(item)
    return item:HasTag("preparedfood") and item.components.edible
end

local function OnBox(inst, item)
    if item.components.edible then
        inst.healthvalue = item.components.edible.healthvalue or 0
        inst.hungervalue = item.components.edible.hungervalue or 0
        inst.sanityvalue = item.components.edible.sanityvalue or 0
        addediblecomponent(inst)
    end
    setsprite(inst)
end

local function OnUnbox(inst)
    if inst.components.edible then
        inst:RemoveComponent("edible")
        inst.healthvalue = nil
        inst.hungervalue = nil
        inst.sanityvalue = nil
    end
    setsprite(inst)
end

local function OnSave(inst, data)
    data.healthvalue = inst.healthvalue or nil
    data.hungervalue = inst.hungervalue or nil
    data.sanityvalue = inst.sanityvalue or nil
end

local function OnLoad(inst, data)
    if data then
        inst.healthvalue = data.healthvalue or nil
        inst.hungervalue = data.hungervalue or nil
        inst.sanityvalue = data.sanityvalue or nil
        addediblecomponent(inst)
    end
    setsprite(inst)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("bentobox")
    inst.AnimState:SetBuild("bentobox")
    inst.AnimState:PlayAnimation("idle_off")

    MakeInventoryPhysics(inst)
    inst:AddTag("chasnibox")

    inst._boxedprefab = net_string(inst.GUID, "chasnibox.boxedprefab", "chasnibox_boxed_update")
    inst.displaynamefn = function(inst)
        local inside = inst._boxedprefab:value()
        if inside and inside ~= "" then
            local itemname = STRINGS.NAMES[string.upper(inside)]
            return itemname or inside
        end
        return STRINGS.NAMES.BOX
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetSinks(true)
    inst.components.inventoryitem.imagename = "bentobox_off"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/bentobox_off.xml"

    inst:AddComponent("chasnibox")
    inst.components.chasnibox:SetBoxablefn(IsBoxable)
    inst.components.chasnibox:SetOnBoxfn(OnBox)
    inst.components.chasnibox:SetOnUnboxfn(OnUnbox)
    inst._boxedprefab:set("")

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave

    return inst
end

return
Prefab("bentobox", fn, assets)