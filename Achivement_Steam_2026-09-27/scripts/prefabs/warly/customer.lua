local function MakeCustomer(name, anim, patience)
    local assets =
    {
        Asset("ANIM", "anim/"..anim..".zip"),
    }
    local function ontimerdone(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        inst:DoTaskInTime(1, function(i)
            chasni_spawnprefab("chestupgrade_stacksize_fx", x, y, z)
            chasni_spawnprefab("chestupgrade_stacksize_fx", x, y+2, z)
            i:Remove()
        end)
    end

    local function ontalk(inst, script)
        inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_elderdrake/idle_happy", nil, 0.8)
    end

    local function launchitem(item, angle)
        local speed = math.random() * 4 + 2
        angle = (angle + math.random() * 60 - 30) * DEGREES
        item.Physics:SetVel(speed * math.cos(angle), math.random() * 2 + 8, speed * math.sin(angle))
    end

    local function abletoaccepttest(inst, item, giver)
        if inst.components.timer:TimerExists("waiting") and item.prefab == inst.wantedfoodprefab then
            return true
        end
        return false
    end

    local function ongivenitem(inst, giver, item)
        local x, y, z = inst.Transform:GetWorldPosition()
        local angle
        if giver ~= nil and giver:IsValid() then
            angle = 180 - giver:GetAngleToPoint(x, 0, z)
        else
            local down = TheCamera:GetDownVec()
            angle = math.atan2(down.z, down.x) / DEGREES
            giver = nil
        end

        local timeleft = inst.components.timer:GetTimeLeft("waiting") or 1
        local bonus = math.floor(timeleft / (TUNING.TOTAL_DAY_TIME * 0.2)) - 2
        for _, v in pairs(inst.rewards) do
            local count = v.count + bonus
            for _ = 1, count do
                local reward = SpawnPrefab(v.prefab)
                if reward then
                    reward.Transform:SetPosition(x, 4.5, z)
                    launchitem(reward, angle)
                end
            end
        end
        if giver and giver.components.levelsystem then
            giver.components.levelsystem:xpDoDelta(timeleft, giver)
        end
        if _G.NOAWARDS ~= true and giver and giver.components.allachivcoin then
            if timeleft > TUNING.TOTAL_DAY_TIME * 0.6 or giver.prefab == "warly" then
                SpawnPrefab("seffc").entity:SetParent(giver.entity)
                giver.components.allachivcoin:coinDoDelta(1)
                if _G.NOTIFICATION then
                    TheNet:Announce(giver:GetDisplayName().." nhận 1 Sao Thành Tựu nhờ giao món ăn")
                end
            end
        end

        inst.components.talker:Say(STRINGS.GOATKID_TALK_TRADE[math.random(#STRINGS.GOATKID_TALK_TRADE)])
        inst:DoTaskInTime(1, function(i)
            chasni_spawnprefab("chestupgrade_stacksize_fx", x, y, z)
            chasni_spawnprefab("chestupgrade_stacksize_fx", x, y+2, z)
            i:Remove()
        end)
    end

    local function Onrefuseitem(inst, giver, item)
        inst.components.talker:Say(STRINGS.CARNIVAL_CROWKID_REFUSEGIFT[math.random(#STRINGS.CARNIVAL_CROWKID_REFUSEGIFT)])
    end

    local function getdesc(inst)
        if inst.wantedfoodname then
            return subfmt(STRINGS.CUSTOMER_DESC, {gender = name == "goatmum" and "Cô ấy" or "Anh ấy", food = inst.wantedfoodname})
        end
        return subfmt(STRINGS.CUSTOMER_DESC, {gender = name == "goatmum" and "Cô ấy" or "Anh ấy", food = "món ăn nào đó"})
    end

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 1)

        inst.DynamicShadow:SetSize(2, 1)
        inst.Transform:SetFourFaced()
        if name == "goatmum" then
            inst.Transform:SetScale(1.3, 1.3, 1.3)
        end

        inst.AnimState:SetBank(anim)
        inst.AnimState:SetBuild(anim)
        inst.AnimState:PlayAnimation("idle_loop", true)

        inst:AddComponent("talker")
        inst.components.talker.ontalk = ontalk
        inst.components.talker.fontsize = 35
        inst.components.talker.font = TALKINGFONT
        inst.components.talker.offset = Vector3(0, -400, 0)
        inst.components.talker:MakeChatter()

        inst:AddTag("trader")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("inspectable")
        inst.components.inspectable.getspecialdescription = getdesc

        inst:AddComponent("trader")
        inst.components.trader:SetAcceptTest(abletoaccepttest)
        inst.components.trader.acceptnontradable = true
        inst.components.trader.deleteitemonaccept = true
        inst.components.trader.onaccept = ongivenitem
        inst.components.trader.onrefuse = Onrefuseitem

        inst:AddComponent("timer")
        inst.components.timer:StartTimer("waiting", patience)
        inst:ListenForEvent("timerdone", ontimerdone)

        inst.wantedfoodprefab = "goldnugget"
        inst.rewards = {{ prefab = "goldnugget", count = 5 },}
        inst.persists = false

        return inst
    end

    return Prefab("customer_"..name, fn, assets)
end

return
MakeCustomer("goatmum", "quagmire_goatmom_basic", TUNING.TOTAL_DAY_TIME * 1),
MakeCustomer("goatkid", "quagmire_goatkid_basic", TUNING.TOTAL_DAY_TIME * 0.8)
