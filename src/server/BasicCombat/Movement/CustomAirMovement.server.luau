-- AirMovement.lua
-- Quake-style air movement overlay for Roblox (smooth transition fix)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AIR_ACCEL = 15
local AIR_MAX_SPEED = 30
local MAX_VELOCITY = 150
local GRAVITY = Vector3.new(0, -50, 0)
local GROUND_CHECK_DIST = 4
local FLOOR_OFFSET = 0.1 -- distance to stay above ground

local moveEvent = Instance.new("RemoteEvent")
moveEvent.Name = "AirMovementEvent"
moveEvent.Parent = ReplicatedStorage

local playerData = {}

local function isGrounded(root)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { root.Parent }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local result = Workspace:Raycast(root.Position, Vector3.new(0, -GROUND_CHECK_DIST, 0), params)
	return result
end

local function AirAccelerate(currentVel, wishDir, wishSpeed, accel, dt)
	local wishspd = math.min(wishSpeed, AIR_MAX_SPEED)
	local currentspeed = currentVel:Dot(wishDir)
	local addspeed = wishspd - currentspeed
	if addspeed <= 0 then
		return currentVel
	end

	local accelspeed = accel * wishspd * dt
	if accelspeed > addspeed then
		accelspeed = addspeed
	end

	return currentVel + wishDir * accelspeed
end

-- Helper: anchor only HRP for manual control
local function disablePhysics(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = true
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = true
	end
end

local function enablePhysics(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = false
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = false
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local root = char:WaitForChild("HumanoidRootPart")
		playerData[player] = {
			vel = Vector3.zero,
			facingDir = root.CFrame.LookVector,
			wishDir = Vector3.zero,
			airborne = false,
			transitionCooldown = 0, -- prevents rapid toggling
		}
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerData[player] = nil
end)

RunService.Heartbeat:Connect(function(dt)
	for player, data in pairs(playerData) do
		local char = player.Character
		if not char or not char.PrimaryPart then
			continue
		end
		local root = char.PrimaryPart

		-- Apply cooldown to avoid flickering physics on edges
		if data.transitionCooldown > 0 then
			data.transitionCooldown -= dt
		end

		local hit = isGrounded(root)
		local grounded = hit ~= nil

		-- Handle state transitions
		if grounded and data.airborne and data.transitionCooldown <= 0 then
			-- Landing transition
			local normal = hit.Normal
			local pos = hit.Position + normal * FLOOR_OFFSET
			char:PivotTo(CFrame.lookAt(pos, pos + data.facingDir))
			data.vel = Vector3.zero
			task.defer(enablePhysics, char)
			data.airborne = false
			data.transitionCooldown = 0.15
		elseif not grounded and not data.airborne and data.transitionCooldown <= 0 then
			-- Leaving ground transition
			task.defer(disablePhysics, char)
			data.airborne = true
			data.vel = root.AssemblyLinearVelocity
			data.transitionCooldown = 0.15
		end

		-- Air movement
		if data.airborne then
			data.vel += GRAVITY * dt

			if data.wishDir.Magnitude > 0 then
				data.vel = AirAccelerate(data.vel, data.wishDir, MAX_VELOCITY, AIR_ACCEL, dt)
			end

			local horiz = Vector3.new(data.vel.X, 0, data.vel.Z)
			if horiz.Magnitude > MAX_VELOCITY then
				horiz = horiz.Unit * MAX_VELOCITY
			end
			data.vel = Vector3.new(horiz.X, data.vel.Y, horiz.Z)

			local newPos = root.Position + data.vel * dt
			char:PivotTo(CFrame.lookAt(newPos, newPos + data.facingDir))
		end
	end
end)

moveEvent.OnServerEvent:Connect(function(player, moveDir: Vector3, facingDir: Vector3)
	local data = playerData[player]
	if not data then
		return
	end

	if facingDir and facingDir.Magnitude > 0 then
		data.facingDir = facingDir.Unit
	end

	if moveDir.Magnitude > 0 then
		local char = player.Character
		if not char or not char.PrimaryPart then
			return
		end

		local root = char.PrimaryPart
		local baseCF = CFrame.lookAt(root.Position, root.Position + data.facingDir)
		local wishDir = baseCF:VectorToWorldSpace(moveDir).Unit

		data.wishDir = wishDir
	else
		data.wishDir = Vector3.zero
	end
end)
