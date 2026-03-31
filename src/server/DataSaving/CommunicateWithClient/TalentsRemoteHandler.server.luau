-- ServerScriptService/RemoteHandlers/SkillTreeRemoteHandler.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local XPSystem = require(game.ServerScriptService.DataSaving.XPSystem)
local TalentsModule = require(game.ServerScriptService.DataSaving.Upgrades:WaitForChild("TalentsModule"))

local remoteFolder = ReplicatedStorage:WaitForChild("UIs"):WaitForChild("RemoteEvents")
local upgradeEvent = remoteFolder:WaitForChild("UpgradeSubmitted")
local TalentUpdateEvent = remoteFolder:WaitForChild("SkillTreeUpdateEvent")
local XPUpdatedEvent = remoteFolder:FindFirstChild("XPUpdated")

--------------------------------------------------------
-- 🟩 CLIENT → SERVER UPGRADE REQUEST
--------------------------------------------------------

upgradeEvent.OnServerEvent:Connect(function(player, skillName)
	local success, msg = TalentsModule.ApplyUpgrade(player, skillName)

	local stats = XPSystem.GetStats(player)
	local upgrades = TalentsModule.GetStats(player)

	local payload = {
		TalentPoints = stats.TalentPoints,
		Talents = upgrades.Talents,
	}

	if not success then
		TalentUpdateEvent:FireClient(player, payload)
		return upgradeEvent:FireClient(player, false, msg)
	end

	TalentUpdateEvent:FireClient(player, payload)
	upgradeEvent:FireClient(player, true, payload)
end)

-- Server-side example
TalentUpdateEvent.OnServerEvent:Connect(function(player, request)
	if request == "RequestFullSync" then
		local ap = XPSystem.GetField(player, "TalentPoints") or 0
		local stats = TalentsModule.GetStats(player)

		TalentUpdateEvent:FireClient(player, {
			TalentPoints = ap,
			Talents = stats.Talents,
		})
	end
end)

---------------------------------------------------------------------
-- CLEANUP ON PLAYER JOIN
---------------------------------------------------------------------
local function setupPlayer(player)
	TalentsModule.InitPlayer(player)

	player.CharacterAdded:Connect(function(character)
		print("CharacterAdded fired for", player.Name)

		task.defer(function()
			print("Attempting to apply talents...")

			TalentsModule.ApplyAllEffects(player)

			local ap = XPSystem.GetField(player, "TalentPoints") or 0
			local stats = TalentsModule.GetStats(player)

			TalentUpdateEvent:FireClient(player, {
				TalentPoints = ap,
				Talents = stats.Talents,
			})

			XPUpdatedEvent:FireClient(player, XPSystem.GetStats(player))

			print("updating skill tree text")
		end)
	end)

	-- 🔥 IMPORTANT: handle already spawned character
	if player.Character then
		print("Character already exists for", player.Name)

		task.defer(function()
			print("Attempting to apply talents (existing character)...")

			TalentsModule.ApplyAllEffects(player)

			local ap = XPSystem.GetField(player, "TalentPoints") or 0
			local stats = TalentsModule.GetStats(player)

			TalentUpdateEvent:FireClient(player, {
				TalentPoints = ap,
				Talents = stats.Talents,
			})

			XPUpdatedEvent:FireClient(player, XPSystem.GetStats(player))

			print("updating skill tree text (existing character)")
		end)
	end
end

-- Existing players
for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

-- Future players
Players.PlayerAdded:Connect(setupPlayer)
