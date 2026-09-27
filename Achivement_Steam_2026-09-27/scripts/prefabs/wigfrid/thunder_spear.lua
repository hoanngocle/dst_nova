local assets =
{
    Asset("ANIM", "anim/thunder_spear.zip"),
    Asset("ATLAS", "images/inventoryimages/thunder_spear1.xml"),
    Asset("ATLAS", "images/inventoryimages/thunder_spear2.xml"),
}

local assets_lightning = {
    Asset("ANIM", "anim/lightning.zip")
}

local assets_preparefx = {
    Asset("ANIM", "anim/lavaarena_creature_teleport.zip")
}

local prefabs =
{
    "electrichitsparks",
    "sword_lunarplant_blade_fx",
    "spear_wathgrithr_lightning_lunge_fx",
}

local CANT_HAVE_SPELL_TAGS = {"FX", "NOCLICK", "INLIMBO", "DECOR"}
local SELF_DAMAGE = chasni_getitemconfig("thunder_spear", "SDM") or 34
local COOLDOWN = chasni_getitemconfig("thunder_spear", "CD") or 300
local USES = 100
local DAMAGE = chasni_getitemconfig("thunder_spear", "DMM") or 50
local BASE_DAMAGE = chasni_getitemconfig("thunder_spear", "BDM") or 10
local CHARGE_BONUS = chasni_getitemconfig("thunder_spear", "CRG") or 0
local STORM_STRIKE_COUNT = chasni_getitemconfig("thunder_spear", "SSC") or 10
local STORM_STRIKE_DAMAGE_MULTIPLIER = chasni_getitemconfig("thunder_spear", "SSD") or 1.5
local ATTACK_COMBO_COUNT = chasni_getitemconfig("thunder_spear", "COM") or 10
local ATTACK_RANGE = 2
local HIT_RANGE = 2.5
local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_thunder_spear", "swap_sword_lunarplant")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    chasni_equipanimatedswaphand(inst, owner)
    if owner.components.combat then
        owner.components.combat:GetAttacked(inst, SELF_DAMAGE, nil, "electric")
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    if inst.components.finiteuses then
        inst.components.finiteuses:SetUses(0)
    end
    chasni_equipanimatedswaphand(inst, nil)
end

local function reticule_target_function(inst)
    return Vector3(ThePlayer.entity:LocalToWorldSpace(10, 0.001, 0))
end

local function createSingleThunder(inst, owner, target)
    SpawnAt("spear_lightning", target)
    if target.components.health and not target.components.health:IsDead() then
        if owner and owner.components.singinginspiration and owner.components.singinginspiration.current > 0 and target.components.combat then
            target.components.combat:GetAttacked(owner, owner.components.singinginspiration.current, nil, "electric")
            if target.sg and target.sg:HasState("hit") and not target.sg:HasStateTag("noouthit") then
                target.sg:GoToState("hit")
            end
        end
    end
end

local function OnAttack(inst, attacker, target, projectile)
    if chasni_hastag2(attacker, "expertwathg1") then
        inst.AttackNum = inst.AttackNum + 1
        if inst.AttackNum >= ATTACK_COMBO_COUNT then
            if attacker.components.inventory:EquipHasTag("thunder_armor") and attacker.components.inventory:EquipHasTag("thunder_hat") then
                createSingleThunder(inst, attacker, target)
            end
            inst.AttackNum = 0
            if inst.components.finiteuses then
                inst.components.finiteuses:Repair(5 + CHARGE_BONUS)
            end
        end
        if inst.components.finiteuses then
            inst.components.finiteuses:Repair(1 + CHARGE_BONUS)
        end
    end
    if target and target:IsValid() and attacker and attacker:IsValid() then
        SpawnPrefab("electrichitsparks"):AlignToTarget(target, attacker, true)
    end
end

local function getDamage(inst, attacker, target)
    local mult = inst.components.finiteuses and inst.components.finiteuses:GetPercent() or 0
    return BASE_DAMAGE + (DAMAGE * mult)
end

