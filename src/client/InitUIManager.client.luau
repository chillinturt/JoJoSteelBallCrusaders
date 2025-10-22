local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIManager = require(ReplicatedStorage.Shared:WaitForChild("Modules"):WaitForChild("UIManager"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local specialtyValue = player:WaitForChild("Specialty")

-- Initial load (defaults + specialty)
UIManager.LoadUI(playerGui, specialtyValue.Value)

-- Reload when specialty changes
specialtyValue.Changed:Connect(function(newSpecialty)
	UIManager.LoadUI(playerGui, newSpecialty)
end)
