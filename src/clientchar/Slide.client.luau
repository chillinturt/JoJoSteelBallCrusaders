local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SlideRemote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("SlideToggle")

local isSlideActive = false

-- Start Slide
local function startSlide()
	if not isSlideActive then
		local success = SlideRemote:InvokeServer(true) -- Ask server: can we Slide?
		if success then
			isSlideActive = true
			print("isSlideActive set to true")
		else
			print("Slide not available right now. ")
			print(isSlideActive)
		end
	else
		print("Slide is active or on cooldown.")
	end
end

-- Stop Slide
local function stopSlide()
	if isSlideActive then
		isSlideActive = false
		SlideRemote:InvokeServer(false)
		print("stop Slide client")
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftControl then
		--[[
		local canBlock = CanBlockFunction:InvokeServer()
		if not canBlock then
			warn("Blocking denied by server")
			return
		end
		]]

		startSlide()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftControl then
		stopSlide()
	end
end)
