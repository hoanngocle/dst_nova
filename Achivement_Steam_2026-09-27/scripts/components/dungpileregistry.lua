--------------------------------------------------------------------------
--[[ dungpileregistry class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

	assert(TheWorld.ismastersim, "dungpileregistry should not exist on client")

	--------------------------------------------------------------------------
	--[[ Member variables ]]
	--------------------------------------------------------------------------

	--Public
	self.inst = inst

	--Private
	local _dungpiles = {}

	--------------------------------------------------------------------------
	--[[ Private member functions ]]
	--------------------------------------------------------------------------

	local function OnRemoveDungPile(dungpile)
		if _dungpiles[dungpile] then
			_dungpiles[dungpile] = nil
			inst:RemoveEventCallback("onremove", OnRemoveDungPile, dungpile)
		end
	end

	--------------------------------------------------------------------------
	--[[ Public member functions ]]
	--------------------------------------------------------------------------

	function self:Register(dungpile)
		if dungpile then
			_dungpiles[dungpile] = true
			inst:ListenForEvent("onremove", OnRemoveDungPile, dungpile)
		end
	end

	function self:IsActive()
		return GetTableSize(_dungpiles) > 0
	end

	function self:Count()
		return GetTableSize(_dungpiles)
	end

	function self:GetNearestDungpiles(x, y, z)
		local rangesq = math.huge
		local nearestdungpile = nil
		for i, v in pairs(_dungpiles) do
			local distsq = i:GetDistanceSqToPoint(x, y, z)
			if distsq < rangesq then
				rangesq = distsq
				nearestdungpile = i
			end
		end
		return nearestdungpile
	end

	--------------------------------------------------------------------------
	--[[ Debug ]]
	--------------------------------------------------------------------------

	function self:GetDebugString()
		return "Num: " .. tostring(GetTableSize(_dungpiles)) .. ", is_active:" .. tostring(self:IsActive())
	end

	--------------------------------------------------------------------------
	--[[ End ]]
	--------------------------------------------------------------------------
end)
