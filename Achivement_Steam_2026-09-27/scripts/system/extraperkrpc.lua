require "functions/helperfunctions"

if not chasni_getperkexcludeconfig("blueprintextractor") then
    AddModRPCHandler("Active_Perk", "blueprintextractor", function(inst)
        if inst.components.inventory then
            local gift = "papyrus"
            local papers = inst.components.inventory:FindItems(function(item) return item.components.erasablepaper end)
            for i, v in ipairs(papers) do
                if v.components.teacher then
                    local recname = v.components.teacher.recipe
                    local recipe = GetValidRecipe(recname)
                    if recipe then
                        gift = recipe.ingredients[math.random(#recipe.ingredients)].type
                    end
                end
                v:Remove()
                chasni_giveItem(inst, gift, 1)
            end
        end
    end)
end

if not chasni_getperkexcludeconfig("itemmerger") then
    AddModRPCHandler("Active_Perk", "itemmerger", function(inst)
        if inst.components.inventory then
            local inv = inst.components.inventory
            local finiteuses_item_map = {}
            local armor_item_map = {}
            local fueled_item_map = {}

            for _, item in pairs(inv.itemslots) do
                if item then
                    if item.components.finiteuses then
                        local prefab = item.prefab
                        local uses = item.components.finiteuses:GetUses()

                        if not finiteuses_item_map[prefab] then
                            finiteuses_item_map[prefab] = {}
                        end

                        table.insert(finiteuses_item_map[prefab], { item = item, uses = uses })
                    elseif item.components.armor then
                        local prefab = item.prefab
                        local uses = item.components.armor.condition

                        if not armor_item_map[prefab] then
                            armor_item_map[prefab] = {}
                        end

                        table.insert(armor_item_map[prefab], { item = item, uses = uses })
                    elseif item.components.fueled then
                        local prefab = item.prefab
                        local uses = item.components.fueled.currentfuel

                        if not fueled_item_map[prefab] then
                            fueled_item_map[prefab] = {}
                        end

                        table.insert(fueled_item_map[prefab], { item = item, uses = uses })
                    end
                end
            end

            for _, items in pairs(finiteuses_item_map) do
                table.sort(items, function(a, b) return a.uses > b.uses end)
                while #items > 1 do
                    local first = items[1]
                    local second = items[2]

                    local max_uses = first.item.components.finiteuses.total
                    local total_uses = first.uses + second.uses

                    if total_uses <= max_uses then
                        first.item.components.finiteuses:SetUses(total_uses)
                        items[1].uses = total_uses
                        inv:RemoveItem(second.item, true):Remove()
                        table.remove(items, 2)
                    else
                        first.item.components.finiteuses:SetUses(max_uses)
                        second.item.components.finiteuses:SetUses(total_uses - max_uses)
                        items[2].uses = total_uses - max_uses
                        table.remove(items, 1)
                    end
                end
            end

            for _, items in pairs(armor_item_map) do
                table.sort(items, function(a, b) return a.uses > b.uses end)
                while #items > 1 do
                    local first = items[1]
                    local second = items[2]

                    local max_uses = first.item.components.armor.maxcondition
                    local total_uses = first.uses + second.uses

                    if total_uses <= max_uses then
                        first.item.components.armor:SetCondition(total_uses)
                        items[1].uses = total_uses
                        inv:RemoveItem(second.item, true):Remove()
                        table.remove(items, 2)
                    else
                        first.item.components.armor:SetCondition(max_uses)
                        second.item.components.armor:SetCondition(total_uses - max_uses)
                        items[2].uses = total_uses - max_uses
                        table.remove(items, 1)
                    end
                end
            end

            for _, items in pairs(fueled_item_map) do
                table.sort(items, function(a, b) return a.uses > b.uses end)
                while #items > 1 do
                    local first = items[1]
                    local second = items[2]

                    local max_uses = first.item.components.fueled.maxfuel
                    local total_uses = first.uses + second.uses

                    if total_uses <= max_uses then
                        first.item.components.fueled:DoDelta(second.uses)
                        items[1].uses = total_uses
                        inv:RemoveItem(second.item, true):Remove()
                        table.remove(items, 2)
                    else
                        local delta = max_uses - first.uses
                        first.item.components.fueled:DoDelta(delta)
                        second.item.components.fueled:DoDelta(-delta)
                        items[2].uses = total_uses - max_uses
                        table.remove(items, 1)
                    end
                end
            end
        end
    end)
end

if not chasni_getperkexcludeconfig("itemcleaner") then
    AddModRPCHandler("Active_Perk", "itemcleaner", function(inst)
        local ents = {}
        for k, v in pairs(Ents) do
            if v.components.inventoryitem and v.components.inventoryitem.owner == nil
                    and not v:HasTag("irreplaceable")
                    and not v.components.locomotor
                    and not v:IsInLimbo() then
                table.insert(ents, v)
            end
        end

        local index = 1
        local batch_size = 20

        local function ProcessNextBatch()
            for i = 1, batch_size do
                local entity = ents[index]

                if entity and entity.Remove and entity.components.inventoryitem and entity.components.inventoryitem.owner == nil
                        and not entity:HasTag("irreplaceable")
                        and not entity.components.locomotor
                        and not entity:IsInLimbo() then
                    entity:DoTaskInTime(0, function(e)
                        local x, y, z = e.Transform:GetWorldPosition()
                        chasni_spawnprefab("circle_puff_fx", x, y, z)
                        e:Remove()
                    end)
                end
                index = index + 1
            end
            if index <= #ents then
                inst:DoTaskInTime(0, ProcessNextBatch)
            end
        end

        ProcessNextBatch()
    end)
end

if not chasni_getperkexcludeconfig("sharemap") then
    AddModRPCHandler("Active_Perk", "sharemap", function(inst)
        for _, player in ipairs(AllPlayers) do
            if inst ~= player then
                local map = SpawnPrefab("mapscroll")
                if map and map.components.maprecorder then
                    map.components.maprecorder:RecordMap(inst)
                    map.components.maprecorder:TeachMap(player)
                end
            end
        end
        return nil
    end)
end
