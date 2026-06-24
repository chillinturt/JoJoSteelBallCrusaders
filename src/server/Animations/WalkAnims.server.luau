local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AnimationModule = require(ServerScriptService.BasicCombat.AnimationModule)
local StandUtils = require(ServerScriptService.BasicCombat.StandUtils)

local SwimmingState = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Ocean"):WaitForChild("SwimmingState")

-- Example animation IDs (replace with your own)
local animations = {
	--96767618650505 old run anim
	Forward = "111996277762833",
	Backward = "74432122888392",
	Left = "127264779281230",
	Right = "137936019211555",
	Idle = "104714640622145",
	Fall = "80938111042689", -- ✅ falling anim
	Land = "74308587429244", -- ✅ landing anim
	SwimIdle = "507785072", -- ✅ swimming idle anim
	SwimMove = "507784897", -- ✅ swimming move anim
	StandForward = "103461332131808",
	StandIdle = "89452205434139",
}

-- Track active animations
local activeStates = {}
local lastDirection = {}
local wasMoving = {}
local standStates = {}
local swimmingPlayers = {}
local swimHeartbeats = {}

local function updateStand(player, character, shouldBeForward)
	local stand = StandUtils.GetActiveStand(character)
	if not stand then
		return
	end

	-- 🚨 BLOCK movement if attacking
	local isActing = AnimationModule.IsActionPlaying(character)

	local desiredState = shouldBeForward and "Forward" or "Idle"

	-- ✅ Prevent spam / restarts
	if standStates[player] == desiredState then
		return
	end

	-- Stop previous
	if standStates[player] == "Forward" then
		AnimationModule.StopAnimation(stand, animations["StandForward"])
	elseif standStates[player] == "Idle" then
		AnimationModule.StopAnimation(stand, animations["StandIdle"])
	end

	-- Play new
	if desiredState == "Forward" then
		if not isActing then
			AnimationModule.PlayAnimation(stand, animations["StandForward"], true, Enum.AnimationPriority.Movement, 1)
		end
	else
		if not isActing then
			AnimationModule.PlayAnimation(stand, animations["StandIdle"], true, Enum.AnimationPriority.Movement, 1)
		end
	end

	standStates[player] = desiredState
end

-- Decide movement direction relative to character facing
local function getMovementDirection(player, character, humanoid)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return "Idle"
	end

	-- Swimming overrides all physics states. swimmingPlayers is driven by the
	-- SwimmingState remote, not FloorMaterial, so it stays correct even when
	-- ChangeState(Landed) is called by OceanSwimming to reset freefall.
	if swimmingPlayers[player] then
		if humanoid.MoveDirection.Magnitude > 0.1 then
			return "SwimMove"
		else
			return "SwimIdle"
		end
	end

	if humanoid.FloorMaterial == Enum.Material.Air then
		return "Fall"
	end

	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude < 0.1 then
		return "Idle"
	end

	local forward = root.CFrame.LookVector
	local dot = forward:Dot(moveDir.Unit)
	local cross = forward:Cross(moveDir.Unit)

	if dot > 0.7 then
		return "Forward"
	elseif dot < -0.7 then
		return "Backward"
	elseif cross.Y > 0 then
		return "Left"
	elseif cross.Y < 0 then
		return "Right"
	else
		return "Idle"
	end
end

