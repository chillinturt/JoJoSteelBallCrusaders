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

function RaycastModule.RaycastFromCamera(character, maxDistance)
	maxDistance = maxDistance or 500

	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return nil
	end

	local remote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("RequestCameraDirection")
	local cameraDirection = remote:InvokeClient(player)
	if not cameraDirection then
		return nil
	end

	cameraDirection = cameraDirection.Unit

	local origin = character:FindFirstChild("Head") and character.Head.Position
		or character:FindFirstChild("HumanoidRootPart").Position

	if not origin then
		return nil
	end

	local rayParams = RaycastParams.new()
	local ignoreList = RaycastIgnoreModule.GetIgnoreList()
	table.insert(ignoreList, character)

	rayParams.FilterDescendantsInstances = ignoreList
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(origin, cameraDirection * maxDistance, rayParams)

	return result -- 🔥 FULL result (Position, Instance, Normal)
end

-- Same client "camera direction" round trip as RaycastFromCamera, but also
-- returns the raw camera direction alongside the RaycastResult. Callers that
-- need to place something along the camera direction even when the ray hits
-- nothing (e.g. a teleport destination) can't do that from RaycastFromCamera
-- alone, since a miss there just returns nil and the direction is lost.
function RaycastModule.RaycastFromCameraWithDirection(character, maxDistance)
	maxDistance = maxDistance or 500

	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return nil, nil
	end

	local remote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("RequestCameraDirection")
	local cameraDirection = remote:InvokeClient(player)
	if not cameraDirection or cameraDirection.Magnitude == 0 then
		return nil, nil
	end
	cameraDirection = cameraDirection.Unit

	local origin = character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart.Position
		or (character:FindFirstChild("Head") and character.Head.Position)
	if not origin then
		return nil, cameraDirection
	end

	local rayParams = RaycastParams.new()
	local ignoreList = RaycastIgnoreModule.GetIgnoreList()
	table.insert(ignoreList, character)

	rayParams.FilterDescendantsInstances = ignoreList
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(origin, cameraDirection * maxDistance, rayParams)

	return result, cameraDirection
end

-- Checks if entity has clear line of sight to target
function RaycastModule.HasLineOfSight(entity, target, maxDistance)
	maxDistance = maxDistance or 200

	if not entity or not target then
		warn("RaycastModule.HasLineOfSight: Missing entity or target!")
		return false
	end

	-- === Get origin ===
	local originPart
	if entity:IsA("Model") then
		originPart = entity.PrimaryPart or entity:FindFirstChild("HumanoidRootPart") or entity:FindFirstChild("Head")
	elseif entity:IsA("BasePart") then
		originPart = entity
	end

	-- === Get target part ===
	local targetPart
	if target:IsA("Model") then
		targetPart = target.PrimaryPart or target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head")
	elseif target:IsA("BasePart") then
		targetPart = target
	end

	if not originPart or not targetPart then
		warn("RaycastModule.HasLineOfSight: Invalid origin or target part!")
		return false
	end

	local origin = originPart.Position
	local targetPos = targetPart.Position
	local direction = targetPos - origin
	local distance = direction.Magnitude

	-- Optional distance cap
	if distance > maxDistance then
		return false
	end

	direction = direction.Unit

	-- === Raycast setup ===
	local rayParams = RaycastParams.new()
	local ignoreList = RaycastIgnoreModule.GetIgnoreList()

	table.insert(ignoreList, entity)
	table.insert(ignoreList, target) -- ignore target model so we can detect it properly

	rayParams.FilterDescendantsInstances = ignoreList
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	-- === Perform raycast ===
	local result = workspace:Raycast(origin, direction * distance, rayParams)

	-- === LOS logic ===
	if result then
		-- Something is blocking the view
		return false, result
	else
		-- Nothing hit → clear line of sight
		return true, nil
	end
end

return RaycastModule
