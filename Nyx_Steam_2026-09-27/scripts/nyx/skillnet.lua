local json=require('json')
local M={}
function M.Install(inst)
    inst._nyx_snapshot=net_string(inst.GUID,'nyx.snapshot','nyx_snapshotdirty')
    inst._nyx_appearance=net_string(inst.GUID,'nyx.appearance','nyx_appearancedirty')
    inst._nyx_eye=net_bool(inst.GUID,'nyx.eye','nyx_eyedirty')
    inst._nyx_wings=net_bool(inst.GUID,'nyx.wings','nyx_wingsdirty')
end
function M.Read(inst)
    if not inst._nyx_snapshot then return {ready=false} end
    local ok,s=pcall(json.decode,inst._nyx_snapshot:value())
    return ok and type(s)=='table' and s or {ready=false}
end
function M.Publish(inst,s)
    local text=json.encode(s)
    if text~=inst._nyx_last_snapshot then inst._nyx_last_snapshot=text; inst._nyx_snapshot:set(text) end
end
return M
