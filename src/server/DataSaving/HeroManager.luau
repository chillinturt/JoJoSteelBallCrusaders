---------------------------------------------------------------------
-- HeroManager.lua
---------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

---------------------------------------------------------------------
-- Remote for client UI sync
---------------------------------------------------------------------
local HeroUpdatedEvent = Instance.new("RemoteEvent")
HeroUpdatedEvent.Name = "HeroUpdated"
HeroUpdatedEvent.Parent = ReplicatedStorage:WaitForChild("UIs"):WaitForChild("RemoteEvents")

---------------------------------------------------------------------
-- MODULE
---------------------------------------------------------------------
local HeroManager = {}

---------------------------------------------------------------------
-- IN-MEMORY STORAGE
-- Key: player.UserId
-- Value: table of hero fields
--
-- Example:
-- {
--    Hero = "Fire",
--    Specialty = "Tank",
--    Race = "Elf"
-- }
---------------------------------------------------------------------

local heroData = {}

-- Higher number = more common, lower number = rarer
local standRarities = {
	MagiciansRed = 50, -- Common
	HierophantGrand = 46, -- Uncommon
	ThatHand = 40, -- Rare
	NuclearRain = 20, -- Very Rare
	GoldExperiment = 10, -- Epic
	KingCarmine = 6, -- Legendary
	StarPurple = 2, -- Mythic
	TheWorld = 1,
}

function HeroManager.GetRandomStand()
	-- Step 1: Calculate total weight
	local totalWeight = 0
	for _, weight in pairs(standRarities) do
		totalWeight = totalWeight + weight
	end

	-- Step 2: Pick a random weight
	local randomWeight = math.random(1, totalWeight)

	-- Step 3: Iterate and find which stand corresponds to the weight
	local currentWeight = 0
	for stand, weight in pairs(standRarities) do
		currentWeight = currentWeight + weight
		if randomWeight <= currentWeight then
			return stand
		end
	end
end

---------------------------------------------------------------------
-- PRIVATE
---------------------------------------------------------------------

local function deepCopy(tbl)
	local result = {}
	for k, v in pairs(tbl) do
		result[k] = v
	end
	return result
end

---------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------

-- Initialize a new hero data structure if none exists
function HeroManager.InitPlayer(player)
	heroData[player.UserId] = heroData[player.UserId] or {
		Hero = "None",
		Specialty = "None",
		Race = "Human",
	}
end

-- Remove a player’s data (cleanup on exit)
function HeroManager.RemovePlayer(player)
	heroData[player.UserId] = nil
end

---------------------------------------------------------------------
-- SAVING / LOADING
---------------------------------------------------------------------

-- Return a deep copy suitable for saving to ProfileStore
function HeroManager.GetHero(player)
	local data = heroData[player.UserId]
	if not data then
		return {}
	end
	return deepCopy(data)
end

-- Load hero values from saved ProfileStore data
function HeroManager.SetHero(player, savedData)
	heroData[player.UserId] = {}

	for key, value in pairs(savedData or {}) do
		heroData[player.UserId][key] = tostring(value)
	end

	HeroUpdatedEvent:FireClient(player, HeroManager.GetHero(player))
end

---------------------------------------------------------------------
-- MANIPULATION
---------------------------------------------------------------------

-- Set a specific hero field
-- Example: HeroManager.SetField(player, "Hero", "Fire")
function HeroManager.SetField(player, field, value)
	local data = heroData[player.UserId]
	if not data then
		return
	end

	data[field] = value
	HeroUpdatedEvent:FireClient(player, HeroManager.GetHero(player))
end

-- Returns string value (Hero, Specialty, Race, etc.)
function HeroManager.GetField(player, field)
	local data = heroData[player.UserId]
	if not data then
		return nil
	end

	return data[field]
end

---------------------------------------------------------------------
-- DEBUG
---------------------------------------------------------------------

function HeroManager.DebugPrint(player)
	local data = heroData[player.UserId]
	if not data then
		print("No hero data")
		return
	end

	print("Hero data for", player.Name)
	for k, v in pairs(data) do
		print("  > ", k, "=", v)
	end
end

---------------------------------------------------------------------
-- Player UI sync on respawn
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	HeroManager.InitPlayer(player)
	player.CharacterAdded:Connect(function()
		player:WaitForChild("PlayerGui")

		task.defer(function()
			local data = HeroManager.GetHero(player)
			HeroUpdatedEvent:FireClient(player, data)
		end)
	end)
end)

---------------------------------------------------------------------
return HeroManager
