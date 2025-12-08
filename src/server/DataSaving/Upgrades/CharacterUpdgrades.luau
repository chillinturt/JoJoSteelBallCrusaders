-- CharacterUpgrades.lua
-- In-memory character upgrade system (no workspace objects)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local XPSystem = require(game.ServerScriptService.DataSaving:WaitForChild("XPSystem"))

---------------------------------------------------------------------
-- REMOTE EVENT (UI Sync)
---------------------------------------------------------------------
local UpgradeSubmitted = ReplicatedStorage:FindFirstChild("UpgradeSubmitted")
if not UpgradeSubmitted then
	UpgradeSubmitted = Instance.new("RemoteEvent")
	UpgradeSubmitted.Name = "UpgradeSubmitted"
	UpgradeSubmitted.Parent = ReplicatedStorage
end

local CharacterUpgrades = {}
---------------------------------------------------------------------
-- CONSTANTS
---------------------------------------------------------------------
local MAX_HP_UPGRADES = 100

---------------------------------------------------------------------
-- IN-MEMORY STORAGE
-- upgradeData[player.UserId] = {
--     Health = 0,
--     Damage = 0,
--     whatever...
-- }
---------------------------------------------------------------------
local upgradeData = {}

---------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------
local function get(player)
	return upgradeData[player.UserId]
end

local function ensure(player)
	if not upgradeData[player.UserId] then
		upgradeData[player.UserId] = {}
	end

	local data = upgradeData[player.UserId]

	-- 🔥 defaults
	data.Health = data.Health or 0

	return data
end
---------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------

-- Called on PlayerAdded from PlayerManager
function CharacterUpgrades.InitPlayer(player)
	ensure(player)
end

function CharacterUpgrades.RemovePlayer(player)
	upgradeData[player.UserId] = nil
end

---------------------------------------------------------------------
-- UPGRADE HANDLER
---------------------------------------------------------------------
function CharacterUpgrades.ApplyUpgrade(player, upgradeType)
	local data = ensure(player)

	local ap = XPSystem.GetField(player, "AbilityPoints") or 0

	-- Check ability points
	if ap <= 0 then
		UpgradeSubmitted:FireClient(player, false, {
			AbilityPoints = ap,
			HealthLevel = data.Health or 0,
		})
		return
	end

	-----------------------------------------------------------------
	-- HEALTH
	-----------------------------------------------------------------
	if upgradeType == "Health" then
		data.Health = data.Health or 0

		if data.Health >= MAX_HP_UPGRADES then
			UpgradeSubmitted:FireClient(player, false, {
				AbilityPoints = ap,
				HealthLevel = data.Health,
			})
			return
		end

		-- Spend ability point
		XPSystem.SetField(player, "AbilityPoints", ap - 1)

		-- Apply upgrade
		data.Health += 1

		-- Always send table
		UpgradeSubmitted:FireClient(player, true, {
			AbilityPoints = ap - 1,
			HealthLevel = data.Health,
		})
		return
	end

	-----------------------------------------------------------------
	-- UNKNOWN TYPE
	-----------------------------------------------------------------
	UpgradeSubmitted:FireClient(player, false, {
		AbilityPoints = ap,
		HealthLevel = data.Health or 0,
	})
end

---------------------------------------------------------------------
-- REMOTE LISTENER
---------------------------------------------------------------------
UpgradeSubmitted.OnServerEvent:Connect(function(player, requestedUpgrade)
	if typeof(requestedUpgrade) ~= "string" then
		warn("Invalid upgrade request from", player.Name)
		return
	end

	CharacterUpgrades.ApplyUpgrade(player, requestedUpgrade)
end)

---------------------------------------------------------------------
-- PROFILESTORE HELPERS (SAVE / LOAD)
---------------------------------------------------------------------
function CharacterUpgrades.GetStats(player)
	local data = get(player)
	if not data then
		return {}
	end

	-- shallow copy is fine
	local copy = {}
	for k, v in pairs(data) do
		copy[k] = v
	end
	return copy
end

function CharacterUpgrades.SetStats(player, savedData)
	upgradeData[player.UserId] = savedData or {}
	local data = upgradeData[player.UserId]

	-- 🔥 defaults
	data.Health = data.Health or 0
end

---------------------------------------------------------------------
-- RETURN MODULE
---------------------------------------------------------------------
return CharacterUpgrades
