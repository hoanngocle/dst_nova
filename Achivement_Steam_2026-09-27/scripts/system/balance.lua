reset_refund_percentage = _G.REFUND_CONFIG
reset_health_penalty 	= _G.HPPENALTY_CONFIG

attributepointsOnLevel = _G.LEVELPOINTS
achievementAssistrange = _G.ASSISTRANGE_CONFIG

cz_initial_stars = 10

-- leveldataup
healthGain = _G.HEALTHGAIN
sanityGain = _G.SANITYGAIN
hungerGain = _G.HUNGERGAIN
speedGain = _G.SPEEDGAIN
absorbGain = _G.ABSORBGAIN
damageGain = _G.DAMAGEGAIN
max_absorbGain = _G.MAX_ABSORBGAIN
petspeedGain = 0.05
petdamageGain = 1

-- perkdataup
allachiv_coindata={
	["hungerup"] = 3,
	["sanityup"] = 3,
	["healthup"] = 3,
	["healthregenup"] = 0.1,
	["hungerrateup"] = 0.01,
	["sanityregenup"] = 0.1,
	["speedup"] = 0.01,
	["absorbup"] = 0.025, --obsolete
	["damageup"] = 0.01, --obsolete
	["planarabsorbup"] = 0.25,
	["planardamageup"] = 0.5,
	["criticalup"] = 0.01,
	["criticaldmgup"] = 0.01,
	["lifestealup"] = 0.005,
	["fireflylightup"] = 0.4,
	["scaleup"] = 0.01,
	["xpmultup"] = 0.05,
	["repairitemup"] = 0.001,
	["repairmagiup"] = 0.001,
	["repairfoodup"] = 0.1,
	["krampussackup"] = .05,
}
toggleableglobalperk = {
	riftcontroller = true,
}

booklist =
{
	"book_birds", "book_sleep", "book_tentacles", "book_brimstone", "book_horticulture", "book_horticulture_upgraded", "book_silviculture", "book_fish",
	"book_fire", "book_web", "book_temperature", "book_light", "book_light_upgraded", "book_rain", "book_moon", "book_bees", "book_research_station"
}
fishlist =
{
	"oceanfish_small_1_inv", "oceanfish_small_2_inv", "oceanfish_small_3_inv", "oceanfish_small_4_inv", "oceanfish_small_5_inv", "oceanfish_small_6_inv", "oceanfish_small_7_inv", "oceanfish_small_8_inv", "oceanfish_small_9_inv",
	"oceanfish_medium_1_inv", "oceanfish_medium_2_inv", "oceanfish_medium_3_inv", "oceanfish_medium_4_inv", "oceanfish_medium_5_inv", "oceanfish_medium_8_inv", "oceanfish_medium_9_inv"
}
-- Stuffed Pepper Poppers, Dragonpie, Honey Ham, Kabobs, Spicy Chili, Stuffed Eggplant, Turkey Dinner, Hot Dragon Chili Salad
-- Fruit Medley, Melonsicle, Ice Cream, Ceviche, Banana Pop, Asparagazpacho
heatfood = {"pepperpopper", "dragonpie", "honeyham", "kabobs", "hotchili", "stuffedeggplant", "turkeydinner", "dragonchilisalad"}
coldfood = {"fruitmedley", "watermelonicle", "icecream", "ceviche", "bananapop", "gazpacho"}
magicitems = {
	"crabstaff_shadow", "crabstaff_lunar", "crabstaff_electric", "crabstaff_fire", "crabstaff_water", "crabstaff_ice",
}
plantables =
{
	"pinecone", "twiggy_nut", "acorn", "palmcone_seed", "marblebean", "seeds",
	"dug_berrybush", "dug_berrybush2", "dug_berrybush_juicy", "dug_grass", "dug_marsh_bush", "dug_sapling", 
	"dug_rock_avocado_bush", "rock_avocado_fruit_sprout", "dug_sapling_moon", 
	"dug_bananabush", "dug_monkeytail",
	"butterfly", "moonbutterfly", "livingtree_root",
	"cave_banana_seeds", "carrot_seeds", "corn_seeds", "pumpkin_seeds", "eggplant_seeds", "durian_seeds", "pomegranate_seeds",
	"dragonfruit_seeds", "berries_seeds", "berries_juicy_seeds", "fig_seeds", "cactus_meat_seeds", "watermelon_seeds",
	"kelp_seeds", "tomato_seeds", "potato_seeds", "asparagus_seeds", "onion_seeds", "garlic_seeds", "pepper_seeds",
}
farmplantlist =  {
	"farm_plant_randomseed", "farm_plant_asparagus", "farm_plant_garlic", "farm_plant_pumpkin", "farm_plant_corn",
	"farm_plant_onion", "farm_plant_potato", "farm_plant_dragonfruit", "farm_plant_pomegranate", "farm_plant_eggplant",
	"farm_plant_tomato", "farm_plant_watermelon", "farm_plant_pepper", "farm_plant_durian", "farm_plant_carrot",
}
--Ancient Mural, Boulder, Boulder, Boulder, Mini Glacier, Moon Glass, Broken Clockworks, Broken Clockworks, Broken Clockworks, Bones, Sea Bones, Skeleton, Red Mushroom, Blue Mushroom, Green Mushroom, Blue Mushtree, Red Mushtree, Green Mushtree, Lunar Mushtree, Webbed Blue Mushtree, Cactus, Planted Carrot, Cave Lichen, Reeds, Driftwood Tree, Spiky Tree, Cave Banana Tree, Flower, Evil Flower, Fern, Succulent, Light Flower, Mysterious Plant, Headstone, Obelisk, Obelisk, Beehive, Killer Bee Hive, Rabbit Hole, Walrus Camp, Pond, Pond, Pond, Magma, Hot Spring, Tidy Hidey-Hole, Small Vitreoasis, Naked Mole Bat Burrow, Slurtle Mound
investigateablelist =
{
	"atrium_rubble", "rock1", "rock_flintless", "rock_moon", "rock_ice", "moonglass_rock",
	"chessjunk1", "chessjunk2", "chessjunk3", "houndbone", "dead_sea_bones", "skeleton",
	"red_mushroom",	"blue_mushroom", "green_mushroom", "mushtree_tall",	"mushtree_medium", "mushtree_small", "mushtree_moon", "mushtree_tall_webbed",
	"cactus", "oasis_cactus", "carrot_planted", "lichen", "reeds",
	"driftwood_small1", "driftwood_small2", "driftwood_tall", "marsh_tree", "cave_banana_tree",
	"flower", "flower_evil", "cave_fern", "succulent_plant",
	"flower_cave", "flower_cave_double", "flower_cave_triple", "wormlight_plant",
	"gravestone", "sanityrock", "insanityrock",
	"beehive", "wasphive", "rabbithole", "walrus_camp",
	"pond", "pond_mos", "pond_cave", "lava_pond", "hotspring",
	"dustmothden", "grotto_pool_small", "molebathill", "slurtlehole"
}
-- Salt Formation, Sea Stack, Wobster Mound, Moon Glass Mound, Sea Strider Nest, Mossy Vine
investigateablelist_water =
{
	"saltstack", "seastack", "wobster_den", "moonglass_wobster_den", "oceanvine_cocoon", "oceanvine",
}
AchievementData = {}
LevelData = {}
DespawnData = {}

