local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIManager = require(ReplicatedStorage.Shared:WaitForChild("Modules"):WaitForChild("UIManager"))
local UIController = require(ReplicatedStorage.Shared.Modules:WaitForChild("UIController"))
local GetHeroData = ReplicatedStorage.UIs.RemoteEvents:WaitForChild("GetHeroData")

local PowerChangedEvent = ReplicatedStorage:WaitForChild("UIs"):WaitForChild("RemoteEvents"):WaitForChild("HeroUpdated")

local player = Players.LocalPlayer
player.CharacterAdded:Wait() -- force replication to catch up

local playerGui = player:WaitForChild("PlayerGui")

local heroData = GetHeroData:InvokeServer()
local specialtyValue = heroData.Specialty
local raceValue = heroData.Race

local hasOpenedQuestlog = false

local function setupUIController(playerGui)
	-- Wait for UIs to exist (important because LoadUI just cloned them)
	local menu = playerGui:WaitForChild("MenuUI"):WaitForChild("Menu")
	local talent = playerGui:WaitForChild("TalentUI"):WaitForChild("TalentFrame")
	local settings = playerGui:WaitForChild("SettingsGUI"):WaitForChild("SettingsWindow")
	local shop = playerGui:WaitForChild("StorageUI"):WaitForChild("CharacterStorageFrame") --temporarily replaced with storage
	local inventory = playerGui:WaitForChild("Inventory"):WaitForChild("Frame")
	local alliance = playerGui:WaitForChild("AllianceGui"):WaitForChild("Frame")
	local questlog = playerGui:WaitForChild("QuestGUI"):WaitForChild("QuestLogFrame")
	local robux = playerGui:WaitForChild("Robux"):WaitForChild("Frame")

	-- Clear previous registrations (optional but safer)
	UIController.Reset()

	-- Register everything fresh
	UIController.Register("Menu", menu, UDim2.new(0, 0, 0, 0), UDim2.new(-1, 0, 0, 0))
	UIController.Register("Talent", talent, UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, 1.5, 0))
	UIController.Register("Settings", settings, UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, 1.5, 0))
	UIController.Register("Shop", shop, UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, 1.5, 0))
	UIController.Register("Inventory", inventory, UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, 1.5, 0))
	UIController.Register("Alliance", alliance, UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, 1.5, 0))
	UIController.Register("Questlog", questlog, UDim2.new(0.87, 0, 0.5, 0), UDim2.new(1.13, 0, 0.5, 0))
	UIController.Register("Robux", robux, UDim2.new(0.87, 0, 0.5, 0), UDim2.new(1, 0, 0.5, 0))

	-- Open questlog when player first joins
	if not hasOpenedQuestlog then
		hasOpenedQuestlog = true

		task.delay(5, function()
			print("Opening Questlog")
			UIController.Open("Questlog")
		end)
	end
end

-- Initial load (defaults + specialty)
UIManager.LoadUI(playerGui, specialtyValue, raceValue)
setupUIController(playerGui)

-- Reload when specialty changes
PowerChangedEvent.OnClientEvent:Connect(function(fieldName, newValue)
	local heroData = GetHeroData:InvokeServer()
	local specialtyValue = heroData.Specialty
	local raceValue = heroData.Race
	local heroValue = heroData.Hero

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	UIManager.LoadUI(playerGui, specialtyValue, raceValue, heroValue)
	setupUIController(playerGui)
end)
