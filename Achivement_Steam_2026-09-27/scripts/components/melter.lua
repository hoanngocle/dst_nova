local Melter = Class(function(self, inst) 
    self.inst = inst
    self.cooking = false
end, nil, {})

local function dostew(inst)
    local meltercomp = inst.components.melter
    meltercomp.task = nil

    if meltercomp.ondonecooking then
        meltercomp.ondonecooking(inst)
    end

    meltercomp.targettime = nil

    if meltercomp.inst.components.container then
        meltercomp.inst.components.container.canbeopened = true
    end

    local product = inst.components.container:GetItemInSlot(1)
    if product then
        if product.components.weapon and product.components.planardamage == nil then
            product:AddComponent("planardamage")
            product.components.planardamage:SetBaseDamage(15)
            product:AddTag("winona_blessed")
        end
        if product.components.armor and product.components.planardefense == nil then
            product:AddComponent("planardefense")
            product.components.planardefense:SetBaseDefense(20)
            product:AddTag("winona_blessed")
        end
    end

    meltercomp.cooking = nil
end

function Melter:GetTimeToCook()
    if self.cooking then
        return self.targettime - GetTime()
    end
    return 0
end

function Melter:CanCook()
    return self.inst.components.container and self.inst.components.container:IsFull()
end

function Melter:IsCooking()
    return self.targettime
end

function Melter:StartCooking()
    if not self.cooking then
        if self.inst.components.container then
            self.cooking = true

            if self.onstartcooking then
                self.onstartcooking(self.inst)
            end

            local cooktime = 0.2

            local grow_time = TUNING.BASE_COOK_TIME * cooktime
            self.targettime = GetTime() + grow_time
            self.task = self.inst:DoTaskInTime(grow_time, dostew, "stew")

            self.inst.components.container:Close()
            for k = 2, 4 do
                local item = self.inst.components.container:RemoveItemBySlot(k)
                if item then
                    item:Remove()
                end
            end
            self.inst.components.container.canbeopened = false
        end

    end
end

function Melter:OnSave()
    local time = GetTime()
    if self.cooking then
        local data = {}
        data.cooking = true
        if self.targettime and self.targettime > time then
            data.time = self.targettime - time
        end
        return data
    end
end

function Melter:OnLoad(data)
    --self.produce = data.produce
    if data.cooking then
        if self.oncontinuecooking then
            local time = data.time or 1
            self.oncontinuecooking(self.inst)
            self.cooking = true
            self.targettime = GetTime() + time
            self.task = self.inst:DoTaskInTime(time, dostew, "stew")

            if self.inst.components.container then
                self.inst.components.container.canbeopened = false
            end
        end
    end
end

function Melter:GetDebugString()
    local str = nil

    if self.cooking then
        str = "COOKING"
    else
        str = "EMPTY"
    end
    if self.targettime then
        str = str.." ("..tostring(self.targettime - GetTime())..")"
    end
    return str
end

function Melter:StopCooking(reason)
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
    self.targettime = nil
end

function Melter:LongUpdate(dt)
    if not self.paused and self.targettime then
        if self.task then
            self.task:Cancel()
            self.task = nil
        end

        self.targettime = self.targettime - dt

        if self.cooking then
            local time_to_wait = self.targettime - GetTime()
            if time_to_wait < 0 then
                dostew(self.inst)
            else
                self.task = self.inst:DoTaskInTime(time_to_wait, dostew, "stew")
            end
        end
    end
end

return Melter
