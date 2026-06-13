local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local NPCController = {}
NPCController.__index = NPCController

local WALK_ANIM_ID = 111996277762833
local IDLE_ANIM_ID = 103218691522993 -- replace with your idle animation

-- Constructor
function NPCController.new(npc, config)
	local self = setmetatable({}, NPCController)

	self.npc = npc
	self.humanoid = npc:WaitForChild("Humanoid")
	self.rootPart = npc:WaitForChild("HumanoidRootPart")

	self.config = config

	-- State
	self.aggro = false
	self.currentTarget = nil
	self.spawnPosition = self.rootPart.Position
	self.damageLog = {}

	-- Path state
	self.currentPath = nil
	self.waypoints = {}
	self.waypointIndex = 1
	self.lastTargetPos = nil
	self.pathTarget = nil

	self.isMoving = false
	self.lastMoveTime = 0

	self.currentAnimationState = nil
	self.lastMovementTime = 0

	self.lastMoveTarget = nil
	self.pathBlockedConnection = nil

	self.aggroType = nil
	self.lastAggroSwap = 0

	self:_start()

	return self
end

function NPCController:isTargetValid(character)
	if not character then
		return false
	end

	local humanoid = character:FindFirstChild("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	return humanoid and root and humanoid.Health > 0 and character.Parent
end

function NPCController:setCombatTarget(character)
	if not self:isTargetValid(character) then
		return
	end

	self.aggro = true
	self.aggroType = "Combat"
	self.currentTarget = character
	self.humanoid.WalkSpeed = self.config.CHASE_SPEED

	self.lastAggroSwap = tick()
end

function NPCController:setAnimationState(state)
	if self.currentAnimationState == state then
		return
	end

	self.currentAnimationState = state

	if state == "Idle" then
		AnimationModule.StopAnimation(self.npc, WALK_ANIM_ID)

		AnimationModule.PlayAnimation(self.npc, IDLE_ANIM_ID, true, Enum.AnimationPriority.Movement, 1)
	elseif state == "Walk" then
		AnimationModule.StopAnimation(self.npc, IDLE_ANIM_ID)

		AnimationModule.PlayAnimation(self.npc, WALK_ANIM_ID, true, Enum.AnimationPriority.Movement, 1)
	end
end

-- 🔍 Find nearest player
function NPCController:getNearestPlayer(maxDistance)
	local closestChar = nil
	local closestDist = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character

		if self:isTargetValid(character) then
			local dist = (character.HumanoidRootPart.Position - self.rootPart.Position).Magnitude

			if dist < closestDist and dist <= maxDistance then
				closestChar = character
				closestDist = dist
			end
		end
	end

	return closestChar, closestDist
end

-- 👁 LOS check
function NPCController:hasLineOfSight(targetCharacter)
	local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
	if not targetRoot then
		return false
	end

	local direction = targetRoot.Position - self.rootPart.Position

	if direction.Magnitude > self.config.MAX_VISION_DISTANCE then
		return false
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { self.npc, targetCharacter }
	rayParams.IgnoreWater = true

	local result = workspace:Raycast(self.rootPart.Position, direction, rayParams)

	return (not result) or result.Instance:IsDescendantOf(targetCharacter)
end

-- 🧭 Pathfinding
function NPCController:computePath(destination)
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
	})

	path:ComputeAsync(self.rootPart.Position, destination)

	if path.Status ~= Enum.PathStatus.Success then
		return nil
	end

	return path
end

function NPCController:followPath(destination)
	local path = self:computePath(destination)

	if not path then
		return
	end

	if self.pathBlockedConnection then
		self.pathBlockedConnection:Disconnect()
		self.pathBlockedConnection = nil
	end

	self.currentPath = path
	self.waypoints = path:GetWaypoints()
	self.waypointIndex = 1
	self.pathTarget = destination

	self.pathBlockedConnection = path.Blocked:Connect(function(blockedIndex)
		if blockedIndex >= self.waypointIndex and self.pathTarget then
			self:followPath(self.pathTarget)
		end
	end)
end

function NPCController:stopPath()
	if self.pathBlockedConnection then
		self.pathBlockedConnection:Disconnect()
		self.pathBlockedConnection = nil
	end

	self.currentPath = nil
	self.waypoints = {}
	self.waypointIndex = 1
end

-- 🚀 Movement loop
function NPCController:_movementLoop()
	task.spawn(function()
		while task.wait(0.05) do -- 🔥 faster updates = smoother
			if self.humanoid.Health <= 0 then
				continue
			end

			if self.currentPath then
				local waypoint = self.waypoints[self.waypointIndex]

				if waypoint then
					local nextWaypoint = self.waypoints[self.waypointIndex + 1]
					local targetPos = waypoint.Position

					-- 🔥 Smooth lookahead
					if nextWaypoint then
						targetPos = waypoint.Position:Lerp(nextWaypoint.Position, 0.6)
					end

					self.humanoid:MoveTo(targetPos)

					-- Jump handling
					if waypoint.Action == Enum.PathWaypointAction.Jump then
						self.humanoid.Jump = true
					end

					-- Advance waypoint
					if (self.rootPart.Position - waypoint.Position).Magnitude < 3 then
						self.waypointIndex += 1
					end
				else
					-- 🔥 PATH FINISHED → CLEAR IT
					self:stopPath()

					self.isMoving = false
					self:onStopMoving()
				end
			elseif self.aggro and self:isTargetValid(self.currentTarget) then
				local targetRoot = self.currentTarget.HumanoidRootPart

				if not self.lastMoveTarget or (targetRoot.Position - self.lastMoveTarget).Magnitude > 2 then
					self.lastMoveTarget = targetRoot.Position
					self.humanoid:MoveTo(targetRoot.Position)
				end
			end

			-- Detect if we've stopped moving
			local moveMagnitude = self.rootPart.AssemblyLinearVelocity.Magnitude

			if moveMagnitude > 1 then
				self.lastMovementTime = tick()

				if not self.isMoving then
					self.isMoving = true
					self:onStartMoving()
				elseif self.currentAnimationState ~= "Walk" then
					self:setAnimationState("Walk")
				end
			else
				-- wait a little before idling
				if self.isMoving and tick() - self.lastMovementTime > 0.25 then
					self.isMoving = false
					self:onStopMoving()
				end
			end

			if not self.isMoving and self.currentAnimationState ~= "Idle" then
				self:setAnimationState("Idle")
			end
		end
	end)
