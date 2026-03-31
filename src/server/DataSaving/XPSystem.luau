---------------------------------------------------------------------
-- XPSystem.lua
--
-- Fully rewritten using HeroManager design patterns:
--  ✓ In-memory data
--  ✓ RemoteEvent for UI sync
--  ✓ Compatible with ProfileStore saving
---------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local HeroManager = require(ServerScriptService.DataSaving.HeroManager)

---------------------------------------------------------------------
-- Remote for client UI sync
---------------------------------------------------------------------
local remoteFolder = ReplicatedStorage:WaitForChild("UIs"):WaitForChild("RemoteEvents")
local XPUpdatedEvent = remoteFolder:FindFirstChild("XPUpdated")

if not XPUpdatedEvent then
	XPUpdatedEvent = Instance.new("RemoteEvent")
	XPUpdatedEvent.Name = "XPUpdated"
	XPUpdatedEvent.Parent = remoteFolder
end

local SkillTreeUpdateEvent = remoteFolder:FindFirstChild("SkillTreeUpdateEvent")

if not SkillTreeUpdateEvent then
	SkillTreeUpdateEvent = Instance.new("RemoteEvent")
	SkillTreeUpdateEvent.Name = "SkillTreeUpdateEvent"
	SkillTreeUpdateEvent.Parent = remoteFolder
end

local MusicEvents = ReplicatedStorage:WaitForChild("MusicEvents")
local PlaySoundEvent = MusicEvents:FindFirstChild("PlaySoundEvent")
if not PlaySoundEvent then
	PlaySoundEvent = Instance.new("RemoteEvent")
	PlaySoundEvent.Name = "PlaySoundEvent"
	PlaySoundEvent.Parent = MusicEvents
end

---------------------------------------------------------------------
-- MODULE
---------------------------------------------------------------------
local XPSystem = {}

---------------------------------------------------------------------
-- CONSTANTS
---------------------------------------------------------------------
local MAX_LEVEL = 50

local ABILITY_UNLOCK_LEVELS = {
	[10] = true,
	[25] = true,
	[40] = true,
	[50] = true,
}

local function getXPRequirement(level)
	return 100 + 20 * ((level - 1) ^ 2)
end

---------------------------------------------------------------------
-- IN-MEMORY STORAGE
-- Key: player.UserId
-- Value: table of XP stats
--
-- Example:
-- {
--   Level = 1,
--   XP = 0,
--   MaxXP = 100,
--   TalentPoints = 0
-- }
---------------------------------------------------------------------

local xpData = {}

---------------------------------------------------------------------
-- UTILITY
---------------------------------------------------------------------
local function deepCopy(tbl)
	local result = {}
	for k, v in pairs(tbl) do
		result[k] = v
	end
	return result
end

local function get(player)
	local data = xpData[player.UserId]

	if not data then
		-- 🔥 Lazy initialization (fixes race conditions)
		XPSystem.InitPlayer(player)
		data = xpData[player.UserId]
	end

	return data
end

---------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------

-- Initialize default stats (runs on PlayerAdded)
function XPSystem.InitPlayer(player)
	print("Initializing XP data for", player.Name)

	xpData[player.UserId] = xpData[player.UserId]
		or {
			Level = 1,
			XP = 0,
			MaxXP = getXPRequirement(1),
			TalentPoints = 0,
		}
end

-- Cleanup on PlayerRemoving
function XPSystem.RemovePlayer(player)
	xpData[player.UserId] = nil
end

---------------------------------------------------------------------
-- SAVING / LOADING
---------------------------------------------------------------------

-- Return deep copy for ProfileStore saving
function XPSystem.GetStats(player)
	local data = get(player)

	if not data then
		warn("XPSystem.GetStats: No data for", player.Name)

		return {
			Level = 1,
			XP = 0,
			MaxXP = getXPRequirement(1),
			TalentPoints = 0,
			AbilityPoints = 0,
		}
	end

	return deepCopy(data)
end

