-- ExtraHealthServer.lua
-- Applies health upgrades from CharacterUpgrades + live health updates
-- Compatible with in-memory CharacterUpgrades

local Players = game:GetService("Players")
local CharacterUpgrades = require(game.ServerScriptService.DataSaving.Upgrades:WaitForChild("CharacterUpdgrades"))
local XPSystem = require(game.ServerScriptService.DataSaving.XPSystem)

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

	local upgrades = CharacterUpgrades.GetStats(player)
	local hpUpgrades = upgrades.Health or 0

	local newMax = BASE_HEALTH + (hpUpgrades * HEALTH_PER_UPGRADE)
	humanoid.MaxHealth = newMax
	humanoid.Health = newMax -- Heal to new maximum
end

--[[ Listen for upgrades being applied through CharacterUpgrades
local function setupLiveUpgradeUpdates(player)
	-- RemoteEvent fires whenever an upgrade is applied
	local remote = CharacterUpgrades and game.ReplicatedStorage:WaitForChild("UpgradeSubmitted")
	if not remote then
		return
	end

	remote.OnServerEvent:Connect(function(plr, upgradeType)
		if plr ~= player then
			return
		end
		if upgradeType == "Health" then
			local character = player.Character
			if character then
				applyUpgradeHealth(player, character)
			end
		end
	end)
end
]]

local function onCharacterAdded(player, character)
	character:WaitForChild("Humanoid")
	task.wait(0.1)
	applyUpgradeHealth(player, character)
end

-- Player join setup
Players.PlayerAdded:Connect(function(player)
	CharacterUpgrades.InitPlayer(player)

	-- Listen for character spawn
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	-- Set up live upgrade connection
	--setupLiveUpgradeUpdates(player)

	-- Studio immediate spawn
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end)
