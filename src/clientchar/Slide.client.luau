local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SlideRemote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("SlideToggle")

local isTryingToSlide = false
local bufferEnd = 0

local BUFFER_DURATION = 1
local BUFFER_RATE = 0.05

local function trySlide()
	SlideRemote:FireServer("Begin")
end

local function startSlideBuffered()
	if isTryingToSlide then
		return
	end

	isTryingToSlide = true
	bufferEnd = os.clock() + BUFFER_DURATION

	trySlide() -- immediate attempt

	task.spawn(function()
		while isTryingToSlide and os.clock() < bufferEnd do
			task.wait(BUFFER_RATE)
			trySlide()
		end
		isTryingToSlide = false
	end)
end

local function stopSlide()
	isTryingToSlide = false
	SlideRemote:FireServer("End")
end

-- === Input Hooks ===
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftControl then
		startSlideBuffered()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftControl then
		stopSlide()
	end
end)
