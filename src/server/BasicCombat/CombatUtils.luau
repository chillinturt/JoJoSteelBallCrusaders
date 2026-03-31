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

local BarrierStateEvent = Instance.new("RemoteEvent")
BarrierStateEvent.Name = "BarrierState"
BarrierStateEvent.Parent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BasicCombat"):WaitForChild("UI")

CombatUtils.StunEnded = Instance.new("BindableEvent")
CombatUtils.ActionEnded = Instance.new("BindableEvent")

local BlockUpdateEvent = ReplicatedStorage.UIs.RemoteEvents:WaitForChild("BlockUpdateEvent")

local BlockRequestFunction = Instance.new("RemoteFunction")
BlockRequestFunction.Name = "BlockRequestFunction"
BlockRequestFunction.Parent = ReplicatedStorage.UIs.RemoteEvents

local slidingPlayers = {}

local activeVelocities = {}
local heartbeatConnections = {}
local baseVelocities = {}

local isDashingState = {} -- [character] = { active = boolean, token = number }

local ActiveStuns = {} -- [character] = { expiresAt = number }

local combatData = {}

local STUN_SPEED_MULT = 0.16
local EPSILON = 0.05

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
local blockingState = {} -- [Player | Character] = boolean

local BLOOD_DRAIN_CONST = 10 -- cost of buff is damage / const

local VAMPIRE_DAMAGE_BUFF = 1.2 -- 20%

local activeBarriers = {}

local blockMaxHPByCharacter = {}
local blockHPByCharacter = {} -- [character] = number

-- Movement
local moveSpeedByCharacter = {} -- [character] = number
local moveSpeedMultiplierByCharacter = {} -- NEW
local jumpHeightByCharacter = {} -- [character] = number

-- Block regen state
local blockRegenState = {} -- [character] = { lastDamageTime, regenRunning }

local actionInProgress = {}

local DEFAULT_MOVE_SPEED = 24
local DEFAULT_JUMP_HEIGHT = 40.996

--services
local RunService = game:GetService("RunService")
local HeroManager = require(ServerScriptService.DataSaving.HeroManager)

local AnimationModule = require(script.Parent.AnimationModule)
local StandUtils = require(script.Parent.StandUtils)
local VampireModule = require(game.ServerScriptService.BasicCombat.RaceScripts:WaitForChild("Vampire"))

local function ensure(player)
	if not combatData[player] then
		combatData[player] = {
			Power = 0,
			Strength = 0,
			Dexterity = 0,
		}
	end

	return combatData[player]
end

-- Function to send block updates to the client
function CombatUtils.SyncBlockUI(player, value, max)
	if not player then
		return
	end

	BlockUpdateEvent:FireClient(player, value, max)
end

function CombatUtils.SyncBlock(character)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	local current = CombatUtils.GetBlockHP(character)
	local max = CombatUtils.GetBlockMaxHP(character)

	CombatUtils.SyncBlockUI(player, current, max)
end

-- Function to return modified damage based on blocking state
function CombatUtils.ReturnDamage(character, damage, canBlock, attacker)
	local isBlocking = CombatUtils.IsBlocking(character)
	local blockHP = CombatUtils.GetBlockHP(character)

	local newDamage = damage

	local damageMult = CombatUtils.GetDamageMult(character)
	if damageMult then
		newDamage = newDamage * damageMult
	end

	local attackerPlayer = Players:GetPlayerFromCharacter(attacker)
	local race
	local isVamp = false
	if attackerPlayer then
		race = HeroManager.GetField(attackerPlayer, "Race")
	else
		isVamp = VampireModule.getIsVampireRace(attacker)
	end

	if race == "Vampire" or isVamp then
		--Apply Vampire blood buff if applicable
		if VampireModule.spendBlood(attacker, damage / BLOOD_DRAIN_CONST) then
			newDamage = newDamage * VAMPIRE_DAMAGE_BUFF
		end
	end

	-- Apply Hamon damage reduction if applicable
	local hamonMeter = character:FindFirstChild("HamonMeter")
	if hamonMeter and hamonMeter.Value > 0 then
		newDamage = newDamage * HAMON_DAMAGE_REDUCTION
	end

	-- If blocking is allowed
	if canBlock and isBlocking and blockHP > 0 then
		-- Calculate the reduced damage that the block tries to absorb
		local reducedDamage = newDamage * (1 - BLOCK_DAMAGE_REDUCTION)

		if blockHP >= reducedDamage then
			CombatUtils.SpendBlockHP(character, reducedDamage)
			newDamage = newDamage * BLOCK_DAMAGE_REDUCTION
		else
			local remainingDamage = reducedDamage - blockHP
			CombatUtils.SpendBlockHP(character, blockHP)

			newDamage = (newDamage * BLOCK_DAMAGE_REDUCTION) + remainingDamage
		end

		CombatUtils.SyncBlock(character)
	end

	return newDamage
