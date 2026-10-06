local E=require('nyx/effects')
local function componentHandle(inst,name,start,done)
    local c=inst.components[name]
    if not c then return nil,'Thiếu bộ xử lý kỹ năng.' end
    local h={}
    function h:Start() return start(c) end
    function h:Cancel(reason) c:Stop(reason) end
    function h:IsDone() return done(c) end
    return h
end
E.Register('absolute_domain',function(inst)
    return componentHandle(inst,'nyx_domain',function(c) return c:Activate() end,function(c) return not c.active end)
end)
E.Register('purple_gather',function(inst,p)
    return componentHandle(inst,'nyx_gather',function(c) return c:CastAt(p.x,p.z) end,function(c) return c.controller==nil end)
end)
for _,id in ipairs({'triflame_fan','eternal_night','spirit_sword','bean_soldiers'}) do
    local skill=id
    E.Register(skill,function(inst,p) return require('nyx/attack18').Prepare(inst,skill,p) end)
end
for _,id in ipairs({'purple_eye','moon_wings'}) do
    local skill=id
    E.Register(skill,function(inst) return require('nyx/utility18').Prepare(inst,skill) end)
end
E.Register('yellow_river',function(inst) return require('nyx/yellow_river').Prepare(inst) end)
return true
