GLOBAL.setmetatable(env,{__index=function(_,k) return GLOBAL.rawget(GLOBAL,k) end})

STRINGS.GUI = {
    ["complA"] = "Hoàn thành Thành tựu [",
    ["br2"] = "]",
    ["space"] = "   ",
    ["obt"] = "Nhận. ",
    ["points"] = " Điểm",
    ["br1"] = "[",
    ["viewA"] = "Xem thành tựu",
    ["viewR"] = "Xem phần thưởng",
    ["viewT"] = "Xem nhiệm vụ",
    ["viewL"] = "Xem cấp độ",
    ["comp"] = "Hoàn thành: ",
    ["obta"] = "Đã nhận: x",
    ["dgnfly"] = "Dragonfly:",
    ["bqueen"] = "Bee Queen:",
    ["mallbt"] = "Malbatross:",
    ["crabkg"] = "Crab King:",
    ["ancgua"] = "Ancient Guardian:",
    ["ancfue"] = "Ancient Fuelweaver:",
    ["sknig"] = "Knight:",
    ["sbish"] = "Bishop:",
    ["srook"] = "Rook:",
    ["twin1"] = "Retinazor:",
    ["twin2"] = "Spazmatism:",
    ["werep1"] = "Nightmare Werepig:",
    ["werep2"] = "Scrappy Werepig:",
    ["season1"] = "Moose/Goose:",
    ["season2"] = "Antlion:",
    ["season3"] = "Bearger:",
    ["season4"] = "Deerclops:",
    ["mutated1"] = "Varg:",
    ["mutated2"] = "Bearger:",
    ["mutated3"] = "Deerclops:",
    ["set"] = "Cài đặt",
    ["zoomI"] = "Phóng to",
    ["zoomO"] = "Thu nhỏ",
    ["minim"] = "Đổi giao diện tối giản",
    ["achievementTitle"] = "Sao thành tựu",
    ["taskTitle"] = "Nhiệm vụ mùa",
    ["levelTitle"] = "Cấp độ",
    ["petlevelTitle"] = "Cấp thú cưng",
    ["achievementInfo"] = "Theo dõi tiến độ thành tựu và nhận Sao.",
    ["perkInfo-attributes"] = "Tăng chỉ số cơ bản. Có thể nhận nhiều lần; giá tăng sau mỗi lần nhận.",
    ["perkInfo-abilities"] = "Mở khả năng bị động mạnh với chi phí cao hơn.",
    ["perkInfo-expert"] = "Đặc quyền gắn với vai trò của từng nhân vật.",
    ["perkInfo-expert2"] = "Đặc quyền gắn với vai trò của từng nhân vật.",
    ["perkInfo-expert3"] = "Đặc quyền gắn với vai trò của từng nhân vật.",
    ["perkInfo-crafting"] = "Mở công thức chế tạo khi nhận.",
    ["perkInfo-global"] = "Tác động đến toàn thế giới hiện tại và không thể đặt lại.",
    ["taskInfo"] = "Mỗi mùa có tối đa 4 lượt. Mỗi lượt phát 6 nhiệm vụ ngẫu nhiên và làm mới quà sau khi nhận đủ.",
    ["close"] = "Đóng",
    ["resetR"] = "Đặt lại đặc quyền",
    ["resetL"] = "Đặt lại thuộc tính",
    ["reset"] = "Đặt lại",
    ["levelPet"] = "Cấp thú cưng",
    ["levelPlayer"] = "Cấp nhân vật",
    ["petEvolve"] = "Tiến hóa",
    ["resetinfo"] = "Đặt lại sẽ xóa tất cả nâng cấp và hoàn lại "..math.ceil(reset_refund_percentage*100).."% điểm. Bạn cũng nhận được một hình phạt sức khỏe tạm thời.",
    ["claimtask"] = "Nhận tất cả",
    ["taskRound"] = "Lượt %d/4",
    ["taskSeasonFinished"] = "Đã hoàn tất 4 lượt. Hãy chờ mùa mới để nhận nhiệm vụ tiếp theo.",
    ["taskRewardPending"] = "Hoàn thành đủ nhiệm vụ để mở quà ngẫu nhiên.",
    ["taskinfo"] = "Hoàn thành 1, 2, 4 và 6 nhiệm vụ để mở bốn rương. Rương cuối luôn có 1 Star.",
    ["unknowntask"] = "Nhiệm vụ đã hết hạn.",
    ["food"] = "Ăn",
    ["life"] = "Sống",
    ["hurt"] = "Sát thương",
    ["work"] = "Làm",
    ["have"] = "Có",
    ["stat"] = "Chỉ số",
    ["bond"] = "Thích",
    ["talk"] = "Tương tác",
    ["vile"] = "Hèn",
    ["slay"] = "Giết",
    ["slay2"] = "Giết2",
    ["duel"] = "Săn",
    ["boss"] = "Trùm",
    ["misc"] = "Khác",
    ["mile"] = "Đi",
    ["task"] = "Nhiệm vụ",
    ["attributes"] = "Thuộc tính",
    ["abilities"] = "Khả năng",
    ["expert"] = "Chuyên môn",
    ["expert2"] = "Chuyên môn 2",
    ["expert3"] = "Chuyên môn 3",
    ["crafting"] = "Sản xuất",
    ["global"] = "Toàn cầu",
    ["attributelabels"] = "Độ no:\nTỉnh táo:\nMáu:\nSát thương:\nPhòng thủ:\nTốc độ:\n",
    ["attributeunits"] = "\n\n\n\n%\n%\n%\n",
    ["petattributelabels"] = "Tốc độ:\nSát thương:\nHồi đòn:\nHồi phép:\nSức mạnh phép:\nBị động:\n",
    ["petattributeunits"] = "\ns\ns\n\n\n\n\n",
    ["levelinfo"] = "Nâng cấp được áp dụng cho các giá trị mặc định trừ vật phẩm.\nGiá trị hiển thị ở đây là giá trị cuối cùng sau khi áp dụng tất cả các hiệu ứng.",
    ["availablePoints"] = "Điểm Khả dụng: ",
    ["overallxp"] = "Tổng kinh nghiệm: ",
    ["giantplant"] = "Danh sách cây khổng lồ",
    ["oceanfish"] = "Cá đã bắt:",
    ["havebird"] = "Chim còn thiếu:",
    ["glassmaker"] = "Các món đồ thủy tinh",
    ["walkturf"] = "Các loại địa hình đã đi qua",
    ["attributecost"] = "Giá",
    ["attributecurrent"] = "Hiện tại",
}

STRINGS.ACHIEVEMENTS={
    -- # FOOD
    ["supereat"] = {
        ["name"] = "Sành ăn",
        ["description"] = "Đớp "..ach_lists.supereat.current.." đồ ăn",
        ["info"] = "Đớp "..ach_lists.supereat.current.." đồ ăn",
    },
    ["eathot"] = {
        ["name"] = "Đêm Gió Lạnh",
        ["description"] = "Ăn một món ăn để tăng nhiệt",
        ["info"] = "Ăn thức ăn và làm ấm bản thân khỏi bị đóng băng",
    },
    ["eatcold"] = {
        ["name"] = "Ngày Nắng Nóng",
        ["description"] = "Ăn một món ăn để hạ nhiệt",
        ["info"] = "Ăn thức ăn và làm mát bản thân khỏi quá nóng",
    },
    ["eatmandrake"] = {
        ["name"] = "Bú cần lúc 4:20",
        ["description"] = "Ăn Nhân Săm nấu chín",
        ["info"] = "Ăn Nhân Sâm nấu chín",
    },
    ["eatguardianhorn"] = {
        ["name"] = "Hụt tay hở?",
        ["description"] = "Ăn sừng của Ancient Guardian",
        ["info"] = "Ăn sừng của Ancient Guardian",
    },
    ["eatnightberry"] = {
        ["name"] = "Sao mình không phát sáng?",
        ["description"] = "Ăn quả mọng đêm đã nấu chín",
        ["info"] = "Đã ăn quả mọng đêm đã nấu chín",
    },
    ["eatmonsterlasagna"] = {
        ["name"] = "Ngấu nghiến",
        ["description"] = "Ăn "..ach_lists.eatmonsterlasagna.current.." đĩa lasagna quái vật trong 60 giây",
        ["info"] = "Đã ăn "..ach_lists.eatmonsterlasagna.current.." đĩa lasagna quái vật trong 60 giây",
    },
    -- # LIFE
    ["death"] = {
        ["name"] = "Thần chết quá quen",
        ["description"] = "Chết "..ach_lists.death.current.." lần",
        ["info"] = "Chết "..ach_lists.death.current.." lần",
    },
    ["reviveamulet"] = {
        ["name"] = "Hồi quang phản chiếu",
        ["description"] = "Hồi sinh "..ach_lists.reviveamulet.current.." lần bằng bùa hồi sinh",
        ["info"] = "Đã hồi sinh "..ach_lists.reviveamulet.current.." lần bằng bùa hồi sinh",
    },
    -- # HURT
    ["pacifist"] = {
        ["name"] = "Hòa Bình",
        ["description"] = "Không tấn công sinh vật nào trong "..(ach_lists.pacifist.current/60).." phút",
        ["info"] = "Đã không tấn công sinh vật nào trong "..(ach_lists.pacifist.current/60).." phút",
    },
    ["damagedeal"] = {
        ["name"] = "Độc ác",
        ["description"] = "Gây "..ach_lists.damagedeal.current.." sát thương",
        ["info"] = "Gây tổng "..ach_lists.damagedeal.current.." sát thương",
    },
    ["tank"] = {
        ["name"] = "Da dày",
        ["description"] = "Nhận "..ach_lists.tank.current.." sát thương",
        ["info"] = "Nhận tổng "..ach_lists.tank.current.." sát thương",
    },
    ["dmgnodmg"] = {
        ["name"] = "Thánh né",
        ["description"] = "Gây "..(ach_lists.dmgnodmg.current/1000).."k sát thương khi không nhận sát thương",
        ["info"] = "Đã gây "..ach_lists.dmgnodmg.current.." sát thương mà không nhận sát thương",
    },
    ["burn"] = {
        ["name"] = "Nóng cháy đít",
        ["description"] = "Bắt lửa",
        ["info"] = "Bị cháy bởi lửa",
    },
    ["freeze"] = {
        ["name"] = "Lạnh thấu xương",
        ["description"] = "Bị đóng băng",
        ["info"] = "Bị đóng băng",
    },
    ["drown"] = {
        ["name"] = "Sung quanh toàn là nước Êi",
        ["description"] =  "Thử bơi ngoài biển",
        ["info"] = "Chết đuối ngoài biển",
    },
    ["lightning"] = {
        ["name"] = "Trời đánh",
        ["description"] = "Bị đánh trúng bởi sấm sét",
        ["info"] = "Bị đánh trúng bởi sấm sét",
    },
    -- # WORK
    ["plantmaster"] = {
        ["name"] = "Làm vườn",
        ["description"] = "Trồng "..ach_lists.plantmaster.current.." cây hoặc hạt giống",
        ["info"] = "Đã trồng "..ach_lists.plantmaster.current.." cây hoặc hạt giống trên mặt đất",
    },
    ["fishmaster"] = {
        ["name"] = "Ngư ông",
        ["description"] = "Bắt "..ach_lists.fishmaster.current.." cá",
        ["info"] = "Đã bắt "..ach_lists.fishmaster.current.." con cá",
    },
    ["pickmaster"] = {
        ["name"] = "Tích trữ",
        ["description"] = "Thu hoạch "..ach_lists.pickmaster.current.." lần",
        ["info"] = "Thu hoạch "..ach_lists.pickmaster.current.." lần",
    },
    ["chopmaster"] = {
        ["name"] = "Bổ củi",
        ["description"] = "Bổ hoặc đào "..ach_lists.chopmaster.current.." cây",
        ["info"] = "Đã bổ hoặc đào "..ach_lists.chopmaster.current.." cây",
    },
    ["minemaster"] = {
        ["name"] = "Đập đá",
        ["description"] = "Đập đá "..ach_lists.minemaster.current.." lần",
        ["info"] = "Đã đập đá "..ach_lists.minemaster.current.." lần",
    },
    ["cookmaster"] = {
        ["name"] = "Bếp trưởng",
        ["description"] = "Làm "..ach_lists.cookmaster.current.." món ăn nồi hầm",
        ["info"] = "Làm "..ach_lists.cookmaster.current.." món ăn nồi hầm",
    },
    ["buildmaster"] = {
        ["name"] = "Nghệ nhân",
        ["description"] = "Chế tạo "..ach_lists.buildmaster.current.." lần",
        ["info"] = "Đã chế tạo "..ach_lists.buildmaster.current.." lần",
    },
    ["honeymaster"] = {
        ["name"] = "Nuôi ong",
        ["description"] = "Thu hoạch mật ong từ một hộp ong đầy "..ach_lists.honeymaster.current.." lần",
        ["info"] = "Thu hoạch mật ong từ một hộp ong đầy "..ach_lists.honeymaster.current.." lần",
    },
    ["jerkymaster"] = {
        ["name"] = "Phơi nắng",
        ["description"] = "Thu hoạch giàn phơi thịt "..ach_lists.jerkymaster.current.." lần",
        ["info"] = "Đã thu hoạch giàn phơi thịt "..ach_lists.jerkymaster.current.." lần",
    },
    ["flowermaster"] = {
        ["name"] = "Gái bán hoa",
        ["description"] = "Trồng hoa "..ach_lists.flowermaster.current.." lần",
        ["info"] = "Đã trồng hoa "..ach_lists.flowermaster.current.." lần",
    },
    ["fertilizemaster"] = {
        ["name"] = "Bón cây",
        ["description"] = "Bón phân cho cây "..ach_lists.fertilizemaster.current.." lần",
        ["info"] = "bón phân cho cây "..ach_lists.fertilizemaster.current.." lần",
    },
    ["fertilizebigmaster"] = {
        ["name"] = "Bón cây to",
        ["description"] = "Bón phân cho cây lớn "..ach_lists.fertilizebigmaster.current.." lần",
        ["info"] = "Bón phân cho cây lớn "..ach_lists.fertilizebigmaster.current.." lần",
    },
    ["wallmaster"] = {
        ["name"] = "Chủ tịch",
        ["description"] = "Xây tường "..ach_lists.wallmaster.current.." lần",
        ["info"] = "xây tường "..ach_lists.wallmaster.current.." lần",
    },
    ["picktumbleweed"] = {
        ["name"] = "Tấn công trại cỏ",
        ["description"] = "Nhặt "..ach_lists.picktumbleweed.current.." bụi cỏ lăn",
        ["info"] = "Đã nhặt "..ach_lists.picktumbleweed.current.." bụi cỏ lăn",
    },
    -- # HAVE
    ["equipingkrampussack"] = {
        ["name"] = "Phú bà phú ông",
        ["description"] = "Có một túi Krampus",
        ["info"] = "Đã có một túi Krampus",
    },
    ["luckyrabbit"] = {
        ["name"] = "Oswald, chú thỏ may mắn",
        ["description"] = "Có một chú thỏ may mắn",
        ["info"] = "Đã có một chú thỏ may mắn",
    },
    ["iridescentgems"] = {
        ["name"] = "7 Sắc cầu vồng",
        ["description"] = "Chế tạo đá quý bảy màu",
        ["info"] = "Đã chế tạo đá quý bảy màu",
    },
    -- # STAT
    ["fullsanity"] = {
        ["name"] = "Thông thái",
        ["description"] = "Duy trì độ tỉnh táo trên 95% trong "..(ach_lists.fullsanity.current/60).." phút",
        ["info"] = "Đã duy trì độ tỉnh táo trên 95% trong "..(ach_lists.fullsanity.current/60).." phút",
    },
    ["fullhunger"] = {
        ["name"] = "Đầy bụng",
        ["description"] = "Duy trì độ no trên 95% trong "..(ach_lists.fullhunger.current/60).." phút",
        ["info"] = "Đã duy trì độ no trên 95% trong "..(ach_lists.fullhunger.current/60).." phút",
    },
    ["sanitymaxwell"] = {
        ["name"] = "Tâm thần",
        ["description"] = "Duy trì độ tỉnh táo tối đa 50% trong "..(ach_lists.sanitymaxwell.current/60).." phút",
        ["info"] = "Đã duy trì độ tỉnh táo tối đa 50% trong "..(ach_lists.sanitymaxwell.current/60).." phút",
    },
    ["nosanity"] = {
        ["name"] = "Bại não",
        ["description"] = "Điên trong "..(ach_lists.nosanity.current/60).." phút",
        ["info"] = "ở trong trạng thái điên trong "..(ach_lists.nosanity.current/60).." phút",
    },
    ["lunacy"] = {
        ["name"] = "Giác ngộ",
        ["description"] = "Ở trạng thái giác ngộ trong "..(ach_lists.lunacy.current/60).." phút",
        ["info"] = "Đã ở trạng thái giác ngộ trong "..(ach_lists.lunacy.current/60).." phút",
    },
    ["starve"] = {
        ["name"] = "Chết đói cùng nhau",
        ["description"] = "Đói trong "..(ach_lists.starve.current/60).." phút",
        ["info"] = "ở trong trạng thái đói trong "..(ach_lists.starve.current/60).." phút",
    },
    ["icebody"] = {
        ["name"] = "Cô bé bán diêm",
        ["description"] = "Đóng băng trong "..(ach_lists.icebody.current/60).." phút",
        ["info"] = "Vẫn đóng băng trong "..(ach_lists.icebody.current/60).." phút",
    },
    ["firebody"] = {
        ["name"] = "Quá Nhiệt",
        ["description"] = "Quá nhiệt trong "..(ach_lists.firebody.current/60).." phút",
        ["info"] = "Vẫn quá nhiệt trong "..(ach_lists.firebody.current/60).." phút",
    },
    ["moistbody"] = {
        ["name"] = "Con mèo ướt át",
        ["description"] = "Bị ướt trong "..(ach_lists.moistbody.current/60).." phút",
        ["info"] = "Vẫn bị ướt trong "..(ach_lists.moistbody.current/60).." phút",
    },
    -- # BOND
    -- # TALK
    -- # VILE
    ["killbutterfly"] = {
        ["name"] = "Diệt cả lò Bướm",
        ["description"] = "Giết "..ach_lists.killbutterfly.current.." bướm",
        ["info"] = "Giết "..ach_lists.killbutterfly.current.." bướm",
    },
    ["killbird"] = {
        ["name"] = "Chim tuyệt chủng",
        ["description"] = "Giết "..ach_lists.killbird.current.." chim không thù địch",
        ["info"] = "giết "..ach_lists.killbird.current.." chim",
    },
    ["killgloomer"] = {
        ["name"] = "Giọt máu đầu tiên",
        ["description"] = "Giết Glommer",
        ["info"] = "Giết Glommer",
    },
    ["killchester"] = {
        ["name"] = "Hạ gục kép",
        ["description"] = "Giết Chester",
        ["info"] = "Đã giết Chester",
    },
    -- # SLAY
    ["lightninggoat"] = {
        ["name"] = "100 ngàn Volt",
        ["description"] = "Giết "..ach_lists.lightninggoat.current.." Volt Goat tích điện",
        ["info"] = "Đã giết "..ach_lists.lightninggoat.current.." Volt Goat tích điện",
    },
    ["beefalo"] = {
        ["name"] = "Khát máu",
        ["description"] = "Giết "..ach_lists.beefalo.current.." Beefalo",
        ["info"] = "Đã giết "..ach_lists.beefalo.current.." Beefalo",
    },
    ["koalefant"] = {
        ["name"] = "Săn ngà",
        ["description"] = "Giết "..ach_lists.koalefant.current.." Koalefant mùa đông",
        ["info"] = "Đã giết "..ach_lists.koalefant.current.." Koalefant mùa đông",
    },
    ["horrorhound"] = {
        ["name"] = "Xác sống",
        ["description"] = "Giết "..ach_lists.horrorhound.current.." Horror Hound",
        ["info"] = "Đã giết "..ach_lists.horrorhound.current.." Horror Hound",
    },
    ["werepig"] = {
        ["name"] = "Người Sói",
        ["description"] = "Giết "..ach_lists.werepig.current.." Werepig",
        ["info"] = "Đã giết "..ach_lists.werepig.current.." Werepig",
    },
    ["beardlord"] = {
        ["name"] = "Phản Quốc",
        ["description"] = "Giết "..ach_lists.beardlord.current.." Beardlord",
        ["info"] = "Đã giết "..ach_lists.beardlord.current.." Beardlord",
    },
    ["snurtle"] = {
        ["name"] = "Kẻ phá vỏ",
        ["description"] = "Giết "..ach_lists.snurtle.current.." Snurtle",
        ["info"] = "Đã giết "..ach_lists.snurtle.current.." Snurtle",
    },
    ["mosling"] = {
        ["name"] = "Gà quay",
        ["description"] = "Giết "..ach_lists.mosling.current.." Mosling nổi giận",
        ["info"] = "Đã giết "..ach_lists.mosling.current.." Mosling nổi giận",
    },
    ["birchnut"] = {
        ["name"] = "Bóng cười",
        ["description"] = "Chặt "..ach_lists.birchnut.current.." cây Birchnut nhiễm độc",
        ["info"] = "Đã chặt "..ach_lists.birchnut.current.." cây Birchnut nhiễm độc",
    },
    -- # SLAY2
    -- # DUEL
    ["lavae"] = {
        ["name"] = "Đùa với lửa",
        ["description"] = "Một mình đánh bại "..ach_lists.lavae.current.." Lavae",
        ["info"] = "Đã một mình đánh bại "..ach_lists.lavae.current.." Lavae",
    },
    ["spiderqueen"] = {
        ["name"] = "Chúa nhện",
        ["description"] = "Một mình đánh bại "..ach_lists.spiderqueen.current.." Spider Queen",
        ["info"] = "Đã một mình đánh bại "..ach_lists.spiderqueen.current.." Spider Queen",
    },
    ["pengul"] = {
        ["name"] = "Xác sống 2",
        ["description"] = "Một mình đánh bại "..ach_lists.pengul.current.." Moonrock Pengull",
        ["info"] = "Đã một mình đánh bại "..ach_lists.pengul.current.." Moonrock Pengull",
    },
    ["tentapillar"] = {
        ["name"] = "Bộ sưu tập Hentai",
        ["description"] = "Một mình đánh bại "..ach_lists.tentapillar.current.." Tentapillar",
        ["info"] = "Đã đánh bại "..ach_lists.tentapillar.current.." Tentapillar mà không có tùy tùng",
    },
    ["seaweed"] = {
        ["name"] = "Cưới nước",
        ["description"] = "Một mình đánh bại "..ach_lists.seaweed.current.." Sea Weed",
        ["info"] = "Đã một mình đánh bại "..ach_lists.seaweed.current.." Sea Weed",
    },
    ["grassgator"] = {
        ["name"] = "Chinh phục Florida",
        ["description"] = "Một mình đánh bại "..ach_lists.grassgator.current.." Grass Gator",
        ["info"] = "Đã một mình đánh bại "..ach_lists.grassgator.current.." Grass Gator",
    },
    ["ewecus"] = {
        ["name"] = "Cái gì dính thế?",
        ["description"] = "Một mình đánh bại Ewecus",
        ["info"] = "Một mình đánh bại Ewecus",
    },
    ["ghost"] = {
        ["name"] = "Thợ Săn Ma",
        ["description"] = "Một mình đánh bại Ghost",
        ["info"] = "Một mình đánh bại Ghost",
    },
    ["gnarwail"] = {
        ["name"] = "Sừng sỏ",
        ["description"] = "Một mình đánh bại Gnarwail",
        ["info"] = "Một mình đánh bại Gnarwail",
    },
    ["rockjaw"] = {
        ["name"] = "Tiệc cá mập",
        ["description"] = "Một mình đánh bại Rockjaw",
        ["info"] = "Một mình đánh bại Rockjaw",
    },
    ["bigworm"] = {
        ["name"] = "Alaskan Bull Worm",
        ["description"] = "Một mình hạ gục Great Depths Worm",
        ["info"] = "Đã một mình hạ gục Great Depths Worm",
    },
    ["soloyourself"] = {
        ["name"] = "Soi gương",
        ["description"] = "Một mình hạ gục Deadelgänger của chính mình",
        ["info"] = "Đã một mình hạ gục Deadelgänger",
    },
    -- # BOSS
    ["santaklaus"] = {
        ["name"] = "Nghiến Răng",
        ["description"] = "Giết Klaus",
        ["info"] = "Giết Klaus",
    },
    ["dragonflybeequeen"] = {
        ["name"] = "Thuốc diệt côn trùng",
        ["description"] = "Đánh bại các trùm côn trùng",
        ["info"] = "Đã đánh bại Dragonfly và Bee Queen",
    },
    ["malbatrosscrabking"] = {
        ["name"] = "Mồ chôn dưới nước",
        ["description"] = "Đánh bại các trùm đại dương",
        ["info"] = "Đã đánh bại Malbatross và Crab King",
    },
    ["shadowpieche"] = {
        ["name"] = "Chinh phục bóng tối",
        ["description"] = "Giết cả ba Shadow Knight, Shadow Bishop và Shadow Rook cấp 3",
        ["info"] = "Đã giết cả ba Shadow Knight, Shadow Bishop và Shadow Rook cấp 3",
    },
    ["ancientguardianancientfuelweaver"] = {
        ["name"] = "Kẻ diệt trùm cổ đại",
        ["description"] = "Đánh bại các trùm cổ đại",
        ["info"] = "Đã đánh bại Ancient Guardian và Ancient Fuelweaver",
    },
    ["celestialchampion"] = {
        ["name"] = "Nhật Thực",
        ["description"] = "Giết Celestial Champion",
        ["info"] = "Giết Celestial Champion",
    },
    ["celestialscion"] = {
        ["name"] = "Nguyệt thực toàn phần",
        ["description"] = "Đánh bại Celestial Scion",
        ["info"] = "Đã đánh bại Celestial Scion",
    },
    ["guardtower"] = {
        ["name"] = "Đoản mạch",
        ["description"] = "Giết "..ach_lists.guardtower.current.." Ancient Guard Tower",
        ["info"] = "Đã giết "..ach_lists.guardtower.current.." Ancient Guard Tower",
    },
    ["werepigs"] = {
        ["name"] = "Homo Troglodytes",
        ["description"] = "Đánh bại các Werepig",
        ["info"] = "Đã đánh bại Nightmare Werepig và Scrappy Werepig",
    },
    ["toadstool"] = {
        ["name"] = "Con cóc ghẻ",
        ["description"] = "Giết Misery Toadstool",
        ["info"] = "Giết Misery Toadstool",
    },
    ["twinterror"] = {
        ["name"] = "TERRARIA!!",
        ["description"] = "Giết Retinazor và Spazmatism",
        ["info"] = "Đã đánh bại Retinazor và Spazmatism",
    },
    ["seasonboss"] = {
        ["name"] = "Chiến binh thực thụ",
        ["description"] = "Giết tất cả trùm theo mùa",
        ["info"] = "Đã đánh bại tất cả trùm theo mùa",
    },
    ["mutationboss"] = {
        ["name"] = "Chiến binh đột biến",
        ["description"] = "Giết tất cả trùm đột biến",
        ["info"] = "Đã đánh bại tất cả trùm đột biến",
    },
    -- # MISC
    ["opentreasure"] = {
        ["name"] = "Kho báu X",
        ["description"] = "Mở một rương chìm",
        ["info"] = "Đã mở một rương chìm",
    },
    ["piratechest"] = {
        ["name"] = "Dấu X chỉ kho báu",
        ["description"] = "Đào kho báu cướp biển",
        ["info"] = "Đã đào kho báu cướp biển",
    },
    ["sitting"] = {
        ["name"] = "Chiếc ghế chứng nhân",
        ["description"] = "Ngồi xuống",
        ["info"] = "Đã ngồi xuống",
    },
    ["sacrificecotl"] = {
        ["name"] = "Thành viên giáo phái",
        ["description"] = "Nấu thịt thỏ ở Tượng Cừu",
        ["info"] = "Đã nấu thịt thỏ ở Tượng Cừu",
    },
    ["sewing"] = {
        ["name"] = "Thợ may?",
        ["description"] = "Sử dụng bộ kim chỉ",
        ["info"] = "Sử dụng bộ kim chỉ",
    },
    ["wither"] = {
        ["name"] = "Bông hoa bị lãng quên",
        ["description"] = "Nhặt "..ach_lists.wither.current.." bông hoa héo",
        ["info"] = "Đã nhặt "..ach_lists.wither.current.." bông hoa héo",
    },
    ["minemoon"] = {
        ["name"] = "Khai thác đá mặt trăng",
        ["description"] = "Khai thác "..ach_lists.minemoon.current.." suối nước nóng hóa kính",
        ["info"] = "Đã khai thác "..ach_lists.minemoon.current.." suối nước nóng hóa kính",
    },
    ["aquarium"] = {
        ["name"] = "Bể cá hữu dụng",
        ["description"] = "Cho cá hữu ích vào bình bảo quản Icker",
        ["info"] = "Đã bảo quản một con cá hữu ích",
    },
    -- # MILE
    ["intogame"] = {
        ["name"] = "Khởi đầu mới",
        ["description"] = "Bước vào thế giới",
        ["info"] = "Thành công bước vào thế giới",
    },
    ["starspent"] = {
        ["name"] = "Siêu sao",
        ["description"] = "Xài "..ach_lists.starspent.current.." sao",
        ["info"] = "Xài "..ach_lists.starspent.current.." sao trên thanh phần thưởng",
    },
    ["didtask"] = {
        ["name"] = "Ngôi sao nhiệm vụ",
        ["description"] = "Hoàn thành "..ach_lists.didtask.current.." nhiệm vụ mùa",
        ["info"] = "Đã hoàn thành "..ach_lists.didtask.current.." nhiệm vụ mùa",
    },
    ["oldage"] = {
        ["name"] = "Sống lâu trăm tuổi",
        ["description"] = "Sống "..ach_lists.oldage.current.." ngày",
        ["info"] = "Đã sống được "..ach_lists.oldage.current.." ngày",
    },
    ["walkalot"] = {
        ["name"] = "Leo núi",
        ["description"] = "Đi bộ "..(ach_lists.walkalot.current/60).." phút",
        ["info"] = "đã đi được "..(ach_lists.walkalot.current/60).." phút",
    },
    ["stopalot"] = {
        ["name"] = "TƯỢNG!",
        ["description"] = "Đứng im trong "..(ach_lists.stopalot.current/60).." phút",
        ["info"] = "vẫn bất động trong "..(ach_lists.stopalot.current/60).." phút",
    },
    ["caveage"] = {
        ["name"] = "Gái cave",
        ["description"] = "Ở "..(ach_lists.caveage.current/60).." phút trong hang",
        ["info"] = "Chui vô hang trong "..(ach_lists.caveage.current/60).." phút",
    },
    ["waterage"] = {
        ["name"] = "Thủy thủ",
        ["description"] = "Ở ngoài đất liền trong "..(ach_lists.waterage.current/60).." phút",
        ["info"] = "Đã ở ngoài đất liền trong "..(ach_lists.waterage.current/60).." phút",
    },
    ["rider"] = {
        ["name"] = "Cao bồi",
        ["description"] = "Cưỡi bò trong "..(ach_lists.rider.current/60).." phút",
        ["info"] = "Đã cưỡi bò trong "..(ach_lists.rider.current/60).." phút",
    },
    ["walkturf"] = {
        ["name"] = "Nhà thám hiểm",
        ["description"] = "Đi qua "..ach_lists.walkturf.current.." loại địa hình khác nhau",
        ["info"] = "Đã đi qua "..ach_lists.walkturf.current.." loại địa hình khác nhau",
    },
    ["complete"] = {
        ["name"] = "Tốt nghiệp",
        ["description"] = "Hoàn thành tất cả các thành tựu",
        ["info"] = "Hoàn thành tất cả các thành tựu",
    },
    -- # TASK
    ["task1"] = {
        ["name"] = "Nhiệm vụ mùa 1",
        ["description"] = 1,
        ["info"] = "Đã hoàn thành nhiệm vụ mùa 1",
    },
    ["task2"] = {
        ["name"] = "Nhiệm vụ mùa 2",
        ["description"] = 2,
        ["info"] = "Đã hoàn thành nhiệm vụ mùa 2",
    },
    ["task3"] = {
        ["name"] = "Nhiệm vụ mùa 3",
        ["description"] = 3,
        ["info"] = "Đã hoàn thành nhiệm vụ mùa 3",
    },
    ["task4"] = {
        ["name"] = "Nhiệm vụ mùa 4",
        ["description"] = 4,
        ["info"] = "Đã hoàn thành nhiệm vụ mùa 4",
    },
    ["task5"] = {
        ["name"] = "Nhiệm vụ mùa 5",
        ["description"] = 5,
        ["info"] = "Đã hoàn thành nhiệm vụ mùa 5",
    },
    ["task6"] = {
        ["name"] = "Nhiệm vụ mùa 6",
        ["description"] = 6,
        ["info"] = "Đã hoàn thành nhiệm vụ mùa 6",
    },
}

