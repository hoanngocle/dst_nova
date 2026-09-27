local brain = require "brains/chasni_gronehogbrain"

local HEALTH = chasni_getmobconfig("gronehog", "HP") or 104
local SPEED = chasni_getmobconfig("gronehog", "SPD") or 7

local function MakeGroneHog(element, loot, loot2, sound)
    local assets =
    {
        Asset("ANIM", "anim/gronehog_"..element..".zip"),
        Asset("SOUND", "sound/rabbit.fsb"),
    }

    local sounds =
    {
        scream = "dontstarve/rabbit/"..sound.."scream",
        hurt = "dontstarve/rabbit/"..sound.."scream_short",
    }

    local prefabs =
    {
        "smallmeat",
        "batnose",
        loot,
        loot2,
    }

    SetSharedLootTable("gronehog_"..element, {
        { "batnose",	    0.85 },
        { loot,	            0.50 },
        { loot2,	        0.40 },
    })

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddNetwork()

        MakeCharacterPhysics(inst, 1, 0.5)

        inst.DynamicShadow:SetSize(1, .75)
        inst.Transform:SetTwoFaced()
        inst.Transform:SetScale(1.5, 1.5, 1.5)

        inst.AnimState:SetBank("gronehog_"..element)
        inst.AnimState:SetBuild("gronehog_"..element)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("animal")
        inst:AddTag("prey")
        inst:AddTag("smallcreature")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("locomotor")
        inst.components.locomotor.runspeed = SPEED

        inst:AddComponent("eater")
        inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })

        inst:AddComponent("sanityaura")
        inst.components.sanityaura.aura = -TUNING.SANITYAURA_TINY

        inst:AddComponent("health")
        inst.components.health:SetMaxHealth(HEALTH)

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable("gronehog_"..element)

        inst:AddComponent("combat")
        MakeSmallBurnableCharacter(inst, "chest")

        inst:AddComponent("timer")
        inst:AddComponent("inspectable")

        inst.sounds = sounds

        inst:SetBrain(brain)
        inst:SetStateGraph("SGCZgronehog")

        return inst
    end

    return Prefab("gronehog_"..element, fn, assets, prefabs)
end

return
MakeGroneHog("snow", "bluegem", "greengem", "winter"),
MakeGroneHog("sand", "yellowgem", "orangegem", "beard")
