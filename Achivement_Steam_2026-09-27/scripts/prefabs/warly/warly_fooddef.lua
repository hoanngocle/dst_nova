-- jellybeanval -> white = 0 -> 0.5, red = 2 -> 3, green = 3 -> 5, yellow = 5 -> 7
AddIngredientValues({"jellybean_yellow"}, {chasni_jellybean = 5})
AddIngredientValues({"jellybean_green"}, {chasni_jellybean = 3})
AddIngredientValues({"jellybean_red"}, {chasni_jellybean = 2})
AddIngredientValues({"jellybean_white"}, {chasni_jellybean = 0.5})

local new_foods = {
	jellybean_yellow =
	{
		name = "jellybean_yellow",
		overridebuild = "chasni_warlyfood_symbol",
		cookbook_atlas = "images/inventoryimages/jellybean_yellow.xml",
		cookbook_tex = "jellybean_yellow.tex",
		test = function(cooker, names, tags)
			return tags.chasni_jellybean and tags.chasni_jellybean >= 7 and names.yellowgem and names.yellowgem >= 4
		end,
		priority = 100,
		weight = 1,
		foodtype = FOODTYPE.GOODIES,
		cooktime = 0.5,
		maxstacksize = TUNING.STACK_SIZE_SMALLITEM,
		oneat_desc = "Nhận điểm Thành Tựu",
		floater = {"med", nil, 0.65},
		health = 0,
		hunger = 0,
		sanity = 0,
		oneatenfn = function(inst, eater)
			if _G.NOAWARDS ~= true and eater.components.allachivcoin then
				SpawnPrefab("seffc").entity:SetParent(eater.entity)
				eater.components.allachivcoin:coinDoDelta(1)
				if _G.NOTIFICATION then
					TheNet:Announce(eater:GetDisplayName().." nhận 1 điểm Thành Tựu từ Kẹo Đậu Vàng")
				end
			end
		end,
	},
	jellybean_green =
	{
		name = "jellybean_green",
		overridebuild = "chasni_warlyfood_symbol",
		cookbook_atlas = "images/inventoryimages/jellybean_green.xml",
		cookbook_tex = "jellybean_green.tex",
		test = function(cooker, names, tags)
			return tags.chasni_jellybean and tags.chasni_jellybean >= 5 and names.greengem and names.greengem >= 3
		end,
		priority = 100,
		weight = 1,
		foodtype = FOODTYPE.GOODIES,
		cooktime = 0.5,
		maxstacksize = TUNING.STACK_SIZE_SMALLITEM,
		oneat_desc = "Nhận kinh nghiệm",
		floater = {"med", nil, 0.65},
		health = 0,
		hunger = 0,
		sanity = 0,
		oneatenfn = function(inst, eater)
			if eater.components.levelsystem then
				eater.components.levelsystem:xpDoLevelUp(eater)
			end
		end,
	},
	jellybean_red =
	{
		name = "jellybean_red",
		overridebuild = "chasni_warlyfood_symbol",
		cookbook_atlas = "images/inventoryimages/jellybean_red.xml",
		cookbook_tex = "jellybean_red.tex",
		test = function(cooker, names, tags)
			return tags.chasni_jellybean and tags.chasni_jellybean >= 3 and names.redgem and names.redgem >= 2
		end,
		priority = 100,
		weight = 1,
		foodtype = FOODTYPE.GOODIES,
		cooktime = 0.5,
		maxstacksize = TUNING.STACK_SIZE_SMALLITEM,
		oneat_desc = "Đánh cược Sao Thành Tựu",
		floater = {"med", nil, 0.65},
		health = 0,
		hunger = 0,
		sanity = 0,
		oneatenfn = function(inst, eater)
			if _G.NOAWARDS ~= true and eater.components.allachivcoin then
				local coinamount = eater.components.allachivcoin.coinamount
				if math.random() < 0.5 then
					SpawnPrefab("seffc").entity:SetParent(eater.entity)
					local maxcoinget = chasni_getitemconfig("jellybean_red", "CAP") or 50
					local coinget = coinamount
					if maxcoinget > 0 then
						coinget = math.min(coinamount, maxcoinget)
					end
					eater.components.allachivcoin:coinDoDelta(coinget)
					if _G.NOTIFICATION then
						TheNet:Announce(eater:GetDisplayName().." nhận "..coinget.." Sao Thành Tựu từ Kẹo Đậu Đỏ")
					end
				else
					eater.components.allachivcoin:coinDoDelta(-coinamount)
					if _G.NOTIFICATION then
						TheNet:Announce(eater:GetDisplayName().." mất "..coinamount.." Sao Thành Tựu vì Kẹo Đậu Đỏ")
					end
				end
			end
		end,
	},
	jellybean_white =
	{
		name = "jellybean_white",
		overridebuild = "chasni_warlyfood_symbol",
		cookbook_atlas = "images/inventoryimages/jellybean_white.xml",
		cookbook_tex = "jellybean_white.tex",
		test = function(cooker, names, tags) return names.royal_jelly and names.royal_jelly >= 8 end,
		priority = 100,
		weight = 1,
		foodtype = FOODTYPE.GOODIES,
		cooktime = 0.5,
		maxstacksize = TUNING.STACK_SIZE_SMALLITEM,
		oneat_desc = "Đặt lại cấp độ và Thành Tựu miễn phí",
		floater = {"med", nil, 0.65},
		health = 0,
		hunger = 0,
		sanity = 0,
		oneatenfn = function(inst, eater)
			if eater.components.levelsystem then
				eater.components.levelsystem:removeattributepoints(eater, true)
			end
			if _G.NOAWARDS ~= true and eater.components.allachivcoin then
				eater.components.allachivcoin:removecoin(eater, true)
			end
			eater:AddTag("chasni_forcerefreshui")
		end,
	},
	chasni_mooncake =
	{
		name = "chasni_mooncake",
		overridebuild = "chasni_warlyfood_symbol",
		cookbook_atlas = "images/inventoryimages/chasni_mooncake.xml",
		cookbook_tex = "chasni_mooncake.tex",
		test = function(cooker, names, tags) return (names.moonglass or names.moonglass_charged or names.purebrilliance) and names.honey and tags.egg and tags.dairy end,
		priority = 110,
		weight = 1,
		foodtype = FOODTYPE.GOODIES,
		cooktime = 5,
		maxstacksize = TUNING.STACK_SIZE_SMALLITEM,
		oneat_desc = "Nhận hiệu ứng khiên tinh thần Mặt Trăng",
		floater = {"med", nil, 0.65},
		health = 3,
		hunger = 10,
		sanity = 999,
		perishtime = TUNING.PERISH_SLOW,
		prefabs = { "chasni_mooncakebuff" },
		oneatenfn = function(inst, eater)
			if eater:HasTag("player") then
				eater.components.debuffable:AddDebuff("chasni_mooncakebuff", "chasni_mooncakebuff")
			end
		end,
	},
	chasni_balut =
	{
		name = "chasni_balut",
		overridebuild = "chasni_warlyfood_symbol",
		cookbook_atlas = "images/inventoryimages/chasni_balut.xml",
		cookbook_tex = "chasni_balut.tex",
		test = function(cooker, names, tags) return (names.horrorfuel or names.nightmarefuel) and names.tallbirdegg end,
		priority = 110,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		cooktime = 5,
		maxstacksize = TUNING.STACK_SIZE_SMALLITEM,
		oneat_desc = "Nhận hiệu ứng tăng sát thương chiều không gian bóng tối",
		floater = {"med", nil, 0.65},
		health = 30,
		hunger = 2,
		sanity = -999,
		perishtime = TUNING.PERISH_FASTISH,
		prefabs = { "chasni_balutbuff" },
		oneatenfn = function(inst, eater)
			if eater:HasTag("player") then
				eater.components.debuffable:AddDebuff("chasni_balutbuff", "chasni_balutbuff")
			end
		end,
	},
	chasni_popcorn =
	{
		name = "chasni_popcorn",
		overridebuild = "chasni_warlyfood_symbol",
		cookbook_atlas = "images/inventoryimages/chasni_popcorn.xml",
		cookbook_tex = "chasni_popcorn.tex",
		test = function(cooker, names, tags) return names.corn and names.corn >= 3 and (names.butter or tags.sweetener) and not tags.meat end,
		priority = 110,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		cooktime = 1.5,
		maxstacksize = TUNING.STACK_SIZE_TINYITEM,
		stacksize = 10,
		floater = {"med", nil, 0.65},
		health = 3,
		hunger = 3,
		sanity = 5,
		perishtime = TUNING.PERISH_SUPERSLOW,
	},
	chasni_brigadeiro =
	{
		name = "chasni_brigadeiro",
		overridebuild = "chasni_warlyfood_symbol",
		cookbook_atlas = "images/inventoryimages/chasni_brigadeiro.xml",
		cookbook_tex = "chasni_brigadeiro.tex",
		test = function(cooker, names, tags) return names.butter and tags.sweetener and tags.sweetener >= 3 end,
		priority = 110,
		weight = 1,
		foodtype = FOODTYPE.GOODIES,
		cooktime = 1.5,
		maxstacksize = TUNING.STACK_SIZE_SMALLITEM,
		oneat_desc = "Nhận hiệu ứng triệu hồi bướm",
		floater = {"med", nil, 0.65},
		health = -8,
		hunger = 3,
		sanity = 62.5,
		perishtime = TUNING.PERISH_PRESERVED,
		prefabs = { "chasni_brigadeirobuff" },
		oneatenfn = function(inst, eater)
			if eater:HasTag("player") then
				eater.components.debuffable:AddDebuff("chasni_brigadeirobuff", "chasni_brigadeirobuff")
			end
		end,
	},
	chasni_tumpeng =
	{
		name = "chasni_tumpeng",
		overridebuild = "chasni_warlyfood_symbol",
		cookbook_atlas = "images/inventoryimages/chasni_tumpeng.xml",
		cookbook_tex = "chasni_tumpeng.tex",
		test = function(cooker, names, tags) return tags.meat and tags.meat >= 1.5 and tags.veggie and tags.veggie >= 1.5 and tags.veggie == tags.meat and (names.pepper or names.pepper_cooked) and tags.egg end,
		priority = 110,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		cooktime = 3,
		maxstacksize = TUNING.STACK_SIZE_LARGEITEM,
		oneat_desc = "Chia sẻ độ no và trao điểm Thành Tựu",
		floater = {"med", nil, 0.65},
		health = 10,
		hunger = 0,
		sanity = 3,
		perishtime = TUNING.PERISH_SUPERFAST,
		prefabs = { "seffc" },
		oneatenfn = function(inst, eater)
			local pos = Vector3(eater.Transform:GetWorldPosition())
			local ents = FindPlayersInRange(pos.x,pos.y,pos.z, 15)
			local hunger = 30 + (270 / math.max(#ents, 1))
			for k,v in pairs(ents) do
				if v.components.hunger then
					v.components.hunger:DoDelta(hunger)
				end
				if v._feelaccomplished then
					if _G.NOAWARDS ~= true and v.components.allachivcoin then
						SpawnPrefab("seffc").entity:SetParent(v.entity)
						v.components.allachivcoin:coinDoDelta(5)
						if _G.NOTIFICATION then
							TheNet:Announce(eater:GetDisplayName().." nhận 5 Sao Thành Tựu từ Tumpeng")
						end
					end
					v._feelaccomplished = nil
				end
			end
		end,
	},
	chasni_kyivcake =
	{
		name = "chasni_kyivcake",
		overridebuild = "chasni_warlyfood_symbol",
		cookbook_atlas = "images/inventoryimages/chasni_kyivcake.xml",
		cookbook_tex = "chasni_kyivcake.tex",
		test = function(cooker, names, tags) return tags.dairy and tags.egg and tags.sweetener and (names.acorn or names.acorn_cooked) end,
		priority = 110,
		weight = 1,
		foodtype = FOODTYPE.GOODIES,
		cooktime = 2.5,
		maxstacksize = TUNING.STACK_SIZE_SMALLITEM,
		oneat_desc = "Nhận hiệu ứng tăng độ bền áo giáp",
		floater = {"med", nil, 0.65},
		health = -5,
		hunger = 62.5,
		sanity = 33,
		perishtime = TUNING.PERISH_MED,
		prefabs = { "chasni_kyivcakebuff" },
		oneatenfn = function(inst, eater)
			if eater:HasTag("player") then
				eater.components.debuffable:AddDebuff("chasni_kyivcakebuff", "chasni_kyivcakebuff")
			end
		end,
	},
	chasni_empanadas =
	{
		name = "chasni_empanadas",
		overridebuild = "chasni_warlyfood_symbol",
		cookbook_atlas = "images/inventoryimages/chasni_empanadas.xml",
		cookbook_tex = "chasni_empanadas.tex",
		test = function(cooker, names, tags) return tags.veggie and tags.egg and tags.meat end,
		priority = 90,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		cooktime = 2.5,
		maxstacksize = TUNING.STACK_SIZE_SMALLITEM,
		oneat_desc = "Nhận hiệu ứng khiến kẻ địch không thể chọn bạn làm mục tiêu và tăng hiệu suất làm việc",
		floater = {"med", nil, 0.65},
		health = 3,
		hunger = 40,
		sanity = 10,
		perishtime = TUNING.PERISH_SLOW,
		prefabs = { "chasni_empanadasbuff" },
		oneatenfn = function(inst, eater)
			if eater:HasTag("player") then
				eater.components.debuffable:AddDebuff("chasni_empanadasbuff", "chasni_empanadasbuff")
			end
		end,
	},
	chasni_kimchi =
	{
		name = "chasni_kimchi",
		overridebuild = "chasni_warlyfood_symbol",
		cookbook_atlas = "images/inventoryimages/chasni_kimchi.xml",
		cookbook_tex = "chasni_kimchi.tex",
		test = function(cooker, names, tags) return tags.veggie and tags.veggie >= 3 and (names.pepper or names.pepper_cooked) and not tags.meat end,
		priority = 90,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		cooktime = 2.5,
		maxstacksize = TUNING.STACK_SIZE_SMALLITEM,
		oneat_desc = "Nhận hiệu ứng tăng né tránh",
		floater = {"med", nil, 0.65},
		health = 8,
		hunger = 3,
		sanity = 1,
		perishtime = TUNING.PERISH_FAST,
		prefabs = { "chasni_kimchibuff" },
		oneatenfn = function(inst, eater)
			if eater:HasTag("player") and inst:HasTag("spoiled")then
				eater.components.debuffable:AddDebuff("chasni_kimchibuff", "chasni_kimchibuff")
			end
		end,
	},
	chasni_anzac =
	{
		name = "chasni_anzac",
		overridebuild = "chasni_warlyfood_symbol",
		cookbook_atlas = "images/inventoryimages/chasni_anzac.xml",
		cookbook_tex = "chasni_anzac.tex",
		test = function(cooker, names, tags) return names.pumpkincookie and names.goatmilk and not tags.meat end,
		priority = 90,
		weight = 1,
		foodtype = FOODTYPE.GOODIES,
		cooktime = 1,
		maxstacksize = TUNING.STACK_SIZE_SMALLITEM,
		oneat_desc = "Nhận hiệu ứng ngăn quái vật chủ động tấn công bạn",
		floater = {"med", nil, 0.65},
		health = 10,
		hunger = 10,
		sanity = 10,
		perishtime = TUNING.PERISH_SLOW,
		prefabs = { "chasni_anzacbuff" },
		oneatenfn = function(inst, eater)
			if eater:HasTag("player") then
				eater.components.debuffable:AddDebuff("chasni_anzacbuff", "chasni_anzacbuff")
			end
		end,
	},
	chasni_mopane =
	{
		name = "chasni_mopane",
		overridebuild = "chasni_warlyfood_symbol",
		cookbook_atlas = "images/inventoryimages/chasni_mopane.xml",
		cookbook_tex = "chasni_mopane.tex",
		test = function(cooker, names, tags) return names.onion and names.lavae_cocoon and (names.pepper or names.pepper_cooked) end,
		priority = 110,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		cooktime = 1.5,
		maxstacksize = TUNING.STACK_SIZE_SMALLITEM,
		oneat_desc = "Nhận hiệu ứng sức mạnh ban phước",
		floater = {"med", nil, 0.65},
		health = 15,
		hunger = 1,
		sanity = -10,
		perishtime = TUNING.PERISH_FAST,
		prefabs = { "chasni_mopanebuff" },
		oneatenfn = function(inst, eater)
			if eater:HasTag("player") then
				eater.components.debuffable:AddDebuff("chasni_mopanebuff", "chasni_mopanebuff")
			end
		end,
	},
}

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

return new_foods, spiced_new_foods