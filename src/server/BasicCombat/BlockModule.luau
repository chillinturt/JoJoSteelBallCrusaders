--// BlockModule.lua
local BlockModule = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

--// Constants
local BLOCK_ANIMATION_ID = "82125777884940" -- character loop
local STAND_BLOCK_ANIMATION = "133892948612008" -- Stand loop

local BLOCK_SLOW = 0.5

local EMERGENCYBLOCK_COST = 35

--// Services / Modules
local SlowingFieldRegistry = require(ServerScriptService.BasicCombat.Managers.SlowingFieldRegistry)
local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)

--// Internal state
local activeAnimations = {} -- [character] = AnimationTrack

-- Server
local emergencyBlockCooldown = {} -- [player] = timeWhenAllowedAgain
local currentlyBlocking = {} -- [player] = true/false
local suppressAutoRestart = {}
local blockHeld = {} -- [character] = true / false

local EMERGENCY_BLOCK_COOLDOWN = 1.5 -- seconds (tune later)
local EMERGENCYBLOCK_SIZE = Vector3.new(10, 10, 10)
local EMERGENCYBLOCK_KNOCKBACK_SPEED = 60
local EMERGENCYBLOCK_KNOCKBACK_DURATION = 0.5
local EMERGENCYBLOCK_OFFSET = Vector3.new(0, 0, 0)

local BlockUpdateEvent = game.ReplicatedStorage.UIs.RemoteEvents:WaitForChild("BlockUpdateEvent")

--=============================================================
--  Helper Functions
--=============================================================

local function stopBlockingAnimation(character)
	if activeAnimations[character] then
		activeAnimations[character]:Stop()
		activeAnimations[character] = nil
	end
end

local function freezeAnimation(track)
	if not track then
		return
	end

	task.defer(function()
		local duration = track.Length > 0 and track.Length or 1
		local freezeTime = math.max(duration - 0.1, 0)

		task.delay(freezeTime, function()
			if track and track.IsPlaying then
				track.TimePosition = duration - 0.1
				track:AdjustSpeed(0)
			end
		end)
	end)
end

--=============================================================
--  Core Functions
--=============================================================
local function applyBlockingState(character)
	local hum = character:FindFirstChild("Humanoid")
	local moveSpeed = CombatUtils.GetMoveSpeed(character)

	-- Apply slow
	if hum and moveSpeed then
		SlowingFieldRegistry.SetSlow(character, "Block", BLOCK_SLOW)
		local baseSpeed = CombatUtils.GetMoveSpeed(character)
		local mult = CombatUtils.GetSlowMultiplier(character)
		hum.WalkSpeed = baseSpeed * mult
	end

	stopBlockingAnimation(character)

	local standModel = StandUtils.getStandModel(character)
	local entity = standModel or character

	local track
	if standModel then
		local standTag = StandUtils.getStandTag(character).Value
		if
			standTag and standTag == "TuskAct1"
			or standTag == "TuskAct2"
			or standTag == "TuskAct3"
			or standTag == "NuclearRain"
		then
			track = AnimationModule.PlayAnimation(character, BLOCK_ANIMATION_ID, false, Enum.AnimationPriority.Action)
		else
			track = AnimationModule.PlayAnimation(entity, STAND_BLOCK_ANIMATION, false, Enum.AnimationPriority.Action)
		end
	else
		track = AnimationModule.PlayAnimation(character, BLOCK_ANIMATION_ID, false, Enum.AnimationPriority.Action)
	end

	if track then
		activeAnimations[character] = track
		freezeAnimation(track)
	end
end

function BlockModule.StartBlocking(character)
	if currentlyBlocking[character] then
		return
	end

	local actionFlag = CombatUtils.GetActionInProgress(character)

	if CombatUtils.GetStun(character) or actionFlag then
		return
	end
	if CombatUtils.IsBlocking(character) then
		return
	end

	currentlyBlocking[character] = true
	CombatUtils.SetBlocking(character, true)

	applyBlockingState(character)
end

function BlockModule.StopBlocking(character)
	if not character then
		return
	end

	-- Prevent auto restart
	suppressAutoRestart[character] = true

	-- Always clear internal state
	currentlyBlocking[character] = nil

	BlockModule.SetBlockHeld(character, false)

	-- Always clear blocking flag
	if CombatUtils.IsBlocking(character) then
		CombatUtils.SetBlocking(character, false)
	end

	-- Restore movement
	local hum = character:FindFirstChild("Humanoid")
	local moveSpeed = CombatUtils.GetMoveSpeed(character)

	if hum and moveSpeed then
		local baseSpeed = CombatUtils.GetMoveSpeed(character)
		SlowingFieldRegistry.ClearSlow(character, "Block")
		local mult = CombatUtils.GetSlowMultiplier(character)
		hum.WalkSpeed = baseSpeed * mult
	end

	-- Stop animation
	stopBlockingAnimation(character)

	task.defer(function()
		suppressAutoRestart[character] = nil
	end)
end

