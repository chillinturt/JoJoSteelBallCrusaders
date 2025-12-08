local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIManager = require(ReplicatedStorage.Shared:WaitForChild("Modules"):WaitForChild("UIManager"))
local GetHeroData = ReplicatedStorage.UIs.RemoteEvents:WaitForChild("GetHeroData")

local PowerChangedEvent = ReplicatedStorage:WaitForChild("UIs"):WaitForChild("RemoteEvents"):WaitForChild("HeroUpdated")

local player = Players.LocalPlayer
player.CharacterAdded:Wait() -- force replication to catch up

local playerGui = player:WaitForChild("PlayerGui")

local heroData = GetHeroData:InvokeServer()
local specialtyValue = heroData.Specialty
local raceValue = heroData.Race

-- Initial load (defaults + specialty)
UIManager.LoadUI(playerGui, specialtyValue.Value, raceValue.Value)

-- Reload when specialty changes
PowerChangedEvent.OnClientEvent:Connect(function(fieldName, newValue)
	local heroData = GetHeroData:InvokeServer()
	local specialtyValue = heroData.Specialty
	local raceValue = heroData.Race

	print("Power updated:", fieldName, "=", newValue)
	UIManager.LoadUI(playerGui, specialtyValue.Value, raceValue.Value)
end)
