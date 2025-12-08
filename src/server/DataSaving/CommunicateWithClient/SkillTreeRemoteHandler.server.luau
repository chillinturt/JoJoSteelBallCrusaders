-- ServerScriptService/RemoteHandlers/SkillTreeRemoteHandler.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local XPSystem = require(game.ServerScriptService.DataSaving.XPSystem)
local CharacterUpgrades = require(game.ServerScriptService.DataSaving.Upgrades:WaitForChild("CharacterUpdgrades"))

local remoteFolder = ReplicatedStorage:WaitForChild("UIs"):WaitForChild("RemoteEvents")
local upgradeEvent = ReplicatedStorage:WaitForChild("UpgradeSubmitted")
local updateEvent = remoteFolder:WaitForChild("SkillTreeUpdateEvent")

--------------------------------------------------------
-- 🟩 CLIENT → SERVER UPGRADE REQUEST
--------------------------------------------------------

upgradeEvent.OnServerEvent:Connect(function(player, skillName)
	local success, msg = CharacterUpgrades.ApplyUpgrade(player, skillName)
	local stats = XPSystem.GetStats(player)

	if not success then
		updateEvent:FireClient(player, {
			AbilityPoints = stats.AbilityPoints,
		})

		return upgradeEvent:FireClient(player, false, msg)
	end

	-- Success: send updated values back
	updateEvent:FireClient(player, stats)
	upgradeEvent:FireClient(player, true, stats)
end)
