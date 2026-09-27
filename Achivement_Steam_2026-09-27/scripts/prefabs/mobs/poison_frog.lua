local assets =
{
	Asset("ANIM", "anim/frog_poison.zip"),	
	Asset("ANIM", "anim/frog_poison_build.zip"),
	Asset("ATLAS", "images/inventoryimages/poison_frog.xml"),
}

local prefabs =
{
	"frog",
}

local function OnAttackOther(inst, data)
	if data.target then
		if data.target.components.playerpoisonable then
			data.target.components.playerpoisonable:Poison()
		end
	end
end

local function fn()
	local inst = Prefabs["frog"].fn()
	inst.AnimState:SetBuild("frog_poison_build")

	if not TheWorld.ismastersim then
		return inst
	end

	inst:ListenForEvent("onhitother", OnAttackOther)
	if inst.components.lootdropper then
		inst.components.lootdropper:AddChanceLoot("chasni_poison_gland", 0.2)
	end

	if inst.components.inventoryitem then
		inst.components.inventoryitem.imagename = "poison_frog"
		inst.components.inventoryitem.atlasname = "images/inventoryimages/poison_frog.xml"
	end

	return inst
end
return Prefab("chasni_frog_poison", fn, assets, prefabs)
