-- ServerScriptService/BasicCombat/DashHandler.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local dashEvent = Instance.new("RemoteEvent")
dashEvent.Name = "DashEvent"
dashEvent.Parent = ReplicatedStorage.Shared.BasicCombat

local dashUpdateEvent = Instance.new("RemoteEvent")
dashUpdateEvent.Name = "DashUpdateEvent"
dashUpdateEvent.Parent = ReplicatedStorage.Shared.BasicCombat

local doubleJumpEvent = Instance.new("RemoteEvent") -- RemoteEvent
doubleJumpEvent.Name = "DoubleJumpEvent"
doubleJumpEvent.Parent = ReplicatedStorage.Shared.BasicCombat

local wallJumpEvent = Instance.new("RemoteEvent") -- RemoteEvent
wallJumpEvent.Name = "WallJumpEvent"
wallJumpEvent.Parent = ReplicatedStorage.Shared.BasicCombat

local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))

local DashAnimations = {
	Forward = 116488788576301, -- replace with your Forward dash animation ID
	Backward = 71493580132157, -- replace with your Backward dash animation ID
	Left = 119476538755231, -- replace with your Left dash animation ID
	Right = 129728193718537, -- replace with your Right dash animation ID
}

-- Settings
local MAX_CHARGES = 3
local RECHARGE_TIME = 3 -- seconds per charge
local DASH_FORCE = 50
local DASH_DURATION = 0.5
local DASH_COOLDOWN = 0.75 -- new delay between dashes

local DOUBLE_JUMP_Y = 50 -- should match/approx client value
local DOUBLE_JUMP_DURATION = 0.1

-- Per-player dash state
local dashData = {}
local playerJumpData = {}

-- Initialize double jump state for a player
local function setupDoubleJump(player)
	playerJumpData[player] = {
		canDoubleJump = false,
	}
end

-- Helper to sync charges to client
local function updateClient(player)
	local data = dashData[player]
	if data then
		dashUpdateEvent:FireClient(player, data.charges)
	end
end

-- Recharge loop for each player
local function startRecharge(player)
	local data = dashData[player]
	if not data then
		return
	end

	-- already running?
	if data.recharging then
		return
	end
	data.recharging = true

	task.spawn(function()
		while data and data.charges < MAX_CHARGES do
			task.wait(RECHARGE_TIME)
			if not data then
				return
			end
			data.charges = math.min(MAX_CHARGES, data.charges + 1)
			updateClient(player)
		end
		if data then
			data.recharging = false
		end
	end)
end

