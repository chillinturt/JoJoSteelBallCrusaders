-- CustomShiftLock.lua
-- Binds ShiftLock toggle to Tab, disables default ShiftLock and Tab menu.
-- Adds right-side camera offset like the default Roblox ShiftLock.

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local shiftLockEnabled = false

-- Disable Roblox’s default Shift Lock
StarterPlayer.EnableMouseLockOption = false

-- Helper to safely call SetCore once CoreScripts are ready
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

-- Optional: Hide the top bar entirely (prevents Tab from opening player list)
task.spawn(function()
	safeSetCore("TopbarEnabled", false)
end)

-- Camera offset parameters
local CAMERA_OFFSET = Vector3.new(2, 0, 0) -- offset to the right
local CAMERA_DISTANCE = 8 -- how far the camera sits behind the player

-- Helper: Toggle ShiftLock manually
local function setShiftLock(state)
	if state then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
	shiftLockEnabled = state
	print("Shift Lock is now", shiftLockEnabled and "ON" or "OFF")
end

-- Continuously rotate the character and adjust camera while shiftlock is active
RunService.RenderStepped:Connect(function()
	local character = player.Character
	local camera = workspace.CurrentCamera

	if shiftLockEnabled and character and character:FindFirstChild("HumanoidRootPart") then
		local root = character.HumanoidRootPart
		local lookVector = camera.CFrame.LookVector
		local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z).Unit

		-- Instantly face the same direction as the camera
		root.CFrame = CFrame.lookAt(root.Position, root.Position + flatLook)

		-- Camera offset (right-shoulder third-person view)
		local camPos = root.Position - flatLook * CAMERA_DISTANCE + (camera.CFrame.RightVector * CAMERA_OFFSET.X)
		local camCFrame = CFrame.lookAt(camPos, root.Position + flatLook * 10)
		camera.CFrame = camCFrame
	end
end)

-- Input handling
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	-- Press Tab → toggle shiftlock
	if input.KeyCode == Enum.KeyCode.Tab then
		setShiftLock(not shiftLockEnabled)

		-- prevent Roblox from toggling the player list
		safeSetCore("PlayerListVisible", false)
	end
end)
