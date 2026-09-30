test('Tu Tien reward rolls obey tier boundary and fallback',function()
    local rewards=require('hn_dungeon/rewards')
    local exists=function() return true end
    local yes=function() return .49 end;local no=function() return .5 end
    assert(rewards.Roll('monster',1,yes,exists)[1].count==1)
    assert(rewards.Roll('monster',2,yes,exists)[1].count==2)
    assert(#rewards.Roll('monster',1,no,exists)==0)
    local hard=rewards.Roll('boss',2,yes,exists)
    assert(hard[1].prefab=='xd_lingshi3' and hard[1].count==2 and hard[2].prefab=='ttk_huyen_tinh_trung_pham')
    local fallback=rewards.Roll('boss',2,yes,function(n) return not n:find('huyen_tinh') end)
    assert(fallback[2].prefab=='xd_lingshi1' and fallback[2].count==20)
end)
test('clear rewards ignore old run and duplicated clear event',function()
    local a=require('support/dst_mock').Install();local rewards=require('hn_dungeon/rewards');local calls=0
    local spawn=SpawnPrefab
    SpawnPrefab=function(n) calls=calls+1;local e=spawn(n);e.components.container={GiveItem=function() return true end};return e end
    local m={run_epoch=2,is_cleared=true,max_waves=3,Track=function(_,e) return e end,Schedule=function() end}
    assert(not rewards.GrantClear(m,1,{x=0,z=0}) and calls==0)
    assert(rewards.GrantClear(m,2,{x=0,z=0}));local n=calls
    assert(not rewards.GrantClear(m,2,{x=0,z=0}) and calls==n)
end)
