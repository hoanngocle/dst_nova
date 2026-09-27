local assets =
{
	Asset("ANIM", "anim/mosquito_poison.zip"),
	Asset("ATLAS", "images/inventoryimages/poison_mosquito.xml"),
}

local prefabs =
{
	"mosquito",
}

local function OnAttackOther(inst, data)
	if data.target then
		if data.target.components.playerpoisonable then
			data.target.components.playerpoisonable:Poison()
		end
	end
end

local function fn()
	local inst = Prefabs["mosquito"].fn()
	inst.AnimState:SetBuild("mosquito_poison")

	if not TheWorld.ismastersim then
		return inst
	end

	inst:ListenForEvent("onhitother", OnAttackOther)
	if inst.components.lootdropper then
		inst.components.lootdropper:AddChanceLoot("chasni_poison_gland", 0.2)
	end

	if inst.components.inventoryitem then
		inst.components.inventoryitem.imagename = "poison_mosquito"
		inst.components.inventoryitem.atlasname = "images/inventoryimages/poison_mosquito.xml"
	end

	return inst
end
return Prefab("chasni_mosquito_poison", fn, assets, prefabs)
