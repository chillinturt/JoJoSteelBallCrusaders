local ChestSpawner = require(script.Parent:WaitForChild("ChestSpawner"))

local ChestDefinitions = require(script.Parent:WaitForChild("ChestDefinitions"))
local ChestZoneDefinitions = require(script.Parent:WaitForChild("ChestZoneDefinitions"))

local ZoneFolder = workspace:WaitForChild("ChestZones")

local zones = {}

for _, zoneFolder in ipairs(ZoneFolder:GetChildren()) do
	if not zoneFolder:IsA("Folder") then
		continue
	end

	local zoneConfig = ChestZoneDefinitions[zoneFolder.Name]

	if not zoneConfig then
		warn("Missing ChestZoneDefinition for:", zoneFolder.Name)
		continue
	end

	local spawners = {}

	for _, spawnPart in ipairs(zoneFolder:GetChildren()) do
		if spawnPart:IsA("BasePart") then
			table.insert(spawners, ChestSpawner.new(spawnPart, ChestDefinitions))
		end
	end

	table.insert(zones, {
		Name = zoneFolder.Name,
		Config = zoneConfig,
		Spawners = spawners,
	})
end

local function pickRandomChestType(zoneConfig)
	local chestTypes = zoneConfig.ChestTypes

	return chestTypes[math.random(1, #chestTypes)]
end

local function fillZone(zone)
	local activeCount = 0

	for _, spawner in ipairs(zone.Spawners) do
		if spawner.IsActive then
			activeCount += 1
		end
	end

	local slotsToFill = zone.Config.MaxChests - activeCount

	if slotsToFill <= 0 then
		return
	end

	local available = {}

	for _, spawner in ipairs(zone.Spawners) do
		if spawner:IsAvailable() then
			table.insert(available, spawner)
		end
	end

	-- shuffle available spawn points so the same ones don't always win
	for i = #available, 2, -1 do
		local j = math.random(i)
		available[i], available[j] = available[j], available[i]
	end

	for i = 1, math.min(slotsToFill, #available) do
		available[i]:Activate(pickRandomChestType(zone.Config))
	end
end

local totalSpawners = 0
for _, zone in ipairs(zones) do
	totalSpawners += #zone.Spawners
end

print("Loaded", #zones, "chest zones with", totalSpawners, "chest spawn points.")

while true do
	for _, zone in ipairs(zones) do
		fillZone(zone)
	end

	task.wait(5)
end
