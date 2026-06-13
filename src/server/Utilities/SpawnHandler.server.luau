local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local SpawnConfig = require(game.ServerScriptService.Utilities:WaitForChild("SpawnConfig"))
local XPSystem = require(game.ServerScriptService.DataSaving:WaitForChild("XPSystem"))

local spawnFolder = Workspace:WaitForChild("Teleports"):WaitForChild("SpawnLocations")

-- Get player's level safely
local function getPlayerLevel(player)
	local stats = XPSystem.GetStats(player)
	return stats and stats.Level or 1
end

-- Get valid spawn parts for player
local function getAvailableSpawns(player)
	local level = getPlayerLevel(player)
	local validSpawns = {}

	for spawnName, requiredLevel in pairs(SpawnConfig.Spawns) do
		if level >= requiredLevel then
			local spawnPart = spawnFolder:FindFirstChild(spawnName)
			if spawnPart then
				table.insert(validSpawns, spawnPart)
			end
		end
	end

	return validSpawns
end

-- Choose random spawn
local function getRandomSpawn(spawnList)
	if #spawnList == 0 then
		return nil
	end
	return spawnList[math.random(1, #spawnList)]
end

-- Apply spawn
local function setCharacterSpawn(player, character)
	local hrp = character:WaitForChild("HumanoidRootPart")

	local spawns = getAvailableSpawns(player)
	local chosenSpawn = getRandomSpawn(spawns)

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
end)
