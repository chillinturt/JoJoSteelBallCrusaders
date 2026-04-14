local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local NPCController = {}
NPCController.__index = NPCController

local WALK_ANIM_ID = 111996277762833

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

	self:_start()

	return self
end

-- 🔍 Find nearest player
function NPCController:getNearestPlayer()
	local closestChar, closestDist = nil, math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (player.Character.HumanoidRootPart.Position - self.rootPart.Position).Magnitude
			if dist < closestDist then
				closestChar = player.Character
				closestDist = dist
			end
		end
	end

	return closestChar
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

	self.currentPath = path
	self.waypoints = path:GetWaypoints()
	self.waypointIndex = 1
	self.pathTarget = destination
end

function NPCController:stopPath()
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

					self.isMoving = true
					self.lastMoveTime = os.clock()

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
				end
			elseif self.aggro and self.currentTarget then
				local targetRoot = self.currentTarget:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					self.humanoid:MoveTo(targetRoot.Position)

					self.isMoving = true
					self.lastMoveTime = os.clock()
				end
			end

			-- Detect if we've stopped moving
			if os.clock() - self.lastMoveTime > 0.3 then
				self.isMoving = false
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

			if self.aggro and self.currentTarget then
				local targetPos = self.currentTarget.HumanoidRootPart.Position

				local distToTarget = (targetPos - self.rootPart.Position).Magnitude
				local distFromSpawn = (self.rootPart.Position - self.spawnPosition).Magnitude

				if distToTarget > self.config.CHASE_RADIUS or distFromSpawn > self.config.LEASH_DISTANCE then
					self:reset()
					continue
				end

				if self:hasLineOfSight(self.currentTarget) then
					-- Direct movement
					self:stopPath()
				else
					-- Only repath if destination changed enough
					if not self.pathTarget or (targetPos - self.pathTarget).Magnitude > self.config.REPATH_DISTANCE then
						self.pathTarget = targetPos
						self:followPath(targetPos)
					end
				end

				-- Ensure animation plays while chasing
				if not self.isMoving then
					self:onStartMoving()
				end
			else
				local dist = (self.rootPart.Position - self.spawnPosition).Magnitude

				if dist > self.config.RETURN_THRESHOLD then
					-- ✅ Ensure animation plays while returning
					if not self.isMoving then
						self:onStartMoving()
					end

					-- Path back to spawn
					if
						not self.pathTarget
						or (self.spawnPosition - self.pathTarget).Magnitude > self.config.REPATH_DISTANCE
					then
						self:followPath(self.spawnPosition)
					end
				else
					-- ✅ FULLY RETURNED
					self:stopPath()
					self.pathTarget = nil -- 🔥 CRITICAL FIX

					-- ✅ Stop animation cleanly
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

	self.currentPath = nil
	self.pathTarget = nil -- 🔥 CRITICAL FIX
	self.humanoid.Health = self.humanoid.MaxHealth
end

-- 🎯 Hooks
function NPCController:onAggro()
	-- override per NPC
	AnimationModule.PlayAnimation(self.npc, WALK_ANIM_ID, true, Enum.AnimationPriority.Action, 1)
end

function NPCController:onAttack()
	-- override per NPC
end

function NPCController:onStartMoving()
	-- override per NPC
	AnimationModule.PlayAnimation(self.npc, WALK_ANIM_ID, true, Enum.AnimationPriority.Action, 1)
end

function NPCController:onStopMoving()
	-- override per NPC
	AnimationModule.StopAnimation(self.npc, WALK_ANIM_ID)
end

-- 🚀 Start system
function NPCController:_start()
	-- Movement
	self:_movementLoop()

	-- AI
	self:_aiLoop()

	-- Aggro trigger
	self.humanoid.HealthChanged:Connect(function(health)
		if health < self.humanoid.MaxHealth and not self.aggro then
			self.aggro = true
			self.currentTarget = self:getNearestPlayer()
			self.humanoid.WalkSpeed = self.config.CHASE_SPEED

			self:onAggro()
		end
	end)

	-- Attack loop
	task.spawn(function()
		while task.wait(self.config.ATTACK_INTERVAL or 0.5) do
			if self.aggro and self.currentTarget then
				self:onAttack()
			end
		end
	end)
end

return NPCController
