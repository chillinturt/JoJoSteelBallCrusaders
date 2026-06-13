local ServerScriptService = game:GetService("ServerScriptService")

local EnemySpawner = require(script.Parent:WaitForChild("EnemySpawner"))

local EnemyDefinitions = require(script.Parent:WaitForChild("EnemyDefinitions"))

local SpawnFolder = workspace.NPCs:WaitForChild("EnemyNPCSpawns")

local activeSpawners = {}

local EnemySpawner = require(script.Parent:WaitForChild("EnemySpawner"))

local EnemyDefinitions = require(script.Parent:WaitForChild("EnemyDefinitions"))

local SpawnFolder = workspace.NPCs:WaitForChild("EnemyNPCSpawns")

local activeSpawners = {}

for _, enemyFolder in ipairs(SpawnFolder:GetChildren()) do
	if not enemyFolder:IsA("Folder") then
		continue
	end

	local enemyType = enemyFolder.Name

	local config = EnemyDefinitions[enemyType]

	if not config then
		warn("Missing EnemyDefinition for:", enemyType)
		continue
	end

	for _, spawnPart in ipairs(enemyFolder:GetChildren()) do
		if spawnPart:IsA("BasePart") then
			local spawner = EnemySpawner.new(spawnPart, enemyType, config)

			table.insert(activeSpawners, spawner)
		end
	end
end

while true do
	for _, spawner in ipairs(activeSpawners) do
		spawner:Update()
	end

	task.wait(5)
end

print("Loaded", #activeSpawners, "enemy spawners.")
