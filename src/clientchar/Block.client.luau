local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local blockEvent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("BlockEvent")
local CanBlockFunction = ReplicatedStorage.Shared.BasicCombat:WaitForChild("CanBlockFunction")

-- ===== CONFIG =====
local BUFFER_DURATION = 30 -- How long to hold a buffered F input (reduce from 100s!)
local BUFFER_CHECK_RATE = 0.05 -- How often to retry (in seconds)

-- ===== STATE =====
local isBlocking = false
local isTryingToBlock = false
local bufferStartTime = 0
local bufferConnection = nil

-- === Core Functions ===
local function tryStartBlock()
	if isBlocking then
		return true
	end

	local canBlock = false
	local success, result = pcall(function()
		return CanBlockFunction:InvokeServer()
	end)
	if success then
		canBlock = result
	else
		warn("❌ Failed to invoke CanBlockFunction:", result)
		return false
	end

	if canBlock then
		isBlocking = true
		blockEvent:FireServer(true)
		print("✅ Blocking started")
		return true
	end

	return false
end

local function startBlockingBuffered()
	if isBlocking or isTryingToBlock then
		return
	end

	isTryingToBlock = true
	bufferStartTime = os.clock()

	-- Immediate attempt
	if tryStartBlock() then
		isTryingToBlock = false
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
			isTryingToBlock = false
			print("⏳ Block buffer expired")
			return
		end

		if tryStartBlock() then
			-- Success while buffered
			if bufferConnection then
				bufferConnection:Disconnect()
				bufferConnection = nil
			end
			isTryingToBlock = false
		end
	end)
end

local function stopBlocking()
	-- Stop buffer safely
	if bufferConnection then
		bufferConnection:Disconnect()
		bufferConnection = nil
	end

	isTryingToBlock = false

	if isBlocking then
		isBlocking = false
		blockEvent:FireServer(false)
		print("🛑 Blocking ended")
	end
end

-- === Input Hooks ===
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		startBlockingBuffered()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F then
		stopBlocking()
	end
end)
