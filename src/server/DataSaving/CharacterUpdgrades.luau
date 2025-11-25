-- CharacterUpgrades.luau
local CharacterUpgrades = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local upgradeEvent = ReplicatedStorage:FindFirstChild("UpgradeSubmitted")
if not upgradeEvent then
	upgradeEvent = Instance.new("RemoteEvent")
	upgradeEvent.Name = "UpgradeSubmitted"
	upgradeEvent.Parent = ReplicatedStorage
end

local MAX_HP_UPGRADES = 100

-- Default per-player upgrade state
local function createUpgradeFolder(player)
	local folder = Instance.new("Folder")
	folder.Name = "UpgradeData"
	folder.Parent = player

	local health = Instance.new("IntValue")
	health.Name = "HealthUpgrades"
	health.Value = 0
	health.Parent = folder

	return folder
end

-- Fetch or create the player's upgrade data folder
function CharacterUpgrades.getUpgradeFolder(player)
	local folder = player:FindFirstChild("UpgradeData")
	if not folder then
		folder = createUpgradeFolder(player)
	end
	return folder
end

---------------------------------------------------------------------
-- PROCESS UPGRADE REQUEST
---------------------------------------------------------------------
function CharacterUpgrades.ApplyUpgrade(player, upgradeType)
	local upgradeFolder = CharacterUpgrades.getUpgradeFolder(player)
	local stats = player:FindFirstChild("Stats")
	if not stats then
		return
	end

	local abilityPoints = stats:FindFirstChild("AbilityPoints")
	if not abilityPoints or abilityPoints.Value <= 0 then
		upgradeEvent:FireClient(player, false, 0) -- failure
		return
	end

	-- HEALTH UPGRADE
	if upgradeType == "Health" then
		local hpUpgrades = upgradeFolder:FindFirstChild("HealthUpgrades")
		if hpUpgrades.Value >= MAX_HP_UPGRADES then
			upgradeEvent:FireClient(player, false, hpUpgrades.Value)
			return
		end

		-- Deduct point and apply upgrade
		hpUpgrades.Value += 1
		abilityPoints.Value -= 1

		-- Success: send back to UI
		upgradeEvent:FireClient(player, true, hpUpgrades.Value)
		return
	end

	-- UNKNOWN UPGRADE
	warn("Unknown upgrade type from client: " .. tostring(upgradeType))
	upgradeEvent:FireClient(player, false, 0)
end

---------------------------------------------------------------------
-- LISTEN FOR CLIENT SIGNALS
---------------------------------------------------------------------
upgradeEvent.OnServerEvent:Connect(function(player, requestedUpgrade)
	if typeof(requestedUpgrade) ~= "string" then
		warn("Invalid upgrade request from", player.Name)
		return
	end

	CharacterUpgrades.ApplyUpgrade(player, requestedUpgrade)
end)

return CharacterUpgrades
