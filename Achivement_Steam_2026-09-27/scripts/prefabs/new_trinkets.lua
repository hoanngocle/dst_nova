local function MakeTrinket(id, trinketgold, variant, notfloating)
    local assets =
    {
        Asset("ANIM", "anim/chasni_trinkets.zip"),
        Asset("ATLAS", "images/inventoryimages/chasni_trinkets.xml"),
    }

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("chasni_trinkets")
        inst.AnimState:SetBuild("chasni_trinkets")
        inst.AnimState:PlayAnimation("trinket_" .. id, false)
        MakeInventoryPhysics(inst)
        local swap_data = {bank = "chasni_trinkets", anim = "trinket_water_" .. id}
        MakeInventoryFloatable(inst, nil, nil, nil, nil, nil, swap_data)

        inst:AddTag("molebait")
        inst:AddTag("cattoy")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = "chasnitrinkets_" .. id
        inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_trinkets.xml"

        inst:AddComponent("bait")
        inst:AddComponent("tradable")

        inst.components.tradable.goldvalue = trinketgold
        if not notfloating then
            inst:ListenForEvent("floater_startfloating", function(_inst) _inst.AnimState:PlayAnimation("trinket_water_" .. id, false) end)
            inst:ListenForEvent("floater_stopfloating", function(_inst) _inst.AnimState:PlayAnimation("trinket_" .. id, false) end)
        end

        return inst
    end
    local name = "trinket_chasni_" .. (id + 2) .. (variant or "")
    return Prefab(name, fn, assets)
end

return
MakeTrinket(1, 1), -- 3. Sea Worther (SUNKEN_BOAT_TRINKET_4)
MakeTrinket(2, 3), -- 4.  One True Earring (KYNO_EARRING, EARRING)                                  
MakeTrinket(3, 4), -- 5. Queen Malfalfa (TRINKET_GIFTSHOP_1, TRINKET_HAM_1)                         
--MakeTrinket(4, 4), -- Queen Malfalfa 2
MakeTrinket(5, 4), -- 7. Post Card of the Royal Palace (TRINKET_GIFTSHOP_3, TRINKET_HAM_3)
MakeTrinket(6, 5), -- 8. Can of Silly String (TRINKET_GIFTSHOP_4)
MakeTrinket(7, 6), -- 9. Orange Soda (TRINKET_IA_13, TRINKET_13, KYNO_SODACAN, TRINKET_SW_13)
MakeTrinket(8, 8), -- 10. Voodoo Doll (TRINKET_IA_14, TRINKET_SW_14)
MakeTrinket(9, 6), -- 11. Ukulele (TRINKET_IA_15, TRINKET_SW_15)
MakeTrinket(10, 7), -- 12. License Plate (TRINKET_IA_16, TRINKET_SW_16)
MakeTrinket(11, 4), -- 13. Old Boot (SUNKEN_BOAT_TRINKET_5, TRINKET_IA_17, TRINKET_SW_17)
MakeTrinket(12, 7), -- 14. Ancient Vase (TRINKET_IA_18, TRINKET_SW_18)
MakeTrinket(13, 6), -- 15. Brain Cloud Pill (TRINKET_IA_19, TRINKET_SW_19)
MakeTrinket(14, 2), -- 16. Sextant (SUNKEN_BOAT_TRINKET_1, TRINKET_IA_20, TRINKET_SW_20)
MakeTrinket(15, 2), -- 17. Toy Boat (SUNKEN_BOAT_TRINKET_2, TRINKET_IA_21, TRINKET_SW_21)
MakeTrinket(16, 4, "a"), -- 18. Wine Bottle Candle (TRINKET_IA_22, TRINKET_SW_22)
MakeTrinket(16, 7, "b"), -- 18. Soaked Candle (SUNKEN_BOAT_TRINKET_3)
MakeTrinket(17, 10), -- 19. Broken AAC Device (TRINKET_IA_23, TRINKET_SW_23)
-- NEW
MakeTrinket(18, 25), -- Floppy Disc
MakeTrinket(19, 10), -- Dev Mug
--MakeTrinket(20, 12), -- Electrical Cable
MakeTrinket(21, 30, "", true), -- #1 Battlesongs Fan
MakeTrinket(22, 12, "", true) -- Framed Dead Spritter