-- TUNING
TUNING.EXPERT_WOODIE1_COOLDOWN = {
	goose = TUNING.TOTAL_DAY_TIME * 2,
	beaver = TUNING.TOTAL_DAY_TIME * 2,
	moose = TUNING.TOTAL_DAY_TIME * 7,
}

-- ROG
chasni_boss_prefab_default =
{
	chasni_crocodogspawner = 0.20,
	chasni_pangolden = 0.20,
	chasni_giantgrub = 0.20,
	chasni_wargfant = 0.20,
	chasni_spidermonkey = 0.20,
}
chasni_boss_prefab_winter =
{
	chasni_brrrd_winter = 0.3,
	chasni_slipstor = 0.3,
	allseason = 0.4,
}
chasni_boss_prefab_spring =
{
	chasni_snapdragon = 0.3,
	chasni_adultflytrap = 0.3,
	allseason = 0.4,
}
chasni_boss_prefab_summer =
{
	chasni_brrrd_summer = 0.3,
	chasni_treeguard = 0.3,
	allseason = 0.4,
}
chasni_boss_prefab_autumn =
{
	chasni_mandrakeman = 0.3,
	chasni_hippopotamoose = 0.3,
	allseason = 0.4,
}
chasni_boss_drop =
{
	"chasni_wargfant_tooth",
	"chasni_wargfant_fur",
	"chasni_grub_jaw",
	"chasni_grub_skull",
	"chasni_pangolden_scale",
	"chasni_crocodog_skin",
	"chasni_cocoontreeseed",
	"chasni_quas_feather",
	"chasni_slipstor_fur",
	"chasni_snapdragon_petal",
	"dug_trap_flytrap",
	"chasni_snapdragon_seed",
	"chasni_exort_feather",
	"chasni_palmtreeguard_log",
	"chasni_hippo_skin",
	"chasni_hippo_antler",
	"chasni_gas",
}
