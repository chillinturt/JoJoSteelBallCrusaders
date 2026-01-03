-- CombatUtils.lua
local CombatUtils = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local SlowingFieldRegistry = require(ServerScriptService.BasicCombat.Managers.SlowingFieldRegistry)

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
	BaseSpeed = 70,
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
local HAMON_DAMAGE_REDUCTION = 0.8 -- 25% damage reduction

-- Constants
local BLOCK_REGEN_DELAY = 5 -- seconds to wait before regen starts
local BLOCK_REGEN_RATE = 2 -- HP per second regenerated
local BLOCK_MAX_HP = 80 -- maximum block HP
local BLOOD_DRAIN_CONST = 10

local VAMPIRE_DAMAGE_BUFF = 1.2 -- 25%

local activeBarriers = {}
local BARRIER_COLOR = Color3.fromRGB(0, 170, 255) -- optional visual cue

--services
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

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
		if VampireModule.spendBlood(attacker, damage / BLOOD_DRAIN_CONST) then
			newDamage = newDamage * VAMPIRE_DAMAGE_BUFF
		end
	else
		--print("Not a vampire, did not apply damage buff")
	end

	-- Apply Hamon damage reduction if applicable
	local hamonMeter = character:FindFirstChild("HamonMeter")
	if hamonMeter and hamonMeter.Value > 0 then
		newDamage = newDamage * HAMON_DAMAGE_REDUCTION
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
	local player = Players:GetPlayerFromCharacter(character)
	CombatManager.RegisterStun(character, duration)
	if player then
		CombatUtils.StopSlide(player)
	end
end

function CombatUtils.GetStun(character)
	local stunValue = character:FindFirstChild("Stun")
	if stunValue then
		return true
	else
		return false
	end
end

function CombatUtils.GetSlowMultiplier(character)
	local finalMult = SlowingFieldRegistry.GetFinalMultiplier(character)
	return finalMult
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
		local BarrierFolder = Instance.new("Folder")
		BarrierFolder.Name = "BarrierFolder"
		BarrierFolder.Parent = character
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

--[[ Helper: Stop the slide
function CombatUtils.StopSlide(player)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

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

	humanoid:ChangeState(Enum.HumanoidStateType.Running)
end
]]

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

	slidingPlayers[character] = nil

	-- Return to normal movement
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
	end

	AnimationModule.StopAllAnimations(character)
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

