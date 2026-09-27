--------------------------------------------------------------------------
--[[ crafterchestregistry class definition ]]
--------------------------------------------------------------------------
local MAX_CRAFTER_CHEST = 1

return Class(function(self, inst)

	assert(TheWorld.ismastersim, "crafterchestregistry should not exist on client")

	--------------------------------------------------------------------------
	--[[ Member variables ]]
	--------------------------------------------------------------------------

	--Public
	self.inst = inst

	--Private
	local _crafterchest = {}

	--------------------------------------------------------------------------
	--[[ Private member functions ]]
	--------------------------------------------------------------------------

	local function OnRemoveCrafterChest(crafterchest)
		if _crafterchest[crafterchest] then
			_crafterchest[crafterchest] = nil
			inst:RemoveEventCallback("onremove", OnRemoveCrafterChest, crafterchest)
		end
	end

	--------------------------------------------------------------------------
	--[[ Public member functions ]]
	--------------------------------------------------------------------------

	function self:Register(crafterchest)
		if crafterchest then
			_crafterchest[crafterchest] = true
			inst:ListenForEvent("onremove", OnRemoveCrafterChest, crafterchest)
		end
	end

	function self:TooMuch()
		return GetTableSize(_crafterchest) > MAX_CRAFTER_CHEST
	end

	function self:Exist()
		return GetTableSize(_crafterchest) > 0
	end

	--------------------------------------------------------------------------
	--[[ Debug ]]
	--------------------------------------------------------------------------

	function self:GetDebugString()
		return "Num: " .. tostring(GetTableSize(_crafterchest)) .. ", is_active:" .. tostring(self:IsActive())
	end

	--------------------------------------------------------------------------
	--[[ End ]]
	--------------------------------------------------------------------------
end)
