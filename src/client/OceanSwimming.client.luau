local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local WaveModule = require(ReplicatedStorage.Shared.Ocean.WaveModule)

local SwimmingState = ReplicatedStorage.Remotes.Ocean:WaitForChild("SwimmingState")

local SWIM_OFFSET = 0

local ENTER_MARGIN = 0.5
local EXIT_MARGIN = 2.5

-- How many studs below the wave surface triggers a rescue teleport.
local RESCUE_DEPTH = 3
-- Seconds after last confirmed surface contact within which a rescue fires.
local RESCUE_WINDOW = 3

local swimming = false
local jumpLockUntil = 0
local airborneLock = false
local lastInWater = false
local swimTilt = 0 -- 0 = upright, 1 = fully horizontal
local swimYaw = 0 -- cached facing angle (radians) while in water
local serverSwimming = false
local lastAtSurface = 0

-- Stand counter-tilt: cache the motor and its server-set C0 so we can derive
-- a counter-rotation each frame without drifting from the original offset.
local standMotorData = nil -- { motor: Motor6D, originalC0: CFrame }

local function getStandMotor(): Motor6D?
	local character = player.Character
	if not character then
		return nil
	end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Model") and child:FindFirstChild("StandTag") then
			local primary = child.PrimaryPart
			if primary then
				local motor = primary:FindFirstChild("StandMotor")
				if motor and motor:IsA("Motor6D") then
					return motor
				end
			end
		end
	end
	return nil
end

SwimmingState.OnClientEvent:Connect(function(value)
	if value then
		task.wait(0.05)
	end
	swimming = value
end)

UserInputService.JumpRequest:Connect(function()
	-- Allow jump if either the server confirmed swimming OR the client locally
	-- detected being in water (serverSwimming). Using only `swimming` misses a
	-- window where the server hasn't replied yet or wave oscillation briefly
	-- cleared it, leaving the player pinned at the surface with no way out.
	if not swimming and not serverSwimming then
		return
	end

	if tick() < jumpLockUntil then
		return
	end

	jumpLockUntil = tick() + 0.6
	airborneLock = true
	swimming = false

	serverSwimming = false
	lastInWater = false
	SwimmingState:FireServer("Exit")

	task.delay(1.0, function()
		airborneLock = false
	end)

	local character = player.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		-- Reset from horizontal swim tilt so the character launches upright.
		humanoid.AutoRotate = true
		swimTilt = 0
		root.CFrame = CFrame.new(root.Position) * CFrame.fromEulerAnglesYXZ(0, swimYaw, 0)

		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

		local velocity = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(velocity.X, 50, velocity.Z)
	end
end)

RunService.RenderStepped:Connect(function(dt)
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

	if humanoid.SeatPart then
		humanoid.AutoRotate = true
		return
	end

	local waterHeight = WaveModule:GetHeight(root.Position.X, root.Position.Z)
	local targetY = waterHeight + SWIM_OFFSET

	-- Rescue: player sank well below the surface (e.g. jumped into a ceiling and
	-- bounced back down while airborneLock was still active). Runs before the
	-- airborneLock early-return so it fires even during the jump window.
	if root.Position.Y < waterHeight - RESCUE_DEPTH and tick() - lastAtSurface < RESCUE_WINDOW then
		root.CFrame = CFrame.new(root.Position.X, targetY, root.Position.Z) * CFrame.fromEulerAnglesYXZ(0, swimYaw, 0)
		root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		airborneLock = false
		jumpLockUntil = 0
		serverSwimming = false
		lastInWater = false
		swimTilt = 0
	end

	-- Use a larger exit threshold when already swimming so that the tilted HRP
	-- (which physics nudges slightly above targetY each frame) doesn't trigger
	-- a rapid Enter → Exit → Enter loop. A jump carries the player well above
	-- this margin, so real exits still fire correctly.
	local inWater

	local distanceFromSurface = math.abs(root.Position.Y - targetY)

	if lastInWater then
		inWater = distanceFromSurface <= 3
	else
		inWater = distanceFromSurface <= 1
	end

	if inWater ~= serverSwimming then
		serverSwimming = inWater

		if inWater then
			SwimmingState:FireServer("Enter")

			local lv = root.CFrame.LookVector
			swimYaw = math.atan2(-lv.X, -lv.Z)

			if not airborneLock then
				humanoid:ChangeState(Enum.HumanoidStateType.Landed)
			end
		else
			SwimmingState:FireServer("Exit")

			humanoid.AutoRotate = true
			swimTilt = 0
		end
	end

	lastInWater = inWater

	if inWater then
		lastAtSurface = tick()
	end

	if not inWater or airborneLock then
		-- Hand yaw back to Roblox and snap tilt to 0
		humanoid.AutoRotate = true
		swimTilt = 0
	else
		-- We own rotation while in water. AutoRotate only sets yaw and would
		-- fight any pitch we applied, so we disable it and do both ourselves.
		humanoid.AutoRotate = false

		local isMoving = humanoid.MoveDirection.Magnitude > 0.1

		-- Track the movement direction as yaw whenever the player is moving
		if isMoving then
			local flat = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z)
			if flat.Magnitude > 0.001 then
				swimYaw = math.atan2(-flat.Unit.X, -flat.Unit.Z)
			end
		end

		-- Lerp tilt: 1 (horizontal) when moving, 0 (upright) when still
		local targetTilt = isMoving and 1 or 0
		swimTilt = swimTilt + (targetTilt - swimTilt) * math.min(dt * 8, 1)

		-- Apply yaw then pitch. fromEulerAnglesYXZ applies Y first then X in the
		-- yawed frame, so pitch always tilts the character along its facing direction.
		local pitch = -(math.pi / 2) * swimTilt
		root.CFrame = CFrame.new(root.Position.X, targetY, root.Position.Z)
			* CFrame.fromEulerAnglesYXZ(pitch, swimYaw, 0)

		if not airborneLock then
			root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
		end
	end

	-- Keep the stand upright by applying a counter-pitch equal and opposite to
	-- the player's swim tilt. This is done every frame (even when swimTilt = 0)
	-- so the C0 is always restored correctly when leaving the water.
	--
	-- Formula derivation: Part0 (HRP) has world rotation Ry(swimYaw)*Rx(pitch).
	-- To make the stand upright (Ry(swimYaw) only), C0 must contribute Rx(-pitch).
	-- Applying Rx(-pitch) to the original C0 position vector also preserves the
	-- stand's world-space offset direction (it stays behind the player, not above).
	local motor = getStandMotor()
	if motor and motor.Parent then
		if standMotorData == nil or standMotorData.motor ~= motor then
			standMotorData = { motor = motor, originalC0 = motor.C0 }
		end
		local origC0 = standMotorData.originalC0
		local origPos = origC0.Position
		-- Strip translation from original C0 to get rotation-only component.
		local origRotOnly = CFrame.new(-origPos) * origC0
		-- Counter-rotation cancels the HRP pitch: Rx(+swimTilt * π/2)
		local counterRot = CFrame.Angles((math.pi / 2) * swimTilt, 0, 0)
		-- Rotate the position vector too so the world-space offset stays correct.
		motor.C0 = CFrame.new(counterRot * origPos) * counterRot * origRotOnly
	else
		standMotorData = nil
	end
end)
