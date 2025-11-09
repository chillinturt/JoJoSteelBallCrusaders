local replicatedStorage = game:GetService("ReplicatedStorage")
local summonEvent = Instance.new("RemoteEvent")
summonEvent.Name = "SummonEvent"
summonEvent.Parent = replicatedStorage.Shared.BasicCombat

local pilotModule = require(game.ServerScriptService.BasicCombat:WaitForChild("PilotModule"))

local physicsService = game:GetService("PhysicsService")

local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))

-- Ensure "NoCollision" group exists
local success, errorMessage = pcall(function()
	physicsService:RegisterCollisionGroup("NoCollision")
end)

if success then
	print("Collision group 'NoCollision' registered successfully.")
else
	warn("Failed to register collision group 'NoCollision': " .. errorMessage)
end

-- Function to toggle the summoned model on and off using the module
local function onSummonRequested(player)
	local character = player.Character
	if not character then
		return
	end

	local powersFolder = character:WaitForChild("Powers")

	local heroValue = powersFolder:FindFirstChild("Hero")
	if not heroValue or heroValue.Value == "" then
		warn("⚠️ No Hero value found for", player.Name)
		return
	end

	-- ✅ Get the StandTag from Hero value (or another mapping system if needed)
	local standTag = nil

	if heroValue.Value then
		standTag = heroValue.Value
	end

	if not standTag then
		warn("⚠️ No standTag found for hero:", heroValue.Value)
		return
	end

	-- ✅ Toggle using SummonStand and RemoveStand
	if StandUtils.getStandModel(character) then
		StandUtils.RemoveStand(character, player)
		pilotModule.ExitPilotMode(character)
		print("Exit Pilot Mode/ remove stand called")
	else
		StandUtils.SummonStand(character, standTag)
	end
end

-- Connect the summon event
summonEvent.OnServerEvent:Connect(onSummonRequested)
