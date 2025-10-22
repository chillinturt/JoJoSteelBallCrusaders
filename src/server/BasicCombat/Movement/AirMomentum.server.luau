--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- CONFIG
local AIR_ACCEL = 200 -- how fast you can accelerate in the air
local AIR_MAX_SPEED = 50 -- max horizontal speed in the air
local AIR_DRAG = 0 -- optional slowdown factor per second (0 for none)

-- UTILITY: Check if character is airborne
local function isAirborne(hrp: BasePart)
	local parent = hrp.Parent
	if not parent then
		return false -- or true? depends on your logic; probably assume grounded
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { parent } -- now guaranteed to be non-nil
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(hrp.Position, Vector3.new(0, -4, 0), params)
	return result == nil
end

-- Air movement logic
local function applyAirMovement(player: Player)
	local character = player.Character
	if not character then
		return
	end

	-- Explicitly assert correct types
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	if not hrp or not humanoid then
		return
	end

	-- Track airborne state
	local airborne = false

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not character.Parent then
			connection:Disconnect()
			return
		end

		local inAir = isAirborne(hrp)

		-- Detect leaving / landing
		if inAir and not airborne then
			airborne = true
		elseif not inAir and airborne then
			airborne = false
		end

		if airborne then
			-- Get current horizontal velocity (ignore Y)
			local planeVelocity = Vector2.new(hrp.AssemblyLinearVelocity.X, hrp.AssemblyLinearVelocity.Z)

			-- GET INPUT: Convert Humanoid move direction to 2D
			local moveVector: Vector3 = humanoid.MoveDirection
			local wishDir = Vector2.new(moveVector.X, moveVector.Z)
			if wishDir.Magnitude > 0 then
				wishDir = wishDir.Unit
			end

			-- Accelerate toward wishDir (TF2-style)
			local currentSpeed = planeVelocity:Dot(wishDir)
			local wishSpeed = 16 -- Desired air speed
			local addSpeed = wishSpeed - currentSpeed
			if addSpeed > 0 then
				local accel = math.min(AIR_ACCEL * dt * wishSpeed, addSpeed)
				planeVelocity += wishDir * accel
			end

			-- Clamp to max horizontal air speed
			if planeVelocity.Magnitude > AIR_MAX_SPEED then
				planeVelocity = planeVelocity.Unit * AIR_MAX_SPEED
			end

			-- Optional drag
			if AIR_DRAG > 0 then
				planeVelocity *= 1 - (AIR_DRAG * dt)
			end

			-- APPLY: Replace XZ but preserve Y velocity
			local currentVel = hrp.AssemblyLinearVelocity
			hrp.AssemblyLinearVelocity = Vector3.new(planeVelocity.X, currentVel.Y, planeVelocity.Y)
		end
	end)
end

-- Apply air movement to every player
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(1) -- wait for character to fully load
		applyAirMovement(player)
	end)
end)
