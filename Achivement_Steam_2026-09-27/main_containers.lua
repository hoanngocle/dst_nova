GLOBAL.setmetatable(env,{__index=function(_,k) return GLOBAL.rawget(GLOBAL,k) end})

local containers = require "containers"
local containers_widgetsetup_base = containers.widgetsetup
require "functions/helperfunctions"

local params = {}
function containers.widgetsetup(container, prefab, data, ...)
    local t = params[prefab or container.inst.prefab]
    if t then
        for k, v in pairs(t) do
            container[k] = v
        end
        container:SetNumSlots(container.widget.slotpos and #container.widget.slotpos or 0)
    else
        containers_widgetsetup_base(container, prefab, data, ...)
    end
end
--------------------------------------------------------------------------
--[[ chest ]]
--------------------------------------------------------------------------
if not chasni_getperkexcludeconfig("expertwinona1") then
    params.chasni_pugalisk_trapdoor =
    {
        widget =
        {
            slotpos = {},
            animbank = "ui_largechest_5x5",
            animbuild = "ui_largechest_5x5",
            pos = GLOBAL.Vector3(0, 200, 0),
            side_align_tip = 160,
        },
        type = "chest",
    }
    for y = 3, -1, -1 do for x = -1, 3 do table.insert(params.chasni_pugalisk_trapdoor.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0)) end end

    params.crafterchest =
    {
        widget =
        {
            slotpos = {},
            animbank = "ui_largechest_5x5",
            animbuild = "ui_largechest_5x5",
            pos = GLOBAL.Vector3(0, 200, 0),
            side_align_tip = 160,
        },
        type = "chest",
    }
    for y = 3, -1, -1 do for x = -1, 3 do table.insert(params.crafterchest.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0)) end end
end
if not chasni_getperkexcludeconfig("expertworm1") then
    params.bramblechest =
    {
        widget =
        {
            slotpos =
            {
                Vector3(-37.5, 32 + 4, 0),
                Vector3(37.5, 32 + 4, 0),
                Vector3(-37.5, -(32 + 4), 0),
                Vector3(37.5, -(32 + 4), 0),
            },
            animbank = "ui_chest_2x2",
            animbuild = "ui_chest_2x2",
            pos = GLOBAL.Vector3(0, 200, 0),
            side_align_tip = 120,
        },
        type = "chest",
    }
end
if not chasni_getperkexcludeconfig("bosshunting") then
    params.upgraded_treasurechest =
    {
        widget =
        {
            slotpos = {},
            animbank = "ui_largechest_5x5",
            animbuild = "ui_largechest_5x5",
            pos = GLOBAL.Vector3(0, 200, 0),
            side_align_tip = 160,
        },
        type = "chest",
    }
    for y = 3, -1, -1 do for x = -1, 3 do table.insert(params.upgraded_treasurechest.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0)) end end

    params.upgraded_icebox =
    {
        widget =
        {
            slotpos = {},
            animbank = "ui_largechest_5x5",
            animbuild = "ui_largechest_5x5",
            pos = GLOBAL.Vector3(0, 200, 0),
            side_align_tip = 160,
        },
        type = "chest",
    }
    for y = 3, -1, -1 do for x = -1, 3 do table.insert(params.upgraded_icebox.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0)) end end
    function params.upgraded_icebox.itemtestfn(container, item, slot)
        if item:HasTag("icebox_valid") then
            return true
        end

        if not (item:HasTag("fresh") or item:HasTag("stale") or item:HasTag("spoiled")) then
            return false
        end

        if item:HasTag("smallcreature") then
            return false
        end

        for k, v in pairs(FOODTYPE) do
            if item:HasTag("edible_"..v) then
                return true
            end
        end

        return false
    end
end
--------------------------------------------------------------------------
--[[ backpack ]]
--------------------------------------------------------------------------
if not chasni_getperkexcludeconfig("expertwicker3") then
    params.bookpack =
    {
        widget =
        {
            slotpos = {},
            animbank = "ui_krampusbag_2x8",
            animbuild = "ui_krampusbag_2x8",
            pos = Vector3(-5, -120, 0),
        },
        issidewidget = true,
        type = "pack",
    }
    function params.bookpack.itemtestfn(container, item, slot)
        return item:HasTag("book") or item:HasTag("bookcabinet_item")
    end
