local VampireModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- CONFIGURATION
local MAX_BLOOD = 100
local DRAIN_RATE = 2.5 -- units per second

local activeBloodValues = {} -- [character] = NumberValue
local chargingFlags = {} -- [character] = true/false

function VampireModule.spendBlood(character, cost)
	if not character or typeof(cost) ~= "number" then
		return false -- invalid input
	end

	local bloodVal = VampireModule.getBloodValue(character)
	if not bloodVal then
		return false
	end

	-- Check if the player has enough Blood
	if bloodVal.Value >= cost then
		bloodVal.Value -= cost
		return true -- success
	else
		return false -- not enough Blood
	end
end

function VampireModule.addBlood(character, amount)
	if not character or typeof(amount) ~= "number" then
		print("Invalid arguments in add blood")
		return false -- invalid input
	end

	local bloodVal = VampireModule.getBloodValue(character)
	if not bloodVal then
		print("cannot get blood value")
		return false
	end

	-- Add blood, but don't exceed MAX_BLOOD
	local newValue = math.min(bloodVal.Value + amount, MAX_BLOOD)
	bloodVal.Value = newValue

	return true -- success
end

function VampireModule.getIsVampireRace(character)
	local characterPowersFolder = character:WaitForChild("Powers")
	local raceValueObject = characterPowersFolder:FindFirstChild("Race")
	if not raceValueObject then
		warn("Player has no Race StringValue!")
		return false
	end

	local race = raceValueObject.Value
	if race == "Vampire" then
		return true
	end
	return false
end

-- Utility: get or create BloodMeter NumberValue
function VampireModule.getBloodValue(character)
	if not character then
		return
	end
	local val = character:FindFirstChild("BloodMeter")
	if not val then
		val = Instance.new("NumberValue")
		val.Name = "BloodMeter"
		val.Value = 0
		val.Parent = character
	end
	return val
end

function VampireModule.initVampirismForPlayer(player)
	-- When the character spawns, ensure it has a Blood
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid") -- wait until the character is fully loaded
		VampireModule.getBloodValue(character)
	end)
end

Players.PlayerAdded:Connect(function(player)
	VampireModule.initVampirismForPlayer(player)
end)

-- Constant drain when not charging
RunService.Heartbeat:Connect(function(dt)
	for char, bloodVal in pairs(activeBloodValues) do
		if char and char.Parent and not chargingFlags[char] then
			bloodVal.Value = math.clamp(bloodVal.Value - DRAIN_RATE * dt, 0, MAX_BLOOD)
		end
	end
end)

-- Cleanup when character despawns
Players.PlayerRemoving:Connect(function(player)
	local char = player.Character
	if char then
		chargingFlags[char] = nil
		activeBloodValues[char] = nil
	end
end)

return VampireModule
