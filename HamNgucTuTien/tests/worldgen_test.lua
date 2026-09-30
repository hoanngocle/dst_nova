test('U16 codec preserves values and rejects corrupt maps', function()
    local codec = require('hn_dungeon/map_codec')
    local encoded = codec.EncodeU16({0,1,255,256,65535})
    -- Independently encoded with Python base64 + struct.pack('<5H', ...).
    assert(encoded == 'VlJTTgABAAAAAAABAP8AAAH//w==')
    local values = codec.DecodeU16(encoded)
    for i,v in ipairs({0,1,255,256,65535}) do assert(values[i]==v) end
    assert(not pcall(codec.EncodeU16, {-1}))
    assert(not pcall(codec.EncodeU16, {65536}))
    assert(not pcall(codec.DecodeU16, 'invalid'))
    assert(not pcall(codec.DecodeU16, 'VlJTTgABAAAAAA=='))
end)

test('only authoritative Forest owns dungeon', function()
    local authority = require('hn_dungeon/authority')
    local w={ismastersim=true,ismastershard=true,HasTag=function(_,t) return t=='forest' end}
    assert(authority.IsAuthority(w))
    w.ismastershard=false; assert(not authority.IsAuthority(w))
    w.ismastershard=true; w.ismastersim=false; assert(not authority.IsAuthority(w))
    w.ismastersim=true; w.HasTag=function() return false end; assert(not authority.IsAuthority(w))
end)

local function fixture(fail_second)
    local codec=require('hn_dungeon/map_codec')
    local base={map={width=2,height=2,tiles=codec.EncodeU16({1,1,1,1}),nodeidtilemap=codec.EncodeU16({1,1,1,1}),
        topology={nodes={{x=0,y=4,cent={0,4},poly={{0,4},{4,8}}}},ids={'mainland'}},roads={{{0.5},{0,4},{4,8}}}},
        ents={portal={{x=0,z=4}}}}
    local methods={}
    function methods:ResetAll() end
    function methods:ConvertToTileMap(size) self.size=size end
    function methods:SetTile(x,y,t) self.tiles[self.size*y+x+1]=t end
    function methods:SetTileNodeId() end
    function methods:GetEncodedMap() return codec.EncodeU16(self.tiles) end
    local worldsim=setmetatable({tiles={}}, {__index=methods})
    local original_convert,original_encoded=methods.ConvertToTileMap,methods.GetEncodedMap
    local count=0
    local forest={Generate=function(name)
        count=count+1
        if count==1 then return base end
        if fail_second then error('engine generation failed') end
        worldsim:ConvertToTileMap(2)
        return {map={tiles=worldsim:GetEncodedMap(),nav='new_nav',adj='new_adj'}}
    end}
    local g={TILE_SCALE=4,WORLD_TILES={IMPASSABLE=0,HN_ARENA_LAVA=7},WorldSim=worldsim}
    g.require=function(name)
        if name=='map/forest_map' then return forest end
        if name=='hn_dungeon/blueprints' then return {Test={'WWW','WEW','WWW'}} end
        return require(name)
    end
    local api={GLOBAL=g,AddTile=function() error('tile already registered') end}
    return api,forest,base,methods,original_convert,original_encoded
end

test('Forest expansion keeps terrain entities roads topology aligned and restores hooks',function()
    local api,forest,base,methods,oc,oe=fixture(false)
    require('hn_dungeon/worldgen').Install(api)
    local generated=forest.Generate('forest')
    -- 2 original + 16 gap + (3 blueprint + 28 margins) = 49 tiles.
    assert(generated.map.width==49 and generated.map.height==49)
    assert(base.ents.portal[1].x==-94 and base.ents.portal[1].z==-90)
    assert(base.map.topology.nodes[1].cent[1]==-94)
    assert(base.map.roads[1][1][1]==0.5 and base.map.roads[1][2][2]==-90)
    assert(#base.ents.hn_dungeon_exit==1)
    assert(base.map.nav=='new_nav' and base.map.adj=='new_adj')
    local tiles=require('hn_dungeon/map_codec').DecodeU16(base.map.tiles)
    assert(#tiles==49*49 and tiles[1]==1 and tiles[3]==0)
    assert(methods.ConvertToTileMap==oc and methods.GetEncodedMap==oe)
end)

test('Caves are unchanged',function()
    local api,forest,base=fixture(false)
    require('hn_dungeon/worldgen').Install(api)
    assert(forest.Generate('cave')==base and base.map.width==2)
    assert(base.ents.hn_dungeon_exit==nil)
end)

test('failed engine generation restores WorldSim methods',function()
    local api,forest,base,methods,oc,oe=fixture(true)
    require('hn_dungeon/worldgen').Install(api)
    local ok,err=pcall(forest.Generate,'forest')
    assert(not ok and tostring(err):find('engine generation failed'))
    assert(methods.ConvertToTileMap==oc and methods.GetEncodedMap==oe)
end)

test('every shipped blueprint has exactly one exit and consistent rows', function()
    for name,layout in pairs(require('hn_dungeon/blueprints')) do
        local exits=0
        for _,row in ipairs(layout) do
            assert(#row==#layout[1], name..': uneven rows')
            local _,n=row:gsub('E',''); exits=exits+n
        end
        assert(exits==1,name..': invalid exits')
    end
end)
