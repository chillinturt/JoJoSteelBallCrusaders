-- CombatUtils.lua
local CombatUtils = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CooldownUpdateEvent = Instance.new("RemoteEvent")
CooldownUpdateEvent.Name = "CooldownUpdateEvent"
CooldownUpdateEvent.Parent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BasicCombat"):WaitForChild("UI")

local SpecCooldownUpdateEvent = Instance.new("RemoteEvent")
SpecCooldownUpdateEvent.Name = "SpecCooldownUpdateEvent"
SpecCooldownUpdateEvent.Parent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BasicCombat"):WaitForChild("UI")

local slidingPlayers = {}

local activeVelocities = {}
local heartbeatConnections = {}
local baseVelocities = {}

local SLIDE_ANIM_ID = 100879728251436

-- Basic collision parameters
local RAYCAST_PARAMS = RaycastParams.new()
RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude

-- Slide configuration
local SLIDE_SETTINGS = {
	BaseSpeed = 65,
	MaxMultiplier = 1.75,
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
local HamonDamageReduction = 0.75 -- 25% damage reduction

-- Constants
local BLOCK_REGEN_DELAY = 5 -- seconds to wait before regen starts
local BLOCK_REGEN_RATE = 2 -- HP per second regenerated
local BLOCK_MAX_HP = 80 -- maximum block HP

local VAMPIRE_DAMAGE_BUFF = 1.25 -- 25%

local activeBarriers = {}
local BARRIER_COLOR = Color3.fromRGB(0, 170, 255) -- optional visual cue
local BARRIER_DECAY_RATE = 1 -- set to >0 if barrier should decay over time

--services
local RunService = game:GetService("RunService")

local AnimationModule = require(script.Parent.AnimationModule)
local VampireModule = require(game.ServerScriptService.BasicCombat.RaceScripts:WaitForChild("Vampire"))
local CombatManager = require(
	game:GetService("ServerScriptService")
		:WaitForChild("BasicCombat")
		:WaitForChild("Managers")
		:WaitForChild("CombatManager")
)

-- Function to return modified damage based on blocking state
function CombatUtils.ReturnDamage(character, damage, canBlock, attacker)
	local isBlocking = character:FindFirstChild("isBlocking")
	local blockHP = CombatUtils.GetBlockHP(character)

	local newDamage = damage

	local damageMult = CombatUtils.GetDamageMult(character)
	if damageMult then
		newDamage = newDamage * damageMult
	end

	local isVamp = VampireModule.getIsVampireRace(attacker)
	if isVamp then
		--Apply Vampire blood buff if applicable
		if VampireModule.spendBlood(attacker, damage / 3) then
			newDamage = newDamage * VAMPIRE_DAMAGE_BUFF
		end
	else
		print("Not a vampire, did not apply damage buff")
	end

	-- Apply Hamon damage reduction if applicable
	local hamonMeter = character:FindFirstChild("HamonMeter")
	if hamonMeter and hamonMeter.Value > 0 then
		newDamage = damage * HamonDamageReduction
	end

	-- If blocking is allowed
	if canBlock and isBlocking and isBlocking:IsA("BoolValue") and isBlocking.Value == true and blockHP.Value > 0 then
		-- Calculate the reduced damage that the block tries to absorb
		local reducedDamage = newDamage * (1 - BLOCK_DAMAGE_REDUCTION)

		-- If block HP can fully absorb the reduced damage
		if blockHP.Value >= reducedDamage then
			blockHP.Value -= reducedDamage
			newDamage = newDamage * BLOCK_DAMAGE_REDUCTION -- player only takes reduced damage
		else
			-- Block HP runs out; calculate leftover damage
			local remainingDamage = reducedDamage - blockHP.Value
			blockHP.Value = 0

			-- The leftover goes through at full damage rate (since block is broken)
			newDamage = (newDamage * BLOCK_DAMAGE_REDUCTION) + remainingDamage
		end
	end

	return newDamage
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
	local blockHP = character:FindFirstChild("BlockHP")
	if not blockHP then
		blockHP = Instance.new("NumberValue")
		blockHP.Name = "BlockHP"
		blockHP.Parent = character
		blockHP.Value = 80
	end

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

function CombatUtils.ApplyTimedVelocity(
	humanoidRootPart: BasePart,
	speed: number,
	duration: number,
	velocityName: string?,
	dir: Vector3
)
	local name = velocityName or "CustomVelocity"

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = name
	bodyVelocity.P = 1250
	bodyVelocity.Parent = humanoidRootPart

	-- Normalize input direction if it's not zero
	local moveDirection = dir.Magnitude > 0 and dir.Unit or humanoidRootPart.CFrame.LookVector

	-- Only apply force on specified axes
	bodyVelocity.MaxForce = Vector3.new(dir.X ~= 0 and 1e5 or 0, dir.Y ~= 0 and 1e5 or 0, dir.Z ~= 0 and 1e5 or 0)

	local elapsed = 0
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if elapsed >= duration then
			bodyVelocity:Destroy()
			connection:Disconnect()
			return
		end

		-- Only set velocity for the axes we care about
		local targetVel = Vector3.new(
			dir.X ~= 0 and moveDirection.X * speed or 0,
			dir.Y ~= 0 and moveDirection.Y * speed or 0,
			dir.Z ~= 0 and moveDirection.Z * speed or 0
		)

		bodyVelocity.Velocity = targetVel
		elapsed += deltaTime
	end)