STRINGS.PERKS={
    -- # ATTRIBUTE
    ["hungerup"] = {
        ["name"]="Độ no +",
        ["description"]="Tăng độ no thêm "..allachiv_coindata["hungerup"],
    },
    ["healthup"] = {
        ["name"]="Máu +",
        ["description"]="Tăng máu thêm "..allachiv_coindata["healthup"],
    },
    ["sanityup"] = {
        ["name"]="Tinh thần +",
        ["description"]="Tăng tinh thần thêm "..allachiv_coindata["sanityup"],
    },
    ["healthregenup"] = {
        ["name"]="Hồi máu +",
        ["description"]="Tăng tốc độ hồi máu thêm "..allachiv_coindata["healthregenup"].."/s",
    },
    ["hungerrateup"] = {
        ["name"]="Tốc độ đói -",
        ["description"]="Giảm tốc độ tiêu hao độ no đi "..(math.ceil(allachiv_coindata["hungerrateup"]*100)).."%",
    },
    ["sanityregenup"] = {
        ["name"]="Hồi tinh thần +",
        ["description"]="Tăng tốc độ hồi tinh thần thêm "..allachiv_coindata["sanityregenup"].."/s",
    },
    ["speedup"] = {
        ["name"]="Tốc độ +",
        ["description"]="Tăng tốc độ di chuyển thêm "..(math.ceil(allachiv_coindata["speedup"]*100)).."%",
    },
    ["absorbup"] = {
        ["name"]="Phòng thủ +",
        ["description"]="Tăng phòng thủ thêm "..(math.ceil(allachiv_coindata["absorbup"]*100)).."%",
    },
    ["damageup"] = {
        ["name"]="Sát thương +",
        ["description"]="Tăng sát thương thêm "..(math.ceil(allachiv_coindata["damageup"]*100)).."%",
    },
    ["planarabsorbup"] = {
        ["name"]="Phòng thủ vị diện +",
        ["description"]="Tăng phòng thủ vị diện thêm "..allachiv_coindata["planarabsorbup"],
    },
    ["planardamageup"] = {
        ["name"]="Sát thương vị diện +",
        ["description"]="Tăng sát thương vị diện thêm "..allachiv_coindata["planardamageup"],
    },
    ["criticalup"] = {
        ["name"]="Tỉ lệ chí mạng +",
        ["description"]="Tăng tỉ lệ chí mạng thêm "..(math.ceil(allachiv_coindata["criticalup"]*100)).."%",
    },
    ["criticaldmgup"] = {
        ["name"]="Sát thương chí mạng +",
        ["description"]="Tăng sát thương chí mạng thêm "..(math.ceil(allachiv_coindata["criticaldmgup"]*100)).."%",
    },
    ["lifestealup"] = {
        ["name"]="Hút máu +",
        ["description"]="Tăng lượng máu hút được thêm "..(math.ceil(allachiv_coindata["lifestealup"]*1000)/10).."% sát thương bạn gây ra",
    },
    ["fireflylightup"] = {
        ["name"]="Ánh sáng mờ +",
        ["description"]="Tỏa ánh sáng xung quanh bạn với bán kính ngày càng tăng.",
    },
    ["scaleup"] = {
        ["name"]="Kích thước +",
        ["description"]="Tăng kích thước của nhân vật lên "..(math.ceil(allachiv_coindata["scaleup"]*100)).."%",
    },
    ["xpmultup"] = {
        ["name"]="Hệ số kinh nghiệm +",
        ["description"]="Tăng kinh nghiệm nhận được thêm "..(math.ceil(allachiv_coindata["xpmultup"]*100)).."%",
    },
    ["repairitemup"] = {
        ["name"]="Giả kim",
        ["description"]="Vũ khí, áo giáp và quần áo được trang bị dần được sửa chữa",
    },
    ["repairmagiup"] = {
        ["name"]="Pháp sư",
        ["description"]="Các vật phẩm ma thuật được trang bị dần được sửa chữa",
    },
    ["repairfoodup"] = {
        ["name"]="Tinh linh",
        ["description"]="Vật phẩm dễ hỏng trong hành trang dần được làm tươi trở lại",
    },
    ["krampussackup"] = {
        ["name"]="Thợ săn bao tải",
        ["description"]="Tăng tỉ lệ rơi túi Krampus thêm "..(math.ceil(allachiv_coindata["krampussackup"]*100)).."%",
    },
    -- # ABILITY
    ["nomoist"] = {
        ["name"]="Kháng mưa",
        ["description"]="Không bị ướt từ mưa",
    },
    ["icemaster"] = {
        ["name"]="Kháng lạnh",
        ["description"]="Miễn nhiễm với lạnh",
    },
    ["firemaster"] = {
        ["name"]="Kháng nóng",
        ["description"]="Miễn nhiễm với quá nhiệt",
    },
    ["fastworker"] = {
        ["name"]="Tay nhanh",
        ["description"]="Nhặt và chế tạo nhanh hơn",
    },
    ["minefaster"] = {
        ["name"]="Búa tạ",
        ["description"]="Đào đá ngay lập tức",
    },
    ["chopfaster"] = {
        ["name"]="Máy cưa",
        ["description"]="Chặt cây ngay lập tức",
    },
    ["fishfaster"] = {
        ["name"]="Ngư thần",
        ["description"]="Bắt cá ngay lập tức",
    },
    ["cookfaster"] = {
        ["name"]="Siêu đầu bếp",
        ["description"]="Nấu món bằng nồi hầm ngay lập tức",
    },
    ["warlychef"] = {
        ["name"]="Đầu bếp năm sao",
        ["description"]="Có được khả năng sử dụng đồ dùng nhà bếp màu đỏ",
    },
    ["trinketowner"] = {
        ["name"]="Bùa kỷ vật",
        ["description"]="Có thể trang bị đồ trang sức để nhận năng lực",
    },
    ["christmastbulb"] = {
        ["name"]="Bùa trang trí",
        ["description"]="Có thể đeo vật trang trí để nhận năng lực đặc biệt",
    },
    ["strongergrip"] = {
        ["name"]="Nắm chắc tay",
        ["description"]="Nắm vũ khí chắc hơn, không thể bị tước vũ khí",
    },
    ["doublehealed"] = {
        ["name"]="Trị liệu Sư",
        ["description"]="Vật phẩm hồi máu có hiệu quả gấp đôi",
    },
    ["doublepick"] = {
        ["name"]="Thu hoạch",
        ["description"]="Vật phẩm thu hoạch được gấp đôi",
    },
    ["doubledrop"] = {
        ["name"]="Khát máu",
        ["description"]="Nhận gấp đôi chiến lợi phẩm khi tiêu diệt quái vật",
    },
    ["doubleworkdrop"] = {
        ["name"]="Người làm việc hiệu quả",
        ["description"]="Nhận gấp đôi tài nguyên khi chặt cây và khai thác đá",
    },
    ["buildcheaper"] = {
        ["name"]="Bậc thầy chế tác",
        ["description"]="Chế tạo vật phẩm yêu cầu một nửa nguyên liệu",
    },
    ["supercritter"] = {
        ["name"]="Thú cưng siêu cấp",
        ["description"]="Thú cưng đi theo bạn nhận thêm hiệu ứng nội tại",
    },
    ["blueprintextractor"] = {
        ["name"]="Nhà vẽ bản đồ",
        ["description"]="Có thể tháo một số vật phẩm bằng giấy để lấy nguyên liệu",
    },
    ["itemmerger"] = {
        ["name"]="Lò luyện di động",
        ["description"]="Kích hoạt: gộp độ bền của các vật phẩm trong hành trang",
    },
    ["itemcleaner"] = {
        ["name"]="Chuyên gia dọn rác",
        ["description"]="Kích hoạt: dọn dẹp thế giới để nhận kinh nghiệm",
    },
    ["sharemap"] = {
        ["name"]="Người dẫn đường",
        ["description"]="Kích hoạt: chia sẻ phần bản đồ đã khám phá với người chơi khác",
    },
    -- # EXPERTISE
    ["expertwilson1"] = {
        ["name"]="Người ăn Moonlens",
        ["description"]="Có thể ăn Moonlens để tăng chỉ số vĩnh viễn",
    },
    ["expertwilson2"] = {
        ["name"]="Đá vô cực",
        ["description"]="Đá quý trong hành trang mang lại lợi ích",
    },
    ["expertwes1"] = {
        ["name"]="Nhân vật chúa hề",
        ["description"]="Nhận thêm 100% kinh nghiệm",
    },
    ["expertwes2"] = {
        ["name"]="Đùa không vui",
        ["description"]="Có thể chế tạo thêm bong bóng",
    },
    ["expertwoodie1"] = {
        ["name"]="Thuần Thú",
        ["description"]="Kiểm soát hoàn toàn con thú trong người",
    },
    ["expertwoodie2"] = {
        ["name"]="Người hóa Bearver",
        ["description"]="Có thể ăn các loại gỗ để nhận chỉ số",
    },
    ["expertwoodie3"] = {
        ["name"]="Dạng kích thích",
        ["description"]="Những dạng biến hình mạnh hơn",
    },
    ["expertwinona1"] = {
        ["name"]="Thợ xây Bob",
        ["description"]="Có thể xây công trình nâng cấp",
    },
    ["expertwinona2"] = {
        ["name"]="Người cầm cờ",
        ["description"]="Có thể xây công trình cờ và biểu ngữ",
    },
    ["expertwebber1"] = {
        ["name"]="Người gọi nhện",
        ["description"]="Triệu hồi Spider ngẫu nhiên khi đội mũ nhện",
    },
    ["expertwebber2"] = {
        ["name"]="Người bạn của Fluffy",
        ["description"]="Có thể chế tạo nhà cho Fluffy và kết bạn với Fluffy",
    },
    ["expertwebber3"] = {
        ["name"]="Phước lành Arachne",
        ["description"]="Có thể chế tạo mặt nạ đặc biệt",
    },
    ["expertwx1"] = {
        ["name"]="WX-12",
        ["description"]="Tăng số ô mô-đun lên 12",
    },
    ["expertwx2"] = {
        ["name"]="WX-99",
        ["description"]="Các mạch có độ bền vô hạn",
    },
    ["expertwx4"] = {
        ["name"]="J4-M5",
        ["description"]="Có thể chế tạo J1-M1 nâng cấp để quét dữ liệu về các sinh vật mới",
    },
    ["expertwillow3"] = {
        ["name"]="Phước lành Hephaestus",
        ["description"]="Có thể chế tạo vật phẩm đặc biệt",
    },
    ["expertwillow4"] = {
        ["name"]="Tinh linh than hồng",
        ["description"]="Có thể dùng Than hồng siêu thực để thi triển phép thuật mới",
    },
    ["expertwathg1"] = {
        ["name"]="Phước lành Zeus",
        ["description"]="Có thể chế tạo vật phẩm đặc biệt",
    },
    ["expertwathg2"] = {
        ["name"]="Diva hàng hiệu",
        ["description"]="Có thể chế tạo thêm sách chiến đấu",
    },
    ["expertwendy1"] = {
        ["name"]="Dược phẩm (bất) ổn định",
        ["description"]="Thuốc tiên ma mạnh hơn",
    },
    ["expertwendy2"] = {
        ["name"]="José Valim",
        ["description"]="Có thể chế tạo thuốc tiên mới",
    },
    ["expertwendy3"] = {
        ["name"]="Mối liên kết linh hồn",
        ["description"]="Bình thờ chị em nhận thêm hiệu ứng",
    },
    ["expertwolf1"] = {
        ["name"]="Chiến binh cơ bắp",
        ["description"]="Dễ dàng trở nên khỏe mạnh",
    },
    ["expertwolf2"] = {
        ["name"]="Phước lành Ares",
        ["description"]="Có thể chế tạo các vật phẩm đặc biệt",
    },
    ["expertwalter1"] = {
        ["name"]="Sức mạnh Tình bạn",
        ["description"]="Woby lớn mãi mãi (?)",
    },
    ["expertwalter3"] = {
        ["name"]="Phước lành Hermes",
        ["description"]="Có thể chế tạo các vật phẩm đặc biệt",
    },
    ["expertwalter4"] = {
        ["name"]="Thiên tài đạn ná",
        ["description"]="Có thể chế tạo đạn ná đặc biệt",
    },
    ["expertwicker2"] = {
        ["name"]="Ma pháp chương I",
        ["description"]="Sách ma pháp mạnh hơn",
    },
    ["expertwicker3"] = {
        ["name"]="Ma pháp chương II",
        ["description"]="Có thể chế tạo sách mới",
    },
    ["expertwaxwell2"] = {
        ["name"]="Quỷ dữ",
        ["description"]="Gây - Nhận ít sát thương         từ bóng tối, nhưng...",
    },
    ["expertwaxwell3"] = {
        ["name"]="Phước lành Erebus",
        ["description"]="Có thể chế tạo những công cụ đặc biệt",
    },
    ["expertwaxwell4"] = {
        ["name"]="Tri thức bị nguyền rủa",
        ["description"]="Có thể dùng Sách Bóng Tối để thi triển phép thuật mới",
    },
    ["expertwarly3"] = {
        ["name"]="Đầu bếp kỹ tính",
        ["description"]="Có thể chế tạo vũ khí đặc biệt",
    },
    ["expertwarly4"] = {
        ["name"]="Đầu bếp sành ăn",
        ["description"]="Có thể chế tạo bếp nướng di động mới để nấu thêm món ăn",
    },
    ["expertworm1"] = {
        ["name"]="Phước lành Persephone",
        ["description"]="Có thể chế tạo những công cụ đặc biệt",
    },
    ["expertworm2"] = {
        ["name"]="Bàn tay cứt",
        ["description"]="Có thể bón cây bằng tay",
    },
    ["expertwortox1"] = {
        ["name"]="Tốc biến",
        ["description"]="Dịch chuyển linh hồn trên bản đồ luôn tiêu tốn tối đa 5 linh hồn",
    },
    ["expertwortox3"] = {
        ["name"]="Phước lành Hades",
        ["description"]="Có thể chế tạo vũ khí đặc biệt",
    },
    ["expertwanda1"] = {
        ["name"]="Giờ giải lao",
        ["description"]="Có thể chế tạo thêm đồng hồ",
    },
    ["expertwanda2"] = {
        ["name"]="Thêm giờ nghỉ",
        ["description"]="Túi đồng hồ mạnh hơn",
    },
    ["expertwurt1"] = {
        ["name"]="Phước lành Poseidon",
        ["description"]="Có thể chế tạo vũ khí đặc biệt",
    },
    ["expertwurt2"] = {
        ["name"]="Nữ hoàng Merm",
        ["description"]="Hiệu ứng của Merm King mạnh hơn và có thêm vệ sĩ",
    },
    ["expertwonk1"] = {
        ["name"]="Vuốt khỉ",
        ["description"]="Wonkey có thể đào và di chuyển dưới lòng đất",
    },
    ["expertwonk2"] = {
        ["name"]="Sức mạnh thực thụ",
        ["description"]="Wonkey mạnh hơn với mỗi Kỷ vật bị nguyền rủa trong hành trang",
    },
    -- # CRAFT
    ["ancientstation"] = {
        ["name"]="Thợ xây cổ đại",
        ["description"]="Có thể chế tạo vật phẩm trong mục Giả khoa học cổ đại",
    },
    ["lunarcraft"] = {
        ["name"]="Kỵ sĩ ánh trăng",
        ["description"]="Có thể chế tạo vật phẩm trong mục Mặt trăng",
    },
    ["pearlcraft"] = {
        ["name"]="Bạn thân của Pearl",
        ["description"]="Có thể chế tạo vật phẩm trong mục trao đổi của Pearl",
    },
    ["rabbitkingcraft"] = {
        ["name"]="Tâm hồn nhân ái",
        ["description"]="Có thể chế tạo vật phẩm của Benevolent Rabbit King",
    },
    ["carpentercraft"] = {
        ["name"]="Bậc thầy mộc",
        ["description"]="Có thể chế tạo vật phẩm từ Giá cưa",
    },
    ["crittercraft"] = {
        ["name"]="Nhà nhận nuôi thú cưng",
        ["description"]="Có thể nhận nuôi thú cưng",
    },
    ["madsciencecraft"] = {
        ["name"]="Nhà khoa học điên",
        ["description"]="Có thể chế tạo vật phẩm trong mục Thí nghiệm",
    },
    ["eventcraft"] = {
        ["name"]="Mừng năm mới!",
        ["description"]="Có thể chế tạo vật phẩm của sự kiện năm mới",
    },
    ["carnivalcraft"] = {
        ["name"]="Vui hội nào!",
        ["description"]="Có thể chế tạo vật phẩm của sự kiện Carnival",
    },
    ["klaussackbuilder"] = {
        ["name"]="Quà giáng sinh",
        ["description"]="Có thể chế tạo Kho Chiến Lợi Phẩm và Gạc Hươu",
    },
    ["bossitemcraft"] = {
        ["name"]="Thợ rèn huyền thoại",
        ["description"]="Có thể chế tạo vật phẩm của các trùm",
    },
    ["dencraft"] = {
        ["name"]="Bóng bắt thú",
        ["description"]="Có thể chế tạo hang và tổ của động vật",
    },
    ["trinketcraft"] = {
        ["name"]="Tiệm đồ cổ",
        ["description"]="Có thể chế tạo đồ trang sức (bản gốc, DLC và loại mới)",
    },
    ["clustercraft"] = {
        ["name"]="Thợ chế tạo theo cụm",
        ["description"]="Có thể chế tạo cả cụm vật phẩm",
    },
    ["multicraft"] = {
        ["name"]="Chế tạo hàng loạt",
        ["description"]="Có thể chế tạo nhiều nguyên liệu cùng lúc",
    },
    ["duppercritter"] = {
        ["name"]="Thú cưng đồng hành",
        ["description"]="Có thể nhận nuôi bạn đồng hành có thể lên cấp và nâng cấp",
    },
    -- # GLOBAL
    ["eternalcage"] = {
        ["name"]="Phước lành Fawkes",
        ["description"]="Chim trong lồng bất tử",
    },
    ["eternalicebox"] = {
        ["name"]="Tủ lạnh ngưng đọng",
        ["description"]="Thực phẩm trong tủ lạnh lấy lại độ tươi",
    },
    ["eternalthermal"] = {
        ["name"]="Đá thuần khiết",
        ["description"]="(Gần như) Sử dụng đá nhiệt không giới hạn",
    },
    ["easyfarm"] = {
        ["name"]="Phân bón tốt",
        ["description"]="Cây trồng dễ trở thành khổng lồ hơn",
    },
    ["easybeef"] = {
        ["name"]="Người thuần dưỡng Beefalo",
        ["description"]="Beefalo dễ được thuần hóa hơn",
    },
    ["icyweed"] = {
        ["name"]="Gió lạnh vi vu",
        ["description"]="Bụi cỏ lăn đóng băng xuất hiện ngẫu nhiên từ cây hoặc gốc cây vào mùa đông",
    },
    ["bosshunting"] = {
        ["name"]="Triều đại người khổng lồ",
        ["description"]="Đống đất khả nghi giờ có thể dẫn đến trùm đặc biệt mới",
    },
    ["stackinfinite"] = {
        ["name"]="Xếp chồng vô hạn",
        ["description"]="Vật phẩm có thể xếp chồng sẽ xếp được vô hạn",
    },
    ["insightinfinite"] = {
        ["name"]="Điểm thông hiểu vô hạn",
        ["description"]="Tất cả người chơi có 99 điểm thông hiểu",
    },
    ["groundedscream"] = {
        ["name"]="Chiến lợi phẩm danh dự",
        ["description"]="Quân cờ từ Bàn xoay gốm mang lại hiệu ứng cho cả thế giới",
    },
    ["riftcontroller"] = {
        ["name"]="Người quản lý khe nứt",
        ["description"]="Thế giới hoạt động như thể các khe nứt đang mở",
    },
}