end

function CombatUtils.ApplyStatScaling(attackerCharacter, baseDamage, statScaling)
	local player = Players:GetPlayerFromCharacter(attackerCharacter)
	if not player then
		return baseDamage
	end

	local damage = baseDamage

	for stat, scale in pairs(statScaling) do
		local statValue = 0

		if stat == "Power" then
			statValue = CombatUtils.GetPower(player)
		elseif stat == "Strength" then
			statValue = CombatUtils.GetStrength(player)
		elseif stat == "Dexterity" then
			statValue = CombatUtils.GetDexterity(player)
		end

		damage += statValue * scale
	end

	return damage
end

function CombatUtils.GetActionInProgress(character)
	if not character then
		warn("Cannot GetActionInProgress: character does not exist")
		return false
	end

	local state = actionInProgress[character]
	if not state then
		return false
	end

	-- Auto-expire
	if os.clock() >= state.expiresAt then
		actionInProgress[character] = nil
		return false
	end

	return true
end

function CombatUtils.SetActionInProgress(character, duration)
	if not character then
		warn("Cannot SetActionInProgress: character does not exist")
		return
	end

	duration = duration or 0
	local expiresAt = os.clock() + duration

	actionInProgress[character] = {
		expiresAt = expiresAt,
	}

	-- Apply slow
	CombatUtils.ApplyMoveSpeedMultiplier(character, 0.5)

	task.delay(duration, function()
		local state = actionInProgress[character]

		if state and state.expiresAt <= os.clock() then
			actionInProgress[character] = nil

			-- Restore normal speed safely
			CombatUtils.ApplyMoveSpeedMultiplier(character, 1)
		end
	end)

	return expiresAt
end

function CombatUtils.ResetActionInProgress(character)
	actionInProgress[character] = nil
	CombatUtils.ApplyMoveSpeedMultiplier(character, 1)
end

function CombatUtils.UpdateMovement(character)
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local base = CombatUtils.GetMoveSpeed(character)
	local mult = moveSpeedMultiplierByCharacter[character] or 1
	local slowMult = SlowingFieldRegistry.GetFinalMultiplier(character)

	local finalSpeed = base * mult * slowMult
	humanoid.WalkSpeed = finalSpeed
end

function CombatUtils.applyStun(character, duration)
	if not character then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	CombatUtils.RegisterStun(character, duration)
	if player then
		CombatUtils.StopSlide(player)
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	for _, child in ipairs(hrp:GetChildren()) do
		if child:IsA("BasePart") and child:GetAttribute("RemoveOnStun") then
			child:Destroy()
		end
	end

	local stand = StandUtils.getStandModel(character)
	if not stand then
		return
	end
	local standRoot = stand.PrimaryPart

	for _, child in ipairs(standRoot:GetChildren()) do
		if child:IsA("BasePart") and child:GetAttribute("RemoveOnStun") then
			child:Destroy()
		end
	end
end

function CombatUtils.GetStun(character)
	return ActiveStuns[character] ~= nil
end

function CombatUtils.GetSlowMultiplier(character)
	local finalMult = SlowingFieldRegistry.GetFinalMultiplier(character)
	return finalMult
end

function CombatUtils.IsBlocking(character)
	return blockingState[character] == true
end

function CombatUtils.SetBlocking(character, value)
	blockingState[character] = value == true
end

function CombatUtils.ClearBlocking(character)
	blockingState[character] = nil
end

function CombatUtils.SetPower(player, level)
	local data = ensure(player)

	data.Power = level
end

function CombatUtils.GetPower(player)
	local data = ensure(player)

	return data.Power
end

function CombatUtils.SetStrength(player, level)
	local data = ensure(player)

	data.Strength = level
end

function CombatUtils.GetStrength(player)
	local data = ensure(player)

	return data.Strength
end

