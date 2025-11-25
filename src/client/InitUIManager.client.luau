local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIManager = require(ReplicatedStorage.Shared:WaitForChild("Modules"):WaitForChild("UIManager"))

local player = Players.LocalPlayer
local powersFolder = player:WaitForChild("Powers", 5)
if not powersFolder then
	warn("⚠ NuclearRain: Powers folder missing for player", player.Name)
	return
end
local playerGui = player:WaitForChild("PlayerGui")
local specialtyValue = powersFolder:WaitForChild("Specialty")
local raceValue = powersFolder:WaitForChild("Race")

-- Initial load (defaults + specialty)
UIManager.LoadUI(playerGui, specialtyValue.Value, raceValue.Value)

-- Reload when specialty changes
specialtyValue.Changed:Connect(function(newSpecialty)
	UIManager.LoadUI(playerGui, newSpecialty, raceValue.Value)
end)

raceValue.Changed:Connect(function(newRace)
	UIManager.LoadUI(playerGui, specialtyValue.Value, newRace)
end)
