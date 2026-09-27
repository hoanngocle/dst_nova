local Badge = require('widgets/badge')
local Text = require('widgets/text')
local Net = require('nyx/skillnet')

local Resource = Class(Badge, function(self, owner)
    Badge._ctor(self, nil, owner, {.35, .68, 1, 1}, nil, true)
    self.owner = owner
    self.circleframe:GetAnimState():OverrideSymbol(
        'frame_circle', 'status_xd_htz_lq', 'frame_circle')
    self.num:Show()
    self.num:SetScale(.72)
    self.num:SetPosition(0, -2, 0)
    self.label = self:AddChild(Text(BODYTEXTFONT, 17, 'Linh Lực'))
    self.label:SetPosition(0, -42, 0)
    self.label:SetColour(.75, .85, 1, 1)
    self:StartUpdating()
end)

function Resource:OnUpdate()
    local s = Net.Read(self.owner)
    if s.ready then
        local maximum = math.max(1, s.maximum or 0)
        local current = math.max(0, math.min(maximum, s.current or 0))
        self:SetPercent(current / maximum, maximum)
        self:SetHoverText(string.format(
            'Linh Lực %d / %d\n%s · Cấp %d\nHồi %d/s · Thuấn Ảnh: %ds',
            current, maximum, s.realm_label or '', s.level or 0,
            s.regen or 0, math.ceil(s.blink_cd or 0)))
    else
        self:SetPercent(0, 1)
        self.num:SetString('—')
        self:SetHoverText(s.reason or 'Đang nạp dữ liệu')
    end
end

function Resource:OnLoseFocus()
    Badge.OnLoseFocus(self)
    self.num:Show()
end

return Resource
