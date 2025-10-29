local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SlideRemote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("SlideToggle")

-- ===== CONFIG =====
local BUFFER_DURATION = 1 -- seconds to keep trying (tune as desired)
local BUFFER_CHECK_RATE = 0.05 -- how often to retry (in seconds)

-- ===== STATE =====
local isSlideActive = false
local isTryingToSlide = false
local bufferStartTime = 0
local bufferConnection = nil

-- === Core Functions ===
local function tryStartSlide()
	if isSlideActive then
		return true
	end

	local success, result = pcall(function()
		return SlideRemote:InvokeServer(true)
	end)

	if success and result then
		isSlideActive = true
		print("✅ Slide started")
		return true
	else
		-- Server denied or failed to start slide
		print("⚠️ Slide not available right now")
		return false
	end
end

local function startSlideBuffered()
	if isSlideActive or isTryingToSlide then
		return
	end

	isTryingToSlide = true
	bufferStartTime = os.clock()

	-- Immediate attempt
	if tryStartSlide() then
		isTryingToSlide = false
		return
	end

	-- Start buffering
	bufferConnection = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - bufferStartTime > BUFFER_DURATION then
			-- Expired
			if bufferConnection then
				bufferConnection:Disconnect()
				bufferConnection = nil
			end
			isTryingToSlide = false
			print("⏳ Slide buffer expired")
			return
		end

		if tryStartSlide() then
			-- Success while buffered
			if bufferConnection then
				bufferConnection:Disconnect()
				bufferConnection = nil
			end
			isTryingToSlide = false
		end
	end)
end

local function stopSlide()
	-- Stop buffer safely
	if bufferConnection then
		bufferConnection:Disconnect()
		bufferConnection = nil
	end

	isTryingToSlide = false

	if isSlideActive then
		isSlideActive = false
		SlideRemote:InvokeServer(false)
		print("🛑 Slide stopped")
	end
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
