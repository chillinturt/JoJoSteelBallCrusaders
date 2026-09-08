local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local spawnFolder = Workspace:WaitForChild("Teleports"):WaitForChild("SpawnLocations")

-- Used the first time a player spawns in a session, before any death position is known.
local DEFAULT_SPAWN_NAME = "FirstIsland"

-- [Player] = Vector3, the position they were at right before their character was removed.
local lastPositions = {}

local function getSpawnParts()
	local parts = {}
	for _, child in ipairs(spawnFolder:GetChildren()) do
		if child:IsA("BasePart") then
			table.insert(parts, child)
		end
	end
	return parts
end

-- Closest spawn part to the given world position, regardless of level.
local function getNearestSpawn(position)
	local nearestPart, nearestDist

	for _, part in ipairs(getSpawnParts()) do
		local dist = (part.Position - position).Magnitude
		if not nearestDist or dist < nearestDist then
			nearestPart, nearestDist = part, dist
		end
	end

	return nearestPart
end

-- Apply spawn
local function setCharacterSpawn(player, character)
	local hrp = character:WaitForChild("HumanoidRootPart")

	local referencePosition = lastPositions[player]
	local chosenSpawn = referencePosition and getNearestSpawn(referencePosition)
		or spawnFolder:FindFirstChild(DEFAULT_SPAWN_NAME)

	if chosenSpawn then
		hrp.CFrame = chosenSpawn.CFrame + Vector3.new(0, 3, 0)
	else
		warn("No valid spawn found for", player.Name)
	end
end

-- Hook into character spawning
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait() -- ensure everything loads
		setCharacterSpawn(player, character)
	end)

	player.CharacterRemoving:Connect(function(character)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			lastPositions[player] = hrp.Position
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	lastPositions[player] = nil
end)
