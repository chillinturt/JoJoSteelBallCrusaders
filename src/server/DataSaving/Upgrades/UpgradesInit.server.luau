local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- require the module so it actually runs
local CharacterUpgrades = require(ServerScriptService.DataSaving.Upgrades:WaitForChild("CharacterUpdgrades"))
local XPSystem = require(ServerScriptService.DataSaving:WaitForChild("XPSystem"))

local remoteFolder = ReplicatedStorage:WaitForChild("UIs"):WaitForChild("RemoteEvents")
local SkillTreeUpdateEvent = remoteFolder:FindFirstChild("SkillTreeUpdateEvent")
if not SkillTreeUpdateEvent then
	remote = Instance.new("RemoteEvent")
	remote.Name = "SkillTreeUpdateEvent"
	SkillTreeUpdateEvent.Parent = remoteFolder
end

-- Server-side example
SkillTreeUpdateEvent.OnServerEvent:Connect(function(player, request)
	if request == "RequestFullSync" then
		local upgrades = CharacterUpgrades.GetStats(player)
		local ap = XPSystem.GetField(player, "AbilityPoints") or 0
		SkillTreeUpdateEvent:FireClient(player, {
			AbilityPoints = ap,
			HealthLevel = upgrades.Health or 0,
		})
	end
end)

---------------------------------------------------------------------
-- CLEANUP ON PLAYER JOIN
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	-- Ensure folder exists
	CharacterUpgrades.InitPlayer(player)
	player.CharacterAdded:Connect(function()
		wait(3)
		SkillTreeUpdateEvent:FireClient(player, CharacterUpgrades.GetStats(player))
		print("updating skill tree text")
	end)
end)
