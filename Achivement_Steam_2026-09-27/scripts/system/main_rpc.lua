-- Crafted critters also use this RPC, even when expertwinona1 is excluded.
AddClientModRPCHandler("CrafterChest", "RefreshCrafting", function(player)
	player = player or ThePlayer
	if player then
		ThePlayer:PushEvent("refreshcrafting")
	end
end)

