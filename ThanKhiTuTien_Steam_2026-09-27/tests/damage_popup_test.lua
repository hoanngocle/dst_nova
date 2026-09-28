package.path = "ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;" .. package.path

local Widget = {}
function Widget._ctor(self, name) self.name = name end
function Widget:AddChild(child) return child end
function Widget:SetClickable() end
function Widget:SetScaleMode() end
function Widget:StartUpdating() end
function Widget:SetPosition(x, y)
    assert(type(x) == "number" and type(y) == "number", "widget position needs numeric x and y")
    self.position_x, self.position_y = x, y
end
function Widget:Kill() self.killed = true end

local Text = {}
setmetatable(Text, { __call = function(_, font, size, label)
    return setmetatable({ font = font, size = size, label = label }, { __index = Text })
end })
function Text:SetColour() end
function Text:SetPosition(x, y) self.position_x, self.position_y = x, y end

package.preload["widgets/widget"] = function() return Widget end
package.preload["widgets/text"] = function() return Text end

function Class(base, constructor)
    local cls = setmetatable({}, { __index = base })
    cls.__index = cls
    return setmetatable(cls, {
        __index = base,
        __call = function(_, ...)
            local instance = setmetatable({}, cls)
            constructor(instance, ...)
            return instance
        end,
    })
end

NUMBERFONT = "numberfont"
SCALEMODE_PROPORTIONAL = 1
local screen_x, screen_y = 320, 240
TheSim = { GetScreenPos = function(_, x, y, z)
    assert(x == 1 and y == 2 and z == 3, "popup projects the world position")
    return screen_x, screen_y
end }

local Popup = require("widgets/tbc_damage_popup")
local world_pos = { Get = function() return 1, 2, 3 end }
local popup = Popup("50", "normal", false, world_pos, 2, 1, 1, 1)
assert(popup.anchor_x == 320 and popup.anchor_y == 240, "popup anchors at projected coordinates")
assert(popup.position_x == 320 and popup.position_y == 240, "widget starts at projected coordinates")
assert(popup.screen_x == 320 and popup.screen_y == 288, "popup starts above the target")

screen_x, screen_y = 400, 300
popup:OnUpdate(1)
assert(popup.position_x == 400 and popup.position_y == 300, "widget follows the target")
assert(popup.screen_y == 376, "popup rises while following the target")

popup:Kill()
print("damage_popup_test: ok")