end
if not chasni_getperkexcludeconfig("expertwarly3") then
    params.chefpackred =
    {
        widget =
        {
            slotpos = {},
            animbank = "ui_krampusbag_2x8",
            animbuild = "ui_krampusbag_2x8",
            pos = Vector3(-5, -120, 0),
        },
        issidewidget = true,
        type = "pack",
    }
    function params.chefpackred.itemtestfn(container, item, slot)
        return item:HasTag("preparedfood")
    end
end
if not chasni_getperkexcludeconfig("expertwanda1") then
    params.watchcase =
    {
        widget =
        {
            slotpos = {},
            animbank = "ui_krampusbag_2x8",
            animbuild = "ui_krampusbag_2x8",
            pos = Vector3(0, -130, 0),
        },
        type = "side_inv_behind",
        openlimit = 1,
    }
    function params.watchcase.itemtestfn(container, item, slot)
        return item.prefab == "pocketwatch_dismantler" or item:HasTag("pocketwatch") or item.prefab == "pocketwatch_parts"
    end
end
if not chasni_getperkexcludeconfig("expertwalter3") then
    params.campingbag =
    {
        widget =
        {
            slotpos = {},
            animbank = "ui_krampusbag_2x8",
            animbuild = "ui_krampusbag_2x8",
            pos = Vector3(-5, -120, 0),
        },
        issidewidget = true,
        type = "pack",
    }
    for y = 0, 6 do
        table.insert(params.bookpack.widget.slotpos, Vector3(-162, -75 * y + 240, 0))
        table.insert(params.bookpack.widget.slotpos, Vector3(-162 + 75, -75 * y + 240, 0))
        table.insert(params.chefpackred.widget.slotpos, Vector3(-162, -75 * y + 240, 0))
        table.insert(params.chefpackred.widget.slotpos, Vector3(-162 + 75, -75 * y + 240, 0))
        table.insert(params.watchcase.widget.slotpos, Vector3(-162, -75 * y + 240, 0))
        table.insert(params.watchcase.widget.slotpos, Vector3(-162 + 75, -75 * y + 240, 0))
        table.insert(params.campingbag.widget.slotpos, Vector3(-162, -75 * y + 240, 0))
        table.insert(params.campingbag.widget.slotpos, Vector3(-162 + 75, -75 * y + 240, 0))
    end
end
if not chasni_getperkexcludeconfig("bosshunting") then
    params.rottenpack =
    {
        widget =
        {
            slotpos =
            {
                Vector3(-37.5, 32 + 4, 0),
                Vector3(37.5, 32 + 4, 0),
                Vector3(-37.5, -(32 + 4), 0),
                Vector3(37.5, -(32 + 4), 0),
            },
            animbank = "ui_chest_2x2",
            animbuild = "ui_chest_2x2",
            pos = Vector3(-5, -120, 0),
        },
        issidewidget = true,
        type = "pack",
    }

    params.crocpack =
    {
        widget = {
            slotpos = {},
            animbank = "ui_piggyback_2x6",
            animbuild = "ui_piggyback_2x6",
            pos = Vector3(-5, -120, 0),
        },
        issidewidget = true,
        type = "pack",
    }
    for y = 0, 5 do
        table.insert(params.crocpack.widget.slotpos, Vector3(-162, -75 * y + 170, 0))
        table.insert(params.crocpack.widget.slotpos, Vector3(-162 + 75, -75 * y + 170, 0))
    end
end
--------------------------------------------------------------------------
--[[ hover top ]]
--------------------------------------------------------------------------
if not chasni_getperkexcludeconfig("bosshunting") then
    params.armorgold =
    {
        widget =
        {
            slotpos = { Vector3(0,   32 + 4,  0), },
            animbank = "ui_cookpot_1x2",
            animbuild = "ui_cookpot_1x2",
            pos = Vector3(55, 15, 0),
        },
        usespecificslotsforitems = true,
        type = "hand_inv",
        excludefromcrafting = true,
    }
    function params.armorgold.itemtestfn(container, item, slot)
        return item.prefab == "goldnugget"
    end

    params.watchpaint =
    {
        widget =
        {
            slotpos = { Vector3(0,   32 + 4,  0), },
            animbank = "ui_cookpot_1x2",
            animbuild = "ui_cookpot_1x2",
            pos = Vector3(0, 15, 0),
        },
        usespecificslotsforitems = true,
        type = "hand_inv",
        excludefromcrafting = true,
    }
    function params.watchpaint.itemtestfn(container, item, slot)
        return item.prefab == "pocketwatch_recall" or item.prefab == "pocketwatch_portal"
    end
end

