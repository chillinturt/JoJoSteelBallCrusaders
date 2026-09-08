local Cream = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local StandUtils = require(ServerScriptService.BasicCombat.StandUtils)
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))

-- Shared placeholder animation used across all Cream abilities until dedicated
-- animations are authored.
local ERASE_ANIM_ID = 90498591949232

------------------------------------------------------------------------------
-- DarkSpace: dash forward as a void ball, erasing everything in the path.
-- Has 2 charges (managed in AbilityRegistry).
------------------------------------------------------------------------------
local DARKSPACE_DAMAGE = 22
local DARKSPACE_SIZE = Vector3.new(6, 6, 6)
local DARKSPACE_OFFSET = CFrame.new(0, 0, -3)
local DARKSPACE_SPEED = 95
local DARKSPACE_DASH_DURATION = 0.45
local DARKSPACE_STUN = 1.2
local DARKSPACE_ENDLAG = 0.6

------------------------------------------------------------------------------
-- HowsThat: grab the nearest opponent and unload a flurry of punches.
-- Both fighters are locked in place and shielded from outside interference
-- for the duration of the grab.
------------------------------------------------------------------------------
local HOWSTHAT_RANGE = 10
local HOWSTHAT_GRAB_DISTANCE = 4
local HOWSTHAT_PUNCH_COUNT = 6
local HOWSTHAT_PUNCH_INTERVAL = 0.15
local HOWSTHAT_PUNCH_DAMAGE = 4
local HOWSTHAT_FINISHER_DAMAGE = 12
local HOWSTHAT_FINISHER_STUN = 1.5
local HOWSTHAT_FINISHER_KNOCKBACK = 60
local HOWSTHAT_ENDLAG = 0.4

------------------------------------------------------------------------------
-- VoidLeap: turn into a void ball and fly along an arc, following the
-- projectile until it lands.
------------------------------------------------------------------------------
local VOIDLEAP_SIZE = Vector3.new(4, 4, 4)
local VOIDLEAP_DAMAGE = 25
local VOIDLEAP_SPEED = 120
local VOIDLEAP_DURATION = 5
local VOIDLEAP_GRAVITY = Vector3.new(0, -workspace.Gravity * 0.65, 0)
local VOIDLEAP_ENDLAG = 0.5

local VOIDLEAP_IMPACT_SIZE = Vector3.new(12, 12, 12)
local VOIDLEAP_IMPACT_DAMAGE = 40

------------------------------------------------------------------------------
-- MadnessSorrow: become a void ball and lash out in every direction,
-- dealing repeated damage to everyone nearby while retaining (slowed)
-- movement so the player can reposition the storm.
------------------------------------------------------------------------------
local MADNESS_DURATION = 4
local MADNESS_SIZE = Vector3.new(16, 16, 16)
local MADNESS_TICK_INTERVAL = 0.5
local MADNESS_TICK_DAMAGE = 8
local MADNESS_TICK_STUN = 0.6
local MADNESS_FINAL_KNOCKBACK = 80
local MADNESS_ENDLAG = 0.6

local SpawnClientVfx = ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")

--------------------------------------------------------------------------------
-- Shared helper: resolve the direction the player is aiming, falling back to
-- their facing direction when nothing is targeted.
--------------------------------------------------------------------------------
local function getAimDirection(character, hrp, maxCloseDistance)
	local isClose = RaycastModule.CheckIfTargetIsClose(character, maxCloseDistance or 10)
	if isClose then
		return hrp.CFrame.LookVector
	end

	local targetPoint = RaycastModule.ReturnFacingPoint(character, 1500)
	if not targetPoint then
		return hrp.CFrame.LookVector
	end

	local direction = targetPoint - hrp.Position
	if direction.Magnitude < 0.01 then
		return hrp.CFrame.LookVector
	end

	return direction.Unit
end

