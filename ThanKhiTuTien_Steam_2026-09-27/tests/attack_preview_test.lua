package.path="ThanKhiTuTien_Steam_2026-09-27/scripts/?.lua;"..package.path
local Combat=require("tbc_combat")
assert(type(Combat.PreviewAttack)=="function", "read-only attack preview must exist")
local values={addComDamage=20,addComDamagePercent=20,moreDamage30To150=150,trueDamageNum=15}
local player={components={tbc_player_effects={
    Get=function(_,k) return values[k] or 0 end,
    Has=function(_,k) return (values[k] or 0)>0 end}}}
local random=math.random
math.random=function() error("opening information must never consume combat RNG") end
local result=Combat.PreviewAttack(player,nil,310)
math.random=random
assert(math.abs(result.damage-396)<.001)
assert(result.pierce_percent==10)
assert(values.addComDamage==20, "preview does not consume effects")
print("attack_preview_test: ok")
