local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SunlightYellowRemote = ReplicatedStorage.Shared.BasicCombat.Hamon:WaitForChild("SunlightYellowToggle")

local isSunlightYellowActive = false

-- Start SunlightYellow
local function startSunlightYellow()
	if not isSunlightYellowActive then
		local success = SunlightYellowRemote:InvokeServer(true) -- Ask server: can we SunlightYellow?
		if success then
			isSunlightYellowActive = true
			print("isSunlightYellowActive set to true")
		else
			print("SunlightYellow not available right now. ")
			print(isSunlightYellowActive)
		end
	else
		print("SunlightYellow is active or on cooldown.")
	end
end

-- Stop SunlightYellow
local function stopSunlightYellow()
	if isSunlightYellowActive then
		isSunlightYellowActive = false
		SunlightYellowRemote:InvokeServer(false)
		print("stop SunlightYellow client")
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.C then
		--[[
		local canBlock = CanBlockFunction:InvokeServer()
		if not canBlock then
			warn("Blocking denied by server")
			return
		end
		]]

		startSunlightYellow()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.C then
		stopSunlightYellow()
	end
end)