STRINGS.SEASONAL_TASK = {
    ["eat_a_butter_muffin"] = "Ăn một Bánh nướng bơ",
    ["eat_a_california_roll"] = "Ăn một Cuộn California",
    ["eat_ceviche"] = "Ăn Ceviche",
    ["eat_a_figgy_frogwich"] = "Ăn một Bánh mì kẹp ếch và quả sung",
    ["eat_fish_tacos"] = "Ăn Taco cá",
    ["eat_fishsticks"] = "Ăn Cá que",
    ["eat_a_froggle_bunwich"] = "Ăn một Bánh mì kẹp ếch",
    ["eat_a_fruit_medley"] = "Ăn một Đĩa trái cây thập cẩm",
    ["eat_a_leafy_meatloaf"] = "Ăn một Ổ thịt lá",
    ["eat_a_seafood_gumbo"] = "Ăn một Súp hải sản Gumbo",
    ["drink_a_soothing_tea"] = "Uống một tách trà an thần",
    ["eat_unagi"] = "Ăn Unagi",
    ["eat_something_while_fully_wet"] = "Ăn khi đang ướt sũng",
    ["eat_something_while_fully_dry"] = "Ăn khi đang hoàn toàn khô ráo",
    ["eat_a_mushy_cake"] = "Ăn một Bánh nấm nhão",
    ["kill_a_batilisk"] = "Hạ một Batilisk",
    ["kill_a_baby_beefalo"] = "Hạ một Beefalo non",
    ["kill_a_bunnyman"] = "Hạ một Bunnyman",
    ["kill_a_depths_worm"] = "Hạ một Depths Worm",
    ["kill_a_blue_hound"] = "Hạ một Blue Hound",
    ["kill_a_merm"] = "Hạ một Merm",
    ["kill_a_lureplant"] = "Hạ một Lureplant",
    ["kill_a_rabbit"] = "Hạ một con thỏ",
    ["kill_a_terrorbeak"] = "Hạ một Terrorbeak",
    ["kill_a_slurtle"] = "Hạ một Slurtle",
    ["kill_a_snurtle"] = "Hạ một Snurtle",
    ["kill_a_sea_strider"] = "Hạ một Sea Strider",
    ["kill_a_spider_warrior"] = "Hạ một Spider Warrior",
    ["kill_a_dangling_depth_dweller"] = "Hạ một Dangling Depth Dweller",
    ["kill_a_tentacle"] = "Giết một Tentacle",
    ["kill_a_mosling"] = "Hạ một Mosling",
    ["kill_a_volt_goat"] = "Hạ một Volt Goat",
    ["kill_a_grass_gekko"] = "Hạ một Grass Gekko",
    ["kill_something_while_fully_wet"] = "Hạ một sinh vật khi đang ướt sũng",
    ["kill_something_while_fully_dry"] = "Hạ một sinh vật khi đang hoàn toàn khô ráo",
    ["craft_a_pretty_parasol"] = "Chế tạo một Dù hoa",
    ["craft_an_umbrella"] = "Chế tạo một Chiếc ô",
    ["craft_a_rain_coat"] = "Chế tạo một Áo mưa",
    ["craft_an_eyebrella"] = "Chế tạo một Eyebrella",
    ["craft_a_rain_hat"] = "Chế tạo một Mũ đi mưa",
    ["craft_an_item_while_fully_wet"] = "Chế tạo một vật phẩm khi đang ướt sũng",
    ["craft_an_item_while_fully_dry"] = "Chế tạo một vật phẩm khi đang hoàn toàn khô ráo",
    ["catch_a_bee"] = "Bắt một con ong",
    ["catch_a_killer_bee"] = "Bắt một con ong sát thủ",
    ["dig_up_a_berry_bush"] = "Đào một bụi dâu",
    ["dig_up_garden_detritus"] = "Đào rác vụn trong vườn",
    ["catch_a_moon_moth"] = "Bắt một Moon Moth",
    ["chop_down_a_lune_tree"] = "Chặt một Cây Lune",
    ["chop_down_a_green_mushtree"] = "Chặt một Cây nấm xanh",
    ["catch_a_green_mushroom_spore"] = "Bắt một Bào tử nấm xanh",
    ["dig_up_a_sapling"] = "Đào một cây non",
    ["pick_a_composting_bin"] = "Thu hoạch một Thùng ủ phân",
    ["pick_a_green_mushroom"] = "Hái một Nấm xanh",
    ["pick_an_eggplant_stalk"] = "Thu hoạch một cây cà tím",
    ["pick_a_durian_vine"] = "Thu hoạch một dây sầu riêng",
    ["pick_a_mysterious_plant"] = "Hái một Cây bí ẩn",
    ["harvest_from_a_bee_box"] = "Thu hoạch mật từ một thùng nuôi ong",
    ["plant_a_flower"] = "Trồng một bông hoa",
    ["deploy_a_garden_digamajig"] = "Đặt một Máy đào vườn",
    ["plant_a_fleshy_bulb"] = "Trồng một Củ thịt",
    ["plant_a_lune_tree"] = "Trồng một Cây Lune",
    ["plant_a_normal_berry_bush"] = "Trồng một bụi dâu thường",
    ["check_crops_with_gardeneer_hat_vision"] = "Kiểm tra cây trồng bằng tầm nhìn của Mũ Làm Vườn",
    ["start_going_insane"] = "Bắt đầu mất trí",
    ["start_becoming_enlightened"] = "Bắt đầu khai sáng",
    ["enter_lunar_territory"] = "Đi vào lãnh thổ Mặt Trăng",
    ["drown"] = "Chết đuối",
    ["heal_using_a_mosquito_sack"] = "Hồi máu bằng Túi muỗi",
    ["heal_using_a_spider_gland"] = "Hồi máu bằng Tuyến nhện",
    ["avoid_lightning_damage_using_insulation"] = "Tránh sát thương sét nhờ cách điện",
    ["eat_an_asparagus_soup"] = "Ăn một bát Súp măng tây",
    ["eat_a_creamy_potato_purée"] = "Ăn Khoai tây nghiền kem",
    ["eat_fancy_spiralled_tubers"] = "Ăn Khoai củ xoắn cầu kỳ",
    ["eat_guacamole"] = "Ăn Guacamole",
    ["eat_ratatouille"] = "Ăn Ratatouille",
    ["eat_jellybeans"] = "Ăn Kẹo đậu",
    ["eat_a_monster_lasagna"] = "Ăn Lasagna quái vật",
    ["eat_a_plain_omelette"] = "Ăn Trứng tráng đơn giản",
    ["eat_pumpkin_cookies"] = "Ăn Bánh quy bí ngô",
    ["eat_a_stuffed_eggplant"] = "Ăn Cà tím nhồi",
    ["eat_spicy_chili"] = "Ăn Ớt hầm cay",
    ["eat_tall_scotch_eggs"] = "Ăn trứng Scotch Tallbird",
    ["eat_something_while_freezing"] = "Ăn khi đang rét cóng",
    ["kill_a_batilisk_2"] = "Hạ một Batilisk",
    ["kill_a_beefalo"] = "Hạ một Beefalo",
    ["kill_a_bunnyman_2"] = "Hạ một Bunnyman",
    ["kill_a_depths_worm_2"] = "Hạ một Depths Worm",
    ["kill_a_frog"] = "Hạ một con ếch",
    ["kill_a_blue_hound_2"] = "Hạ một Blue Hound",
    ["kill_a_winter_koalefant"] = "Hạ một Koalefant mùa đông",
    ["kill_krampus"] = "Hạ Krampus",
    ["kill_mactusk"] = "Hạ MacTusk",
    ["kill_a_wee_mactusk"] = "Hạ một Wee MacTusk",
    ["kill_a_no_eyed_deer"] = "Hạ một No-Eyed Deer",
    ["kill_a_moon_moth"] = "Hạ một Moon Moth",
    ["kill_a_naked_mole_bat"] = "Hạ một Naked Mole Bat",
    ["kill_something_while_freezing"] = "Hạ một sinh vật khi đang rét cóng",
    ["craft_a_thermal_stone"] = "Chế tạo một Đá giữ nhiệt",
    ["craft_a_dapper_vest"] = "Chế tạo một Áo ghi lê lịch lãm",
    ["craft_a_puffy_vest"] = "Chế tạo một Áo ghi lê phao",
    ["craft_a_hibearnation_vest"] = "Chế tạo một Áo ghi lê ngủ đông",
    ["craft_rabbit_earmuffs"] = "Chế tạo một Bịt tai thỏ",
    ["craft_a_winter_hat"] = "Chế tạo một Mũ mùa đông",
    ["craft_a_beefalo_hat"] = "Chế tạo một Mũ Beefalo",
    ["craft_a_campfire"] = "Dựng một đống lửa trại",
    ["craft_a_tent"] = "Chế tạo một Lều",
    ["mine_a_tidy_hidey_hole"] = "Khai thác một Hốc ẩn gọn gàng",
    ["mine_a_hot_spring"] = "Khai thác một Suối nước nóng",
    ["dig_up_a_spiky_bush"] = "Đào một Bụi gai",
    ["chop_down_a_blue_mushtree"] = "Chặt một Cây nấm xanh lam",
    ["catch_a_blue_mushroom_spore"] = "Bắt một Bào tử nấm xanh lam",
    ["hammer_a_pig_house"] = "Dùng búa phá một Nhà lợn",
    ["mine_a_meteor_boulder"] = "Khai thác một Tảng thiên thạch",
    ["pick_bull_kelp"] = "Hái Tảo bẹ lớn",
    ["pick_a_blue_mushroom"] = "Hái một Nấm xanh lam",
    ["pick_a_stone_fruit_bush"] = "Hái quả từ một Bụi quả đá",
    ["pick_a_tallbird_nest"] = "Lấy trứng ở một Tổ Tallbird",
    ["pick_a_tumbleweed"] = "Nhặt một Bụi cỏ lăn",
    ["pick_a_potato_plant"] = "Thu hoạch một Cây khoai tây",
    ["pick_a_carrot_plant"] = "Thu hoạch một Cây cà rốt",
    ["pick_a_pumpkin_plant"] = "Thu hoạch một Cây bí ngô",
    ["pick_an_asparagus_fern"] = "Thu hoạch một Cây măng tây",
    ["pick_a_garlic_plant"] = "Thu hoạch một Cây tỏi",
    ["craft_an_item_that_costs_health"] = "Chế tạo một vật phẩm tiêu hao máu",
    ["place_down_carpeted_flooring"] = "Đặt Sàn trải thảm",
    ["plant_a_marble_bean"] = "Trồng một Hạt cẩm thạch",
    ["plant_a_pine_cone"] = "Trồng một Quả thông",
    ["plant_a_spiky_bush"] = "Trồng một Bụi gai",
    ["catch_an_ocean_fish"] = "Câu một con cá biển",
    ["attacked_by_charlie"] = "Bị Charlie tấn công",
    ["take_damage_from_starving"] = "Chịu sát thương do đói",
    ["bucked_by_mount"] = "Bị thú cưỡi hất xuống",
    ["failed_to_mount"] = "Thất bại khi leo lên thú cưỡi",
    ["ride_a_mount"] = "Cưỡi thú cưỡi",
    ["go_to_sleep"] = "Đi ngủ",
    ["slip_on_ice"] = "Trượt trên băng",
    ["catch_fire"] = "Bắt lửa",
    ["get_frozen"] = "Bị đóng băng",
    ["eat_a_banana_pop"] = "Ăn một Que kem chuối",
    ["drink_a_banana_shake"] = "Uống một Ly sữa chuối",
    ["eat_a_dragonpie"] = "Ăn một Bánh thanh long",
    ["eat_a_jelly_salad"] = "Ăn một Đĩa salad thạch",
    ["eat_stuffed_pepper_poppers"] = "Ăn Ớt nhồi",
    ["eat_taffy"] = "Ăn kẹo kéo",
    ["eat_a_flower_salad"] = "Ăn Salad hoa",
    ["eat_ice_cream"] = "Ăn Kem",
    ["eat_a_melonsicle"] = "Ăn một Que kem dưa",
    ["eat_a_wobster_bisque"] = "Ăn một bát Súp tôm hùm",
    ["eat_something_while_overheating"] = "Ăn khi đang quá nóng",
    ["kill_a_batilisk_3"] = "Hạ một Batilisk",
    ["kill_a_baby_beefalo_2"] = "Hạ một Beefalo non",
    ["kill_a_bunnyman_3"] = "Hạ một Bunnyman",
    ["kill_a_depths_worm_3"] = "Hạ một Depths Worm",
    ["kill_a_frog_2"] = "Hạ một con ếch",
    ["kill_a_red_hound"] = "Hạ một Red Hound",
    ["kill_a_koalefant"] = "Hạ một Koalefant",
    ["kill_a_slurper"] = "Hạ một Slurper",
    ["kill_a_tallbird"] = "Hạ một Tallbird",
    ["kill_a_moleworm"] = "Hạ một Moleworm",
    ["kill_a_cookie_cutter"] = "Hạ một Cookie Cutter",
    ["kill_a_crustashine"] = "Hạ một Crustashine",
    ["kill_a_skittersquid"] = "Hạ một Skittersquid",
    ["kill_a_suspicious_peeper"] = "Hạ một Suspicious Peeper",
    ["kill_something_while_overheating"] = "Hạ một sinh vật khi đang quá nóng",
    ["craft_a_thermal_stone_2"] = "Chế tạo một Đá giữ nhiệt",
    ["craft_a_chilled_amulet"] = "Chế tạo một Bùa làm mát",
    ["craft_a_whirly_fan"] = "Chế tạo một Quạt chong chóng",
    ["craft_a_luxury_fan"] = "Chế tạo một Quạt sang trọng",
    ["craft_a_summer_frest"] = "Chế tạo một Áo mùa hè",
    ["craft_a_floral_shirt"] = "Chế tạo một Áo hoa",
    ["craft_a_fashion_melon"] = "Chế tạo một Mũ dưa thời trang",
    ["craft_desert_goggles"] = "Chế tạo Kính sa mạc",
    ["craft_an_ice_cube"] = "Chế tạo một Khối băng",
    ["craft_an_endothermic_fire"] = "Dựng một đống lửa làm mát",
    ["craft_a_siesta_lean_to"] = "Chế tạo một Lều nghỉ trưa",
    ["catch_fireflies"] = "Bắt đom đóm",
    ["chop_down_a_red_mushtree"] = "Chặt một Cây nấm đỏ",
    ["catch_a_red_mushroom_spore"] = "Bắt một Bào tử nấm đỏ",
    ["chop_down_a_palmcone_tree"] = "Chặt một Cây cọ thông",
    ["hammer_a_player_skeleton"] = "Dùng búa phá một Bộ xương người chơi",
    ["pick_a_cave_banana_tree"] = "Hái quả từ một Cây chuối hang",
    ["pick_a_red_mushroom"] = "Hái một Nấm đỏ",
    ["pick_a_mossy_vine"] = "Hái một Dây leo rêu",
    ["pick_a_succulent"] = "Hái một Cây mọng nước",
    ["pick_a_toma_root_plant"] = "Thu hoạch một Cây cà chua",
    ["pick_a_dragon_fruit_vine"] = "Thu hoạch một Dây thanh long",
    ["pick_a_pepper_plant"] = "Thu hoạch một Cây ớt",
    ["pick_an_onion_plant"] = "Thu hoạch một Cây hành tây",
    ["pick_pomegranate_branch"] = "Hái một Nhánh lựu",
    ["pick_a_corn_stalk"] = "Thu hoạch một Cây ngô",
    ["pick_a_watermelon_plant"] = "Thu hoạch một Cây dưa hấu",
    ["harvest_sea_weed"] = "Thu hoạch rong biển",
    ["place_down_scaled_flooring"] = "Đặt Sàn vảy",
    ["deploy_a_dock_kit"] = "Đặt một Bộ cầu tàu",
    ["deploy_a_grass_raft_kit"] = "Đặt một Bộ bè cỏ",
    ["plant_a_palmcone_sprout"] = "Trồng một Mầm cọ thông",
    ["plant_monkeytails"] = "Trồng cây Đuôi khỉ",
    ["deploy_an_anenemy_trap"] = "Đặt một Bẫy Anenemy",
    ["plant_a_bull_kelp_stalk"] = "Trồng một Cuống tảo bẹ lớn",
    ["catch_a_pond_fish"] = "Bắt một con cá ao",
    ["take_fire_damage"] = "Chịu sát thương lửa",
    ["die"] = "Chết",
    ["burnt_from_smolders"] = "Bị thiêu do vật đang âm ỉ cháy",
    ["catch_fire_2"] = "Bắt lửa",
    ["get_frozen_2"] = "Bị đóng băng",
    ["hopping"] = "Nhảy qua",
    ["use_goggle"] = "Sử dụng kính bảo hộ",
    ["perform_on_stage"] = "Biểu diễn trên sân khấu",
    ["eat_bacon_and_eggs"] = "Ăn Thịt xông khói và trứng",
    ["eat_barnacle_linguine"] = "Ăn Mì Ý hà biển",
    ["eat_barnacle_nigiri"] = "Ăn Sushi hà biển",
    ["eat_barnacle_pita"] = "Ăn Bánh pita hà biển",
    ["eat_a_breakfast_skillet"] = "Ăn Chảo điểm tâm",
    ["eat_a_bunny_stew"] = "Ăn Thịt thỏ hầm",
    ["eat_a_fig_stuffed_trunk"] = "Ăn Vòi nhồi quả sung",
    ["eat_a_figatoni"] = "Ăn Figatoni",
    ["eat_a_figkabab"] = "Ăn Figkabab",
    ["eat_stuffed_fish_heads"] = "Ăn Đầu cá nhồi",
    ["eat_surf_n_turf"] = "Ăn Hải sản và thịt nướng",
    ["eat_a_turkey_dinner"] = "Ăn Bữa tối gà tây",
    ["eat_a_veggie_burger"] = "Ăn Burger rau củ",
    ["eat_beefy_greens"] = "Ăn Rau xanh với thịt",
    ["eat_a_salsa_fresca"] = "Ăn Salsa tươi",
    ["eat_waffles"] = "Ăn Bánh quế",
    ["eat_something_while_enlightened"] = "Ăn khi đang khai sáng",
    ["eat_something_while_insane"] = "Ăn khi đang mất trí",
    ["kill_a_batilisk_4"] = "Hạ một Batilisk",
    ["kill_a_beefalo_2"] = "Hạ một Beefalo",
    ["kill_a_bunnyman_4"] = "Hạ một Bunnyman",
    ["kill_a_depths_worm_4"] = "Hạ một Depths Worm",
    ["kill_a_frog_3"] = "Hạ một con ếch",
    ["kill_a_red_hound_2"] = "Hạ một Chó săn đỏ",
    ["kill_a_merm_2"] = "Hạ một Merm",
    ["kill_a_rock_lobster"] = "Hạ một Rock Lobster",
    ["kill_a_splumonkey"] = "Hạ một Splumonkey",
    ["kill_a_spider_warrior_2"] = "Hạ một Spider Warrior",
    ["kill_a_spider_spitter"] = "Hạ một Spider Spitter",
    ["kill_a_nurse_spider"] = "Hạ một Nurse Spider",
    ["kill_a_cave_spider"] = "Hạ một Cave Spider",
    ["kill_a_shattered_spider"] = "Hạ một Shattered Spider",
    ["kill_a_buzzard"] = "Hạ một con kền kền",
    ["kill_a_catcoon"] = "Giết một Catcoon",
    ["kill_a_birchnutter"] = "Hạ một Birchnutter",
    ["craft_a_garland"] = "Chế tạo một Vòng hoa",
    ["craft_a_rope"] = "Chế tạo một Sợi dây thừng",
    ["craft_boards"] = "Chế tạo Ván gỗ",
    ["craft_a_cut_stone"] = "Chế tạo một Đá đẽo",
    ["craft_a_papyrus"] = "Chế tạo một Tờ giấy cói",
    ["dig_up_a_birchnut_tree"] = "Đào một Cây bạch dương",
    ["chop_down_a_twiggy_tree"] = "Chặt một Cây cành khẳng khiu",
    ["dig_up_grass"] = "Đào một Bụi cỏ",
    ["mine_a_marble_shrub"] = "Khai thác một Bụi cẩm thạch",
    ["chop_down_a_normal_sporecap"] = "Chặt một Cây nấm bào tử thường",
    ["chop_down_a_lunar_mushtree"] = "Chặt một Cây nấm Mặt Trăng",
    ["catch_a_lunar_spore"] = "Bắt một Bào tử Mặt Trăng",
    ["dig_up_a_moon_sapling"] = "Đào một Cây non Mặt Trăng",
    ["catch_a_bulbous_lightbug"] = "Bắt một Bọ phát sáng bụng phình",
    ["catch_a_mosquito"] = "Bắt một con muỗi",
    ["pick_a_junk_pile"] = "Lục một Đống phế liệu",
    ["pick_a_teetering_junk_pile"] = "Lục một Đống phế liệu chênh vênh",
    ["pick_ocean_debris"] = "Nhặt Rác trôi trên biển",
    ["pick_a_moon_sapling"] = "Hái một Cây non Mặt Trăng",
    ["pick_forget_me_lots"] = "Hái Hoa lưu ly",
    ["harvest_a_mushroom_planter"] = "Thu hoạch một Khay trồng nấm",
    ["broke_your_armor"] = "Làm hỏng áo giáp của mình",
    ["place_down_cobblestones"] = "Đặt Sàn đá cuội",
    ["deploy_a_fossil_fragment"] = "Đặt một Mảnh hóa thạch",
    ["plant_a_twiggy_tree_cone"] = "Trồng một Hạt cây cành khẳng khiu",
    ["plant_a_sapling"] = "Trồng một Cây non",
    ["plant_a_moon_sapling"] = "Trồng một Cây non Mặt Trăng",
    ["plant_grass"] = "Trồng Cỏ",
    ["deploy_a_tooth_trap"] = "Đặt một Bẫy răng",
    ["plant_a_banana_bush"] = "Trồng một Bụi chuối",
    ["exit_lunar_territory"] = "Rời lãnh thổ Mặt Trăng",
    ["heal_using_a_honey_poultice"] = "Hồi máu bằng Thuốc đắp mật ong",
    ["heal_using_a_healing_salve"] = "Hồi máu bằng Thuốc mỡ chữa thương",
    ["get_hit_by_a_spider"] = "Bị nhện đánh trúng",
    ["get_a_monkey_trinket"] = "Nhận một Món đồ khỉ",
    ["lose_a_monkey_trinket"] = "Mất một Món đồ khỉ",
    ["eat_10_wet_goops"] = "Ăn 10 phần đồ ăn nhão",
    ["eat_10_foods_while_starving"] = "Ăn 10 món khi đang đói lả",
    ["kill_10_bees"] = "Hạ 10 con ong",
    ["kill_10_killer_bees"] = "Hạ 10 con ong sát thủ",
    ["kill_10_butterflies"] = "Hạ 10 con bướm",
    ["kill_10_frogs"] = "Hạ 10 con ếch",
    ["kill_10_hounds"] = "Hạ 10 Hound",
    ["kill_10_crawling_horrors"] = "Hạ 10 Crawling Horror",
    ["kill_10_canaries"] = "Hạ 10 con chim hoàng yến",
    ["catch_10_butterflies"] = "Bắt 10 con bướm",
    ["catch_10_things_using_a_net"] = "Bắt 10 sinh vật bằng vợt",
    ["shovel_10_things"] = "Đào 10 thứ bằng xẻng",
    ["pick_10_normal_berry_bushes"] = "Hái quả từ 10 bụi dâu thường",
    ["pick_10_flowers"] = "Hái 10 bông hoa",
    ["pick_10_light_flowers"] = "Hái 10 Bông hoa phát sáng",
    ["till_soil_10_times_using_a_hoe"] = "Xới đất 10 lần bằng cuốc",
    ["craft_10_items"] = "Chế tạo 10 vật phẩm",
    ["eat_10_kabobs"] = "Ăn 10 phần Thịt xiên",
    ["eat_10_meatballs"] = "Ăn 10 phần Thịt viên",
    ["eat_10_meaty_stews"] = "Ăn 10 phần Thịt hầm",
    ["kill_10_snowbirds"] = "Hạ 10 con chim tuyết",
    ["kill_10_puffins"] = "Hạ 10 Puffin",
    ["kill_10_hounds_2"] = "Hạ 10 Hound",
    ["kill_10_pengulls"] = "Hạ 10 con Pengull",
    ["kill_10_pigs"] = "Hạ 10 Pigman",
    ["kill_10_spiders"] = "Hạ 10 Spider",
    ["chop_down_10_evergreens"] = "Chặt 10 Cây thông thường xanh",
    ["chop_down_10_lumpy_evergreens"] = "Chặt 10 Cây thông thường xanh gồ ghề",
    ["mine_10_mini_glaciers"] = "Khai thác 10 Tảng băng nhỏ",
    ["mine_things_10_times"] = "Khai thác 10 lần",
    ["pick_10_ferns"] = "Hái 10 Cây dương xỉ",
    ["pick_10_lichens"] = "Hái 10 Địa y",
    ["pick_10_spiky_bushes"] = "Hái 10 Bụi gai",
    ["eat_things_10_times"] = "Ăn 10 lần",
    ["get_fed_by_another_player_10_times"] = "Được người chơi khác cho ăn 10 lần",
    ["eat_10_fists_full_of_jam"] = "Ăn 10 phần Mứt quả",
    ["eat_10_pierogies"] = "Ăn 10 phần Bánh gối",
    ["kill_10_butterflies_2"] = "Hạ 10 con bướm",
    ["kill_10_canaries_2"] = "Hạ 10 con chim hoàng yến",
    ["kill_10_hounds_3"] = "Hạ 10 Hound",
    ["kill_10_mosquitos"] = "Hạ 10 con muỗi",
    ["kill_10_spiders_2"] = "Hạ 10 Spider",
    ["mine_10_stone_fruits"] = "Khai thác 10 Quả đá",
    ["hammer_things_10_times"] = "Dùng búa đập 10 lần",
    ["pick_10_banana_bushes"] = "Hái quả từ 10 Bụi chuối",
    ["pick_10_monkeytails"] = "Hái 10 Cây đuôi khỉ",
    ["pick_10_cacti"] = "Hái 10 Cây xương rồng",
    ["pick_10_oasis_cacti"] = "Hái 10 Cây xương rồng ốc đảo",
    ["row_10_times"] = "Chèo 10 lần",
    ["terraform_10_times_using_a_pitchfork"] = "Thay đổi địa hình 10 lần bằng chĩa ba",
    ["eat_something_10_times"] = "Ăn 10 lần",
    ["get_fed_by_another_player_10_times_2"] = "Được người chơi khác cho ăn 10 lần",
    ["do_an_emote_10_times"] = "Thực hiện một biểu cảm 10 lần",
    ["eat_10_honey_hams"] = "Ăn 10 phần Giăm bông mật ong",
    ["eat_10_honey_nuggets"] = "Ăn 10 phần Thịt tẩm mật ong",
    ["eat_10_trail_mixes"] = "Ăn 10 phần Hỗn hợp hạt quả",
    ["kill_10_crows"] = "Hạ 10 con quạ",
    ["kill_10_red_birds"] = "Hạ 10 con chim đỏ",
    ["kill_10_canaries_3"] = "Hạ 10 con chim hoàng yến",
    ["kill_10_puffins_2"] = "Hạ 10 Puffin",
    ["kill_10_hounds_4"] = "Hạ 10 Hound",
    ["kill_10_pigs_2"] = "Hạ 10 Pigman",
    ["kill_10_spiders_3"] = "Giết 10 nhện",
    ["chop_down_10_birchnut_trees"] = "Chặt 10 cây bạch dương",
    ["chop_down_something_10_times"] = "Chặt cây 10 lần",
    ["pick_10_grass"] = "Hái 10 bụi cỏ",
    ["pick_10_saplings"] = "Hái 10 cây non",
    ["pick_10_reeds"] = "Hái 10 bụi lau sậy",
    ["plant_10_birchnuts"] = "Trồng 10 hạt bạch dương",
    ["craft_item"] = "Chế tạo một vật phẩm",
}

