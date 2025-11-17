local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIManager = {}

-- Folder references
local uiFolder = ReplicatedStorage:WaitForChild("UIs")
local defaultFolder = uiFolder:WaitForChild("DefaultUIs")
local specialtyFolder = uiFolder:WaitForChild("SpecialtyUIs")
local raceFolder = uiFolder:WaitForChild("RaceUIs")
local heroFolder = uiFolder:WaitForChild("HeroUIs")

-- Utility: safely clone a folder of UIs into PlayerGui
local function cloneUIsInto(playerGui, folder)
	for _, ui in ipairs(folder:GetChildren()) do
		if ui:IsA("ScreenGui") then
			local clone = ui:Clone()
			clone.Parent = playerGui
		end
	end
end

-- Clear all old specialty UIs but keep default ones
local function clearOldSpecialtyUIs(playerGui)
	for _, ui in ipairs(playerGui:GetChildren()) do
		if ui:IsA("ScreenGui") and not defaultFolder:FindFirstChild(ui.Name) then
			ui:Destroy()
		end
	end
end

-- Main function: load UIs
function UIManager.LoadUI(playerGui, specialty, race, hero)
	-- Step 1: Always ensure default UIs exist
	for _, defaultUI in ipairs(defaultFolder:GetChildren()) do
		if not playerGui:FindFirstChild(defaultUI.Name) then
			local clone = defaultUI:Clone()
			clone.Parent = playerGui
			print("✅ Loaded default UI:", defaultUI.Name)
		end
	end

	-- Step 2: Clear old specialty UIs
	clearOldSpecialtyUIs(playerGui)

	-- Step 3: Load specialty UI
	if specialty ~= "" then
		local specUI = specialtyFolder:FindFirstChild(specialty .. "UI")
		if specUI then
			local clone = specUI:Clone()
			clone.Parent = playerGui
			print("✅ Loaded specialty UI for", specialty)
		else
			warn("⚠️ No UI found for specialty:", specialty)
		end

		local specCooldownUI = specialtyFolder:FindFirstChild("SpecCooldownUI")
		if specCooldownUI then
			local clone = specCooldownUI:Clone()
			clone.Parent = playerGui
			print("✅ Given player a spec cooldown UI")
		else
			print("No spec cooldown UI found")
		end
	end

	-- Step 4: Load race UI
	if race ~= "Human" then
		local raceUI = raceFolder:FindFirstChild(race .. "UI")
		if raceUI then
			local clone = raceUI:Clone()
			clone.Parent = playerGui
			print("✅ Loaded race UI for", race)
		else
			print("⚠️ No UI found for race:", race)
		end
	end

	-- Step 5: Load hero UI
	if hero and hero ~= "" then
		local heroUI = heroFolder:FindFirstChild(hero .. "UI")
		if heroUI then
			local clone = heroUI:Clone()
			clone.Parent = playerGui
			print("✅ Loaded hero UI for", hero)
		else
			print("⚠️ No UI found for hero:", hero)
		end
	end
end

return UIManager
