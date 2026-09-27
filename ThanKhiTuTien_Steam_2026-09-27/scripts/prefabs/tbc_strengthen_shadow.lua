local assets = {
    Asset("ANIM", "anim/lavaarena_shadow_lunge.zip"),
    Asset("ANIM", "anim/waxwell_shadow_mod.zip"),
    Asset("ANIM", "anim/swap_nightmaresword_shadow.zip"),
}

local function Valid(entity)
    return entity ~= nil and (entity.IsValid == nil or entity:IsValid())
end

local function Attack(inst)
    local target, attacker = inst.target, inst.attacker
    if not Valid(target) or not Valid(attacker) then return end
    local health = target.components ~= nil and target.components.health or nil
    local combat = target.components ~= nil and target.components.combat or nil
    if combat == nil or health ~= nil and health:IsDead() then return end
    local x, y, z = target.Transform:GetWorldPosition()
    local fx = SpawnPrefab("shadowstrike_slash_fx")
    if fx ~= nil then fx.Transform:SetPosition(x, y, z) end
    combat:GetAttacked(attacker, inst.damage, nil, "tbc_strengthen_auxiliary")
end

local function Init(inst, attacker, target, damage, angle)
    inst.attacker = attacker
    inst.target = target
    inst.damage = damage
    local x, y, z = target.Transform:GetWorldPosition()
    inst.Transform:SetPosition(x + math.cos(angle) * 4.5, y, z + math.sin(angle) * 4.5)
    inst:FacePoint(x, y, z)
    inst.AnimState:PlayAnimation("lunge_pre")
    inst.AnimState:PushAnimation("lunge_lag")
    inst.AnimState:PushAnimation("lunge_pst")
    inst:DoTaskInTime(15 * FRAMES, Attack)
    inst:DoTaskInTime(35 * FRAMES, inst.Remove)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.Transform:SetFourFaced()
    inst.AnimState:SetBank("lavaarena_shadow_lunge")
    inst.AnimState:SetBuild("waxwell_shadow_mod")
    inst.AnimState:AddOverrideBuild("lavaarena_shadow_lunge")
    inst.AnimState:OverrideSymbol("swap_object", "swap_nightmaresword_shadow", "swap_nightmaresword_shadow")
    inst.AnimState:SetMultColour(0, 0, 0, .5)
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end
    inst.Init = Init
    return inst
end

return Prefab("tbc_strengthen_shadow", fn, assets, {"shadowstrike_slash_fx"})