if not chasni_getperkexcludeconfig("expertwalter4") then
    params.chasni_slingshot_splitshot =
    {
        widget =
        {
            slotpos =
            {
                Vector3(0,   32 + 4,  0),
            },
            slotbg =
            {
                { image = "slingshot_ammo_slot.tex" },
            },
            animbank = "ui_cookpot_1x2",
            animbuild = "ui_cookpot_1x2",
            pos = Vector3(0, 15, 0),
        },
        usespecificslotsforitems = true,
        type = "hand_inv",
        excludefromcrafting = true,
    }
    function params.chasni_slingshot_splitshot.itemtestfn(container, item, slot)
        if item.REQUIRED_SKILL then
            local owner
            if TheWorld.ismastersim then
                owner = container.inst.components.container:GetOpeners()[1]
            elseif ThePlayer and container:IsOpenedBy(ThePlayer) then
                owner = ThePlayer
            end
            if owner and not (owner.components.skilltreeupdater and owner.components.skilltreeupdater:IsActivated(item.REQUIRED_SKILL)) then
                return false
            end
        end
        return item:HasTag("slingshotammo")
    end
    params.chasni_slingshot_gereminate = deepcopy(params.chasni_slingshot_splitshot)

    params.chasni_slingshotex_splitshot = deepcopy(params.chasni_slingshot_splitshot)
    params.chasni_slingshotex_splitshot.widget.animbank = "ui_slingshot_wagpunk_0"
    params.chasni_slingshotex_splitshot.widget.animbuild = "ui_slingshot_wagpunk_0"
    params.chasni_slingshot999ex_splitshot = deepcopy(params.chasni_slingshotex_splitshot)
    params.chasni_slingshot999ex_splitshot.widget.animbank = "ui_slingshot_wagpunk"
    params.chasni_slingshot999ex_splitshot.widget.animbuild = "ui_slingshot_wagpunk"

    params.chasni_slingshotex_gereminate = deepcopy(params.chasni_slingshot_gereminate)
    params.chasni_slingshotex_gereminate.widget.animbank = "ui_slingshot_wagpunk_0"
    params.chasni_slingshotex_gereminate.widget.animbuild = "ui_slingshot_wagpunk_0"
    params.chasni_slingshot999ex_gereminate = deepcopy(params.chasni_slingshotex_gereminate)
    params.chasni_slingshot999ex_gereminate.widget.animbank = "ui_slingshot_wagpunk"
    params.chasni_slingshot999ex_gereminate.widget.animbuild = "ui_slingshot_wagpunk"

    params.chasni_slingshot2_splitshot =
    {
        widget =
        {
            slotpos =
            {
                --reversed so bottom is slot 1
                Vector3(0, 32 + 4, 0),
                Vector3(0, 64 + 32 + 8 + 4, 0),
            },
            slotbg =
            {
                { image = "slingshot_ammo_slot.tex" },
                { image = "slingshot_ammo_slot.tex" },
            },
            animbank = "ui_slingshot_bone",
            animbuild = "ui_slingshot_bone",
            pos = Vector3(0, 15, 0),
        },
        type = "hand_inv",
        excludefromcrafting = true,
    }
    params.chasni_slingshot2_gereminate = deepcopy(params.chasni_slingshot2_splitshot)

    params.chasni_slingshot2ex_splitshot = deepcopy(params.chasni_slingshot2_splitshot)
    params.chasni_slingshot2ex_splitshot.widget.animbank = "ui_slingshot_gems"
    params.chasni_slingshot2ex_splitshot.widget.animbuild = "ui_slingshot_gems"
    params.chasni_slingshot2ex_splitshot.widget.slotpos[2].y = 64 + 32 + 8 + 4 + 32
    params.chasni_slingshotex_splitshot.itemtestfn = params.chasni_slingshot_splitshot.itemtestfn
    params.chasni_slingshot999ex_splitshot.itemtestfn = params.chasni_slingshot_splitshot.itemtestfn
    params.chasni_slingshot2_splitshot.itemtestfn = params.chasni_slingshot_splitshot.itemtestfn
    params.chasni_slingshot2ex_splitshot.itemtestfn = params.chasni_slingshot_splitshot.itemtestfn

    params.chasni_slingshot2ex_gereminate = deepcopy(params.chasni_slingshot2_gereminate)
    params.chasni_slingshot2ex_gereminate.widget.animbank = "ui_slingshot_gems"
    params.chasni_slingshot2ex_gereminate.widget.animbuild = "ui_slingshot_gems"
    params.chasni_slingshot2ex_gereminate.widget.slotpos[2].y = 64 + 32 + 8 + 4 + 32
    params.chasni_slingshotex_gereminate.itemtestfn = params.chasni_slingshot_gereminate.itemtestfn
    params.chasni_slingshot999ex_gereminate.itemtestfn = params.chasni_slingshot_gereminate.itemtestfn
    params.chasni_slingshot2_gereminate.itemtestfn = params.chasni_slingshot_gereminate.itemtestfn
    params.chasni_slingshot2ex_gereminate.itemtestfn = params.chasni_slingshot_gereminate.itemtestfn
