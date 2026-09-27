require "functions/helperfunctions"

local SPEED_MUL = chasni_getitemconfig("book_voker", "WEX") or 0.04
local function updatespeedmult(inst, book)
	local w = 0 + (book._qwei[1] == 2 and 1 or 0) + (book._qwei[2] == 2 and 1 or 0) + (book._qwei[3] == 2 and 1 or 0)
	if book.components.equippable then
		book.components.equippable.walkspeedmult = 1 + (w * w * SPEED_MUL)
	end
end

local function updateballs(inst, c1, c2, c3, id)
	if inst and inst.components.inventory and inst.components.inventory:EquipHasTag("book_voker") then
		local book = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		if book and book._qwe and #book._qwe > 0 then
			book._qwei[book._qweid] = id
			book._qwe[book._qweid].AnimState:SetMultColour(c1, c2, c3, 1)
			book._qwe[book._qweid].Light:SetColour(c1, c2, c3)
			book._qweid = book._qweid + 1
			book._qweid = book._qweid > 3 and 1 or book._qweid
			updatespeedmult(inst, book)
		end
	end
end

AddModRPCHandler("InvokerBook", "E", function(inst)
	updateballs(inst, 1, 0.7, 0,3)
end)

AddModRPCHandler("InvokerBook", "Q", function(inst)
	updateballs(inst, 0.6, 0.9, 1, 1)
end)

AddModRPCHandler("InvokerBook", "W", function(inst)
	updateballs(inst, 1, 0.6, 1,2)
end)
