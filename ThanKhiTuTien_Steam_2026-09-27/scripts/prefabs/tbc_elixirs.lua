local Defs=require('tbc_elixir/defs')
local prefabs={}
for _,key in ipairs(Defs.ORDER) do
    local row=Defs.BY_KEY[key]
    local function fn()
        local inst=CreateEntity()
        inst.entity:AddTransform(); inst.entity:AddAnimState(); inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank('hh_dungeon_potions')
        inst.AnimState:SetBuild('hh_dungeon_potions')
        inst.AnimState:PlayAnimation(row.anim)
        inst:AddTag('preparedfood'); inst:AddTag('potion')
        MakeInventoryFloatable(inst,'small',.15,.55)
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end
        inst:AddComponent('inspectable')
        inst.components.inspectable.descriptionfn=function(_,viewer)
            local count=viewer and viewer.GetTbcElixirCount and viewer:GetTbcElixirCount(key) or 0
            return ('Đã luyện hóa: %d/10. %s'):format(count,row.description)
        end
        inst:AddComponent('inventoryitem')
        inst.components.inventoryitem.atlasname=row.atlas
        inst.components.inventoryitem.imagename=row.icon
        inst:AddComponent('stackable')
        inst.components.stackable.maxsize=TUNING.STACK_SIZE_SMALLITEM
        inst:AddComponent('edible')
        inst.components.edible.foodtype=FOODTYPE.GOODIES
        inst.components.edible.secondaryfoodtype=FOODTYPE.MEAT
        inst.components.edible.healthvalue=0
        inst.components.edible.hungervalue=0
        inst.components.edible.sanityvalue=0
        inst.components.edible:SetOnEatenFn(function(_,eater)
            local progress=eater.components.tbc_elixir_progress
            if progress then progress:Consume(key) end
        end)
        MakeHauntableLaunch(inst)
        return inst
    end
    prefabs[#prefabs+1]=Prefab(row.prefab,fn,{
        Asset('ANIM','anim/hh_dungeon_potions.zip'),
        Asset('ATLAS',row.atlas),Asset('IMAGE','images/potions/'..row.icon..'.tex'),
    })
end
return unpack(prefabs)
