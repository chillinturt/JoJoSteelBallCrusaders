local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BarrageEvent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("StandBarrageToggle")

-- ===== CONFIG =====
local BUFFER_DURATION = 30 -- How long to hold a buffered F input (reduce from 100s!)
local BUFFER_CHECK_RATE = 0.05 -- How often to retry (in seconds)

-- ===== STATE =====
local isBarraging = false
local isTryingToBarrage = false
local bufferStartTime = 0
local bufferConnection = nil

-- === Core Functions ===
local function tryStartBarrage()
	if isBarraging then
		return true
	end

	if not isBarraging then
		isBarraging = true
		BarrageEvent:FireServer(true)
		print("✅ Barraging started")
		return true
	end

	return false
end

local function startBarragingBuffered()
	if isBarraging or isTryingToBarrage then
		return
	end

	isTryingToBarrage = true
	bufferStartTime = os.clock()

	-- Immediate attempt
	if tryStartBarrage() then
		isTryingToBarrage = false
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
			isTryingToBarrage = false
			print("⏳ Barrage buffer expired")
			return
		end

		if tryStartBarrage() then
			-- Success while buffered
			if bufferConnection then
				bufferConnection:Disconnect()
				bufferConnection = nil
			end
			isTryingToBarrage = false
		end
	end)
end

local function stopBarraging()
	-- Stop buffer safely
	if bufferConnection then
		bufferConnection:Disconnect()
		bufferConnection = nil
	end

	isTryingToBarrage = false

	if isBarraging then
		isBarraging = false
		BarrageEvent:FireServer(false)
		print("🛑 Barraging ended")
	end
end

-- === Input Hooks ===
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.E then
		startBarragingBuffered()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E then
		stopBarraging()
	end
end)