end

function CombatUtils.ApplyDamageMult(char, mult, duration)
	local damageMult = Instance.new("NumberValue")
	damageMult.Value = mult
	damageMult.Name = "DamageMultiplier"
	damageMult.Parent = char
	Debris:AddItem(damageMult, duration)
end

function CombatUtils.GetDamageMult(char)
	local damageMult = char:FindFirstChild("DamageMultiplier")
	if not damageMult then
		return 1
	end
	if damageMult and damageMult.Value then
		return damageMult.Value
	end
	return 1
end

--[[
function CombatUtils.ApplyTurningVelocity(character, speed, duration, dir)
	CombatUtils.AddVelocity(character, dir, speed, duration)
end
]]

--[[
function CombatUtils.ApplyTimedVelocity(character, speed, duration, _, dir)
	CombatUtils.AddVelocity(character, dir, speed, duration)
end
]]

-- Main velocity update
local function UpdateVelocity(character, dt)
	local totalVelocity = Vector3.zero
	local velocityList = activeVelocities[character]

	if velocityList then
		for i = #velocityList, 1, -1 do
			local entry = velocityList[i]
			entry.Elapsed += dt
			if entry.Elapsed >= entry.Duration then
				table.remove(velocityList, i)
			else
				local dir = entry.Direction.Unit
				totalVelocity += dir * entry.Speed
			end
		end
	end

	if baseVelocities[character] then
		totalVelocity += baseVelocities[character]
	end

	return totalVelocity
end

-- Exposed API
function CombatUtils.AddVelocity(character, direction: Vector3, speed: number, duration: number)
	if not character or not character:IsA("Model") then
		return
	end

	activeVelocities[character] = activeVelocities[character] or {}
	table.insert(activeVelocities[character], {
		Direction = direction,
		Speed = speed,
		Duration = duration,
		Elapsed = 0,
	})

	if not heartbeatConnections[character] then
		local lastTime = os.clock()
		heartbeatConnections[character] = RunService.Heartbeat:Connect(function()
			local now = os.clock()
			local dt = now - lastTime
			lastTime = now
			UpdateVelocity(character, dt)
		end)
	end
end

function CombatUtils.SetBaseVelocity(character, velocity)
	if not character or not character:IsA("Model") then
		return
	end
	baseVelocities[character] = velocity
end

function CombatUtils.GetTotalVelocity(character)
	return UpdateVelocity(character, RunService.Heartbeat:Wait())
end

