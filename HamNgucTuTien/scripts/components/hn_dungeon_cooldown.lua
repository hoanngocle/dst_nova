local Cooldown=Class(function(self,inst) self.inst=inst;self.until_time=0 end)
function Cooldown:StartTimer(seconds) self.until_time=GetTime()+math.max(0,tonumber(seconds) or 0) end
function Cooldown:GetTime() return math.max(0,self.until_time-GetTime()) end
function Cooldown:OnSave() return {remaining=self:GetTime()} end
function Cooldown:OnLoad(data) self:StartTimer(data and data.remaining or 0) end
return Cooldown