STRINGS.UI.CRAFTING_FILTERS.REWARD = "Phần thưởng"
STRINGS.CHARACTERS.GENERIC.NOT_BLESSED = "Tôi chưa được ban phước để dùng vật này."
-- KLAUS_SACK
STRINGS.RECIPE_DESC.KLAUS_SACK = "Chứa đựng chương thứ tư"
STRINGS.RECIPE_DESC.DEER_ANTLER1 = "Gạc hươu một mắt"
-- DENCRAFT
STRINGS.RECIPE_DESC.RABBITHOLE = "Hố thỏ"
STRINGS.RECIPE_DESC.TALLBIRDNEST = "Tổ Tallbird"
STRINGS.RECIPE_DESC.HOUNDMOUND = "Gò Hound"
STRINGS.RECIPE_DESC.MOLEHILL = "Hang chuột chũi"
STRINGS.RECIPE_DESC.CATCOONDEN = "Gốc Rỗng"
STRINGS.RECIPE_DESC.MONKEYBARREL = "Khoang khỉ"
STRINGS.RECIPE_DESC.SLURTLEHOLE = "Gò đất Slurtle"
STRINGS.RECIPE_DESC.WALRUS_CAMP = "Trại Walrus"
STRINGS.RECIPE_DESC.WASPHIVE = "Tổ ong sát thủ"
STRINGS.RECIPE_DESC.OCEANVINE_COCOON = "Tổ Sea Strider"
STRINGS.RECIPE_DESC.SPIDERHOLE = "Hang Spilagmite"
STRINGS.RECIPE_DESC.MOONSPIDERDEN = "Hang Shattered Spider"
-- CLUSTERCRAFT
STRINGS.NAMES.BERRYBUSH_CLUSTER_CZ = STRINGS.NAMES.BERRYBUSH .. " 9×"
STRINGS.RECIPE_DESC.BERRYBUSH_CLUSTER_CZ = STRINGS.NAMES.BERRYBUSH .. " theo cụm"
STRINGS.NAMES.BERRYBUSH2_CLUSTER_CZ = STRINGS.NAMES.BERRYBUSH2 .. " 9×"
STRINGS.RECIPE_DESC.BERRYBUSH2_CLUSTER_CZ = STRINGS.NAMES.BERRYBUSH2 .. " theo cụm"
STRINGS.NAMES.BERRYBUSH_JUICY_CLUSTER_CZ = STRINGS.NAMES.BERRYBUSH_JUICY .. " 9×"
STRINGS.RECIPE_DESC.BERRYBUSH_JUICY_CLUSTER_CZ = STRINGS.NAMES.BERRYBUSH_JUICY .. " theo cụm"
STRINGS.NAMES.SAPLING_CLUSTER_CZ = STRINGS.NAMES.SAPLING .. " 9×"
STRINGS.RECIPE_DESC.SAPLING_CLUSTER_CZ = STRINGS.NAMES.SAPLING .. " theo cụm"
STRINGS.NAMES.SAPLING_MOON_CLUSTER_CZ = STRINGS.NAMES.SAPLING .. " ánh trăng" .. " 9×"
STRINGS.RECIPE_DESC.SAPLING_MOON_CLUSTER_CZ = STRINGS.NAMES.SAPLING .. " ánh trăng" .. " theo cụm"
STRINGS.NAMES.MARSH_BUSH_CLUSTER_CZ = STRINGS.NAMES.MARSH_BUSH .. " 9×"
STRINGS.RECIPE_DESC.MARSH_BUSH_CLUSTER_CZ = STRINGS.NAMES.MARSH_BUSH .. " theo cụm"
STRINGS.NAMES.GRASS_CLUSTER_CZ = STRINGS.NAMES.GRASS .. " 9×"
STRINGS.RECIPE_DESC.GRASS_CLUSTER_CZ = STRINGS.NAMES.GRASS .. " theo cụm"
STRINGS.NAMES.MONKEYTAIL_CLUSTER_CZ = STRINGS.NAMES.MONKEYTAIL .. " 9×"
STRINGS.RECIPE_DESC.MONKEYTAIL_CLUSTER_CZ = STRINGS.NAMES.MONKEYTAIL .. " theo cụm"
STRINGS.NAMES.ROCK_AVOCADO_BUSH_CLUSTER_CZ = STRINGS.NAMES.ROCK_AVOCADO_BUSH .. " 9×"
STRINGS.RECIPE_DESC.ROCK_AVOCADO_BUSH_CLUSTER_CZ = STRINGS.NAMES.ROCK_AVOCADO_BUSH .. " theo cụm"
STRINGS.NAMES.BANANABUSH_CLUSTER_CZ = STRINGS.NAMES.BANANABUSH .. " 9×"
STRINGS.RECIPE_DESC.BANANABUSH_CLUSTER_CZ = STRINGS.NAMES.BANANABUSH .. " theo cụm"
STRINGS.NAMES.BUTTERFLY_CLUSTER_CZ = STRINGS.NAMES.FLOWER .. " 9×"
STRINGS.RECIPE_DESC.BUTTERFLY_CLUSTER_CZ = STRINGS.NAMES.FLOWER .. " theo cụm"
STRINGS.NAMES.MOONBUTTERFLY_CLUSTER_CZ = STRINGS.NAMES.MOONBUTTERFLY_SAPLING .. " 9×"
STRINGS.RECIPE_DESC.MOONBUTTERFLY_CLUSTER_CZ = STRINGS.NAMES.MOONBUTTERFLY_SAPLING .. " theo cụm"
STRINGS.NAMES.PINECONE_CLUSTER_CZ = STRINGS.NAMES.PINECONE .. " 9×"
STRINGS.RECIPE_DESC.PINECONE_CLUSTER_CZ = STRINGS.NAMES.PINECONE .. " theo cụm"
STRINGS.NAMES.TWIGGY_NUT_CLUSTER_CZ = STRINGS.NAMES.TWIGGY_NUT .. " 9×"
STRINGS.RECIPE_DESC.TWIGGY_NUT_CLUSTER_CZ = STRINGS.NAMES.TWIGGY_NUT .. " theo cụm"
STRINGS.NAMES.ACORN_CLUSTER_CZ = STRINGS.NAMES.ACORN .. " 9×"
STRINGS.RECIPE_DESC.ACORN_CLUSTER_CZ = STRINGS.NAMES.ACORN .. " theo cụm"
STRINGS.NAMES.MARBLEBEAN_CLUSTER_CZ = STRINGS.NAMES.MARBLEBEAN .. " 9×"
STRINGS.RECIPE_DESC.MARBLEBEAN_CLUSTER_CZ = STRINGS.NAMES.MARBLEBEAN .. " theo cụm"
STRINGS.NAMES.LIVINGTREE_ROOT_CLUSTER_CZ = STRINGS.NAMES.LIVINGTREE_ROOT .. " 9×"
STRINGS.RECIPE_DESC.LIVINGTREE_ROOT_CLUSTER_CZ = STRINGS.NAMES.LIVINGTREE_ROOT .. " theo cụm"
STRINGS.NAMES.BEEMINE_CLUSTER_CZ = STRINGS.NAMES.BEEMINE .. " 9×"
STRINGS.RECIPE_DESC.BEEMINE_CLUSTER_CZ = STRINGS.NAMES.BEEMINE .. " theo cụm"
STRINGS.NAMES.TRAP_BRAMBLE_CLUSTER_CZ = STRINGS.NAMES.TRAP_BRAMBLE .. " 9×"
STRINGS.RECIPE_DESC.TRAP_BRAMBLE_CLUSTER_CZ = STRINGS.NAMES.TRAP_BRAMBLE .. " theo cụm"
STRINGS.NAMES.TRAP_TEETH_CLUSTER_CZ = STRINGS.NAMES.TRAP_TEETH .. " 9×"
STRINGS.RECIPE_DESC.TRAP_TEETH_CLUSTER_CZ = STRINGS.NAMES.TRAP_TEETH .. " theo cụm"
STRINGS.NAMES.TRAP_STARFISH_CLUSTER_CZ = STRINGS.NAMES.TRAP_STARFISH .. " 9×"
STRINGS.RECIPE_DESC.TRAP_STARFISH_CLUSTER_CZ = STRINGS.NAMES.TRAP_STARFISH .. " theo cụm"
STRINGS.NAMES.TRAP_FLYTRAP_CLUSTER_CZ = (STRINGS.NAMES.TRAP_FLYTRAP or "Pakkun") .. " 9×"  -- >>>> pakkun defined below
STRINGS.RECIPE_DESC.TRAP_FLYTRAP_CLUSTER_CZ = (STRINGS.NAMES.TRAP_FLYTRAP or "Pakkun") .. " theo cụm"  -- >>>> pakkun defined below
-- WES BALLOONS
STRINGS.NAMES.BALLOON_BEEFALO = "Bóng bay Beefalo"
STRINGS.RECIPE_DESC.BALLOON_BEEFALO = "Bất ngờ trên đống cứt!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BALLOON_BEEFALO = "Chúng nổi như thế nào?"
STRINGS.NAMES.BALLOON_BUNNYMAN = "Bóng bay Bunnyman"
STRINGS.RECIPE_DESC.BALLOON_BUNNYMAN = "Một đội quân đang đến!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BALLOON_BUNNYMAN = "Chúng nổi như thế nào?"
STRINGS.NAMES.BALLOON_BUTTERFLY = "Bóng bay Butterfly"
STRINGS.RECIPE_DESC.BALLOON_BUTTERFLY = "Bong bóng hoa có mùi thơm!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BALLOON_BUTTERFLY = "Chúng nổi như thế nào?"
STRINGS.NAMES.BALLOON_HOUND = "Bóng bay Hound"
STRINGS.RECIPE_DESC.BALLOON_HOUND = "Một trò đùa nhỏ không đau!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BALLOON_HOUND = "Chúng nổi như thế nào?"
STRINGS.NAMES.BALLOON_MERM = "Bóng bay Merm"
STRINGS.RECIPE_DESC.BALLOON_MERM = "Có lẽ ai đó thích nó?"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BALLOON_MERM = "Chúng nổi như thế nào?"
STRINGS.NAMES.BALLOON_PIG = "Bóng bay Pig"
STRINGS.RECIPE_DESC.BALLOON_PIG = "Món quà tuyệt vời cho Pig King!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BALLOON_PIG = "Chúng nổi như thế nào?"
STRINGS.NAMES.BALLOON_TENTACLE = "Bóng bay Tentacle"
STRINGS.RECIPE_DESC.BALLOON_TENTACLE = "Là một loại vũ khí nào đó?"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BALLOON_TENTACLE = "Chúng nổi như thế nào?"
STRINGS.NAMES.BALLOON_SPIDER = "Bóng bay Spider"
STRINGS.RECIPE_DESC.BALLOON_SPIDER = "Tôi có thể lẻn qua mạng nhện với cái này"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BALLOON_SPIDER = "Chúng nổi như thế nào?"
-- WEBBER MASKS
STRINGS.NAMES.FLUFFYHOUSE = "Nhà của Fluffy"
STRINGS.RECIPE_DESC.FLUFFYHOUSE = "Một ngôi nhà bông xù xứng tầm hoàng gia."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.FLUFFYHOUSE = "Không biết có gì ẩn náu bên trong nhỉ?"
STRINGS.ACTIONS.CALLFLUFFY = "Gọi Fluffy"
STRINGS.CHARACTERS.GENERIC.CALLFLUFFYFAIL1 = "Fluffy cần nghỉ ngơi thêm."
STRINGS.CHARACTERS.GENERIC.CALLFLUFFYFAIL2 = "Fluffy đang đi vắng."
STRINGS.ACTIONS.WEBBERMASKING = "Ngụy trang lãnh địa"
STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.CAST_SPELLBOOK.NO_RECIPE = "Mình cần nghiên cứu loài đó trước."
STRINGS.NAMES.WEBBERMASK_NORMAL = "Mặt nạ Spider"
STRINGS.RECIPE_DESC.WEBBERMASK_NORMAL = "Hòa mình vào đàn nhện."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WEBBERMASK_NORMAL = "Đã đến Halloween rồi sao?"
STRINGS.NAMES.WEBBERMASK_WARRIOR = "Mặt nạ Spider Warrior"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WEBBERMASK_WARRIOR = "Mong là nó cho mình giác quan nhện."
STRINGS.NAMES.WEBBERMASK_DROPPER = "Mặt nạ Dangling Depth Dweller"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WEBBERMASK_DROPPER = "Hoàn hảo để đi xin kẹo Halloween."
STRINGS.NAMES.WEBBERMASK_HIDER = "Mặt nạ Cave Spider"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WEBBERMASK_HIDER = "Để che những khuôn mặt xấu xí."
STRINGS.NAMES.WEBBERMASK_SPITTER = "Mặt nạ Spitter"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WEBBERMASK_SPITTER = "Trông giống hệt một con nhện phun."
STRINGS.NAMES.WEBBERMASK_MOON = "Mặt nạ Shattered Spider"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WEBBERMASK_MOON = "Chà! Đáng sợ thật!"
STRINGS.NAMES.WEBBERMASK_HEALER = "Mặt nạ Nurse Spider"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WEBBERMASK_HEALER = "Chiếc này trông dịu dàng hơn."
STRINGS.NAMES.WEBBERMASK_WATER = "Mặt nạ Sea Strider"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WEBBERMASK_WATER = "Ơ! Sao nó ướt thế?"
STRINGS.NAMES.WEBBERMASK_POISON = "Mặt nạ Venomous Spider"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WEBBERMASK_POISON = "Đeo thứ này ngứa mặt quá."
-- WENDY
STRINGS.NAMES.GHOSTLYELIXIR_TEMPERATURE = "Huyết thanh điều hòa nhiệt"
STRINGS.RECIPE_DESC.GHOSTLYELIXIR_TEMPERATURE = "Nó vừa ấm vừa lạnh theo một cách nào đó."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GHOSTLYELIXIR_TEMPERATURE = "Giống cà phê nóng có đá vậy."
STRINGS.NAMES.GHOSTLYELIXIR_SLOW = "Thuốc hãm động năng"
STRINGS.RECIPE_DESC.GHOSTLYELIXIR_SLOW = "Chứa điện tích làm chậm chuyển động."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GHOSTLYELIXIR_SLOW = "Hữu ích khi đuổi theo hoặc bị đuổi."
STRINGS.NAMES.GHOSTLYELIXIR_CHASNILUNAR = "Thuốc mỡ ánh trăng"
STRINGS.RECIPE_DESC.GHOSTLYELIXIR_CHASNILUNAR = "Chất lỏng được sức mạnh thiên thể phù phép."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GHOSTLYELIXIR_CHASNILUNAR = "Dùng nó để giao tiếp với thế giới bên kia."
STRINGS.NAMES.GHOSTLYELIXIR_CHASNISHADOW = "Thuốc bổ bóng tối"
STRINGS.RECIPE_DESC.GHOSTLYELIXIR_CHASNISHADOW = "Đối mặt với những bóng đen ẩn sâu bên trong."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GHOSTLYELIXIR_CHASNISHADOW = "Lấp lánh tinh chất của bóng tối vĩnh cửu."
STRINGS.CHARACTERS.GENERIC.SISTURN_TELE_FAIL = "Mình không làm được việc đó."
-- WOODIE
STRINGS.CHARACTERS.GENERIC.WOODIE_TRANSFORM_FAIL = "Mình chưa thể biến hình."
-- ZEUS BLESSING
STRINGS.NAMES.THUNDER_HAT = "Vương miện kim tuyến"
STRINGS.RECIPE_DESC.THUNDER_HAT = "Mũ lấp lánh"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.THUNDER_HAT = "Sức mạnh được ban bởi các thần"
STRINGS.NAMES.THUNDER_SPEAR = "Thương Sấm Sét"
STRINGS.RECIPE_DESC.THUNDER_SPEAR = "Một cây thương lung linh"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.THUNDER_SPEAR = "Tôi tự hỏi món cổ vật này đã bao nhiêu tuổi?"
STRINGS.CHARACTERS.GENERIC.THUNDER_SPEAR_FAIL = "Cần thêm xung điện để sạc."
STRINGS.NAMES.THUNDER_ARMOR = "Áo choàng của Thor"
STRINGS.RECIPE_DESC.THUNDER_ARMOR = "Một chiếc áo lung linh"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.THUNDER_ARMOR = "Một chiếc áo xứng đáng cho một chiến binh"
-- HEPHAESTUS BLESSING
STRINGS.NAMES.FIRE_HAT = "Mũ đầu rồng"
STRINGS.RECIPE_DESC.FIRE_HAT = "Xác đầu của một con rồng lửa"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.FIRE_HAT = "Là ai có sức mạnh như vậy để giết một con rồng?"
STRINGS.NAMES.FIRE_SPEAR = "Kiếm của Hephaestus"
STRINGS.RECIPE_DESC.FIRE_SPEAR = "Thanh kiếm được rèn bởi nguyên liệu đặc biệt"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.FIRE_SPEAR = "Rèn bởi chính Hephaestus"
STRINGS.NAMES.FIRE_ARMOR = "Khăn Natsu"
STRINGS.RECIPE_DESC.FIRE_ARMOR = "Khăn sát long lửa"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.FIRE_ARMOR = "Nó được sử dụng bởi kẻ diệt rồng lửa"
STRINGS.NAMES.FIRE_STAFF = "Gậy Thiên Thạch"
STRINGS.RECIPE_DESC.FIRE_STAFF = "Gậy lửa mạnh mẽ"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.FIRE_STAFF = "Nhãn ghi: Để xa tầm tay trẻ em."
STRINGS.CHARACTERS.GENERIC.FIRE_STAFF_FAIL_1 = "Cần nhiều sức mạnh lửa hơn nữa."
STRINGS.CHARACTERS.GENERIC.FIRE_STAFF_FAIL_2 = "Ta không được ban phước bởi thần Hephaestus."
STRINGS.NAMES.FIRE_ROCK = "Kim loại của Hephaestus"
STRINGS.RECIPE_DESC.FIRE_ROCK = "Kim loại quý để rèn vũ khí mạnh mẽ."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.FIRE_ROCK = "Đó là một tảng đá lửa."
-- EXPERTWILLOW4
STRINGS.WILLOW_SPELL_REMNANT = "Tàn dư lửa (3 tàn lửa)"
STRINGS.WILLOW_SPELL_BLINK = "Kích hoạt tàn dư gần (0 tàn lửa)"
STRINGS.WILLOW_SPELL_TELEPORT = "Kích hoạt tàn dư xa (0 tàn lửa)"
STRINGS.WILLOW_SPELL_SHIELD = "Lá chắn lửa (2 tàn lửa)"
STRINGS.CHARACTERS.GENERIC.ANNOUNCE_CHASNI_NO_EMBER = "Không tìm thấy tàn dư đang hoạt động."
-- ARES BLESSING
STRINGS.NAMES.MARBLED_SPEAR = "Chùy cẩm thạch"
STRINGS.RECIPE_DESC.MARBLED_SPEAR = "Nó cần thức ăn để chế tạo vũ khí"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MARBLED_SPEAR = "Dành cho những cú giáng."
STRINGS.NAMES.MARBLED_ARMOR = "Giáp thần Ares"
STRINGS.RECIPE_DESC.MARBLED_ARMOR = "Giáp cực kì nặng"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MARBLED_ARMOR = "Nâng lên.. nặng quá"
STRINGS.NAMES.MARBLED_HAT = "Đấu sĩ Galea"
STRINGS.RECIPE_DESC.MARBLED_HAT = "Mũ để chiến đấu trong Đấu Trường Máu."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MARBLED_HAT = "Mũ bảo hiểm trông dữ dằn"
-- EREBUS BLESSING
STRINGS.NAMES.SHADOW_AXE = "Rìu Bóng tối"
STRINGS.RECIPE_DESC.SHADOW_AXE = "Bổ xuống bởi tâm trí"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SHADOW_AXE = "Tại sao bất cứ ai cũng sử dụng thứ này? Thật đáng sợ."
STRINGS.NAMES.SHADOW_PICKAXE = "Cúp Bóng tối"
STRINGS.RECIPE_DESC.SHADOW_PICKAXE = "Nghiền nát tâm trí ngươi."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SHADOW_PICKAXE = "Tại sao bất cứ ai cũng sử dụng thứ này? Thật đáng sợ."
STRINGS.NAMES.SHADOW_HAMMER = "Búa Bóng tối"
STRINGS.RECIPE_DESC.SHADOW_HAMMER = "Đập tan tâm trí ngươi."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SHADOW_HAMMER = "Tại sao bất cứ ai cũng sử dụng thứ này? Thật đáng sợ."
STRINGS.NAMES.SHADOW_SHOVEL = "Xẻng bóng tối"
STRINGS.RECIPE_DESC.SHADOW_SHOVEL = "Đào xới tâm trí ngươi."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SHADOW_SHOVEL = "Sao lại có người dùng thứ này? Đáng sợ quá."
STRINGS.NAMES.SHADOW_PITCHFORK = "Chĩa ba bóng tối"
STRINGS.RECIPE_DESC.SHADOW_PITCHFORK = "Đâm xuyên tâm trí ngươi."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SHADOW_PITCHFORK = "Sao lại có người dùng thứ này? Đáng sợ quá."
STRINGS.NAMES.SHADOW_OAR = "Mái chèo bóng tối"
STRINGS.RECIPE_DESC.SHADOW_OAR = "Khuấy đảo tâm trí ngươi."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SHADOW_OAR = "Sao lại có người dùng thứ này? Đáng sợ quá."
STRINGS.NAMES.SHADOW_SCYTHE = "Lưỡi hái bóng tối"
STRINGS.RECIPE_DESC.SHADOW_SCYTHE = "Cắt đứt tâm trí ngươi."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SHADOW_SCYTHE = "Sao lại có người dùng thứ này? Đáng sợ quá."
-- EXPERTWAXWELL4
STRINGS.WAXWELL_SPELL_HEAL = "Làn sóng bóng tối"
STRINGS.WAXWELL_SPELL_LIGHT = "Đốm sáng bóng tối"
STRINGS.WAXWELL_SPELL_INVULNERABILITY = "Cõi bóng tối"
STRINGS.WAXWELL_SPELL_ACHIEVEMENT = "Tham vọng bóng tối"
STRINGS.CHARACTERS.GENERIC.ANNOUNCE_CHASNI_NOT_ENOUGH_SANITY = "Mình không đủ tỉnh táo để làm việc đó."
-- WINONA
STRINGS.NAMES.CHASNI_BASEFAN = "Quạt dao động"
STRINGS.RECIPE_DESC.CHASNI_BASEFAN = "Giảm dị ứng phấn hoa và giữ bạn khô ráo."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SPRINKLER = "Nước.. mày nghĩ mày là ai?"
STRINGS.NAMES.CHASNI_SPRINKLER = "Vòi phun nước"
STRINGS.RECIPE_DESC.CHASNI_SPRINKLER = "Cây nước."
STRINGS.NAMES.CHASNI_CITY_LAMP = "Cột đèn"
STRINGS.RECIPE_DESC.CHASNI_CITY_LAMP = "Ta không thể tin rằng ta có thể làm điều này."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CITY_LAMP = {}
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CITY_LAMP.GENERIC = "Lửa tự nhiên. Không có khoa học liên quan."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CITY_LAMP.ON = "Ánh đèn xua tan bóng tối."
STRINGS.NAMES.CHASNI_PUGALISK_TRAPDOOR = "Hố Pugalisk"
STRINGS.RECIPE_DESC.CHASNI_PUGALISK_TRAPDOOR = "Dịch chuyển tài nguyên"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_PUGALISK_TRAPDOOR = "Ờ, điều đó có vẻ đáng ngại"
STRINGS.ROPEMAKER = "Dây 3000"
STRINGS.NAMES.ROPEMAKER = "Làm dây 3000"
STRINGS.RECIPE_DESC.ROPEMAKER = "Máy làm dây cho thợ xây"
STRINGS.BOARDSMAKER = "Ván gỗ 3000"
STRINGS.NAMES.BOARDSMAKER = "Làm ván gỗ 3000"
STRINGS.RECIPE_DESC.BOARDSMAKER = "Máy làm gỗ cho thợ xây"
STRINGS.CUTSTONEMAKER = "Đá cắt 3000"
STRINGS.NAMES.CUTSTONEMAKER = "Làm đá cắt 3000"
STRINGS.RECIPE_DESC.CUTSTONEMAKER = "Máy làm đá cắt cho thợ xây"
STRINGS.GEMMAKER = "Ngọc 3000"
STRINGS.NAMES.GEMMAKER = "Làm ngọc 3000"
STRINGS.RECIPE_DESC.GEMMAKER = "Máy chế tạo đá quý cho thợ xây dựng"
STRINGS.NAMES.CHASNI_TELEBRELLA = "Ô dịch chuyển"
STRINGS.NAMES.CHASNI_TELIPAD = "Tấm dịch chuyển"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_TELIPAD = "Nó hoạt động nhờ khoa học."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_TELEBRELLA = "Nào-bắn tôi ra khỏi đây!"
STRINGS.RECIPE_DESC.CHASNI_TELEBRELLA = "Một cuộc cách mạng di chuyển"
STRINGS.RECIPE_DESC.CHASNI_TELIPAD = "Một nền tảng mang tính cách mạng"
STRINGS.NAMES.CHASNI_THUMPER = "Máy dập"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_THUMPER = "Làm tất cả các công việc khó khăn cho ta."
STRINGS.RECIPE_DESC.CHASNI_THUMPER = "Một máy dập cách mạng"
STRINGS.ACTIONS.CHASNI_SMELT = "Nấu chảy"
STRINGS.NAMES.PROPELOMATIC = "Máy tạo mùi muối"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.PROPELOMATIC = "Có mùi mặn."
STRINGS.RECIPE_DESC.PROPELOMATIC = "Mùi nhân tạo thu hút các loài thú."
STRINGS.NAMES.CHRONOFLUX = "Cổ vật biến đổi vũ trụ"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHRONOFLUX = "Trông như một thảm họa mang tính khoa học."
STRINGS.RECIPE_DESC.CHRONOFLUX = "Một cơ cấu đồng hồ phức tạp."
STRINGS.NAMES.ACCOMPLISHRINE = "Đền thành tựu"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ACCOMPLISHRINE = "Mình muốn dùng nó và muốn cả thế giới biết điều đó."
STRINGS.RECIPE_DESC.ACCOMPLISHRINE = "Đồng hồ bấm giờ cho người chơi phá đảo nhanh."
STRINGS.CHARACTERS.GENERIC.ACCOMPLISHRINESUCCESS = "Bắt đầu cày cuốc thôi!"
STRINGS.NAMES.CRAFTERCHEST = "Rương chế tạo"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CRAFTERCHEST = "Nó sẽ giúp ích khi làm đồ thủ công."
STRINGS.RECIPE_DESC.CRAFTERCHEST = "Chiếc rương do thợ chế tạo làm ra, dành cho thợ chế tạo. (Tối đa 1 chiếc mỗi thế giới.)"
STRINGS.CHARACTERS.GENERIC.CRAFTER_EXIST = "Không thể có hơn 1 Rương chế tạo."
STRINGS.NAMES.CHASNI_WINONA_BATTERY = "Pin không dây"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WINONA_BATTERY = "Hay quá! Giờ mình không còn vấp phải dây điện nữa."
STRINGS.RECIPE_DESC.CHASNI_WINONA_BATTERY = "Một kỳ quan tiện lợi của thời hiện đại."
STRINGS.NAMES.CHASNI_BANNER_MISS = "Cờ mời khiêu vũ"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BANNER_MISS = "Ở gần nó, mình bỗng thấy nhanh nhẹn lạ thường."
STRINGS.RECIPE_DESC.CHASNI_BANNER_MISS = "Bước chân thật nhẹ nào!"
STRINGS.NAMES.CHASNI_BANNER_XP = "Cờ tinh thần cộng đồng"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BANNER_XP = "Cùng nhau tiến bộ nhé."
STRINGS.RECIPE_DESC.CHASNI_BANNER_XP = "Có đồng đội thì việc gì cũng thành."
STRINGS.NAMES.CHASNI_BANNER_REPAIR = "Cờ phế liệu của Winona"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BANNER_REPAIR = "Phế liệu vẫn có giá trị!"
STRINGS.RECIPE_DESC.CHASNI_BANNER_REPAIR = "Vá nó lại bằng sự lạc quan và vài con bu lông."
STRINGS.NAMES.CHASNI_BANNER_MOON = "Cờ dìu dắt của Wagstaff"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BANNER_MOON = "Wagstaff quả là biết cách giúp mọi người hồi phục."
STRINGS.RECIPE_DESC.CHASNI_BANNER_MOON = "Di sản của một trí tuệ lỗi lạc."
STRINGS.NAMES.CHASNI_BANNER_SHADOW = "Cờ tình chị em của Charlie"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BANNER_SHADOW = "Xem ra cô ấy vẫn đang giật dây."
STRINGS.RECIPE_DESC.CHASNI_BANNER_SHADOW = "Món quà từ vị nữ chủ nhân vô hình."
-- WALTER
STRINGS.NAMES.CHASNI_MAGNIFYING_GLASS = "Kính lúp"
STRINGS.RECIPE_DESC.CHASNI_MAGNIFYING_GLASS = "Một công cụ tốt để khám phá"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_MAGNIFYING_GLASS = "Khoa học đang chờ đợi!"
STRINGS.ACTIONS.CHASNI_RESEARCH = "Nghiên cứu"
STRINGS.CHARACTERS.GENERIC.CHASNI_MAGNIFYING_GLASS_FAIL_1 = "Ta đã nghiên cứu nó gần đây."
STRINGS.CHARACTERS.GENERIC.CHASNI_MAGNIFYING_GLASS_FAIL_2 = "Ta không thể nghiên cứu thứ đó."
STRINGS.NAMES.WETPAPER = "Giấy cói ướt"
STRINGS.RECIPE_DESC.WETPAPER = "Giấy cói sũng nước."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WETPAPER = "Để lau đi lỗi lầm trên hành trình nghiên cứu."
STRINGS.ACTIONS.CHASNI_WIPE = "Lau"
STRINGS.NAMES.CAMPINGBAG = "Ba lô du hành"
STRINGS.RECIPE_DESC.CAMPINGBAG = "Một chiếc túi để cắm trại."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CAMPINGBAG = "Ngươi không bao giờ có thể có quá nhiều túi!"
STRINGS.NAMES.ADVENTURE_HAT = "Mũ cối thám hiểm"
STRINGS.RECIPE_DESC.ADVENTURE_HAT = "Một chiếc mũ phiêu lưu phù hợp."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ADVENTURE_HAT = "Một chiếc mũ phiêu lưu phù hợp."
STRINGS.NAMES.CHASNI_SLINGSHOT_SPLITSHOT = "Ná bắn đạn tách đôi"
STRINGS.RECIPE_DESC.CHASNI_SLINGSHOT_SPLITSHOT = "Ná BFS"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SLINGSHOT_SPLITSHOT = "Píu píu!"
STRINGS.NAMES.CHASNI_SLINGSHOT_GEREMINATE = "Ná bắn nhiều đạn"
STRINGS.RECIPE_DESC.CHASNI_SLINGSHOT_GEREMINATE = "Ná DFS."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SLINGSHOT_GEREMINATE = "Píu píu píu píu píu!"
-- AMMO
STRINGS.NAMES.CHASNI_SLINGSHOTAMMO_BOMB = "Đạn nổ"
STRINGS.RECIPE_DESC.CHASNI_SLINGSHOTAMMO_BOMB = "Thứ này sẽ nổ tung!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SLINGSHOTAMMO_BOMB = "Bắn vút lên nào!"
STRINGS.NAMES.CHASNI_SLINGSHOTAMMO_EGG = "Đạn ấp nở"
STRINGS.RECIPE_DESC.CHASNI_SLINGSHOTAMMO_EGG = "Có một chú chim bên trong."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SLINGSHOTAMMO_EGG = "Nó sẽ nở chứ?"
STRINGS.NAMES.CHASNI_SLINGSHOTAMMO_PILLS = "Thuốc viên"
STRINGS.RECIPE_DESC.CHASNI_SLINGSHOTAMMO_PILLS = "Giúp đồng đội trong chiến đấu."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SLINGSHOTAMMO_PILLS = "Vị đắng quá."
STRINGS.NAMES.CHASNI_SLINGSHOTAMMO_LUNAR = "Đạn Mặt Trăng"
STRINGS.RECIPE_DESC.CHASNI_SLINGSHOTAMMO_LUNAR = "Làm từ sỏi cuội được khai sáng."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SLINGSHOTAMMO_LUNAR = "Những viên sỏi nhỏ này chứa sức mạnh Mặt Trăng rất lớn."
STRINGS.NAMES.CHASNI_SLINGSHOTAMMO_SHADOW = "Đạn Bóng Tối"
STRINGS.RECIPE_DESC.CHASNI_SLINGSHOTAMMO_SHADOW = "Làm từ sỏi cuội bị bóng tối bao phủ."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SLINGSHOTAMMO_SHADOW = "Những viên sỏi nhỏ này chứa sức mạnh Bóng Tối rất lớn."
-- WX
STRINGS.NAMES.CHASNI_WX78_SCANNER = "Máy phân tích sinh học Pro"
STRINGS.NAMES.CHASNI_WX78_SCANNER_ITEM = "Máy phân tích sinh học Pro"
STRINGS.NAMES.CHASNI_WX78_SCANNER_SUCCEEDED = "Máy phân tích sinh học Pro"
STRINGS.RECIPE_DESC.CHASNI_WX78_SCANNER_ITEM = "Hậu duệ của J1M1."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WX78_SCANNER_ITEM = {}
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WX78_SCANNER_ITEM.GENERIC = "Nó tên là James."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WX78_SCANNER_ITEM.HUNTING = "Thu thập dữ liệu đó! "
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WX78_SCANNER_ITEM.SCANNING = "Có vẻ nó đã tìm thấy thứ gì đó."
STRINGS.NAMES.WX78MODULE_CHASNI_SAVE = "Mạch bảo vệ"
STRINGS.RECIPE_DESC.WX78MODULE_CHASNI_SAVE = "Thiên thần hộ mệnh cho đồ vật vô tri sao?"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WX78MODULE_CHASNI_SAVE = "Bao nhiêu khoa học gói gọn trong một thiết bị tí hon."
STRINGS.NAMES.WX78MODULE_CHASNI_EXP = "Mạch kinh nghiệm"
STRINGS.RECIPE_DESC.WX78MODULE_CHASNI_EXP = "AI cải tiến giúp tích lũy kinh nghiệm nhanh hơn."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WX78MODULE_CHASNI_EXP = "Bao nhiêu khoa học gói gọn trong một thiết bị tí hon."
STRINGS.NAMES.WX78MODULE_CHASNI_ACHIEV = "Mạch thành tựu"
STRINGS.RECIPE_DESC.WX78MODULE_CHASNI_ACHIEV = "Dành cho những robot có thành tích xuất sắc."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WX78MODULE_CHASNI_ACHIEV = "Bao nhiêu khoa học gói gọn trong một thiết bị tí hon."
STRINGS.NAMES.WX78MODULE_CHASNI_MOON_SOUL = "Mạch Gestalt"
STRINGS.RECIPE_DESC.WX78MODULE_CHASNI_MOON_SOUL = "Nghe nói nó có thể thu hút linh hồn Mặt Trăng."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WX78MODULE_CHASNI_MOON_SOUL = "Bao nhiêu khoa học gói gọn trong một thiết bị tí hon."
STRINGS.NAMES.WX78MODULE_CHASNI_MOON_SPEAR = "Mạch giáo Mặt Trăng"
STRINGS.RECIPE_DESC.WX78MODULE_CHASNI_MOON_SPEAR = "Cây giáo Mặt Trăng lao vào tấn công."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WX78MODULE_CHASNI_MOON_SPEAR = "Bao nhiêu khoa học gói gọn trong một thiết bị tí hon."
STRINGS.NAMES.WX78MODULE_CHASNI_SHADOW_MONSTER = "Mạch bóng tối"
STRINGS.RECIPE_DESC.WX78MODULE_CHASNI_SHADOW_MONSTER = "Xua đuổi bóng tối."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WX78MODULE_CHASNI_SHADOW_MONSTER = "Bao nhiêu khoa học gói gọn trong một thiết bị tí hon."
STRINGS.NAMES.WX78MODULE_CHASNI_SHADOW_SHIELD = "Mạch khiên hắc ám"
STRINGS.RECIPE_DESC.WX78MODULE_CHASNI_SHADOW_SHIELD = "Chiếc khiên hắc ám lao đến bảo vệ."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WX78MODULE_CHASNI_SHADOW_SHIELD = "Bao nhiêu khoa học gói gọn trong một thiết bị tí hon."
STRINGS.NAMES.CHASNI_WX78_FOODBRICK = "Thanh dinh dưỡng ma thuật"
STRINGS.RECIPE_DESC.CHASNI_WX78_FOODBRICK = "Thanh dinh dưỡng ma thuật"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WX78_FOODBRICK = {}
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WX78_FOODBRICK.WET =  "Thử ăn khi còn ướt xem sao!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WX78_FOODBRICK.GENERIC =  "Nó cứng quá, không ăn được."
-- WARLY
STRINGS.NAMES.CHEFHAT = "Mũ đầu bếp trắng"
STRINGS.RECIPE_DESC.CHEFHAT = "Trông như một đầu bếp chuyên nghiệp"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHEFHAT = "Đó có phải là mũ của Gordon không?"
STRINGS.NAMES.CHEFPACKRED = "Túi đầu bếp đỏ"
STRINGS.RECIPE_DESC.CHEFPACKRED = "Làm mới món ăn của bạn."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHEFPACKRED = "Túi màu đỏ của mánh khóe đầu bếp!"
STRINGS.NAMES.FRYINGPAN = "Chảo chiên"
STRINGS.RECIPE_DESC.FRYINGPAN = "Để tạo ra món ngon đầu bếp."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.FRYINGPAN = "Hương vị thơm ngon trên mỗi cú vung."
STRINGS.NAMES.BENTOBOX = "Hộp cơm Bento"
STRINGS.RECIPE_DESC.BENTOBOX = "Một hộp cơm nhỏ gọn. Ngăn nắp thật!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BENTOBOX = "Ai mà không thích cơm hộp chứ?"
STRINGS.ACTIONS.CHASNI_BOX = "Bỏ vào"
-- FOOD
STRINGS.NAMES.CHASNI_PORTABLEGRILLER_ITEM = "Bếp nướng di động"
STRINGS.RECIPE_DESC.CHASNI_PORTABLEGRILLER_ITEM = "Dành cho người sành bếp núc, chế biến những món truyền thống chuẩn vị từ nhiều nền ẩm thực."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_PORTABLEGRILLER_ITEM = {}
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_PORTABLEGRILLER_ITEM.GENERIC = "Để mình nấu cho!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_PORTABLEGRILLER_ITEM.DONE = "Thơm nức mũi! "
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_PORTABLEGRILLER_ITEM.COOKING_LONG = "Món này sẽ mất khá lâu mới chín."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_PORTABLEGRILLER_ITEM.COOKING_SHORT = "Sắp xong rồi! "
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_PORTABLEGRILLER_ITEM.EMPTY = "Chắc chẳng có gì trong đó đâu."
STRINGS.NAMES.CHASNI_MOONCAKE = "Bánh Trung Thu da tuyết"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_MOONCAKE = "Món tráng miệng Trung Quốc thường dùng trong Tết Trung Thu."
STRINGS.NAMES.CHASNI_BALUT = "Trứng vịt lộn Balut"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BALUT = "Trứng vịt lộn của Philippines."
STRINGS.NAMES.CHASNI_POPCORN = "Bắp rang Garret"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POPCORN = "Bắp rang thượng hạng từ Chicago."
STRINGS.NAMES.CHASNI_BRIGADEIRO = "Kẹo Brigadeiro"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BRIGADEIRO = "Kẹo sô cô la đặc sản Brazil."
STRINGS.NAMES.CHASNI_TUMPENG = "Cơm Tumpeng"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_TUMPENG = "Món cơm hình nón của Indonesia."
STRINGS.NAMES.CHASNI_KYIVCAKE = "Bánh Kievsky"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_KYIVCAKE = "Bánh kem bơ của Ukraina."
STRINGS.NAMES.CHASNI_EMPANADAS = "Bánh Empanada"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_EMPANADAS = "Bánh nhân mặn của Mỹ Latinh."
STRINGS.NAMES.CHASNI_KIMCHI = "Dưa chuột muối Ba Lan"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_KIMCHI = "Dưa chuột muối kiểu Ba Lan."
STRINGS.NAMES.CHASNI_ANZAC = "Bánh quy Anzac"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_ANZAC = "Bánh quy yến mạch ngọt của Úc và New Zealand."
STRINGS.NAMES.CHASNI_MOPANE = "Món hầm Mopane"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_MOPANE = "Một món đặc sản châu Phi lạ miệng."
-- SONG
STRINGS.NAMES.CHASNI_BATTLESONG_INSTANT_RECHARGE = "Khúc hát dồn dập"
STRINGS.RECIPE_DESC.CHASNI_BATTLESONG_INSTANT_RECHARGE = "Nạp thêm lượt sử dụng cho công cụ."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BATTLESONG_INSTANT_RECHARGE = "Chỉ Wathgrithr mới sử dụng được."
STRINGS.CHARACTERS.WATHGRITHR.ANNOUNCE_CHASNI_BATTLESONG_INSTANT_RECHARGE_BUFF = "\"Hãy để giai điệu tiếp thêm sức mạnh!\""
STRINGS.NAMES.CHASNI_BATTLESONG_INSTANT_STOPMOVE = "Giai điệu ngắt quãng"
STRINGS.RECIPE_DESC.CHASNI_BATTLESONG_INSTANT_STOPMOVE = "Hôm nay không có màn diễn thêm."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BATTLESONG_INSTANT_STOPMOVE = "Chỉ Wathgrithr mới sử dụng được."
STRINGS.CHARACTERS.WATHGRITHR.ANNOUNCE_CHASNI_BATTLESONG_INSTANT_STOPMOVE_BUFF = "\"Lời thơ hùng tráng khiến khán giả choáng váng!\""
STRINGS.NAMES.CHASNI_BATTLESONG_CHANNEL_LUNAR = "Khúc tình ca Selemene"
STRINGS.RECIPE_DESC.CHASNI_BATTLESONG_CHANNEL_LUNAR = "Để phụng sự Selemene."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BATTLESONG_CHANNEL_LUNAR = "Chỉ Wathgrithr mới sử dụng được."
STRINGS.CHARACTERS.WATHGRITHR.ANNOUNCE_CHASNI_BATTLESONG_CHANNEL_LUNAR_BUFF = "\"Trăng càng tròn, lòng thương xót của ta càng vơi.\""
STRINGS.NAMES.CHASNI_BATTLESONG_CHANNEL_SHADOW = "Khúc cầu hồn bằng thơ"
STRINGS.RECIPE_DESC.CHASNI_BATTLESONG_CHANNEL_SHADOW = "Giai điệu ma quỷ nuốt chửng linh hồn ngươi."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BATTLESONG_CHANNEL_SHADOW = "Chỉ Wathgrithr mới sử dụng được."
STRINGS.CHARACTERS.WATHGRITHR.ANNOUNCE_CHASNI_BATTLESONG_CHANNEL_SHADOW_BUFF = "\"Ozh gluth izh. Arkosh izh-domosh.\""
STRINGS.NAMES.CHASNI_BATTLESONG_SAILOR = "Thánh ca hải tặc"
STRINGS.RECIPE_DESC.CHASNI_BATTLESONG_SAILOR = "Đóng kín các cửa hầm!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BATTLESONG_SAILOR = "Chỉ Wathgrithr mới sử dụng được."
STRINGS.NAMES.CHASNI_BATTLESONG_LIGHTNING = "Khúc dạo đầu tích điện"
STRINGS.RECIPE_DESC.CHASNI_BATTLESONG_LIGHTNING = "Linh hồn của một vở đại nhạc kịch!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BATTLESONG_LIGHTNING = "Chỉ Wathgrithr mới sử dụng được."
STRINGS.NAMES.SONGFOLDER = "Tập nhạc"
STRINGS.RECIPE_DESC.SONGFOLDER = "Tràn đầy giai điệu"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SONGFOLDER = "Ta có thể nghe các giai điệu ở đây"
-- BOOK
STRINGS.NAMES.CHASNI_BOOK_GATHER = "Tự động 101"
STRINGS.RECIPE_DESC.CHASNI_BOOK_GATHER = "Giảm lao động thủ công."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BOOK_GATHER = "Làm việc khôn ngoan hơn, đỡ tốn sức hơn."
STRINGS.NAMES.CHASNI_BOOK_TELEPORT = "Cô gái du hành"
STRINGS.RECIPE_DESC.CHASNI_BOOK_TELEPORT = "Ghép từ những cuộn giấy dịch chuyển."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BOOK_TELEPORT = "Ta sẽ đi đâu đây?"
STRINGS.NAMES.CHASNI_BOOK_SHIELD = "Ánh sáng hộ vệ"
STRINGS.RECIPE_DESC.CHASNI_BOOK_SHIELD = "Truyền thuyết kể rằng, cuốn sách này bảo vệ ngươi khỏi quái vật."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BOOK_SHIELD = "Ta thấy an toàn rồi."
STRINGS.NAMES.CHASNI_BOOK_SHADOW = "Hắc thuật thư"
STRINGS.RECIPE_DESC.CHASNI_BOOK_SHADOW = "Nơi tri thức giao thoa với lời nguyền."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BOOK_SHADOW = "Cuốn sách bị nguyền rủa hứa hẹn sức mạnh với cái giá hiểm nguy."
STRINGS.NAMES.CHASNI_BOOK_LUNAR = "Sách Vishanti"
STRINGS.RECIPE_DESC.CHASNI_BOOK_LUNAR = "Tri thức và sự bảo hộ đan xen."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BOOK_LUNAR = "Ngọn hải đăng soi sáng giữa bóng tối."
STRINGS.NAMES.BOOKPACK = "Túi đựng sách"
STRINGS.RECIPE_DESC.BOOKPACK = "Thủ thư phải có."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BOOKPACK = "Ta thấy an toàn rồi."
-- WATCHES
STRINGS.NAMES.WATCHCASE = "Hộp đồng hồ"
STRINGS.RECIPE_DESC.WATCHCASE = "Hộp đựng đồng hồ của bạn"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WATCHCASE = "Bảo quản những đồng hồ cổ"
STRINGS.NAMES.CHASNI_POCKETWATCH_BLOOM = "Đồng hồ sinh sôi"
STRINGS.RECIPE_DESC.CHASNI_POCKETWATCH_BLOOM = "Cũng giống như khi xuân sang"
STRINGS.CHARACTERS.GENERIC.CHASNI_POCKETWATCH_BLOOM_FAIL = "Chỉ có thể sử dụng bởi Wanda"
STRINGS.CHARACTERS.WANDA.CHASNI_POCKETWATCH_BLOOM_FAIL = "Giờ chưa phải lúc!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_BLOOM = {}
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_BLOOM.GENERIC = "Ta cá là có rất nhiều khoa học thú vị bên trong đấy "
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_BLOOM.RECHARGING = "Nó đang sạc.. không thấy à? "
STRINGS.NAMES.CHASNI_POCKETWATCH_BURNT = "Đồng hồ âm ỉ"
STRINGS.RECIPE_DESC.CHASNI_POCKETWATCH_BURNT = "Tiện dụng vào mùa hè."
STRINGS.CHARACTERS.GENERIC.CHASNI_POCKETWATCH_BURNT_FAIL = "Chỉ có thể sử dụng bởi Wanda"
STRINGS.CHARACTERS.WANDA.CHASNI_POCKETWATCH_BURNT_FAIL = "Giờ chưa phải lúc!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_BURNT = {}
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_BURNT.GENERIC = "Ta cá là có rất nhiều khoa học thú vị bên trong đấy "
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_BURNT.RECHARGING = "Nó đang sạc.. không thấy à? "
STRINGS.NAMES.CHASNI_POCKETWATCH_CORRUPT = "Đồng hồ nguyền rủa"
STRINGS.RECIPE_DESC.CHASNI_POCKETWATCH_CORRUPT = "Đừng đùa với dòng chảy thời gian."
STRINGS.CHARACTERS.GENERIC.CHASNI_POCKETWATCH_CORRUPT_FAIL = "Chỉ có thể sử dụng bởi Wanda"
STRINGS.CHARACTERS.WANDA.CHASNI_POCKETWATCH_CORRUPT_FAIL = "Giờ chưa phải lúc!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_CORRUPT = {}
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_CORRUPT.GENERIC = "Ta cá là có rất nhiều khoa học thú vị bên trong đấy "
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_CORRUPT.RECHARGING = "Nó đang sạc.. không thấy à? "
STRINGS.NAMES.CHASNI_POCKETWATCH_DECONSTRUCT = "Đồng hồ ngưng đọng"
STRINGS.RECIPE_DESC.CHASNI_POCKETWATCH_DECONSTRUCT = "Công cụ tháo dỡ."
STRINGS.CHARACTERS.GENERIC.CHASNI_POCKETWATCH_DECONSTRUCT_FAIL = "Chỉ có thể sử dụng bởi Wanda"
STRINGS.CHARACTERS.WANDA.CHASNI_POCKETWATCH_DECONSTRUCT_FAIL = "Giờ chưa phải lúc!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_DECONSTRUCT = {}
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_DECONSTRUCT.GENERIC = "Ta cá là có rất nhiều khoa học thú vị bên trong đấy "
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_DECONSTRUCT.RECHARGING = "Nó đang sạc.. không thấy à? "
STRINGS.NAMES.CHASNI_POCKETWATCH_REPAIR = "Đồng hồ vá thuyền"
STRINGS.RECIPE_DESC.CHASNI_POCKETWATCH_REPAIR = "Giờ không phải lúc chết đuối."
STRINGS.CHARACTERS.GENERIC.CHASNI_POCKETWATCH_REPAIR_FAIL = "Chỉ có thể sử dụng bởi Wanda"
STRINGS.CHARACTERS.WANDA.CHASNI_POCKETWATCH_REPAIR_FAIL = "Giờ chưa phải lúc!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_REPAIR = {}
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_REPAIR.GENERIC = "Ta cá là có rất nhiều khoa học thú vị bên trong đấy "
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_REPAIR.RECHARGING = "Nó đang sạc.. không thấy à? "
STRINGS.NAMES.CHASNI_POCKETWATCH_REFRESHER = "Đồng hồ làm mới"
STRINGS.RECIPE_DESC.CHASNI_POCKETWATCH_REFRESHER = "Dành cho ai không thích chờ đợi."
STRINGS.CHARACTERS.GENERIC.CHASNI_POCKETWATCH_REFRESHER_FAIL = "Chỉ Wanda mới sử dụng được."
STRINGS.CHARACTERS.WANDA.CHASNI_POCKETWATCH_REFRESHER_FAIL = "Giờ chưa phải lúc!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_REFRESHER = {}
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_REFRESHER.GENERIC = "Ta cá bên trong có bao điều khoa học thú vị. "
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_REFRESHER.RECHARGING = "Chưa đến lúc đâu! "
STRINGS.NAMES.CHASNI_POCKETWATCH_MULTIVERSE = "Đồng hồ đa vũ trụ"
STRINGS.RECIPE_DESC.CHASNI_POCKETWATCH_MULTIVERSE = "Vô vàn dòng thời gian, vô vàn khả năng."
STRINGS.CHARACTERS.GENERIC.CHASNI_POCKETWATCH_MULTIVERSE_FAIL = "Chỉ Wanda mới sử dụng được."
STRINGS.CHARACTERS.WANDA.CHASNI_POCKETWATCH_MULTIVERSE_FAIL = "Giờ chưa phải lúc!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_MULTIVERSE = {}
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_MULTIVERSE.GENERIC = "Ta cá bên trong có bao điều khoa học thú vị. "
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POCKETWATCH_MULTIVERSE.RECHARGING = "Chưa đến lúc đâu! "
-- PERSEPHONE BLESSING 
STRINGS.NAMES.NATURE_HAT = "Vương miện rừng già"
STRINGS.RECIPE_DESC.NATURE_HAT = "Biểu tượng của người bảo hộ khu rừng."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.NATURE_HAT = "Cảm thấy tự nhiên hơn"
STRINGS.NAMES.NATURE_STAFF = "Gậy tinh linh"
STRINGS.RECIPE_DESC.NATURE_STAFF = "Cây trượng của sự hồi phục và sinh trưởng"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.NATURE_STAFF = "Được sử dụng để triệu hồi các tinh linh mộc của khu rừng"
STRINGS.CHARACTERS.GENERIC.NATURE_STAFF_FAIL_1 = "Ta không được ban phước bởi Persephone"
STRINGS.NAMES.WORMWOOD_SALVE = "Nhầy Wormwood"
STRINGS.RECIPE_DESC.WORMWOOD_SALVE = "Nó đến từ bộ phận cơ thể nào?"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WORMWOOD_SALVE = "Nhớp và thơm"
STRINGS.NAMES.BRAMBLETOWER = "Tháp dây gai"
STRINGS.RECIPE_DESC.BRAMBLETOWER = "Một cái cây bảo vệ khu rừng"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BRAMBLETOWER = "Người ta không bao giờ có thể quá chắc chắn ai, hoặc cái gì, có thể cần được bảo vệ."
STRINGS.NAMES.BRAMBLECHEST = "Rương dây gai"
STRINGS.RECIPE_DESC.BRAMBLECHEST = "Rương tích hợp hệ thống chống trộm"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BRAMBLECHEST = "Ờ.. nó bảo vệ đồ."
-- HADES BLESSING
STRINGS.NAMES.HELL_HAT = "Mũ địa ngục"
STRINGS.RECIPE_DESC.HELL_HAT = "Mũ sắt từ địa ngục."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HELL_HAT = "Chiếc mũ bảo hiểm mạnh mẽ của người chết."
STRINGS.NAMES.HELL_ARMOR = "Áo choàng ma quỷ"
STRINGS.RECIPE_DESC.HELL_ARMOR = "Được rèn trong vực sâu của âm phủ."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HELL_ARMOR = "Chiếc áo choàng cổ xưa hấp thụ xung đột để tiếp sức cho chủ nhân."
STRINGS.NAMES.HELL_STAFF = "Quyền trượng Con mắt của Sauron"
STRINGS.RECIPE_DESC.HELL_STAFF = "Một biểu tượng của Chúa tể bóng tối."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HELL_STAFF = "Đừng nhìn vào mắt nó!"
STRINGS.CHARACTERS.GENERIC.HELL_STAFF_FAIL_1 = "Cần thêm năng lượng địa ngục."
STRINGS.CHARACTERS.GENERIC.HELL_STAFF_FAIL_2 = "Ta không được ban phước bởi Hades."
STRINGS.CHARACTERS.GENERIC.HELL_STAFF_FAIL_3 = "Đó không phải kẻ thù của ta."
-- POSEIDON BLESSING
STRINGS.NAMES.WATER_HAT = "Vương miện biển cả"
STRINGS.RECIPE_DESC.WATER_HAT = "Làm bằng chất liệu biển"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WATER_HAT = "Thật là một chiếc mũ trông nguy hiểm"
STRINGS.NAMES.WATER_SPEAR = "Đinh ba Neptune"
STRINGS.RECIPE_DESC.WATER_SPEAR = "Gọi vài con sóng biển."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WATER_SPEAR = "Ta tự hỏi cổ vật này bao nhiêu tuổi?"
-- WONKEY
STRINGS.NAMES.WONKEY_BURROW = ""
-- NEW MOBS
STRINGS.NAMES.MERMPROTECTOR = "Merm Warden"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MERMPROTECTOR = "Tốt nhất đừng giở trò mờ ám."
STRINGS.NAMES.CHASNI_FLUFFY = "Fluffy"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_FLUFFY = "Tơ nó dệt mềm như mây!"
STRINGS.NAMES.DEER_ORANGE = "Orange Gem Deer"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.DEER_ORANGE = "Nó đang bị kiểm soát bởi con thú đó!"
STRINGS.NAMES.DEER_YELLOW = "Yellow Gem Deer"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.DEER_YELLOW = "Nó đang bị kiểm soát bởi con thú đó!"
STRINGS.NAMES.DEER_GREEN = "Green Gem Deer"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.DEER_GREEN = "Nó đang bị kiểm soát bởi con thú đó!"
STRINGS.NAMES.DEER_PURPLE = "Purple Gem Deer"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.DEER_PURPLE = "Nó đang bị con quái thú ấy điều khiển!"
STRINGS.NAMES.CHASNI_KLAUS_SACK = "Kho chiến lợi phẩm phù phép"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_KLAUS_SACK = "Kho báu đen tối nào ẩn bên trong?"
STRINGS.NAMES.CHASNI_KLAUSSACKKEY = "Gạc hươu vàng"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_KLAUSSACKKEY = "Ngươi sẽ hé lộ điều kỳ diệu gì?"
STRINGS.NAMES.CHASNI_KLAUS = "Golden Klaus"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_KLAUS = "Cái quái gì thế này!"
STRINGS.NAMES.CHASNI_ANCIENTHERALD = "Ancient Ink Blight"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_ANCIENTHERALD = "Một thực thể tận diệt siêu hình."
STRINGS.NAMES.CHASNI_ANCIENTHERALD_LAVAPOOL = "Hồ dung nham"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_ANCIENTHERALD_LAVAPOOL = "Hơi nóng quá so với ý ta."
STRINGS.NAMES.CHASNI_SEALNADO = "Sealnado"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SEALNADO = "Bảo sao quanh đây gió thổi lạ thế."
STRINGS.NAMES.CHASNI_SEAL = "Seal"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SEAL = "Ôi, dễ thương quá."
STRINGS.NAMES.CHASNI_ANCIENT_HULK = "Iron Hulk"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_ANCIENT_HULK = "Ta hối hận vì đã gây ra chuyện này."
STRINGS.NAMES.CHASNI_HULK_ASSEMBLY = "????"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_HULK_ASSEMBLY = "Chà, hay đấy."
STRINGS.NAMES.CHASNI_HULK_SPIDER = "Xương sườn Hulk"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_HULK_SPIDER = "Thứ đó là cái gì?"
STRINGS.NAMES.CHASNI_HULK_CLAW = "Cánh tay Hulk"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_HULK_CLAW = "Một công nghệ thật khác thường."
STRINGS.NAMES.CHASNI_HULK_LEG = "Chân Hulk"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_HULK_LEG = "Đó là một cái chân sao?"
STRINGS.NAMES.CHASNI_HULK_HEAD = "Đầu Hulk"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_HULK_HEAD = "Chẳng biết nó thuộc tương lai hay thời cổ đại nữa."
STRINGS.NAMES.CHASNI_BASALT = "Đá bazan phun trào"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BASALT = "Một tảng đá kết hợp với nhiều loại đá khác."
STRINGS.NAMES.CRABQUEEN = "Crab Queen"
STRINGS.NAMES.CHASNI_FIRECRABKING_CLAW = "Càng lửa"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_FIRECRABKING_CLAW = "Đóng băng nó đi."
STRINGS.NAMES.CHASNI_WATERCRABKING_CLAW = "Càng nước"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WATERCRABKING_CLAW = "Có vẻ nó yếu trước sát thương điện."
STRINGS.NAMES.CHASNI_ICECRABKING_CLAW = "Càng băng"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_ICECRABKING_CLAW = "Đốt nó đi."
STRINGS.NAMES.CHASNI_ELECTRICCRABKING_CLAW = "Càng điện"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_ELECTRICCRABKING_CLAW = "Dội nước vào nó có thể gây đoản mạch."
STRINGS.NAMES.CHASNI_SHADOWCRABKING_CLAW = "Càng bóng tối"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SHADOWCRABKING_CLAW = "Chỉ người mất trí mới hạ được nó."
STRINGS.NAMES.CHASNI_LUNARCRABKING_CLAW = "Càng mặt trăng"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_LUNARCRABKING_CLAW = "Ta phải giữ tỉnh táo mới hạ được nó."

