local function MakeItem(name, bank, build, anim, data)
    local assets =
    {
        Asset("ANIM", "anim/"..bank..".zip"),
        Asset("ATLAS", "images/inventoryimages/"..bank..".xml"),
    }

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(bank)
        inst.AnimState:PlayAnimation(anim, false)
        if data and data.doublesized then
            inst.Transform:SetScale(2,2,2)
        end
        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "small")

        if data and data.trinketgold then
            inst:AddTag("molebait")
            inst:AddTag("cattoy")
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = build
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. bank .. ".xml"

        if data and data.trinketgold then
            inst:AddComponent("bait")

            inst:AddComponent("tradable")
            inst.components.tradable.goldvalue = data.trinketgold
        end

        if data and data.food then
            inst:AddComponent("edible")
            inst.components.edible.foodtype = data.food.foodtype or FOODTYPE.GENERIC
            inst.components.edible.healthvalue = data.food.health or 0
            inst.components.edible.hungervalue = data.food.hunger or 0
            inst.components.edible.sanityvalue = data.food.sanity or 0
            if data.food.oneatenfn then
                inst.components.edible:SetOnEatenFn(data.food.oneatenfn)
            end
        end
        if data and data.perishtime then
            inst:AddComponent("perishable")
            inst.components.perishable:SetPerishTime(data.perishtime)
            inst.components.perishable:StartPerishing()
            inst.components.perishable.onperishreplacement = "spoiled_food"
        end

        return inst
    end

    return Prefab(name, fn, assets)
end
local function roe_oneatenfn(inst, eater)
    if eater.components.levelsystem then
        eater.components.levelsystem:petxpDoLevelUp(eater)
    end
end
AddIngredientValues({"chasni_fish_roe"}, {fish=.5})

local function caviar_oneatenfn(inst, eater)
    if eater.components.levelsystem then
        eater.components.levelsystem:petxpDoLevelUp(eater)
    end
    local pet = eater.components.petleash and eater.components.petleash:GetChasniCritter()
    if pet and pet.evolve then
        pet:evolve()
    end
end
AddIngredientValues({"chasni_caviar"}, {fish=.5})

return
MakeItem("chasni_memorycard_blue", "memorycard", "blue", "rain"),
MakeItem("chasni_memorycard_brown", "memorycard", "brown", "storage"),
MakeItem("chasni_memorycard_green", "memorycard", "green", "strong"),
MakeItem("chasni_memorycard_red", "memorycard", "red", "cook"),
MakeItem("chasni_memorycard_pink", "memorycard", "pink", "revive"),
MakeItem("chasni_memorycard_yellow", "memorycard", "yellow", "boom"),
MakeItem("chasni_pearl", "chasni_pearl", "chasni_pearl", "idle"),
MakeItem("chasni_fish_roe", "chasni_fish_roe", "chasni_fish_roe", "idle", {food = {health = -30, hunger = 0, sanity = -10, foodtype = FOODTYPE.MEAT, oneatenfn = roe_oneatenfn}, perishtime = TUNING.PERISH_SLOW}),
MakeItem("chasni_caviar", "chasni_caviar", "chasni_caviar", "idle", {food = {health = 0, hunger = 0, sanity = 10, foodtype = FOODTYPE.MEAT, oneatenfn = caviar_oneatenfn}, perishtime = TUNING.PERISH_PRESERVED}),
MakeItem("trinket_chasni_2", "trinket_chasni_2", "trinket_chasni_2", "idle", { trinketgold = 10 })
