-- CombatUtils.lua
local CombatUtils = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CooldownUpdateEvent = Instance.new("RemoteEvent")
CooldownUpdateEvent.Name = "CooldownUpdateEvent"
CooldownUpdateEvent.Parent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BasicCombat"):WaitForChild("UI")

local slidingPlayers = {}

local activeVelocities = {}
local heartbeatConnections = {}

local SLIDE_ANIM_ID = 100879728251436

-- Slide configuration
local SLIDE_SETTINGS = {
	BaseSpeed = 55,
	MaxMultiplier = 2,
	SpeedChangeRate = {
		Forward = 1,
		Upward = 2,
		Downward = 1,
	},
	PushVelocity = {
		Forward = 50,
		Up = 50,
	},
	PushOnCancel = true,
}

local Debris = game:GetService("Debris")

-- Constants
local BLOCK_DAMAGE_REDUCTION = 0.1 -- 90% damage reduction

-- Constants
local BLOCK_REGEN_DELAY = 5 -- seconds to wait before regen starts
local BLOCK_REGEN_RATE = 2 -- HP per second regenerated
local BLOCK_MAX_HP = 40 -- maximum block HP

--services
local RunService = game:GetService("RunService")

local AnimationModule = require(script.Parent.AnimationModule)
local CombatManager = require(
	game:GetService("ServerScriptService")
		:WaitForChild("BasicCombat")
		:WaitForChild("Managers")
		:WaitForChild("CombatManager")
)

-- Function to return modified damage based on blocking state
function CombatUtils.ReturnDamage(character, damage)
	local isBlocking = character:FindFirstChild("isBlocking")
	local blockHP = CombatUtils.GetBlockHP(character)

	if isBlocking and isBlocking:IsA("BoolValue") and isBlocking.Value == true and blockHP.Value > 0 then
		blockHP.Value -= damage - (damage * BLOCK_DAMAGE_REDUCTION)
		damage = damage * BLOCK_DAMAGE_REDUCTION
	end

	return damage
end

function CombatUtils.GetActionInProgress(character)
	-- Setup action flag
	if not character then
		print("Cannot GetActionInProgress. Character does not exist")
		return
	end
	local actionFlag = character:FindFirstChild("ActionInProgress") or Instance.new("BoolValue")
	actionFlag.Name = "ActionInProgress"
	actionFlag.Parent = character
	return actionFlag
end

function CombatUtils.SetActionInProgress(character, duration)
	if not character then
		warn("Cannot SetActionInProgress. Character does not exist")
		return
	end

	-- Find or create the flag
	local actionFlag = character:FindFirstChild("ActionInProgress") or Instance.new("BoolValue")
	actionFlag.Name = "ActionInProgress"
	actionFlag.Parent = character
	actionFlag.Value = true

	-- Clear the flag after duration
	task.delay(duration, function()
		-- Ensure the character and flag still exist before clearing
		if character and actionFlag and actionFlag.Parent == character then
			actionFlag.Value = false
		end
	end)

	return actionFlag
end

--[[
function CombatUtils.applyStun(character, duration)
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")

	if not humanoid or not animator then
		return
	end

	-- ⏱️ If already stunned, extend duration
	local stunValue = character:FindFirstChild("Stun")
	if stunValue and stunValue:IsA("NumberValue") then
		stunValue.Value = math.max(stunValue.Value, duration)
		return
	end

	-- 💫 Create the stun tracker
	stunValue = Instance.new("NumberValue")
	stunValue.Name = "Stun"
	stunValue.Value = duration
	stunValue.Parent = character

	-- 🚫 Apply stun effects
	humanoid.WalkSpeed = STUN_SPEED
	humanoid.JumpPower = 0

	-- ⏳ Countdown loop
	task.spawn(function()
		while stunValue.Parent and stunValue.Value > 0 do
			task.wait(0.1)
			if stunValue.Parent then
				stunValue.Value = math.max(0, stunValue.Value - 0.1)
			end
		end

		-- 🧹 Cleanup
		if stunValue and stunValue.Parent then
			stunValue:Destroy()
		end

		-- ✅ Restore original values
		if humanoid then
			humanoid.WalkSpeed = CombatUtils.GetMoveSpeed(character).Value
			humanoid.JumpPower = CombatUtils.GetJumpHeight(character).Value
		end
	end)
end
]]

function CombatUtils.applyStun(character, duration)
	if not character then
		return
	end
	CombatManager.RegisterStun(character, duration)
end

function CombatUtils.GetStun(character)
	local stunValue = character:FindFirstChild("Stun")
	if stunValue then
		return true
	else
		return false
	end
end

function CombatUtils.GetIsBlocking(character)
	-- Setup blocking flag
	local isBlocking = character:FindFirstChild("isBlocking") or Instance.new("BoolValue")
	isBlocking.Name = "isBlocking"
	isBlocking.Parent = character
	return isBlocking
