-- StarterPlayerScripts/UIBootstrapper.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local powersFolder = player:WaitForChild("Powers")
local UIManager = require(ReplicatedStorage.Shared.Modules:WaitForChild("UIManager"))

-- Helper function to load all UI
local function loadAllUI()
	local playerGui = player:WaitForChild("PlayerGui")
	local specialty = powersFolder:FindFirstChild("Specialty") and powersFolder.Specialty.Value or nil
	local race = powersFolder:WaitForChild("Race") and powersFolder.Race.Value or nil

	UIManager.LoadUI(playerGui, specialty or "", race)
end

-- Load UI once when game starts
loadAllUI()

-- Reload UI when the player respawns (CharacterAdded fires on each respawn)
player.CharacterAdded:Connect(function()
	-- Wait for PlayerGui to reset
	task.wait(0.5)
	loadAllUI()
end)

-- Also detect if the player's specialty changes (in case it updates mid-session)
if powersFolder:FindFirstChild("Specialty") then
	powersFolder.Specialty.Changed:Connect(function()
		loadAllUI()
	end)
end

if powersFolder:FindFirstChild("Race") then
	powersFolder.Race.Changed:Connect(function()
		loadAllUI()
	end)
end

player.CharacterAdded:Connect(function()
	task.defer(loadAllUI)
end)
