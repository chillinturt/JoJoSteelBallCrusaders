-- ForceShiftLockKey.client.lua
-- Ensures MouseLockController BoundKeys always uses LeftAlt

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local DESIRED_KEY = "LeftAlt"

-- Utility: wait for deep descendant chain safely
local function waitForDescendant(parent, pathArray)
	local current = parent
	for _, name in ipairs(pathArray) do
		current = current:WaitForChild(name)
	end
	return current
end

task.spawn(function()
	local success, boundKeys = pcall(function()
		return waitForDescendant(player, {
			"PlayerScripts",
			"PlayerModule",
			"CameraModule",
			"MouseLockController",
			"BoundKeys",
		})
	end)

	if success and boundKeys and boundKeys:IsA("StringValue") then
		boundKeys.Value = DESIRED_KEY
		--print("[ForceShiftLockKey] BoundKeys set to", DESIRED_KEY)

		-- Optional: ensure it never resets to something else
		boundKeys:GetPropertyChangedSignal("Value"):Connect(function()
			if boundKeys.Value ~= DESIRED_KEY then
				warn("[ForceShiftLockKey] BoundKeys changed externally, resetting...")
				boundKeys.Value = DESIRED_KEY
			end
		end)
	else
		warn("[ForceShiftLockKey] Failed to locate BoundKeys.")
	end
end)
