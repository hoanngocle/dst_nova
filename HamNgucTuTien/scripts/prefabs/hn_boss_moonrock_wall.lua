-- Temporary arena obstacle: no workable, inventory, loot, or persistent state.
local assets={Asset('ANIM','anim/wall.zip'),Asset('ANIM','anim/wall_moonrock.zip')}
local function fn()
    local inst=CreateEntity()
    inst.entity:AddTransform();inst.entity:AddAnimState();inst.entity:AddNetwork()
    MakeObstaclePhysics(inst,.5)
    inst.AnimState:SetBank('wall');inst.AnimState:SetBuild('wall_moonrock')
    inst.AnimState:PlayAnimation('fullA')
    inst:AddTag('wall');inst:AddTag('NOCLICK');inst.persists=false
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end
    inst:DoTaskInTime(4,inst.Remove)
    return inst
end
return Prefab('hn_boss_moonrock_wall',fn,assets)
