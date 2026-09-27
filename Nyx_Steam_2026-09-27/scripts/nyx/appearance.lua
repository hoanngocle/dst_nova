-- Full player builds from Tu Tien. Item skins, effects and death-only builds
-- are intentionally absent: they cannot be used as a player appearance.
local groups = {
    { name = "Trần Bình An", builds = { "xd_chenpingan", "xd_chenpingan_hphz", "xd_chenpingan_shadow" } },
    { name = "Hàn Lập", builds = { "xd_hantianzun", "xd_hantianzun_qh", "xd_hantianzun_qzxx", "xd_hantianzun_zymj" } },
    { name = "Tinh Vệ", builds = { "xd_jingwei", "xd_jingwei_clys", "xd_jingwei_dfjm", "xd_jingwei_fenice3", "xd_jingwei_fenice3_gxsl", "xd_jingwei_gxsl" } },
    { name = "Long Thái Tử", builds = { "xd_longtaizi", "xd_longtaizi_hysj", "xd_longtaizi_nl" } },
    { name = "Lạc Thần", builds = { "xd_luoshen", "xd_luoshen_mksny" } },
    { name = "Thạch Cơ", builds = { "xd_shiji", "xd_shiji_jyxx", "xd_shiji_kl" } },
    { name = "Đát Kỷ", builds = { "xd_sudaji", "xd_sudaji_gstx", "xd_sudaji_qrsy", "xd_sudaji_qsdc", "xd_sudaji_wcgz" } },
    { name = "Vương Ma Tử", builds = { "xd_wangmazi", "xd_wangmazi_jxgs", "xd_wangmazi_tymh" } },
    { name = "Ngộ Không", builds = { "xd_wukong", "xd_wukong_ds", "xd_wukong_hsmy", "xd_wukong_sxz" } },
    { name = "Vân Tiêu", builds = { "xd_yunxiao", "xd_yunxiao_msnzs", "xd_yunxiao_zwzy" } },
}

local valid = {}
for _, group in ipairs(groups) do
    for _, build in ipairs(group.builds) do
        valid[build] = true
    end
end

return { groups = groups, valid = valid }
