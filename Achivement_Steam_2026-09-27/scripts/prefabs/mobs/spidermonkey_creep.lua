local function InitCreep(inst, structure)
	inst.structure = structure.prefab
	inst:ListenForEvent("onremove", function() inst:Remove() end, structure)
	inst:ListenForEvent("onburnt", function() inst:Remove() end, structure)
	structure:AddTag("spidermonkey_creeped")
end

local function onSave(inst, data)
	data.structure = inst.structure or nil
end

local function onLoad(inst, data)
	inst:DoTaskInTime(0.1, function()
		if data and data.structure then
			local x, _, z = inst.Transform:GetWorldPosition()
			local ents = TheSim:FindEntities(x, 0, z, 1, {"structure"}, {"spidermonkey_creeped"})
			local structure = nil
			for i, v in ipairs(ents) do
				if v:IsValid() and v.prefab == data.structure then
					structure = v
					break
				end
			end
			if structure then
				InitCreep(inst, structure)
				return
			end
		end
	inst:Remove()
	end)
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddGroundCreepEntity()
	inst.entity:AddNetwork()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.GroundCreepEntity:SetRadius(4)
	inst.structure = nil
	inst.InitCreep = InitCreep
	inst.OnSave = onSave
	inst.OnLoad = onLoad

	return inst
end

return Prefab("spidermonkey_creep", fn)