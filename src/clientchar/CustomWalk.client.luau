-- FloatMovementClient.lua
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local movementEvent = ReplicatedStorage:WaitForChild("FloatMovementEvent")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local moveDir = Vector3.zero

-- Handle WASD input
local keyMap = {
	[Enum.KeyCode.W] = Vector3.new(0, 0, -1),
	[Enum.KeyCode.S] = Vector3.new(0, 0, 1),
	[Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
	[Enum.KeyCode.D] = Vector3.new(1, 0, 0),
	[Enum.KeyCode.Space] = Vector3.new(0, 1, 0),
	[Enum.KeyCode.LeftControl] = Vector3.new(0, -1, 0),
}

local function updateMoveDir()
	local dir = Vector3.zero
	for key, vec in pairs(keyMap) do
		if UserInputService:IsKeyDown(key) then
			dir += vec
		end
	end
	moveDir = dir.Magnitude > 0 and dir.Unit or Vector3.zero
end

RunService.RenderStepped:Connect(function()
	updateMoveDir()

	local facingDir = camera.CFrame.LookVector
	movementEvent:FireServer(moveDir, facingDir)
end)