function CombatUtils.SetDexterity(player, level)
	local data = ensure(player)

	data.Dexterity = level
end

function CombatUtils.GetDexterity(player)
	local data = ensure(player)

	return data.Dexterity
end

function CombatUtils.GetBlockHP(character)
	if not character then
		return 0
	end

	if blockHPByCharacter[character] == nil then
		local maxHP = CombatUtils.GetBlockMaxHP(character)
		blockHPByCharacter[character] = maxHP
	end

	return blockHPByCharacter[character]
end

function CombatUtils.GetBlockMaxHP(character)
	return blockMaxHPByCharacter[character] or BLOCK_MAX_HP
end

function CombatUtils.SetBlockMaxHP(character, value)
	if not character then
		return
	end

	blockMaxHPByCharacter[character] = value

	if blockHPByCharacter[character] == nil then
		blockHPByCharacter[character] = value
	end

	blockHPByCharacter[character] = math.min(blockHPByCharacter[character], value)
end

function CombatUtils.SpendBlockHP(character, hp)
	if not character or hp <= 0 then
		return false
	end

	local current = CombatUtils.GetBlockHP(character)
	if current < hp then
		return false
	end

	blockHPByCharacter[character] = current - hp
	CombatUtils.NotifyBlockDamage(character)

	local state = blockRegenState[character]
	if state then
		state.lastDamageTime = os.clock()
	end

	CombatUtils.SyncBlock(character)

	return true
end

function CombatUtils.GetMoveSpeed(character)
	if not character then
		return DEFAULT_MOVE_SPEED
	end

	if moveSpeedByCharacter[character] == nil then
		moveSpeedByCharacter[character] = DEFAULT_MOVE_SPEED
	end

	return moveSpeedByCharacter[character]
end

function CombatUtils.SetMoveSpeed(character, value)
	if not character then
		return
	end

	moveSpeedByCharacter[character] = value or DEFAULT_MOVE_SPEED
	CombatUtils.UpdateMovement(character)
end

function CombatUtils.ApplyMoveSpeedMultiplier(character, multiplier)
	if not character then
		return
	end

	moveSpeedMultiplierByCharacter[character] = multiplier or 1
	CombatUtils.UpdateMovement(character)
end

function CombatUtils.GetJumpHeight(character)
	if not character then
		return DEFAULT_JUMP_HEIGHT
	end

	if jumpHeightByCharacter[character] == nil then
		jumpHeightByCharacter[character] = DEFAULT_JUMP_HEIGHT
	end

	return jumpHeightByCharacter[character]
end

function CombatUtils.SetJumpHeight(character, value)
	if not character then
		return
	end

	jumpHeightByCharacter[character] = value or DEFAULT_JUMP_HEIGHT

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.JumpHeight = jumpHeightByCharacter[character]
	end
end

function CombatUtils.NotifyBlockDamage(character)
	if not character then
		return
	end

	blockRegenState[character] = blockRegenState[character] or {}
	blockRegenState[character].lastDamageTime = os.clock()
end

function CombatUtils.StartBlockRegen(character)
	if not character then
		return
	end

	-- Prevent duplicate regen loops
	if blockRegenState[character] and blockRegenState[character].regenRunning then
		return
	end

	blockRegenState[character] = {
		lastDamageTime = os.clock(),
		regenRunning = true,
	}

	task.spawn(function()
		while true do
			task.wait(0.1)

			local state = blockRegenState[character]
			if not state or not state.regenRunning then
				break
			end

			local timeSinceDamage = os.clock() - state.lastDamageTime
			if timeSinceDamage >= BLOCK_REGEN_DELAY then
				local current = CombatUtils.GetBlockHP(character)
				local maxHP = CombatUtils.GetBlockMaxHP(character)

				if current < maxHP then
					local regenAmount = BLOCK_REGEN_RATE * 0.1
					local newHP = math.min(maxHP, current + regenAmount)
					blockHPByCharacter[character] = newHP
					CombatUtils.SyncBlock(character)
				end
			end
		end
	end)
end

local function cleanupCharacter(character)
	moveSpeedByCharacter[character] = nil
	jumpHeightByCharacter[character] = nil
	blockHPByCharacter[character] = nil
	blockRegenState[character] = nil
	actionInProgress[character] = nil

	local state = blockRegenState[character]
	if state then
		state.regenRunning = false
	end