end

-- 🧠 Main AI loop
function NPCController:_aiLoop()
	task.spawn(function()
		while task.wait(0.15) do
			if self.humanoid.Health <= 0 then
				continue
			end

			--------------------------------------------------
			-- Acquire target
			--------------------------------------------------

			if not self.aggro then
				local nearest = self:getNearestPlayer(self.config.AGGRO_RADIUS)

				if nearest and self:hasLineOfSight(nearest) then
					self.aggro = true
					self.aggroType = "Passive"
					self.currentTarget = nearest
					self.humanoid.WalkSpeed = self.config.CHASE_SPEED

					self:onAggro()
				end
			end

			--------------------------------------------------
			-- Combat
			--------------------------------------------------

			if self.aggro then
				if not self:isTargetValid(self.currentTarget) then
					self:reset()
					continue
				end

				local searchRadius

				if self.aggroType == "Combat" then
					searchRadius = self.config.COMBAT_CHASE_RADIUS
				else
					searchRadius = self.config.PASSIVE_CHASE_RADIUS
				end

				local targetRoot = self.currentTarget.HumanoidRootPart
				local targetPos = targetRoot.Position

				local distToTarget = (targetPos - self.rootPart.Position).Magnitude

				local distFromSpawn = (self.rootPart.Position - self.spawnPosition).Magnitude

				local chaseRadius

				if self.aggroType == "Combat" then
					chaseRadius = self.config.COMBAT_CHASE_RADIUS
				else
					chaseRadius = self.config.PASSIVE_CHASE_RADIUS
				end

				if distToTarget > chaseRadius then
					self:reset()
					continue
				end

				if distFromSpawn > self.config.LEASH_DISTANCE then
					self:reset()
					continue
				end

				if self:hasLineOfSight(self.currentTarget) then
					self:stopPath()
				else
					if not self.pathTarget or (targetPos - self.pathTarget).Magnitude > self.config.REPATH_DISTANCE then
						self:followPath(targetPos)
					end
				end

			--------------------------------------------------
			-- Return home
			--------------------------------------------------
			else
				local dist = (self.rootPart.Position - self.spawnPosition).Magnitude

				if dist > self.config.RETURN_THRESHOLD then
					if
						not self.pathTarget
						or (self.spawnPosition - self.pathTarget).Magnitude > self.config.REPATH_DISTANCE
					then
						self:followPath(self.spawnPosition)
					end
				else
					self:stopPath()
					self.pathTarget = nil

					self.isMoving = false
					self:onStopMoving()
				end
			end
		end
	end)
end

-- 🔄 Reset
function NPCController:reset()
	self.aggro = false
	self.currentTarget = nil
	self.lastTargetPos = nil
	self.damageLog = {}

	self.lastMoveTarget = nil

	self:stopPath()

	self.pathTarget = nil

	self.humanoid.WalkSpeed = self.config.WALK_SPEED

	self.isMoving = false
	self.aggroType = nil

	self:onStopMoving()
end

function NPCController:onAggro()
	-- override per NPC
end

function NPCController:onAttack()
	-- override per NPC
end

function NPCController:onStartMoving()
	self:setAnimationState("Walk")
end

function NPCController:onStopMoving()
	self:setAnimationState("Idle")
end

-- 🚀 Start system
function NPCController:_start()
	-- Movement
	self:_movementLoop()

	-- AI
	self:_aiLoop()

	self.humanoid.Died:Connect(function()
		self:stopPath()

		self.currentTarget = nil
		self.aggro = false
		self.aggroType = nil
	end)

	-- Aggro trigger
	self.humanoid.HealthChanged:Connect(function(health)
		if health >= self.humanoid.MaxHealth then
			return
		end

		local nearest = self:getNearestPlayer(self.config.COMBAT_CHASE_RADIUS)

		if not nearest then
			return
		end

		local wasCombat = self.aggroType == "Combat"

		self.aggro = true
		self.aggroType = "Combat"
		self.currentTarget = nearest
		self.humanoid.WalkSpeed = self.config.CHASE_SPEED

		if not wasCombat then
			self:onAggro()
		end
	end)

	-- Attack loop
	task.spawn(function()
		while task.wait(self.config.ATTACK_INTERVAL or 0.5) do
			if self.aggro and self:isTargetValid(self.currentTarget) then
				self:onAttack()
			end
		end
	end)

	task.delay(1, function()
		if self.humanoid.Health > 0 and not self.isMoving then
			self:setAnimationState("Idle")
		end
	end)
end

return NPCController
