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
assert(math.abs(result.pierce_damage-54.6)<.001)
assert(math.abs(result.total_damage-450.6)<.001,
    'the single attack total includes physical and armor-piercing damage once')
player.HasTag=function(_,tag) return tag=='player' end
local actual_damage,actual_pierce
local victim={components={health={IsDead=function() return false end}},
    HasTag=function() return false end}
local combat={inst=victim,GetAttacked=function(_,_,damage,_,_,packet)
    actual_damage=damage
    actual_pierce=packet and packet.tbc_armor_pierce or 0
    return true
end}
Combat.Install(combat,true,function() return 1 end)
assert(combat:GetAttacked(player,310))
assert(math.abs(actual_damage+actual_pierce-result.total_damage)<.001,
    'preview total matches the actual combat packet before target defense')
assert(values.addComDamage==20, "preview does not consume effects")
print("attack_preview_test: ok")
