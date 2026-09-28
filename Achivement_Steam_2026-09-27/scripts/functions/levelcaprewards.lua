local Rewards = { XP_PER_STONE = 100 }

local function Deliver(inst, item)
    local inventory = inst.components and inst.components.inventory
    if inventory and type(inventory.GiveItem) == "function" then
        local position = inst.GetPosition and inst:GetPosition() or nil
        -- Keep a rejected item detached so we can place it at the player's feet.
        local old_ignorefull = inventory.ignorefull
        inventory.ignorefull = true
        local ok, accepted = pcall(inventory.GiveItem, inventory, item, nil, position)
        inventory.ignorefull = old_ignorefull
        if ok and accepted == true then return true end
    end

    if item.Transform and inst.Transform and type(inst.Transform.GetWorldPosition) == "function" then
        item.Transform:SetPosition(inst.Transform:GetWorldPosition())
        return true
    end
    return false
end

function Rewards.GiveLowerSpiritStones(inst, count)
    local delivered = 0
    while delivered < count do
        local item = SpawnPrefab("xd_lingshi1")
        if item == nil then break end

        local stackable = item.components and item.components.stackable
        local maximum = 1
        if stackable and type(stackable.SetStackSize) == "function" then
            local size = type(stackable.GetMaxSize) == "function" and stackable:GetMaxSize() or stackable.maxsize
            maximum = math.max(1, math.floor(tonumber(size) or 1))
        end
        local amount = math.min(count - delivered, maximum)
        if stackable and type(stackable.SetStackSize) == "function" then stackable:SetStackSize(amount) end

        if not Deliver(inst, item) then
            if type(item.Remove) == "function" then item:Remove() end
            break
        end
        delivered = delivered + amount
    end
    return delivered
end

return Rewards
