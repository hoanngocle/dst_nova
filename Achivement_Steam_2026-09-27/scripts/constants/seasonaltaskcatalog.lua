-- Curated seasonal quests. Server evidence only; no client-side progress.
local Catalog = {}

Catalog.SEASONS = {"spring", "summer", "autumn", "winter"}
Catalog.NORMAL_PER_ROUND = 5
Catalog.COUNT_PER_ROUND = 1

local definitions = {
{id="spring_muffin",season="spring",kind="normal",name="Bánh Bướm",description="Ăn 3 bánh bướm trong mùa xuân.",event="oneat",target=3,params={prefab="butterflymuffin"},foodprefab="butterflymuffin"},
{id="spring_frogglebun",season="spring",kind="normal",name="Bánh Kẹp Ếch",description="Ăn 3 bánh kẹp chân ếch.",event="oneat",target=3,params={prefab="frogglebunwich"},foodprefab="frogglebunwich"},
{id="spring_dragonpie",season="spring",kind="normal",name="Bánh Thanh Long",description="Ăn 3 bánh thanh long.",event="oneat",target=3,params={prefab="dragonpie"},foodprefab="dragonpie"},
{id="spring_taffy",season="spring",kind="normal",name="Kẹo Mật Xuân",description="Ăn 3 viên kẹo mật ong.",event="oneat",target=3,params={prefab="taffy"},foodprefab="taffy"},
{id="spring_cookie",season="spring",kind="normal",name="Bánh Bí Ngô",description="Ăn 3 bánh quy bí ngô.",event="oneat",target=3,params={prefab="pumpkincookie"},foodprefab="pumpkincookie"},
{id="spring_eggplant",season="spring",kind="normal",name="Cà Tím Nhồi",description="Ăn 3 phần cà tím nhồi.",event="oneat",target=3,params={prefab="stuffedeggplant"},foodprefab="stuffedeggplant"},
{id="spring_ratatouille",season="spring",kind="normal",name="Rau Hầm Xuân",description="Ăn 3 phần rau củ hầm.",event="oneat",target=3,params={prefab="ratatouille"},foodprefab="ratatouille"},
{id="spring_powcake",season="spring",kind="normal",name="Bánh Bột Ngô",description="Ăn 1 chiếc bánh bột ngô Powcake.",event="oneat",target=1,params={prefab="powcake"},foodprefab="powcake"},
{id="spring_berries",season="spring",kind="normal",name="Quả Mọng Tươi",description="Ăn 10 quả mọng chưa nấu.",event="oneat",target=10,params={prefab="berries"},foodprefab="berries"},
{id="spring_carrot",season="spring",kind="normal",name="Cà Rốt Tươi",description="Ăn 5 củ cà rốt chưa nấu.",event="oneat",target=5,params={prefab="carrot"},foodprefab="carrot"},
{id="spring_spider",season="spring",kind="normal",name="Dọn Nhện Vườn",description="Hạ 15 nhện thường trong mùa xuân.",event="killed",target=15,params={prefab="spider"}},
{id="spring_warrior",season="spring",kind="normal",name="Nhện Chiến Binh",description="Hạ 5 nhện chiến binh.",event="killed",target=5,params={prefab="spider_warrior"}},
{id="spring_tentacle",season="spring",kind="normal",name="Đầm Lầy An Toàn",description="Hạ 3 xúc tu đầm lầy.",event="killed",target=3,params={prefab="tentacle"}},
{id="spring_merm",season="spring",kind="normal",name="Ngư Nhân Đầm Lầy",description="Hạ 5 ngư nhân Merm.",event="killed",target=5,params={prefab="merm"}},
{id="spring_bat",season="spring",kind="normal",name="Dơi Trong Hang",description="Hạ 8 con dơi trong hang.",event="killed",target=8,params={prefab="bat"}},
{id="spring_slurtle",season="spring",kind="normal",name="Ốc Sên Giáp Nhọn",description="Hạ 2 Slurtle trong hang.",event="killed",target=2,params={prefab="slurtle"}},
{id="spring_snurtle",season="spring",kind="normal",name="Ốc Sên Mai Tròn",description="Hạ 1 Snurtle trong hang.",event="killed",target=1,params={prefab="snurtle"}},
{id="spring_eyeplant",season="spring",kind="normal",name="Nhổ Mắt Ăn Thịt",description="Hạ 10 mắt cây ăn thịt.",event="killed",target=10,params={prefab="eyeplant"}},
{id="spring_mosling",season="spring",kind="normal",name="Đàn Ngỗng Non",description="Hạ 3 ngỗng non Mosling.",event="killed",target=3,params={prefab="mossling"}},
{id="spring_goose",season="spring",kind="normal",name="Chúa Tể Mưa Xuân",description="Hạ 1 Moose/Goose trong mùa xuân.",event="killed",target=1,params={prefab="moose"}},
{id="spring_umbrella",season="spring",kind="normal",name="Chiếc Ô Đầu Mùa",description="Chế tạo 1 chiếc ô chống mưa.",event="builditem",target=1,params={prefab="umbrella"}},
{id="spring_rainhat",season="spring",kind="normal",name="Mũ Đi Mưa",description="Chế tạo 1 chiếc mũ đi mưa.",event="builditem",target=1,params={prefab="rainhat"}},
{id="spring_raincoat",season="spring",kind="normal",name="Áo Đi Mưa",description="Chế tạo 1 chiếc áo đi mưa.",event="builditem",target=1,params={prefab="raincoat"}},
{id="spring_lightningrod",season="spring",kind="normal",name="Cột Thu Lôi",description="Dựng 1 cột thu lôi bảo vệ căn cứ.",event="buildstructure",target=1,params={prefab="lightningrod"}},
{id="spring_fishbox",season="spring",kind="normal",name="Thùng Nuôi Cá",description="Dựng 1 thùng chứa cá sống Tin Fishin' Bin.",event="buildstructure",target=1,params={prefab="fish_box"}},
{id="spring_fishingrod",season="spring",kind="normal",name="Cần Câu Ao",description="Chế tạo 1 cần câu dùng tại ao.",event="builditem",target=1,params={prefab="fishingrod"}},
{id="spring_birdtrap",season="spring",kind="normal",name="Bẫy Chim Xuân",description="Chế tạo 2 bẫy chim.",event="builditem",target=2,params={prefab="birdtrap"}},
{id="spring_bugnet",season="spring",kind="normal",name="Vợt Bắt Côn Trùng",description="Chế tạo 1 vợt bắt côn trùng.",event="builditem",target=1,params={prefab="bugnet"}},
{id="spring_strawhat",season="spring",kind="normal",name="Mũ Rơm Ra Vườn",description="Chế tạo 1 mũ rơm.",event="builditem",target=1,params={prefab="strawhat"}},
{id="spring_backpack",season="spring",kind="normal",name="Ba Lô Thu Hái",description="Chế tạo 1 ba lô cho chuyến thu hái.",event="builditem",target=1,params={prefab="backpack"}},
{id="spring_berrybush",season="spring",kind="normal",name="Bụi Quả Mọng",description="Thu hoạch 10 bụi quả mọng thường.",event="picksomething",target=10,params={prefab="berrybush"}},
{id="spring_berrybush_leaf",season="spring",kind="normal",name="Quả Mọng Lá Rộng",description="Thu hoạch 10 bụi quả mọng lá rộng.",event="picksomething",target=10,params={prefab="berrybush2"}},
{id="spring_juicybush",season="spring",kind="normal",name="Quả Mọng Mọng Nước",description="Thu hoạch 8 bụi quả mọng nước.",event="picksomething",target=8,params={prefab="berrybush_juicy"}},
{id="spring_redmushroom",season="spring",kind="normal",name="Nấm Đỏ Ban Ngày",description="Hái 6 cây nấm đỏ.",event="picksomething",target=6,params={prefab="red_mushroom"}},
{id="spring_greenmushroom",season="spring",kind="normal",name="Nấm Xanh Chiều Tà",description="Hái 6 cây nấm xanh lá.",event="picksomething",target=6,params={prefab="green_mushroom"}},
{id="spring_bluemushroom",season="spring",kind="normal",name="Nấm Lam Ban Đêm",description="Hái 6 cây nấm xanh dương.",event="picksomething",target=6,params={prefab="blue_mushroom"}},
{id="spring_reeds",season="spring",kind="normal",name="Lau Sậy Đầm Lầy",description="Thu hoạch 15 bụi lau sậy.",event="picksomething",target=15,params={prefab="reeds"}},
{id="spring_marshbush",season="spring",kind="normal",name="Bụi Gai Đầm Lầy",description="Thu hoạch 8 bụi gai đầm lầy.",event="picksomething",target=8,params={prefab="marsh_bush"}},
{id="spring_fern",season="spring",kind="normal",name="Dương Xỉ Trong Hang",description="Hái 10 cây dương xỉ trong hang.",event="picksomething",target=10,params={prefab="cave_fern"}},
{id="spring_evilflower",season="spring",kind="normal",name="Hoa Tối",description="Hái 6 bông hoa ác.",event="picksomething",target=6,params={prefab="flower_evil"}},
{id="spring_wetgoop",season="spring",kind="count",name="Món Hầm Vụng Về",description="Ăn 3 phần Wet Goop mỗi lượt.",event="oneat",target=3,params={prefab="wetgoop"},foodprefab="wetgoop"},
{id="spring_bee",season="spring",kind="count",name="Ong Trong Vườn",description="Hạ 8 ong thường mỗi lượt.",event="killed",target=8,params={prefab="bee"}},
{id="spring_killerbee",season="spring",kind="count",name="Ong Hung Hãn",description="Hạ 8 ong sát thủ mỗi lượt.",event="killed",target=8,params={prefab="killerbee"}},
{id="spring_frog",season="spring",kind="count",name="Mưa Ếch",description="Hạ 10 con ếch mỗi lượt.",event="killed",target=10,params={prefab="frog"}},
{id="spring_horror",season="spring",kind="count",name="Bóng Bò Trườn",description="Hạ 3 Crawling Horror mỗi lượt.",event="killed",target=3,params={prefab="crawlinghorror"}},
{id="spring_butterfly",season="spring",kind="count",name="Bắt Bướm",description="Dùng vợt bắt 5 con bướm mỗi lượt.",event="finishedwork",target=5,params={action="NET",prefab="butterfly"}},
{id="spring_flowers",season="spring",kind="count",name="Bó Hoa Xuân",description="Hái 10 bông hoa thường mỗi lượt.",event="picksomething",target=10,params={prefab="flower"}},
{id="spring_till",season="spring",kind="count",name="Luống Đất Mới",description="Cày thành công 8 ô đất mỗi lượt.",event="tilling",target=8,params={action="TILL"}},
{id="summer_icecream",season="summer",kind="normal",name="Kem Ngày Nóng",description="Ăn 2 phần kem trong mùa hạ.",event="oneat",target=2,params={prefab="icecream"},foodprefab="icecream"},
{id="summer_watermelonicle",season="summer",kind="normal",name="Kem Dưa Hấu",description="Ăn 3 que kem dưa hấu.",event="oneat",target=3,params={prefab="watermelonicle"},foodprefab="watermelonicle"},
{id="summer_guacamole",season="summer",kind="normal",name="Guacamole Mùa Hạ",description="Ăn 3 phần guacamole.",event="oneat",target=3,params={prefab="guacamole"},foodprefab="guacamole"},
{id="summer_flowersalad",season="summer",kind="normal",name="Salad Hoa",description="Ăn 3 phần salad hoa xương rồng.",event="oneat",target=3,params={prefab="flowersalad"},foodprefab="flowersalad"},
{id="summer_ceviche",season="summer",kind="normal",name="Cá Ướp Lạnh",description="Ăn 3 phần ceviche.",event="oneat",target=3,params={prefab="ceviche"},foodprefab="ceviche"},
{id="summer_surfnturf",season="summer",kind="normal",name="Tiệc Biển Và Rừng",description="Ăn 3 phần Surf 'n' Turf.",event="oneat",target=3,params={prefab="surfnturf"},foodprefab="surfnturf"},
{id="summer_unagi",season="summer",kind="normal",name="Lươn Nướng",description="Ăn 3 phần unagi.",event="oneat",target=3,params={prefab="unagi"},foodprefab="unagi"},
{id="summer_bananapop",season="summer",kind="normal",name="Kem Chuối",description="Ăn 3 que kem chuối.",event="oneat",target=3,params={prefab="bananapop"},foodprefab="bananapop"},
{id="summer_fruitmedley",season="summer",kind="normal",name="Đĩa Trái Cây",description="Ăn 3 phần trái cây trộn.",event="oneat",target=3,params={prefab="fruitmedley"},foodprefab="fruitmedley"},
{id="summer_watermelon",season="summer",kind="normal",name="Dưa Hấu Nướng",description="Ăn 5 miếng dưa hấu đã nấu.",event="oneat",target=5,params={prefab="watermelon_cooked"},foodprefab="watermelon_cooked"},
{id="summer_hound",season="summer",kind="normal",name="Đàn Chó Săn",description="Hạ 12 chó săn thường.",event="killed",target=12,params={prefab="hound"}},
{id="summer_firehound",season="summer",kind="normal",name="Chó Săn Lửa",description="Hạ 5 chó săn lửa.",event="killed",target=5,params={prefab="firehound"}},
{id="summer_dropper",season="summer",kind="normal",name="Nhện Treo Hang",description="Hạ 5 nhện thả từ trần hang.",event="killed",target=5,params={prefab="spider_dropper"}},
{id="summer_spitter",season="summer",kind="normal",name="Nhện Phun Tơ",description="Hạ 5 nhện phun tơ trong hang.",event="killed",target=5,params={prefab="spider_spitter"}},
{id="summer_bunnyman",season="summer",kind="normal",name="Thỏ Người",description="Hạ 5 thỏ người Bunnyman.",event="killed",target=5,params={prefab="bunnyman"}},
{id="summer_tallbird",season="summer",kind="normal",name="Chim Chân Dài",description="Hạ 3 chim Tallbird.",event="killed",target=3,params={prefab="tallbird"}},
{id="summer_antlion",season="summer",kind="normal",name="Chúa Cát",description="Hạ 1 Antlion trong mùa hạ.",event="killed",target=1,params={prefab="antlion"}},
{id="summer_dragonfly",season="summer",kind="normal",name="Rồng Sa Mạc",description="Hạ 1 Dragonfly tại sa mạc.",event="killed",target=1,params={prefab="dragonfly"}},
{id="summer_warg",season="summer",kind="normal",name="Đầu Đàn Chó Săn",description="Hạ 1 Varg dẫn đàn chó săn.",event="killed",target=1,params={prefab="warg"}},
{id="summer_queen",season="summer",kind="normal",name="Nữ Hoàng Nhện",description="Hạ 1 nữ hoàng nhện.",event="killed",target=1,params={prefab="spiderqueen"}},
{id="summer_coldfire",season="summer",kind="normal",name="Bếp Lửa Lạnh",description="Dựng 1 bếp lửa thu nhiệt cố định.",event="buildstructure",target=1,params={prefab="coldfirepit"}},
{id="summer_icebox",season="summer",kind="normal",name="Tủ Lạnh Mùa Hạ",description="Dựng 1 tủ lạnh bảo quản thức ăn.",event="buildstructure",target=1,params={prefab="icebox"}},
{id="summer_watermelonhat",season="summer",kind="normal",name="Mũ Dưa Hấu",description="Chế tạo 1 mũ dưa hấu.",event="builditem",target=1,params={prefab="watermelonhat"}},
{id="summer_featherfan",season="summer",kind="normal",name="Quạt Lông Vũ",description="Chế tạo 1 quạt lông vũ.",event="builditem",target=1,params={prefab="featherfan"}},
{id="summer_icehat",season="summer",kind="normal",name="Mũ Băng",description="Chế tạo 1 khối băng đội đầu.",event="builditem",target=1,params={prefab="icehat"}},
{id="summer_goggles",season="summer",kind="normal",name="Kính Thời Trang",description="Chế tạo 1 kính thời trang tại ốc đảo.",event="builditem",target=1,params={prefab="goggleshat"}},
{id="summer_deserthat",season="summer",kind="normal",name="Kính Sa Mạc",description="Chế tạo 1 kính chống bão cát.",event="builditem",target=1,params={prefab="deserthat"}},
{id="summer_wateringcan",season="summer",kind="normal",name="Bình Tưới Vườn",description="Chế tạo 1 bình tưới thường.",event="builditem",target=1,params={prefab="wateringcan"}},
{id="summer_farmhoe",season="summer",kind="normal",name="Cuốc Làm Vườn",description="Chế tạo 1 cuốc làm vườn.",event="builditem",target=1,params={prefab="farm_hoe"}},
{id="summer_flingomatic",season="summer",kind="normal",name="Máy Dập Lửa",description="Dựng 1 máy ném tuyết bảo vệ căn cứ.",event="buildstructure",target=1,params={prefab="firesuppressor"}},
{id="summer_rock",season="summer",kind="normal",name="Đá Ven Sa Mạc",description="Đào vỡ 8 tảng đá thường.",event="finishedwork",target=8,params={action="MINE",prefab="rock1"}},
{id="summer_goldrock",season="summer",kind="normal",name="Mạch Vàng",description="Đào vỡ 6 tảng đá chứa vàng.",event="finishedwork",target=6,params={action="MINE",prefab="rock2"}},
{id="summer_flintless",season="summer",kind="normal",name="Đá Không Đá Lửa",description="Đào vỡ 6 tảng đá không chứa đá lửa.",event="finishedwork",target=6,params={action="MINE",prefab="rock_flintless"}},
{id="summer_moonrock",season="summer",kind="normal",name="Thiên Thạch Mặt Trăng",description="Đào vỡ 3 tảng đá mặt trăng.",event="finishedwork",target=3,params={action="MINE",prefab="rock_moon"}},
{id="summer_stonefruitbush",season="summer",kind="normal",name="Bụi Quả Đá",description="Thu hoạch 8 bụi quả đá trên đảo trăng.",event="picksomething",target=8,params={prefab="rock_avocado_bush"}},
{id="summer_palm",season="summer",kind="normal",name="Gỗ Cọ Bờ Biển",description="Chặt hạ 5 cây cọ Palmcone.",event="finishedwork",target=5,params={action="CHOP",prefab="palmconetree"}},
{id="summer_farmwatermelon",season="summer",kind="normal",name="Vụ Dưa Hấu",description="Thu hoạch 6 cây dưa hấu trong vườn.",event="picksomething",target=6,params={prefab="farm_plant_watermelon"}},
{id="summer_farmdragonfruit",season="summer",kind="normal",name="Vụ Thanh Long",description="Thu hoạch 6 cây thanh long trong vườn.",event="picksomething",target=6,params={prefab="farm_plant_dragonfruit"}},
{id="summer_farmpomegranate",season="summer",kind="normal",name="Vụ Lựu",description="Thu hoạch 6 cây lựu trong vườn.",event="picksomething",target=6,params={prefab="farm_plant_pomegranate"}},
{id="summer_farmdurian",season="summer",kind="normal",name="Vụ Sầu Riêng",description="Thu hoạch 6 cây sầu riêng trong vườn.",event="picksomething",target=6,params={prefab="farm_plant_durian"}},
{id="summer_jam",season="summer",kind="count",name="Mứt Quả Mùa Hạ",description="Ăn 3 phần mứt quả mỗi lượt.",event="oneat",target=3,params={prefab="jammypreserves"},foodprefab="jammypreserves"},
{id="summer_pierogi",season="summer",kind="count",name="Bánh Xếp Hồi Sức",description="Ăn 3 phần bánh xếp mỗi lượt.",event="oneat",target=3,params={prefab="perogies"},foodprefab="perogies"},
{id="summer_mosquito",season="summer",kind="count",name="Dẹp Muỗi",description="Hạ 8 con muỗi mỗi lượt.",event="killed",target=8,params={prefab="mosquito"}},
{id="summer_stonefruit",season="summer",kind="count",name="Tách Quả Đá",description="Đập mở 10 quả đá mỗi lượt.",event="finishedwork",target=10,params={action="MINE",prefab="rock_avocado_fruit"}},
{id="summer_hammer",season="summer",kind="count",name="Tháo Dỡ Công Trình",description="Hoàn tất 5 lần phá bằng búa mỗi lượt.",event="finishedwork",target=5,params={action="HAMMER"}},
{id="summer_cactus",season="summer",kind="count",name="Xương Rồng Sa Mạc",description="Thu hoạch 8 cây xương rồng thường mỗi lượt.",event="picksomething",target=8,params={prefab="cactus"}},
{id="summer_oasiscactus",season="summer",kind="count",name="Xương Rồng Ốc Đảo",description="Thu hoạch 8 cây xương rồng ốc đảo mỗi lượt.",event="picksomething",target=8,params={prefab="oasis_cactus"}},
{id="summer_row",season="summer",kind="count",name="Tay Chèo Mùa Hạ",description="Thực hiện thành công 30 nhịp chèo thuyền mỗi lượt.",event="rowing",target=30,params={action="ROW"}},
{id="autumn_roastberries",season="autumn",kind="normal",name="Quả Mọng Nướng",description="Ăn 10 quả mọng đã nấu.",event="oneat",target=10,params={prefab="berries_cooked"},foodprefab="berries_cooked"},
{id="autumn_juicyberries",season="autumn",kind="normal",name="Quả Mọng Nước Tươi",description="Ăn 10 quả mọng nước chưa nấu.",event="oneat",target=10,params={prefab="berries_juicy"},foodprefab="berries_juicy"},
{id="autumn_roastjuicy",season="autumn",kind="normal",name="Quả Mọng Nước Nướng",description="Ăn 10 quả mọng nước đã nấu.",event="oneat",target=10,params={prefab="berries_juicy_cooked"},foodprefab="berries_juicy_cooked"},
{id="autumn_roastcarrot",season="autumn",kind="normal",name="Cà Rốt Nướng",description="Ăn 5 củ cà rốt đã nấu.",event="oneat",target=5,params={prefab="carrot_cooked"},foodprefab="carrot_cooked"},
{id="autumn_corn",season="autumn",kind="normal",name="Bắp Tươi",description="Ăn 5 bắp ngô chưa nấu.",event="oneat",target=5,params={prefab="corn"},foodprefab="corn"},
{id="autumn_popcorn",season="autumn",kind="normal",name="Bắp Rang",description="Ăn 5 phần bắp rang.",event="oneat",target=5,params={prefab="corn_cooked"},foodprefab="corn_cooked"},
{id="autumn_pumpkin",season="autumn",kind="normal",name="Bí Ngô Tươi",description="Ăn 5 quả bí ngô chưa nấu.",event="oneat",target=5,params={prefab="pumpkin"},foodprefab="pumpkin"},
{id="autumn_roastpumpkin",season="autumn",kind="normal",name="Bí Ngô Nướng",description="Ăn 5 phần bí ngô đã nấu.",event="oneat",target=5,params={prefab="pumpkin_cooked"},foodprefab="pumpkin_cooked"},
{id="autumn_dragonfruit",season="autumn",kind="normal",name="Thanh Long Tươi",description="Ăn 3 quả thanh long chưa nấu.",event="oneat",target=3,params={prefab="dragonfruit"},foodprefab="dragonfruit"},
{id="autumn_roastdragonfruit",season="autumn",kind="normal",name="Thanh Long Nướng",description="Ăn 3 quả thanh long đã nấu.",event="oneat",target=3,params={prefab="dragonfruit_cooked"},foodprefab="dragonfruit_cooked"},
{id="autumn_pigman",season="autumn",kind="normal",name="Thợ Săn Lợn",description="Hạ 5 người lợn thường.",event="killed",target=5,params={prefab="pigman"}},
{id="autumn_pigguard",season="autumn",kind="normal",name="Lính Gác Lợn",description="Hạ 2 lính gác lợn.",event="killed",target=2,params={prefab="pigguard"}},
{id="autumn_beefalo",season="autumn",kind="normal",name="Săn Beefalo",description="Hạ 3 Beefalo hoang dã.",event="killed",target=3,params={prefab="beefalo"}},
{id="autumn_goat",season="autumn",kind="normal",name="Dê Điện",description="Hạ 3 dê điện Lightning Goat.",event="killed",target=3,params={prefab="lightninggoat"}},
{id="autumn_koalefant",season="autumn",kind="normal",name="Dấu Chân Voi",description="Hạ 1 Koalefant không có lông mùa đông.",event="killed",target=1,params={prefab="koalefant_summer"}},
{id="autumn_catcoon",season="autumn",kind="normal",name="Mèo Gấu Rừng",description="Hạ 3 Catcoon trong rừng bạch dương.",event="killed",target=3,params={prefab="catcoon"}},
{id="autumn_mole",season="autumn",kind="normal",name="Chuột Chũi",description="Hạ 5 chuột chũi.",event="killed",target=5,params={prefab="mole"}},
{id="autumn_rabbit",season="autumn",kind="normal",name="Thỏ Đồng",description="Hạ 8 con thỏ đồng.",event="killed",target=8,params={prefab="rabbit"}},
{id="autumn_grassgekko",season="autumn",kind="normal",name="Thằn Lằn Cỏ",description="Hạ 5 thằn lằn cỏ Grass Gekko.",event="killed",target=5,params={prefab="grassgekko"}},
{id="autumn_bearger",season="autumn",kind="normal",name="Gấu Lửng Mùa Thu",description="Hạ 1 Bearger trong mùa thu.",event="killed",target=1,params={prefab="bearger"}},
{id="autumn_axe",season="autumn",kind="normal",name="Rìu Khai Hoang",description="Chế tạo 2 chiếc rìu thường.",event="builditem",target=2,params={prefab="axe"}},
{id="autumn_pickaxe",season="autumn",kind="normal",name="Cuốc Khai Mỏ",description="Chế tạo 2 cuốc chim thường.",event="builditem",target=2,params={prefab="pickaxe"}},
{id="autumn_shovel",season="autumn",kind="normal",name="Xẻng Làm Vườn",description="Chế tạo 2 chiếc xẻng thường.",event="builditem",target=2,params={prefab="shovel"}},
{id="autumn_hammer",season="autumn",kind="normal",name="Búa Của Thợ",description="Chế tạo 1 chiếc búa.",event="builditem",target=1,params={prefab="hammer"}},
{id="autumn_spear",season="autumn",kind="normal",name="Giáo Phòng Thân",description="Chế tạo 2 cây giáo thường.",event="builditem",target=2,params={prefab="spear"}},
{id="autumn_logarmor",season="autumn",kind="normal",name="Áo Giáp Gỗ",description="Chế tạo 2 bộ giáp gỗ.",event="builditem",target=2,params={prefab="armorwood"}},
{id="autumn_footballhat",season="autumn",kind="normal",name="Mũ Bảo Hộ",description="Chế tạo 2 mũ bóng bầu dục.",event="builditem",target=2,params={prefab="footballhat"}},
{id="autumn_chest",season="autumn",kind="normal",name="Kho Dự Trữ",description="Dựng 3 rương gỗ chứa vật tư.",event="buildstructure",target=3,params={prefab="treasurechest"}},
{id="autumn_cookpot",season="autumn",kind="normal",name="Bếp Thu Hoạch",description="Dựng 1 nồi hầm.",event="buildstructure",target=1,params={prefab="cookpot"}},
{id="autumn_science",season="autumn",kind="normal",name="Máy Khoa Học",description="Dựng 1 máy khoa học.",event="buildstructure",target=1,params={prefab="researchlab"}},
{id="autumn_farmpumpkin",season="autumn",kind="normal",name="Thu Hoạch Bí Ngô",description="Thu hoạch 8 cây bí ngô trong vườn.",event="picksomething",target=8,params={prefab="farm_plant_pumpkin"}},
{id="autumn_farmcorn",season="autumn",kind="normal",name="Thu Hoạch Bắp",description="Thu hoạch 8 cây ngô trong vườn.",event="picksomething",target=8,params={prefab="farm_plant_corn"}},
{id="autumn_farmcarrot",season="autumn",kind="normal",name="Thu Hoạch Cà Rốt",description="Thu hoạch 8 cây cà rốt trong vườn.",event="picksomething",target=8,params={prefab="farm_plant_carrot"}},
{id="autumn_farmpotato",season="autumn",kind="normal",name="Thu Hoạch Khoai Tây",description="Thu hoạch 8 cây khoai tây trong vườn.",event="picksomething",target=8,params={prefab="farm_plant_potato"}},
{id="autumn_farmgarlic",season="autumn",kind="normal",name="Thu Hoạch Tỏi",description="Thu hoạch 6 cây tỏi trong vườn.",event="picksomething",target=6,params={prefab="farm_plant_garlic"}},
{id="autumn_farmonion",season="autumn",kind="normal",name="Thu Hoạch Hành",description="Thu hoạch 6 cây hành trong vườn.",event="picksomething",target=6,params={prefab="farm_plant_onion"}},
{id="autumn_farmtomato",season="autumn",kind="normal",name="Thu Hoạch Cà Chua",description="Thu hoạch 8 cây cà chua trong vườn.",event="picksomething",target=8,params={prefab="farm_plant_tomato"}},
{id="autumn_farmeggplant",season="autumn",kind="normal",name="Thu Hoạch Cà Tím",description="Thu hoạch 6 cây cà tím trong vườn.",event="picksomething",target=6,params={prefab="farm_plant_eggplant"}},
{id="autumn_farmasparagus",season="autumn",kind="normal",name="Thu Hoạch Măng Tây",description="Thu hoạch 6 cây măng tây trong vườn.",event="picksomething",target=6,params={prefab="farm_plant_asparagus"}},
{id="autumn_farmpepper",season="autumn",kind="normal",name="Thu Hoạch Ớt",description="Thu hoạch 6 cây ớt trong vườn.",event="picksomething",target=6,params={prefab="farm_plant_pepper"}},
{id="autumn_honeyham",season="autumn",kind="count",name="Giăm Bông Mật Ong",description="Ăn 3 phần giăm bông mật ong mỗi lượt.",event="oneat",target=3,params={prefab="honeyham"},foodprefab="honeyham"},
{id="autumn_honeynuggets",season="autumn",kind="count",name="Thịt Viên Mật Ong",description="Ăn 3 phần thịt viên mật ong mỗi lượt.",event="oneat",target=3,params={prefab="honeynuggets"},foodprefab="honeynuggets"},
{id="autumn_trailmix",season="autumn",kind="count",name="Lương Khô Đường Rừng",description="Ăn 3 phần hỗn hợp hạt và quả mỗi lượt.",event="oneat",target=3,params={prefab="trailmix"},foodprefab="trailmix"},
{id="autumn_birchnut",season="autumn",kind="count",name="Gỗ Bạch Dương",description="Chặt hạ 8 cây bạch dương mỗi lượt.",event="finishedwork",target=8,params={action="CHOP",prefab="deciduoustree"}},
{id="autumn_chop",season="autumn",kind="count",name="Thợ Đốn Củi",description="Hoàn tất 12 lần chặt cây mỗi lượt.",event="finishedwork",target=12,params={action="CHOP"}},
{id="autumn_grass",season="autumn",kind="count",name="Bó Cỏ Khô",description="Thu hoạch 20 bụi cỏ mỗi lượt.",event="picksomething",target=20,params={prefab="grass"}},
{id="autumn_sapling",season="autumn",kind="count",name="Cành Cây Dự Trữ",description="Thu hoạch 20 cây non mỗi lượt.",event="picksomething",target=20,params={prefab="sapling"}},
{id="autumn_plantbirchnut",season="autumn",kind="count",name="Gieo Rừng Mới",description="Trồng thành công 8 hạt bạch dương mỗi lượt.",event="deployitem",target=8,params={action="DEPLOY",prefab="acorn"}},
{id="winter_chili",season="winter",kind="normal",name="Ớt Hầm Giữ Ấm",description="Ăn 3 phần ớt hầm cay.",event="oneat",target=3,params={prefab="hotchili"},foodprefab="hotchili"},
{id="winter_baconeggs",season="winter",kind="normal",name="Trứng Thịt No Lâu",description="Ăn 3 phần thịt xông khói và trứng.",event="oneat",target=3,params={prefab="baconeggs"},foodprefab="baconeggs"},
{id="winter_fishsticks",season="winter",kind="normal",name="Que Cá Nóng",description="Ăn 3 phần que cá.",event="oneat",target=3,params={prefab="fishsticks"},foodprefab="fishsticks"},
{id="winter_turkeydinner",season="winter",kind="normal",name="Tiệc Gà Tây",description="Ăn 2 phần tiệc gà tây.",event="oneat",target=2,params={prefab="turkeydinner"},foodprefab="turkeydinner"},
{id="winter_waffles",season="winter",kind="normal",name="Bánh Waffle",description="Ăn 1 phần bánh waffle.",event="oneat",target=1,params={prefab="waffles"},foodprefab="waffles"},
{id="winter_cookedmeat",season="winter",kind="normal",name="Thịt Nướng Bên Lửa",description="Ăn 8 miếng thịt lớn đã nấu.",event="oneat",target=8,params={prefab="cookedmeat"},foodprefab="cookedmeat"},
{id="winter_smallmeat",season="winter",kind="normal",name="Miếng Thịt Nhỏ",description="Ăn 8 miếng thịt nhỏ đã nấu.",event="oneat",target=8,params={prefab="cookedsmallmeat"},foodprefab="cookedsmallmeat"},
{id="winter_monstermeat",season="winter",kind="normal",name="Thịt Quái Nướng",description="Ăn 3 miếng thịt quái vật đã nấu.",event="oneat",target=3,params={prefab="cookedmonstermeat"},foodprefab="cookedmonstermeat"},
{id="winter_cookedfish",season="winter",kind="normal",name="Cá Nướng Mùa Đông",description="Ăn 5 con cá ao đã nấu.",event="oneat",target=5,params={prefab="fish_cooked"},foodprefab="fish_cooked"},
{id="winter_cookedeel",season="winter",kind="normal",name="Lươn Nướng Than",description="Ăn 3 con lươn đã nấu.",event="oneat",target=3,params={prefab="eel_cooked"},foodprefab="eel_cooked"},
{id="winter_icehound",season="winter",kind="normal",name="Chó Săn Băng",description="Hạ 5 chó săn băng.",event="killed",target=5,params={prefab="icehound"}},
{id="winter_koalefant",season="winter",kind="normal",name="Voi Lông Dày",description="Hạ 1 Koalefant mùa đông.",event="killed",target=1,params={prefab="koalefant_winter"}},
{id="winter_walrus",season="winter",kind="normal",name="Thợ Săn Hải Mã",description="Hạ 2 MacTusk trong mùa đông.",event="killed",target=2,params={prefab="walrus"}},
{id="winter_littlewalrus",season="winter",kind="normal",name="Hải Mã Con",description="Hạ 2 Wee MacTusk trong mùa đông.",event="killed",target=2,params={prefab="little_walrus"}},
{id="winter_treeguard",season="winter",kind="normal",name="Thần Rừng Thông",description="Hạ 1 Treeguard thường.",event="killed",target=1,params={prefab="leif"}},
{id="winter_lumpytreeguard",season="winter",kind="normal",name="Thần Rừng Thưa",description="Hạ 1 Treeguard từ cây thông thưa.",event="killed",target=1,params={prefab="leif_sparse"}},
{id="winter_terrorbeak",season="winter",kind="normal",name="Mỏ Kinh Hoàng",description="Hạ 3 Terrorbeak do mất tỉnh táo.",event="killed",target=3,params={prefab="terrorbeak"}},
{id="winter_deerclops",season="winter",kind="normal",name="Người Khổng Lồ Một Mắt",description="Hạ 1 Deerclops trong mùa đông.",event="killed",target=1,params={prefab="deerclops"}},
{id="winter_krampus",season="winter",kind="normal",name="Kẻ Trộm Mùa Đông",description="Hạ 1 Krampus sau khi tích lũy độ nghịch.",event="killed",target=1,params={prefab="krampus"}},
{id="winter_rook",season="winter",kind="normal",name="Xe Máy Canh Gác",description="Hạ 2 quân xe máy Clockwork Rook.",event="killed",target=2,params={prefab="rook"}},
{id="winter_heatrock",season="winter",kind="normal",name="Đá Giữ Nhiệt",description="Chế tạo 1 viên đá giữ nhiệt.",event="builditem",target=1,params={prefab="heatrock"}},
{id="winter_winterhat",season="winter",kind="normal",name="Mũ Len Mùa Đông",description="Chế tạo 1 mũ mùa đông.",event="builditem",target=1,params={prefab="winterhat"}},
{id="winter_beefalohat",season="winter",kind="normal",name="Mũ Lông Beefalo",description="Chế tạo 1 mũ Beefalo giữ ấm.",event="builditem",target=1,params={prefab="beefalohat"}},
{id="winter_trunkvest",season="winter",kind="normal",name="Áo Lông Dày",description="Chế tạo 1 áo voi mùa đông.",event="builditem",target=1,params={prefab="trunkvest_winter"}},
{id="winter_bandage",season="winter",kind="normal",name="Băng Mật Ong",description="Chế tạo 3 băng mật ong.",event="builditem",target=3,params={prefab="bandage"}},
{id="winter_salve",season="winter",kind="normal",name="Thuốc Bôi Vết Thương",description="Chế tạo 3 thuốc bôi hồi máu.",event="builditem",target=3,params={prefab="healingsalve"}},
{id="winter_firepit",season="winter",kind="normal",name="Bếp Sưởi Đá",description="Dựng 1 bếp lửa đá.",event="buildstructure",target=1,params={prefab="firepit"}},
{id="winter_lantern",season="winter",kind="normal",name="Đèn Lồng Đêm Dài",description="Chế tạo 1 đèn lồng.",event="builditem",target=1,params={prefab="lantern"}},
{id="winter_minerhat",season="winter",kind="normal",name="Mũ Đèn Thợ Mỏ",description="Chế tạo 1 mũ đèn thợ mỏ.",event="builditem",target=1,params={prefab="minerhat"}},
{id="winter_tent",season="winter",kind="normal",name="Lều Trú Đông",description="Dựng 1 lều nghỉ tại căn cứ.",event="buildstructure",target=1,params={prefab="tent"}},
{id="winter_ice",season="winter",kind="normal",name="Dự Trữ Băng",description="Nhận vào hành trang tổng cộng 30 viên băng.",event="itemget",target=30,params={prefab="ice"}},
{id="winter_cutstone",season="winter",kind="normal",name="Đá Xây Trú Ẩn",description="Nhận vào hành trang tổng cộng 12 đá cắt.",event="itemget",target=12,params={prefab="cutstone"}},
{id="winter_nitre",season="winter",kind="normal",name="Diêm Tiêu Dự Trữ",description="Nhận vào hành trang tổng cộng 15 diêm tiêu.",event="itemget",target=15,params={prefab="nitre"}},
{id="winter_gold",season="winter",kind="normal",name="Vàng Dưới Tuyết",description="Nhận vào hành trang tổng cộng 20 vàng.",event="itemget",target=20,params={prefab="goldnugget"}},
{id="winter_marble",season="winter",kind="normal",name="Cẩm Thạch Trắng",description="Nhận vào hành trang tổng cộng 12 cẩm thạch.",event="itemget",target=12,params={prefab="marble"}},
{id="winter_moonrock",season="winter",kind="normal",name="Đá Trăng Lạnh",description="Nhận vào hành trang tổng cộng 12 đá mặt trăng.",event="itemget",target=12,params={prefab="moonrocknugget"}},
{id="winter_thulecite",season="winter",kind="normal",name="Khoáng Cổ Đại",description="Nhận vào hành trang tổng cộng 6 Thulecite.",event="itemget",target=6,params={prefab="thulecite"}},
{id="winter_fragments",season="winter",kind="normal",name="Mảnh Khoáng Cổ",description="Nhận vào hành trang tổng cộng 18 mảnh Thulecite.",event="itemget",target=18,params={prefab="thulecite_pieces"}},
{id="winter_redgem",season="winter",kind="normal",name="Ngọc Đỏ Sưởi Ấm",description="Nhận vào hành trang tổng cộng 3 ngọc đỏ.",event="itemget",target=3,params={prefab="redgem"}},
{id="winter_purplegem",season="winter",kind="normal",name="Ngọc Tím Huyền Thuật",description="Nhận vào hành trang tổng cộng 2 ngọc tím.",event="itemget",target=2,params={prefab="purplegem"}},
{id="winter_kabob",season="winter",kind="count",name="Xiên Thịt Nóng",description="Ăn 3 xiên thịt mỗi lượt.",event="oneat",target=3,params={prefab="kabobs"},foodprefab="kabobs"},
{id="winter_meatballs",season="winter",kind="count",name="Thịt Viên No Bụng",description="Ăn 3 phần thịt viên mỗi lượt.",event="oneat",target=3,params={prefab="meatballs"},foodprefab="meatballs"},
{id="winter_stew",season="winter",kind="count",name="Nồi Thịt Hầm",description="Ăn 3 phần thịt hầm mỗi lượt.",event="oneat",target=3,params={prefab="bonestew"},foodprefab="bonestew"},
{id="winter_pengull",season="winter",kind="count",name="Đàn Pengull",description="Hạ 5 Pengull mỗi lượt.",event="killed",target=5,params={prefab="penguin"}},
{id="winter_evergreen",season="winter",kind="count",name="Củi Thông",description="Chặt hạ 8 cây thông thường mỗi lượt.",event="finishedwork",target=8,params={action="CHOP",prefab="evergreen"}},
{id="winter_lumpy",season="winter",kind="count",name="Củi Thông Thưa",description="Chặt hạ 8 cây thông thưa mỗi lượt.",event="finishedwork",target=8,params={action="CHOP",prefab="evergreen_sparse"}},
{id="winter_glacier",season="winter",kind="count",name="Khai Thác Băng",description="Đào vỡ 8 tảng băng nhỏ mỗi lượt.",event="finishedwork",target=8,params={action="MINE",prefab="rock_ice"}},
{id="winter_lichen",season="winter",kind="count",name="Địa Y Dưới Hang",description="Hái 8 bụi địa y mỗi lượt.",event="picksomething",target=8,params={prefab="lichen"}},
}

