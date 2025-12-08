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

---------------------------------------------------------------------
-- MODULE
---------------------------------------------------------------------
local XPSystem = {}

---------------------------------------------------------------------
-- CONSTANTS
---------------------------------------------------------------------
local MAX_LEVEL = 50

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
--   AbilityPoints = 0
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
	return xpData[player.UserId]
end

---------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------

-- Initialize default stats (runs on PlayerAdded)
function XPSystem.InitPlayer(player)
	xpData[player.UserId] = xpData[player.UserId]
		or {
			Level = 1,
			XP = 0,
			MaxXP = getXPRequirement(1),
			AbilityPoints = 0,
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
		return
	end
	if not data then
		return {}
	end
	return deepCopy(data)
end

-- Load from ProfileStore data
function XPSystem.SetStats(player, savedData)
	xpData[player.UserId] = {
		Level = savedData.Level or 1,
		XP = savedData.XP or 0,
		MaxXP = savedData.MaxXP or getXPRequirement(savedData.Level or 1),
		AbilityPoints = savedData.AbilityPoints or 0,
	}

	-- sync UI
	XPUpdatedEvent:FireClient(player, XPSystem.GetStats(player))
end

---------------------------------------------------------------------
-- MANIPULATION (Core Logic)
---------------------------------------------------------------------

function XPSystem.AddXP(player, amount)
	local ABILITY_POINTS_PER_LEVEL = 2

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
		data.AbilityPoints += ABILITY_POINTS_PER_LEVEL
		data.MaxXP = getXPRequirement(data.Level)
		SkillTreeUpdateEvent:FireClient(player, XPSystem.GetStats(player))
	end

	-- Hard cap if just hit max level
	if data.Level >= MAX_LEVEL then
		data.XP = data.MaxXP
	end

	-- sync UI
	XPUpdatedEvent:FireClient(player, XPSystem.GetStats(player))
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

	player.CharacterAdded:Connect(function()
		player:WaitForChild("PlayerGui")

		task.defer(function()
			wait(2)
			XPUpdatedEvent:FireClient(player, XPSystem.GetStats(player))
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	XPSystem.RemovePlayer(player)
end)

---------------------------------------------------------------------
return XPSystem
