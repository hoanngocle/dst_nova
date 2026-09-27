local assets = {
    Asset("SOUNDPACKAGE", "sound/ember_spirit.fev"),
    Asset("SOUND", "sound/ember_spirit.fsb"),
}

local RADIUS = 3
local TICK = 1
local DURATION = 120
local DAMAGE = 1
local AURA_EXCLUDE_TAGS = { "heatresistant", "player", "playerghost", "ghost", "noauradamage", "INLIMBO", "notarget", "noattack", "invisible" }

local function CopySkin(inst, player)
    if inst.components.skinner then
        inst.components.skinner:CopySkinsFromPlayer(player)
    end
end

local function onextinguish(inst)
    if inst._owner and inst._owner._fireclones then
        inst.SoundEmitter:PlaySound("ember_spirit/chasni_ember_spirit/ember_remnant_activate")
        table.remove(inst._owner._fireclones, chasni_findindex(inst._owner._fireclones, inst))
    end
    ErodeAway(inst)
end

local function fn()
	local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("wilson")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.AnimState:OverrideSymbol("fx_wipe", "wilson_fx", "fx_wipe")
    inst.AnimState:SetMultColour(1, 0.4, 0.1, 0.5)
    inst.AnimState:UsePointFiltering(true)

    inst.SoundEmitter:PlaySound("ember_spirit/chasni_ember_spirit/ember_remnant_set")

    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Hide("HAT")
    inst.AnimState:Hide("HAIR_HAT")
    inst.AnimState:Show("HAIR_NOHAT")
    inst.AnimState:Show("HAIR")
    inst.AnimState:Show("HEAD")
    inst.AnimState:Hide("HEAD_HAT")

    inst.CopySkin = CopySkin

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then 
        return inst 
    end

    MakeSmallBurnableCharacter(inst, "torso")
    inst.components.burnable:SetBurnTime(DURATION)
    inst.components.burnable.nocharring = true
    inst:ListenForEvent("onextinguish", onextinguish)

    inst:AddComponent("skinner")
    inst.components.skinner:SetupNonPlayerData()

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DAMAGE)

    inst:AddComponent("aura")
    inst.components.aura.radius = RADIUS
    inst.components.aura.tickperiod = TICK
    inst.components.aura.auraexcludetags = AURA_EXCLUDE_TAGS
    inst.components.aura:Enable(true)

    inst:AddComponent("heater")
    inst.components.heater.heat = 65

    inst._owner = nil
    inst.persists = false

    return inst
end

return Prefab("fire_clone", fn, assets)
