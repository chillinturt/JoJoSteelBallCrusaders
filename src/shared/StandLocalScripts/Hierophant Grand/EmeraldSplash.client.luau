local UserInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local splashRemote = replicatedStorage.Shared.BasicCombat.HierophantGrand:WaitForChild("EmeraldSplashToggle")
local CanBlockFunction = replicatedStorage.Shared.BasicCombat:WaitForChild("CanBlockFunction")

local isSplashActive = false
local splashCooldown = 8 -- seconds

--Start splash
local function startSplash()
	if not isSplashActive then
		local success = splashRemote:InvokeServer(true) -- Ask server: can we splash?
		if success then
			isSplashActive = true
		else
			print("splash not available right now. ")
			print(isSplashActive)
		end
	else
		print("splash is active or on cooldown.")
	end
end

-- Stop splash
local function stopSplash()
	if isSplashActive then
		isSplashActive = false
		splashRemote:InvokeServer(false)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.R then
		local canBlock = CanBlockFunction:InvokeServer()
		if not canBlock then
			warn("Blocking denied by server")
			return
		end

		startSplash()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.R then
		stopSplash()
	end
end)

--[[Start splash
local function startSplash()
	if CanSplash and not isSplashActive then
		local success = splashRemote:InvokeServer(true) -- Ask server: can we splash?
		if success then
			isSplashActive = true
		else
			print("splash not available right now. ")
			print(isSplashActive)
		end
	else
		print("splash is active or on cooldown.")
	end
end

-- Stop splash
local function stopSplash()
	if isSplashActive then
		isSplashActive = false
		splashRemote:InvokeServer(false)

		CanSplash = false
		task.delay(splashCooldown, function()
			CanSplash = true
		end)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.R then
		local canBlock = CanBlockFunction:InvokeServer()
		if not canBlock then
			warn("Blocking denied by server")
			return
		end

		startSplash()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.R then
		stopSplash()
	end
end)
]]
