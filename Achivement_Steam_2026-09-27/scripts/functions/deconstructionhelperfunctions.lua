local DESTSOUNDS =
{
	{   --magic
		soundpath = "dontstarve/common/destroy_magic",
		ing = { "nightmarefuel", "livinglog" },
	},
	{   --cloth
		soundpath = "dontstarve/common/destroy_clothing",
		ing = { "silk", "beefalowool" },
	},
	{   --tool
		soundpath = "dontstarve/common/destroy_tool",
		ing = { "twigs" },
	},
	{   --gem
		soundpath = "dontstarve/common/gem_shatter",
		ing = { "redgem", "bluegem", "greengem", "purplegem", "yellowgem", "orangegem" },
	},
	{   --wood
		soundpath = "dontstarve/common/destroy_wood",
		ing = { "log", "boards" },
	},
	{   --stone
		soundpath = "dontstarve/common/destroy_stone",
		ing = { "rocks", "cutstone" },
	},
	{   --straw
		soundpath = "dontstarve/common/destroy_straw",
		ing = { "cutgrass", "cutreeds" },
	},
}
local DESTSOUNDSMAP = {}
for i, v in ipairs(DESTSOUNDS) do
	for i2, v2 in ipairs(v.ing) do
		DESTSOUNDSMAP[v2] = v.soundpath
	end
end
DESTSOUNDS = nil

local function SpawnLootPrefab(inst, lootprefab, caster)
	if lootprefab == nil then
		return
	end

	local loot = SpawnPrefab(lootprefab)
	if loot == nil then
		return
	end
	if caster.components.inventory then
		local pos = inst:GetPosition()
		caster.components.inventory:GiveItem(loot, nil, pos)
	end

	loot:PushEvent("on_loot_dropped", {dropper = inst})

	return loot
end

function chasni_DoDisasemble(item, disasembler)
	local recipe = AllRecipes[item.prefab]
	if recipe == nil or FunctionOrValue(recipe.no_deconstruction, item) then
		return
	end

	local ingredient_percent =
	((
			(item.components.finiteuses and item.components.finiteuses:GetPercent()) or
					(item.components.fueled and item.components.inventoryitem and item.components.fueled:GetPercent()) or
					(item.components.armor and item.components.inventoryitem and item.components.armor:GetPercent()) or
					1
	) / recipe.numtogive) / 2

	local stacksize = (item.components.stackable and item.components.stackable:StackSize()) or 1
	for i, v in ipairs(recipe.ingredients) do
		if disasembler and DESTSOUNDSMAP[v.type] then
			disasembler.SoundEmitter:PlaySound(DESTSOUNDSMAP[v.type])
		end
		if string.sub(v.type, -3) ~= "gem" or string.sub(v.type, -11, -4) == "precious" then
			local amt = v.amount == 0 and 0 or math.max(1, math.ceil(v.amount * ingredient_percent))
			local total_amt = amt * stacksize
			for n = 1, total_amt do
				SpawnLootPrefab(item, v.type, disasembler)
			end
		end
	end

	if item.components.inventory then
		item.components.inventory:DropEverything()
	end

	if item.components.container then
		item.components.container:DropEverything()
	end

	if item.components.spawner and item.components.spawner:IsOccupied() then
		item.components.spawner:ReleaseChild()
	end

	if item.components.occupiable and item.components.occupiable:IsOccupied() then
		local item = item.components.occupiable:Harvest()
		if item then
			item.Transform:SetPosition(item.Transform:GetWorldPosition())
			item.components.inventoryitem:OnDropped()
		end
	end

	if item.components.trap then
		item.components.trap:Harvest()
	end

	if item.components.dryer then
		item.components.dryer:DropItem()
	end

	if item.components.harvestable then
		item.components.harvestable:Harvest()
	end

	if item.components.stewer then
		item.components.stewer:Harvest()
	end

	item:PushEvent("ondeconstructstructure", disasembler)

	if item.components.stackable then
		item.components.stackable:Get(stacksize):Remove()
	else
		item:Remove()
	end
end