local Runtime = {}

local supported_events = {
	oneat = "oneat",
	killed = "killed",
	builditem = "builditem",
	buildstructure = "buildstructure",
	picksomething = "picksomething",
	finishedwork = "finishedwork",
	itemget = "gotnewitem",
	rowing = "rowing",
	tilling = "tilling",
	deployitem = "deployitem",
}

local function ActionName(action)
    if type(action) == "string" then return action end
    if type(action) == "table" then return action.id or action.str end
    return nil
end

local function CraftedPrefab(data)
    if type(data) ~= "table" then return nil end
    if type(data.recipe) == "table" and type(data.recipe.product) == "string" then
        return data.recipe.product
    end
    return type(data.item) == "table" and data.item.prefab or nil
end

function Runtime.EventName(quest)
	if type(quest) ~= "table" then return nil end
	return supported_events[quest.event]
end

function Runtime.Match(quest, inst, data)
	local event = type(quest) == "table" and quest.event or nil
    local params = type(quest) == "table" and quest.params or nil
	if Runtime.EventName(quest) == nil or type(params) ~= "table" then return false end
	if event == "rowing" or event == "tilling" then return true end
	if type(data) ~= "table" then return false end

    if event == "oneat" then
        return type(data.food) == "table" and data.food.prefab == params.prefab
    elseif event == "killed" then
        return type(data.victim) == "table" and data.victim.prefab == params.prefab
    elseif event == "builditem" or event == "buildstructure" then
        return CraftedPrefab(data) == params.prefab
    elseif event == "picksomething" then
        return type(data.object) == "table" and data.object.prefab == params.prefab
    elseif event == "finishedwork" then
        local action_ok = params.action == nil or ActionName(data.action) == params.action
        local prefab_ok = params.prefab == nil or (type(data.target) == "table" and data.target.prefab == params.prefab)
        return action_ok and prefab_ok
    elseif event == "itemget" then
        return type(data.item) == "table" and data.item.prefab == params.prefab
    elseif event == "deployitem" then
        local prefab = data.prefab or (type(data.item) == "table" and data.item.prefab or nil)
        return prefab == params.prefab
    end
    return false
end

function Runtime.Amount(quest, inst, data)
    local amount = type(data) == "table" and tonumber(data.amount) or nil
    if amount == nil and type(data) == "table" and type(data.item) == "table" then
        local stackable = data.item.components and data.item.components.stackable or nil
        if stackable and type(stackable.StackSize) == "function" then
            amount = tonumber(stackable:StackSize())
        end
    end
    if amount == nil or amount < 1 then return 1 end
    return math.max(1, math.floor(amount))
end

return Runtime
