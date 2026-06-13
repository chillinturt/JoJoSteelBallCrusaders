-- VehicleRaycastModule.lua
-- Shared vehicle raycast utilities
-- Built for suspension, grounding, terrain normals,
-- future boats, PvP collisions, and ramming.

local VehicleRaycastModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RaycastIgnoreModule = require(ReplicatedStorage.Shared.Modules.RaycastIgnoreModule)

-- Creates raycast params using global ignore list
local function getVehicleParams(vehicle, extraIgnore)
	local ignore = RaycastIgnoreModule.GetIgnoreList()

	if vehicle then
		table.insert(ignore, vehicle)
	end

	if extraIgnore then
		if typeof(extraIgnore) == "Instance" then
			table.insert(ignore, extraIgnore)
		elseif typeof(extraIgnore) == "table" then
			for _, obj in ipairs(extraIgnore) do
				if typeof(obj) == "Instance" then
					table.insert(ignore, obj)
				end
			end
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = false

	return params
end

-- Suspension raycast for wheels/thrusters
function VehicleRaycastModule.RaycastSuspension(vehicle, origin, direction, extraIgnore)
	local params = getVehicleParams(vehicle, extraIgnore)

	local result = workspace:Raycast(origin, direction, params)

	if result then
		return {
			Hit = true,
			Instance = result.Instance,
			Position = result.Position,
			Normal = result.Normal,
			Material = result.Material,
			Distance = (origin - result.Position).Magnitude,
		}
	end

	return {
		Hit = false,
		Instance = nil,
		Position = origin + direction,
		Normal = Vector3.yAxis,
		Material = nil,
		Distance = direction.Magnitude,
	}
end

-- Checks if vehicle is grounded
function VehicleRaycastModule.IsGrounded(vehicle, chassis, height)
	local origin = chassis.Position

	local direction = Vector3.yAxis * (height + 1)

	local result = VehicleRaycastModule.RaycastSuspension(vehicle, origin, direction)

	return result.Hit, result
end

-- Gets surface normal below vehicle
function VehicleRaycastModule.GetGroundNormal(vehicle, chassis, height)
	local grounded, result = VehicleRaycastModule.IsGrounded(vehicle, chassis, height)

	if grounded then
		return result.Normal
	end

	return Vector3.yAxis
end

-- Future-ready collision check
function VehicleRaycastModule.CheckForwardCollision(vehicle, chassis, distance)
	local origin = chassis.Position
	local direction = chassis.CFrame.LookVector * distance

	local result = VehicleRaycastModule.RaycastSuspension(vehicle, origin, direction)

	return result.Hit, result
end

return VehicleRaycastModule