STRINGS.NAMES.GRONEHOG_SNOW = "Snow Gronehog"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GRONEHOG_SNOW = "Cơ thể bé nhỏ của nó phủ đầy tuyết."
STRINGS.NAMES.GRONEHOG_SAND = "Sand Gronehog"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GRONEHOG_SAND = "Cơ thể bé nhỏ của nó phủ đầy cát."
STRINGS.NAMES.CHASNI_PLASMABLOB = "Zapperpillar"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_PLASMABLOB = "Sinh vật tràn đầy năng lượng."

STRINGS.NAMES.CHASNI_WARGFANT = "Wargfant"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WARGFANT = "Đó là Varg hay Koalefant vậy?"
STRINGS.NAMES.CHASNI_SNAPDRAGON = "Snap Dragon"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SNAPDRAGON = "Một con rồng lai thực vật"
STRINGS.NAMES.CHASNI_SLIP = "Slip"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SLIP = "Nhìn kìa! Đó là con quỷ làm tê liệt giấc mơ"
STRINGS.NAMES.CHASNI_SLIPSTOR = "Slipstor"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SLIPSTOR = "Một con quỷ gây tê liệt khi ngủ."
STRINGS.NAMES.CHASNI_BRRRD_SUMMER = "Summer Brrrd"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BRRRD_SUMMER = "Loài chim máu nóng"
STRINGS.NAMES.CHASNI_BRRRD_WINTER = "Winter Brrrd"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BRRRD_WINTER = "Loài chim máu lạnh."
STRINGS.NAMES.CHASNI_BLACKFLY = "Big Black Fly"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BLACKFLY = "Đó là một con ruồi khổng lồ!"
STRINGS.NAMES.CHASNI_FROG_POISON = "Venomous Frog"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_FROG_POISON = "Nó đang quằn quại."
STRINGS.NAMES.CHASNI_MOSQUITO_POISON = "Venomous Mosquito"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_MOSQUITO_POISON = "Thứ nhỏ nhắn hút máu đáng ghê tởm."
STRINGS.NAMES.CHASNI_SPIDER_POISON = "Venomous Spider"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SPIDER_POISON = "Ta ghét bọn nhện."
STRINGS.NAMES.CHASNI_GIANTGRUB = "Giant Grub"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_GIANTGRUB = "Ta sẽ không bén mảng lại gần thứ đó!"
STRINGS.NAMES.CHASNI_WEEVOLE = "Weevole"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WEEVOLE = "Úi chà!"
STRINGS.NAMES.CHASNI_SPIDERMONKEY = "Spiderilla"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SPIDERMONKEY = "Thứ đó khá lớn!"
STRINGS.NAMES.CHASNI_CROCODOG = "Crocodog"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CROCODOG = "Tốt nhất ta nên tránh xa nó."
STRINGS.NAMES.CHASNI_WATERCROCODOG = "Blue Crocodog"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WATERCROCODOG = "Nó có mùi như một con chó ướt."
STRINGS.NAMES.CHASNI_POISONCROCODOG = "Yellow Crocodog"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POISONCROCODOG = "Nọc độc nào chảy qua tĩnh mạch của thứ đó?"
STRINGS.NAMES.CHASNI_PANGOLDEN = "Pangolden"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_PANGOLDEN = "Nó thích thức ăn sang chảnh."
STRINGS.NAMES.CHASNI_ADULTFLYTRAP = "Snaptooth Flytrap"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_ADULTFLYTRAP = "Khoa học không thể tạo ra thứ này."
STRINGS.NAMES.CHASNI_GRABBINGVINE = "Hanging Vine"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_GRABBINGVINE = "Lúc nào cũng lơ lửng quanh đây."
STRINGS.NAMES.CHASNI_TREEGUARD = "Palm Treeguard"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_TREEGUARD = "Ai giúp ta xử lý cây cọ này với!"
STRINGS.NAMES.CHASNI_HIPPOPOTAMOOSE = "Hippopotamoose"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_HIPPOPOTAMOOSE = "To lớn, đầu lại nhọn hoắt."
STRINGS.NAMES.CHASNI_WATERBISHOP = "Floaty Boaty Bishop"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WATERBISHOP = "Điện với nước ư? Kết hợp chẳng lành chút nào!"
STRINGS.NAMES.CHASNI_MANDRAKEMAN = "Elder Mandrake"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_MANDRAKEMAN = "To lớn và vang vọng."
STRINGS.MANDRAKEMAN_BATTLECRY = {
    "MỤC RỮA!",
    "ĐẤT!",
    "TRỘN!",
    "KHUÔN!",
}
STRINGS.MANDRAKEMAN_MANDRAKE_BATTLECRY = {
    "CƯỚP!",
    "TÊN CƯỚP!",
    "LỪA ĐẢO!",
    "GIAN LẬN!",
}
STRINGS.MANDRAKEMAN_GIVEUP = {
    "LÀM GÌ?",
    "MỆT",
    "NGỦ",
    "RÁCH NÁT",
}
-- NEW ITEM
STRINGS.NAMES.DIRTPILE_BOSS = "Đống đất đáng ngờ của trùm"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.DIRTPILE_BOSS = "Một đống đất... thật vậy sao?"
STRINGS.NAMES.ANIMAL_TRACK_BOSS = "Dấu chân trùm"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ANIMAL_TRACK_BOSS = "Dấu vết do thức ăn để lại. Ý ta là... con thú."
STRINGS.NAMES.JELLYBEAN_YELLOW = "Kẹo đậu vàng"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.JELLYBEAN_YELLOW = "Một phần thạch vàng, một phần đậu vàng."
STRINGS.NAMES.JELLYBEAN_GREEN = "Kẹo đậu xanh"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.JELLYBEAN_GREEN = "Một phần thạch xanh, một phần đậu xanh."
STRINGS.NAMES.JELLYBEAN_RED = "Kẹo đậu đỏ"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.JELLYBEAN_RED = "Một phần thạch đỏ, một phần đậu đỏ."
STRINGS.NAMES.JELLYBEAN_WHITE = "Kẹo đậu trắng"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.JELLYBEAN_WHITE = "Một phần thạch trắng, một phần đậu trắng."
STRINGS.NAMES.CHASNI_DUNGPILE = "Đống phân"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_DUNGPILE = "Đó là một đống phân khổng lồ!"
STRINGS.CHASNI_DUNGPILE = {
    SPAWN = "Ôi không! Con chim ấy vừa thải phân khắp nơi!",
    DESTORY = {
        DONE = "Phù, có vẻ đó là đống cuối cùng!",
        NOTDONE1 = "Đã dọn một đống phân, còn ",
        NOTDONE2 = " đống nữa cần dọn", -- Biến số đếm được ghép giữa NOTDONE1 và NOTDONE2.
    }
}
STRINGS.NAMES.CHASNI_POISON_GLAND = "Tuyến độc"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POISON_GLAND = "Ngươi có thể ủ nó, để làm thuốc giải độc."
STRINGS.NAMES.CHASNI_POISON_ANTIDOTE = "Thuốc giải độc"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_POISON_ANTIDOTE = "Miếng băng ma thuật này chữa được cả loại độc nguy hiểm nhất."
STRINGS.NAMES.CHASNI_MUTATOR_POISON = "Bánh biến hình độc"
STRINGS.RECIPE_DESC.CHASNI_MUTATOR_POISON = "Đảm bảo có vị ngon chết người!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_MUTATOR_POISON = "Ai muốn ăn bánh quy nào?"
STRINGS.NAMES.CHASNI_RO_BIN = "Ro Bin"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_RO_BIN = "Chú chim chuyên chở."
STRINGS.NAMES.CHASNI_ROBIN_STONE = "Sỏi mề của Ro Bin"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_ROBIN_STONE = "Sao lại thành ra thế này được?"
STRINGS.NAMES.CHASNI_ROBIN_EGG = "Trứng đá"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_ROBIN_EGG = "Có lẽ ta nên ấp nó."
STRINGS.NAMES.CHASNI_ICYWEED = "Bụi cỏ lăn đóng băng"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_ICYWEED = "Một bụi cỏ lăn đóng băng."

