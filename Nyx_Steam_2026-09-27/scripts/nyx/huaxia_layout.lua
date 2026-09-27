local M = {}

function M.Install(add_class_post_construct)
    add_class_post_construct('widgets/containerwidget', function(widget)
        local open = widget.Open
        widget.Open = function(self, container, doer)
            if container ~= nil and container.prefab == 'xd_luoshen_huaxia'
                and container.replica ~= nil and container.replica.container ~= nil then
                local config = container.replica.container:GetWidget()
                if config ~= nil and not config._nyx_backpack_aligned then
                    local original_pos = config.pos
                    local original_posfn = config.posfn
                    local backpack = require('containers').params.backpack
                    local backpack_pos = backpack ~= nil and backpack.widget ~= nil
                        and backpack.widget.pos or nil
                    if backpack_pos ~= nil then
                        config._nyx_backpack_aligned = true
                        config.posfn = function(item, player)
                            local pos = original_posfn ~= nil
                                and original_posfn(item, player) or original_pos
                            if pos == nil or player == nil or player.prefab ~= 'nyx' then
                                return pos
                            end
                            return Vector3(backpack_pos.x, pos.y, pos.z)
                        end
                    end
                end
            end
            return open(self, container, doer)
        end
    end)
end

return M
