test('cooldown persists remaining time without gaining offline time',function()
    local a=require('support/dst_mock').Install()
    local p=a.player();local cd=p.components.hn_dungeon_cooldown
    cd:StartTimer(960);a.advance(60);assert(cd:GetTime()==900)
    local data=cd:OnSave();local p2=a.player();p2.components.hn_dungeon_cooldown:OnLoad(data)
    assert(p2.components.hn_dungeon_cooldown:GetTime()==900)
    a.advance(901);assert(cd:GetTime()==0)
end)