local function spawnlungefx(x, y, z)
    local lungefx = chasni_spawnprefab("spear_wathgrithr_lightning_lunge_fx", x, y, z)
    lungefx.Transform:SetRotation(45)
    local lungefx2 = chasni_spawnprefab("spear_wathgrithr_lightning_lunge_fx", x, y, z)
    lungefx2.Transform:SetRotation(135)
    local lungefx3 = chasni_spawnprefab("spear_wathgrithr_lightning_lunge_fx", x, y, z)
    lungefx3.Transform:SetRotation(-45)
    local lungefx4 = chasni_spawnprefab("spear_wathgrithr_lightning_lunge_fx", x, y, z)
    lungefx4.Transform:SetRotation(-135)
end

local function createThunderStorm(inst, target, position)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    local uses = inst.components.finiteuses and inst.components.finiteuses:GetPercent() or 0
    if uses < 1 then
        owner.components.talker:Say(GetString(owner, "THUNDER_SPEAR_FAIL"))
        return
    end

    local max = STORM_STRIKE_COUNT
    local current = 0

    local px, py, pz = chasni_getPos(position, target)
    if not TheNet:GetPVPEnabled() then
        table.insert(CANT_HAVE_SPELL_TAGS, "player")
        table.insert(CANT_HAVE_SPELL_TAGS, "companion")
        table.insert(CANT_HAVE_SPELL_TAGS, "ally")
    end
    inst:StartThread(
            function()
                Sleep(0.3)
                while true do
                    local ents = TheSim:FindEntities(px, py, pz, 7, nil, CANT_HAVE_SPELL_TAGS, nil)
                    for k, v in pairs(ents) do
                        if v ~= owner and v:IsValid() and inst.components.finiteuses and inst.components.finiteuses:GetPercent() >= 1 and v.components.combat and v.components.health 
                                and not v.components.health:IsDead() and owner.components.combat:CanTarget(v) and not owner.components.combat:IsAlly(v)
                        then
                            SpawnAt("spear_elec_preparefx", v)
                            local dmg = owner.components.combat:CalcDamage(v, inst)
                            v.components.combat:GetAttacked(owner, dmg * STORM_STRIKE_DAMAGE_MULTIPLIER, nil, "electric")
                            if v.components.health:IsDead() then
                                max = max + 1
                            end
                            break
                        end
                    end
                    spawnlungefx(px, py, pz)
                    current = current + 1
                    if current > max then
                        return
                    end
                    Sleep(0.3)
                end
            end
    )
    inst.components.rechargeable:Discharge(COOLDOWN)
end

local function OnCharged(inst)
    inst.components.spellcaster:SetSpellFn(createThunderStorm)
end

local function OnDischarged(inst)
    inst.components.spellcaster:SetSpellFn(nil)
end

local function OnSave(inst, data)
    data.uses = inst.components.finiteuses.current
end

local function OnLoad(inst, data)
    if data and data.uses then
        inst.components.finiteuses:SetUses(data.uses)
    end
end

local function PushIdleLoop(inst)
    if inst.components.finiteuses:GetUses() > 0 then
        inst.AnimState:PushAnimation("idle")
    end
end

local function OnStopFloating(inst)
    if inst.components.finiteuses:GetUses() > 0 then
        inst._fxswap.AnimState:SetFrame(0)
        inst:DoTaskInTime(0, PushIdleLoop) --#V2C: #HACK restore the looping anim, timing issues
    end
end

local function PercentChanged(inst, data)
    if data.percent and data.percent >= 1 then
        inst._fxswap.AnimState:PlayAnimation("swap_energy", true)
        inst._fxswap.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.components.inventoryitem.imagename = "thunder_spear2"
        inst.components.inventoryitem.atlasname = "images/inventoryimages/thunder_spear2.xml"
    else
        inst._fxswap.AnimState:PlayAnimation("swap_normal", true)
        inst._fxswap.AnimState:ClearBloomEffectHandle()
        inst.components.inventoryitem.imagename = "thunder_spear1"
        inst.components.inventoryitem.atlasname = "images/inventoryimages/thunder_spear1.xml"
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("thunder_spear")
    inst.AnimState:SetBuild("thunder_spear")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetSymbolBloom("pb_energy_loop01")
    inst.AnimState:SetSymbolLightOverride("pb_energy_loop01", .5)
    inst.AnimState:SetLightOverride(.1)

    inst:AddTag("allow_action_on_impassable")
    inst:AddTag("sharp")
    inst:AddTag("pointy")
    inst:AddTag("weapon")
    inst:AddTag("charges_percentage")
    inst:AddTag("rechargeable")
    inst:AddTag("guitar")

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = reticule_target_function
    inst.components.reticule.ease = true
    inst.components.reticule.ispassableatallpoints = true

    inst._restrictedtag = "expertwathg1"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    local frame = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
    inst.AnimState:SetFrame(frame)
    inst._fxswap = SpawnPrefab("thunder_spear_fx")
    inst._fxswap.AnimState:PlayAnimation("swap_normal", true)
    inst._fxswap.AnimState:SetFrame(frame)
    chasni_equipanimatedswaphand(inst, nil)
    inst:ListenForEvent("floater_stopfloating", OnStopFloating)

    inst.AttackNum = 0

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(getDamage)
    inst.components.weapon:SetOnAttack(OnAttack)
    inst.components.weapon:SetRange(ATTACK_RANGE, HIT_RANGE)
    inst.components.weapon:SetElectric()

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(USES)
    inst.components.finiteuses:SetUses(0)
    inst.components.finiteuses:SetIgnoreCombatDurabilityLoss(true)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "thunder_spear1"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/thunder_spear1.xml"

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canuseonpoint_water = true
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster:SetSpellFn(createThunderStorm)

    MakeHauntableLaunch(inst)

    inst:ListenForEvent("percentusedchange", PercentChanged)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

