local function MakePreparedFood(data)
    local foodname = data.basename or data.name
    local foodassets = {
        Asset("ANIM", "anim/chasni_warlyfood.zip"),
        Asset("ANIM", "anim/chasni_warlyfood_symbol.zip"),
    }
    table.insert(foodassets, Asset("ATLAS", "images/inventoryimages/"..foodname..".xml"))
    table.insert(foodassets, Asset("IMAGE", "images/inventoryimages/"..foodname..".tex"))
    local spicename = data.spice and string.lower(data.spice) or nil
    if spicename then
        table.insert(foodassets, Asset("ANIM", "anim/spices.zip"))
        table.insert(foodassets, Asset("ANIM", "anim/plate_food.zip"))
        table.insert(foodassets, Asset("INV_IMAGE", spicename.."_over"))
    end

    local foodprefabs = { "spoiled_food" }
    if data.prefabs then
        for i, v in ipairs(data.prefabs) do
            if not table.contains(foodprefabs, v) then
                table.insert(foodprefabs, v)
            end
        end
    end

    local function DisplayNameFn(inst)
        return subfmt(STRINGS.NAMES[data.spice.."_FOOD"], {food = STRINGS.NAMES[string.upper(data.basename)]})
    end

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        if spicename then
            inst.AnimState:SetBuild("plate_food")
            inst.AnimState:SetBank("plate_food")
            inst.AnimState:PlayAnimation("idle")
            inst.AnimState:OverrideSymbol("swap_garnish", "spices", spicename)

            inst:AddTag("spicedfood")

            inst.drawnameoverride = STRINGS.NAMES[string.upper(data.basename)]
            inst.inv_image_bg = { atlas = "images/inventoryimages/"..foodname..".xml", image = foodname..".tex" }

            inst.AnimState:OverrideSymbol("swap_food", "chasni_warlyfood_symbol", data.basename or data.name)
        else
            inst.AnimState:SetBank("chasni_warlyfood")
            inst.AnimState:SetBuild("chasni_warlyfood")
            inst.AnimState:PlayAnimation(data.name, false)
        end

        inst:AddTag("preparedfood")
        if data.tags then
            for i,v in pairs(data.tags) do
                inst:AddTag(v)
            end
        end

        if data.basename then
            inst:SetPrefabNameOverride(data.basename)
            if data.spice then
                inst.displaynamefn = DisplayNameFn
            end
        end

        if data.floater then
            MakeInventoryFloatable(inst, data.floater[1], data.floater[2], data.floater[3])
        else
            MakeInventoryFloatable(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("edible")
        inst.components.edible.foodtype = data.foodtype or FOODTYPE.GENERIC
        inst.components.edible.hungervalue = data.hunger or 0
        inst.components.edible.healthvalue = data.health or 0
        inst.components.edible.sanityvalue = data.sanity or 0
        inst.components.edible.temperaturedelta = data.temperature or 0
        inst.components.edible.temperatureduration = data.temperatureduration or 0
        inst.components.edible.nochill = data.nochill or nil
        inst.components.edible.spice = data.spice
        inst.components.edible:SetOnEatenFn(data.oneatenfn)

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = data.maxstacksize or TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("bait")
        inst:AddComponent("tradable")
        inst:AddComponent("inspectable")

        if data.perishtime and data.perishtime > 0 then
            inst:AddComponent("perishable")
            inst.components.perishable:SetPerishTime(data.perishtime)
            inst.components.perishable:StartPerishing()
            inst.components.perishable.onperishreplacement = "spoiled_food"
        end

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = foodname
        if spicename then
            inst.components.inventoryitem:ChangeImageName(spicename.."_over")
        elseif data.basename then
            inst.components.inventoryitem:ChangeImageName(data.basename)
        else
            inst.components.inventoryitem.atlasname = "images/inventoryimages/"..foodname..".xml"
        end

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        MakeHauntableLaunchAndPerish(inst)

        return inst
    end

    return Prefab(data.name, fn, foodassets, foodprefabs)
end

local new_foods = require("prefabs/warly/warly_fooddef")
local spiced_new_foods = require("prefabs/warly/warly_spicedfooddef")
local prefs = {}
for k, v in pairs(new_foods) do
    table.insert(prefs, MakePreparedFood(v))
end
--
for k, v in pairs(spiced_new_foods) do
    table.insert(prefs, MakePreparedFood(v))
end

return unpack(prefs)