-- NEW RoG item
STRINGS.NAMES.CHASNI_COCOONTREE = "Cây kén"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_COCOONTREE = "Ta thích cây ra quả hơn."
STRINGS.NAMES.CHASNI_COCOONTREESEED = "Hạt cây kén"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_COCOONTREESEED = "Hạt giống kỳ lạ thật."

STRINGS.NAMES.CHASNI_SNAPDRAGON_PETAL = "Cánh hoa hồng"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SNAPDRAGON_PETAL = "Hương thơm quyến rũ làm sao."
STRINGS.NAMES.CHASNI_SNAPDRAGON_SEED = "Hạt của Snap Dragon"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SNAPDRAGON_SEED = "Ta sẽ trồng nó."
STRINGS.NAMES.CHASNI_SNAPDRAGON_FLOWER = "Hoa của Snap Dragon"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SNAPDRAGON_FLOWER = "Nó đầy mật hoa."
STRINGS.NAMES.UPGRADED_FARMPLOT = "Nông trại phù phép"
STRINGS.RECIPE_DESC.UPGRADED_FARMPLOT = "Hạt giống tự lớn nhờ phép thuật."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_FARMPLOT = "Lớn lên đi, cây cối ơi!"
STRINGS.NAMES.MEDICALKIT = "Bộ cứu thương"
STRINGS.RECIPE_DESC.MEDICALKIT = "Bộ dụng cụ y tế thiết yếu để cấp cứu tức thì."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MEDICALKIT = "Chứa đủ dụng cụ để cứu mạng."
STRINGS.NAMES.CHASNI_REPAIRKIT = "Hộp dụng cụ"
STRINGS.RECIPE_DESC.CHASNI_REPAIRKIT = "Bộ dụng cụ thiết yếu."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_REPAIRKIT = "Thứ này tiện thật."

STRINGS.NAMES.CHASNI_WARGFANT_FUR = "Lông Wargfant"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WARGFANT_FUR = "Nó đem lại cảm giác chẳng lành."
STRINGS.NAMES.CHASNI_WARGFANT_TOOTH = "Răng Hound khổng lồ"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WARGFANT_TOOTH = "Nhọn hoắt!"
STRINGS.NAMES.UPGRADED_BATBAT = "Gậy dơi bị nguyền"
STRINGS.RECIPE_DESC.UPGRADED_BATBAT = "Một cây gậy dơi đầy uy lực."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_BATBAT = "Thú vị đấy. Vũ khí này có vẻ đang sống."
STRINGS.NAMES.ROTTENPACK = "Ba lô mục rữa"
STRINGS.RECIPE_DESC.ROTTENPACK = "Thấm đẫm năng lượng hắc ám."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ROTTENPACK = "Trông như nhặt từ bãi rác ra."

STRINGS.NAMES.CHASNI_GRUB_JAW = "Hàm sâu"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_GRUB_JAW = "Sắc hơn cả lưỡi dao."
STRINGS.NAMES.CHASNI_GRUB_SKULL = "Sọ sâu"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_GRUB_SKULL = "Cứng hơn cả khiên."
STRINGS.NAMES.UPGRADED_SHOVEL = "Xẻng đào sâu"
STRINGS.RECIPE_DESC.UPGRADED_SHOVEL = "Một chiếc xẻng đầy uy lực."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_SHOVEL = "Dưới đất có nhiều chuyện thú vị lắm."
STRINGS.NAMES.UPGRADED_SHOVEL_GROUND = "Hố sụt tạm thời"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_SHOVEL_GROUND = "Ta cá dưới đó có đủ thứ để khám phá."
STRINGS.NAMES.UPGRADED_MINERHAT = "Mũ thợ mỏ cao cấp"
STRINGS.RECIPE_DESC.UPGRADED_MINERHAT = "Chiếc mũ thợ mỏ đầy uy lực."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_MINERHAT = "Thắp sáng ngày mới mà chẳng cần dùng tay."

STRINGS.NAMES.CHASNI_EXORT_FEATHER = "Lông vũ Exort"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_EXORT_FEATHER = "Exort tam dương!"
STRINGS.NAMES.CHASNI_QUAS_FEATHER = "Lông vũ Quas"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_QUAS_FEATHER = "Quas hàn băng!"
STRINGS.NAMES.UPGRADED_AMULET = "Bùa hộ mệnh Exort"
STRINGS.RECIPE_DESC.UPGRADED_AMULET = "Cơn rùng mình dai dẳng của Sadron."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_AMULET = "Ta thấy ấm áp quá."
STRINGS.NAMES.UPGRADED_BLUEAMULET = "Bùa hộ mệnh Quas"
STRINGS.RECIPE_DESC.UPGRADED_BLUEAMULET = "Thần chú thiêu đốt của Harlek."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_BLUEAMULET = "Ta thấy lạnh buốt."
STRINGS.NAMES.VOLCANIC_HAT = "Mũ núi lửa"
STRINGS.RECIPE_DESC.VOLCANIC_HAT = "Nóng như lửa."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.VOLCANIC_HAT = "Đầu ta sắp sôi lên rồi."
STRINGS.NAMES.ARCTIC_HAT = "Vòng đội đầu băng sơn"
STRINGS.RECIPE_DESC.ARCTIC_HAT = "Lạnh như băng."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ARCTIC_HAT = "Giữ đầu óc ta mát mẻ."
STRINGS.NAMES.UPGRADED_FEATHERHAT = "Mũ lông vũ cao cấp"
STRINGS.RECIPE_DESC.UPGRADED_FEATHERHAT = "Một bộ cánh dành cho đầu ngươi."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_FEATHERHAT = "TA LÀ THỦ LĨNH CỦA MUÔN CHIM!"
STRINGS.NAMES.POOFAN = "Phù~"
STRINGS.RECIPE_DESC.POOFAN = "Dọn sạch ô nhiễm phân."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.POOFAN = "Cùng dọn sạch thế giới nào."
STRINGS.CHARACTERS.GENERIC.POOFAN_NO_DUNGPILE = "Thế giới đã hết ô nhiễm phân."

STRINGS.NAMES.CHASNI_PANGOLDEN_SCALE = "Vảy vàng"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_PANGOLDEN_SCALE = "Ta giàu rồi!"
STRINGS.NAMES.ARMORGOLD = "Áo giáp vảy vàng"
STRINGS.RECIPE_DESC.ARMORGOLD = "Bộ giáp mang khí chất vàng son."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ARMORGOLD = "Giáp vàng đây!"
STRINGS.NAMES.UPGRADED_FENCEROTATOR = "Kiếm đấu vàng"
STRINGS.RECIPE_DESC.UPGRADED_FENCEROTATOR = "Thanh kiếm dùng để đấu kiếm."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_FENCEROTATOR = "Thủ thế! Phản đòn!"
STRINGS.NAMES.UPGRADED_BOOMERANG = "Boomerang diệt vong"
STRINGS.RECIPE_DESC.UPGRADED_BOOMERANG = "Có ngày thứ này quay lại hại ta cho xem."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_BOOMERANG = "Ngày tàn của ngươi là điều không tránh khỏi."

STRINGS.NAMES.CHASNI_HIPPO_ANTLER = "Gạc Hippopotamoose"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_HIPPO_ANTLER = "Chà, làm giá treo mũ thì hợp đấy."
STRINGS.NAMES.CHASNI_HIPPO_SKIN = "Da Hippopotamoose"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_HIPPO_SKIN = "Chà, làm mũ thì hợp đấy."
STRINGS.NAMES.OAR_STOPPER = "Mái chèo neo thuyền"
STRINGS.RECIPE_DESC.OAR_STOPPER = "Giống như chiếc neo mang theo được."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.OAR_STOPPER = "Dùng để dừng thuyền, không phải đẩy thuyền đi."

STRINGS.NAMES.TRAP_FLYTRAP = "Pakkun"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRAP_FLYTRAP = "Ôi, cái cây bé xinh làm sao!"
STRINGS.NAMES.DUG_TRAP_FLYTRAP = "Bẫy Pakkun"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.DUG_TRAP_FLYTRAP = "Ta nên tìm chỗ đặt nó."
STRINGS.NAMES.CHASNI_GAS = "LPG"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_GAS = "Trông có vẻ dễ nổ đấy."

STRINGS.NAMES.CHASNI_PALMTREEGUARD_LOG = "Khúc gỗ cọ"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_PALMTREEGUARD_LOG = "Chắc chắn hơn khúc gỗ thường một chút."
STRINGS.NAMES.UPGRADED_BOAT_ITEM = "Bộ thuyền gia cố"
STRINGS.RECIPE_DESC.UPGRADED_BOAT_ITEM = "Hãy làm chủ đại dương."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_BOAT_ITEM = "Thật tuyệt nếu có thể làm thêm thí nghiệm trên mặt nước."
STRINGS.NAMES.UPGRADED_BOAT = "Thuyền gia cố"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_BOAT = "Thật tuyệt nếu có thể làm thêm thí nghiệm trên mặt nước."
STRINGS.NAMES.UPGRADED_TREASURECHEST = "Rương rộng rãi"
STRINGS.RECIPE_DESC.UPGRADED_TREASURECHEST = "Một chiếc rương chứa được nhiều đồ."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_TREASURECHEST = "Rương to hơn để chứa thêm đủ thứ linh tinh."

STRINGS.NAMES.CHASNI_CROCODOG_SKIN = "Da Crocodog"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CROCODOG_SKIN = "Da này may túi thời trang thì hợp đấy."
STRINGS.NAMES.CROCKIT = "Bộ xây cầu tàu"
STRINGS.RECIPE_DESC.CROCKIT = "Bộ xây cầu tàu bền chắc"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CROCKIT = "Giờ tôi có thể xây cầu tàu ở bất cứ đâu."
STRINGS.NAMES.CROCPACK = "Túi da đắt tiền"
STRINGS.RECIPE_DESC.CROCPACK = "Vừa thời trang, vừa bảo vệ"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CROCPACK = "Chúng cắn trước thì đâu thể trách tôi."

