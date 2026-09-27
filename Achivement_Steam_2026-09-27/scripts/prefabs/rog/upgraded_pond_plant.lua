local assets =
{
    Asset("ANIM", "anim/pondflower_autumn.zip"),
    Asset("ANIM", "anim/pondflower_winter.zip"),
}

local function fn(bank)
    return function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.Transform:SetScale(0.8, 0.8, 0.8)

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(bank)
        inst.AnimState:PlayAnimation("idle_full", true)

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        MakeMediumBurnable(inst)
        MakeSmallPropagator(inst)
        MakeHauntableIgnite(inst)

        return inst
    end
end

return
Prefab("pondflower_autumn", fn("pondflower_autumn"), assets),
Prefab("pondflower_winter", fn("pondflower_winter"), assets)
