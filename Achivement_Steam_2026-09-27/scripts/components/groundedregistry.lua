--------------------------------------------------------------------------
-- groundedregistry
--------------------------------------------------------------------------

return Class(function(self, inst)

	assert(TheWorld.ismastersim, "groundedregistry should not exist on client")

	--------------------------------------------------------------------------
	-- Member variables
	--------------------------------------------------------------------------

	self.inst = inst

	-- [prefab] = { [inst] = true }
	local _grounded = {}
	local CLIENT_STATUE = {
		chesspiece_carrat_stone        = true,
		chesspiece_beefalo_marble      = true,
		chesspiece_manrabbit_stone     = true,
		chesspiece_manrabbit_moonglass = true,
		chesspiece_yots_marble         = true,
		chesspiece_formal_moonglass    = true,
	}

	--------------------------------------------------------------------------
	-- Private
	--------------------------------------------------------------------------

	local function OnRemoveGrounded(statue)
		local prefab = statue._chasniprefabname or statue.prefab

		if prefab ~= nil and _grounded[prefab] ~= nil then
			_grounded[prefab][statue] = nil

			if next(_grounded[prefab]) == nil then
				_grounded[prefab] = nil
				if CLIENT_STATUE[prefab] then
					for _, v in ipairs(AllPlayers) do
						SendModRPCToClient(GetClientModRPC("groundedregistry", "send_exist_result"), v, prefab, false)
					end
				end
			end
		end

		inst:RemoveEventCallback("onremove", OnRemoveGrounded, statue)
	end

	--------------------------------------------------------------------------
	-- Public
	--------------------------------------------------------------------------

	function self:Register(statue)
		if statue == nil then
			return
		end

		local prefab = statue._chasniprefabname or statue.prefab

		if _grounded[prefab] == nil then
			_grounded[prefab] = {}
			if CLIENT_STATUE[prefab] then
				for _, v in ipairs(AllPlayers) do
					SendModRPCToClient(GetClientModRPC("groundedregistry", "send_exist_result"), v, prefab, true)
				end
			end
		end

		_grounded[prefab][statue] = true

		inst:ListenForEvent("onremove", OnRemoveGrounded, statue)
	end

	function self:GetCount(prefab)
		if _grounded[prefab] == nil then
			return 0
		end

		return GetTableSize(_grounded[prefab])
	end

	function self:Exist(prefab)
		return self:GetCount(prefab) > 0
	end

	--------------------------------------------------------------------------
	-- Debug
	--------------------------------------------------------------------------

	function self:GetDebugString()
		local str = ""

		for prefab, list in pairs(_grounded) do
			str = str .. prefab .. ": " .. tostring(GetTableSize(list)) .. "\n"
		end

		return str
	end

	--------------------------------------------------------------------------
	-- Local Fn
	--------------------------------------------------------------------------

	local function OnPlayerJoined(src, player)
		for prefab in pairs(CLIENT_STATUE) do
			local isexist = _grounded[prefab] ~= nil and GetTableSize(_grounded[prefab]) > 0 or false
			SendModRPCToClient(GetClientModRPC("groundedregistry", "send_exist_result"), player, prefab, isexist)
		end
	end
	inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
end)