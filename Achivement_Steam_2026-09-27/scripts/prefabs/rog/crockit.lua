local assets =
{
    Asset("ANIM", "anim/crockit.zip"),
    Asset("ATLAS", "images/inventoryimages/crockit.xml"),
}

local prefabs =
{
    "gridplacer",
    "dock_damage",
    "dock_kit",
}

local function CLIENT_CanDeployDockKit(inst, pt, mouseover, deployer, rotation)
    local tile = TheWorld.Map:GetTileAtPoint(pt.x, 0, pt.z)
    if (TileGroupManager:IsOceanTile(tile)) then
        local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(pt.x, 0, pt.z)
        local found_adjacent_safetile = false
        for x_off = -1, 1, 1 do
            for y_off = -1, 1, 1 do
                if (x_off ~= 0 or y_off ~= 0) and IsLandTile(TheWorld.Map:GetTile(tx + x_off, ty + y_off)) then
                    found_adjacent_safetile = true
                    break
                end
            end
            if found_adjacent_safetile then break end
        end

        if found_adjacent_safetile then
            local center_pt = Vector3(TheWorld.Map:GetTileCenterPoint(tx, ty))
            return found_adjacent_safetile and TheWorld.Map:CanDeployDockAtPoint(center_pt, inst, mouseover)
        end
    end

    return false
end

local function fn()
    local inst = Prefabs["dock_kit"].fn()
    inst.AnimState:SetBuild("crockit")

    inst._custom_candeploy_fn = CLIENT_CanDeployDockKit

    if not TheWorld.ismastersim then
        return inst
    end

    if inst.components.inventoryitem then
        inst.components.inventoryitem.imagename = "crockit"
        inst.components.inventoryitem.atlasname = "images/inventoryimages/crockit.xml"
    end

    return inst
end

return Prefab("crockit", fn, assets, prefabs)