-- Play the correct animation when state changes
local function onStateChanged(player, humanoid, character)
	if not character or not character.Parent then
		return
	end
	local isActing = AnimationModule.IsActionPlaying(character)

	local direction = getMovementDirection(player, character, humanoid)

	-- ✅ ALWAYS track real movement input (even in air)
	wasMoving[player] = humanoid.MoveDirection.Magnitude > 0.1

	local animId = animations[direction]

	-- Detect landing (Fall/Swim → Grounded) ✅ FIRST
	-- Also handle Swim → ground so a stale swim state doesn't skip cleanup.
	-- Exclude Swim as the destination so falling into water skips the land anim.
	local wasAerial = lastDirection[player] == "Fall" or lastDirection[player] == "SwimIdle" or lastDirection[player] == "SwimMove"
	if wasAerial and direction ~= "Fall" and direction ~= "SwimIdle" and direction ~= "SwimMove" then
		-- Stop fall animation
		if activeStates[player] then
			AnimationModule.StopAnimation(character, activeStates[player].animId)
			activeStates[player] = nil
		end

		-- Play landing anim once
		local landTrack
		if not isActing then
			landTrack =
				AnimationModule.PlayAnimation(character, animations.Land, false, Enum.AnimationPriority.Action, 1.5)
		end

		if landTrack then
			local connection
			connection = landTrack.Stopped:Connect(function()
				if connection then
					connection:Disconnect()
				end
				onStateChanged(player, humanoid, character)
			end)
		end

		lastDirection[player] = direction
		return
	end

	-- Handle Swim (overrides Fall — water has no collision mesh so floor is always Air)
	if direction == "SwimIdle" or direction == "SwimMove" then
		local animId = animations[direction]
		if not activeStates[player] or activeStates[player].direction ~= direction then
			if activeStates[player] then
				AnimationModule.StopAnimation(character, activeStates[player].animId)
			end
			-- Movement priority: doesn't pollute actionStates, so landing and
			-- fall transitions are never blocked. Combat actions (Action priority)
			-- will visually override swim animations naturally.
			AnimationModule.PlayAnimation(character, animId, true, Enum.AnimationPriority.Movement, 1)
			activeStates[player] = {
				direction = direction,
				animId = animId,
			}
		end
		updateStand(player, character, wasMoving[player])
		lastDirection[player] = direction
		return
	end

	-- Handle Fall (high priority)
	if direction == "Fall" then
		if not activeStates[player] or activeStates[player].direction ~= "Fall" then
			if activeStates[player] then
				AnimationModule.StopAnimation(character, activeStates[player].animId)
			end
			-- Movement priority for the same reason as Swim: keeps actionStates
			-- clean so the landing animation is never blocked by isActing.
			AnimationModule.PlayAnimation(character, animations.Fall, true, Enum.AnimationPriority.Movement, 1)
			activeStates[player] = {
				direction = "Fall",
				animId = animations.Fall,
			}
		end

		updateStand(player, character, wasMoving[player])

		lastDirection[player] = "Fall"
		return
	end

	-- ALWAYS update stand (fixes stuck animation bug)
	updateStand(player, character, wasMoving[player])

	-- Now we can early return safely for character
	if activeStates[player] and activeStates[player].direction == direction then
		lastDirection[player] = direction
		return
	end

	-- Stop old track if any
	if activeStates[player] and activeStates[player].animId ~= animId then
		AnimationModule.StopAnimation(character, activeStates[player].animId)
		activeStates[player] = nil
	end

	if not isActing then
		AnimationModule.PlayAnimation(character, animId, true, Enum.AnimationPriority.Movement, 1)
	end

	activeStates[player] = {
		direction = direction,
		animId = animId,
	}

	lastDirection[player] = direction
end

-- Setup when player spawns
local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		-- Movement direction changed
		humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
			onStateChanged(player, humanoid, character)
		end)

		-- Air/ground state changed
		humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
			onStateChanged(player, humanoid, character)
		end)
	end
end

-- Setup for new players
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		activeStates[player] = nil
		lastDirection[player] = nil
		swimmingPlayers[player] = nil
		if swimHeartbeats[player] then
			swimHeartbeats[player]:Disconnect()
			swimHeartbeats[player] = nil
		end

		onCharacterAdded(player, character)
	end)
end)

-- Mirror the swim state tracked by OceanService so the animation layer knows
-- when to override Fall with Swim (water has no collision, so FloorMaterial
-- is always Air while floating).
SwimmingState.OnServerEvent:Connect(function(player, action)
	if action == "Enter" then
		swimmingPlayers[player] = true

		-- Poll movement each heartbeat so SwimIdle ↔ SwimMove transitions fire
		-- even when the MoveDirection signal is delayed by network replication.
		if swimHeartbeats[player] then
			swimHeartbeats[player]:Disconnect()
		end
		local lastMoving = nil
		local stoppedAt = nil
		swimHeartbeats[player] = RunService.Heartbeat:Connect(function()
			local character = player.Character
			if not character then return end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end
			local isMoving = humanoid.MoveDirection.Magnitude > 0.1
			if isMoving then
				-- Moving: fire immediately, clear any pending idle timer.
				stoppedAt = nil
				if lastMoving ~= true then
					lastMoving = true
					onStateChanged(player, humanoid, character)
				end
			else
				-- Not moving: only commit to SwimIdle after 100 ms of continuous
				-- stillness so momentary MoveDirection drops from physics jitter
				-- don't restart the animation.
				if stoppedAt == nil then stoppedAt = tick() end
				if lastMoving ~= false and tick() - stoppedAt >= 0.1 then
					lastMoving = false
					onStateChanged(player, humanoid, character)
				end
			end
		end)

	elseif action == "Exit" then
		swimmingPlayers[player] = nil
		if swimHeartbeats[player] then
			swimHeartbeats[player]:Disconnect()
			swimHeartbeats[player] = nil
		end
	else
		return
	end

	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	onStateChanged(player, humanoid, character)
end)
