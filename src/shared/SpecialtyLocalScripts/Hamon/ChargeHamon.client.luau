local UserInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local HamonChargeEvent = replicatedStorage.Shared.BasicCombat.Hamon:WaitForChild("ChargeHamonToggle")
local CanBlockFunction = replicatedStorage.Shared.BasicCombat:WaitForChild("CanBlockFunction")

local isChargeActive = false
local canCharge = true
local chargeCooldown = 1 -- seconds

-- Start Charge
local function StartCharge()
	if canCharge and not isChargeActive then
		local success = HamonChargeEvent:InvokeServer(true) -- Ask server: can we Charge?
		if success then
			isChargeActive = true
		else
			print("Charge not available right now. ")
			print(isChargeActive)
		end
	else
		print("Charge is active or on cooldown.")
	end
end

-- Stop Charge
local function stopCharge()
	if isChargeActive then
		isChargeActive = false
		HamonChargeEvent:InvokeServer(false)

		canCharge = false
		task.delay(chargeCooldown, function()
			canCharge = true
		end)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.G then
		local canBlock = CanBlockFunction:InvokeServer()
		if not canBlock then
			warn("Blocking denied by server")
			return
		end

		StartCharge()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.G then
		stopCharge()
	end
end)
