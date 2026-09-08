local Players = game:GetService("Players")

local VehicleRaycastModule = require(script.Parent.VehicleRaycastModule)
local SeatPrompts = require(script.Parent.SeatPrompts)

local CarController = {}

-- Unlike BoatController/HoverController (kinematic -- AlignPosition owns the
-- hull, no real gravity/collision), cars are real unanchored physics bodies:
-- driven entirely by applied forces so they can jump ramps, collide, and flip
-- like a Jailbreak-style car.
--
-- ============================================================================
-- HOW TO WIRE UP A CAR MODEL (e.g. from a Toolbox find)
-- ============================================================================
-- Where it goes:
--   ReplicatedStorage.Vehicles.<ModelName>
--   <ModelName> must exactly match the `ModelName` field of a CarDefinitions
--   entry (e.g. CarDefinitions.Concept.ModelName = "Concept" -> the Model must
--   be named "Concept"). CarService clones this template when a player buys
--   that car -- see CarService.BuyCar.
--
-- Required Studio hierarchy inside that Model:
--   Model "Concept"                     -- top-level Model, this is what CarService clones
--   ├─ (chassis part, any name)         -- BasePart, Model.PrimaryPart MUST point to this
--   │                                      (Studio: select part + model, right-click ->
--   │                                      "Set as PrimaryPart", or set in Properties).
--   │                                      CanCollide = true. Anchored doesn't matter --
--   │                                      CarController forces it to false on spawn.
--   ├─ DriverSeat                       -- a VehicleSeat, name must be exactly "DriverSeat"
--   ├─ (any other visual body parts)    -- fenders/interior/glass/etc, purely cosmetic
--   └─ Wheels                           -- OPTIONAL Folder
--      ├─ FL                            -- BasePart at the front-left wheel's position
--      ├─ FR                            -- BasePart at the front-right wheel's position
--      ├─ RL                            -- BasePart at the rear-left wheel's position
--      └─ RR                            -- BasePart at the rear-right wheel's position
--
-- EVERY part in the model (DriverSeat, wheel meshes, body panels, the Wheels
-- folder's parts, etc.) must be rigidly attached to the chassis/PrimaryPart --
-- normally via WeldConstraint -- so the whole model moves as one assembly.
-- Applied forces (suspension, drive, grip) only ever push on the PrimaryPart;
-- anything not welded to it will not follow the car.
--
-- The Wheels/FL/FR/RL/RR parts are read ONCE at spawn purely to get a wheel's
-- world Position, which becomes that wheel's suspension raycast origin (see
-- resolveWheelOffsets below) -- the script never moves them afterward, so they
-- do not currently spin or turn with steering (a Toolbox model's own wheel
-- rig, if it has one, is safe to leave attached; it just won't be driven by
-- this script yet). If the Wheels folder or a wheel part is missing, that
-- corner's mount point falls back to a rectangle computed from the
-- CarDefinitions entry's Wheelbase/TrackWidth, so a model with no wheel
-- markers at all still works, just with suspension points at flat guesses
-- instead of the model's actual wheel positions.
--
-- Passenger seats: any other Seat/VehicleSeat in the model (any name) other
-- than DriverSeat is auto-detected as a passenger seat -- see
-- SeatPrompts.FindPassengerSeats.
--
-- Dealer NPC (separate from the car model, for reference): give the selling
-- NPC model an NPCName StringValue matching a CarDefinitions entry's `Dealer`
-- field, and optionally a "CarSpawn" BasePart child marking where purchased
-- cars appear (falls back to 30 studs in front of the NPC) -- see
-- CarService.getSpawnCFrame.
-- ============================================================================
--
-- Every applied force is `desired studs/sec^2 * hull.AssemblyMass`, so a
-- CarDefinitions entry's numbers behave the same regardless of the actual
-- part's mass/density (F = m*a).

local MIN_TURN_SPEED = 4 -- studs/sec of forward speed needed for full steering authority; prevents spinning in place when stopped
local FLIP_RECOVERY_DELAY = 2.5 -- seconds spent flipped + near-stationary before auto-righting
local FLIP_UP_DOT_THRESHOLD = -0.3
local FLIP_SPEED_THRESHOLD = 3

local WHEEL_SPECS = {
	{ Name = "FL", IsFront = true, IsLeft = true },
	{ Name = "FR", IsFront = true, IsLeft = false },
	{ Name = "RL", IsFront = false, IsLeft = true },
	{ Name = "RR", IsFront = false, IsLeft = false },
}

local function sign(n)
	if n > 0 then
		return 1
	elseif n < 0 then
		return -1
	end
	return 0
end

