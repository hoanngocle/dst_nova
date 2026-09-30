local assets={Asset('ANIM','anim/lavaarena_boarrior_basic.zip'),Asset('ANIM','anim/hh_beru_dungeon.zip')}
local function corpse(name,bank,build,anim)
    local function fn()
        local inst=CreateEntity()
        inst.entity:AddTransform();inst.entity:AddAnimState();inst.entity:AddNetwork()
        inst.AnimState:SetBank(bank);inst.AnimState:SetBuild(build);inst.AnimState:PlayAnimation(anim)
        inst:AddTag('NOCLICK');inst:AddTag('DECOR');inst.persists=false
        inst.entity:SetPristine()
        if TheWorld.ismastersim then inst:DoTaskInTime(30,inst.Remove) end
        return inst
    end
    return Prefab(name,fn,assets)
end
return corpse('hn_corpse_igris','boarrior','lavaarena_boarrior_basic','death2'),corpse('hn_corpse_beru','beetletaur','hh_beru_dungeon','death')
