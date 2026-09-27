-- CC : update old book logic >> [Reward] expertwicker2
if not chasni_getperkexcludeconfig("expertwicker2", "expertwicker3") then
    -- CC : add additional effects >> [Reward] expertwicker2 and lunar_book
    AddComponentPostInit("book", function(self)
        local new_bookbirdfn = function(inst, reader)
            local x, y, z = reader.Transform:GetWorldPosition()
            local range = 30
            local ents = TheSim:FindEntities(x, y, z, range, { "sleeper", "bird" })
            for _, v in ipairs(ents) do
                if v ~= reader and
                        not (v.components.freezable and v.components.freezable:IsFrozen()) and
                        not (v.components.pinnable and v.components.pinnable:IsStuck()) and
                        not (v.components.fossilizable and v.components.fossilizable:IsFossilized()) then
                    if v.components.sleeper then
                        v.components.sleeper:AddSleepiness(10, 20)
                    elseif v.components.grogginess then
                        v.components.grogginess:AddGrogginess(10, 20)
                    else
                        v:PushEvent("knockedout")
                    end
                    local fx = SpawnPrefab("fx_book_sleep")
                    fx.Transform:SetPosition(v.Transform:GetWorldPosition())
                    fx.Transform:SetRotation(v.Transform:GetRotation())
                end
            end
        end

        local new_bookrainfn = function(inst, reader)
            local x, y, z = reader.Transform:GetWorldPosition()
            local range = 20
            local ents = TheSim:FindEntities(x, y, z, range, { "player" })
            for _, v in ipairs(ents) do
                if not v:HasTag("playerghost") then
                    v:AddDebuff("buff_electricattack", "buff_electricattack")
                end
            end
        end

        local new_booksleepfn = function(inst, reader)
            local pt = reader:GetPosition()
            local bunnycount = 2
            local num_fails = 0
            local positions = {}
            for _ = 1, bunnycount do
                local theta = math.random() * 2 * PI
                local radius = math.random(1, 5)
                local result_offset = FindValidPositionByFan(theta, radius, 8, function(offset)
                    local pos = pt + offset
                    return #TheSim:FindEntities(pos.x, 0, pos.z, 1, nil, { "INLIMBO", "FX" }) <= 0 and TheWorld.Map:IsPassableAtPoint(pos:Get()) and TheWorld.Map:IsDeployPointClear(pos, nil, 1)
                end)
                if result_offset then table.insert(positions, {x = pt.x + result_offset.x, z = pt.z + result_offset.z}) else num_fails = num_fails + 1 end
            end

            if num_fails >= bunnycount then return end
            reader:StartThread(function()
                for _, pos in ipairs(positions) do
                    chasni_spawnprefab("pillowfight_confetti_fx", pos.x, 0, pos.z)
                    local bunnyman = chasni_spawnprefab("bunnyman", pos.x, 0, pos.z)
                    if bunnyman.components.follower and not reader:HasTag("playerghost") then
                        if bunnyman.components.combat and bunnyman.components.combat:TargetIs(reader) then
                            bunnyman.components.combat:SetTarget(nil)
                        end
                        if reader.components.leader then
                            reader:PushEvent("makefriend")
                            reader.components.leader:AddFollower(bunnyman)
                            bunnyman.components.follower:AddLoyaltyTime(1440)
                            bunnyman.components.follower.maxfollowtime = 1440

                            local hat = SpawnPrefab("nightcaphat")
                            bunnyman.components.inventory:GiveItem(hat)
                            bunnyman.components.inventory:Equip(hat)
                        end
                    end
                    Sleep(0.33)
                end
            end)
        end

        local new_booklightfn = function(inst, reader)
            local x, y, z = reader.Transform:GetWorldPosition()
            local range = 20
            local ents = TheSim:FindEntities(x, y, z, range, { "playerghost" })
            for _, v in ipairs(ents) do
                local announcement_string = v:GetDisplayName().." "..STRINGS.UI.HUD.REZ_ANNOUNCEMENT.." "..reader.name.."."
                TheNet:AnnounceResurrect(announcement_string, reader.entity)
                v:PushEvent("respawnfromghost", { source = inst, user = reader })
                break
            end
        end

        local new_booklightupgradedfn = function(inst, reader)
            for _, v in ipairs(AllPlayers) do
                if v:HasTag("playerghost") then
                    local announcement_string = v:GetDisplayName().." "..STRINGS.UI.HUD.REZ_ANNOUNCEMENT.." "..reader.name.."."
                    TheNet:AnnounceResurrect(announcement_string, reader.entity)
                    v:PushEvent("respawnfromghost", { source = inst, user = reader })
                end
            end
        end

        local new_booksilviculturefn = function(inst, reader)
            local function regrow(range, posx, posy, posz)
                local ents = TheSim:FindEntities(posx, posy, posz, range, { "silviculture2" })
                reader:StartThread(function()
                    for _, v in ipairs(ents) do
                        if v:IsValid() then
                            if v.components.timer and v.components.timer:TimerExists("grow") then
                                v.components.timer:SetTimeLeft("grow", 0.1)
                                local x, y, z = v.Transform:GetWorldPosition()
                                Sleep(0.1)
                                regrow(0.1, x, y, z)
                            end

                            if v.components.growable and v.components.growable.magicgrowable and not v:HasTag("stump") then
                                if v.components.simplemagicgrower ~= nil then
                                    v.components.simplemagicgrower:StartGrowing()
                                    Sleep(0.33)
                                else
                                    while v:IsValid() and v.components.growable and not v:HasTag("stump") do
                                        if v.components.growable.stage == #v.components.growable.stages or not v.components.growable:DoGrowth() then
                                            break
                                        end

                                        Sleep(0.33)
                                    end
                                end
                            end
                            if v.components.growable and not v.components.growable.magicgrowable then
                                while v:IsValid() and v.components.growable and not v:HasTag("stump") do
                                    if v.components.growable.stage == #v.components.growable.stages or not v.components.growable:DoGrowth() then
                                        break
                                    end

                                    Sleep(0.33)
                                end
                            end
                        end
                    end
                end)
            end
            local x, y, z = reader.Transform:GetWorldPosition()
            regrow(30, x, y, z)
        end

        local temperaturetask = function(inst)
            inst.components.temperature:SetTemperature(TUNING.BOOK_TEMPERATURE_AMOUNT)
            inst.components.moisture:SetMoistureLevel(0)
        end

        local new_booktemperaturefn = function(inst, reader)
            local x, y, z = reader.Transform:GetWorldPosition()
            local range = 20
            local ents = TheSim:FindEntities(x, y, z, range, { "player" })
            for _, v in ipairs(ents) do
                if not v:HasTag("playerghost") then
                    if v._temperaturetask then
                        v._temperaturetask:Cancel()
                        v._temperaturetask = nil
                    end
                    if v._temperaturetask == nil then
                        v._temperaturetask = v:DoPeriodicTask(1, temperaturetask)
                        v:DoTaskInTime(60, function()
                            if v._temperaturetask then
                                v._temperaturetask:Cancel()
                                v._temperaturetask = nil
                            end
                        end)
                    end
                end
            end
        end

        local new_bookresearchstationfn = function(inst, reader)
            local x, y, z = reader.Transform:GetWorldPosition()
            local range = 20
            local ents = TheSim:FindEntities(x, y, z, range, { "player" })
            for _, v in ipairs(ents) do
                if not v:HasTag("playerghost") then
                    if v._bookxpmultiplier then
                        v._bookxpmultiplier:Cancel()
                        v._bookxpmultiplier = nil
                    end
                    v._bookxpmultiplier = v:DoTaskInTime(1 * TUNING.TOTAL_DAY_TIME, function()
                        if v._bookxpmultiplier then
                            v._bookxpmultiplier:Cancel()
                            v._bookxpmultiplier = nil
                        end
                    end)
                end
            end
        end

        local new_bookfishfn = function(inst, reader)
            local mount_prefab = reader.components.areaaware and reader.components.areaaware:CurrentlyInTag("lunacyarea") and "moonglass_wobster_den" or "wobster_den"
            local pt = reader:GetPosition()
            local offset = FindSwimmableOffset(pt, math.random() * TWOPI, 8, 8)

            if offset then
                local x = pt.x + offset.x
                local y = pt.y + offset.y
                local z = pt.z + offset.z
                chasni_spawnprefab("crab_king_waterspout", x, y, z)
                chasni_spawnprefab(mount_prefab, x, y, z)
            end
        end

        local new_bookbeefn = function(inst, reader)
            local x, y, z = reader.Transform:GetWorldPosition()
            local range = 8
            local ents = TheSim:FindEntities(x, y, z, range, { "beebox" }, {"FX", "NOCLICK", "INLIMBO", "DECOR"})
            for _, v in ipairs(ents) do
                if v and v.components.harvestable then
                    local stillgrowing = true
                    while(stillgrowing) do
                        stillgrowing = v.components.harvestable:Grow()
                    end
                end
            end
        end

        local new_booktentaclesfn = function(inst, reader)
            local x, y, z = reader.Transform:GetWorldPosition()
            local range = 20
            local ents = TheSim:FindEntities(x, y, z, range, { "player" })
            for _, v in ipairs(ents) do
                if not v:HasTag("playerghost") then
                    if v._tentacleimune_task then
                        v._tentacleimune_task:Cancel()
                        v._tentacleimune_task = nil
                    end
                    v:AddTag("chasni_tentacleimmune")
                    v._tentacleimune_task = v:DoTaskInTime(60, function()
                        v:RemoveTag("chasni_tentacleimmune")
                    end)
                end
            end
        end

        local new_bookmoonfn = function(inst, reader)
            local x, y, z = reader.Transform:GetWorldPosition()
            local range = 5
            local ents = TheSim:FindEntities(x, y, z, range, { "halloweenmoonmutable" }, {"FX", "NOCLICK", "INLIMBO", "DECOR"})
            for _, v in ipairs(ents) do
                if v and v.components.halloweenmoonmutable then
                    local new_v = v.components.halloweenmoonmutable:Mutate()
                    SpawnPrefab("halloween_moonpuff").Transform:SetPosition(new_v.Transform:GetWorldPosition())
                end
            end
        end

        local new_bookfirefn = function(inst, reader)
            local pos = Vector3(inst.Transform:GetWorldPosition())
            chasni_spawnprefab("firesplash_fx", pos.x, pos.y, pos.z)
            local targets = TheSim:FindEntities(pos.x, pos.y, pos.z, TUNING.BOOK_FIRE_RADIUS, nil, { "FX", "INLIMBO", "lighter", "invisible" })
            for _, target in pairs(targets) do
                if target and target.components.burnable and not target:HasTag("burnt") and target.components.fueled == nil and not target:HasTag("INLIMBO") then
                    target.components.burnable:Ignite(true, inst, reader)
                end
            end
        end

        local SLOWDOWN_MUST_TAGS = { "locomotor" }
        local SLOWDOWN_CANT_TAGS = { "player", "flying", "playerghost", "INLIMBO" }
        local HEAL_CANT_TAGS = { "flying", "playerghost", "INLIMBO" }
        local new_bookwebfn_OnUpdate = function(inst, x, y, z)
            for _, v in ipairs(TheSim:FindEntities(x, y, z, TUNING.BOOK_WEB_GROUND_RADIUS, SLOWDOWN_MUST_TAGS, SLOWDOWN_CANT_TAGS)) do
                if v.components.locomotor and not (chasni_friendpet(v)) then
                    if v.components.health then
                        local damage = math.min(50, v.components.health.currenthealth * 0.01)
                        v.components.health:DoDelta(-damage)
                    end
                end
            end
            for _, v in ipairs(TheSim:FindEntities(x, y, z, TUNING.BOOK_WEB_GROUND_RADIUS, SLOWDOWN_MUST_TAGS, HEAL_CANT_TAGS)) do
                if v.components.health and (v:HasTag("player") or (chasni_friendpet(v))) then
                    local heal = math.max(0, (v.components.health.maxhealth - v.components.health.currenthealth) * 0.1)
                    v.components.health:DoDelta(heal)
                end
            end
        end
        local new_bookwebfn = function(inst, reader)
            local x, y, z = reader.Transform:GetWorldPosition()
            local ground_web = SpawnPrefab("book_web_ground")
            ground_web.Transform:SetPosition(x,y,z)
            ground_web:DoPeriodicTask(1, new_bookwebfn_OnUpdate, nil, x, y, z)
        end

        local oldOnRead = self.OnRead
        self.OnRead = function(_self, reader, ...)
            local isAchieve = reader and reader.prefab == "wickerbottom" and reader.components.allachivcoin and reader.components.allachivcoin.expertwicker2
            if isAchieve and _self.inst.prefab == "book_fire" then
                new_bookfirefn(_self.inst, reader)
            end

            local success, reason = oldOnRead(_self, reader, ...)
            if isAchieve and success then
                if _self.inst.prefab == "book_horticulture" or _self.inst.prefab == "book_horticulture_upgraded" then
                    _self.inst:DoTaskInTime(5, _self.onread, reader)
                elseif _self.inst.prefab == "book_birds" then
                    _self.inst:DoTaskInTime(2.25, new_bookbirdfn, reader)
                elseif _self.inst.prefab == "book_web" then
                    new_bookwebfn(_self.inst, reader)
                elseif _self.inst.prefab == "book_rain" then
                    new_bookrainfn(_self.inst, reader)
                elseif _self.inst.prefab == "book_sleep" then
                    new_booksleepfn(_self.inst, reader)
                elseif _self.inst.prefab == "book_light" then
                    new_booklightfn(_self.inst, reader)
                elseif _self.inst.prefab == "book_light_upgraded" then
                    new_booklightupgradedfn(_self.inst, reader)
                elseif _self.inst.prefab == "book_silviculture" then
                    new_booksilviculturefn(_self.inst, reader)
                elseif _self.inst.prefab == "book_temperature" then
                    new_booktemperaturefn(_self.inst, reader)
                elseif _self.inst.prefab == "book_research_station" then
                    new_bookresearchstationfn(_self.inst, reader)
                elseif _self.inst.prefab == "book_fish" then
                    new_bookfishfn(_self.inst, reader)
                elseif _self.inst.prefab == "book_bees" then
                    new_bookbeefn(_self.inst, reader)
                elseif _self.inst.prefab == "book_tentacles" then
                    new_booktentaclesfn(_self.inst, reader)
                elseif _self.inst.prefab == "book_moon" then
                    new_bookmoonfn(_self.inst, reader)
                elseif _self.inst.prefab == "book_brimstone" then -- >>>> JUST REPEAT
                    _self.onread(_self.inst, reader)
                end
            end

            local isOnLunarEffect = success and reader and reader:HasDebuff("book_lunar_buff")
            if isOnLunarEffect then
                local x, y, z = reader.Transform:GetWorldPosition()
                local range = 10
                local ents = FindPlayersInRange(x, y, z, range, true)
                for _, v in ipairs(ents) do
                    if v.components.health and v.components.sanity then
                        v.components.health:DoDelta(30)
                        v.components.sanity:DoDelta(30)
                    end
                end
            end

            return success, reason
        end
    end)

    -- CC : add silviculture2 to marblescrub items and ancienttree >> [Reward] expertwicker2
    AddPrefabPostInit("marbleshrub",function(inst)
        inst:AddTag("silviculture2")
    end)
    AddPrefabPostInit("marblebean_sapling",function(inst)
        inst:AddTag("silviculture2")
    end)

    local ancienttree_defs = require("prefabs/ancienttree_defs")
    local TREE_DEFS  = ancienttree_defs.TREE_DEFS
    for name, _ in pairs(TREE_DEFS) do
        AddPrefabPostInit("ancienttree_"..name,function(inst)
            inst:AddTag("silviculture2")
        end)
        AddPrefabPostInit("ancienttree_"..name.."_sapling",function(inst)
            inst:AddTag("silviculture2")
        end)
    end
end
