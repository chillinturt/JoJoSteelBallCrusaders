-- CustomShiftLock.lua
-- Proper custom ShiftLock bound to Tab, preserves default Roblox camera.
-- Rotates character to camera direction and offsets camera slightly to the right.

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local shiftLockEnabled = false

-- Disable Roblox’s default ShiftLock
StarterPlayer.EnableMouseLockOption = false

script.Parent
	:WaitForChild("PlayerModule")
	:WaitForChild("CameraModule")
	:WaitForChild("MouseLockController")
	:WaitForChild("BoundKeys").Value =
	"Tab"

-- Safely call SetCore
local function safeSetCore(name, value)
	local success = false
	repeat
		success = pcall(function()
			StarterGui:SetCore(name, value)
		end)
		if not success then
			task.wait(0.1)
		end
	until success
end

-- Hide top bar (optional)
task.spawn(function()
	safeSetCore("TopbarEnabled", false)
end)

-- Camera offset config
local CAMERA_OFFSET = Vector3.new(1.75, 0, 0) -- right offset like default shiftlock

-- Enable/disable ShiftLock
local function setShiftLock(state)
	if state then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
	shiftLockEnabled = state
	print("Shift Lock is now", state and "ON" or "OFF")
end

--[[Apply rotation and camera offset
RunService.RenderStepped:Connect(function()
	if not shiftLockEnabled then
		return
	end

	local character = player.Character
	local camera = Workspace.CurrentCamera
	if not (character and camera) then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	-- Instantly rotate player toward the camera's horizontal direction
	local camLook = camera.CFrame.LookVector
	local flatLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
	root.CFrame = CFrame.lookAt(root.Position, root.Position + flatLook)

	-- Apply right offset (locally to camera)
	local camCF = camera.CFrame
	local offsetCF = camCF * CFrame.new(CAMERA_OFFSET)
	camera.CFrame = CFrame.lookAt(offsetCF.Position, offsetCF.Position + camCF.LookVector)
end)
]]
-- Handle Tab toggle
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Tab then
		setShiftLock(not shiftLockEnabled)

		-- Prevent Tab from opening player list
		safeSetCore("PlayerListVisible", false)
	end

	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		-- Do nothing: block ShiftLock toggle
		print("Shift key pressed: default ShiftLock disabled")
	end
end)
