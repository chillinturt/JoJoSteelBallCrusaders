local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local WaveModule = require(ReplicatedStorage.Shared.Ocean.WaveModule)
local VehicleRaycastModule = require(script.Parent.VehicleRaycastModule)
local SeatPrompts = require(script.Parent.SeatPrompts)

local HoverController = {}

local GROUND_PROBE_HEIGHT = 1000
local GROUND_PROBE_DEPTH = 2000

-- Higher of terrain-ground and ocean-water height beneath (x, z) -- the
-- surface the vehicle hovers above.
local function getSurfaceHeight(hoverModel, x, z)
	local origin = Vector3.new(x, GROUND_PROBE_HEIGHT, z)
	local result = VehicleRaycastModule.RaycastSuspension(hoverModel, origin, Vector3.new(0, -GROUND_PROBE_DEPTH, 0))
	local groundY = result.Hit and result.Position.Y or -math.huge
	local waterY = WaveModule:GetHeight(x, z)
	return math.max(groundY, waterY)
end

-- Creates and returns a controller for a single hover vehicle.
-- config: a HoverDefinitions entry (MaxSpeed, MinHoverHeight, MaxHoverHeight, etc.)
-- Returns { Update(dt), SetVerticalInput(player, direction, isActive), Destroy() }
function HoverController.new(hoverModel, config)
	local hull = hoverModel.PrimaryPart
	local seat = hoverModel:WaitForChild("DriverSeat")
	local alignPosition = hull:WaitForChild("AlignPosition")
	local alignOrientation = hull:WaitForChild("AlignOrientation")

	local seatCleanups = { SeatPrompts.Attach(seat, "Ride", config.Name) }
	for _, passengerSeat in ipairs(SeatPrompts.FindPassengerSeats(hoverModel, seat)) do
		table.insert(seatCleanups, SeatPrompts.Attach(passengerSeat, "Sit", config.Name))
	end

	local targetPosition = hull.Position
	local currentSpeed = 0
	local currentYaw
	local hoverOffset = config.MinHoverHeight
	local ascending = false
	local descending = false

	do
		local look = hull.CFrame.LookVector
		currentYaw = math.atan2(-look.X, -look.Z)
	end

	local occupantConn = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = seat.Occupant
		if occupant then
			local player = Players:GetPlayerFromCharacter(occupant.Parent)
			if player then
				hull:SetNetworkOwner(player)
			end
		else
			hull:SetNetworkOwner(nil)
			ascending = false
			descending = false
		end
	end)

	local self = {}

	-- Called by HoverService after validating the remote sender is a real player.
	-- Re-validated here against the actual seat occupant so only the driver's
	-- input can move the vehicle.
	function self.SetVerticalInput(player, direction, isActive)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or seat.Occupant ~= humanoid then
			return
		end

		if direction == "Ascend" then
			ascending = isActive
		elseif direction == "Descend" then
			descending = isActive
		end
	end

	function self.Update(dt)
		-- AlignPosition owns Y; zeroing vertical velocity every tick keeps the hull
		-- from picking up fall/launch momentum between ticks (mirrors BoatController).
		local vel = hull.AssemblyLinearVelocity
		hull.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)

		if ascending and not descending then
			hoverOffset = math.min(hoverOffset + config.VerticalSpeed * dt, config.MaxHoverHeight)
		elseif descending and not ascending then
			hoverOffset = math.max(hoverOffset - config.VerticalSpeed * dt, config.MinHoverHeight)
		end

		currentYaw -= seat.SteerFloat * config.TurnSpeed * dt

		local forward = Vector3.new(-math.sin(currentYaw), 0, -math.cos(currentYaw))
		local targetSpeed = seat.ThrottleFloat * config.MaxSpeed

		if currentSpeed < targetSpeed then
			currentSpeed = math.min(currentSpeed + config.Acceleration * dt, targetSpeed)
		else
			currentSpeed = math.max(currentSpeed - config.Deceleration * dt, targetSpeed)
		end

		local proposedPosition = targetPosition + forward * currentSpeed * dt
		local surfaceY = getSurfaceHeight(hoverModel, proposedPosition.X, proposedPosition.Z)
		targetPosition = Vector3.new(proposedPosition.X, surfaceY + hoverOffset, proposedPosition.Z)

		-- Clamp targetPosition to not outrun the hull's actual position (see
		-- BoatController for why: keeps turns pivoting around the vehicle itself).
		local hullXZ = Vector3.new(hull.Position.X, 0, hull.Position.Z)
		local targetXZ = Vector3.new(targetPosition.X, 0, targetPosition.Z)
		local drift = targetXZ - hullXZ
		if drift.Magnitude > config.HoverLength * 0.5 then
			local clampedXZ = hullXZ + drift.Unit * (config.HoverLength * 0.5)
			targetPosition = Vector3.new(clampedXZ.X, targetPosition.Y, clampedXZ.Z)
		end

		alignPosition.Position = targetPosition
		alignOrientation.CFrame = CFrame.new(targetPosition) * CFrame.Angles(0, currentYaw, 0)
	end

	function self.Destroy()
		occupantConn:Disconnect()
		for _, cleanup in ipairs(seatCleanups) do
			cleanup()
		end
		hoverModel:Destroy()
	end

	return self
end

return HoverController
