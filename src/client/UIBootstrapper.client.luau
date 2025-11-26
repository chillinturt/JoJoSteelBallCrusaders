-- StarterPlayerScripts/UIBootstrapper.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
player.CharacterAdded:Wait() -- force replication to catch up

local powersFolder = player:WaitForChild("Powers")
if not powersFolder then
	warn("⚠ NuclearRain: Powers folder missing for player", player.Name)
	return
end
local UIManager = require(ReplicatedStorage.Shared.Modules:WaitForChild("UIManager"))

-- Helper function to load all UI
local function loadAllUI()
	local playerGui = player:WaitForChild("PlayerGui")
	local specialty = powersFolder:FindFirstChild("Specialty") and powersFolder.Specialty.Value or nil
	local race = powersFolder:WaitForChild("Race") and powersFolder.Race.Value or nil
	local hero = powersFolder:WaitForChild("Hero") and powersFolder.Hero.Value or nil

	UIManager.LoadUI(playerGui, specialty or "", race, hero)
end

-- Load UI once when game starts
--loadAllUI()

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

if powersFolder:FindFirstChild("Hero") then
	powersFolder.Hero.Changed:Connect(function()
		loadAllUI()
	end)
end

player.CharacterAdded:Connect(function()
	task.defer(loadAllUI)
end)
