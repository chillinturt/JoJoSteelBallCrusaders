local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local blockEvent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("BlockEvent")
local CanBlockFunction = ReplicatedStorage.Shared.BasicCombat:WaitForChild("CanBlockFunction")

local isBlocking = false

-- Function to start blocking
local function startBlocking()
	if not isBlocking then
		local canBlock = CanBlockFunction:InvokeServer()
		if not canBlock then
			warn("Blocking denied by server")
			return
		end

		isBlocking = true
		blockEvent:FireServer(true) -- ✅ send true to server (start)
		print("Blocking started")
	end
end

-- Function to stop blocking
local function stopBlocking()
	if isBlocking then
		isBlocking = false
		blockEvent:FireServer(false) -- ✅ send false to server (stop)
		print("Blocking ended")
	end
end

-- Detect key press (F key)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		startBlocking()
	end
end)

-- Detect key release (Stop blocking)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F then
		stopBlocking()
	end
end)
