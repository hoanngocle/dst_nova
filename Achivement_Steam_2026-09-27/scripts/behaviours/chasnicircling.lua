ChasniCircling = Class(BehaviourNode, function(self, inst, get_target_fn, radius)
    BehaviourNode._ctor(self, "ChasniCircling")
    self.inst = inst
    self.get_target_fn = get_target_fn
    self.radius = 20
    if inst._circlingangle then
        self.angle               = inst._circlingangle
        inst._circlingangle      = nil
    else
        self.angle               = math.random() * 2 * PI
    end
end)

function ChasniCircling:__tostring()
    local target = self.get_target_fn and self.get_target_fn()
    return string.format("CIRCLING %f from: %s", self.radius, target and target.prefab or "none")
end

function ChasniCircling:Visit()
    local target = self.get_target_fn()
    if not target or not target:IsValid() then
        self.status = FAILED
        return
    end

    if self.status == READY then
        self.status = RUNNING
    end

    -- advance the angle
    self.angle = (self.angle + 0.03) % (2 * PI)

    -- compute circle point
    local tx, ty, tz = target.Transform:GetWorldPosition()
    local x = tx + self.radius * math.cos(self.angle)
    local z = tz + self.radius * math.sin(self.angle)

    self.inst.components.locomotor:GoToPoint(Vector3(x, 0, z))
    self.status = RUNNING
end

return ChasniCircling