local by_id = {}
local by_season = {}

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = Copy(child) end
    return result
end

local function IsUsed(used_ids, id)
    if type(used_ids) ~= "table" then return false end
    if used_ids[id] == true then return true end
    for _, used_id in ipairs(used_ids) do
        if used_id == id then return true end
    end
    return false
end

function Catalog.Validate()
    local ids = {}
    local pools = {}
    for _, season in ipairs(Catalog.SEASONS) do
        pools[season] = {normal = {}, count = {}}
    end
    for _, row in ipairs(definitions) do
        assert(type(row.id) == "string" and not ids[row.id], "duplicate seasonal ID: " .. tostring(row.id))
        assert(pools[row.season] ~= nil, "invalid seasonal season: " .. tostring(row.season))
        assert(row.kind == "normal" or row.kind == "count", "invalid seasonal kind: " .. tostring(row.kind))
        assert(type(row.name) == "string" and row.name ~= "", "missing seasonal name")
        assert(type(row.description) == "string" and row.description ~= "", "missing seasonal description")
        assert(type(row.event) == "string" and row.event ~= "", "missing seasonal event")
        assert(type(row.params) == "table", "missing seasonal evidence")
        assert(type(row.target) == "number" and row.target > 0 and row.target == math.floor(row.target), "invalid seasonal target")
        ids[row.id] = row
        pools[row.season][row.kind][#pools[row.season][row.kind] + 1] = row
    end
    assert(#definitions == 192, "seasonal catalog must contain 192 activities")
    for _, season in ipairs(Catalog.SEASONS) do
        assert(#pools[season].normal == 40, season .. " must contain 40 normal activities")
        assert(#pools[season].count == 8, season .. " must contain 8 count activities")
    end
    by_id = ids
    by_season = pools
    return true
end

function Catalog.All()
    return Copy(definitions)
end

function Catalog.ById(id)
    return type(id) == "string" and by_id[id] and Copy(by_id[id]) or nil
end

function Catalog.IsSeason(season)
    return type(season) == "string" and by_season[season] ~= nil
end

function Catalog.Pool(season, kind)
    local pools = by_season[season]
    if pools == nil or (kind ~= "normal" and kind ~= "count") then return {} end
    return Copy(pools[kind])
end

function Catalog.Draw(season, used_ids, random_fn)
    if not Catalog.IsSeason(season) then return nil, "invalid season" end
    random_fn = random_fn or math.random
    local result = {}

    local function DrawKind(kind, amount)
        local available = {}
        for _, row in ipairs(by_season[season][kind]) do
            if not IsUsed(used_ids, row.id) then available[#available + 1] = row end
        end
        if #available < amount then return false end
        for index = 1, amount do
            local chosen = random_fn(index, #available)
            if type(chosen) ~= "number" or chosen ~= math.floor(chosen) or chosen < index or chosen > #available then
                return false
            end
            available[index], available[chosen] = available[chosen], available[index]
            result[#result + 1] = Copy(available[index])
        end
        return true
    end

    if not DrawKind("normal", Catalog.NORMAL_PER_ROUND) then return nil, "not enough unused normal quests" end
    if not DrawKind("count", Catalog.COUNT_PER_ROUND) then return nil, "not enough unused count quests" end
    return result
end

Catalog.Validate()
return Catalog