end

function CombatUtils.GetBlockHP(character)
	local blockHP = character:FindFirstChild("BlockHP") or Instance.new("NumberValue")
	blockHP.Name = "BlockHP"
	blockHP.Parent = character
	return blockHP
end

function CombatUtils.GetMoveSpeed(character)
	local moveSpeed = character:FindFirstChild("MoveSpeed") or Instance.new("NumberValue")
	moveSpeed.Name = "MoveSpeed"
	moveSpeed.Parent = character
	return moveSpeed
end

function CombatUtils.SetMoveSpeed(character)
	local moveSpeed = CombatUtils.GetMoveSpeed(character)
	moveSpeed.Value = 24
end

function CombatUtils.GetJumpHeight(character)
	local jumpHeight = character:FindFirstChild("JumpHeight") or Instance.new("NumberValue")
	jumpHeight.Name = "JumpHeight"
	jumpHeight.Parent = character
	return jumpHeight
end

function CombatUtils.SetJumpHeight(character)
	local jumpHeight = CombatUtils.GetJumpHeight(character)
	jumpHeight.Value = 40.996
end

function CombatUtils.StartBlockRegen(character)
	local blockHP = CombatUtils.GetBlockHP(character)
	if not blockHP then
		return
	end

	-- Prevent duplicate regen loops
	if blockHP:FindFirstChild("RegenRunning") then
		return
	end

	-- Create tracking values
	local lastDamageTime = Instance.new("NumberValue")
	lastDamageTime.Name = "LastBlockDamage"
	lastDamageTime.Value = tick()
	lastDamageTime.Parent = blockHP

	local regenFlag = Instance.new("BoolValue")
	regenFlag.Name = "RegenRunning"
	regenFlag.Value = true
	regenFlag.Parent = blockHP

	-- Track last HP value to detect real damage
	local lastValue = blockHP.Value
	blockHP.Changed:Connect(function(newValue)
		if newValue < lastValue then
			-- Only reset timer if block HP decreased
			lastDamageTime.Value = tick()
		end
		lastValue = newValue
	end)

	-- Regen loop
	task.spawn(function()
		while blockHP.Parent and regenFlag.Parent do
			task.wait(0.1)

			local timeSinceDamage = tick() - lastDamageTime.Value
			if timeSinceDamage >= BLOCK_REGEN_DELAY and blockHP.Value < BLOCK_MAX_HP then
				-- Regen at 2 HP per second (0.2 HP every 0.1s)
				blockHP.Value = math.min(BLOCK_MAX_HP, blockHP.Value + (BLOCK_REGEN_RATE * 0.1))
			end
		end
	end)
end

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		CombatUtils.StartBlockRegen(character)
		CombatUtils.GetMoveSpeed(character)
		CombatUtils.SetMoveSpeed(character)
		CombatUtils.GetJumpHeight(character)
		CombatUtils.SetJumpHeight(character)
	end)
end)

--[[
function CombatUtils.ApplyTimedVelocity(
	hrp: BasePart,
	speed: number,
	duration: number,
	velocityName: string?,
	dir: Vector3
)
	local name = velocityName or "CustomVelocity"
	local character = hrp.Parent
	if not character then
		return
	end

	-- Initialize table for this character
	if not activeVelocities[character] then
		activeVelocities[character] = {}
	end

	-- Normalize input direction if non-zero
	local moveDir = dir.Magnitude > 0 and dir.Unit or hrp.CFrame.LookVector

	-- Store this velocity's info
	activeVelocities[character][name] = {
		Direction = moveDir,
		Speed = speed,
		Elapsed = 0,
		Duration = duration,
	}

	-- Ensure a single BodyVelocity exists for stacking
	local bv = hrp:FindFirstChild("StackedVelocity")
	if not bv then
		bv = Instance.new("BodyVelocity")
		bv.Name = "StackedVelocity"
		bv.MaxForce = Vector3.new(1e5, 1e5, 1e5) -- ✅ Allow Y movement
		bv.P = 1250
		bv.Parent = hrp
	end

	-- Heartbeat loop to update stacked velocities
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not hrp.Parent then
			connection:Disconnect()
			activeVelocities[character] = nil
			if bv then
				bv:Destroy()
			end
			return
		end

		local charVelocities = activeVelocities[character]
		if not charVelocities then
			connection:Disconnect()
			if bv then
				bv:Destroy()
			end
			return
		end

		local totalVelocity = Vector3.zero

		-- Update all active velocities safely
		for k, v in pairs(charVelocities) do
			v.Elapsed += dt
			if v.Elapsed >= v.Duration then
				charVelocities[k] = nil
			else
				totalVelocity += hrp.CFrame:VectorToWorldSpace(v.Direction.Unit) * v.Speed
			end
		end

		bv.Velocity = totalVelocity

		-- Cleanup if no velocities remain
		if next(charVelocities) == nil then
			activeVelocities[character] = nil
			connection:Disconnect()
			if bv then
				bv:Destroy()
			end
		end
	end)
end
]]

