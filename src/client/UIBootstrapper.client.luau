-- StarterPlayerScripts/UIBootstrapper.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Remote references
local uiFolder = ReplicatedStorage:WaitForChild("UIs")
local remoteFolder = uiFolder:WaitForChild("RemoteEvents")

local PowerChangedEvent = remoteFolder:WaitForChild("HeroUpdated")
local GetHeroData = remoteFolder:WaitForChild("GetHeroData")

-- Modules
local UIManager = require(ReplicatedStorage.Shared.Modules:WaitForChild("UIManager"))
local UIController = require(ReplicatedStorage.Shared.Modules:WaitForChild("UIController"))

local function setupUIController(playerGui)
	UIController.Reset() -- clear old references

	-- Menu
	local menuUI = playerGui:FindFirstChild("MenuUI")
	if menuUI then
		local menu = menuUI:FindFirstChild("Menu")
		if menu then
			UIController.Register("Menu", menu, UDim2.new(0, 0, 0, 0), UDim2.new(-1, 0, 0, 0))
		end
	end

	-- Talent
	local talentUI = playerGui:FindFirstChild("TalentUI")
	if talentUI then
		local frame = talentUI:FindFirstChild("TalentFrame")
		if frame then
			UIController.Register("Talent", frame, UDim2.new(0.5, 0, 0.5, -0), UDim2.new(0.5, 0, 1.5, 0))
		end
	end

	-- Settings
	local settingsUI = playerGui:FindFirstChild("SettingsGUI")
	if settingsUI then
		local frame = settingsUI:FindFirstChild("SettingsWindow")
		if frame then
			UIController.Register("Settings", frame, UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, 1.5, 0))
		end
	end

	-- Shop
	local shopUI = playerGui:WaitForChild("StorageUI")
	if shopUI then
		local frame = shopUI:WaitForChild("CharacterStorageFrame")
		if frame then
			UIController.Register("Shop", frame, UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, 1.5, 0))
		end
	end

	local inventory = playerGui:WaitForChild("Inventory")
	if inventory then
		local frame = inventory:WaitForChild("Frame")
		if frame then
			UIController.Register("Inventory", frame, UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, 1.5, 0))
		end
	end

	local alliance = playerGui:WaitForChild("AllianceGui")
	if alliance then
		local frame = alliance:WaitForChild("Frame")
		if frame then
			UIController.Register("Alliance", frame, UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, 1.5, 0))
		end
	end

	local questlog = playerGui:WaitForChild("QuestGUI")
	if questlog then
		local frame = questlog:WaitForChild("QuestLogFrame")
		if frame then
			UIController.Register("Questlog", frame, UDim2.new(0.87, 0, 0.5, 0), UDim2.new(1.5, 0, 0.5, 0))
		end
	end
end

----------------------------------------------------------
-- 🟢 Load base UI immediately (NO DATA REQUIRED)
----------------------------------------------------------
local function loadBaseUI()
	local playerGui = player:WaitForChild("PlayerGui")

	-- Load with empty/default values so UI ALWAYS exists
	UIManager.LoadUI(playerGui, nil, nil, nil)
	setupUIController(playerGui)
end

----------------------------------------------------------
-- 🟡 Load data-driven UI (SAFE + RETRY)
----------------------------------------------------------
local function loadDataUI()
	local playerGui = player:WaitForChild("PlayerGui")

	local success, heroData

	-- Retry system (handles server delay / profile loading)
	for attempt = 1, 10 do
		success, heroData = pcall(function()
			return GetHeroData:InvokeServer()
		end)

		if success and heroData then
			break
		end

		task.wait(0.5)
	end

	if not heroData then
		warn("❌ UI Bootstrapper: Failed to get hero data after retries")
		return
	end

	-- Apply real data to UI
	UIManager.LoadUI(playerGui, heroData.Specialty or "None", heroData.Race, heroData.Hero)
	setupUIController(playerGui)
end

----------------------------------------------------------
-- 🔵 Full UI load sequence
----------------------------------------------------------
local function loadAllUI()
	-- Step 1: ALWAYS load base UI instantly
	loadBaseUI()

	-- Step 2: Then safely load real data UI
	loadDataUI()
end

----------------------------------------------------------
-- 🟣 Character spawn handling (SAFE)
----------------------------------------------------------
local function onCharacterAdded()
	-- Defer to next frame to avoid replication timing issues
	task.defer(loadAllUI)
end

-- Handle existing character (important fix)
if player.Character then
	onCharacterAdded()
end

-- Handle respawns
player.CharacterAdded:Connect(onCharacterAdded)

----------------------------------------------------------
-- 🟠 Live updates (power / hero changes)
----------------------------------------------------------
PowerChangedEvent.OnClientEvent:Connect(function()
	-- Reload ONLY data-driven UI (base already exists)
	loadDataUI()
end)
