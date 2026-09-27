local Life=require('util/nyx_domain_common')
local T={}
function T.CanDamage(owner,target)
    return Life.IsValidTarget(owner,target,nil)
end
function T.Find(owner,x,z,radius)
    local result={}
    for _,v in ipairs(TheSim:FindEntities(x,0,z,radius,{'_combat','_health'},{'INLIMBO','FX','playerghost'})) do
        if T.CanDamage(owner,v) then result[#result+1]=v end
    end
    return result
end
function T.Nearest(owner,x,z,radius)
    local best,distance
    for _,target in ipairs(T.Find(owner,x,z,radius)) do
        local tx,_,tz=target.Transform:GetWorldPosition()
        local d=(tx-x)^2+(tz-z)^2
        if not distance or d<distance then best,distance=target,d end
    end
    return best
end
return T
