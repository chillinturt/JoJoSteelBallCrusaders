local replicatedStorage = game:GetService("ReplicatedStorage")

local pilotEvent = Instance.new("RemoteEvent")
pilotEvent.Name = "PilotMode"
pilotEvent.Parent = replicatedStorage.Shared.BasicCombat

local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local PilotModeModule = require(game.ServerScriptService.BasicCombat:WaitForChild("PilotModule"))

local CameraEvent = replicatedStorage.Shared:WaitForChild("BasicCombat"):WaitForChild("PilotCameraEvent")

-- Toggle Pilot Mode
pilotEvent.OnServerEvent:Connect(function(player, inPilotMode)
	local character = player.Character
	local stun = character:FindFirstChild("Stun")
	if stun then
		return
	end

	if inPilotMode then
		PilotModeModule.EnterPilotMode(player.Character, StandUtils.getStandModel(player.Character))
	else
		PilotModeModule.ExitPilotMode(player.Character)
		CameraEvent:FireClient(player, "reset")
	end
end)
