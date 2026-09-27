-- CC : add spider spawner to spiderhat >> [Reward] expertwebber1
if not chasni_getperkexcludeconfig("expertwebber1") then
    if TheNet:GetIsServer() then
        local spidertypes = { "hider", "warrior", "spitter", "dropper", "moon", "healer", "water", "poison"}
        AddPrefabPostInit("spiderhat", function(inst)
            if inst.components.equippable then
                local _OnEquip = inst.components.equippable.onequipfn
                local new_OnEquip = function(_inst, owner, ...)
                    if _inst.spidersummoner then
                        _inst.spidersummoner:Cancel()
                    end
                    local isAchieve = owner and owner.components.allachivcoin and owner.components.allachivcoin.expertwebber1
                    if isAchieve then
                        _inst.spidersummoner = _inst:DoPeriodicTask(10, function(__inst)
                            local owner_ = __inst.components.inventoryitem:GetGrandOwner()
                            if owner_ then
                                local pos = owner_:GetPosition()
                                local offset = FindValidPositionByFan((owner_.Transform:GetRotation()+(math.random(-100,100)*0.01*30))*(PI/180), -1, 10, function() return true end)
                                local fx = SpawnPrefab("spider_mutate_fx")
                                local allowedSpider = {"spider"}
                                for _, mask_type in ipairs(spidertypes) do
                                    local mutatorname = mask_type == "poison" and  "chasni_mutator_poison" or "mutator_" .. mask_type
                                    if owner_.components.builder and owner_.components.builder:KnowsRecipe(mutatorname) then
                                        table.insert(allowedSpider, "spider_" .. mask_type)
                                    end
                                end
                                local s = GetRandomItem(allowedSpider)
                                local spider = SpawnPrefab(s)
                                if spider then
                                    if offset then
                                        spider.Transform:SetPosition((pos+offset):Get())
                                        fx.Transform:SetPosition((pos+offset):Get())
                                    else
                                        spider.Transform:SetPosition(pos:Get())
                                        fx.Transform:SetPosition(pos:Get())
                                    end
                                    if spider.components.spiderpackmember then
                                        spider.components.spiderpackmember:MakeMember(__inst, owner_)
                                    end
                                end
                            end
                        end)
                    end
                    if _OnEquip then
                        _OnEquip(_inst, owner, ...)
                    end
                end
                local _OnUnequip = inst.components.equippable.onunequipfn
                local new_OnUnequip = function(_inst, owner, ...)
                    if _inst.spidersummoner then
                        _inst.spidersummoner:Cancel()
                    end
                    if _OnUnequip then
                        _OnUnequip(_inst, owner, ...)
                    end
                end
                inst.components.equippable:SetOnEquip(new_OnEquip)
                inst.components.equippable:SetOnUnequip(new_OnUnequip)
            end
        end)
    end
end

-- CC : set fluffy loyalty to always 100% >> [Reward] expertwebber2
if not chasni_getperkexcludeconfig("expertwebber2") then
    AddComponentPostInit("follower", function(self)
        local OldGetLoyaltyPercent = self.GetLoyaltyPercent
        self.GetLoyaltyPercent = function(...)
            if self.inst and self.inst:HasTag("fluffy") then
                return 1
            else
                return OldGetLoyaltyPercent(self, ...)
            end
        end
    end)
end