-- Load from ProfileStore data
function XPSystem.SetStats(player, savedData)
	local level = savedData.Level or 1

	xpData[player.UserId] = {
		Level = level,
		XP = savedData.XP or 0,
		MaxXP = savedData.MaxXP or getXPRequirement(level),
		TalentPoints = savedData.TalentPoints or 0,

		-- ✅ New data points
		AbilityPoints = savedData.AbilityPoints or 0,

		UnlockedAbilities = savedData.UnlockedAbilities or {
			[1] = false,
			[2] = false,
			[3] = false,
			[4] = false,
		},
	}

	-- sync UI
	XPUpdatedEvent:FireClient(player, XPSystem.GetStats(player))
end

function XPSystem.ResetAbilityPoints(player)
	local level = XPSystem.GetField(player, "Level") or 1
	local newPoints = 0

	-- Count how many unlock milestones the player has reached
	for unlockLevel, _ in pairs(ABILITY_UNLOCK_LEVELS) do
		if level >= unlockLevel then
			newPoints += 1
		end
	end

	-- Reset unlocked abilities
	HeroManager.SetField(player, "UnlockedAbilities", {
		[1] = false,
		[2] = false,
		[3] = false,
		[4] = false,
	})

	-- Set ability points based on level
	XPSystem.SetField(player, "AbilityPoints", newPoints)
end

---------------------------------------------------------------------
-- MANIPULATION (Core Logic)
---------------------------------------------------------------------

function XPSystem.AddXP(player, amount)
	local TALENT_POINTS_PER_LEVEL = 2

	local data = get(player)
	if not data then
		return
	end

	-- Cap at max level
	if data.Level >= MAX_LEVEL then
		data.XP = data.MaxXP
		XPUpdatedEvent:FireClient(player, XPSystem.GetStats(player))
		return
	end

	data.XP += amount

	-- Level up handling
	local gaurd = 0
	while data.XP >= data.MaxXP and data.Level < MAX_LEVEL do
		gaurd += 1
		if gaurd > 100 then
			break
		end
		data.XP -= data.MaxXP
		data.Level += 1
		data.TalentPoints += TALENT_POINTS_PER_LEVEL

		-- ✅ Grant ability point at milestone levels
		if ABILITY_UNLOCK_LEVELS[data.Level] then
			data.AbilityPoints += 1

			print("Granted Ability Point at level", data.Level)

			-- Optional: feedback
			PlaySoundEvent:FireClient(player, {
				id = "rbxassetid://97468293210189",
				volume = 1.2,
				pitch = 1,
			})
		end

		data.MaxXP = getXPRequirement(data.Level)
		SkillTreeUpdateEvent:FireClient(player, XPSystem.GetStats(player))

		--sfx
		PlaySoundEvent:FireClient(player, {
			id = "rbxassetid://114390175182916",
			volume = 1,
			pitch = 1,
		})
	end

	-- Hard cap if just hit max level
	if data.Level >= MAX_LEVEL then
		data.XP = data.MaxXP
	end

	-- sync UI
	XPUpdatedEvent:FireClient(player, XPSystem.GetStats(player))

	--sfx
	PlaySoundEvent:FireClient(player, {
		id = "rbxassetid://88387457337661",
		volume = 1,
		pitch = 1,
	})
end

---------------------------------------------------------------------
-- GETTERS
---------------------------------------------------------------------

function XPSystem.GetField(player, field)
	local data = get(player)
	if not data then
		return
	end
	return data[field]
end

function XPSystem.SetField(player, field, value)
	local data = get(player)
	if not data then
		return
	end

	data[field] = value
	XPUpdatedEvent:FireClient(player, XPSystem.GetStats(player))
end

---------------------------------------------------------------------
-- DEBUG
---------------------------------------------------------------------

function XPSystem.DebugPrint(player)
	local data = get(player)
	if not data then
		return
	end

	print("XP data for", player.Name)
	for k, v in pairs(data) do
		print(" > ", k, "=", v)
	end
end

---------------------------------------------------------------------
-- PLAYER HOOKS
---------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
	XPSystem.InitPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	XPSystem.RemovePlayer(player)
end)

---------------------------------------------------------------------
return XPSystem
