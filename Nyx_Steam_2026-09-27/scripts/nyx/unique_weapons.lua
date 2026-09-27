-- Dispatch each unique weapon to its own 18.1 skills, never change Nyx's identity.
local M={}
local families={xd_sly='xd_longtaizi',xd_sudaji_mxrg='xd_sudaji',xd_wukong_jgb='xd_wukong',
 xd_jingwei_zzql='xd_jingwei',xd_yunxiao_jjj='xd_yunxiao',xd_htz_qzj='xd_hantianzun',
 xd_sj_tej='xd_shiji',xd_wmz_xsj='xd_wangmazi',xd_chenpingan_cm='xd_chenpingan',xd_chenpingan_kcd='xd_chenpingan'}
M.Families=families
local states={xd_yunxiao='xd_yunxiao_jjj_lungestart',xd_hantianzun='xd_superjump_start',
 xd_shiji='xd_superjump_start',xd_chenpingan='xd_chenpingan_lingji_lungestart'}
function M.State(inst,weapon,action)
    local family=weapon and families[weapon.prefab]
    if states[family] then return states[family] end
    if weapon and weapon.onusesgname then
        return type(weapon.onusesgname)=='function' and weapon.onusesgname(weapon,inst,action) or weapon.onusesgname
    end
    return 'xd_ljattack'
end
local function Add(inst,name)
    if not inst.components[name] then inst:AddComponent(name) end
    return inst.components[name]
end
function M.Attach(inst)
    if inst._nyx_unique_weapons then return end
    inst._nyx_unique_weapons=true
    inst.onuseljsgname=M.State
    inst.onuseljsgname_client=M.State
    if not TheWorld.ismastersim then return end
    local callbacks={}
    for family,init in pairs(require('nyx/unique_native18')) do
        local holder={};init(holder);callbacks[family]=holder
    end
    -- These save their own summons. Suppress Jingwei's free spawn until her weapon is used.
    Add(inst,'xd_petleash_mxrg')
    local pet=Add(inst,'xd_jingwei_pet');pet.first=false
    inst.lingqi_mode=inst.lingqi_mode or 0
    local oldlingji,oldshentong=inst.dolingjiskill,inst.doshentongskill
    local function prepare(owner,weapon)
        local family=weapon and families[weapon.prefab]
        local native=family and callbacks[family]
        if family=='xd_jingwei' and not owner.components.xd_jingwei_pet:GetPet() then
            owner.components.xd_jingwei_pet:SpawnPet()
        end
        return native
    end
    inst.dolingjiskill=function(owner,weapon,pos,target)
        local native=prepare(owner,weapon)
        if native then return native.dolingjiskill(owner,weapon,pos,target) end
        if oldlingji then return oldlingji(owner,weapon,pos,target) end
    end
    inst.doshentongskill=function(owner,weapon)
        local native=prepare(owner,weapon)
        if native then return native.doshentongskill(owner,weapon) end
        if oldshentong then return oldshentong(owner,weapon) end
    end
    inst.ljattack_fn=function(owner,weapon,...)
        local native=weapon and callbacks[families[weapon.prefab]]
        if native and native.ljattack_fn then return native.ljattack_fn(owner,weapon,...) end
    end
    local oldredirect=inst.components.health.redirect
    inst.components.health.redirect=function(owner,amount,...)
        if oldredirect and oldredirect(owner,amount,...) then return true end
        local shield=owner.xd_wmz_forcefieldfx
        if amount and amount<0 and shield and shield:IsValid() then
            shield:TakeDamage(amount);return true
        end
    end
end
function M.Install(api)
    api.AddPrefabPostInit('nyx',M.Attach)
    api.AddPrefabPostInit('xd_chenpingan_kcd',function(inst)
        if not TheWorld.ismastersim then return end
        local old=inst.UseLingJi
        inst.UseLingJi=function(item,doer,...)
            if doer and doer.prefab=='nyx' then return doer:doshentongskill(item) end
            if old then return old(item,doer,...) end
        end
    end)
end
return M
