local PlayerPoisonable = Class(function(self, inst)
    self.inst = inst
    self.poisondamage = 0
    self.interval = 10
    self.updating = false
    self.lastDamageTime = 0
    self.poisonfx = nil
end)

function PlayerPoisonable:Poison(interval)
    if self.inst:HasTag("weremoose")  or self.inst:HasTag("weregoose")  or self.inst:HasTag("beaver")  or self.inst:HasTag("playerghost")  or self.inst:HasTag("playerpoisonimmunity") then
        return
    end

    self.poisondamage = -2
    self.interval = interval or self.interval <= 1 and self.interval or self.interval - 0.5

    if not self.updating then
        self.updating = true
        self.inst:StartUpdatingComponent(self)
    end

    if not self.poisonfx then
        self.poisonfx = SpawnPrefab("poisonfx")
        local comp = self.inst.components
        if comp.burnable and #comp.burnable.fxdata > 0 then
            local symbol = comp.burnable.fxdata[1].follow
            if symbol then
                self.poisonfx.Follower:FollowSymbol(self.inst.GUID,symbol,0,0,0)
            end
        end
    end
end

function PlayerPoisonable:WearOff()
    self.poisondamage = 0
    self.interval = 10
    self.lastDamageTime = 0

    self.inst:StopUpdatingComponent(self)
    self.updating = false

    if self.poisonfx then
        self.poisonfx:Remove()
        self.poisonfx = nil
    end
end

function PlayerPoisonable:OnUpdate(dt)
    if self.inst:HasTag("weremoose")  or self.inst:HasTag("weregoose")  or self.inst:HasTag("beaver")  or self.inst:HasTag("playerghost")  or self.inst:HasTag("playerpoisonimmunity") then
        self:WearOff()
    end

    self.lastDamageTime = self.lastDamageTime - dt
    if self.inst.components.health and self.lastDamageTime <= 0 then
        self.inst.components.health:DoDelta(self.poisondamage, nil, "poison")
        self.lastDamageTime = self.interval
        self.inst:PushEvent("playerpoisondamage")
        if self.inst.player_classified then
            self.inst.player_classified.playerpoisonover:set_local(true)
            self.inst.player_classified.playerpoisonover:set(true)
        end
    end
end

function PlayerPoisonable:OnLoad(data)
    if data.interval and data.poisondamage ~= 0 then
        self:Poison(data.interval)
    end
    if data.lastDamageTime then
        self.lastDamageTime = data.lastDamageTime
    end
end

function PlayerPoisonable:OnSave()
    return {
        interval = self.interval,
        poisondamage = self.poisondamage or 0,
        lastDamageTime = self.lastDamageTime
    }
end

return PlayerPoisonable
