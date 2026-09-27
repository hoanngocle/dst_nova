local Widget = require("widgets/widget")
local Text = require("widgets/text")

local Popup = Class(Widget, function(self, label, kind, critical, pos, duration, spread, index, count)
    Widget._ctor(self, "ThanKhiDamagePopup")
    local colours = require("tbc_damage_style").COLOURS
    self.colour = colours[kind] or colours.normal
    self.text = self:AddChild(Text(NUMBERFONT, critical and 54 or 35, label))
    self.pos = pos
    self.duration = duration
    self.age = 0
    index = type(index) == "number" and index or 1
    count = type(count) == "number" and count or 1
    local distance = math.min(2, math.max(.5, spread or 1))
    self.x = (index - (count + 1) / 2) * 18
    self.y = 48 + (index - 1) * 22
    self.dx = (math.random() < .5 and -1 or 1) * 10 * distance
    self.rise = 56 * distance
    self:SetClickable(false)
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:StartUpdating()
    self:OnUpdate(0)
end)

function Popup:OnUpdate(dt)
    self.age = self.age + dt
    if self.age >= self.duration then
        self:Kill()
        return
    end
    local progress = self.age / self.duration
    local alpha = math.min(1, self.age * 8, (1 - progress) * 4)
    self.text:SetColour(self.colour[1], self.colour[2], self.colour[3], alpha)
    self:SetPosition(TheSim:GetScreenPos(self.pos:Get()))
    self.text:SetPosition(self.x + self.dx * progress,
        self.y + self.rise * progress)
end

return Popup