local function onDashRequested(player, dirLabel)
	print("dash requested")
	-- Validate player & character
	local character = player and player.Character
	if not character then
		print("No character")
		return
	end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		print("no HRP")
		return
	end
	if CombatUtils.GetStun(character) then
		print("stunned!")
		return
	end
	if CombatUtils.IsBlocking(character) then
		print("isblocking")
		return
	end
	if CombatUtils.IsDashing(character) then
		print("movement ability in progress...")
		return
	end

	local data = dashData[player]
	if not data then
		print("no dash data")
		return
	end

	-- cooldown check
	local now = tick()
	if data.lastDashTime and (now - data.lastDashTime) < DASH_COOLDOWN then
		print("on cooldown")
		return -- too soon
	end

	-- Not enough charges
	if data.charges <= 0 then
		print("no charges")
		return
	end

	-- Validate dirLabel
	if typeof(dirLabel) ~= "string" then
		dirLabel = "Forward"
	end

	-- consume a charge and inform client
	data.charges = data.charges - 1
	data.lastDashTime = now -- record last dash time
	updateClient(player)

	-- Compute world-space dash direction
	local dashDir = Vector3.new(0, 0, 0)

	if dirLabel == "Forward" then
		dashDir = Vector3.new(0, 0, -1)
	elseif dirLabel == "Backward" then
		dashDir = Vector3.new(0, 0, 1)
	elseif dirLabel == "Left" then
		dashDir = Vector3.new(-1, 0, 0)
	elseif dirLabel == "Right" then
		dashDir = Vector3.new(1, 0, 0)
	else
		dashDir = Vector3.new(0, 0, -1)
	end

	CombatUtils.ApplyTurningVelocity({
		Character = character,
		Speed = DASH_FORCE,
		Duration = DASH_DURATION,
		Direction = dashDir, -- Local direction
	})

	AnimationModule.PlayAnimation(character, DashAnimations[dirLabel], false, 1, 1)
	SoundModule.PlaySound({
		Root = humanoidRootPart,
		soundName = "Dash",
		soundID = "6128977275",
		volume = 1.5,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	-- Start recharge if not full
	if data.charges < MAX_CHARGES then
		startRecharge(player)
	end

	CombatUtils.SetIsDashing(character, DASH_DURATION)
	print("dash finished!")
end

local function isAirborne(rootPart)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { rootPart.Parent }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local result = workspace:Raycast(rootPart.Position, Vector3.new(0, -4, 0), params)
	return result == nil
end

local function isNextToWall(rootPart, checkDistance)
	checkDistance = checkDistance or 3 -- how far to check horizontally

	if not rootPart or not rootPart.Parent then
		return false
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { rootPart.Parent }
	params.FilterType = Enum.RaycastFilterType.Exclude

	local rootCFrame = rootPart.CFrame
	local directions = {
		rootCFrame.LookVector, -- front
		-rootCFrame.LookVector, -- back
		rootCFrame.RightVector, -- right
		-rootCFrame.RightVector, -- left
	}

	for _, dir in ipairs(directions) do
		local result = workspace:Raycast(rootPart.Position, dir * checkDistance, params)
		if result then
			-- Optional: check if the surface is roughly vertical to avoid counting the floor
			local normal = result.Normal
			if math.abs(normal.Y) < 0.5 then
				return true, result
			end
		end
	end

	return false
end

-- === Mantle Detection ===
local function canMantle(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character }
	params.FilterType = Enum.RaycastFilterType.Exclude

	-- Raycast forward to detect wall
	local forwardRay = workspace:Raycast(rootPart.Position, rootPart.CFrame.LookVector * 3, params)
	if forwardRay then
		-- Check above ledge: is there open space to climb?
		local upwardRay = workspace:Raycast(forwardRay.Position, Vector3.new(0, 3, 0), params)
		if not upwardRay then
			return true
		end
	end

	return false
end

-- checks if a player can wall jump
local function getWallJumpValue(character)
	local val = character:FindFirstChild("CanWallJump")
	if not val then
		val = Instance.new("BoolValue")
		val.Name = "CanWallJump"
		val.Value = true
		val.Parent = character
	end
	return val
end

local function SetWallJumpAvailable(character, state)
	local val = getWallJumpValue(character)
	val.Value = state
end

local function isGrounded(rootPart)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { rootPart.Parent }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local result = workspace:Raycast(rootPart.Position, Vector3.new(0, -3.5, 0), params)
	return result ~= nil
end

local function isNearWall(rootPart)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { rootPart.Parent }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local directions = {
		Vector3.new(1, 0, 0),
		Vector3.new(-1, 0, 0),
		Vector3.new(0, 0, 1),
		Vector3.new(0, 0, -1),
	}
	for _, dir in ipairs(directions) do
		local result = workspace:Raycast(rootPart.Position, dir * 3, params)
		if result then
			return true
		end
	end
	return false
end

-- ✅ Main logic
local function canWallJump(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end

	local wallJumpVal = getWallJumpValue(character)
	if not wallJumpVal.Value then
		return false
	end

	if not isGrounded(rootPart) and isNearWall(rootPart) then
		return true
	end

	return false
end

local function SetDoubleJump(character, value)
	if not character then
		return
	end

	local hasDoubleJumped = character:FindFirstChild("HasDoubleJumped")
	if not hasDoubleJumped then
		hasDoubleJumped = Instance.new("BoolValue")
		hasDoubleJumped.Name = "HasDoubleJumped"
		hasDoubleJumped.Value = false
		hasDoubleJumped.Parent = character
	end

	hasDoubleJumped.Value = value
end

-- ✅ Improved Ground Monitor with delay to prevent false resets
local function monitorGroundState(character)
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local wasGrounded = false
	local groundedTime = 0
	--local groundedThreshold = 0.01 -- seconds required on ground before resetting

	while task.wait(0.05) do
		if not rootPart.Parent then
			break
		end

		local grounded = isGrounded(rootPart)

		if grounded then
			--this fixes the double wall jump tech, but feels slow in game
			--[[
			if not wasGrounded then
				-- Just became grounded — start counting
				groundedTime = time()
			elseif time() - groundedTime >= groundedThreshold then
				-- Stayed grounded long enough → reset wall jump availability
				SetWallJumpAvailable(character, true)
				SetDoubleJump(character, false)
			end
			]]

			SetWallJumpAvailable(character, true)
			SetDoubleJump(character, false)
		else
			-- Reset timer when leaving ground
			groundedTime = 0
		end

		wasGrounded = grounded
	end
end

local function GetDoubleJump(character)
	if not character then
		return nil
	end

	local hasDoubleJumped = character:FindFirstChild("HasDoubleJumped")
	if not hasDoubleJumped then
		hasDoubleJumped = Instance.new("BoolValue")
		hasDoubleJumped.Name = "HasDoubleJumped"
		hasDoubleJumped.Value = false
		hasDoubleJumped.Parent = character

		-- Reset when grounded
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
				if humanoid.FloorMaterial ~= Enum.Material.Air then
					hasDoubleJumped.Value = false
				end
			end)
		end
	end

	return hasDoubleJumped
end

local function onJumpRequest(player)
	local character = player.Character
	if not character then
		print("no character")
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		print("no hrp")
		return
	end

	-- Cannot jump while stunned or blocking
	if CombatUtils.GetStun(character) then
		print("stun")
		return
	end
	if CombatUtils.IsBlocking(character) then
		print("blocking,..")
		return
	end

	-- Must be airborne for wall/double jumps
	if not isAirborne(hrp) then
		print("not airborne")
		return
	end

	local dashInfo = dashData[player]
	if not dashInfo then
		print("no dashinfo")
		return
	end
	if CombatUtils.IsDashing(character) then
		print("movement ability in progress...")
		return
	end

	-- Determine jump type
	local jumpType = nil
	local consumeStamina = true
	local soundID = "7043834737" -- default double jump sound

	if canWallJump(character) then
		jumpType = "WallJump"
		consumeStamina = false -- wall jump does not consume stamina
		soundID = "6817149752" -- replace with wall jump sound ID
		SetWallJumpAvailable(character, false)
	elseif not GetDoubleJump(character).Value and isAirborne(hrp) then
		if dashInfo.charges <= 0 then
			print("no charges")
			return
		end
		jumpType = "DoubleJump"
		SetDoubleJump(character, true)
	else
		-- No jump available
		return
	end

	-- Consume a dash charge only if it's a double jump
	if consumeStamina then
		dashInfo.charges -= 1
		updateClient(player)
	end

	-- Apply upward force
	task.defer(function()
		CombatUtils.ApplyTimedVelocity(hrp, DOUBLE_JUMP_Y, DOUBLE_JUMP_DURATION, jumpType, Vector3.new(0, 1, 0))
	end)

	-- Play animation & sound
	AnimationModule.PlayAnimation(character, "121074387087243", false, 1, 1)
	SoundModule.PlaySound({
		Root = hrp,
		soundName = jumpType,
		soundID = soundID,
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	print(jumpType .. " performed on server")

	-- Start recharge if needed (double jump only)
	if consumeStamina and dashInfo.charges < MAX_CHARGES then
		startRecharge(player)
	end
	CombatUtils.SetIsDashing(character, DOUBLE_JUMP_DURATION)
end

local function initCharacter(player, character)
	-- Refresh UI on respawn
	updateClient(player)

	-- Character-specific setup
	setupDoubleJump(player)
	getWallJumpValue(character)

	task.spawn(function()
		monitorGroundState(character)
	end)
end

local function initPlayer(player)
	if dashData[player] then
		return
	end

	-- Initialize stamina/dash memory ONCE
	dashData[player] = {
		charges = MAX_CHARGES,
		recharging = false,
		lastDashTime = 0,
	}

	playerJumpData[player] = playerJumpData[player] or {}

	updateClient(player)
	setupDoubleJump(player)

	-- Handle existing character
	if player.Character then
		initCharacter(player, player.Character)
	end

	-- Handle future respawns
	player.CharacterAdded:Connect(function(character)
		initCharacter(player, character)
	end)

	-- Cleanup on leave
	player.CharacterRemoving:Connect(function(character)
		-- Character-specific cleanup if needed
	end)
end

-- Existing players (THIS FIXES YOUR BUG)
for _, player in ipairs(Players:GetPlayers()) do
	initPlayer(player)
end

-- Future players
Players.PlayerAdded:Connect(initPlayer)

Players.PlayerRemoving:Connect(function(player)
	dashData[player] = nil
	playerJumpData[player] = nil
end)

-- Listen for dash requests
dashEvent.OnServerEvent:Connect(onDashRequested)
doubleJumpEvent.OnServerEvent:Connect(onJumpRequest)