-- Resolves each wheel's suspension raycast origin in chassis-local space.
local function resolveWheelOffsets(carModel, hull, config)
	local wheelsFolder = carModel:FindFirstChild("Wheels")
	local offsets = {}

	for _, spec in ipairs(WHEEL_SPECS) do
		local wheelPart = wheelsFolder and wheelsFolder:FindFirstChild(spec.Name)
		local localOffset

		if wheelPart and wheelPart:IsA("BasePart") then
			localOffset = hull.CFrame:PointToObjectSpace(wheelPart.Position)
		else
			localOffset = Vector3.new(
				(spec.IsLeft and -1 or 1) * config.TrackWidth / 2,
				-0.5,
				(spec.IsFront and 1 or -1) * config.Wheelbase / 2
			)
		end

		table.insert(offsets, { Name = spec.Name, IsFront = spec.IsFront, LocalOffset = localOffset })
	end

	return offsets
end

-- Creates and returns a controller for a single car model.
-- config: a CarDefinitions entry (MaxSpeed, Acceleration, SuspensionStiffness, etc.)
-- Returns { Update(dt), SetHandbrake(player, isActive), Destroy() }
function CarController.new(carModel, config)
	local hull = carModel.PrimaryPart
	hull.Anchored = false

	local seat = carModel:WaitForChild("DriverSeat")

	local seatCleanups = { SeatPrompts.Attach(seat, "Drive", config.Name) }
	for _, passengerSeat in ipairs(SeatPrompts.FindPassengerSeats(carModel, seat)) do
		table.insert(seatCleanups, SeatPrompts.Attach(passengerSeat, "Sit", config.Name))
	end

	local wheels = {}
	for _, wheelInfo in ipairs(resolveWheelOffsets(carModel, hull, config)) do
		local attachment = Instance.new("Attachment")
		attachment.Name = wheelInfo.Name .. "SuspensionAttachment"
		attachment.Position = wheelInfo.LocalOffset
		attachment.Parent = hull

		local vectorForce = Instance.new("VectorForce")
		vectorForce.Name = wheelInfo.Name .. "SuspensionForce"
		vectorForce.Attachment0 = attachment
		vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
		vectorForce.ApplyAtCenterOfMass = false
		vectorForce.Force = Vector3.zero
		vectorForce.Parent = attachment

		table.insert(wheels, {
			Name = wheelInfo.Name,
			IsFront = wheelInfo.IsFront,
			LocalOffset = wheelInfo.LocalOffset,
			VectorForce = vectorForce,
		})
	end

	-- Drive (throttle/brake/reverse) + downforce are applied at the chassis
	-- center rather than per-wheel, so the engine can't induce unwanted
	-- pitch/roll -- only the suspension and tire grip forces above do that.
	local driveAttachment = Instance.new("Attachment")
	driveAttachment.Name = "DriveAttachment"
	driveAttachment.Parent = hull

	local driveForce = Instance.new("VectorForce")
	driveForce.Name = "DriveForce"
	driveForce.Attachment0 = driveAttachment
	driveForce.RelativeTo = Enum.ActuatorRelativeTo.World
	driveForce.ApplyAtCenterOfMass = true
	driveForce.Force = Vector3.zero
	driveForce.Parent = driveAttachment

	local currentSteerAngle = 0
	local handbrakeActive = false
	local flipTimer = 0

	local occupantConn = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = seat.Occupant
		if occupant then
			local player = Players:GetPlayerFromCharacter(occupant.Parent)
			if player then
				hull:SetNetworkOwner(player)
			end
		else
			hull:SetNetworkOwner(nil)
			handbrakeActive = false
		end
	end)

	local self = {}

	-- Called by CarService after validating the remote sender is a real player.
	-- Re-validated here against the actual seat occupant so only the driver's
	-- input can engage the handbrake (mirrors HoverController.SetVerticalInput).
	function self.SetHandbrake(player, isActive)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or seat.Occupant ~= humanoid then
			return
		end
		handbrakeActive = isActive
	end

	function self.Update(dt)
		local mass = hull.AssemblyMass
		local chassisCFrame = hull.CFrame
		local forwardDir = chassisCFrame.LookVector
		local rightDir = chassisCFrame.RightVector
		local upDir = chassisCFrame.UpVector
		local linearVelocity = hull.AssemblyLinearVelocity
		local forwardSpeed = linearVelocity:Dot(forwardDir)

		------------------------------------------------
		-- Steering angle + yaw rate. Steering authority ramps up from a stop
		-- (no spinning in place) and tapers off near top speed, and reverses
		-- sense in reverse gear -- same as a real front-steered car.
		------------------------------------------------
		local speedRatio = math.clamp(math.abs(forwardSpeed) / config.MaxSpeed, 0, 1)
		local steerScale = 1 - speedRatio * config.HighSpeedSteerFactor
		local targetSteerAngle = seat.SteerFloat * config.MaxSteerAngle * steerScale
		local steerDelta =
			math.clamp(targetSteerAngle - currentSteerAngle, -config.SteerSpeed * dt, config.SteerSpeed * dt)
		currentSteerAngle += steerDelta

		local turnAuthority = math.clamp(math.abs(forwardSpeed) / MIN_TURN_SPEED, 0, 1)
		local reverseSign = forwardSpeed < 0 and -1 or 1
		local desiredYawRate = -seat.SteerFloat * config.TurnSpeed * steerScale * turnAuthority * reverseSign

		local angularVelocity = hull.AssemblyAngularVelocity
		local yawDelta = math.clamp(desiredYawRate - angularVelocity.Y, -config.YawAccel * dt, config.YawAccel * dt)
		hull.AssemblyAngularVelocity =
			Vector3.new(angularVelocity.X, angularVelocity.Y + yawDelta, angularVelocity.Z)

		------------------------------------------------
		-- Per-wheel suspension (raycast spring-damper) + lateral tire grip.
		-- Holding the handbrake drops rear grip only, so the back end slides
		-- while the front still bites -- this is what produces the drift.
		------------------------------------------------
		local frontLateralDir = rightDir * math.cos(currentSteerAngle) - forwardDir * math.sin(currentSteerAngle)

		for _, wheel in ipairs(wheels) do
			local mountPosition = chassisCFrame:PointToWorldSpace(wheel.LocalOffset)
			local rayResult =
				VehicleRaycastModule.RaycastSuspension(carModel, mountPosition, -upDir * config.SuspensionLength)

			local force = Vector3.zero
			if rayResult.Hit then
				local pointVelocity = hull:GetVelocityAtPosition(mountPosition)

				local compressionRatio = math.clamp(1 - (rayResult.Distance / config.SuspensionLength), 0, 1)
				local springVelocity = pointVelocity:Dot(upDir)
				local springAccel = math.max(
					compressionRatio * config.SuspensionStiffness - springVelocity * config.SuspensionDamping,
					0
				)
				force += upDir * (springAccel * mass)

				local lateralDir = wheel.IsFront and frontLateralDir or rightDir
				local lateralSpeed = pointVelocity:Dot(lateralDir)
				local grip = (handbrakeActive and not wheel.IsFront) and config.DriftGrip or config.TireGrip
				force += lateralDir * (-lateralSpeed * grip * (mass / 4))
			end

			wheel.VectorForce.Force = force
		end

		------------------------------------------------
		-- Drive force: throttle accelerates toward MaxSpeed with a tapering
		-- curve (less punch as it nears top speed); throttle opposite the
		-- current direction of travel brakes instead of instantly reversing;
		-- releasing the throttle coasts down via Deceleration engine drag.
		------------------------------------------------
		local throttle = seat.ThrottleFloat
		local driveAccel = 0

		if handbrakeActive then
			driveAccel = -sign(forwardSpeed) * config.BrakeForce
		elseif throttle > 0 then
			if forwardSpeed < -1 then
				driveAccel = config.BrakeForce
			else
				local ratio = math.clamp(forwardSpeed / config.MaxSpeed, 0, 1)
				driveAccel = config.Acceleration * (1 - ratio) * throttle
			end
		elseif throttle < 0 then
			if forwardSpeed > 1 then
				driveAccel = throttle * config.BrakeForce
			else
				local ratio = math.clamp(-forwardSpeed / config.MaxReverseSpeed, 0, 1)
				driveAccel = throttle * config.ReverseAcceleration * (1 - ratio)
			end
		elseif math.abs(forwardSpeed) > 0.5 then
			driveAccel = -sign(forwardSpeed) * config.Deceleration
		end

		local downforceAccel = config.Downforce * (linearVelocity.Magnitude ^ 2)
		driveForce.Force = forwardDir * (driveAccel * mass) - upDir * (downforceAccel * mass)

		------------------------------------------------
		-- Flip recovery: stuck upside-down/on-side and roughly stationary for
		-- too long gets gently set back upright instead of softlocking.
		------------------------------------------------
		if upDir:Dot(Vector3.yAxis) < FLIP_UP_DOT_THRESHOLD and linearVelocity.Magnitude < FLIP_SPEED_THRESHOLD then
			flipTimer += dt
			if flipTimer >= FLIP_RECOVERY_DELAY then
				local flatForward = Vector3.new(forwardDir.X, 0, forwardDir.Z)
				if flatForward.Magnitude < 0.01 then
					flatForward = Vector3.new(rightDir.X, 0, rightDir.Z)
				end
				local uprightPosition = hull.Position + Vector3.new(0, 3, 0)
				hull.CFrame = CFrame.new(uprightPosition, uprightPosition + flatForward)
				hull.AssemblyLinearVelocity = Vector3.zero
				hull.AssemblyAngularVelocity = Vector3.zero
				flipTimer = 0
			end
		else
			flipTimer = 0
		end
	end

	function self.Destroy()
		occupantConn:Disconnect()
		for _, cleanup in ipairs(seatCleanups) do
			cleanup()
		end
		carModel:Destroy()
	end

	return self
end

return CarController
