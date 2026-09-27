local ClusterCraftBuild = Class(function(self, inst)
    self.inst = inst
    self.prefab = nil
    self.size = nil
    self.seed = nil
    self.spacing = 3.2
end)

function ClusterCraftBuild:InitCondition(prefab, seed, size, spacing)
    self.prefab = prefab
    self.size = size
    self.seed = seed
    self.spacing = spacing
end

local function PlantIt(self, spawnpt, builder)
    local seedprefab = self.seed
    for _, v in pairs(spawnpt) do
        builder:DoTaskInTime(0, function()
            local seed = SpawnPrefab(seedprefab)
            if seed then
                seed.Transform:SetPosition(v.x, v.y, v.z)
                if seed.components.deployable then
                    seed.components.deployable:Deploy(Point(v.x, v.y, v.z), builder)
                end
            end
        end)
    end
end

function ClusterCraftBuild:BuildCluster(node, builder)
    local offset = self.spacing
    local refpt = Vector3(node.Transform:GetWorldPosition())
    local xshift, zshift = (self.size/2 - 0.5), (self.size/2 - 0.5)
    local xstart, zstart = (refpt.x - xshift - (xshift * offset)), (refpt.z - zshift - (zshift * offset))
    local spawn_pts= {}
    for kz = 0, self.size - 1, 1 do
        local osx, osz = offset, offset
        for kx = 0, self.size - 1, 1 do
            table.insert(spawn_pts, { x = (xstart + (kx * osx) + kx), y = (refpt.y), z = (zstart + (kz * osz) + kz) })
        end
    end

    PlantIt(self, spawn_pts, builder)
end

return ClusterCraftBuild