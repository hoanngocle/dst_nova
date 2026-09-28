local M = {}

-- Increase this value to move the Lạc Thần Hoa backpack farther left.
local RIGHT_EDGE_PADDING = 25
local SLOT_HALF_WIDTH = 38

function M.Install(add_class_post_construct)
    add_class_post_construct('widgets/containerwidget', function(widget)
        local open = widget.Open
        widget.Open = function(self, container, doer)
            local result = open(self, container, doer)

            if container == nil or container.prefab ~= 'xd_luoshen_huaxia'
                or doer == nil or doer.prefab ~= 'nyx'
                or container.replica == nil or container.replica.container == nil then
                return result
            end

            local config = container.replica.container:GetWidget()
            if config == nil then
                return result
            end

            local right_edge = 0
            local slotpos = config.slotposfn ~= nil
                and config.slotposfn(container, doer) or config.slotpos
            for _, slot in ipairs(slotpos or {}) do
                right_edge = math.max(right_edge, slot.x + SLOT_HALF_WIDTH)
            end

            if self.bgimage ~= nil and self.bgimage.texture ~= nil then
                local width = self.bgimage:GetSize()
                right_edge = math.max(right_edge, width / 2)
            end

            local pos = self:GetPosition()
            local x = math.min(pos.x, -right_edge - RIGHT_EDGE_PADDING)
            if x < pos.x then
                self:SetPosition(x, pos.y, pos.z)
            end

            return result
        end
    end)
end

return M
