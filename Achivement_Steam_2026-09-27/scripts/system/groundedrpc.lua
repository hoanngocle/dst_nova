require "functions/helperfunctions"

AddClientModRPCHandler("groundedregistry", "send_exist_result", function(prefab, exists)
	if ThePlayer then
		ThePlayer._grounded_cache = ThePlayer._grounded_cache or {}
		ThePlayer._grounded_cache[prefab] = exists
	end
end)
