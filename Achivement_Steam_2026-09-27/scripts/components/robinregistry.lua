--------------------------------------------------------------------------
--[[ robinregistry class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

	assert(TheWorld.ismastersim, "robinregistry should not exist on client")

	--------------------------------------------------------------------------
	--[[ Member variables ]]
	--------------------------------------------------------------------------

	--Public
	self.inst = inst
	local _robins = {}

	--------------------------------------------------------------------------
	--[[ Private member functions ]]
	--------------------------------------------------------------------------

	local function OnRemoveRobins(robin)
		if _robins[robin] then
			_robins[robin] = nil
			inst:RemoveEventCallback("onremove", OnRemoveRobins, robin)
		end
	end

	--------------------------------------------------------------------------
	--[[ Public member functions ]]
	--------------------------------------------------------------------------

	function self:Register(robin)
		if robin then
			_robins[robin] = true
			inst:ListenForEvent("onremove", OnRemoveRobins, robin)
		end
	end

	function self:GetRobins()
		return _robins
	end

	function self:GetRobin(id)
		for robin, _ in pairs(_robins) do
			if robin._id == id then
				return robin
			end
		end
		return nil
	end

	--------------------------------------------------------------------------
	--[[ Debug ]]
	--------------------------------------------------------------------------

	function self:GetDebugString()
		return "Num: " .. tostring(GetTableSize(_robins))
	end

	--------------------------------------------------------------------------
	--[[ End ]]
	--------------------------------------------------------------------------
end)
