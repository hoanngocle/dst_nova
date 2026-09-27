GLOBAL.require("fx")
local function GroundOrientation(inst)
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
end

local function FinalOffset3(inst)
	inst.AnimState:SetFinalOffset(3)
end

local Vector3 = GLOBAL.Vector3
local FX =
{
	{
		name = "chop_mangrove_pink",
		bank = "chop_mangrove",
		build = "chop_mangrove_pink",
		anim = "chop",
	},
	{
		name = "fall_mangrove_pink",
		bank = "chop_mangrove",
		build = "chop_mangrove_pink",
		anim = "fall",
	},
	{
		name = "hacking_tall_grass_fx",
		bank = "hacking_fx",
		build = "hacking_tall_grass_fx",
		anim = "idle",
	},
	{
		name = "groundpound_nosound_fx",
		bank = "bearger_ground_fx",
		build = "bearger_ground_fx",
		anim = "idle",
	},
	{
		name = "snake_scales_fx",
		bank = "snake_scales_fx",
		build = "snake_scales_fx",
		anim = "idle",
	},
	{
		name = "splash_water",
		bank = "splash_water",
		build = "splash_water",
		anim = "idle",
	},
	{
		name = "bombsplash",
		bank = "bombsplash",
		build = "water_bombsplash",
		anim = "splash",
	},
	{
		name = "coconut_chunks",
		bank = "ground_breaking",
		build = "ground_chunks_breaking",
		anim = "idle",
		tint = Vector3(183/255,143/255,85/255),
	},
	{
		name = "sparks_green_fx",
		bank = "sparks",
		build = "sparks_green",
		anim = "sparks_1",
	},
	{
		name = "robot_leaf_fx",
		bank = "robot_leaf_fx",
		build = "robot_leaf_fx",
		anim = "idle",
	},
	{
		name = "hacking_fx",
		bank = "hacking_fx",
		build = "hacking_fx",
		anim = "idle",
	},

	{
		name = "circle_puff_fx",
		bank = "circle_puff_fx",
		build = "circle_puff_fx",
		anim = "idle",
	},
	{
		name = "sparklefx",
		bank = "sparklefx",
		build = "sparklefx",
		anim = "sparkle",
		sound = "dontstarve/common/chest_positive",
		tintalpha = 0.6,
	},
	{
		name = "groundpound_fx_hulk",
		bank = "bearger_ground_fx",
		build = "bearger_ground_fx",
		sound = "DLChasni/DLChasni/chasni_hulk/dust",
		anim = "idle",
	},
	{
		name = "laser_burst_fx",
		bank = "laser_ring_fx",
		build = "laser_ring_fx",
		anim = "idle",
	},
	{
		name = "living_suit_explode_fx",
		bank = "living_suit_explode_fx",
		build = "living_suit_explode_fx",
		anim = "idle",
	},
	{
		name = "rock_hit_debris",
		bank = "rock_hit_debris",
		build = "rock_hit_debris",
		anim = "hit_rock_ruins",
	},
	{
		name = "poop_splat",
		bank = "ground_breaking",
		build = "ground_chunks_breaking",
		anim = "idle",
		tint = Vector3(183/255,143/255,85/255),
	},
	{
		name = "shock_machines_fx",
		bank = "shock_machines_fx",
		build = "shock_machines_fx",
		anim = "shock",
	},
	{
		name = "hacking_bamboo_fx",
		bank = "hacking_bamboo_fx",
		build = "hacking_bamboo_fx",
		anim = "idle",
	},
	{
		name = "jungle_chop",
		bank = "chop_jungle",
		build = "chop_jungle",
		anim = "chop",
	},
	{
		name = "jungle_fall",
		bank = "chop_jungle",
		build = "chop_jungle",
		anim = "fall",
	},
	{
		name = "mangrove_chop",
		bank = "chop_mangrove",
		build = "chop_mangrove",
		anim = "chop",
	},
	{
		name = "mangrove_fall",
		bank = "chop_mangrove",
		build = "chop_mangrove",
		anim = "fall",
	},
	{
		name = "chasni_music_fx",
		bank = "music_fx",
		build = "music_fx",
		anim = "loop",
		fn = function(inst) inst.Transform:SetScale(2.2,2.2,2.2)end,
	},
	{
		name =  "voker_light",
		bank =  "fx_book_light",
		build = "fx_book_light",
		anim =  "play_fx",
	},
	{
		name = "vortex_cloak_fx",
		bank = "vortex_cloak_fx",
		build = "vortex_cloak_fx",
		anim = "idle",
	},
	{
		name = "chasni_halloween_moonpuff",
		bank = "fx_moon_tea",
		build = "moon_tea_fx",
		anim = "puff",
		bloom = true,
		fn = FinalOffset3,
	},
	{
		name =  "batbat_batfx1",
		bank =  "batbat_bats",
		build = "batbat_batfx",
		anim =  "bat1",
        fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name =  "batbat_batfx2",
		bank =  "batbat_bats",
		build = "batbat_batfx",
		anim =  "bat2",
        fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name =  "batbat_batfx3",
		bank =  "batbat_bats",
		build = "batbat_batfx",
		anim =  "bat3",
        fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name =  "batbat_batfx4",
		bank =  "batbat_bats",
		build = "batbat_batfx",
		anim =  "bat4",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name =  "embershield",
		bank =  "chasni_willow_shield",
		build = "willow_shield",
		anim =  "idle",
	},
	{
		name = "battlesong_instant_recharge_fx",
		bank = "fx_wathgrithr_buff",
		build = "fx_wathgrithr_buff",
		anim = "quote_electric",
	},
	{
		name = "battlesong_instant_stopmove_fx",
		bank = "fx_wathgrithr_buff",
		build = "fx_wathgrithr_buff",
		anim = "quote_dropattack",
	},
	{
		name = "battlesong_sailor_fx",
		bank = "fx_wathgrithr_buff",
		build = "chasni_fx_wathgrithr_buff",
		anim = "fx_healthgain",
	},
	{
		name = "battlesong_lightning_fx",
		bank = "fx_wathgrithr_buff",
		build = "chasni_fx_wathgrithr_buff",
		anim = "fx_sanitygain",
	},
	{
		name = "sf_ult1_fx",
		bank = "moon_altar_geyser",
		build = "chasni_moon_geyser",
		anim = "explode",
	},
	{
		name = "sf_ult2_fx",
		bank = "moon_altar_geyser",
		build = "chasni_moon_geyser",
		anim = "moonpulse",
		fn = function(inst)
			inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
		end,
	},
	{
		name = "sf_ult3_fx",
		bank = "moon_altar_geyser",
		build = "chasni_moon_geyser",
		anim = "moonpulse2",
		sound = "chasni_song/chasni_song/requirem",
		fn = function(inst)
			inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
		end,
	},
	{
		name = "lucent_beamfx",
		bank = "alterguardian_meteor",
		build = "chasni_alterguardian_meteor",
		anim = "meteor_pre",
	},
	{
		name = "lunar_ground_fx",
		bank = "lunar_shadowfx",
		build = "lunar_shadow_books_fxs",
		anim = "lunar_ground",
		fn = GroundOrientation
	},
	{
		name = "chasni_scoutbadges_attack_onfx",
		bank = "chasni_scoutbadgesfx",
		build = "chasni_scoutbadgesfx",
		anim = "attack_on",
	},
	{
		name = "chasni_scoutbadges_attack_offfx",
		bank = "chasni_scoutbadgesfx",
		build = "chasni_scoutbadgesfx",
		anim = "attack_off",
	},
	{
		name = "plantdeath_goo_fx",
		bank = "plant_death_fx",
		build = "plant_death_fx",
		anim = "goo",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "plantdeath_fx",
		bank = "plant_death_fx",
		build = "plant_death_fx",
		anim = "plant_death",
		fn = function(inst) inst.Transform:SetScale(1.5,1.5,1.5)end,
	},
	{
		name = "chasni_attackfx3",
		bank = "lavaarena_beetletaur_fx",
		build = "lavaarena_beetletaur_fx",
		anim = "defend_fx",
	},
	{
		name = "chasni_tooth_green1",
		bank = "chasni_tooth_green",
		build = "chasni_tooth_green",
		anim = "attack_fx3",
		fn = function(inst) GroundOrientation(inst) inst.Transform:SetScale(1.5,1.5,1.5)end,
	},
	{
		name = "chasni_tooth_green2",
		bank = "chasni_tooth_green",
		build = "chasni_tooth_green",
		anim = "attack_fx3_pre",
		fn = function(inst) GroundOrientation(inst) inst.Transform:SetScale(1.25,1.25,1.25)end,
	},
	{
		name = "chasni_blast_green",
		bank = "chasni_blast_green",
		build = "chasni_blast_green",
		anim = "defend_fx",
		fn = function(inst) inst.Transform:SetScale(0.7,0.7,0.7)end,
	},
	{
		name = "chasni_tooth_pink1",
		bank = "chasni_tooth_pink",
		build = "chasni_tooth_pink",
		anim = "attack_fx3",
		fn = function(inst) GroundOrientation(inst) inst.Transform:SetScale(1.5,1.5,1.5)end,
	},
	{
		name = "chasni_tooth_pink2",
		bank = "chasni_tooth_pink",
		build = "chasni_tooth_pink",
		anim = "attack_fx3_pre",
		fn = function(inst) GroundOrientation(inst) inst.Transform:SetScale(1.25,1.25,1.25)end,
	},
	{
		name = "chasni_blast_pink",
		bank = "chasni_blast_pink",
		build = "chasni_blast_pink",
		anim = "defend_fx",
		fn = function(inst) inst.Transform:SetScale(0.7,0.7,0.7)end,
	},
	{
		name = "big_water_splash",
		bank = "quagmire_portalspawn_fx",
		build = "quagmire_portalspawn_fx",
		anim = "exit",
		sound = "dontstarve/creatures/pengull/splash",
	},
	{
		name = "pyro_fire_fx",
		bank = "pyro_fire_fx",
		build = "pyro_fire_fx",
		anim = "fire_extinguish",
		fn = function(inst) inst.Transform:SetScale(3,3,3)end,
	},
	{
		name = "chasni_blink_fx1",
		bank = "chasni_blink_fx",
		build = "chasni_blink_fx",
		anim = "loop",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_blink_fx2",
		bank = "chasni_blink_fx",
		build = "chasni_blink_fx",
		anim = "glint_fx_bloom",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_sing_black_fx",
		bank = "chasni_sing_black_fx",
		build = "chasni_sing_black_fx",
		anim = "working_loop",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_sing_green_fx",
		bank = "chasni_sing_green_fx",
		build = "chasni_sing_green_fx",
		anim = "working_loop",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_projectile_neuron_impact",
		bank = "chasni_projectile_neuron",
		build = "chasni_projectile_neuron",
		anim = "explode",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_projectile_neuron_yellow_impact",
		bank = "chasni_projectile_neuron_yellow",
		build = "chasni_projectile_neuron_yellow",
		anim = "explode",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_neuron_blast",
		bank = "chasni_projectile_neuron",
		build = "chasni_projectile_neuron",
		anim = "collision",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_neuron_blast_yellow",
		bank = "chasni_projectile_neuron_yellow",
		build = "chasni_projectile_neuron_yellow",
		anim = "collision",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_projectile_laser_impact1",
		bank = "chasni_projectile_laser_impact",
		build = "chasni_projectile_laser_impact",
		anim = "full",
	},
	{
		name = "chasni_projectile_laser_impact2",
		bank = "chasni_projectile_laser_impact",
		build = "chasni_projectile_laser_impact",
		anim = "partial",
	},
	{
		name = "chasni_projectile_laser_impact3",
		bank = "chasni_projectile_laser_impact",
		build = "chasni_projectile_laser_impact",
		anim = "graze",
	},
	{
		name = "chasni_explosion_magic_green_fx1",
		bank = "chasni_explosion_magic_green_fx",
		build = "chasni_explosion_magic_green_fx",
		anim = "explode",
		fn = function(inst)
			inst.Transform:SetScale(2,2,2)
		end,
	},
	{
		name = "chasni_explosion_magic_green_fx2",
		bank = "chasni_explosion_magic_green_fx",
		build = "chasni_explosion_magic_green_fx",
		anim = "explode_ground",
		fn = function(inst) GroundOrientation(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_squid_ink_fx",
		bank = "chasni_squid_ink_fx",
		build = "chasni_squid_ink_fx",
		anim = "loop",
	},
	{
		name = "chasni_snore_fx",
		bank = "chasni_snore_fx",
		build = "chasni_snore_fx",
		anim = "snore",
		fn = function(inst) GroundOrientation(inst) inst.Transform:SetScale(3,3,3)end,
	},
	{
		name = "firework_fx",
		bank = "firework",
		build = "accomplishment_fireworks",
		anim = "single_firework",
		sound = "dontstarve/common/shrine/sadwork_fire",
		sound2 = "dontstarve/common/shrine/sadwork_explo",
		sounddelay2 = 26/30,
		fntime = 26/30
	},
	{
		name = "chasni_green_bubble_mid_buff_fx",
		bank = "chasni_green_bubble_mid_buff_fx",
		build = "chasni_green_bubble_mid_buff_fx",
		anim = "fall_loop",
	},

	-- UNUSED :
	{
		name = "multifirework_fx",
		bank = "firework",
		build = "accomplishment_fireworks",
		anim = "multi_firework",
		sound = "dontstarve/common/shrine/sadwork_fire",
		sound2 = "dontstarve/common/shrine/firework_explo",
		sounddelay2 = 26/30,
		fntime = 26/30
	},
	{
		name = "energyball",
		bank = "laserball",
		build = "laserball",
		anim = "laserball",
		fn = function(inst)
			inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
			inst.AnimState:SetLightOverride(1)
			local alpha = 1
			local delta = 0.1
			inst:DoPeriodicTask(0, function(i)
				alpha = math.max(0, alpha - delta)
				inst.AnimState:SetMultColour(1, 1, 1, alpha)
			end)
		end,
	},
	{
		name = "chasni_attackfx1",
		bank = "lavaarena_beetletaur_fx",
		build = "lavaarena_beetletaur_fx",
		anim = "attack_fx3",
	},
	{
		name = "chasni_attackfx2",
		bank = "lavaarena_beetletaur_fx",
		build = "lavaarena_beetletaur_fx",
		anim = "attack_fx3_pre",
	},
	{
		name = "chasni_attackfx4",
		bank = "lavaarena_beetletaur_fx",
		build = "lavaarena_beetletaur_fx",
		anim = "defend_fx_pre",
	},
	{
		name = "chasni_diseasefx1",
		bank = "disease_fx",
		build = "disease_fx",
		anim = "disease",
	},
	{
		name = "chasni_diseasefx2",
		bank = "disease_fx",
		build = "disease_fx",
		anim = "disease_small",
		fn = function(inst)
			inst.Transform:SetScale(.5,.5,.5)
		end,
	},
	{
		name = "chasni_diseasefx3",
		bank = "disease_fx",
		build = "disease_fx",
		anim = "disease_tall",
	},
	{
		name = "fight_cloudfx",
		bank = "fight_cloud",
		build = "fight_cloud",
		anim = "cloud_pre",
		animqueue = true,
		fn = function(inst)
			inst.Transform:SetScale(2.2,2.2,2.2)
			inst.AnimState:PushAnimation("cloud_loop", false)
			inst.AnimState:PushAnimation("cloud_post", false)
		end,
	},
	{
		name = "interacts_dumpablefx",
		bank = "anim_interacts_dumpable",
		build = "anim_interacts_dumpable",
		anim = "working",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "smelter_flash_fx",
		bank = "smelter_flash_fx",
		build = "smelter_flash_fx",
		anim = "pre",
		animqueue = true,
		fn = function(inst)
			inst.Transform:SetScale(2.5,2.5,2.5)
			inst.AnimState:PushAnimation("loop", false)
			inst.AnimState:PushAnimation("post", false)
		end,
	},
	{
		name = "missile_explosionfx",
		bank = "missile_explosion",
		build = "missile_explosion",
		anim = "idle",
	},
	{
		name = "moo_call_fx",
		bank = "moo_call_fx",
		build = "moo_call_fx",
		anim = "moo_call",
		fn = GroundOrientation
	},
	{
		name = "chasni_whirlpool_fx",
		bank = "whirlpool_fx",
		build = "whirlpool_fx",
		anim = "loop",
		fn = function(inst) GroundOrientation(inst) inst.Transform:SetScale(1.5,1.5,1.5)end,
	},
	{
		name = "plant_harvest_impact_fx",
		bank = "plant_harvest_impact_fx",
		build = "plant_harvest_impact_fx",
		anim = "loop",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "fly_swarmfx",
		bank = "fly_swarm",
		build = "fly_swarm",
		anim = "swarm_pre",
		animqueue = true,
		fn = function(inst)
			inst.Transform:SetScale(3,3,3)
			inst.AnimState:PushAnimation("swarm_loop", false)
			inst.AnimState:PushAnimation("swarm_pst", false)
		end,
	},
	{
		name = "hologram_fx",
		bank = "hologram",
		build = "hologram",
		anim = "hologram_group_pre_bloom ",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "hologram_groundfx",
		bank = "hologram",
		build = "hologram",
		anim = "hologram_group_pre_bloom ",
		fn = function(inst) GroundOrientation(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "plantdeath_gas_puff_fx",
		bank = "plant_death_fx",
		build = "plant_death_fx",
		anim = "gas_Puff",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "plantdeath_gas_puff_fx2",
		bank = "plant_spray_impact_fx",
		build = "plant_spray_impact_fx",
		anim = "gas_Puff",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},

	{
		name = "chasni_arrow_fx",
		bank = "chasni_arrow_fx",
		build = "chasni_arrow_fx",
		anim = "heatfx_d",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
					{
						name = "chasni_bleed_fx",
						bank = "chasni_bleed_fx",
						build = "chasni_bleed_fx",
						anim = "slash",
						fn = function(inst) inst.Transform:SetScale(2,2,2)end,
					},
	{
		name = "chasni_bubble_fx",
		bank = "chasni_bubble_fx",
		build = "chasni_bubble_fx",
		anim = "bubble",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_bubble_poison_buff_fx",
		bank = "chasni_bubble_poison_buff_fx",
		build = "chasni_bubble_poison_buff_fx",
		anim = "gas_Puff",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_bubble_poison_fx",
		bank = "chasni_bubble_poison_fx",
		build = "chasni_bubble_poison_fx",
		anim = "bubble_forsound",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_cloud_action_fx",
		bank = "chasni_cloud_action_fx",
		build = "chasni_cloud_action_fx",
		anim = "working",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_cloud_rope_fx",
		bank = "chasni_cloud_rope_fx",
		build = "chasni_cloud_rope_fx",
		anim = "working_pre",
		animqueue = true,
		fn = function(inst)
			inst.Transform:SetScale(2.2,2.2,2.2)
			inst.AnimState:PushAnimation("working_loop", false)
			inst.AnimState:PushAnimation("working_pst", false)
		end,
	},
	{
		name = "chasni_confetti_fx",
		bank = "chasni_confetti_fx",
		build = "chasni_confetti_fx",
		anim = "100fx_pre",
		animqueue = true,
		fn = function(inst)
			inst.Transform:SetScale(2,2,2)
			inst.AnimState:PushAnimation("100fx", false)
		end,
	},
	{
		name = "chasni_cum_fx",
		bank = "chasni_cum_fx",
		build = "chasni_cum_fx",
		anim = "exhale_pre",
		animqueue = true,
		fn = function(inst)
			inst.Transform:SetScale(2,2,2)
			inst.AnimState:PushAnimation("exhale_loop", false)
			inst.AnimState:PushAnimation("old_exhale_pst", false)
		end,
	},
	{
		name = "chasni_drill_fx",
		bank = "chasni_drill_fx",
		build = "chasni_drill_fx",
		anim = "fall",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_electric_buff_fx",
		bank = "chasni_electric_buff_fx",
		build = "chasni_electric_buff_fx",
		anim = "damage_loop",
		fn = function(inst) inst.Transform:SetScale(3,3,3)end,
	},
	{
		name = "chasni_explosion_fire_fx",
		bank = "chasni_explosion_fire_fx",
		build = "chasni_explosion_fire_fx",
		anim = "explode_nosmoke",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_explosion_magic_fx1",
		bank = "chasni_explosion_magic_fx",
		build = "chasni_explosion_magic_fx",
		anim = "explode",
		fn = function(inst)
			inst.Transform:SetScale(3,3,3)
		end,
	},
	{
		name = "chasni_explosion_magic_fx2",
		bank = "chasni_explosion_magic_fx",
		build = "chasni_explosion_magic_fx",
		anim = "explode_ground",
		fn = function(inst) GroundOrientation(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_fire_magic_fx1",
		bank = "chasni_fire_magic_fx",
		build = "chasni_fire_magic_fx",
		anim = "small",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_fire_magic_fx2",
		bank = "chasni_fire_magic_fx",
		build = "chasni_fire_magic_fx",
		anim = "mid",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_fire_magic_fx3",
		bank = "chasni_fire_magic_fx",
		build = "chasni_fire_magic_fx",
		anim = "big",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_goku_brown_buff_fx1",
		bank = "chasni_goku_brown_buff_fx",
		build = "chasni_goku_brown_buff_fx",
		anim = "fall_loop",
	},
	{
		name = "chasni_goku_brown_buff_fx2",
		bank = "chasni_goku_brown_buff_fx",
		build = "chasni_goku_brown_buff_fx",
		anim = "fall_loop_front",
	},
	{
		name = "chasni_goku_fire_buff_fx1",
		bank = "chasni_goku_fire_buff_fx",
		build = "chasni_goku_fire_buff_fx",
		anim = "fall_loop",
	},
	{
		name = "chasni_goku_fire_buff_fx2",
		bank = "chasni_goku_fire_buff_fx",
		build = "chasni_goku_fire_buff_fx",
		anim = "fall_loop_front",
	},
	{
		name = "chasni_goku_green_buff_fx1",
		bank = "chasni_goku_green_buff_fx",
		build = "chasni_goku_green_buff_fx",
		anim = "fall_loop",
	},
	{
		name = "chasni_goku_green_buff_fx2",
		bank = "chasni_goku_green_buff_fx",
		build = "chasni_goku_green_buff_fx",
		anim = "fall_loop_front",
	},
	{
		name = "chasni_goku_hex_buff_fx1",
		bank = "chasni_goku_hex_buff_fx",
		build = "chasni_goku_hex_buff_fx",
		anim = "fall_loop",
	},
	{
		name = "chasni_goku_hex_buff_fx2",
		bank = "chasni_goku_hex_buff_fx",
		build = "chasni_goku_hex_buff_fx",
		anim = "fall_loop_front",
	},
	{
		name = "chasni_goku_lunar_buff_fx1",
		bank = "chasni_goku_lunar_buff_fx",
		build = "chasni_goku_lunar_buff_fx",
		anim = "fall_loop",
	},
	{
		name = "chasni_goku_lunar_buff_fx2",
		bank = "chasni_goku_lunar_buff_fx",
		build = "chasni_goku_lunar_buff_fx",
		anim = "fall_loop_front",
	},
	{
		name = "chasni_goku_magic_buff_fx1",
		bank = "chasni_goku_magic_buff_fx",
		build = "chasni_goku_magic_buff_fx",
		anim = "fall_loop",
	},
	{
		name = "chasni_goku_magic_buff_fx2",
		bank = "chasni_goku_magic_buff_fx",
		build = "chasni_goku_magic_buff_fx",
		anim = "fall_loop_front",
	},
	{
		name = "chasni_goku_purple_buff_fx1",
		bank = "chasni_goku_purple_buff_fx",
		build = "chasni_goku_purple_buff_fx",
		anim = "fall_loop",
	},
	{
		name = "chasni_goku_purple_buff_fx2",
		bank = "chasni_goku_purple_buff_fx",
		build = "chasni_goku_purple_buff_fx",
		anim = "fall_loop_front",
	},
	{
		name = "chasni_goku_red_buff_fx1",
		bank = "chasni_goku_red_buff_fx",
		build = "chasni_goku_red_buff_fx",
		anim = "fall_loop",
	},
	{
		name = "chasni_goku_red_buff_fx2",
		bank = "chasni_goku_red_buff_fx",
		build = "chasni_goku_red_buff_fx",
		anim = "fall_loop_front",
	},
	{
		name = "chasni_goku_spark_buff_fx1",
		bank = "chasni_goku_spark_buff_fx",
		build = "chasni_goku_spark_buff_fx",
		anim = "fall_loop",
	},
	{
		name = "chasni_goku_spark_buff_fx2",
		bank = "chasni_goku_spark_buff_fx",
		build = "chasni_goku_spark_buff_fx",
		anim = "fall_loop_front",
	},
	{
		name = "chasni_goku_water_buff_fx1",
		bank = "chasni_goku_water_buff_fx",
		build = "chasni_goku_water_buff_fx",
		anim = "fall_loop",
	},
	{
		name = "chasni_goku_water_buff_fx2",
		bank = "chasni_goku_water_buff_fx",
		build = "chasni_goku_water_buff_fx",
		anim = "fall_loop_front",
	},
	{
		name = "chasni_mud_buff_fx",
		bank = "chasni_mud_buff_fx",
		build = "chasni_mud_buff_fx",
		anim = "fall_loop",
	},
	{
		name = "chasni_stink_buff_fx",
		bank = "chasni_stink_buff_fx",
		build = "chasni_stink_buff_fx",
		anim = "fall_loop",
	},
	{
		name = "chasni_healed_buff_fx1",
		bank = "chasni_healed_buff_fx",
		build = "chasni_healed_buff_fx",
		anim = "upgrade_pre",
		animqueue = true,
		fn = function(inst)
			inst.Transform:SetScale(2,2,2)
			inst.AnimState:PushAnimation("upgrade_loop", false)
			inst.AnimState:PushAnimation("upgrade_post", false)
		end,
	},
	{
		name = "chasni_heat_buff_fx1",
		bank = "chasni_heat_buff_fx",
		build = "chasni_heat_buff_fx",
		anim = "falling",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_heat_buff_fx2",
		bank = "chasni_heat_buff_fx",
		build = "chasni_heat_buff_fx",
		anim = "landed",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_heat_ground_fx1",
		bank = "chasni_heat_ground_fx",
		build = "chasni_heat_ground_fx",
		anim = "heatfx_a",
		fn = function(inst) GroundOrientation(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_heat_ground_fx2",
		bank = "chasni_heat_ground_fx",
		build = "chasni_heat_ground_fx",
		anim = "heatfx_b",
		fn = function(inst) GroundOrientation(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_heat_ground_fx3",
		bank = "chasni_heat_ground_fx",
		build = "chasni_heat_ground_fx",
		anim = "heatfx_c",
		fn = function(inst) GroundOrientation(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_impact_bubble_fx",
		bank = "chasni_impact_bubble_fx",
		build = "chasni_impact_bubble_fx",
		anim = "loop",
	},
	{
		name = "chasni_impact_spiral_fx",
		bank = "chasni_impact_spiral_fx",
		build = "chasni_impact_spiral_fx",
		anim = "placer",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_impact_wortox_fx",
		bank = "chasni_impact_wortox_fx",
		build = "chasni_impact_wortox_fx",
		anim = "loop",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_laser_ring_buff_fx1",
		bank = "chasni_laser_ring_buff_fx",
		build = "chasni_laser_ring_buff_fx",
		anim = "on_pre",
		animqueue = true,
		fn = function(inst)
			inst.Transform:SetScale(2,2,2)
			inst.AnimState:PushAnimation("on", false)
			inst.AnimState:PushAnimation("on_pst", false)
		end,
	},
	{
		name = "chasni_lightning_ground_fx",
		bank = "chasni_lightning_ground_fx",
		build = "chasni_lightning_ground_fx",
		anim = "lightning",
		fn = function(inst) GroundOrientation(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_mud_armor_buff_fx1",
		bank = "chasni_mud_armor_buff_fx",
		build = "chasni_mud_armor_buff_fx",
		anim = "body",
	},
	{
		name = "chasni_mud_armor_buff_fx2",
		bank = "chasni_mud_armor_buff_fx",
		build = "chasni_mud_armor_buff_fx",
		anim = "head",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_odor_fx",
		bank = "chasni_odor_fx",
		build = "chasni_odor_fx",
		anim = "working_pre",
		animqueue = true,
		fn = function(inst)
			inst.Transform:SetScale(2,2,2)
			inst.AnimState:PushAnimation("working_loop", false)
			inst.AnimState:PushAnimation("working_pst", false)
		end,
	},
	{
		name = "chasni_orbit_fx1",
		bank = "chasni_orbit_fx",
		build = "chasni_orbit_fx",
		anim = "orbit",
		fn = function(inst) GroundOrientation(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_orbit_fx2",
		bank = "chasni_orbit_fx",
		build = "chasni_orbit_fx",
		anim = "orbit_grow",
		fn = function(inst) GroundOrientation(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_poison_bubble_fx",
		bank = "chasni_poison_bubble_fx",
		build = "chasni_poison_bubble_fx",
		anim = "bubble_forsound",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_projectile_glow",
		bank = "chasni_projectile_glow",
		build = "chasni_projectile_glow",
		anim = "loop",
	},
	{
		name = "chasni_projectile_hologram",
		bank = "chasni_projectile_hologram",
		build = "chasni_projectile_hologram",
		anim = "loop",
	},
	{
		name = "chasni_rage_fx",
		bank = "chasni_rage_fx",
		build = "chasni_rage_fx",
		anim = "rage_pre",
		animqueue = true,
		fn = function(inst)
			inst.Transform:SetScale(2,2,2)
			inst.AnimState:PushAnimation("rage_loop", false)
			inst.AnimState:PushAnimation("rage_pst", false)
		end,
	},
	{
		name = "chasni_sand_armor_buff_fx1",
		bank = "chasni_sand_armor_buff_fx",
		build = "chasni_sand_armor_buff_fx",
		anim = "start",
	},
	{
		name = "chasni_sand_armor_buff_fx2",
		bank = "chasni_sand_armor_buff_fx",
		build = "chasni_sand_armor_buff_fx",
		anim = "loop",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
					{
						name = "chasni_shield_hexagon_fx1",
						bank = "chasni_shield_hexagon_fx",
						build = "chasni_shield_hexagon_fx",
						anim = "working_loop",
						fn = function(inst) inst.Transform:SetScale(3,3,3)end,
					},
					{
						name = "chasni_shield_hexagon_fx2",
						bank = "chasni_shield_hexagon_fx",
						build = "chasni_shield_hexagon_fx",
						anim = "orb_idle",
						fn = function(inst) inst.Transform:SetScale(5,5,5)end,
					},
	{
		name = "chasni_sing_fx",
		bank = "chasni_sing_fx",
		build = "chasni_sing_fx",
		anim = "working_loop",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_sparkle_fx",
		bank = "chasni_sparkle_fx",
		build = "chasni_sparkle_fx",
		anim = "loop",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_spark_fx",
		bank = "chasni_spark_fx",
		build = "chasni_spark_fx",
		anim = "spark",
	},
	{
		name = "chasni_spark_ground_fx",
		bank = "chasni_spark_fx",
		build = "chasni_spark_fx",
		anim = "spark",
		fn = function(inst) GroundOrientation(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_wavesplash_fx",
		bank = "chasni_wavesplash_fx",
		build = "chasni_wavesplash_fx",
		anim = "working_loop",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_winding_fx",
		bank = "chasni_winding_fx",
		build = "chasni_winding_fx",
		anim = "working_loop",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	{
		name = "chasni_cannonball_splash_fx",
		bank = "chasni_cannonball_splash_fx",
		build = "chasni_cannonball_splash_fx",
		anim = "splash",
		fn = function(inst) inst.Transform:SetScale(2,2,2)end,
	},
	
	
	--region NEW CRABKINGS
	{
		name = "ckc_icestaffburst_fx",
		bank = "pensieve_ice_fx",
		build = "ice_burst_fx",
		anim = "ice_burst",
	},
	{
		name = "ckc_icestaffburst2_fx",
		bank = "deer_ice_burst",
		build = "ice_burst2_fx",
		anim = "loop",
	},
	{
		name = "ckc_firedebuff_fx",
		bank = "ckc_firedebuff",
		build = "ckc_firedebuff",
		anim = "loop",
		fn = GroundOrientation
	},
	{
		name = "ckc_waterdebuff_fx",
		bank = "ckc_waterdebuff",
		build = "ckc_waterdebuff",
		anim = "loop",
		fn = GroundOrientation
	},
	{
		name = "ckc_electricdebuff_fx",
		bank = "ckc_electricdebuff",
		build = "ckc_electricdebuff",
		anim = "loop",
		fn = GroundOrientation
	},
	{
		name = "ckc_icedebuff_fx",
		bank = "ckc_icedebuff",
		build = "ckc_icedebuff",
		anim = "loop",
		fn = GroundOrientation
	},
	{
		name = "chasni_lunar_crab_king_claw_fx",
		bank = "crab_claw",
		build = "chasni_lunar_crab_king_claw_fx_build",
		anim = "emerge",
	},
	{
		name = "chasni_shadow_crab_king_claw_fx",
		bank = "crab_claw",
		build = "chasni_shadow_crab_king_claw_fx_build",
		anim = "emerge",
	},
	{
		name = "chasni_ice_crab_king_claw_fx",
		bank = "crab_claw",
		build = "chasni_ice_crab_king_claw_fx_build",
		anim = "emerge",
	},
	{
		name = "chasni_fire_crab_king_claw_fx",
		bank = "crab_claw",
		build = "chasni_fire_crab_king_claw_fx_build",
		anim = "emerge",
	},
	{
		name = "chasni_water_crab_king_claw_fx",
		bank = "crab_claw",
		build = "chasni_water_crab_king_claw_fx_build",
		anim = "emerge",
	},
	{
		name = "chasni_electric_crab_king_claw_fx",
		bank = "crab_claw",
		build = "chasni_electric_crab_king_claw_fx_build",
		anim = "emerge",
	},
	{
		name = "cckproj_electric",
		bank = "lavaarena_arcane_orb",
		build = "lavaarena_arcane_orb",
		anim = "out",
	},
	{
		name = "cckproj_shadow",
		bank = "gooball_fx",
		build = "gooball_fx",
		anim = "blast",
		fn = function(inst)
			inst.Transform:SetScale(0.75,0.75,0.75)
		end,
	},
	{
		name = "cckproj_water",
		bank = "gooball_fx",
		build = "gooball_fx",
		anim = "blast",
		fn = function(inst)
			inst.Transform:SetScale(0.75,0.75,0.75)
			inst.AnimState:SetMultColour(0.2, 0.4, 1, 1)
		end,
	},
	{
		name = "cckproj_lunar",
		bank = "brilliance_projectile_fx",
		build = "brilliance_projectile_fx",
		anim = "blast1",
		anim = "blast1",
		fn = function(inst)
			inst.Transform:SetScale(0.85,0.85,0.85)
			inst.AnimState:SetMultColour(0.6, 1, 0.8, 1)
		end,
	},
	{
		name = "cckproj_shadow",
		bank = "brilliance_projectile_fx",
		build = "brilliance_projectile_fx",
		anim = "blast1",
		fn = function(inst)
			inst.Transform:SetScale(0.85,0.85,0.85)
			inst.AnimState:SetMultColour(0, 0, 0, 1)
		end,
	},
	--endregion
	--region STICKERS
	{
		name = "drawing_flower",
		bank = "chasni_drawing",
		build = "chasni_drawing",
		anim = "sparkle_graffiti_a",
		fn = function(inst)
			GroundOrientation(inst)
			inst.AnimState:PushAnimation("sparkle_graffiti_a", true)
			inst.Transform:SetScale(2,2,2)
			inst:DoTaskInTime(10, inst.Remove)
			inst:RemoveEventCallback("animover", inst.Remove)
		end,
	},
	{
		name = "drawing_love",
		bank = "chasni_drawing",
		build = "chasni_drawing",
		anim = "sparkle_graffiti_b",
		fn = function(inst)
			GroundOrientation(inst)
			inst.AnimState:PushAnimation("sparkle_graffiti_b", true)
			inst.Transform:SetScale(2,2,2)
			inst:DoTaskInTime(10, inst.Remove)
			inst:RemoveEventCallback("animover", inst.Remove)
		end,
	},
	{
		name = "drawing_smile",
		bank = "chasni_drawing",
		build = "chasni_drawing",
		anim = "sparkle_graffiti_c",
		fn = function(inst)
			GroundOrientation(inst)
			inst.AnimState:PushAnimation("sparkle_graffiti_c", true)
			inst.Transform:SetScale(2,2,2)
			inst:DoTaskInTime(10, inst.Remove)
			inst:RemoveEventCallback("animover", inst.Remove)
		end,
	},
	{
		name = "drawing_thumb",
		bank = "chasni_drawing",
		build = "chasni_drawing",
		anim = "sparkle_graffiti_d",
		fn = function(inst)
			GroundOrientation(inst)
			inst.AnimState:PushAnimation("sparkle_graffiti_d", true)
			inst.Transform:SetScale(2,2,2)
			inst:DoTaskInTime(10, inst.Remove)
			inst:RemoveEventCallback("animover", inst.Remove)
		end,
	},
	{
		name = "drawing_star",
		bank = "chasni_drawing",
		build = "chasni_drawing",
		anim = "sparkle_graffiti_e",
		fn = function(inst)
			GroundOrientation(inst)
			inst.AnimState:PushAnimation("sparkle_graffiti_e", true)
			inst.Transform:SetScale(2,2,2)
			inst:DoTaskInTime(10, inst.Remove)
			inst:RemoveEventCallback("animover", inst.Remove)
		end,
	},
	{
		name = "drawing_balloon",
		bank = "chasni_drawing",
		build = "chasni_drawing",
		anim = "sparkle_graffiti_f",
		fn = function(inst)
			GroundOrientation(inst)
			inst.AnimState:PushAnimation("sparkle_graffiti_f", true)
			inst.Transform:SetScale(2,2,2)
			inst:DoTaskInTime(10, inst.Remove)
			inst:RemoveEventCallback("animover", inst.Remove)
		end,
	},
	{
		name = "drawing_bubble",
		bank = "chasni_drawing",
		build = "chasni_drawing",
		anim = "sparkle_graffiti_g",
		fn = function(inst)
			GroundOrientation(inst)
			inst.AnimState:PushAnimation("sparkle_graffiti_g", true)
			inst.Transform:SetScale(2,2,2)
			inst:DoTaskInTime(10, inst.Remove)
			inst:RemoveEventCallback("animover", inst.Remove)
		end,
	},
	{
		name = "drawing_egg",
		bank = "chasni_drawing",
		build = "chasni_drawing",
		anim = "sparkle_graffiti_h",
		fn = function(inst)
			GroundOrientation(inst)
			inst.AnimState:PushAnimation("sparkle_graffiti_h", true)
			inst.Transform:SetScale(2,2,2)
			inst:DoTaskInTime(10, inst.Remove)
			inst:RemoveEventCallback("animover", inst.Remove)
		end,
	},
	{
		name = "drawing_rocket",
		bank = "chasni_drawing",
		build = "chasni_drawing",
		anim = "sparkle_graffiti_rocket",
		fn = function(inst)
			GroundOrientation(inst)
			inst.AnimState:PushAnimation("sparkle_graffiti_rocket", true)
			inst.Transform:SetScale(2,2,2)
			inst:DoTaskInTime(10, inst.Remove)
			inst:RemoveEventCallback("animover", inst.Remove)
		end,
	},
	{
		name = "drawing_plane",
		bank = "chasni_drawing",
		build = "chasni_drawing",
		anim = "sparkle_graffiti_paperplane",
		fn = function(inst)
			GroundOrientation(inst)
			inst.AnimState:PushAnimation("sparkle_graffiti_paperplane", true)
			inst.Transform:SetScale(2,2,2)
			inst:DoTaskInTime(10, inst.Remove)
			inst:RemoveEventCallback("animover", inst.Remove)
		end,
	},
	{
		name = "drawing_plant",
		bank = "chasni_drawing",
		build = "chasni_drawing",
		anim = "sparkle_graffiti_plant",
		fn = function(inst)
			GroundOrientation(inst)
			inst.AnimState:PushAnimation("sparkle_graffiti_plant", true)
			inst.Transform:SetScale(2,2,2)
			inst:DoTaskInTime(10, inst.Remove)
			inst:RemoveEventCallback("animover", inst.Remove)
		end,
	},
	{
		name = "drawing_cactus",
		bank = "chasni_drawing",
		build = "chasni_drawing",
		anim = "sparkle_graffiti_plantpot",
		fn = function(inst)
			GroundOrientation(inst)
			inst.AnimState:PushAnimation("sparkle_graffiti_plantpot", true)
			inst.Transform:SetScale(2,2,2)
			inst:DoTaskInTime(10, inst.Remove)
			inst:RemoveEventCallback("animover", inst.Remove)
		end,
	},
	{
		name = "drawing_merm",
		bank = "chasni_drawing",
		build = "chasni_drawing",
		anim = "sparkle_graffiti_mermaid",
		fn = function(inst)
			GroundOrientation(inst)
			inst.AnimState:PushAnimation("sparkle_graffiti_mermaid", true)
			inst.Transform:SetScale(2,2,2)
			inst:DoTaskInTime(10, inst.Remove)
			inst:RemoveEventCallback("animover", inst.Remove)
		end,
	},
	{
		name = "drawing_unicorn",
		bank = "chasni_drawing",
		build = "chasni_drawing",
		anim = "sparkle_graffiti_unicorn",
		fn = function(inst)
			GroundOrientation(inst)
			inst.AnimState:PushAnimation("sparkle_graffiti_unicorn", true)
			inst.Transform:SetScale(2,2,2)
			inst:DoTaskInTime(10, inst.Remove)
			inst:RemoveEventCallback("animover", inst.Remove)
		end,
	},
	--endregion
}

-- slingshotammofx
local shot_types = {"block", "bomb", "egg", "lunar", "pills", "shadow", "spike", "teleport"}
for _, shot_type in ipairs(shot_types) do
	table.insert(FX, {
		name = "chasni_slingshotammo_hitfx_"..shot_type,
		bank = "slingshotammo",
		build = "chasni_slingshotammo",
		anim = "used",
		sound = "dontstarve/characters/walter/slingshot/rock",
		fn = function(inst)
			inst.AnimState:OverrideSymbol("rock", "chasni_slingshotammo", shot_type)
			inst.AnimState:SetFinalOffset(3)
		end,
	})
end

if GLOBAL.package.loaded.fx then
	for k,v in pairs(FX) do
		table.insert(GLOBAL.package.loaded.fx, v)
		table.insert(Assets, Asset("ANIM", "anim/".. v.build ..".zip"))
	end
end
