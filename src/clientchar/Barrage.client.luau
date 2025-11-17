local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local barrageRemote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("StandBarrageToggle")

local isBarrageActive = false

-- Start Barrage
local function startBarrage()
	if not isBarrageActive then
		local ok, result = pcall(function()
			return barrageRemote:InvokeServer(true)
		end)

		if not ok then
			warn("Error while trying to start barrage:", result) -- <-- this will print the actual server error
			return
		end

		if result then
			isBarrageActive = true
			print("isBarrageActive set to true")
		else
			print("Barrage not available right now.")
		end
	else
		print("Barrage is active or on cooldown.")
	end
end

-- Stop Barrage
local function stopBarrage()
	if isBarrageActive then
		isBarrageActive = false
		barrageRemote:InvokeServer(false)
		print("stop barrage client")
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.E then
		--[[
		local canBlock = CanBlockFunction:InvokeServer()
		if not canBlock then
			warn("Blocking denied by server")
			return
		end
		]]

		startBarrage()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E then
		stopBarrage()
	end
end)