function BlockModule.StartEmergencyBlocking(character)
	CombatUtils.SetBlocking(character, true)

	applyBlockingState(character)

	SoundModule.PlaySound({
		Root = character:FindFirstChild("HumanoidRootPart"),
		soundName = "EmergencyBlockingEffect",
		soundID = "9120042703",
		volume = 1,
	})

	if currentlyBlocking[character] then
		return
	end
	currentlyBlocking[character] = true

	local hrp = character:FindFirstChild("HumanoidRootPart")

	HitboxSpawner.spawnStationaryHitbox({
		Position = hrp.CFrame,
		Character = character,
		Damage = 0,
		Size = EMERGENCYBLOCK_SIZE,
		Offset = CFrame.new(EMERGENCYBLOCK_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = 0.75,
		StunDuration = 0,
		Transparency = 0.6,
		Name = "EmergencyBlockHitbox",
		CanBlock = false,

		OnHit = function(targetChar, newDamage)
			local hitHumanoid = targetChar:FindFirstChild("Humanoid")
			local targetRootPart = targetChar:FindFirstChild("HumanoidRootPart")
			local attackerRoot = character:FindFirstChild("HumanoidRootPart")

			if not (hitHumanoid and targetRootPart and attackerRoot) then
				return
			end

			-- Lock rotation
			hitHumanoid.AutoRotate = false

			local rootJoint = targetRootPart:FindFirstChild("RootJoint")
			local originalC0 = rootJoint and rootJoint.C0

			-- 🔹 Horizontal-only knockback direction
			-- Forward-based knockback (NOT radial)
			local worldDirection = attackerRoot.CFrame.LookVector
			worldDirection = Vector3.new(worldDirection.X, 0, worldDirection.Z).Unit

			-- Convert WORLD → TARGET LOCAL
			local localDirection = targetRootPart.CFrame:VectorToObjectSpace(worldDirection)

			CombatUtils.ApplyTurningVelocity({
				Character = targetChar,
				Speed = EMERGENCYBLOCK_KNOCKBACK_SPEED,
				Duration = EMERGENCYBLOCK_KNOCKBACK_DURATION,
				Name = "BlazingStrikeVelocity",
				Direction = localDirection,
			})

			-- Restore rotation
			task.delay(EMERGENCYBLOCK_KNOCKBACK_DURATION, function()
				if hitHumanoid then
					hitHumanoid.AutoRotate = true
				end
				if rootJoint and originalC0 then
					rootJoint.C0 = originalC0
				end
			end)
		end,
	})

	-- Auto stop emergency block
	task.delay(0.75, function()
		if character and currentlyBlocking[character] then
			BlockModule.StopBlocking(character)
		end
	end)
end

--=============================================================
--  Legacy Support (optional, for Time Erase etc.)
--=============================================================

function BlockModule.BlockOn(character)
	CombatUtils.SetBlocking(character, true)

	local hum = character:FindFirstChild("Humanoid")
	local moveSpeed = CombatUtils.GetMoveSpeed(character)
	-- Apply slow
	if hum and moveSpeed then
		SlowingFieldRegistry.SetSlow(character, "Block", BLOCK_SLOW)
		local baseSpeed = CombatUtils.GetMoveSpeed(character)
		local mult = CombatUtils.GetSlowMultiplier(character)
		hum.WalkSpeed = baseSpeed * mult
	end
end

function BlockModule.BlockOff(character)
	CombatUtils.SetBlocking(character, false)

	local hum = character:FindFirstChild("Humanoid")
	local moveSpeed = CombatUtils.GetMoveSpeed(character)
	-- Restore movement
	if hum and moveSpeed then
		local baseSpeed = CombatUtils.GetMoveSpeed(character)
		SlowingFieldRegistry.ClearSlow(character, "Block")
		local mult = CombatUtils.GetSlowMultiplier(character)
		hum.WalkSpeed = baseSpeed * mult
	end
end

-- helpers

function BlockModule.SetBlockHeld(character, held)
	if not character then
		return
	end
	blockHeld[character] = held
end

function BlockModule.IsBlockHeld(character)
	return blockHeld[character] == true
end

function BlockModule.TryStartBlocking(character)
	if not BlockModule.IsBlockHeld(character) then
		return
	end
	if currentlyBlocking[character] then
		return
	end -- NEW guard
	if suppressAutoRestart[character] then
		return
	end

	local actionFlag = CombatUtils.GetActionInProgress(character)
	local stun = CombatUtils.GetStun(character)

	if stun or actionFlag then
		return
	end
	if CombatUtils.IsBlocking(character) then
		return
	end

	BlockModule.StartBlocking(character)
end

function BlockModule.TryStartEmergencyBlock(character)
	if currentlyBlocking[character] then
		return
	end

	-- 🔒 Cooldown check
	local now = os.clock()
	local nextAllowed = emergencyBlockCooldown[character]
	if nextAllowed and now < nextAllowed then
		return
	end

	if CombatUtils.IsBlocking(character) then
		return
	end

	-- 🔓 Emergency block ignores stun
	local actionFlag = CombatUtils.GetActionInProgress(character)
	if actionFlag then
		return
	end -- still respect actions (for now)

	if not CombatUtils.GetStun(character) then
		return
	end

	if not CombatUtils.SpendBlockHP(character, EMERGENCYBLOCK_COST) then
		return
	end

	local blockHP = CombatUtils.GetBlockHP(character)

	local player = Players:GetPlayerFromCharacter(character)
	if player then
		CombatUtils.SyncBlockUI(player, blockHP, CombatUtils.GetBlockMaxHP(character))
	end

	emergencyBlockCooldown[character] = now + EMERGENCY_BLOCK_COOLDOWN

	BlockModule.StartEmergencyBlocking(character)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local hum = character:FindFirstChild("Humanoid")
		if hum then
			hum.Died:Connect(function()
				BlockModule.StopBlocking(character)
			end)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local character = player.Character
	if character then
		BlockModule.StopBlocking(character)
	end
end)

return BlockModule
