--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Tools in relation with the world and the map.

]]--
--[[ ================================================ ]]--

---requirements
local WorldTools = {}


--[[ ================================================ ]]--
--- IDENTIFICATION ---
--[[ ================================================ ]]--

---Retrieves the room ID based on its coordinates x,y,z.
---@param roomDef RoomDef
---@return string
WorldTools.GetRoomID = function(roomDef)
    return roomDef:getX().."x"..roomDef:getY().."x"..roomDef:getZ()
end

---Used to get a persistent identification coordinates of a building.
---@param buildingDef BuildingDef
---@return integer
---@return integer
---@return integer
WorldTools.getBuildingInfo = function(buildingDef)
    -- get a X and Y coordinate
    local x_bID = buildingDef:getX()
    local y_bID = buildingDef:getY()

    -- get a Z coordinate
    local firstRoom = buildingDef:getFirstRoom()
    local z_bID = firstRoom and firstRoom:getZ() or 0

    return x_bID,y_bID,z_bID
end

---Used to get a persistent identification of a building.
---@param buildingDef BuildingDef
---@return string
WorldTools.getBuildingID = function(buildingDef)
    -- get a X and Y coordinate
    local x_bID = buildingDef:getX()
    local y_bID = buildingDef:getY()

    -- get a Z coordinate
    local firstRoom = buildingDef:getFirstRoom()
    local z_bID = firstRoom and firstRoom:getZ() or 0

    return x_bID.."x"..y_bID.."x"..z_bID
end



--[[ ================================================ ]]--
--- SPRITES PROPERTIES ---
--[[ ================================================ ]]--

WorldTools.IsoObjectType = {
    -- ["curtainE"] = "curtainE",
    -- ["curtainN"] = "curtainN",
    -- ["curtainS"] = "curtainS",
    -- ["curtainW"] = "curtainW",
    -- ["doorFrN"] = "doorFrN",
    -- ["doorFrW"] = "doorFrW",
    -- ["doorN"] = "doorN",
    -- ["doorW"] = "doorW",
    -- ["isMoveAbleObject"] = "isMoveAbleObject",
    -- ["jukebox"] = "jukebox",
    -- ["lightswitch"] = "lightswitch",
    -- ["MAX"] = "MAX",
    -- ["normal"] = "normal",
    -- ["radio"] = "radio",
    ["stairsBN"] = "stairsBN",
    ["stairsBW"] = "stairsBW",
    ["stairsMN"] = "stairsMN",
    ["stairsMW"] = "stairsMW",
    ["stairsTN"] = "stairsTN",
    ["stairsTW"] = "stairsTW",
    ["tree"] = "tree",
    -- ["UNUSED10"] = "UNUSED10",
    -- ["UNUSED24"] = "UNUSED24",
    -- ["UNUSED9"] = "UNUSED9",
    -- ["wall"] = "wall",
    -- ["WestRoofB"] = "WestRoofB",
    -- ["WestRoofM"] = "WestRoofM",
    -- ["WestRoofT"] = "WestRoofT",
    -- ["windowFN"] = "windowFN",
    -- ["windowFW"] = "windowFW",
}

WorldTools._PropertyToStructureType = {
	["WallN"] = "Wall",
	["WallW"] = "Wall",
	["WallNW"] = "Wall",
	["DoorSound"] = "Door",
	["WindowN"] = "Window",
	["WindowW"] = "Window",
    ["stairsBN"] = "Stairs",
    ["stairsBW"] = "Stairs",
    ["stairsMN"] = "Stairs",
    ["stairsMW"] = "Stairs",
    ["stairsTN"] = "Stairs",
    ["stairsTW"] = "Stairs",
}

