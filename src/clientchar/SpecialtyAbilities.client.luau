--=====================================================
-- Specialty Ability Local Handler
--=====================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-----------------------------------------------------------------------
-- Remotes
-----------------------------------------------------------------------
local AbilityFunction = ReplicatedStorage.Shared.BasicCombat:WaitForChild("SpecialtyAbilityFunction")
local AbilityTypesRemote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("SpecialtyAbilityTypes")

-- Updated whenever the player equips a Specialty
local CurrentAbilityTypes = {}
local AbilitiesReady = false

AbilityTypesRemote.OnClientEvent:Connect(function(abilityTypes)
	CurrentAbilityTypes = abilityTypes or {}
	AbilitiesReady = true
	print("[Client] Received ability types:", abilityTypes)
end)

-----------------------------------------------------------------------
-- Keybind → AbilityID mapping
-----------------------------------------------------------------------
local Keybinds = {
	[Enum.KeyCode.C] = 1,
	[Enum.KeyCode.V] = 2,
	[Enum.KeyCode.B] = 3,
	[Enum.KeyCode.N] = 4,
}

-----------------------------------------------------------------------
-- SEND ABILITY REQUEST TO SERVER
-----------------------------------------------------------------------
local function FireAbility(abilityId, state)
	if not AbilitiesReady then
		warn("[Client] Tried to use ability before types were received:", abilityId)
		return
	end
	if not abilityId or not CurrentAbilityTypes[abilityId] then
		warn("[Client] AbilityId invalid or not registered:", abilityId)
		return
	end

	local success, err = pcall(function()
		AbilityFunction:InvokeServer(abilityId, state)
	end)
	if not success then
		warn("[Client] AbilityFunction InvokeServer failed:", err)
	end
end

-----------------------------------------------------------------------
-- Unified input handlers
-----------------------------------------------------------------------
local function handleInputBegan(abilityId)
	print("handle input begins...")
	local abilityType = CurrentAbilityTypes[abilityId]
	if not abilityType then
		print("no ability type found")
		return
	end

	if abilityType == "Press" then
		FireAbility(abilityId, nil)
		print("Press ability fired from client")
	elseif abilityType == "Toggle" then
		FireAbility(abilityId, "Toggle")
		print("Toggle ability fired from client")
	elseif abilityType == "Hold" then
		FireAbility(abilityId, "Start")
		print("Hold ability fired from client")
	end
end

local function handleInputEnded(abilityId)
	local abilityType = CurrentAbilityTypes[abilityId]
	if abilityType == "Hold" then
		FireAbility(abilityId, "Stop")
	end
end

-----------------------------------------------------------------------
-- Keyboard Input
-----------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	local abilityId = Keybinds[input.KeyCode]
	if abilityId then
		handleInputBegan(abilityId)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	local abilityId = Keybinds[input.KeyCode]
	if abilityId then
		handleInputEnded(abilityId)
	end
end)

-----------------------------------------------------------------------
-- Mobile UI Support
-----------------------------------------------------------------------
local function hookMobileButtons()
	local gui = player:WaitForChild("PlayerGui")
	local screenGui = gui:WaitForChild("MobileSpecialtyAbilitiesGUI") -- no timeout
	if not screenGui then
		return
	end

	local frame = screenGui:WaitForChild("AbilitiesFrame")
	local buttonMap = {
		["Ability1ButtonFrame"] = 1,
		["Ability2ButtonFrame"] = 2,
		["Ability3ButtonFrame"] = 3,
		["Ability4ButtonFrame"] = 4,
	}

	for frameName, abilityId in pairs(buttonMap) do
		local holderFrame = frame:FindFirstChild(frameName)
		if not holderFrame then
			warn("[Mobile] Missing frame:", frameName)
			continue
		end

		-- find the actual button inside the frame
		local button = holderFrame:FindFirstChildWhichIsA("ImageButton")
			or holderFrame:FindFirstChildWhichIsA("TextButton")

		if not button then
			warn("[Mobile] No button found inside:", frameName)
			continue
		end

		-- Press / Tap
		button.MouseButton1Down:Connect(function()
			handleInputBegan(abilityId)
		end)

		-- Release (for Hold abilities)
		button.MouseButton1Up:Connect(function()
			handleInputEnded(abilityId)
		end)

		-- Optional: support Activated for mobile reliability
		button.Activated:Connect(function()
			if CurrentAbilityTypes[abilityId] ~= "Hold" then
				handleInputBegan(abilityId)
			end
		end)
	end
end

task.defer(hookMobileButtons)