--Cream turns the user into a void ball, dashing forward and erasing everything caught
--in the attached hitbox for the duration of the dash.
function Cream.DarkSpace(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		return false
	end

	local standModel = StandUtils.getStandModel(character)

	local worldDirection = getAimDirection(character, hrp, 10)
	worldDirection = Vector3.new(worldDirection.X, 0, worldDirection.Z)
	if worldDirection.Magnitude < 0.01 then
		worldDirection = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	end
	worldDirection = worldDirection.Unit

	-- Convert to local space so ApplyTurningVelocity (the standard dash utility) can drive it
	local localDirection = hrp.CFrame:VectorToObjectSpace(worldDirection)

	AnimationModule.PlayAnimation(standModel, ERASE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, DARKSPACE_ENDLAG, false)
	CombatUtils.SetInvulnerable(character, DARKSPACE_DASH_DURATION + 0.15)
	CombatUtils.SetIsDashing(character, DARKSPACE_DASH_DURATION)

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "DarkSpaceDash",
		soundID = "4567255304",
		volume = 3,
		playbackSpeed = 1.3,
		looped = false,
	})

	CombatUtils.ApplyTurningVelocity({
		Character = character,
		Speed = DARKSPACE_SPEED,
		Duration = DARKSPACE_DASH_DURATION,
		Name = "DarkSpaceVelocity",
		Direction = localDirection,
	})

	HitboxSpawner.spawnStandOffHitbox({
		Character = character,
		Damage = DARKSPACE_DAMAGE,
		Size = DARKSPACE_SIZE,
		Offset = DARKSPACE_OFFSET,
		Color = BrickColor.new("Really black"),
		Duration = DARKSPACE_DASH_DURATION,
		StunDuration = DARKSPACE_STUN,
		Transparency = 1,
		Name = "DarkSpaceHitbox",
		CanBlock = false,
	})

	SpawnClientVfx:FireAllClients({
		type = "Particle",
		effectName = "DarkSpaceVoidBall",
		attachTo = hrp,
		emitCount = 6,
	})

	return true
end

