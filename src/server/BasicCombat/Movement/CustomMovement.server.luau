-- FloatMovementServer.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local movementEvent = Instance.new("RemoteEvent")
movementEvent.Name = "FloatMovementEvent"
movementEvent.Parent = ReplicatedStorage
local floatData = {} -- player -> {targetCF, currentVel, speed}

local MOVE_SPEED = 20
local SMOOTHNESS = 0.2
local MAX_SPEED = 150 -- maximum velocity magnitude

local GRAVITY = Vector3.new(0, -50, 0) -- units per second²

local MOMENTUM_ACCEL = 60 -- how quickly velocity builds

-- Utility: disable roblox physics on character
local function disableCharacterPhysics(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid.AutoRotate = false
		humanoid.PlatformStand = true
	end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name == "HumanoidRootPart" then
				part.Anchored = true
			else
				part.Anchored = false
			end
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = true
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

-- Listen for player characters
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.1)
		disableCharacterPhysics(char)
		floatData[player] = {
			targetCF = char:GetPivot(),
			currentVel = Vector3.zero,
			speed = MOVE_SPEED,
			facingDir = char.PrimaryPart.CFrame.LookVector,
		}
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	floatData[player] = nil
end)

-- Apply movement every heartbeat
RunService.Heartbeat:Connect(function(dt)
	for player, data in pairs(floatData) do
		local char = player.Character
		if not char or not char.PrimaryPart then
			continue
		end

		-- Apply gravity
		data.currentVel = data.currentVel + GRAVITY * dt

		local root = char.PrimaryPart
		local newPos = root.Position + data.currentVel * dt -- Raycast to avoid walls

		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { char }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local result = workspace:Raycast(root.Position, data.currentVel * dt, rayParams)
		if result then -- Stop movement at the hit surface
			local hitPos = result.Position
			local normal = result.Normal
			newPos = root.Position + normal * 0.1 -- stay slightly away from surface

			-- Stop velocity in the direction of the collision normal
			local velAlongNormal = data.currentVel:Dot(normal)
			if velAlongNormal < 0 then
				data.currentVel = data.currentVel - normal * velAlongNormal
			end
		end
		local lookDir = data.facingDir or root.CFrame.LookVector
		char:PivotTo(CFrame.lookAt(newPos, newPos + lookDir))
	end
end)

-- Handle movement input from client
movementEvent.OnServerEvent:Connect(function(player, moveDir: Vector3, facingDir: Vector3)
	local data = floatData[player]
	if not data then
		return
	end
	local char = player.Character
	if not char or not char.PrimaryPart then
		return
	end

	-- Store facingDir from client for rotation (shiftlock)
	if facingDir then
		data.facingDir = facingDir.Unit
	end

	if moveDir.Magnitude > 0 then
		-- Convert input to world space
		local baseCF = CFrame.lookAt(char.PrimaryPart.Position, char.PrimaryPart.Position + facingDir)
		local inputDir = baseCF:VectorToWorldSpace(moveDir).Unit

		-- Apply momentum: accelerate in the input direction
		data.currentVel = data.currentVel + inputDir * MOMENTUM_ACCEL * RunService.Heartbeat:Wait() -- delta time
	end

	-- Clamp horizontal speed
	local horizontalVel = Vector3.new(data.currentVel.X, 0, data.currentVel.Z)
	if horizontalVel.Magnitude > MAX_SPEED then
		horizontalVel = horizontalVel.Unit * MAX_SPEED
	end
	data.currentVel = Vector3.new(horizontalVel.X, data.currentVel.Y, horizontalVel.Z)
end)