function CombatUtils.ApplyInstantVelocity(humanoidRootPart: BasePart, boost: Vector3)
	local connection
	connection = RunService.Stepped:Connect(function(_, _)
		local vel = humanoidRootPart.AssemblyLinearVelocity
		humanoidRootPart.AssemblyLinearVelocity = Vector3.new(
			vel.X + boost.X,
			boost.Y, -- overwrite Y cleanly
			vel.Z + boost.Z
		)
		connection:Disconnect() -- only apply once
	end)
end

--[[
function CombatUtils.ApplyTurningVelocity(params)
	local character = params.Character
	local speed = params.Speed
	local duration = params.Duration
	local name = params.Name or "TurningVelocity"
	local dir = params.Direction or Vector3.new(0, 0, -1) -- local-space direction

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	-- Initialize table for this character
	if not activeVelocities[character] then
		activeVelocities[character] = {}
	end

	-- Store this velocity's info (overwrites if same name)
	activeVelocities[character][name] = {
		Direction = dir,
		Speed = speed,
		Elapsed = 0,
		Duration = duration,
	}

	-- Ensure a single BodyVelocity exists for this character
	local bv = hrp:FindFirstChild("StackedVelocity")
	if not bv then
		bv = Instance.new("BodyVelocity")
		bv.Name = "StackedVelocity"
		bv.MaxForce = Vector3.new(1e5, 0, 1e5)
		bv.P = 1250
		bv.Parent = hrp
	end

	-- Heartbeat loop to update all stacked velocities
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not hrp.Parent then
			connection:Disconnect()
			activeVelocities[character] = nil
			if bv then
				bv:Destroy()
			end
			return
		end

		local charVelocities = activeVelocities[character]
		if not charVelocities then
			-- nothing left, cleanup
			connection:Disconnect()
			if bv then
				bv:Destroy()
			end
			return
		end

		local totalVelocity = Vector3.zero

		-- Iterate safely through all active velocities
		for k, v in pairs(charVelocities) do
			v.Elapsed += dt
			if v.Elapsed >= v.Duration then
				charVelocities[k] = nil
			else
				local worldDir = hrp.CFrame:VectorToWorldSpace(v.Direction.Unit)
				totalVelocity += worldDir * v.Speed
			end
		end

		bv.Velocity = totalVelocity

		-- Cleanup if table is empty
		if next(charVelocities) == nil then
			activeVelocities[character] = nil
			connection:Disconnect()
			if bv then
				bv:Destroy()
			end
		end
	end)
end
]]