end

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		CombatUtils.StartBlockRegen(character)
		CombatUtils.GetMoveSpeed(character)
		CombatUtils.SetMoveSpeed(character)
		CombatUtils.GetJumpHeight(character)
		CombatUtils.SetJumpHeight(character)

		CombatUtils.SyncBlock(character)

		local humanoid = character:WaitForChild("Humanoid")

		humanoid.Died:Connect(function()
			cleanupCharacter(character)
		end)
	end)

	player.CharacterRemoving:Connect(cleanupCharacter)
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
	if not character or typeof(duration) ~= "number" then
		return
	end

	local state = isDashingState[character]
	if not state then
		state = {
			active = false,
			token = 0,
		}
		isDashingState[character] = state
	end

	-- Increment token to invalidate old timers
	state.token += 1
	local myToken = state.token
	state.active = true

	-- Auto-clear after duration
	task.delay(duration, function()
		local current = isDashingState[character]
		if not current then
			return
		end

		-- Only clear if this is still the latest dash
		if current.token == myToken then
			current.active = false
		end
	end)
end

function CombatUtils.IsDashing(character)
	local state = isDashingState[character]
	return state and state.active or false
end

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
	if CombatUtils.IsDashing(character) then
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

local function sendBarrierUpdate(player, character)
	local controller = activeBarriers[character]

	local total = 0
	local max = 0
	local barrierList = {}

	if controller then
		for _, id in ipairs(controller.OrderedIds) do
			local barrier = controller.Barriers[id]
			if barrier then
				total += barrier.Current
				max += barrier.Max

				table.insert(barrierList, {
					Id = barrier.Id,
					Current = barrier.Current,
					Max = barrier.Max,
					Priority = barrier.Priority,
					DecayDelay = barrier.DecayDelay,
					DecayRate = barrier.DecayRate,
					LastRefreshed = barrier.LastRefreshed,
				})
			end
		end
	end

	BarrierStateEvent:FireClient(player, {
		Total = total,
		Max = max,
		Barriers = barrierList, -- ordered, safe snapshot
	})
end

-- === Add a barrier to a character ===
local function sortBarrierOrder(controller)
	table.sort(controller.OrderedIds, function(a, b)
		local A = controller.Barriers[a]
		local B = controller.Barriers[b]

		if A.Priority ~= B.Priority then
			return A.Priority > B.Priority
		end

		return A.LastRefreshed < B.LastRefreshed
	end)
end

----------------------------------------------------------------
-- Ensure controller exists
----------------------------------------------------------------
local function getController(character)
	if activeBarriers[character] then
		return activeBarriers[character]
	end

	local controller = {
		Barriers = {},
		OrderedIds = {},
	}

	activeBarriers[character] = controller
	return controller
end

----------------------------------------------------------------
-- Add / Refresh Barrier
----------------------------------------------------------------
function CombatUtils.AddBarrier(character, params)
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local controller = getController(character)
	local now = os.clock()

	local id = params.Id or "Default"
	local amount = params.Amount or 25
	local maxCap = params.MaxCap or 200

	local barrier = controller.Barriers[id]

	if barrier then
		barrier.Max = math.min(barrier.Max + amount, maxCap)
		barrier.Current = math.min(barrier.Current + amount, barrier.Max)
		barrier.LastRefreshed = now
	else
		controller.Barriers[id] = {
			Id = id,
			Priority = params.Priority or 0,
			Max = math.min(amount, maxCap),
			Current = math.min(amount, maxCap),
			DecayRate = params.DecayRate or 1,
			DecayDelay = params.DecayDelay or 3,
			LastRefreshed = now,
		}

		table.insert(controller.OrderedIds, id)
	end

	sortBarrierOrder(controller)

	local player = Players:GetPlayerFromCharacter(character)
	if player then
		sendBarrierUpdate(player, character)
	end
end

-- === Get TOTAL remaining barrier ===
function CombatUtils.GetTotalBarrier(character)
	local controller = activeBarriers[character]
	if not controller then
		return 0
	end

	local total = 0
	for _, barrier in pairs(controller.Barriers) do
		total += barrier.Current
	end

	return total
end

-- === Remove ALL barriers from character ===
function CombatUtils.RemoveAllBarriers(character)
	activeBarriers[character] = nil

	local player = game:GetService("Players"):GetPlayerFromCharacter(character)
	if player then
		sendBarrierUpdate(player, character)
	end
end

