-- ServerScriptService/RemoteHandlers/SkillTreeRemoteHandler.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local XPSystem = require(game.ServerScriptService.DataSaving.XPSystem)
local TalentsModule = require(game.ServerScriptService.DataSaving.Upgrades:WaitForChild("TalentsModule"))

local remoteFolder = ReplicatedStorage:WaitForChild("UIs"):WaitForChild("RemoteEvents")
local upgradeEvent = remoteFolder:WaitForChild("UpgradeSubmitted")
local updateEvent = remoteFolder:WaitForChild("SkillTreeUpdateEvent")

--------------------------------------------------------
-- 🟩 CLIENT → SERVER UPGRADE REQUEST
--------------------------------------------------------

upgradeEvent.OnServerEvent:Connect(function(player, skillName)
	local success, msg = TalentsModule.ApplyUpgrade(player, skillName)

	local stats = XPSystem.GetStats(player)
	local upgrades = TalentsModule.GetStats(player)

	local payload = {
		AbilityPoints = stats.AbilityPoints,
		Talents = upgrades.Talents,
	}

	if not success then
		updateEvent:FireClient(player, payload)
		return upgradeEvent:FireClient(player, false, msg)
	end

	updateEvent:FireClient(player, payload)
	upgradeEvent:FireClient(player, true, payload)
end)

-- Server-side example
updateEvent.OnServerEvent:Connect(function(player, request)
	if request == "RequestFullSync" then
		local ap = XPSystem.GetField(player, "AbilityPoints") or 0
		local stats = TalentsModule.GetStats(player)

		updateEvent:FireClient(player, {
			AbilityPoints = ap,
			Talents = stats.Talents,
		})
	end
end)

---------------------------------------------------------------------
-- CLEANUP ON PLAYER JOIN
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	-- Ensure folder exists
	TalentsModule.InitPlayer(player)
	player.CharacterAdded:Connect(function()
		task.wait(3)

		-- Reapply all talent effects
		TalentsModule.ApplyAllEffects(player)

		local ap = XPSystem.GetField(player, "AbilityPoints") or 0
		local stats = TalentsModule.GetStats(player)

		updateEvent:FireClient(player, {
			AbilityPoints = ap,
			Talents = stats.Talents,
		})
		print("updating skill tree text")
	end)
end)
