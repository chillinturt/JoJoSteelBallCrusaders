local ReplicatedStorage = game:GetService("ReplicatedStorage")

local XPSystem = require(game.ServerScriptService.DataSaving:WaitForChild("XPSystem"))

local remoteFolder = ReplicatedStorage:WaitForChild("UIs"):WaitForChild("RemoteEvents")
local XPUpdatedEvent = remoteFolder:FindFirstChild("XPUpdated")

local RequestXPData = Instance.new("RemoteEvent")
RequestXPData.Name = "RequestXPData"
RequestXPData.Parent = remoteFolder

RequestXPData.OnServerEvent:Connect(function(player)
	local stats = XPSystem.GetStats(player)

	if not stats then
		warn("RequestXPData: stats nil for", player.Name)
		return
	end

	XPUpdatedEvent:FireClient(player, stats)
end)
