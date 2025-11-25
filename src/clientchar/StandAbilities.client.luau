--=====================================================
--  Stand Ability Local Handler (Unified)
--=====================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Remote used to trigger abilities
local AbilityEvent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("StandAbilityEvent")

--------------------------------------------------------
-- CONFIGURE KEYBINDS FOR ABILITIES (change as needed)
--------------------------------------------------------
local Keybinds = {
	[Enum.KeyCode.T] = 1, -- Ability 1
	[Enum.KeyCode.R] = 2, -- Ability 2
	[Enum.KeyCode.Z] = 3, -- Ability 3
	[Enum.KeyCode.X] = 4, -- Ability 4
}

--------------------------------------------------------
-- KEYBOARD HANDLER
--------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	local abilityId = Keybinds[input.KeyCode]
	if abilityId then
		AbilityEvent:FireServer(abilityId)
	end
end)

--------------------------------------------------------
-- MOBILE UI SUPPORT (if mobile UI exists)
--------------------------------------------------------
local function hookMobileButtons()
	local gui = player:WaitForChild("PlayerGui")
	local screenGui = gui:WaitForChild("MobileAbilityUI", 5)

	if not screenGui then
		warn("[AbilityClient] No mobile UI found")
		return
	end

	local frame = screenGui:WaitForChild("AbilitiesFrame")

	-- Button → AbilityID mapping
	local buttonMap = {
		["Ability1ButtonFrame"] = 1,
		["Ability2ButtonFrame"] = 2,
		["Ability3ButtonFrame"] = 3,
		["Ability4ButtonFrame"] = 4,
	}

	for buttonName, id in pairs(buttonMap) do
		local button = frame:FindFirstChild(buttonName)
		if button then
			button.MouseButton1Click:Connect(function()
				AbilityEvent:FireServer(id)
			end)
		end
	end

	print("[AbilityClient] Mobile buttons linked.")
end

-- Wait a moment for UI load
task.defer(hookMobileButtons)
