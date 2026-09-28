local Widget = require("widgets/widget")
local Text = require("widgets/text")
local active = {}
local ROW_GAP = 64

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
    local screen = TheSim:GetScreenPos(pos:Get())
    self.anchor_x, self.anchor_y = screen.x, screen.y
    self.y = 48
    local next_y = screen.y + self.y
    for _, other in ipairs(active) do
        if math.abs(other.anchor_x - screen.x) < 100
            and math.abs(other.anchor_y - screen.y) < 90
            and math.abs(other.screen_x - screen.x - self.x) < 100 then
            next_y = math.min(next_y, other.screen_y - ROW_GAP)
        end
    end
    self.y = next_y - screen.y
    self.dx = (math.random() < .5 and -1 or 1) * 10 * distance
    self.rise = 56 * distance
    self:SetClickable(false)
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:StartUpdating()
    self:OnUpdate(0)
    active[#active + 1] = self
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
    local screen = TheSim:GetScreenPos(self.pos:Get())
    self:SetPosition(screen)
    local x = self.x + self.dx * progress
    local y = self.y + self.rise * progress
    self.text:SetPosition(x, y)
    self.screen_x, self.screen_y = screen.x + x, screen.y + y
end

function Popup:Kill()
    for index, other in ipairs(active) do
        if other == self then
            table.remove(active, index)
            break
        end
    end
    Widget.Kill(self)
end

return Popup
