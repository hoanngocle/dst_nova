package.path = 'Nyx_Steam_2026-09-27/scripts/?.lua;' .. package.path

local widget
require('nyx/huaxia_layout').Install(function(name, callback)
    assert(name == 'widgets/containerwidget')
    widget = {
        x = 0, y = 0, z = 0,
        GetPosition = function(self) return {x = self.x, y = self.y, z = self.z} end,
        SetPosition = function(self, x, y, z) self.x, self.y, self.z = x, y, z end,
        Open = function(self, container)
            local pos = container.replica.container:GetWidget().pos
            self:SetPosition(pos.x, pos.y, pos.z)
            return 'opened'
        end,
    }
    callback(widget)
end)

local config = {
    pos = {x = -50, y = 12, z = 3},
    slotpos = {{x = -32}, {x = 32}},
}
local container = {
    prefab = 'xd_luoshen_huaxia',
    replica = {container = {GetWidget = function() return config end}},
}

assert(widget:Open(container, {prefab = 'nyx'}) == 'opened')
assert(widget.x == 10 and widget.y == 12 and widget.z == 3,
    'Nyx Huaxia panel should use its current offset and preserve Y/Z')
assert(config.pos.x == -50, 'shared container config must not change')

assert(widget:Open(container, {prefab = 'wilson'}) == 'opened')
assert(widget.x == -50, 'other characters should retain the container position')

print('Huaxia panel offset applies only to Nyx')
