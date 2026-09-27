local new_foods = require("prefabs/warly/warly_fooddef")
local spices = require("spicedfoods")
GenerateSpicedFoods(new_foods)
local spiced_new_foods = {}
for k, data in pairs(spices) do
	for name, v in pairs(new_foods) do
		if data.basename == name then
			spiced_new_foods[k] = data
		end
	end
end

return spiced_new_foods