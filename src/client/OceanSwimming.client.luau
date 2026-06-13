local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local WaveModule = require(ReplicatedStorage.Shared.Ocean.WaveModule)

local SwimmingState = ReplicatedStorage.Remotes.Ocean:WaitForChild("SwimmingState")

local SWIM_OFFSET = 3

local swimming = false
local jumpLockUntil = 0
local airborneLock = false
local lastInWater = false

local function isAirborne(character)
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not humanoid then
		return false
	end

	local state = humanoid:GetState()
	return state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall
end

SwimmingState.OnClientEvent:Connect(function(value)
	if value then
		task.wait(0.05)
	end

	swimming = value
end)

UserInputService.JumpRequest:Connect(function()
	if not swimming then
		return
	end

	if tick() < jumpLockUntil then
		return
	end

	jumpLockUntil = tick() + 0.6
	airborneLock = true

	task.delay(0.8, function()
		airborneLock = false
	end)

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

RunService.RenderStepped:Connect(function()
	local character = player.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local waterHeight = WaveModule:GetHeight(root.Position.X, root.Position.Z)

	local inWater = root.Position.Y <= waterHeight

	if inWater and not lastInWater then
		SwimmingState:FireServer("Enter")
	elseif not inWater and lastInWater then
		SwimmingState:FireServer("Exit")
	end

	lastInWater = inWater

	-- ONLY apply movement lock if swimming is active
	if not swimming or airborneLock then
		return
	end

	local targetY = waterHeight + SWIM_OFFSET

	local currentPosition = root.Position

	root.CFrame = CFrame.new(currentPosition.X, targetY, currentPosition.Z)
		* CFrame.fromMatrix(Vector3.zero, root.CFrame.XVector, root.CFrame.YVector, root.CFrame.ZVector)

	root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
end)
