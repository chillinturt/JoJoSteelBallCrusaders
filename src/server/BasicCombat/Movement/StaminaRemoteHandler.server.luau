local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-------------------------------------------------
-- REMOTES
-------------------------------------------------

local dashEvent = Instance.new("RemoteEvent")
dashEvent.Name = "DashEvent"
dashEvent.Parent = ReplicatedStorage.Shared.BasicCombat

local dashUpdateEvent = Instance.new("RemoteEvent")
dashUpdateEvent.Name = "DashUpdateEvent"
dashUpdateEvent.Parent = ReplicatedStorage.Shared.BasicCombat

local doubleJumpEvent = Instance.new("RemoteEvent") -- RemoteEvent
doubleJumpEvent.Name = "DoubleJumpEvent"
doubleJumpEvent.Parent = ReplicatedStorage.Shared.BasicCombat

local wallJumpEvent = Instance.new("RemoteEvent") -- RemoteEvent
wallJumpEvent.Name = "WallJumpEvent"
wallJumpEvent.Parent = ReplicatedStorage.Shared.BasicCombat

local StaminaService = require(script.Parent.StaminaService)

-------------------------------------------------
-- PLAYER SETUP
-------------------------------------------------

-- Existing players (THIS FIXES YOUR BUG)
for _, player in ipairs(Players:GetPlayers()) do
	StaminaService.InitPlayer(player)
end

--joining players
Players.PlayerAdded:Connect(function(player)
	StaminaService.InitPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	StaminaService.RemovePlayer(player)
end)

-------------------------------------------------
-- NETWORK EVENTS
-------------------------------------------------

dashEvent.OnServerEvent:Connect(function(player, dir)
	if typeof(dir) ~= "string" then
		dir = "Forward"
	end

	StaminaService.OnDashRequest(player, dir)
end)

doubleJumpEvent.OnServerEvent:Connect(function(player)
	StaminaService.OnJumpRequest(player)
end)
