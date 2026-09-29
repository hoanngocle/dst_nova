local M = {}
local HORIZONTAL_OFFSET = 60 -- Shift Nyx's Hoa Ha panel from its own default position.

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

            local pos = self:GetPosition()
            self:SetPosition(pos.x + HORIZONTAL_OFFSET, pos.y, pos.z)

            return result
        end
    end)
end

return M
