local function MakeItem(name, bank, build, data)
    local assets =
    {
        Asset("ANIM", "anim/"..build..".zip"),
        Asset("ATLAS", "images/inventoryimages/"..build..".xml"),
    }

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("idle", data and data.animationloop or false)
        if data and data.doublesized then
            inst.Transform:SetScale(2,2,2)
        end
        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "small")

        if data and data.trinketgold then
            inst:AddTag("molebait")
            inst:AddTag("cattoy")
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = build
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. build .. ".xml"

        if data and data.fuelvalue and data.fueltyoe then
            inst:AddComponent("fuel")
            inst.components.fuel.fuelvalue = data.fuelvalue
            inst.components.fuel.fueltype = data.fueltyoe
        end
        if data and data.trinketgold then
            inst:AddComponent("bait")

            inst:AddComponent("tradable")
            inst.components.tradable.goldvalue = data.trinketgold
            --inst.components.tradable.tradefor = TBD
        end
        if data and data.luckvalue then
            inst:AddComponent("luckitem")
            inst.components.luckitem:SetLuck(data.luckvalue)
        end
        return inst
    end

    return Prefab(name, fn, assets)
end

return
MakeItem("chasni_ancient_remnant", "ancient_remnant", "ancient_remnant", { luckvalue = -0.1 }),
MakeItem("chasni_exort_feather", "exort_feather", "exort_feather"),
MakeItem("chasni_quas_feather", "quas_feather", "quas_feather"),
MakeItem("chasni_grub_jaw", "grub_jaw", "grub_jaw"),
MakeItem("chasni_grub_skull", "grub_skull", "grub_skull"),
MakeItem("chasni_snapdragon_petal", "snapdragon_petal", "snapdragon_petal"),
MakeItem("chasni_hippo_skin", "hippo_skin", "hippo_skin"),
MakeItem("chasni_hippo_antler", "hippo_antler", "hippo_antler"),
MakeItem("chasni_wargfant_tooth", "wargfant_tooth", "wargfant_tooth"),
MakeItem("chasni_wargfant_fur", "wargfant_fur", "wargfant_fur"),
MakeItem("chasni_seal_fur", "seal_fur", "seal_fur", { luckvalue = 0.1}),
MakeItem("chasni_slipstor_fur", "slipstor_fur", "slipstor_fur"),
MakeItem("chasni_crocodog_skin", "crocodog_skin", "crocodog_skin"),
MakeItem("chasni_pangolden_scale", "pangolden_scale", "pangolden_scale"),
MakeItem("chasni_palmtreeguard_log", "palmtreeguard_log", "palmtreeguard_log", { fuelvalue = TUNING.TOTAL_DAY_TIME, fueltype = FUELTYPE.BURNABLE }),
MakeItem("chasni_hulk_metalbit", "hulk_metalbit", "hulk_metalbit", { animationloop = true, doublesized = true }),
MakeItem("chasni_crab_fireorgan", "crab_fireorgan", "crab_fireorgan"),
MakeItem("chasni_crab_iceorgan", "crab_iceorgan", "crab_iceorgan"),
MakeItem("chasni_crab_waterorgan", "crab_waterorgan", "crab_waterorgan"),
MakeItem("chasni_crab_electricorgan", "crab_electricorgan", "crab_electricorgan"),
MakeItem("chasni_crab_lunarorgan", "crab_lunarorgan", "crab_lunarorgan"),
MakeItem("chasni_crab_shadoworgan", "crab_shadoworgan", "crab_shadoworgan"),
MakeItem("chasni_plasmablob_blob", "plasmablob_blob", "plasmablob_blob", { fuelvalue = TUNING.TOTAL_DAY_TIME, fueltype = FUELTYPE.CAVE }),
--
MakeItem("trinket_chasni_1", "trinket_chasni_1", "trinket_chasni_1", { animationloop = false, doublesized = false, trinketgold = 25 })
