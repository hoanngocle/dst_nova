return CreatePrefabSkin('nyx_none',{
    base_prefab='nyx',build_name_override='eva_purple',type='base',rarity='Character',
    skip_item_gen=true,skip_giftable_gen=true,skin_tags={'BASE','nyx'},
    skins={normal_skin='eva_purple',ghost_skin='ghost_eva_build'},
    assets={Asset('ANIM','anim/nyx_purple.zip'),Asset('ANIM','anim/nyx_ghost.zip')},
})
