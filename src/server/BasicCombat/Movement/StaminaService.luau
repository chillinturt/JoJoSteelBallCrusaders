local StaminaService = {}

-- ServerScriptService/BasicCombat/DashHandler.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
--local TalentService = require(game.ServerScriptService.DataSaving.Upgrades:WaitForChild("TalentsModule"))

local DashAnimations = {
	Forward = 116488788576301, -- replace with your Forward dash animation ID
	Backward = 71493580132157, -- replace with your Backward dash animation ID
	Left = 119476538755231, -- replace with your Left dash animation ID
	Right = 129728193718537, -- replace with your Right dash animation ID
}

-- Settings
local BASE_STAMINA = 2
local BASE_RECHARGE_TIME = 5 -- seconds per charge
local RECHARGE_REDUCTION_SCALING = 0.6
local BASE_DASH_FORCE = 50
local DASH_FORCE_SCALING = 16
local DASH_DURATION = 0.6
local DASH_COOLDOWN = 0.75 -- new delay between dashes
local REGEN_STEP = 0.05 -- update rate (seconds)

local DOUBLE_JUMP_Y = 50 -- should match/approx client value
local DOUBLE_JUMP_DURATION = 0.1

-- Per-player dash state
local dashData = {}
local playerJumpData = {}

-- Memory storage
local doubleJumpState = {} -- [character] = bool
local wallJumpState = {} -- [character] = bool

local function getMaxCharges(player)
	local dashInfo = dashData[player]

	if not dashInfo then
		return BASE_STAMINA
	end

	local staminaPoints = dashInfo.staminaPoints or 0

	return BASE_STAMINA + staminaPoints
end

-- Initialize double jump state for a player
local function setupDoubleJump(player)
	playerJumpData[player] = {
		canDoubleJump = false,
	}
end

local dashUpdateEvent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("DashUpdateEvent")

-- Helper to sync charges to client
local function updateClient(player)
	local data = dashData[player]
	if not data then
		return
	end

	dashUpdateEvent:FireClient(player, {
		charges = data.charges,
		maxCharges = data.maxCharges,
	})
end

function StaminaService.SetStamina(player, staminaPoints)
	local data = dashData[player]
	if not data then
		return
	end

	-- Store upgrade points
	data.staminaPoints = staminaPoints or 0

	-- Recalculate max stamina
	local newMax = BASE_STAMINA + data.staminaPoints
	data.maxCharges = newMax

	-- Clamp current stamina so it never exceeds max
	data.charges = math.clamp(data.charges, 0, newMax)

	-- Update UI
	updateClient(player)
end

function StaminaService.RefreshStamina(player)
	local data = dashData[player]
	if not data then
		return
	end

	local newMax = getMaxCharges(player)

	-- Update max
	data.maxCharges = newMax

	-- Clamp charges so they never exceed the new max
	data.charges = math.clamp(data.charges, 0, newMax)

	updateClient(player)
end

-- Recharge loop for each player
local function startRecharge(player)
	local data = dashData[player]
	if not data then
		return
	end

	if data.recharging then
		return
	end

	data.recharging = true

	task.spawn(function()
		while data and data.charges < data.maxCharges do
			local staminaPoints = getMaxCharges(player) - BASE_STAMINA
			local regenRate = 1 / (BASE_RECHARGE_TIME - staminaPoints * RECHARGE_REDUCTION_SCALING)
			local regenAmount = regenRate * REGEN_STEP

			data.charges = math.min(data.maxCharges, data.charges + regenAmount)

			updateClient(player)

			task.wait(REGEN_STEP)
		end

		if data then
			data.recharging = false
		end
	end)
end

function StaminaService.OnDashRequest(player, dirLabel)
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
	if data.charges < 1 then
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

	local staminaPoints = getMaxCharges(player) - BASE_STAMINA

	CombatUtils.ApplyTurningVelocity({
		Character = character,
		Speed = BASE_DASH_FORCE + staminaPoints * DASH_FORCE_SCALING,
		Duration = DASH_DURATION,
		Direction = dashDir, -- Local direction
	})

	AnimationModule.PlayAnimation(character, DashAnimations[dirLabel], false, 1, 1)
	SoundModule.PlaySound({
		Root = humanoidRootPart,
		soundName = "Dash",
		soundID = "6128977275",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 400,
	})

	-- Start recharge if not full
	if data.charges < data.maxCharges then
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

local function GetWallJumpAvailable(character)
	if not character then
		return false
	end

	-- Initialize default value
	if wallJumpState[character] == nil then
		wallJumpState[character] = true
	end

	return wallJumpState[character]
end

local function SetWallJumpAvailable(character, state)
	if not character then
		return
	end

	wallJumpState[character] = state
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

	local wallJumpVal = GetWallJumpAvailable(character)
	if not wallJumpVal then
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

	doubleJumpState[character] = value
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
			--this fixes the double wall jump tech, but feels slow in game. save for later
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
		return false
	end

	-- Initialize if missing
	if doubleJumpState[character] == nil then
		doubleJumpState[character] = false

		-- Reset when grounded
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
				if humanoid.FloorMaterial ~= Enum.Material.Air then
					doubleJumpState[character] = false
				end
			end)
		end
	end

	return doubleJumpState[character]
end

function StaminaService.OnJumpRequest(player)
	local character = player.Character
	if not character then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		return
	end

	-- Cannot jump while stunned or blocking
	if CombatUtils.GetStun(character) then
		return
	end
	if CombatUtils.IsBlocking(character) then
		return
	end

	-- Must be airborne for wall/double jumps
	if not isAirborne(hrp) then
		return
	end

	local dashInfo = dashData[player]
	if not dashInfo then
		return
	end
	if CombatUtils.IsDashing(character) then
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
	elseif not GetDoubleJump(character) and isAirborne(hrp) then
		if dashInfo.charges < 1 then
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
	})

	print(jumpType .. " performed on server")

	-- Start recharge if needed (double jump only)
	if consumeStamina and dashInfo.charges < dashInfo.maxCharges then
		startRecharge(player)
	end

	CombatUtils.SetIsDashing(character, DOUBLE_JUMP_DURATION)
end

local function initCharacter(player, character)
	-- Refresh UI on respawn
	updateClient(player)

	-- Character-specific setup
	setupDoubleJump(player)
	GetWallJumpAvailable(character)

	task.spawn(function()
		monitorGroundState(character)
	end)
end

function StaminaService.InitPlayer(player)
	if dashData[player] then
		return
	end

	local maxCharges = getMaxCharges(player)

	-- Initialize stamina/dash memory ONCE
	dashData[player] = {
		charges = maxCharges,
		maxCharges = maxCharges,
		staminaPoints = 0,
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

function StaminaService.RemovePlayer(player)
	dashData[player] = nil
	playerJumpData[player] = nil
end

return StaminaService