end

if not chasni_getperkexcludeconfig("trinketowner") then
    params.trinketslot =
    {
        widget =
        {
            slotpos = { Vector3(0, -14, 0), },
            animbank = "ui_chasni_trinket_1x1",
            animbuild = "ui_chasni_trinket_1x1",
            pos = Vector3(-1194, 1070, 0),
            slotbg =
            {
                { image = "ui_chasni_trinket_bg.tex", atlas = "images/hud/main/ui_chasni_trinket_bg.xml" },
            },
        },
        usespecificslotsforitems = true,
        type = "side_inv",
        excludefromcrafting = true,
        lowpriorityselection = true,
    }
    function params.trinketslot.itemtestfn(container, item, slot)
        return item.prefab:find("trinket", 1, true) ~= nil or cz_trinkets.modded_trinkets[item.prefab]
    end
end

--------------------------------------------------------------------------
--[[ hover right ]]
--------------------------------------------------------------------------
if not chasni_getperkexcludeconfig("expertwathg2") then
    params.songfolder =
    {
        widget =
        {
            slotpos = {},
            animbank = "ui_backpack_2x4",
            animbuild = "ui_backpack_2x4",
            pos = Vector3(0, -80, 0),
        },
        type = "side_inv_behind",
        openlimit = 1,
    }
    for y = 0, 3 do
        table.insert(params.songfolder.widget.slotpos, Vector3(-162, -75 * y + 114, 0))
        table.insert(params.songfolder.widget.slotpos, Vector3(-162 + 75, -75 * y + 114, 0))
    end
    if not _G.INTEGRATEDBACKPACK_CONFIG then
        params.watchcase.widget.pos = Vector3(-150, -130, 0)
        params.songfolder.widget.pos = Vector3(-150, -80, 0)
    end

    function params.songfolder.itemtestfn(container, item, slot)
        return item:HasTag("battlesong")
    end
end

--------------------------------------------------------------------------
--[[ cookpot ]]
--------------------------------------------------------------------------
if not chasni_getperkexcludeconfig("expertwarly4") then
    params.chasni_portablegriller =
    {
        widget =
        {
            slotpos =
            {
                Vector3(-36, 64 + 32 + 8 + 4, 0),
                Vector3(-36, 32 + 4, 0),
                Vector3(-36, -(32 + 4), 0),
                Vector3(-36, -(64 + 32 + 8 + 4), 0),
                Vector3(36, 64 + 32 + 8 + 4, 0),
                Vector3(36, 32 + 4, 0),
                Vector3(36, -(32 + 4), 0),
                Vector3(36, -(64 + 32 + 8 + 4), 0),
            },
            animbank = "ui_cookpot_2x4",
            animbuild = "ui_cookpot_2x4",
            pos = Vector3(200, 0, 0),
            side_align_tip = 100,
            buttoninfo =
            {
                text = STRINGS.ACTIONS.COOK,
                position = Vector3(0, -165, 0),
            }
        },
        acceptsstacks = false,
        type = "cooker",
    }

    function params.chasni_portablegriller.itemtestfn(container, item, slot)
        return not container.inst:HasTag("burnt")
    end

    function params.chasni_portablegriller.widget.buttoninfo.fn(inst, doer)
        if inst.components.container then
            BufferedAction(doer, inst, ACTIONS.COOK):Do()
        elseif inst.replica.container and not inst.replica.container:IsBusy() then
            SendRPCToServer(RPC.DoWidgetButtonAction, ACTIONS.COOK.code, inst, ACTIONS.COOK.mod_name)
        end
    end

    function params.chasni_portablegriller.widget.buttoninfo.validfn(inst)
        return inst.replica.container and not inst.replica.container:IsEmpty()
    end
end

--------------------------------------------------------------------------
--[[ RULES ]]
--------------------------------------------------------------------------
for k, v in pairs(params) do
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos and #v.widget.slotpos or 0)
end