function CombatUtils.Clear(character)
	activeVelocities[character] = nil
	baseVelocities[character] = nil
	if heartbeatConnections[character] then
		heartbeatConnections[character]:Disconnect()
		heartbeatConnections[character] = nil
	end
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

	if CombatUtils.GetIsDashing(character) then
		return
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
	local airTime = 0
	local AIR_GRACE_PERIOD = 0.5 -- seconds

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
			airTime = 0 -- reset timer when on ground
			local right = root.CFrame.RightVector
			local up = ray.Normal
			local forward = right:Cross(up)
			gyro.CFrame = CFrame.fromMatrix(root.Position, right, up, forward)
		else
			airTime += dt -- accumulate time in air
		end

		-- slope-based acceleration logic...
		if deltaY < 0.1 and deltaY > -0.1 then
			currentMultiplier -= SLIDE_SETTINGS.SpeedChangeRate.Forward * dt
		elseif deltaY > 0 then
			currentMultiplier -= SLIDE_SETTINGS.SpeedChangeRate.Upward * dt
		else
			currentMultiplier += SLIDE_SETTINGS.SpeedChangeRate.Downward * dt
		end
		currentMultiplier = math.clamp(currentMultiplier, 0, SLIDE_SETTINGS.MaxMultiplier)

		local worldSlideDir = root.CFrame:VectorToWorldSpace(localSlideDir)
		bodyVelocity.Velocity = worldSlideDir * (SLIDE_SETTINGS.BaseSpeed * currentMultiplier)

		-- stop if too slow or in air for too long
		if currentMultiplier < 0.1 or airTime >= AIR_GRACE_PERIOD then
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

function CombatUtils.SetIsDashing(character, duration)
	if not character or not duration then
		return
	end

	-- Try to find an existing BoolValue; create one if it doesn't exist
	local isDashing = character:FindFirstChild("IsDashing")
	if not isDashing then
		isDashing = Instance.new("BoolValue")
		isDashing.Name = "IsDashing"
		isDashing.Value = true
		isDashing.Parent = character
	else
		isDashing.Value = true
	end

	-- After the dash duration, reset it
	task.delay(duration, function()
		if isDashing and isDashing.Parent then
			isDashing.Value = false
		end
	end)
end

function CombatUtils.GetIsDashing(character)
	if not character then
		return false
	end

	local isDashing = character:FindFirstChild("IsDashing")
	if isDashing and isDashing:IsA("BoolValue") then
		return isDashing.Value
	end

	return false
end

-- === Add a barrier to a character ===
function CombatUtils.AddBarrier(character, amount)
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- Initialize or refresh barrier entry
	activeBarriers[character] = {
		Max = amount,
		Current = amount,
	}

	-- Optional: attach a visual effect
	local barrierEffect = character:FindFirstChild("BarrierEffect")
	if not barrierEffect then
		barrierEffect = Instance.new("Highlight")
		barrierEffect.FillColor = BARRIER_COLOR
		barrierEffect.OutlineTransparency = 1
		barrierEffect.Name = "BarrierEffect"
		barrierEffect.Parent = character
	end

	-- Hook damage interception if not already hooked
	if not humanoid:GetAttribute("BarrierHooked") then
		humanoid:SetAttribute("BarrierHooked", true)

		local lastHealth = humanoid.Health
		humanoid.HealthChanged:Connect(function(newHealth)
			local data = activeBarriers[character]
			if not data then
				lastHealth = newHealth
				return
			end

			local delta = newHealth - lastHealth

			-- If health decreased, damage occurred
			if delta < 0 and data.Current > 0 then
				local damageTaken = -delta
				local absorb = math.min(data.Current, damageTaken)

				data.Current -= absorb

				-- Prevent the health loss from the absorbed damage (no healing!)
				humanoid.Health = lastHealth - (damageTaken - absorb)

				-- If the barrier is depleted, remove it
				if data.Current <= 0 then
					activeBarriers[character] = nil
					if character:FindFirstChild("BarrierEffect") then
						character.BarrierEffect:Destroy()
					end
				end
			end

			lastHealth = humanoid.Health
		end)
	end

	-- Optional: barrier decay logic
	if BARRIER_DECAY_RATE > 0 then
		task.spawn(function()
			while activeBarriers[character] do
				task.wait(1)
				local data = activeBarriers[character]
				if data then
					data.Current = math.max(0, data.Current - BARRIER_DECAY_RATE)
					if data.Current <= 0 then
						activeBarriers[character] = nil
						if character:FindFirstChild("BarrierEffect") then
							character.BarrierEffect:Destroy()
						end
						break
					end
				end
			end
		end)
	end
end

-- === Get remaining barrier ===
function CombatUtils.GetBarrier(character)
	local data = activeBarriers[character]
	return data and data.Current or 0
end

-- === Remove barrier manually ===
function CombatUtils.RemoveBarrier(character)
	if activeBarriers[character] then
		activeBarriers[character] = nil
	end

	local effect = character:FindFirstChild("BarrierEffect")
	if effect then
		effect:Destroy()
	end
end

return CombatUtils
