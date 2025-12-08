-- StarterPlayerScripts/UIBootstrapper.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
player.CharacterAdded:Wait() -- force replication to catch up

local PowerChangedEvent = ReplicatedStorage:WaitForChild("UIs"):WaitForChild("RemoteEvents"):WaitForChild("HeroUpdated")

local UIManager = require(ReplicatedStorage.Shared.Modules:WaitForChild("UIManager"))
local GetHeroData = ReplicatedStorage.UIs.RemoteEvents:WaitForChild("GetHeroData")

-- Helper function to load all UI
local function loadAllUI()
	local playerGui = player:WaitForChild("PlayerGui")
	local heroData = GetHeroData:InvokeServer()
	local specialty = heroData.Specialty
	local race = heroData.Race
	local hero = heroData.Hero

	UIManager.LoadUI(playerGui, specialty or "None", race, hero)
end

-- Load UI once when game starts
--loadAllUI()

-- Also detect if the player's specialty changes (in case it updates mid-session)
-- 🔥 Run when server signals a power change
PowerChangedEvent.OnClientEvent:Connect(function(fieldName, newValue)
	print("Power updated:", fieldName, "=", newValue)
	loadAllUI()
end)

player.CharacterAdded:Connect(function()
	task.defer(loadAllUI)
end)
