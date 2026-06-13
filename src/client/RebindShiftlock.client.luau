-- ForceShiftLockKey.client.lua
-- Rebinds shift lock to LeftAlt + detects when player enables it

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local DESIRED_KEY = "LeftAlt"

local ShiftLockEvent = ReplicatedStorage:WaitForChild("QuestEvents"):WaitForChild("ShiftLockUsed")

--------------------------------------------------
-- Utility: wait for deep descendant safely
--------------------------------------------------
local function waitForDescendant(parent, pathArray)
	local current = parent
	for _, name in ipairs(pathArray) do
		current = current:WaitForChild(name)
	end
	return current
end

--------------------------------------------------
-- Main setup
--------------------------------------------------
task.spawn(function()
	local success, mouseLockController = pcall(function()
		return waitForDescendant(player, {
			"PlayerScripts",
			"PlayerModule",
			"CameraModule",
			"MouseLockController",
		})
	end)

	if not success or not mouseLockController then
		warn("[ShiftLock] Failed to find MouseLockController")
		return
	end

	local boundKeys = mouseLockController:WaitForChild("BoundKeys")

	--------------------------------------------------
	-- 🔒 Force LeftAlt as shift lock key
	--------------------------------------------------
	boundKeys.Value = DESIRED_KEY

	boundKeys:GetPropertyChangedSignal("Value"):Connect(function()
		if boundKeys.Value ~= DESIRED_KEY then
			warn("[ShiftLock] BoundKeys changed externally, resetting...")
			boundKeys.Value = DESIRED_KEY
		end
	end)

	--------------------------------------------------
	-- 🔥 Detect shift lock activation (REAL FIX)
	--------------------------------------------------
	local lastBehavior = UserInputService.MouseBehavior

	UserInputService:GetPropertyChangedSignal("MouseBehavior"):Connect(function()
		local newBehavior = UserInputService.MouseBehavior

		if newBehavior == Enum.MouseBehavior.LockCenter and lastBehavior ~= Enum.MouseBehavior.LockCenter then
			print("[ShiftLock] Shift lock ENABLED")
			ShiftLockEvent:FireServer()
		end

		lastBehavior = newBehavior
	end)
end)
