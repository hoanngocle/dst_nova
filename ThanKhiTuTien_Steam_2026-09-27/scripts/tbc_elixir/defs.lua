local M = {LIMIT=10, ORDER={'power','health','mana','guard','speed','crit'}}
M.BY_KEY = {
    power={name='Linh Dược Sức Mạnh',icon='hh_thuoc_suc_manh',anim='idle_suc_manh',
        stat='trueDamageNum',gain=50,effect='criticalHitEffect',effect_value=50,
        description='+50 sát thương chuẩn mỗi lần. Đủ 10: +50 điểm % sát thương bạo kích.',
        ingredients={{'dragon_scales',1},{'redgem',2},{'xd_lingshi3',5}}},
    health={name='Linh Dược Sinh Mệnh',icon='hh_thuoc_sinh_menh',anim='idle_sinh_menh',
        stat='health',gain=50,immunity='hot',recovery=true,
        description='+50 máu tối đa mỗi lần. Đủ 10: miễn quá nóng; lần sau hồi 100 máu.',
        ingredients={{'royal_jelly',2},{'yellowgem',2},{'xd_lingshi3',5}}},
    mana={name='Linh Dược Ma Lực',icon='hh_thuoc_ma_luc',anim='idle_ma_luc',
        stat='mana',gain=50,immunity='cold',recovery=true,
        description='+50 linh lực tối đa mỗi lần. Đủ 10: miễn quá lạnh; lần sau hồi 100 linh lực.',
        ingredients={{'deerclops_eyeball',1},{'bluegem',2},{'xd_lingshi3',5}}},
    guard={name='Linh Dược Hộ Thể',icon='hh_thuoc_ho_the',anim='idle_ho_the',
        stat='reduceAttackedDamage',gain=50,immunity='sleep',
        description='+50 giảm sát thương cố định mỗi lần. Đủ 10: miễn bị cưỡng ép ngủ.',
        ingredients={{'bearger_fur',1},{'orangegem',2},{'xd_lingshi3',5}}},
    speed={name='Linh Dược Phong Tốc',icon='hh_thuoc_phong_toc',anim='idle_phong_toc',
        stat='speed',gain=2,immunity='poison',
        description='+2% tốc chạy mỗi lần. Đủ 10: miễn độc theo cơ chế Solo/Thần Khí.',
        ingredients={{'goose_feather',3},{'greengem',2},{'xd_lingshi3',5}}},
    crit={name='Linh Dược Bạo Kích',icon='hh_thuoc_bao_kich',anim='idle_bao_kich',
        stat='criticalHitEffect',gain=10,immunity='freeze',
        description='+10 điểm % sát thương bạo kích mỗi lần. Đủ 10: miễn đóng băng.',
        ingredients={{'xd_fs',1},{'xd_qlr',1},{'purplegem',2},{'xd_lingshi3',5}}},
}
M.BY_PREFAB = {}
for key, row in pairs(M.BY_KEY) do
    row.prefab='tbc_elixir_'..key
    row.atlas='images/potions/'..row.icon..'.xml'
    M.BY_PREFAB[row.prefab]=key
end
return M