--[[
function CombatUtils.StartSlide(player)
    local character = player.Character
    if not character then return false end

    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return false end

    -- Prevent double slides / conflict with dash
    if slidingPlayers[character] then return false end
    if CombatUtils.GetIsDashing(character) then return false end

    -- Ground detection
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { character }
    params.FilterType = Enum.RaycastFilterType.Exclude

    local groundRay = workspace:Raycast(root.Position, -root.CFrame.UpVector * 5, params)
    if not groundRay then return false end

    -- Velocity + slope properties
    local vel = root.AssemblyLinearVelocity
    local flatVel = Vector3.new(vel.X, 0, vel.Z)
    local flatSpeed = flatVel.Magnitude

    local slopeNormal = groundRay.Normal
    local slopeAngle = math.deg(math.acos(slopeNormal:Dot(Vector3.new(0,1,0))))

    local MIN_SLIDE_SPEED = 28
    local MAX_SLOPE_TO_ALLOW_SLOW_SLIDE = 20

    if flatSpeed < MIN_SLIDE_SPEED and slopeAngle < MAX_SLOPE_TO_ALLOW_SLOW_SLIDE then
        return false
    end

    -- Animation
    AnimationModule.PlayAnimation(character, SLIDE_ANIM_ID, true, Enum.AnimationPriority.Action, 1)

    humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    ----------------------------------------------------------------------
    -- 1. Choose initial direction
    ----------------------------------------------------------------------
    local initialDir
    if flatSpeed > 1 then
        initialDir = flatVel.Unit
    else
        local look = root.CFrame.LookVector
        initialDir = Vector3.new(look.X, 0, look.Z).Unit
    end

    ----------------------------------------------------------------------
    -- 2. Project direction onto slope tangent plane
    ----------------------------------------------------------------------
    local function ProjectOntoPlane(v, normal)
        return (v - normal * v:Dot(normal)).Unit
    end

    local slideDirectionWorld = ProjectOntoPlane(initialDir, slopeNormal)

    ----------------------------------------------------------------------
    -- 3. Guarantee minimum launch speed
    ----------------------------------------------------------------------
    local MIN_LAUNCH = 100

    if flatSpeed < MIN_LAUNCH then
        local boosted = slideDirectionWorld * MIN_LAUNCH
        root.AssemblyLinearVelocity = Vector3.new(
            boosted.X,
            vel.Y,
            boosted.Z
        )
    end

    ----------------------------------------------------------------------
    -- Convert slide dir into local space to allow rotation during sliding
    ----------------------------------------------------------------------
    local localSlideDir = root.CFrame:VectorToObjectSpace(slideDirectionWorld)

    local prevY = root.Position.Y
    local currentMultiplier = 1
    local airTime = 0
    local AIR_GRACE = 0.5

    -- State required for StopSlide
    local state = {
        Connection = nil,
        UsingVelocityControl = true -- so StopSlide knows no BodyVelocity exists
    }

    slidingPlayers[character] = state

    state.Connection = RunService.Heartbeat:Connect(function(dt)
        if not root.Parent then
            CombatUtils.StopSlide(player)
            return
        end

        ------------------------------------------------------------------
        -- Ground / slope tracking
        ------------------------------------------------------------------
        local ray = workspace:Raycast(root.Position, -root.CFrame.UpVector * 10, params)

        local posY = root.Position.Y
        local deltaY = posY - prevY
        prevY = posY

        if ray then
            airTime = 0

            -- recompute slope-orientation for alignment
            local up = ray.Normal
            local right = root.CFrame.RightVector
            local forward = right:Cross(up)

            -- optional: reorient player to slope without forcing facing direction
            -- (comment out if undesired)
            -- root.CFrame = CFrame.fromMatrix(root.Position, right, up, forward)
        else
            airTime += dt
        end

        ------------------------------------------------------------------
        -- Slope-based accel/decel
        ------------------------------------------------------------------
        if math.abs(deltaY) < 0.1 then
            currentMultiplier -= SLIDE_SETTINGS.SpeedChangeRate.Forward * dt
        elseif deltaY > 0 then
            currentMultiplier -= SLIDE_SETTINGS.SpeedChangeRate.Upward * dt
        else
            currentMultiplier += SLIDE_SETTINGS.SpeedChangeRate.Downward * dt
        end

        currentMultiplier = math.clamp(currentMultiplier, 0, SLIDE_SETTINGS.MaxMultiplier)

        ------------------------------------------------------------------
        -- Convert stored local dir back into world space (allows rotation)
        ------------------------------------------------------------------
        local worldDir = root.CFrame:VectorToWorldSpace(localSlideDir)

        ------------------------------------------------------------------
        -- APPLY VELOCITY DIRECTLY INSTEAD OF USING BODYVELOCITY
        ------------------------------------------------------------------
		local gravity = workspace.Gravity

		-- Compute horizontal slide velocity
		local horizontalVel = worldDir * (SLIDE_SETTINGS.BaseSpeed * currentMultiplier)

		-- Preserve vertical velocity (so Roblox gravity works)
		local currentVel = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(
			horizontalVel.X,
			currentVel.Y + gravity * dt, -- preserve default vertical velocity
			horizontalVel.Z
		)

        ------------------------------------------------------------------
        -- Stop conditions
        ------------------------------------------------------------------
        if currentMultiplier < 0.1 or airTime > AIR_GRACE then
            CombatUtils.StopSlide(player)
        end
    end)

    return true
end
]]

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

	-- Prevent double slides / conflict with dash
	if slidingPlayers[character] then
		return false
	end
	if CombatUtils.GetIsDashing(character) then
		return false
	end
	if CombatUtils.GetStun(character) then
		return false
	end

	-------------------------------------------------------------------------
	-- Ground detection
	-------------------------------------------------------------------------
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character }
	params.FilterType = Enum.RaycastFilterType.Exclude

	local groundRay = workspace:Raycast(root.Position, -root.CFrame.UpVector * 5, params)
	if not groundRay then
		return false
	end

	-------------------------------------------------------------------------
	-- Velocity + slope checks
	-------------------------------------------------------------------------
	local vel = root.AssemblyLinearVelocity
	local flatVel = Vector3.new(vel.X, 0, vel.Z)
	local flatSpeed = flatVel.Magnitude

	local slopeNormal = groundRay.Normal
	local slopeAngle = math.deg(math.acos(slopeNormal:Dot(Vector3.new(0, 1, 0))))

	local MIN_SLIDE_SPEED = 28
	local MAX_SLOPE_TO_ALLOW_SLOW_SLIDE = 20

	if flatSpeed < MIN_SLIDE_SPEED and slopeAngle < MAX_SLOPE_TO_ALLOW_SLOW_SLIDE then
		return false
	end

	-------------------------------------------------------------------------
	-- Animation
	-------------------------------------------------------------------------
	AnimationModule.PlayAnimation(character, SLIDE_ANIM_ID, true, Enum.AnimationPriority.Action, 1)

	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	-------------------------------------------------------------------------
	-- 1. Determine initial sliding direction
	-------------------------------------------------------------------------
	local initialDir
	if flatSpeed > 1 then
		initialDir = flatVel.Unit
	else
		local look = root.CFrame.LookVector
		initialDir = Vector3.new(look.X, 0, look.Z).Unit
	end

	-------------------------------------------------------------------------
	-- 2. Project direction onto slope plane
	-------------------------------------------------------------------------
	local function ProjectOntoPlane(v, normal)
		return (v - normal * v:Dot(normal)).Unit
	end

	local slideDirectionWorld = ProjectOntoPlane(initialDir, slopeNormal)

	-------------------------------------------------------------------------
	-- 3. Guarantee minimum launch speed (horizontal only)
	-------------------------------------------------------------------------
	local MIN_LAUNCH = 70

	if flatSpeed < MIN_LAUNCH then
		local boosted = slideDirectionWorld * MIN_LAUNCH
		root.AssemblyLinearVelocity = Vector3.new(
			boosted.X,
			vel.Y, -- vertical preserved
			boosted.Z
		)
	end

	-------------------------------------------------------------------------
	-- Allow rotation during slide (convert to local space)
	-------------------------------------------------------------------------
	local localSlideDir = root.CFrame:VectorToObjectSpace(slideDirectionWorld)

	local prevY = root.Position.Y
	local currentMultiplier = 1
	local airTime = 0
	local AIR_GRACE = 1

	-------------------------------------------------------------------------
	-- Create horizontal-only BodyVelocity
	-------------------------------------------------------------------------
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e6, 0, 1e6) -- No Y force -> gravity & jumping work
	bv.P = 5000
	bv.Velocity = Vector3.new(0, 0, 0)
	bv.Parent = root

	-------------------------------------------------------------------------
	-- Register sliding state
	-------------------------------------------------------------------------
	local state = {
		BodyVelocity = bv,
		Connection = nil,
	}

	slidingPlayers[character] = state

	-------------------------------------------------------------------------
	-- Heartbeat loop
	-------------------------------------------------------------------------
	state.Connection = RunService.Heartbeat:Connect(function(dt)
		if not root.Parent then
			CombatUtils.StopSlide(player)
			return
		end

		---------------------------------------------------------------------
		-- Ground check
		---------------------------------------------------------------------
		local ray = workspace:Raycast(root.Position, -root.CFrame.UpVector * 10, params)

		local posY = root.Position.Y
		local deltaY = posY - prevY
		prevY = posY

		if ray then
			airTime = 0
		else
			airTime += dt
		end

		---------------------------------------------------------------------
		-- Slope acceleration / deceleration
		---------------------------------------------------------------------
		if math.abs(deltaY) < 0.1 then
			currentMultiplier -= SLIDE_SETTINGS.SpeedChangeRate.Forward * dt
		elseif deltaY > 0 then
			currentMultiplier -= SLIDE_SETTINGS.SpeedChangeRate.Upward * dt
		else
			currentMultiplier += SLIDE_SETTINGS.SpeedChangeRate.Downward * dt
		end

		currentMultiplier = math.clamp(currentMultiplier, 0, SLIDE_SETTINGS.MaxMultiplier)

		---------------------------------------------------------------------
		-- Convert direction back into world space
		---------------------------------------------------------------------
		local worldDir = root.CFrame:VectorToWorldSpace(localSlideDir)

		---------------------------------------------------------------------
		-- APPLY SLIDE USING BODYVELOCITY (HORIZONTAL ONLY)
		---------------------------------------------------------------------
		local horizontalVel = worldDir * (SLIDE_SETTINGS.BaseSpeed * currentMultiplier)

		state.BodyVelocity.Velocity = Vector3.new(
			horizontalVel.X,
			0, -- no vertical force; gravity handles Y
			horizontalVel.Z
		)

		---------------------------------------------------------------------
		-- Stop conditions
		---------------------------------------------------------------------
		if currentMultiplier < 0.1 or airTime > AIR_GRACE then
			CombatUtils.StopSlide(player)
		end
	end)

	return true