STRINGS.NAMES.CHASNI_SLIPSTOR_FUR = "Lông Slipstor"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SLIPSTOR_FUR = "Mềm mượt như nhung!"
STRINGS.NAMES.UPGRADED_CATCOONHAT = "Mũ mèo huyền bí"
STRINGS.RECIPE_DESC.UPGRADED_CATCOONHAT = "Dành cho ai yêu những người bạn ấm áp, thích ôm ấp."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_CATCOONHAT = "Chiếc mũ tai mèo thần kỳ!"
STRINGS.NAMES.CHASNI_KITCOON_HEALER = "Cleric Kitten"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_KITCOON_HEALER = "Ôi, dễ thương quá!"
STRINGS.NAMES.UPGRADED_WHIP = "Roi thuần thú"
STRINGS.RECIPE_DESC.UPGRADED_WHIP = "Cú quất khiến muông thú nghe lời."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_WHIP = "Tiếng roi vang lên khiến muông thú phải nghe lời."
STRINGS.NAMES.SLIPSCRAFT = "Khăn choàng lông Slipstor"
STRINGS.RECIPE_DESC.SLIPSCRAFT = "Làm từ bộ lông mềm mại nhất."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SLIPSCRAFT = "Sưởi ấm cả cổ lẫn tâm hồn tôi."

STRINGS.NAMES.CHASNI_PLASMABLOB_BLOB = "Electrict Blob"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_PLASMABLOB_BLOB = "Bên trong có dòng điện chạy qua."
STRINGS.NAMES.BLOB_LANTERN = "Bóng nhầy phát sáng"
STRINGS.RECIPE_DESC.BLOB_LANTERN = "Thắp sáng lối đi."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BLOB_LANTERN = "Trông mềm nhũn quá."
STRINGS.NAMES.CHASNI_ELECTRICDART = "Phi tiêu điện"
STRINGS.RECIPE_DESC.CHASNI_ELECTRICDART = "Sẽ giật bạn đấy."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_ELECTRICDART = "Đúng là một phát hiện gây sốc."

STRINGS.NAMES.DARK_BEEGUARD = "Cursed Grumble Bee"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.DARK_BEEGUARD = "Ôi. Tiếng vo ve đáng sợ quá."

STRINGS.NAMES.CHASNI_ANCIENT_REMNANT = "Mảnh vải cổ xưa"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_ANCIENT_REMNANT = "Mảnh vỡ đầy sức mạnh của một bóng hình bí ẩn."
STRINGS.NAMES.CHASNI_SEAL_FUR = "Lông Wex"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SEAL_FUR = "Wex nhiễm điện rồi!"
STRINGS.NAMES.CHASNI_HULK_METALBIT = "Mảnh Hulk"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_HULK_METALBIT = "Đậm chất tương lai!"

STRINGS.NAMES.CHASNI_WOODENPIGSTATUE = "Tượng lợn bằng gỗ"
STRINGS.RECIPE_DESC.CHASNI_WOODENPIGSTATUE = "Món quà hoàn hảo dành cho nhà vua"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WOODENPIGSTATUE = "Đức vua hẳn sẽ thích nó."
STRINGS.NAMES.CHASNI_WINDCONCH = "Tù và gió"
STRINGS.RECIPE_DESC.CHASNI_WINDCONCH = "Thổi nhẹ vào tù và rồi chuẩn bị đón bão!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WINDCONCH = "Tôi nghe thấy gió bị nhốt bên trong."
STRINGS.NAMES.CHASNI_BIRDWHISTLE = "Còi gạc hươu"
STRINGS.RECIPE_DESC.CHASNI_BIRDWHISTLE = "Dùng để săn bắn và đủ thứ khác"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BIRDWHISTLE = "Âm thanh của nó gọi muông thú đến."
STRINGS.NAMES.CHASNI_BIRDWHISTLECORRUPTED = "Còi gạc hươu ác mộng"
STRINGS.RECIPE_DESC.CHASNI_BIRDWHISTLECORRUPTED = "Để đi săn, hay để bị săn?"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BIRDWHISTLECORRUPTED = "Âm thanh của nó thật ám ảnh."
STRINGS.NAMES.TRINKET_CHASNI_1 = "Máy chơi game tí hon"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_1 = "Cả một khu trò chơi nằm gọn trong túi."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_1 = "Trông hiện đại mà âm thanh thì hoài cổ."
STRINGS.NAMES.HULKGLOVES = "Cánh tay rô-bốt"
STRINGS.RECIPE_DESC.HULKGLOVES = "Bắn tia la-de."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HULKGLOVES = "Trông hiện đại nhưng có vẻ nguy hiểm."
STRINGS.NAMES.HULKHAT = "Mũ rô-bốt"
STRINGS.RECIPE_DESC.HULKHAT = "Thiết bị bảo hộ đến từ tương lai."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HULKHAT = "Trông hiện đại nhưng có mùi lạ."
STRINGS.NAMES.UPGRADED_ICEBOX = "Tủ lạnh rộng rãi"
STRINGS.RECIPE_DESC.UPGRADED_ICEBOX = "Ngăn chứa lạnh rộng rãi."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_ICEBOX = "Có thêm chỗ cho những món bạn thích."
STRINGS.NAMES.PONDSTRUCTION = "Ao đang xây"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.PONDSTRUCTION = "Thôi, để lát nữa làm tiếp."
STRINGS.NAMES.PONDSTRUCTION_PLANS = "Bản vẽ ao"
STRINGS.RECIPE_DESC.PONDSTRUCTION_PLANS = "Bản vẽ một chiếc ao thần kỳ."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.PONDSTRUCTION_PLANS = "Có ao sau nhà là mơ ước của tôi!"
STRINGS.NAMES.UPGRADED_POND = "Ao thần kỳ"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_POND = "Khoan, kia là cá hiếm à!?"
STRINGS.NAMES.TINKERTOWER = "Xưởng mày mò"
STRINGS.RECIPE_DESC.TINKERTOWER = "Thử mày mò một chút"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TINKERTOWER = "Bạn có đang nghĩ giống tôi không?"
STRINGS.ACTIONS.OPEN_CRAFTING.TINKERING = "Mày mò"
STRINGS.UI.CRAFTING_STATION_FILTERS.TINKER_TOWER = "Tháp mày mò"
STRINGS.UI.CRAFTING_FILTERS.TINKER_TOWER = "Tháp mày mò"

STRINGS.NAMES.CHASNI_GEMPORTAL = "Tiền đồn lăng kính"
STRINGS.RECIPE_DESC.CHASNI_GEMPORTAL = "Làm từ những viên đá rực rỡ sắc màu."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_GEMPORTAL = "Bên trong chứa sức mạnh mặt trăng."
STRINGS.CHASNI_GEMPORTAL_DESC = "Có {red} đỏ, {blue} xanh lam, {purple} tím, {green} xanh lá, {yellow} vàng, {orange} cam"
STRINGS.CHASNI_GEMPORTAL_DEF = "Bên trong chứa sức mạnh mặt trăng"
STRINGS.NAMES.CHASNI_HEATER = "Lò sưởi điện"
STRINGS.RECIPE_DESC.CHASNI_HEATER = "Nguồn nhiệt rất tốt."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_HEATER = "Tôi có thể hâm nóng thức ăn bằng nó."
STRINGS.NAMES.DUMBBELL_TINKER = "Tạ mày mò"
STRINGS.RECIPE_DESC.DUMBBELL_TINKER = "Để rèn luyện trí não."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.DUMBBELL_TINKER = "Quả tạ này tập cho não chứ không phải cơ bắp."
STRINGS.NAMES.CHASNI_SOLAR_PANEL = "Tấm pin mặt trời"
STRINGS.RECIPE_DESC.CHASNI_SOLAR_PANEL = "Thu năng lượng từ mặt trời."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SOLAR_PANEL = "Cần ánh nắng để sạc lại."
STRINGS.CHARACTERS.GENERIC.ANNOUNCE_CHASNI_NO_SOLAR = "Năng lượng mặt trời đã cạn"
STRINGS.CHASNI_SOLAR_PANEL_DESC = "Pin mặt trời còn {charge}"
STRINGS.NAMES.CHASNI_GEARS_CHARGED = "Bánh răng tích điện"
STRINGS.NAMES.CHASNI_GOGGLESSHOOT = "Kính tia điện 200"
STRINGS.RECIPE_DESC.CHASNI_GOGGLESSHOOT = "Thiết bị hội tụ tĩnh điện."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_GOGGLESSHOOT = "Những quả cầu tĩnh điện nhỏ tạo thành đạn điện tuyệt vời."
STRINGS.NAMES.AXE_AXE = "Rìu/Rìu"
STRINGS.RECIPE_DESC.AXE_AXE = "Phiên bản tha hóa của Lucy."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AXE_AXE = "Lấy rìu ra đấu rìu nào."

STRINGS.NAMES.CHASNI_BOOK_VOKER = "Thánh kinh Ka'el"
STRINGS.RECIPE_DESC.CHASNI_BOOK_VOKER = "Ngọn hải đăng tri thức soi sáng biển đen của sự ngu dốt."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_BOOK_VOKER = "Lời triệu hồi thật huy hoàng!"
STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.READ.FAIL_VOKER = "Phép này chẳng linh chút nào!"
STRINGS.CHARACTERS.GENERIC.FAIL_VOKER = "Phép này chẳng linh chút nào!"
STRINGS.NAMES.VOKER_FORGESPIRIT = "Forge Spirit"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.VOKER_FORGESPIRIT = "Tạo tác tinh xảo nhất của Culween."
STRINGS.NAMES.VOKER_ICEWALL = "Tường băng"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.VOKER_ICEWALL = "Bức tường chết chóc của Koryx."
STRINGS.NAMES.WARF_EMITTER = "Máy phát hương"
STRINGS.RECIPE_DESC.WARF_EMITTER = "Một công trình dùng để khiêu khích."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WARF_EMITTER = "Ta có cần dùng cái này không?"
STRINGS.CHARACTERS.GENERIC.ANNOUNCE_CHASNI_NOT_EMITTER_ITEM = "Không thể dùng những thứ đó để dụ chúng."
STRINGS.CHARACTERS.GENERIC.ANNOUNCE_CHASNI_WARF_EMITTER_COOLDOWN = "Nó vẫn chưa sẵn sàng."

STRINGS.NAMES.CHASNI_SEALLOONS = "Bóng lốc xoáy"
STRINGS.RECIPE_DESC.CHASNI_SEALLOONS = "Chỉ lốc xoáy mới thổi phồng được nó."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SEALLOONS = "Đơn vị tiền tệ sang chảnh hơn của chú hề."
STRINGS.NAMES.BALLOON_CHASNI_RED = "Bóng bay khoan đá"
STRINGS.RECIPE_DESC.BALLOON_CHASNI_RED = "Chứa đầy khí nén"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BALLOON_CHASNI_RED = "Phá đá, hoặc bị đá phá."
STRINGS.NAMES.BALLOON_CHASNI_YELLOW = "Bóng bay lòng đỏ trứng"
STRINGS.RECIPE_DESC.BALLOON_CHASNI_YELLOW = "Chứa luồng khí ấm áp"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BALLOON_CHASNI_YELLOW = "Mong là chúng không nở thành quái vật."
STRINGS.NAMES.BALLOON_CHASNI_GREEN = "Bóng bay chất nhầy xanh"
STRINGS.RECIPE_DESC.BALLOON_CHASNI_GREEN = "Chứa đầy khí ô nhiễm"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BALLOON_CHASNI_GREEN = "Chứa khí xanh lá, không biết là gì nhỉ?"
STRINGS.NAMES.BALLOON_CHASNI_BLUE = "Bóng bay kem que"
STRINGS.RECIPE_DESC.BALLOON_CHASNI_BLUE = "Chứa luồng khí mát lạnh"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BALLOON_CHASNI_BLUE = "Ở đây lạnh quá nhỉ?"
STRINGS.NAMES.BALLOON_CHASNI_PURPLE = "Bóng bay lá phép thuật"
STRINGS.RECIPE_DESC.BALLOON_CHASNI_PURPLE = "Chứa luồng khí ma thuật"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BALLOON_CHASNI_PURPLE = "Hãy gọi sức mạnh thiên nhiên."
STRINGS.NAMES.CHASNI_WEBBALL = "Bóng quăng tơ lụa"
STRINGS.RECIPE_DESC.CHASNI_WEBBALL = "Quả bóng dính nhớp."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_WEBBALL = "Tôi không muốn chạm vào đâu."
STRINGS.NAMES.HEALINGWARD = "Cọc chữa trị"
STRINGS.RECIPE_DESC.HEALINGWARD = "Yurnero có mặt."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HEALINGWARD = "Nghi lễ học được trên Đảo Mặt Nạ."
STRINGS.ACTIONS.CALLHEALINGWARD = "Đổi chế độ đi theo"

STRINGS.NAMES.CHASNI_SCOUTBADGES_ATTACK = "Huy hiệu công trạng"
STRINGS.RECIPE_DESC.CHASNI_SCOUTBADGES_ATTACK = "Dành cho những trinh sát dày dạn kinh nghiệm."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_SCOUTBADGES_ATTACK = "Nó tượng trưng cho sự đáng tin cậy."
STRINGS.NAMES.SOULAMULET = "Bùa hộ mệnh linh hồn"
STRINGS.RECIPE_DESC.SOULAMULET = "Romanoff đã chết vì thứ này."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SOULAMULET = "Lưu giữ tinh hoa của những linh hồn đã khuất."
STRINGS.NAMES.UPGRADED_GREENAMULET = "Bùa hộ mệnh sản xuất"
STRINGS.RECIPE_DESC.UPGRADED_GREENAMULET = "Chế tạo mà được thêm một món miễn phí."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.UPGRADED_GREENAMULET = "Nó còn tuyệt hơn nữa!"
STRINGS.NAMES.PIPSPOOK_STAFF = "Trượng ma"
STRINGS.RECIPE_DESC.PIPSPOOK_STAFF = "Vật dẫn cho những linh hồn đã khuất."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.PIPSPOOK_STAFF = "Đảo ngược điều không thể tránh khỏi để làm gì chứ?"
STRINGS.NAMES.CHASNI_READINGGLASSES = "Kính đọc sách"
STRINGS.RECIPE_DESC.CHASNI_READINGGLASSES = "Phụ kiện của học giả."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_READINGGLASSES = "Kính bé xíu để đọc những chữ bé xíu."
STRINGS.NAMES.CHASNI_MERM_HAT = "Mũ thuyền trưởng Merm"
STRINGS.RECIPE_DESC.CHASNI_MERM_HAT = "Thiết kế cho người cá."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_MERM_HAT = "Trông như thứ một người cá ướt sũng sẽ đội."

STRINGS.NAMES.WATCHPAINT = "Cọ vẽ vượt thời gian"
STRINGS.RECIPE_DESC.WATCHPAINT = "Dụng cụ để bộc lộ bản thân."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WATCHPAINT = "Thêm sắc màu cho thế giới u ám này."
STRINGS.ACTIONS.CHASNI_PAINT = "Sơn"
STRINGS.NAMES.WATCHPAINT_BLACK = "ĐEN"
STRINGS.NAMES.WATCHPAINT_BLUE = "XANH LAM"
STRINGS.NAMES.WATCHPAINT_BROWN = "NÂU"
STRINGS.NAMES.WATCHPAINT_GRAY = "XÁM"
STRINGS.NAMES.WATCHPAINT_GREEN = "XANH LÁ"
STRINGS.NAMES.WATCHPAINT_INDIGO = "CHÀM"
STRINGS.NAMES.WATCHPAINT_LIME = "XANH CHANH"
STRINGS.NAMES.WATCHPAINT_MINT = "XANH BẠC HÀ"
STRINGS.NAMES.WATCHPAINT_MOON = "MẶT TRĂNG"
STRINGS.NAMES.WATCHPAINT_ORANGE = "CAM"
STRINGS.NAMES.WATCHPAINT_PINK = "HỒNG"
STRINGS.NAMES.WATCHPAINT_PURPLE = "TÍM"
STRINGS.NAMES.WATCHPAINT_RED = "ĐỎ"
STRINGS.NAMES.WATCHPAINT_SHADOW = "BÓNG TỐI"
STRINGS.NAMES.WATCHPAINT_TOSCA = "XANH NGỌC"
STRINGS.NAMES.WATCHPAINT_WHITE = "TRẮNG"
STRINGS.NAMES.WATCHPAINT_YELLOW = "VÀNG"
STRINGS.NAMES.WATCHPAINT_FLOWER = "HOA"
STRINGS.NAMES.WATCHPAINT_LOVE = "TÌNH YÊU"
STRINGS.NAMES.WATCHPAINT_SMILE = "NỤ CƯỜI"
STRINGS.NAMES.WATCHPAINT_THUMB = "NGÓN CÁI"
STRINGS.NAMES.WATCHPAINT_STAR = "NGÔI SAO"
STRINGS.NAMES.WATCHPAINT_BALLOON = "BÓNG BAY"
STRINGS.NAMES.WATCHPAINT_BUBBLE = "BONG BÓNG"
STRINGS.NAMES.WATCHPAINT_EGG = "TRỨNG"
STRINGS.NAMES.WATCHPAINT_ROCKET = "TÊN LỬA"
STRINGS.NAMES.WATCHPAINT_PLANE = "MÁY BAY"
STRINGS.NAMES.WATCHPAINT_PLANT = "CÂY"
STRINGS.NAMES.WATCHPAINT_CACTUS = "XƯƠNG RỒNG"
STRINGS.NAMES.WATCHPAINT_MERM = "MERM"
STRINGS.NAMES.WATCHPAINT_UNICORN = "KỲ LÂN"

STRINGS.NAMES.WARLYPHONE = "Điện thoại giao hàng"
STRINGS.RECIPE_DESC.WARLYPHONE = "Đáp ứng cơn đói."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WARLYPHONE = "Có người đói bụng sắp gọi tới đấy."
STRINGS.CHARACTERS.GENERIC.WARLYPHONE_FAIL = "Chết tiệt, họ cúp máy mất rồi"
STRINGS.WARLYPHONE_NAMES = {"Milson.", "Millow.", "Marly.", "Malter.", "Minona.", "Milba.", "Milbur.", "Malani."}
STRINGS.WARLYPHONE_GREETINGS1 = {"Chào! Tôi là ", "Xin chào~ Tôi tên là ", "Ê, tôi là ", "Chào nhé! Tôi đây, ", "Bonjour, cứ gọi tôi là "}
STRINGS.WARLYPHONE_GREETINGS2 = {"Chào! Giao hàng ngay được không?", "Xin chào!", "Chào nhé!", "Hola~", "Chào bạn.", "Shalom.", "Assalamualaikum.", "Namaste.", "P"}
STRINGS.WARLYPHONE_ORDERS1 = {"Tôi muốn ", "Tôi muốn gọi ", "Tôi mong được nhận ", "Làm ơn gửi ", "Tôi muốn đặt ", "Tôi muốn gọi món ", "Gửi cho tôi "}
STRINGS.WARLYPHONE_ORDERS2 = {" nhé. Tôi ở gần ", " nhé. Tôi ở cạnh ", " nhé. Tôi ở gần ", " nhé. Tôi ở cạnh ", " ngay nhé. Tôi ở gần ", " càng sớm càng tốt! Tôi ở cạnh "}
STRINGS.WARLYPHONE_ANNOUNCEMENT1 = "Đơn giao hàng: "
STRINGS.WARLYPHONE_ANNOUNCEMENT2 = " gần "
STRINGS.ACTIONS.PICKUP_WARLYPHONE = "Nhận đơn hàng"
STRINGS.NAMES.CUSTOMER_GOATMUM = "Mommy Goat"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CUSTOMER_GOATMUM = "Cô ấy có vẻ đói bụng."
STRINGS.NAMES.CUSTOMER_GOATKID = "Goat Kid"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CUSTOMER_GOATKID = "Cậu ấy có vẻ đói bụng."
STRINGS.CUSTOMER_DESC = "{gender} muốn ăn {food}"

STRINGS.NAMES.WATER_CRABAMULET = "Nước huyền bí"
STRINGS.RECIPE_DESC.WATER_CRABAMULET = "Một giọt nước bí ẩn."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.WATER_CRABAMULET = "Tinh khiết quá."
STRINGS.NAMES.PHASEBELL_SHADOW = "Chuông khiêu khích"
STRINGS.RECIPE_DESC.PHASEBELL_SHADOW = "Tiếng chuông ám ảnh."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.PHASEBELL_SHADOW = "Âm thanh quỷ quái làm sao."
STRINGS.NAMES.PHASEBELL_LUNAR = "Chuông xoa dịu"
STRINGS.RECIPE_DESC.PHASEBELL_LUNAR = "Tiếng chuông dịu lòng."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.PHASEBELL_LUNAR = "Âm thanh êm ái như từ thiên đường."

STRINGS.NAMES.CHASNI_CRAB_ELECTRICORGAN = "Nội tạng điện"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRAB_ELECTRICORGAN = "Thứ này giật điện đấy."
STRINGS.NAMES.CHASNI_CRAB_WATERORGAN = "Nội tạng nước"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRAB_WATERORGAN = "Thứ này bốc hơi nước."
STRINGS.NAMES.CHASNI_CRAB_ICEORGAN = "Nội tạng băng"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRAB_ICEORGAN = "Thứ này lạnh run người."
STRINGS.NAMES.CHASNI_CRAB_FIREORGAN = "Nội tạng lửa"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRAB_FIREORGAN = "Thứ này nóng rát."
STRINGS.NAMES.CHASNI_CRAB_SHADOWORGAN = "Nội tạng bóng tối"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRAB_SHADOWORGAN = "Thứ này tối tăm quá."
STRINGS.NAMES.CHASNI_CRAB_LUNARORGAN = "Nội tạng mặt trăng"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRAB_LUNARORGAN = "Thứ này lấp lánh."
STRINGS.NAMES.CRABSTAFF_ELECTRIC = "Trượng tích điện"
STRINGS.RECIPE_DESC.CRABSTAFF_ELECTRIC = "Cơn bão nghe theo lệnh."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CRABSTAFF_ELECTRIC = "Chắc chắn sẽ gây sốc!"
STRINGS.NAMES.CRABSTAFF_ELECTRICTURRET = "Năng lượng điện"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CRABSTAFF_ELECTRICTURRET = "Những người bạn phóng điện giận dữ."
STRINGS.NAMES.CRABSTAFF_WATER = "Trượng bắn nước"
STRINGS.RECIPE_DESC.CRABSTAFF_WATER = "Nhanh đấy, nhưng ướt sũng."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CRABSTAFF_WATER = "Ôi! Dịch chuyển tức thời! ...Khoan, sao tôi ướt hết thế này?"
STRINGS.NAMES.CRABSTAFF_ICE = "Trượng mùa đông"
STRINGS.RECIPE_DESC.CRABSTAFF_ICE = "Cái lạnh làm tê đi cơn đau."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CRABSTAFF_ICE = "Brrr! Nhưng còn sống vẫn tuyệt hơn."
STRINGS.NAMES.CRABSTAFF_FIRE = "Trượng dung nham"
STRINGS.RECIPE_DESC.CRABSTAFF_FIRE = "Cháy đi, cháy lên nào."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CRABSTAFF_FIRE = "Như một khẩu pháo bắn cầu lửa tí hon."
STRINGS.NAMES.CRABSTAFF_SHADOW = "Trượng Underlord"
STRINGS.RECIPE_DESC.CRABSTAFF_SHADOW = "Bước vào vực thẳm... nếu bạn dám."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CRABSTAFF_SHADOW = "Tôi thích cách di chuyển an toàn hơn."
STRINGS.NAMES.CRABSTAFF_LUNAR = "Trượng rực sáng"
STRINGS.RECIPE_DESC.CRABSTAFF_LUNAR = "Phước lành của mặt trăng."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CRABSTAFF_LUNAR = "Hừm. Vậy chắc tôi đỡ phải dùng băng keo rồi."
STRINGS.ACTIONS.CASTSPELL_MAP = "Tạo cổng dịch chuyển"
STRINGS.CHARACTERS.GENERIC.CRABSTAFF_ICE_FAIL = "Không có mục tiêu cần cứu"
STRINGS.NAMES.CRABSTAFF_SHADOW_PORTAL = "Cổng yêu ma"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CRABSTAFF_SHADOW_PORTAL = "Tôi có nên nhảy vào không?"

