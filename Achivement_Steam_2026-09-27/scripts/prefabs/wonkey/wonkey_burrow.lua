-- # CC : Animation effect on get achievement
local assets =
{
    Asset("ANIM", "anim/wonkey_burrow.zip"),
    Asset("SOUND", "sound/mole.fsb"),
}

local function Move(inst)
    inst.AnimState:PlayAnimation("burrow_pst")
    inst:ListenForEvent("animover", inst.Remove)
end

local function OnRemove(inst)
    inst.SoundEmitter:KillAllSounds()
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("wonkey_burrow")
    inst.AnimState:SetBuild("wonkey_burrow")
    inst.AnimState:PlayAnimation("burrow_pre")
    inst.AnimState:PushAnimation("burrow_idle", true)

    inst:AddTag("moistureimmunity")

    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/move", "move")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("wonkeyburrow")

    inst.persists = true
    inst.Move = Move
    inst.Player = nil
    inst.OnRemoveEntity = OnRemove
    inst.OnLoad = inst.Remove

    return inst
end

return Prefab("wonkey_burrow", fn, assets)