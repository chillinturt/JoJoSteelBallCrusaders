local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Remote setup
local MantleEvent = ReplicatedStorage.Shared.Movement:WaitForChild("MantleEvent")
local CanMantleFunction = ReplicatedStorage.Shared.Movement:WaitForChild("CanMantleFunction")

-- ===== CONFIG =====
local BUFFER_DURATION = 1.0 -- seconds to hold the buffered space input
local BUFFER_CHECK_RATE = 0.05 -- retry rate (seconds)

-- ===== STATE =====
local isMantling = false
local isTryingToMantle = false
local bufferStartTime = 0
local bufferConnection = nil

-- === Core Functions ===
local function tryStartMantle()
	if isMantling then
		return true
	end

	local canMantle = false
	local success, result = pcall(function()
		return CanMantleFunction:InvokeServer()
	end)
	if success then
		canMantle = result
	else
		warn("❌ Failed to invoke CanMantleFunction:", result)
		return false
	end

	if canMantle then
		isMantling = true
		MantleEvent:FireServer(true)
		print("✅ Mantle started")
		return true
	end

	return false
end

local function startMantleBuffered()
	if isMantling or isTryingToMantle then
		return
	end

	isTryingToMantle = true
	bufferStartTime = os.clock()

	-- Try immediately
	if tryStartMantle() then
		isTryingToMantle = false
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
			isTryingToMantle = false
			print("⏳ Mantle buffer expired")
			return
		end

		if tryStartMantle() then
			if bufferConnection then
				bufferConnection:Disconnect()
				bufferConnection = nil
			end
			isTryingToMantle = false
		end
	end)
end

local function stopMantle()
	-- stop buffer safely
	if bufferConnection then
		bufferConnection:Disconnect()
		bufferConnection = nil
	end

	isTryingToMantle = false

	if isMantling then
		isMantling = false
		MantleEvent:FireServer(false)
		print("🛑 Mantle ended")
	end
end

-- === Input Hooks ===
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Space then
		startMantleBuffered()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space then
		stopMantle()
	end
end)