-- NEW Critter
STRINGS.NAMES.CHASNI_CRITTER_ATOPS_A = "Crystalatops"
STRINGS.NAMES.CHASNI_CRITTER_ATOPS_B = "Crystalatops"
STRINGS.NAMES.CHASNI_CRITTER_ATOPS_A_BUILDER = "Crystalatops"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_ATOPS_A_BUILDER = "Nhận nuôi một Crystalatops."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_ATOPS_A = "Một thú cưng bằng đá hóa thạch."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_ATOPS_B = "Một thú cưng bằng đá hóa thạch."
STRINGS.NAMES.CHASNI_CRITTER_BEE_A = "Beeta"
STRINGS.NAMES.CHASNI_CRITTER_BEE_B = "Beeta"
STRINGS.NAMES.CHASNI_CRITTER_BEE_A_BUILDER = "Beeta"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_BEE_A_BUILDER = "Nhận nuôi một Beeta."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_BEE_A = "Chú ong hầu vo ve."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_BEE_B = "Chú ong hầu vo ve."
STRINGS.NAMES.CHASNI_CRITTER_BUG_A = "Buittle"
STRINGS.NAMES.CHASNI_CRITTER_BUG_B = "Buittle"
STRINGS.NAMES.CHASNI_CRITTER_BUG_A_BUILDER = "Buittle"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_BUG_A_BUILDER = "Nhận nuôi một Buittle."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_BUG_A = "Nhặt nhạnh đủ thứ như bọ hung vậy."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_BUG_B = "Nhặt nhạnh đủ thứ như bọ hung vậy."
STRINGS.NAMES.CHASNI_CRITTER_CRAB_A = "Crabble"
STRINGS.NAMES.CHASNI_CRITTER_CRAB_B = "Crabble"
STRINGS.NAMES.CHASNI_CRITTER_CRAB_A_BUILDER = "Crabble"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_CRAB_A_BUILDER = "Nhận nuôi một Crabble."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_CRAB_A = "Có phải mấy bong bóng này từ nó mà ra?"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_CRAB_B = "Có phải mấy bong bóng này từ nó mà ra?"
STRINGS.NAMES.CHASNI_CRITTER_DOG_A = "Squeep xanh"
STRINGS.NAMES.CHASNI_CRITTER_DOG_B = "Squeep xanh"
STRINGS.NAMES.CHASNI_CRITTER_DOG_A_BUILDER = "Squeep xanh"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_DOG_A_BUILDER = "Nhận nuôi một Squeep xanh."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_DOG_A = "Ôi, dễ thương quá đi!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_DOG_B = "Ôi, dễ thương quá đi!"
STRINGS.NAMES.CHASNI_CRITTER_DOG_PINK_A = "Squeep hồng"
STRINGS.NAMES.CHASNI_CRITTER_DOG_PINK_B = "Squeep hồng"
STRINGS.NAMES.CHASNI_CRITTER_DOG_PINK_A_BUILDER = "Squeep hồng"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_DOG_PINK_A_BUILDER = "Nhận nuôi một Squeep hồng."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_DOG_PINK_A = "Ôi, dễ thương quá đi!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_DOG_PINK_B = "Ôi, dễ thương quá đi!"
STRINGS.NAMES.CHASNI_CRITTER_DRILLER_A = "Drillie"
STRINGS.NAMES.CHASNI_CRITTER_DRILLER_B = "Drillie"
STRINGS.NAMES.CHASNI_CRITTER_DRILLER_A_BUILDER = "Drillie"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_DRILLER_A_BUILDER = "Nhận nuôi một Drillie."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_DRILLER_A = "Nhìn nó xoay kìa!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_DRILLER_B = "Nhìn nó xoay kìa!"
STRINGS.NAMES.CHASNI_CRITTER_FISH_BURN_A = "Gupp lửa"
STRINGS.NAMES.CHASNI_CRITTER_FISH_BURN_B = "Gupp lửa"
STRINGS.NAMES.CHASNI_CRITTER_FISH_BURN_A_BUILDER = "Gupp lửa"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_FISH_BURN_A_BUILDER = "Nhận nuôi một Gupp lửa."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_FISH_BURN_A = "Nó nên ở trong bể cá!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_FISH_BURN_B = "Nó nên ở trong bể cá!"
STRINGS.NAMES.CHASNI_CRITTER_FISH_WET_A = "Gupp nước"
STRINGS.NAMES.CHASNI_CRITTER_FISH_WET_B = "Gupp nước"
STRINGS.NAMES.CHASNI_CRITTER_FISH_WET_A_BUILDER = "Gupp nước"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_FISH_WET_A_BUILDER = "Nhận nuôi một Gupp nước."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_FISH_WET_A = "Nó nên ở trong bể cá!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_FISH_WET_B = "Nó nên ở trong bể cá!"
STRINGS.NAMES.CHASNI_CRITTER_LIGHT_ON_A = "Brightcopter"
STRINGS.NAMES.CHASNI_CRITTER_LIGHT_ON_B = "Brightcopter"
STRINGS.NAMES.CHASNI_CRITTER_LIGHT_ON_A_BUILDER = "Brightcopter"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_LIGHT_ON_A_BUILDER = "Nhận nuôi một Brightcopter."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_LIGHT_ON_A = "Đó là bóng đèn à?"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_LIGHT_ON_B = "Đó là bóng đèn à?"
STRINGS.NAMES.CHASNI_CRITTER_LIGHT_OFF_A = "Duscopter"
STRINGS.NAMES.CHASNI_CRITTER_LIGHT_OFF_B = "Duscopter"
STRINGS.NAMES.CHASNI_CRITTER_LIGHT_OFF_A_BUILDER = "Duscopter"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_LIGHT_OFF_A_BUILDER = "Nhận nuôi một Duscopter."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_LIGHT_OFF_A = "Đó là bóng đèn à?"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_LIGHT_OFF_B = "Đó là bóng đèn à?"
STRINGS.NAMES.CHASNI_CRITTER_MAMO_A = "Baaamoth"
STRINGS.NAMES.CHASNI_CRITTER_MAMO_B = "Baaamoth"
STRINGS.NAMES.CHASNI_CRITTER_MAMO_A_BUILDER = "Baaamoth"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_MAMO_A_BUILDER = "Nhận nuôi một Baaamoth."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_MAMO_A = "Ôm chắc thích lắm."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_MAMO_B = "Ôm chắc thích lắm."
STRINGS.NAMES.CHASNI_CRITTER_MOO = "Moosician"
STRINGS.NAMES.CHASNI_CRITTER_MOO_BUILDER = "Moosician"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_MOO_BUILDER = "Nhận nuôi một Moosician."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_MOO = "Thật đấy, tai tôi đau quá."
STRINGS.NAMES.CHASNI_CRITTER_MOODENG = "Moosician nổi loạn"
STRINGS.NAMES.CHASNI_CRITTER_MOODENG_BUILDER = "Moosician nổi loạn"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_MOODENG_BUILDER = "Nhận nuôi một Moosician nổi loạn."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_MOODENG = "Thật đấy, tai tôi đau quá."
STRINGS.NAMES.CHASNI_CRITTER_MOSQ_A = "stequito"
STRINGS.NAMES.CHASNI_CRITTER_MOSQ_B = "stequito"
STRINGS.NAMES.CHASNI_CRITTER_MOSQ_A_BUILDER = "stequito"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_MOSQ_A_BUILDER = "Nhận nuôi một stequito."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_MOSQ_A = "Con bọ hút máu."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_MOSQ_B = "Con bọ hút máu."
STRINGS.NAMES.CHASNI_CRITTER_PUFF_HEALTH_A = "Bông xù lông"
STRINGS.NAMES.CHASNI_CRITTER_PUFF_HEALTH_B = "Bông xù lông"
STRINGS.NAMES.CHASNI_CRITTER_PUFF_HEALTH_A_BUILDER = "Bông xù lông"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_PUFF_HEALTH_A_BUILDER = "Nhận nuôi một Bông xù lông."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_PUFF_HEALTH_A = "Đây là thú cưng tuyệt nhất, mềm xù nhất!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_PUFF_HEALTH_B = "Đây là thú cưng tuyệt nhất, mềm xù nhất!"
STRINGS.NAMES.CHASNI_CRITTER_PUFF_HUNGER_A = "Bông xù lồi lõm"
STRINGS.NAMES.CHASNI_CRITTER_PUFF_HUNGER_B = "Bông xù lồi lõm"
STRINGS.NAMES.CHASNI_CRITTER_PUFF_HUNGER_A_BUILDER = "Bông xù lồi lõm"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_PUFF_HUNGER_A_BUILDER = "Nhận nuôi một Bông xù lồi lõm."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_PUFF_HUNGER_A = "Đây là thú cưng tuyệt nhất, mềm xù nhất!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_PUFF_HUNGER_B = "Đây là thú cưng tuyệt nhất, mềm xù nhất!"
STRINGS.NAMES.CHASNI_CRITTER_PUFF_INSANITY_A = "Bông xù u sầu"
STRINGS.NAMES.CHASNI_CRITTER_PUFF_INSANITY_B = "Bông xù u sầu"
STRINGS.NAMES.CHASNI_CRITTER_PUFF_INSANITY_A_BUILDER = "Bông xù u sầu"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_PUFF_INSANITY_A_BUILDER = "Nhận nuôi một Bông xù u sầu."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_PUFF_INSANITY_A = "Đây là thú cưng tuyệt nhất, mềm xù nhất!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_PUFF_INSANITY_B = "Đây là thú cưng tuyệt nhất, mềm xù nhất!"
STRINGS.NAMES.CHASNI_CRITTER_PUFF_SANITY_A = "Bông xù vui vẻ"
STRINGS.NAMES.CHASNI_CRITTER_PUFF_SANITY_B = "Bông xù vui vẻ"
STRINGS.NAMES.CHASNI_CRITTER_PUFF_SANITY_A_BUILDER = "Bông xù vui vẻ"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_PUFF_SANITY_A_BUILDER = "Nhận nuôi một Bông xù vui vẻ."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_PUFF_SANITY_A = "Đây là thú cưng tuyệt nhất, mềm xù nhất!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_PUFF_SANITY_B = "Đây là thú cưng tuyệt nhất, mềm xù nhất!"
STRINGS.NAMES.CHASNI_CRITTER_RAPTOR_A = "Raptor"
STRINGS.NAMES.CHASNI_CRITTER_RAPTOR_B = "Raptor"
STRINGS.NAMES.CHASNI_CRITTER_RAPTOR_A_BUILDER = "Raptor"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_RAPTOR_A_BUILDER = "Nhận nuôi một Raptor."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_RAPTOR_A = "Vừa đẹp vừa dữ dằn."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_RAPTOR_B = "Vừa đẹp vừa dữ dằn."
STRINGS.NAMES.CHASNI_CRITTER_SEAL_A = "Sleal"
STRINGS.NAMES.CHASNI_CRITTER_SEAL_B = "Sleal"
STRINGS.NAMES.CHASNI_CRITTER_SEAL_A_BUILDER = "Sleal"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_SEAL_A_BUILDER = "Nhận nuôi một Sleal."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_SEAL_A = "Tôi cứ tưởng đó là bóng nước."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_SEAL_B = "Tôi cứ tưởng đó là bóng nước."
STRINGS.NAMES.CHASNI_CRITTER_SLUG_STAR_A = "Oglug"
STRINGS.NAMES.CHASNI_CRITTER_SLUG_STAR_B = "Oglug"
STRINGS.NAMES.CHASNI_CRITTER_SLUG_STAR_A_BUILDER = "Oglug"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_SLUG_STAR_A_BUILDER = "Nhận nuôi Oglug."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_SLUG_STAR_A = "Tôi sẽ không chạm vào nó đâu."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_SLUG_STAR_B = "Tôi sẽ không chạm vào nó đâu."
STRINGS.NAMES.CHASNI_CRITTER_SLUG_XP_A = "Oglex"
STRINGS.NAMES.CHASNI_CRITTER_SLUG_XP_B = "Oglex"
STRINGS.NAMES.CHASNI_CRITTER_SLUG_XP_A_BUILDER = "Oglex"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_SLUG_XP_A_BUILDER = "Nhận nuôi Oglex."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_SLUG_XP_A = "Tôi sẽ không chạm vào nó đâu."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_SLUG_XP_B = "Tôi sẽ không chạm vào nó đâu."
STRINGS.NAMES.CHASNI_CRITTER_STEGO_A = "Stegawk"
STRINGS.NAMES.CHASNI_CRITTER_STEGO_B = "Stegawk"
STRINGS.NAMES.CHASNI_CRITTER_STEGO_A_BUILDER = "Stegawk"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_STEGO_A_BUILDER = "Nhận nuôi Stegawk."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_STEGO_A = "Con khủng long đầy gai."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_STEGO_B = "Con khủng long đầy gai."
STRINGS.NAMES.CHASNI_CRITTER_WOOL_A = "Wamb-Wamb"
STRINGS.NAMES.CHASNI_CRITTER_WOOL_B = "Wamb-Wamb"
STRINGS.NAMES.CHASNI_CRITTER_WOOL_A_BUILDER = "Wamb-Wamb"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_WOOL_A_BUILDER = "Nhận nuôi Wamb-Wamb."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_WOOL_A = "Ư! Nó hôi quá."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_WOOL_B = "Ư! Nó hôi quá."
STRINGS.NAMES.CHASNI_CRITTER_WORM_A = "Caterpilla"
STRINGS.NAMES.CHASNI_CRITTER_WORM_B = "Metaphosa"
STRINGS.NAMES.CHASNI_CRITTER_WORM_A_BUILDER = "Caterpilla"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_WORM_A_BUILDER = "Nhận nuôi Caterpilla."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_WORM_A = "Xấu quá. Sao lại nhận nó làm thú cưng nhỉ?"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_WORM_B = "Đẹp quá. Ai cũng nên nuôi một con!"
STRINGS.NAMES.CHASNI_CRITTER_ELECFISH_A = "Beakon"
STRINGS.NAMES.CHASNI_CRITTER_ELECFISH_B = "Beakon"
STRINGS.NAMES.CHASNI_CRITTER_ELECFISH_A_BUILDER = "Beakon"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_ELECFISH_A_BUILDER = "Nhận nuôi Beakon."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_ELECFISH_A = "Nó giật điện con mồi đến chết."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_ELECFISH_B = "Nó giật điện con mồi đến chết."
STRINGS.NAMES.CHASNI_CRITTER_FUGU_A = "Fugu"
STRINGS.NAMES.CHASNI_CRITTER_FUGU_B = "Fugu"
STRINGS.NAMES.CHASNI_CRITTER_FUGU_A_BUILDER = "Fugu"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_FUGU_A_BUILDER = "Nhận nuôi Fugu."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_FUGU_A = "Tôi... vuốt ve nó được không?"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_FUGU_B = "Tôi... vuốt ve nó được không?"
STRINGS.NAMES.CHASNI_CRITTER_SEAHORSE_A = "Mystery"
STRINGS.NAMES.CHASNI_CRITTER_SEAHORSE_B = "Mystery"
STRINGS.NAMES.CHASNI_CRITTER_SEAHORSE_A_BUILDER = "Mystery"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_SEAHORSE_A_BUILDER = "Nhận nuôi Mystery."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_SEAHORSE_A = "Tôi chẳng thấy khe bỏ xu đâu."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_SEAHORSE_B = "Tôi chẳng thấy khe bỏ xu đâu."
STRINGS.NAMES.CHASNI_CRITTER_SNAIL_A = "Ốc ôm trăng"
STRINGS.NAMES.CHASNI_CRITTER_SNAIL_B = "Ốc ôm trăng"
STRINGS.NAMES.CHASNI_CRITTER_SNAIL_A_BUILDER = "Ốc ôm trăng"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_SNAIL_A_BUILDER = "Nhận nuôi Ốc ôm trăng."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_SNAIL_A = "Nó ghét bóng tối."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_SNAIL_B = "Nó ghét bóng tối."
STRINGS.NAMES.CHASNI_CRITTER_SNAIL_BLACK_A = "Ốc ôm bóng tối"
STRINGS.NAMES.CHASNI_CRITTER_SNAIL_BLACK_B = "Ốc ôm bóng tối"
STRINGS.NAMES.CHASNI_CRITTER_SNAIL_BLACK_A_BUILDER = "Ốc ôm bóng tối"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_SNAIL_BLACK_A_BUILDER = "Nhận nuôi Ốc ôm bóng tối."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_SNAIL_BLACK_A = "Nó ghét ánh trăng."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_SNAIL_BLACK_B = "Nó ghét ánh trăng."
STRINGS.NAMES.CHASNI_CRITTER_TURTLE_A = "Squirt"
STRINGS.NAMES.CHASNI_CRITTER_TURTLE_B = "Crush"
STRINGS.NAMES.CHASNI_CRITTER_TURTLE_A_BUILDER = "Squirt"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_TURTLE_A_BUILDER = "Nhận nuôi Squirt."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_TURTLE_A = "Không có dòng nước, nó di chuyển thật chậm."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_TURTLE_B = "Không có dòng nước, nó di chuyển thật chậm."
STRINGS.NAMES.CHASNI_CRITTER_SQUID_A = "Squillien con"
STRINGS.NAMES.CHASNI_CRITTER_SQUID_B = "Ngài Squillien"
STRINGS.NAMES.CHASNI_CRITTER_SQUID_A_BUILDER = "Squillien con"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_SQUID_A_BUILDER = "Nhận nuôi Squillien con"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_SQUID_A = "Nó có chút năng lực điều khiển vật từ xa."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_SQUID_B = "Nó có năng lực điều khiển vật từ xa rất mạnh."
STRINGS.NAMES.CHASNI_CRITTER_BOT = "NRG-5"
STRINGS.NAMES.CHASNI_CRITTER_BOT_BUILDER = "NRG-5"
STRINGS.RECIPE_DESC.CHASNI_CRITTER_BOT_BUILDER = "Nhận nuôi NRG-5."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CRITTER_BOT = "Một người bạn đồng hành đa năng."
-- NEW Critter Item
STRINGS.NAMES.CHASNI_MEMORYCARD_BLUE = "Thẻ nhớ (Risk of Rain)"
STRINGS.RECIPE_DESC.CHASNI_MEMORYCARD_BLUE = "Chứa dữ liệu về một chiếc ô."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_MEMORYCARD_BLUE = "Bên trong lưu nhiều dữ liệu phức tạp."
STRINGS.NAMES.CHASNI_MEMORYCARD_RED = "Thẻ nhớ (Cooking Mama)"
STRINGS.RECIPE_DESC.CHASNI_MEMORYCARD_RED = "Chứa dữ liệu về một chiếc bếp."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_MEMORYCARD_RED = "Bên trong lưu nhiều dữ liệu phức tạp."
STRINGS.NAMES.CHASNI_MEMORYCARD_BROWN = "Thẻ nhớ (Unpacking)"
STRINGS.RECIPE_DESC.CHASNI_MEMORYCARD_BROWN = "Chứa dữ liệu về một chiếc rương."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_MEMORYCARD_BROWN = "Bên trong lưu nhiều dữ liệu phức tạp."
STRINGS.NAMES.CHASNI_MEMORYCARD_GREEN = "Thẻ nhớ (God of War)"
STRINGS.RECIPE_DESC.CHASNI_MEMORYCARD_GREEN = "Chứa dữ liệu về một vị thần."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_MEMORYCARD_GREEN = "Bên trong lưu nhiều dữ liệu phức tạp."
STRINGS.NAMES.CHASNI_MEMORYCARD_YELLOW = "Thẻ nhớ (Bomberman)"
STRINGS.RECIPE_DESC.CHASNI_MEMORYCARD_YELLOW = "Chứa dữ liệu về chất nổ."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_MEMORYCARD_YELLOW = "Bên trong lưu nhiều dữ liệu phức tạp."
STRINGS.NAMES.CHASNI_MEMORYCARD_PINK = "Thẻ nhớ (Dark Souls)"
STRINGS.RECIPE_DESC.CHASNI_MEMORYCARD_PINK = "Chứa dữ liệu về một linh hồn."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_MEMORYCARD_PINK = "Bên trong lưu nhiều dữ liệu phức tạp."
STRINGS.NAMES.CHASNI_FISH_ROE = "Trứng cá Fugu"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_FISH_ROE = "Có mùi tanh."
STRINGS.NAMES.CHASNI_CAVIAR = "Trứng Fugu muối"
STRINGS.RECIPE_DESC.CHASNI_CAVIAR = "Mùi tanh nồng hơn nhiều."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_CAVIAR = "Chẳng có vị gì."
STRINGS.NAMES.CHASNI_PEARL = "Ngọc trai chất lượng thấp"
STRINGS.RECIPE_DESC.CHASNI_PEARL = "Viên đá lấp lánh từ biển."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_PEARL = "Đây không phải ngọc trai thật, đúng không? Trông giống hàng giả."
STRINGS.NAMES.TRINKET_CHASNI_2 = "Ngọc trai đen"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_2 = "Xứng đáng dâng cho Pig King."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_2 = "Đây không phải ngọc trai thật, đúng không? Trông giống hàng giả."
STRINGS.NAMES.CHASNI_DIDGERIZOO = "Kèn Didgerizoo"
STRINGS.RECIPE_DESC.CHASNI_DIDGERIZOO = "Ống kèn phát ra tiếng hú trầm."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_DIDGERIZOO = "Thổi tù và xung trận!"
STRINGS.NAMES.CHASNI_PEARL_BRACELET = "Vòng tay ngọc trai"
STRINGS.RECIPE_DESC.CHASNI_PEARL_BRACELET = "Một chiếc vòng tay sang trọng."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_PEARL_BRACELET = "Tôi thấy mình thật giàu có."
STRINGS.NAMES.CHASNI_PEARL_AMULET = "Mặt dây chuyền ngọc trai"
STRINGS.RECIPE_DESC.CHASNI_PEARL_AMULET = "Một chiếc vòng cổ sang trọng."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CHASNI_PEARL_AMULET = "Tôi thấy mình cực kỳ giàu có."

-- New trinkets
STRINGS.NAMES.TRINKET_CHASNI_3 = "Vỏ sò biển quý hiếm"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_3 = "Thật khoa học!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_3 = "Thật khoa học!"
STRINGS.NAMES.TRINKET_CHASNI_4 = "Chiếc khuyên tai độc nhất"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_4 = "Lấp lánh quá."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_4 = "Tôi không muốn có thêm lỗ trên người."
STRINGS.NAMES.TRINKET_CHASNI_5 = "Queen Malfalfa"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_5 = "Một quý cô lợn xinh đẹp."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_5 = "Một quý cô lợn xinh đẹp."
--STRINGS.NAMES.TRINKET_CHASNI_6 = "Queen Malfalfa 2"
--STRINGS.RECIPE_DESC.TRINKET_CHASNI_6 = "Một quý cô lợn xinh đẹp."
--STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_6 = "Một quý cô lợn xinh đẹp."
STRINGS.NAMES.TRINKET_CHASNI_7 = "Bưu thiếp Hoàng cung"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_7 = "Ghi: \"Ước gì bạn ở đây.\""
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_7 = "Ghi: \"Ước gì bạn ở đây.\""
STRINGS.NAMES.TRINKET_CHASNI_8 = "Bình phun tinh nghịch"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_8 = "Một món cổ vật kỳ lạ."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_8 = "Lạ thật! Sao cổ vật này lại ở đây?"
STRINGS.NAMES.TRINKET_CHASNI_9 = "Nước ngọt cam"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_9 = "Một chiếc lon thiếc."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_9 = "Một chiếc lon thiếc sao?!"
STRINGS.NAMES.TRINKET_CHASNI_10 = "Búp bê tà thuật"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_10 = "Cổ vật của một nền văn hóa xưa."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_10 = "Chắc chắn là cổ vật của một nền văn hóa xưa!"
STRINGS.NAMES.TRINKET_CHASNI_11 = "Đàn ukulele"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_11 = "Một báu vật âm nhạc."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_11 = "Một báu vật âm nhạc."
STRINGS.NAMES.TRINKET_CHASNI_12 = "Biển số xe"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_12 = "Chữ viết cổ."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_12 = "Có lẽ là chữ viết cổ?"
STRINGS.NAMES.TRINKET_CHASNI_13 = "Chiếc ủng cũ"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_13 = "Một món đồ lỗi thời."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_13 = "E rằng nó không hợp gu của tôi."
STRINGS.NAMES.TRINKET_CHASNI_14 = "Bình cổ"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_14 = "Chiếc bình đã vỡ."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_14 = "Tiếc là nó đã vỡ."
STRINGS.NAMES.TRINKET_CHASNI_15 = "Viên thuốc mụ mị"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_15 = "Thật khiến đầu óc quay cuồng."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_15 = "Thật khiến đầu óc quay cuồng."
STRINGS.NAMES.TRINKET_CHASNI_16 = "Kính lục phân"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_16 = "Một dụng cụ thật văn minh!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_16 = "Một dụng cụ thật văn minh!"
STRINGS.NAMES.TRINKET_CHASNI_17 = "Thuyền đồ chơi"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_17 = "Nó có nổi không?"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_17 = "Tôi không tin nó chịu nổi sóng biển."
STRINGS.NAMES.TRINKET_CHASNI_18A = "Nến trong chai rượu"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_18A = "Rượu đâu rồi?"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_18A = "Nó chẳng giống nến cho lắm, nhỉ?"
STRINGS.NAMES.TRINKET_CHASNI_18B = "Nến ướt"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_18B = "Đầy sáp."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_18B = "Một cây nến sũng nước."
STRINGS.NAMES.TRINKET_CHASNI_19 = "Thiết bị AAC hỏng"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_19 = "Nó hỏng nặng rồi."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_19 = "Cỗ máy này chẳng hợp với biển cả."
STRINGS.NAMES.TRINKET_CHASNI_20 = "Đĩa mềm"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_20 = "Idu từng ở đây."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_20 = "Thiết bị này đâu có cũ đến thế!"
STRINGS.NAMES.TRINKET_CHASNI_21 = "Cốc của nhà phát triển"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_21 = "Cz từng ở đây."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_21 = "Ai sở hữu nó hẳn là huyền thoại!"
STRINGS.NAMES.TRINKET_CHASNI_22 = "Dây cáp điện"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_22 = "Nguy hiểm, điện áp cao!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_22 = "Tôi ngửi thấy mùi cháy khét."
STRINGS.NAMES.TRINKET_CHASNI_23 = "Người hâm mộ Chiến ca số một"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_23 = "Rainbo_om từng ở đây."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_23 = "Có vẻ họ vẫn đang chờ được tăng sức mạnh."
STRINGS.NAMES.TRINKET_CHASNI_24 = "Tranh đóng khung Spritter chết"
STRINGS.RECIPE_DESC.TRINKET_CHASNI_24 = "Vini từng ở đây"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TRINKET_CHASNI_24 = "Chết đi, Spritter! Chết đi!!"

-- Global string changes
STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.READ = STRINGS.CHARACTERS.WICKERBOTTOM.ACTIONFAIL.READ

-- Global string addition 
-- Failed instant perk
STRINGS.CHARACTERS.GENERIC.ADDSTAT_FAILED = "<ĐÂY LÀ LỖI>"
STRINGS.CHARACTERS.GENERIC.REVIVEALL_FAILED = "Không có người chơi nào đã chết."
STRINGS.CHARACTERS.GENERIC.LEVELUP_FAILED = "Tôi không có hệ thống kinh nghiệm và cấp độ."
STRINGS.CHARACTERS.GENERIC.GIVESTAR_FAILED = "Không có ai để tặng Sao."
STRINGS.CHARACTERS.GENERIC.SHARESTAR_FAILED = "Không có ai để chia sẻ Sao."
STRINGS.CHARACTERS.GENERIC.MATERIAL_FAILED = "<ĐÂY LÀ LỖI>"
STRINGS.CHARACTERS.GENERIC.ROBINEGG_FAILED = "<ĐÂY LÀ LỖI>"
STRINGS.CHARACTERS.GENERIC.KILLHOUND_FAILED = "Không có Hound nào ở gần."
STRINGS.CHARACTERS.GENERIC.OPENRIFT_FAILED = "Lúc này không thể mở khe nứt."
STRINGS.CHARACTERS.GENERIC.OPENRIFT_SUCCESS = "Khe nứt đã mở!"

STRINGS.NAMES.TRINKETSLOT = "<ĐÂY LÀ LỖI>"
