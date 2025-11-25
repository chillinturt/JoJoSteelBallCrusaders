local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local UIManager = {}

-- DEBUG: Force mobile UI in Studio for testing
local FORCE_MOBILE_IN_STUDIO = false

-- UI folders in ReplicatedStorage
local uiFolder = ReplicatedStorage:WaitForChild("UIs")
local defaultFolder = uiFolder:WaitForChild("DefaultUIs")
local specialtyFolder = uiFolder:WaitForChild("SpecialtyUIs")
local raceFolder = uiFolder:WaitForChild("RaceUIs")
local heroFolder = uiFolder:WaitForChild("HeroUIs")
local mobileFolder = uiFolder:WaitForChild("MobileUIs")

-- Roblox protected UIs that should never be deleted
local ROBLOX_PROTECTED_UIS = {
	["TouchGui"] = true,
	["Chat"] = true,
}

----------------------------------------------------------
-- Utility: Clone all ScreenGuis in a folder into PlayerGui
----------------------------------------------------------
local function cloneFolderUIs(folder, playerGui)
	for _, ui in ipairs(folder:GetChildren()) do
		if ui:IsA("ScreenGui") and not playerGui:FindFirstChild(ui.Name) then
			ui:Clone().Parent = playerGui
		end
	end
end

----------------------------------------------------------
-- Remove all non-default, non-protected UIs
----------------------------------------------------------
local function clearNonDefaultUIs(playerGui)
	for _, ui in ipairs(playerGui:GetChildren()) do
		if ui:IsA("ScreenGui") then
			if
				not ROBLOX_PROTECTED_UIS[ui.Name]
				and not defaultFolder:FindFirstChild(ui.Name)
				and not mobileFolder:FindFirstChild(ui.Name)
			then
				ui:Destroy()
			end
		end
	end
end

----------------------------------------------------------
-- Ensure Default UIs Are Loaded
----------------------------------------------------------
local function ensureDefaultUIs(playerGui)
	cloneFolderUIs(defaultFolder, playerGui)
end

----------------------------------------------------------
-- Load Specialty UI
----------------------------------------------------------
local function loadSpecialtyUI(playerGui, specialty)
	if specialty == "" then
		return
	end

	local ui = specialtyFolder:FindFirstChild(specialty .. "UI")
	if ui then
		ui:Clone().Parent = playerGui
	end

	local cooldownUI = specialtyFolder:FindFirstChild("SpecCooldownUI")
	if cooldownUI then
		cooldownUI:Clone().Parent = playerGui
	end
end

----------------------------------------------------------
-- Load Race UI
----------------------------------------------------------
local function loadRaceUI(playerGui, race)
	if race == "Human" then
		return
	end

	local raceUI = raceFolder:FindFirstChild(race .. "UI")
	if raceUI then
		raceUI:Clone().Parent = playerGui
	end
end

----------------------------------------------------------
-- Load Hero UI
----------------------------------------------------------
local function loadHeroUI(playerGui, hero)
	if not hero or hero == "" then
		return
	end

	local heroUI = heroFolder:FindFirstChild(hero .. "UI")
	if heroUI then
		heroUI:Clone().Parent = playerGui
	end
end

----------------------------------------------------------
-- Load Mobile UI (waits until UserInputService is ready)
----------------------------------------------------------
local function loadMobileUI(playerGui)
	local isMobile = FORCE_MOBILE_IN_STUDIO or UserInputService.TouchEnabled

	if not isMobile then
		return
	end

	print("[UIManager] Loading mobile UIs...")
	for _, ui in ipairs(mobileFolder:GetChildren()) do
		if ui:IsA("ScreenGui") and not playerGui:FindFirstChild(ui.Name) then
			ui:Clone().Parent = playerGui
		end
	end
end

----------------------------------------------------------
-- Public Function: Load All UI
----------------------------------------------------------
function UIManager.LoadUI(playerGui, specialty, race, hero)
	-- 1) Determine if this player is on mobile
	local isMobile = FORCE_MOBILE_IN_STUDIO or UserInputService.TouchEnabled

	-- 2) Protect mobile UI names first
	if isMobile then
		for _, ui in ipairs(mobileFolder:GetChildren()) do
			if ui:IsA("ScreenGui") then
				ROBLOX_PROTECTED_UIS[ui.Name] = true
			end
		end
	end

	-- 3) Load mobile UIs early (so they exist in PlayerGui before any cleanup)
	if isMobile then
		loadMobileUI(playerGui)
	end

	-- 4) Load default UIs
	ensureDefaultUIs(playerGui)

	-- 5) Clear old non-default UIs (mobile UIs are protected now)
	clearNonDefaultUIs(playerGui)

	-- 6) Load Specialty / Race / Hero
	loadSpecialtyUI(playerGui, specialty)
	loadRaceUI(playerGui, race)
	loadHeroUI(playerGui, hero)

	-- 7) Safety check for Roblox TouchGui
	if isMobile and not playerGui:FindFirstChild("TouchGui") then
		warn("⚠ TouchGui missing. Roblox should auto-regenerate it soon.")
	end
end

return UIManager