---Retrieve property identification.
---@param object IsoObject
---@param spriteProperties PropertyContainer
---@return string|false
WorldTools.GetObjectType = function(object, spriteProperties)
	if spriteProperties:Is("WallN") then
		return "WallN"
	elseif spriteProperties:Is("WallW") then
		return "WallW"
	elseif spriteProperties:Is("WallNW") then
		return "WallNW"
	elseif spriteProperties:Is("DoorSound") then
		return "DoorSound"
	elseif spriteProperties:Is("WindowN") then
		return "WindowN"
	elseif spriteProperties:Is("WindowW") then
		return "WindowW"
    elseif object:isStairsObject() then
        local type = object:getType()
        return type and WorldTools.IsoObjectType[tostring(type)] or false
	end

	return false
end


--[[ ================================================ ]]--
--- OBJECT GEOMETRY ---
--[[ ================================================ ]]--

---Retrieve segments that define the 2D flat geometry of the object.
---@param object IsoObject|IsoDoor|IsoWindow|IsoThumpable
---@param propertyToSegments table
---@return table|nil
WorldTools.GetSegments = function(object,propertyToSegments)
    local sprite = object:getSprite()
    if not sprite then return nil end

    local spriteProperties = sprite:getProperties()
    if not spriteProperties then return nil end

    local objectProperty

    --- WALLS ---
    if spriteProperties:Is("WallN") or spriteProperties:Is("WallW") or spriteProperties:Is("WallNW") then
        ---@cast object IsoObject
        objectProperty = spriteProperties:Is("WallN") and "WallN" or spriteProperties:Is("WallW") and "WallW" or "WallNW"

    --- DOORS ---
	elseif spriteProperties:Is("DoorSound") then
        ---@cast object IsoDoor
        if WorldTools.CanSeeThroughDoor(object,spriteProperties) then return nil end
        objectProperty = object:getNorth() and "DoorN" or "DoorW"

    --- WINDOWS ---
    elseif (spriteProperties:Is("WindowN") or spriteProperties:Is("WindowW")) then
        ---@cast object IsoWindow
        if WorldTools.CanSeeThroughWindow(object) then return nil end

        objectProperty = spriteProperties:Is("WindowN") and "WindowN" or spriteProperties:Is("WindowW") and "WindowW"

    --- STAIRS ---
    elseif object:isStairsObject() then
        local type = object:getType()
        objectProperty = type and WorldTools.IsoObjectType[tostring(type)]
	end

    if not objectProperty then return nil end

	return propertyToSegments[objectProperty]
end


--[[ ================================================ ]]--
--- TILE TRANSPARENCY ---
--[[ ================================================ ]]--

---Checks if the door can be seen through.
---
--- 1. Checks if the door is open
--- 2. Checks for barricades
--- 3. Checks if door is transparent and has closed curtains
---@param door IsoDoor
---@param spriteProperties PropertyContainer
---@return boolean
WorldTools.CanSeeThroughDoor = function(door,spriteProperties)
    -- check open
    if door:IsOpen() then return true end

    -- check for barricades
    local barricade1 = door:getBarricadeOnSameSquare()
    local barricade2 = door:getBarricadeOnOppositeSquare()
    if barricade1 and barricade1:isBlockVision()
    or barricade2 and barricade2:isBlockVision() then
        return false
    end

    if spriteProperties:Is("doorTrans") then
        -- check for curtains
        local curtains = door:HasCurtains() ---@as IsoCurtain
        return not curtains or curtains:isCurtainOpen() -- TODO: might be wrong for IsoThumpable
    end

    return false
end

---Checks if the window can be seen through.
---
--- 1. Checks for barricades
--- 2. Checks for closed curtains
---@param window IsoWindow
---@return boolean
WorldTools.CanSeeThroughWindow = function(window)
    -- check for barricades
    local barricade1 = window:getBarricadeOnSameSquare()
    local barricade2 = window:getBarricadeOnOppositeSquare()
    if barricade1 and barricade1:isBlockVision() or barricade2 and barricade2:isBlockVision() then
        return false
    end

    -- check for curtains
    local curtains = window:HasCurtains() ---@as IsoCurtain
    return not curtains or curtains:IsOpen()
end


return WorldTools