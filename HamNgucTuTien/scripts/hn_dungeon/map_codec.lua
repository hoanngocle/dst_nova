local base64 = require("hn_dungeon/base64")
local MAP_HEADER_PREFIX = "VlJTTgABAAAA"
local MAP_HEADER_RAW = base64.decode(MAP_HEADER_PREFIX)
local MAP_HEADER_BYTES = #MAP_HEADER_RAW
local MAP_DATA_START_BYTE = MAP_HEADER_BYTES + 1

if MAP_HEADER_BYTES ~= 9 then
    error("Ham Nguc: unexpected encoded-map header length", 0)
end

local function EncodeU16(values)
    local chunks = {}
    for i = 1, #values do
        local value = values[i] or 0
        if type(value) ~= "number" or value < 0 or value > 0xFFFF
            or value ~= math.floor(value) then
            error("Ham Nguc: node id is outside the U16 range", 0)
        end
        chunks[#chunks + 1] = string.char(value % 256, math.floor(value / 256))
    end
    return MAP_HEADER_PREFIX .. base64.encode(table.concat(chunks))
end

local function DecodeU16(encoded)
    if encoded == nil then
        return {}
    end

    if encoded:sub(1, #MAP_HEADER_PREFIX) ~= MAP_HEADER_PREFIX then
        error("Ham Nguc: encoded map is missing the expected prefix", 0)
    end
    local decoded = base64.decode(encoded)
    if decoded:sub(1, MAP_HEADER_BYTES) ~= MAP_HEADER_RAW then
        error("Ham Nguc: encoded map has an unexpected header", 0)
    end

    local payload_bytes = #decoded - MAP_HEADER_BYTES
    if payload_bytes % 2 ~= 0 then
        error("Ham Nguc: encoded U16 map payload has an odd byte count", 0)
    end

    local values = {}
    for i = MAP_DATA_START_BYTE, #decoded, 2 do
        local lo = decoded:byte(i)
        local hi = decoded:byte(i + 1)
        values[#values + 1] = lo + hi * 0x100
    end
    return values
end


return {EncodeU16=EncodeU16, DecodeU16=DecodeU16}
