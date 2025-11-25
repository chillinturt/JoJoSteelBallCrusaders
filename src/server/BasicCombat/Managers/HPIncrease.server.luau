-- ExtraHealthServer.lua
-- Applies health upgrades from CharacterUpgrades + live health updates

local Players = game:GetService("Players")

-- === CONFIG ===
local BASE_HEALTH = 100 -- Default humanoid HP
local HEALTH_PER_UPGRADE = 2 -- HP added per upgrade point

-- === FUNCTIONS ===
local function applyUpgradeHealth(player, character)
	if not player or not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local upgradeFolder = player:FindFirstChild("UpgradeData")
	if not upgradeFolder then
		return
	end

	local hpUpgrades = upgradeFolder:FindFirstChild("HealthUpgrades")
	if not hpUpgrades then
		return
	end

	local extraHealth = hpUpgrades.Value * HEALTH_PER_UPGRADE
	local newMax = BASE_HEALTH + extraHealth

	humanoid.MaxHealth = newMax
	humanoid.Health = newMax -- Heal to new maximum
end

local function setupLiveUpgradeUpdates(player)
	-- Wait for upgrade folder (CharacterUpgrades module creates it)
	local upgradeFolder = player:WaitForChild("UpgradeData")
	local hpUpgrades = upgradeFolder:WaitForChild("HealthUpgrades")

	-- Update health LIVE when upgrade value changes
	hpUpgrades:GetPropertyChangedSignal("Value"):Connect(function()
		local character = player.Character
		if character then
			applyUpgradeHealth(player, character)
		end
	end)
end

local function onCharacterAdded(player, character)
	character:WaitForChild("Humanoid")
	task.wait(0.1)
	applyUpgradeHealth(player, character)
end

-- Player join setup
Players.PlayerAdded:Connect(function(player)
	-- Listen for character spawn
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	-- Set up live upgrade connection
	setupLiveUpgradeUpdates(player)

	-- Studio immediate spawn
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end)