--The player grabs the nearest opponent and unloads a flurry of punches at point-blank
--range. Both fighters are locked in place and untouchable by outside attacks until the
--grab ends (the attacker is fully shielded, the target is only vulnerable to this attack).
function Cream.HowsThat(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		return false
	end

	local standModel = StandUtils.getStandModel(character)

	local target = CombatUtils.GetNearestTarget(character, HOWSTHAT_RANGE, true)
	if not target then
		return false
	end

	local targetHRP = target:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
	if not targetHRP or not targetHumanoid or targetHumanoid.Health <= 0 then
		return false
	end

	local totalDuration = (HOWSTHAT_PUNCH_COUNT * HOWSTHAT_PUNCH_INTERVAL) + 0.5

	local prevSpeed, prevJump = humanoid.WalkSpeed, humanoid.JumpPower
	local prevTargetSpeed, prevTargetJump = targetHumanoid.WalkSpeed, targetHumanoid.JumpPower

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false

	targetHumanoid.WalkSpeed = 0
	targetHumanoid.JumpPower = 0
	targetHumanoid.AutoRotate = false

	CombatUtils.SetActionInProgress(character, totalDuration + HOWSTHAT_ENDLAG, false)
	CombatUtils.SetInvulnerable(character, totalDuration + 0.3)
	CombatUtils.SetInvulnerable(target, totalDuration + 0.3, character)

	AnimationModule.PlayAnimation(standModel, ERASE_ANIM_ID, true, Enum.AnimationPriority.Action, 1)

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "HowsThatGrab",
		soundID = "4748348740",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	-- Pin the target directly in front of the attacker for the duration of the grab.
	local holdConn
	holdConn = RunService.Heartbeat:Connect(function()
		if not hrp.Parent or not targetHRP.Parent then
			if holdConn then
				holdConn:Disconnect()
				holdConn = nil
			end
			return
		end

		local holdPosition = hrp.Position + (hrp.CFrame.LookVector * HOWSTHAT_GRAB_DISTANCE)
		targetHRP.CFrame = CFrame.new(holdPosition, holdPosition + hrp.CFrame.LookVector)
		targetHRP.AssemblyLinearVelocity = Vector3.zero
	end)

	local function releaseGrab()
		if holdConn then
			holdConn:Disconnect()
			holdConn = nil
		end

		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = prevSpeed
			humanoid.JumpPower = prevJump
			humanoid.AutoRotate = true
		end

		if targetHumanoid and targetHumanoid.Parent then
			targetHumanoid.WalkSpeed = prevTargetSpeed
			targetHumanoid.JumpPower = prevTargetJump
			targetHumanoid.AutoRotate = true
		end
	end

	task.spawn(function()
		for i = 1, HOWSTHAT_PUNCH_COUNT do
			if not character.Parent or not target.Parent or targetHumanoid.Health <= 0 then
				break
			end

			HitboxSpawner.spawnStandOffHitbox({
				Character = character,
				Damage = HOWSTHAT_PUNCH_DAMAGE,
				Size = Vector3.new(4, 4, 4),
				Offset = CFrame.new(0, 0, -HOWSTHAT_GRAB_DISTANCE),
				Color = BrickColor.new("Bright red"),
				Duration = 0.1,
				StunDuration = 0,
				Transparency = 1,
				Name = "HowsThatPunch",
				CanBlock = false,
			})

			SoundModule.PlaySound({
				Root = targetHRP,
				soundName = "HowsThatPunch",
				soundID = "3378924410",
				volume = 1.5,
				playbackSpeed = 1.1 + (math.random() * 0.2),
				looped = false,
			})

			SpawnClientVfx:FireAllClients({
				type = "Particle",
				effectName = "HowsThatPunch",
				attachTo = targetHRP,
				emitCount = 1,
			})

			task.wait(HOWSTHAT_PUNCH_INTERVAL)
		end

		-- Finisher: a bigger hit that knocks the target away and ends the grab.
		if target.Parent and targetHumanoid.Health > 0 then
			HitboxSpawner.spawnStandOffHitbox({
				Character = character,
				Damage = HOWSTHAT_FINISHER_DAMAGE,
				Size = Vector3.new(5, 5, 5),
				Offset = CFrame.new(0, 0, -HOWSTHAT_GRAB_DISTANCE),
				Color = BrickColor.new("Really black"),
				Duration = 0.15,
				StunDuration = HOWSTHAT_FINISHER_STUN,
				Transparency = 1,
				Name = "HowsThatFinisher",
				CanBlock = false,
			})

			SoundModule.PlaySound({
				Root = targetHRP,
				soundName = "HowsThatFinisher",
				soundID = "491270608",
				volume = 3,
				playbackSpeed = 0.9,
				looped = false,
			})
		end

		releaseGrab()

		if target.Parent and targetHumanoid.Health > 0 then
			local knockDir = targetHRP.Position - hrp.Position
			knockDir = Vector3.new(knockDir.X, 0.3, knockDir.Z)
			knockDir = knockDir.Magnitude > 0.01 and knockDir.Unit or hrp.CFrame.LookVector

			CombatUtils.ApplyInstantVelocity(targetHRP, knockDir * HOWSTHAT_FINISHER_KNOCKBACK)
		end
	end)

	return true
end

--Turn into a void ball and fly along an arc, following the projectile until it lands
--and erupts in a void impact.
function Cream.VoidLeap(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		return false
	end

	-- Prevent stacking
	if CombatUtils.GetActionInProgress(character) then
		return false
	end
	CombatUtils.SetActionInProgress(character, VOIDLEAP_ENDLAG)
	CombatUtils.SetInvulnerable(character, VOIDLEAP_DURATION)

	-- Disable movement
	humanoid.AutoRotate = false
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	local startPos = hrp.Position + Vector3.new(0, 4, 0)
	local player = Players:GetPlayerFromCharacter(character)

	local direction
	if player then
		local remote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("RequestCameraDirection")
		local camDirection = remote:InvokeClient(player)
		local isClose = RaycastModule.CheckIfTargetIsClose(character, 10)

		if isClose then
			direction = camDirection
		else
			local targetPoint = RaycastModule.ReturnFacingPoint(character, 1500)
			if not targetPoint then
				humanoid.AutoRotate = true
				humanoid.WalkSpeed = 16
				humanoid.JumpPower = 50
				return false
			end
			direction = (targetPoint - startPos).Unit
		end
	else
		direction = hrp.CFrame.LookVector
	end

	-- Create projectile
	local projectile = HitboxSpawner.spawnArcProjectile({
		Character = character,
		Size = VOIDLEAP_SIZE,
		Damage = VOIDLEAP_DAMAGE,
		Duration = VOIDLEAP_DURATION,
		Speed = VOIDLEAP_SPEED,
		Direction = direction,
		Origin = startPos,
		Gravity = VOIDLEAP_GRAVITY,
		DetectSurface = true,
		Transparency = 1,
		CanBlock = false,

		OnSurfaceHit = function(proj, hitResult)
			-- Detach player
			if hrp:FindFirstChild("CreamAttach") then
				hrp.CreamAttach:Destroy()
			end

			-- Restore movement
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true

			local hitPos = hitResult.Position

			HitboxSpawner.spawnStationaryHitbox({
				Position = hitPos,
				Character = character,
				Size = VOIDLEAP_IMPACT_SIZE,
				Damage = VOIDLEAP_IMPACT_DAMAGE,
				Duration = 0.5,
				StunDuration = 1.5,
				Transparency = 1,
				Name = "CreamImpact",
			})

			SpawnClientVfx:FireAllClients({
				type = "Stationary",
				effectName = "CreamImpact",
				cframe = CFrame.new(hitPos),
				lifetime = 1,
			})
		end,
	})

	-- Attach player to the projectile
	local attachment = Instance.new("Attachment")
	attachment.Name = "CreamAttach"
	attachment.Parent = hrp

	local align = Instance.new("AlignPosition")
	align.Attachment0 = attachment
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.RigidityEnabled = true
	align.MaxForce = 1e6
	align.Responsiveness = 200
	align.Parent = hrp

	-- Follow the projectile
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not projectile or not projectile.Parent then
			connection:Disconnect()
			return
		end

		align.Position = projectile.Position
	end)

	-- Safety cleanup (if projectile expires without hitting a surface)
	task.delay(VOIDLEAP_DURATION, function()
		if connection then
			connection:Disconnect()
		end

		if align then
			align:Destroy()
		end

		if attachment then
			attachment:Destroy()
		end

		if humanoid then
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
		end
	end)

	SpawnClientVfx:FireAllClients({
		type = "Projectile",
		effectName = "CreamVoidBall",
		cframe = CFrame.new(startPos, startPos + direction),
		lifetime = VOIDLEAP_DURATION,
	})

	return true
end

--Cream turns the user into a void ball and lashes out in every direction, dealing
--repeated damage to everyone nearby. The player keeps (slowed) movement control so
--they can reposition the storm while it's active.
function Cream.MadnessSorrow(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		return false
	end

	local standModel = StandUtils.getStandModel(character)

	CombatUtils.SetActionInProgress(character, MADNESS_DURATION + MADNESS_ENDLAG)
	CombatUtils.SetInvulnerable(character, MADNESS_DURATION + 0.3)

	AnimationModule.PlayAnimation(standModel, ERASE_ANIM_ID, true, Enum.AnimationPriority.Action, 1)

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "MadnessSorrowCall",
		soundID = "6174593000",
		volume = 3,
		playbackSpeed = 1,
		looped = false,
	})

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "MadnessSorrowLoop",
		soundID = "135077341189682",
		volume = 2,
		playbackSpeed = 1,
		looped = true,
	})

	SpawnClientVfx:FireAllClients({
		type = "Stationary",
		effectName = "MadnessSorrowAura",
		cframe = hrp.CFrame,
		lifetime = MADNESS_DURATION,
		scale = 0.1,
		expand = true,
		expandRate = 6,
		maxScale = 1,
	})

	task.spawn(function()
		local startTime = tick()
		local hitCharacters = {}

		while tick() - startTime < MADNESS_DURATION do
			if not character.Parent or humanoid.Health <= 0 then
				break
			end

			HitboxSpawner.spawnStandOffHitbox({
				Character = character,
				Damage = MADNESS_TICK_DAMAGE,
				Size = MADNESS_SIZE,
				Offset = CFrame.new(0, 0, 0),
				Color = BrickColor.new("Really black"),
				Duration = 0.2,
				StunDuration = MADNESS_TICK_STUN,
				Transparency = 1,
				Name = "MadnessSorrowLash",
				CanBlock = false,
				OnHit = function(targetChar)
					hitCharacters[targetChar] = true
				end,
			})

			SpawnClientVfx:FireAllClients({
				type = "Particle",
				effectName = "MadnessSorrowLash",
				attachTo = hrp,
				emitCount = 3,
			})

			task.wait(MADNESS_TICK_INTERVAL)
		end

		SoundModule.StopSound(hrp, "MadnessSorrowLoop")

		-- Final outward burst for anyone caught in the storm
		for targetChar in pairs(hitCharacters) do
			if targetChar.Parent then
				local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
				if targetHRP then
					local dir = targetHRP.Position - hrp.Position
					dir = Vector3.new(dir.X, 0.3, dir.Z)
					dir = dir.Magnitude > 0.01 and dir.Unit or Vector3.new(0, 0.3, 0)

					CombatUtils.ApplyInstantVelocity(targetHRP, dir * MADNESS_FINAL_KNOCKBACK)
				end
			end
		end

		SpawnClientVfx:FireAllClients({
			type = "Stationary",
			effectName = "MadnessSorrowBurst",
			cframe = hrp.CFrame,
			lifetime = 1,
		})
	end)

	return true
end

return Cream
