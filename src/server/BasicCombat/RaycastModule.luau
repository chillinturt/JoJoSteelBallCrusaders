-- RaycastModule.lua
local RaycastModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RaycastIgnoreModule = require(game.ReplicatedStorage.Shared.Modules:WaitForChild("RaycastIgnoreModule"))

local RequestCameraDirection = Instance.new("RemoteFunction")
RequestCameraDirection.Name = "RequestCameraDirection"
RequestCameraDirection.Parent = ReplicatedStorage.Shared:WaitForChild("BasicCombat")

-- function to raycast from the character in the direction of their camera,
-- then return the first point hit by the ray (not in the Exclude list)
function RaycastModule.ReturnFacingPoint(character, maxDistance)
	maxDistance = maxDistance or 500 -- Default max distance if not specified

	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		warn("RaycastModule.ReturnFacingPoint: Character has no player!")
		return nil
	end

	local remote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("RequestCameraDirection")
	local cameraDirection = remote:InvokeClient(player)
	if not cameraDirection then
		warn("RaycastModule.ReturnFacingPoint: No camera direction received!")
		return nil
	end

	-- Ensure direction is normalized
	cameraDirection = cameraDirection.Unit

	-- Get the starting position (character’s head or humanoid root)
	local origin = character:FindFirstChild("Head") and character.Head.Position
		or (character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart.Position)
	if not origin then
		warn("RaycastModule.ReturnFacingPoint: Character has no valid origin part!")
		return nil
	end

	-- === Raycast setup ===
	local rayParams = RaycastParams.new()
	local ignoreList = RaycastIgnoreModule.GetIgnoreList()
	table.insert(ignoreList, character) -- ignore self
	rayParams.FilterDescendantsInstances = ignoreList
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	-- === Perform the raycast ===
	local rayDirection = cameraDirection * maxDistance
	local result = workspace:Raycast(origin, rayDirection, rayParams)

	-- Return the hit position, or max point if nothing hit
	if result then
		return result.Position
	else
		return origin + rayDirection
	end
end

function RaycastModule.CheckIfTargetIsClose(entity, maxDistance)
	maxDistance = maxDistance or 15 -- Default "close" distance

	if not entity then
		warn("RaycastModule.CheckIfTargetIsClose: No entity provided!")
		return false
	end

	local origin
	local direction

	-- Determine the origin and forward direction
	if entity:IsA("Model") then
		local primaryPart = entity.PrimaryPart
			or entity:FindFirstChild("HumanoidRootPart")
			or entity:FindFirstChild("Head")
		if not primaryPart then
			warn("RaycastModule.CheckIfTargetIsClose: Model has no valid primary part!")
			return false
		end
		origin = primaryPart.Position
		direction = primaryPart.CFrame.LookVector
	elseif entity:IsA("BasePart") then
		origin = entity.Position
		direction = entity.CFrame.LookVector
	else
		warn("RaycastModule.CheckIfTargetIsClose: Unsupported entity type (" .. entity.ClassName .. ")")
		return false
	end

	-- === Raycast setup ===
	local rayParams = RaycastParams.new()
	local ignoreList = RaycastIgnoreModule.GetIgnoreList()
	table.insert(ignoreList, entity)
	rayParams.FilterDescendantsInstances = ignoreList
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	-- === Perform raycast ===
	local rayDirection = direction * maxDistance
	local result = workspace:Raycast(origin, rayDirection, rayParams)

	-- === Return logic ===
	if result then
		-- Return true + hit info if something is close
		return true, result
	else
		-- No nearby target
		return false, nil
	end
end

function RaycastModule.CheckForNearbySurface(entity, maxDistance)
	maxDistance = maxDistance or 5 -- distance to check in all directions
	if not entity then
		warn("RaycastModule.CheckForNearbySurface: No entity provided!")
		return false
	end

	local origin
	if entity:IsA("Model") then
		local primaryPart = entity.PrimaryPart
			or entity:FindFirstChild("HumanoidRootPart")
			or entity:FindFirstChildWhichIsA("BasePart")
		if not primaryPart then
			warn("RaycastModule.CheckForNearbySurface: Model has no valid part!")
			return false
		end
		origin = primaryPart.Position
	elseif entity:IsA("BasePart") then
		origin = entity.Position
	else
		warn("RaycastModule.CheckForNearbySurface: Unsupported entity type (" .. entity.ClassName .. ")")
		return false
	end

	local rayParams = RaycastParams.new()
	local ignoreList = RaycastIgnoreModule.GetIgnoreList()
	table.insert(ignoreList, entity)
	rayParams.FilterDescendantsInstances = ignoreList
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	-- Directions to check: up, down, forward, backward, left, right
	local directions = {
		Vector3.new(0, -1, 0),
		Vector3.new(0, 1, 0),
		Vector3.new(1, 0, 0),
		Vector3.new(-1, 0, 0),
		Vector3.new(0, 0, 1),
		Vector3.new(0, 0, -1),
	}

	-- Optional: add diagonals for extra coverage
	for _, dir in ipairs({
		Vector3.new(1, -1, 0),
		Vector3.new(-1, -1, 0),
		Vector3.new(0, -1, 1),
		Vector3.new(0, -1, -1),
	}) do
		table.insert(directions, dir.Unit)
	end

	-- Perform multiple raycasts
	for _, dir in ipairs(directions) do
		local result = workspace:Raycast(origin, dir * maxDistance, rayParams)
		if result then
			local distance = (origin - result.Position).Magnitude
			return true, result, distance
		end
	end

	return false, nil, nil
end

return RaycastModule