----------------------------------------------------------------------------------------------

local function PlayLightningAnim(pos)
    local inst = CreateEntity()
    inst:AddTag("FX")
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()

    inst.Transform:SetPosition(pos:Get())
    inst.Transform:SetScale(2, 2, 2)

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetBank("lightning")
    inst.AnimState:SetBuild("lightning")
    inst.AnimState:PlayAnimation("anim")

    inst:ListenForEvent("animover", inst.Remove)
end

local function PlayThunderSound(pos)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()

    inst.Transform:SetPosition(pos:Get())
    inst.SoundEmitter:PlaySoundWithParams("dontstarve/rain/thunder_close", {intensity = 0.7})
    inst:Remove()
end

local function StartFX(proxy)
    TheWorld:PushEvent("screenflash", .5)

    local pos = Vector3(proxy.Transform:GetWorldPosition())
    PlayLightningAnim(pos)

    if TheNet:IsDedicated() then
        return
    end

    local pos0 = Vector3(TheFocalPoint.Transform:GetWorldPosition())
    local diff = pos - pos0
    local distsq = diff:LengthSq()
    local minsounddist = 10
    local normpos = pos
    if distsq > minsounddist * minsounddist then
        local normdiff = diff * (minsounddist / math.sqrt(distsq))
        normpos = pos0 + normdiff
    end

    if ThePlayer then
        ThePlayer:ShakeCamera(CAMERASHAKE.FULL, .7, .02, .5, proxy, 40)
    end
    PlayThunderSound(normpos)
end

local function lightningfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst:DoTaskInTime(0, StartFX)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetCanSleep(false)
    inst.persists = false
    inst:DoTaskInTime(1, inst.Remove)

    return inst
end

local function preparefxfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lavaarena_creature_teleport")
    inst.AnimState:SetBuild("lavaarena_creature_teleport")
    inst.AnimState:PlayAnimation("spawn_medium")

    inst.AnimState:HideSymbol("blast")
    inst.AnimState:HideSymbol("smoke1")
    inst.AnimState:HideSymbol("smoke3")
    inst.AnimState:SetMultColour(1, 1, 0.7, 1)

    inst.AnimState:SetLightOverride(1)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:ListenForEvent("animover", inst.Remove)
    inst:DoTaskInTime(9 * FRAMES, inst.Remove)

    return inst
end

local function fxfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.AnimState:SetBank("thunder_spear")
    inst.AnimState:SetBuild("thunder_spear")
    inst.AnimState:PlayAnimation("swap_energy", true)
    inst.AnimState:SetSymbolBloom("pb_energy_loop01")
    inst.AnimState:SetSymbolLightOverride("pb_energy_loop01", .5)
    inst.AnimState:SetLightOverride(.1)

    inst:AddComponent("highlightchild")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("colouradder")

    inst.persists = false

    return inst
end

return 
Prefab("thunder_spear", fn, assets, prefabs),
Prefab("spear_lightning", lightningfn, assets_lightning),
Prefab("spear_elec_preparefx", preparefxfn, assets_preparefx),
Prefab("thunder_spear_fx", fxfn, assets)
