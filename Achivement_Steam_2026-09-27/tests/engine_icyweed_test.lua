-- Disposable dedicated QA world only. Loaded from the server console, not modmain.
local ids = {'xd_lingshi1','xd_lingshi2','xd_lc_hsc_seed','xd_lc_qfx_seed','xd_lc_cyh_seed','xd_lc_lmg_seed',
    'hh_essence','ttk_huyen_tinh_ha_pham','ttk_huyen_tinh_trung_pham','hh_effect_tally','hh_remove_stone',
    'ac_refreshstone','ad_cleanstone','goldnugget','saltrock','moonrocknugget','moonglass','thulecite','gears',
    'dreadstone','wagpunk_bits','lunarplant_husk','purebrilliance','horrorfuel','voidcloth'}
local function Save(inst)
    local data={};inst.OnSave(inst,data);return data
end
local function Signature(data)
    local parts={}
    for _, row in ipairs(data.icyweed_loot.rewards) do parts[#parts+1]=row.prefab..':'..row.amount end
    return table.concat(parts,'|')
end
local function New(rewards)
    local inst=assert(SpawnPrefab('chasni_icyweed'))
    local portal=c_find('multiplayer_portal')
    if portal then inst.Transform:SetPosition(portal.Transform:GetWorldPosition()) end
    if rewards then inst.OnLoad(inst,{icyweed_loot={version=1,rewards=rewards}}) end
    return inst
end
local function Run()
    if ICYWEED_QA_RELOAD then
        local found
        for _, inst in pairs(Ents) do
            if inst.prefab=='chasni_icyweed' then
                local data=Save(inst)
                if Signature(data)=='xd_lingshi1:4|xd_lingshi2:1|goldnugget:2' then found=inst;break end
            end
        end
        assert(found,'saved weed rewards changed across engine restart')
        print('ICYWEED_RESTART_OK',Signature(Save(found)))
        found:Remove()
        print('ICYWEED_QA_PASS',ICYWEED_QA_MODE,'reload')
        return
    end
    for _, id in ipairs(ids) do
        local item=Prefabs[id] and SpawnPrefab(id)
        local stack=item and item.components.stackable
        print('ICYWEED_AUDIT',id,item and item:GetDisplayName() or 'MISSING',stack and stack.maxsize or 'NONSTACK')
        if item then item:Remove() end
    end
    for name, recipe in pairs(AllRecipes) do
        if name:find('xd_lingshi',1,true) then
            local ingredients={}
            for _, ingredient in ipairs(recipe.ingredients or {}) do
                ingredients[#ingredients+1]=ingredient.type..':'..ingredient.amount
            end
            print('ICYWEED_CURRENCY_RECIPE',name,recipe.product,recipe.numtogive,table.concat(ingredients,','))
        end
    end
    assert(Prefabs.xd_lingshi1,'required Tu Tien dependency absent')
    -- Use the real stack component and its replica, including a deliberately small cap.
    local definition=Prefabs.xd_lingshi1
    local original=definition.fn
    definition.fn=function(...)
        local item=original(...)
        -- DST replica encodes standard stack caps; 10 is supported, arbitrary 5 is not.
        if item then item.components.stackable.maxsize=10 end
        return item
    end
    local prior={}
    for guid in pairs(Ents) do prior[guid]=true end
    local inst=New({{prefab='xd_lingshi1',amount=4},{prefab='xd_lingshi1',amount=8},{prefab='xd_lingshi1',amount=8}})
    inst.components.pickable.onpickedfn(inst,nil)
    local created={}
    for guid,item in pairs(Ents) do if not prior[guid] then created[#created+1]=item end end
    local count,stacks=0,0
    for _, item in ipairs(created) do
        if item:IsValid() and item.prefab=='xd_lingshi1' then
            count=count+item.components.stackable:StackSize();stacks=stacks+1
        end
    end
    print('ICYWEED_STACK_OBSERVED',count,stacks)
    assert(count==20 and stacks==2,'real stack split/merge lost units')
    inst.components.pickable.onpickedfn(inst,nil)
    inst.components.hauntable.onhaunt(inst,nil)
    local after=0
    for guid,item in pairs(Ents) do
        if not prior[guid] and item.prefab=='xd_lingshi1' then after=after+item.components.stackable:StackSize() end
    end
    assert(after==count,'duplicate pick/haunt generated more items')
    definition.fn=original
    for _, item in ipairs(created) do if item:IsValid() then item:Remove() end end
    if inst:IsValid() then inst:Remove() end
    print('ICYWEED_STACK_OK',count,stacks)
    -- Every optional ID must either deliver a real stack or approved lower currency fallback.
    for _, id in ipairs(ids) do
        local before={}
        for guid in pairs(Ents) do before[guid]=true end
        local weed=New({{prefab='xd_lingshi1',amount=2},{prefab=id,amount=1},{prefab=id,amount=1}})
        weed.components.pickable.onpickedfn(weed,nil)
        local received, total={},0
        for guid,item in pairs(Ents) do
            if not before[guid] and item.components.stackable and item:IsValid() then
                assert(item.prefab==id or item.prefab=='xd_lingshi1' or item.prefab=='goldnugget','unexpected reward')
                local amount=item.components.stackable:StackSize()
                received[item.prefab]=(received[item.prefab] or 0)+amount
                total=total+amount
                item:Remove()
            end
        end
        assert(total==4 or total==6,'wrong quantity for '..id)
        if Prefabs[id] then assert(received[id]~=nil,'registered stackable reward missing: '..id) end
        weed:Remove()
    end
    print('ICYWEED_DELIVERY_OK',#ids)
    local kept=New({{prefab='xd_lingshi1',amount=4},{prefab='xd_lingshi2',amount=1},{prefab='goldnugget',amount=2}})
    local data=Save(kept)
    local copy=New();copy.OnLoad(copy,data)
    assert(Signature(Save(copy))==Signature(data),'OnLoad changed saved roll')
    copy:Remove()
    print('ICYWEED_SAVE_OK',Signature(data))
    -- Both zero-delay world population and legacy weeds may roll without a picker.
    local legacy=New();legacy.OnLoad(legacy,{})
    assert(#Save(legacy).icyweed_loot.rewards==3)
    legacy:Remove()
    c_save()
    TheWorld:DoTaskInTime(2,function() print('ICYWEED_QA_PASS',ICYWEED_QA_MODE,'create') end)
end
TheWorld:DoTaskInTime(1,function()
    local ok,err=xpcall(Run,debug.traceback)
    if not ok then print('ICYWEED_QA_FAIL',err) end
end)