end

-- === Add a barrier to a character ===
function CombatUtils.AddBarrier(character, amount, decayRate, decayDelay, barrierId, maxCap)
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- Defaults
	amount = amount or 25
	decayRate = decayRate or 1
	decayDelay = decayDelay or 3
	barrierId = barrierId or "Default"
	maxCap = maxCap or 200 -- optional upper limit for stacking barrier

	-- Ensure barrier data structure exists
	activeBarriers[character] = activeBarriers[character] or {}
	local barrierGroup = activeBarriers[character]

	-- === Ensure a BarrierFolder exists for client visibility ===
	local barrierFolder = character:FindFirstChild("BarrierFolder")
	if not barrierFolder then
		barrierFolder = Instance.new("Folder")
		barrierFolder.Name = "BarrierFolder"
		barrierFolder.Parent = character
	end

	-- === Find or create the NumberValue for this barrier ===
	local barrierValue = barrierFolder:FindFirstChild(barrierId .. "Barrier")
	if not barrierValue then
		barrierValue = Instance.new("NumberValue")
		barrierValue.Name = barrierId .. "Barrier"
		barrierValue.Value = amount
		barrierValue.Parent = barrierFolder
	else
		-- Stack or refresh existing barrier
		local newValue = math.min(barrierValue.Value + amount, maxCap)
		barrierValue.Value = newValue
	end

	-- Create or update internal barrier data
	if barrierGroup[barrierId] then
		local data = barrierGroup[barrierId]
		data.Max = math.min(data.Max + amount, maxCap)
		data.Current = math.min(data.Current + amount, data.Max)
		data.LastRefreshed = tick()
	else
		barrierGroup[barrierId] = {
			Max = math.min(amount, maxCap),
			Current = math.min(amount, maxCap),
			DecayRate = decayRate,
			DecayDelay = decayDelay,
			LastRefreshed = tick(),
			Value = barrierValue, -- link the NumberValue
		}
	end

	-- === Visual feedback ===
	local barrierEffect = character:FindFirstChild("BarrierEffect")
	if not barrierEffect then
		barrierEffect = Instance.new("Highlight")
		barrierEffect.FillColor = BARRIER_COLOR
		barrierEffect.OutlineTransparency = 1
		barrierEffect.Name = "BarrierEffect"
		barrierEffect.Parent = character
	end

	-- === Hook damage interception once ===
	if not humanoid:GetAttribute("BarrierHooked") then
		humanoid:SetAttribute("BarrierHooked", true)

		local lastHealth = humanoid.Health
		humanoid.HealthChanged:Connect(function(newHealth)
			local barriers = activeBarriers[character]
			if not barriers then
				lastHealth = newHealth
				return
			end

			local delta = newHealth - lastHealth
			if delta < 0 then
				local damageTaken = -delta
				local remainingDamage = damageTaken

				-- Loop through barriers in insertion order
				for id, data in pairs(barriers) do
					if data.Current > 0 and remainingDamage > 0 then
						local absorb = math.min(data.Current, remainingDamage)
						data.Current -= absorb
						remainingDamage -= absorb
						data.LastRefreshed = tick()

						-- Update visible NumberValue
						if data.Value then
							data.Value.Value = data.Current
						end

						if data.Current <= 0 then
							if data.Value then
								data.Value:Destroy()
							end
							barriers[id] = nil
						end
					end
				end

				-- Apply leftover damage to health
				humanoid.Health = lastHealth - remainingDamage

				-- Clean up if no barriers remain
				if not next(barriers) then
					activeBarriers[character] = nil
					if character:FindFirstChild("BarrierEffect") then
						character.BarrierEffect:Destroy()
					end
				end
			end

			lastHealth = humanoid.Health
		end)
	end

	-- === Decay logic per barrier ===
	task.spawn(function()
		local data = barrierGroup[barrierId]
		if not data then
			return
		end

		while activeBarriers[character] and activeBarriers[character][barrierId] do
			task.wait(1)
			data = activeBarriers[character] and activeBarriers[character][barrierId]
			if not data then
				break
			end

			-- Wait for decay delay after last refresh
			if tick() - data.LastRefreshed >= data.DecayDelay then
				data.Current = math.max(0, data.Current - data.DecayRate)

				-- Update visible value
				if data.Value then
					data.Value.Value = data.Current
				end

				if data.Current <= 0 then
					if data.Value then
						data.Value:Destroy()
					end
					activeBarriers[character][barrierId] = nil

					-- Cleanup if no barriers remain
					if not next(activeBarriers[character]) then
						activeBarriers[character] = nil
						if character:FindFirstChild("BarrierEffect") then
							character.BarrierEffect:Destroy()
						end
					end
					break
				end
			end
		end
	end)
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