local function UpdateVelocity(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local totalVelocity = Vector3.zero
	local velocityList = activeVelocities[character]

	for i = #velocityList, 1, -1 do
		local entry = velocityList[i]
		entry.Elapsed += RunService.Heartbeat:Wait()

		if entry.Elapsed >= entry.Duration then
			table.remove(velocityList, i)
		else
			-- Convert local direction to world space
			local worldDir = hrp.CFrame:VectorToWorldSpace(entry.Direction.Unit)
			totalVelocity += worldDir * entry.Speed
		end
	end

	if #velocityList == 0 then
		activeVelocities[character] = nil
		if heartbeatConnections[character] then
			heartbeatConnections[character]:Disconnect()
			heartbeatConnections[character] = nil
		end
	end

	-- Apply velocity through an Attachment constraint (or a BodyVelocity)
	local bv = hrp:FindFirstChild("StackedBV") or Instance.new("BodyVelocity")
	bv.Name = "StackedBV"
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.P = 1250
	bv.Parent = hrp
	bv.Velocity = totalVelocity
end

local function AddVelocity(character, direction: Vector3, speed: number, duration: number)
	if not character or not character:IsA("Model") then
		warn("AddVelocity: invalid character", character)
		return
	end

	if not activeVelocities[character] then
		activeVelocities[character] = {}
	end

	table.insert(activeVelocities[character], {
		Direction = direction,
		Speed = speed,
		Duration = duration,
		Elapsed = 0,
	})

	if not heartbeatConnections[character] then
		heartbeatConnections[character] = RunService.Heartbeat:Connect(function()
			UpdateVelocity(character)
		end)
	end
end

function CombatUtils.ApplyTimedVelocity(character, speed, duration, _, dir)
	AddVelocity(character, dir, speed, duration)
end

function CombatUtils.ApplyTurningVelocity(character, speed, duration, dir)
	AddVelocity(character, dir, speed, duration)
end

-- Helper: Stop the slide
function CombatUtils.StopSlide(player)
	local character = player.Character
	if not character then
		return
	end

	local state = slidingPlayers[character]
	if not state then
		return
	end

	if state.Connection then
		state.Connection:Disconnect()
	end
	if state.BodyVelocity then
		state.BodyVelocity:Destroy()
	end
	if state.Gyro then
		state.Gyro:Destroy()
	end

	slidingPlayers[character] = nil

	AnimationModule.StopAllAnimations(character)
end

-- Start the slide (called by server when player requests)
function CombatUtils.StartSlide(player)
	local character = player.Character
	if not character then
		return false
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return false
	end

	-- prevent double slides
	if slidingPlayers[character] then
		return false
	end

	-- must be grounded
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local groundRay = workspace:Raycast(root.Position, -root.CFrame.UpVector * 5, params)
	if not groundRay then
		return false
	end

	-- ✅ measure slope and current speed
	local velocity = root.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local slopeNormal = groundRay.Normal
	local slopeAngle = math.deg(math.acos(slopeNormal:Dot(Vector3.new(0, 1, 0))))

	-- ✅ Minimum slide speed (adjustable)
	local MIN_SLIDE_SPEED = 28
	local MAX_SLOPE_TO_ALLOW_SLOW_SLIDE = 20

	-- disallow slide if moving too slow and not downhill
	if horizontalSpeed < MIN_SLIDE_SPEED and slopeAngle < MAX_SLOPE_TO_ALLOW_SLOW_SLIDE then
		return false
	end

	-- animation
	AnimationModule.PlayAnimation(character, SLIDE_ANIM_ID, true, Enum.AnimationPriority.Action, 1)

	-- create movers
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(40000, 0, 40000)
	bodyVelocity.Parent = root

	local gyro = Instance.new("BodyGyro")
	gyro.MaxTorque = Vector3.new(3e5, 3e5, 3e5)
	gyro.P = 10000
	gyro.Parent = root

	-- Determine initial slide direction
	local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
	local moveDir
	if horizontalVelocity.Magnitude > 1 then
		moveDir = horizontalVelocity.Unit
	else
		moveDir = root.CFrame.LookVector
	end

	-- ✅ Store slide direction relative to the player's local space
	local localSlideDir = root.CFrame:VectorToObjectSpace(moveDir)

	local previousY = root.Position.Y
	local currentMultiplier = 1

	-- slide loop
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not root.Parent then
			CombatUtils.StopSlide(player)
			return
		end

		local currentY = root.Position.Y
		local deltaY = currentY - previousY
		previousY = currentY

		local ray = workspace:Raycast(root.Position, -root.CFrame.UpVector * 10, params)
		if ray then
			local right = root.CFrame.RightVector
			local up = ray.Normal
			local forward = right:Cross(up)
			gyro.CFrame = CFrame.fromMatrix(root.Position, right, up, forward)
		end

		-- slope-based acceleration logic
		if deltaY < 0.1 and deltaY > -0.1 then
			currentMultiplier -= SLIDE_SETTINGS.SpeedChangeRate.Forward * dt
		elseif deltaY > 0 then
			currentMultiplier -= SLIDE_SETTINGS.SpeedChangeRate.Upward * dt
		else
			currentMultiplier += SLIDE_SETTINGS.SpeedChangeRate.Downward * dt
		end

		currentMultiplier = math.clamp(currentMultiplier, 0, SLIDE_SETTINGS.MaxMultiplier)

		-- ✅ Convert stored local direction back into world space using current player rotation
		local worldSlideDir = root.CFrame:VectorToWorldSpace(localSlideDir)

		-- Apply movement using that rotated direction
		bodyVelocity.Velocity = worldSlideDir * (SLIDE_SETTINGS.BaseSpeed * currentMultiplier)

		-- stop if too slow or airborne
		if currentMultiplier < 0.1 or not ray then
			CombatUtils.StopSlide(player)
		end
	end)

	slidingPlayers[character] = {
		Connection = connection,
		BodyVelocity = bodyVelocity,
		Gyro = gyro,
		LocalSlideDir = localSlideDir,
	}

	return true
end

-- Cancel slide early (e.g., when jumping mid-slide)
function CombatUtils.CancelSlide(player, cancelMultiplier)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	if SLIDE_SETTINGS.PushOnCancel then
		local push = Instance.new("BodyVelocity")
		push.MaxForce = Vector3.new(40000, 40000, 40000)
		push.Velocity = (root.CFrame.LookVector * (SLIDE_SETTINGS.PushVelocity.Forward * (cancelMultiplier or 1)))
			+ (root.CFrame.UpVector * SLIDE_SETTINGS.PushVelocity.Up)
		push.Parent = root
		Debris:AddItem(push, 0.1)
	end

	CombatUtils.StopSlide(player)
end

return CombatUtils