function CombatUtils.AttachBarrierDamageHook(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local lastHealth = humanoid.Health

	humanoid.HealthChanged:Connect(function(newHealth)
		local controller = activeBarriers[character]
		if not controller then
			lastHealth = newHealth
			return
		end

		local damage = lastHealth - newHealth
		if damage <= 0 then
			lastHealth = newHealth
			return
		end

		local remaining = damage

		for _, id in ipairs(controller.OrderedIds) do
			local barrier = controller.Barriers[id]
			if barrier and barrier.Current > 0 and remaining > 0 then
				local absorbed = math.min(barrier.Current, remaining)
				barrier.Current -= absorbed
				remaining -= absorbed
			end
		end

		-- Remove depleted barriers
		for i = #controller.OrderedIds, 1, -1 do
			local id = controller.OrderedIds[i]
			local barrier = controller.Barriers[id]
			if barrier.Current <= 0 then
				controller.Barriers[id] = nil
				table.remove(controller.OrderedIds, i)
			end
		end

		humanoid.Health = lastHealth - remaining
		lastHealth = humanoid.Health

		if not next(controller.Barriers) then
			activeBarriers[character] = nil
		end

		local player = Players:GetPlayerFromCharacter(character)
		if player then
			sendBarrierUpdate(player, character)
		end
	end)
end

-- Add or refresh a stun
function CombatUtils.RegisterStun(character, duration)
	if not (character and character.Parent) then
		return
	end

	duration = math.max(0, duration)
	local now = os.clock()

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local entry = ActiveStuns[character]

	if entry then
		-- Extend stun (never shorten)
		entry.expiresAt = math.max(entry.expiresAt, now + duration)
	else
		-- Create new stun
		ActiveStuns[character] = {
			expiresAt = now + duration,
		}

		-- Apply slowing effect
		SlowingFieldRegistry.SetSlow(character, "Stun", STUN_SPEED_MULT)

		-- Apply slowed walk speed (memory-based)
		CombatUtils.UpdateMovement(character)

		-- Disable jumping
		humanoid.JumpPower = 0

		-- Optional: force-stop actions
		CombatUtils.SetActionInProgress(character, duration)
	end
end

-- Remove stun and restore normal stats
function CombatUtils.UnregisterStun(character)
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Clear slow from stun
		SlowingFieldRegistry.ClearSlow(character, "Stun")

		-- Restore movement
		CombatUtils.UpdateMovement(character)

		-- Restore jump
		humanoid.JumpPower = CombatUtils.GetJumpHeight(character)
	end

	-- Remove stun from memory
	if ActiveStuns[character] then
		ActiveStuns[character] = nil

		-- 🔔 Notify listeners (block buffering, etc.)
		CombatUtils.StunEnded:Fire(character)
	end
end

-- Update loop
RunService.Heartbeat:Connect(function()
	local now = os.clock()

	for character, data in pairs(ActiveStuns) do
		local ok, err = pcall(function()
			if not character or not character.Parent then
				ActiveStuns[character] = nil
				return
			end

			if now >= data.expiresAt - EPSILON then
				CombatUtils.UnregisterStun(character)
			end
		end)

		if not ok then
			warn("⚠️ CombatUtils stun update error:", err)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1)

		for character, controller in pairs(activeBarriers) do
			local now = os.clock()

			for i = #controller.OrderedIds, 1, -1 do
				local id = controller.OrderedIds[i]
				local barrier = controller.Barriers[id]

				if now - barrier.LastRefreshed >= barrier.DecayDelay then
					barrier.Current -= barrier.DecayRate

					if barrier.Current <= 0 then
						controller.Barriers[id] = nil
						table.remove(controller.OrderedIds, i)
					end
				end
			end

			if not next(controller.Barriers) then
				activeBarriers[character] = nil
			end

			local player = Players:GetPlayerFromCharacter(character)
			if player then
				sendBarrierUpdate(player, character)
			end
		end
	end
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	local character = player.Character
	if character then
		activeBarriers[character] = nil
		blockHPByCharacter[character] = nil
		blockMaxHPByCharacter[character] = nil
	end
end)

BlockRequestFunction.OnServerInvoke = function(player)
	local character = player.Character
	if not character then
		return 0, 1
	end

	local current = CombatUtils.GetBlockHP(character)
	local max = CombatUtils.GetBlockMaxHP(character)

	return current, max
end

return CombatUtils
