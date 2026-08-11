local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local WaveModule = require(ReplicatedStorage.Shared.Ocean.WaveModule)

local BoatController = {}

-- Creates and returns a controller for a single boat model.
-- config: a BoatDefinitions entry (MaxSpeed, Acceleration, etc.)
-- Returns { Update(dt), Destroy() }
function BoatController.new(boatModel, config)
	local hull = boatModel.PrimaryPart
	local seat = boatModel:WaitForChild("PilotSeat")
	local alignPosition = hull:WaitForChild("AlignPosition")
	local alignOrientation = hull:WaitForChild("AlignOrientation")

	local targetPosition = hull.Position
	local currentSpeed = 0
	local currentYaw

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
		end
	end)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { boatModel }

	local function isLandAhead(position, yaw)
		local forward = Vector3.new(-math.sin(yaw), 0, -math.cos(yaw))
		local right = Vector3.new(forward.Z, 0, -forward.X)

		local checkPoints = {
			position + forward * (config.BoatLength / 2),
			position + forward * (config.BoatLength / 2) + right * (config.BoatWidth / 2),
			position + forward * (config.BoatLength / 2) - right * (config.BoatWidth / 2),
		}

		for _, point in ipairs(checkPoints) do
			local result = Workspace:Raycast(
				Vector3.new(point.X, WaveModule.OCEAN_HEIGHT + 5, point.Z),
				Vector3.new(0, -10, 0),
				rayParams
			)
			if result and result.Position.Y > WaveModule.OCEAN_HEIGHT then
				return true
			end
		end

		return false
	end

	local self = {}

	function self.Update(dt)
		-- AlignPosition owns Y; boats have no valid vertical velocity. Zeroing it every
		-- tick prevents sloped collisions from flinging the hull up onto land or down
		-- below the ocean before the reactive check can respond.
		local vel = hull.AssemblyLinearVelocity
		hull.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)

		-- Fallback: if the hull has still drifted below the surface (e.g. caught in
		-- geometry between ticks), snap targetPosition back to water height so
		-- AlignPosition has a clear upward target.
		local waterY = WaveModule:GetHeight(hull.Position.X, hull.Position.Z)
		if hull.Position.Y < waterY - 1 then
			targetPosition = Vector3.new(targetPosition.X, waterY, targetPosition.Z)
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

		if not isLandAhead(proposedPosition, currentYaw) then
			targetPosition = Vector3.new(
				proposedPosition.X,
				WaveModule:GetHeight(proposedPosition.X, proposedPosition.Z),
				proposedPosition.Z
			)
		else
			currentSpeed = 0
			hull.AssemblyLinearVelocity = Vector3.zero
		end

		-- Clamp targetPosition to not outrun the hull's actual position. When the hull
		-- lags behind, the AlignPosition anchor would otherwise sit far ahead and cause
		-- turns to pivot around a distant point instead of the boat itself.
		local hullXZ = Vector3.new(hull.Position.X, 0, hull.Position.Z)
		local targetXZ = Vector3.new(targetPosition.X, 0, targetPosition.Z)
		local drift = targetXZ - hullXZ
		if drift.Magnitude > config.BoatLength * 0.5 then
			local clampedXZ = hullXZ + drift.Unit * (config.BoatLength * 0.5)
			targetPosition = Vector3.new(clampedXZ.X, targetPosition.Y, clampedXZ.Z)
		end

		alignPosition.Position = targetPosition
		alignOrientation.CFrame = CFrame.new(targetPosition) * CFrame.Angles(0, currentYaw, 0)
	end

	function self.Destroy()
		occupantConn:Disconnect()
		boatModel:Destroy()
	end

	return self
end

return BoatController
