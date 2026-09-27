-- Define a function to calculate the Euclidean distance between two 3D points
local function distance(point1, point2)
	local dx = point1[1] - point2[1]
	local dy = point1[2] - point2[2]
	local dz = point1[3] - point2[3]
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Define a function to calculate the total distance for a given assignment
local function calculateTotalDistance(assignment, peoplePositions, destinationPositions)
	local totalDistance = 0
	for i, personIndex in ipairs(assignment) do
		local personPosition = peoplePositions[personIndex]
		local destinationPosition = destinationPositions[i]
		totalDistance = totalDistance + distance(personPosition, destinationPosition)
	end
	return totalDistance
end

-- Define a function to check if a value exists in a table
local function containsValue(table, value)
	for _, v in ipairs(table) do
		if v == value then
			return true
		end
	end
	return false
end

-- Define a function to find the best assignment recursively
local function findBestAssignment(peoplePositions, destinationPositions, assignment, bestAssignment, minDistance)
	local n = #peoplePositions
	if #assignment == n then
		local totalDistance = calculateTotalDistance(assignment, peoplePositions, destinationPositions)
		if totalDistance < minDistance[1] then
			minDistance[1] = totalDistance
			bestAssignment[1] = assignment
		end
		return
	end

	local lastPersonIndex = #assignment + 1

	for destinationIndex = 1, n do
		if not containsValue(assignment, destinationIndex) then
			local newAssignment = {unpack(assignment)}
			table.insert(newAssignment, destinationIndex)

			local totalDistance = calculateTotalDistance(newAssignment, peoplePositions, destinationPositions)

			if totalDistance < minDistance[1] then
				findBestAssignment(peoplePositions, destinationPositions, newAssignment, bestAssignment, minDistance)
			end
		end
	end
end

-- Define the Hungarian algorithm function
function chasni_hungarian(peoplePositions, destinationPositions)
	local n = #peoplePositions

	-- Find the best assignment
	local bestAssignment = {}
	local minDistance = {math.huge}
	local assignment = {}
	findBestAssignment(peoplePositions, destinationPositions, assignment, bestAssignment, minDistance)

	return bestAssignment[1]
	-- Print the best assignment
	--print("Best Assignment:")
	--for i, personIndex in ipairs(bestAssignment[1]) do
	--	local destinationIndex = i
	--	print("Person " .. personIndex .. " -> Destination " .. destinationIndex)
	--end
	--print("Total Distance: " .. minDistance[1])
end

---- Example usage
--local peoplePositions = {
--	{7.0, 6.0, 6.0},
--	{1.0, 2.0, 3.0},
--	{1.0, 2.0, 4.0},
--	{5.0, 5.0, 6.0},
--}
--
--local destinationPositions = {
--	{1.0, 2.0, 4.0},
--	{1.0, 2.0, 5.0},
--	{6.0, 6.0, 6.0},
--	{8.0, 8.0, 8.0},
--}
--
--chasni_hungarian(peoplePositions, destinationPositions)
