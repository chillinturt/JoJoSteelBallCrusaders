local GoldExperiment = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local StandUtils = require(ServerScriptService.BasicCombat.StandUtils)
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))

local LIFE_OVERFLOW_DAMAGE = 25
local LIFE_OVERFLOW_ENDLAG = 1
local LIFE_OVERFLOW_SIZE = Vector3.new(4, 4, 7)
local LIFE_OVERFLOW_OFFSET = Vector3.new(2, 0, -8)
local LIFE_OVERFLOW_HEAL = 30
local LIFE_OVERFLOW_STUN = 2

local ERASE_ANIM_ID = 90498591949232

local EAGLESTRIKE_DAMAGE = 20
local EAGLESTRIKE_SIZE = Vector3.new(4, 4, 7)
local EAGLESTRIKE_OFFSET = Vector3.new(0, 4, -2)
local EAGLESTRIKE_STUN = 1.5
local EAGLESTRIKE_SPEED = 170
local EAGLESTRIKE_REDIRECT_SPEED = 220
local EAGLESTRIKE_ENDLAG = 0.5
local EAGLESTRIKE_DURATION = 10

local TREEOFLIFE_DURATION = 4
local TREEOFLIFE_SIZE = Vector3.new(30, 30, 30)
local TREEOFLIFE_DELAY = 1
local TREEOFLIFE_HEAL = 4

local TREEOFLIFE_SEED_DAMAGE = 25
local TREEOFLIFE_SEED_SIZE = Vector3.new(5, 5, 5)
local TREEOFLIFE_SEED_SPEED = 100
local TREEOFLIFE_SEED_GRAVITY = -workspace.Gravity * 0.8
local TREEOFLIFE_SEED_DURATION = 5
local TREEOFLIFE_SEED_STUN = 1.5

local TRAP_RADIUS = 28
local TRAP_DURATION = 6
local TRAP_PULL_FORCE = 18000

local DEAD_ZONE_RADIUS = 3
local MAX_PULL_SPEED = 40
local DAMPING = 0.85
local CENTER_DAMPING = 0.25

local ENEMY_NPC_FOLDER = game.Workspace:WaitForChild("NPCs"):WaitForChild("EnemyNPCs")

-- track projectile state per player
local eagleStrikeState = {} -- [player] = "first" | "redirect"
local eagleStrikeProjectile = {} -- [player] = projectile instance
local eagleStrikeVfxId = {}

local SpawnClientVfx = ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")

function GoldExperiment.LifeOverflow(standModel)
	local character = standModel.Parent

	AnimationModule.PlayAnimation(standModel, ERASE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, LIFE_OVERFLOW_ENDLAG)

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "LifeOverflowEffect",
		soundID = "4567255304",
		volume = 5,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "LifeOverflowCall",
		soundID = "4748348740",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = LIFE_OVERFLOW_DAMAGE or 0.1,
		Size = LIFE_OVERFLOW_SIZE,
		Offset = CFrame.new(LIFE_OVERFLOW_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = 1,
		StunDuration = LIFE_OVERFLOW_STUN,
		Transparency = 1,
		Name = "LifeOverflowHitbox",
		Heal = LIFE_OVERFLOW_HEAL,
	})
end

function GoldExperiment.EagleStrike(character)
	local player = game.Players:GetPlayerFromCharacter(character)
	if not player then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	-- === Play animation & set endlag ===
	AnimationModule.PlayAnimation(standModel, ERASE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, EAGLESTRIKE_ENDLAG)

	-- === Determine whether this is the first use or redirect ===
	local isRedirect = eagleStrikeState[player] == "first"

	local id = HttpService:GenerateGUID(false)

	if eagleStrikeState[player] ~= "active" then
		-- === Direction ===
		local startPos = hrp.Position
		local direction
		local isClose = RaycastModule.CheckIfTargetIsClose(character, 10)
		if isClose then
			direction = hrp:GetPivot().LookVector
		else
			local targetPoint = RaycastModule.ReturnFacingPoint(character, 1500)
			if not targetPoint then
				warn("No target point found")
				return false
			end
			direction = (targetPoint - startPos).Unit
		end

		-- === Spawn first projectile ===
		local projectile = HitboxSpawner.spawnProjectile({
			Character = character,
			Damage = EAGLESTRIKE_DAMAGE,
			Size = EAGLESTRIKE_SIZE,
			Offset = EAGLESTRIKE_OFFSET,
			Color = BrickColor.new("Bright red"),
			Duration = EAGLESTRIKE_DURATION,
			StunDuration = EAGLESTRIKE_STUN,
			Transparency = 1,
			Name = "Eagle Strike Hitbox",
			Speed = EAGLESTRIKE_SPEED,
			Direction = direction,
			Origin = startPos,
		})

		-- === Sound effects ===
		SoundModule.PlaySound({
			Root = projectile,
			soundName = "EagleStrikeEffect",
			soundID = "3378924410",
			volume = 2,
			playbackSpeed = 1,
			looped = false,
			range = 160,
		})
		SoundModule.PlaySound({
			Root = projectile,
			soundName = "EagleStrikeEffect2",
			soundID = "139887585493497",
			volume = 2,
			playbackSpeed = 1,
			looped = false,
			range = 160,
		})

		local vfxId = HttpService:GenerateGUID(false)

		eagleStrikeProjectile[player] = projectile
		eagleStrikeState[player] = "active"
		eagleStrikeVfxId[player] = vfxId

		local offsetWorld = hrp.CFrame:VectorToWorldSpace(EAGLESTRIKE_OFFSET)
		local vfxOrigin = startPos + offsetWorld

		SpawnClientVfx:FireAllClients({
			type = "Projectile",
			effectName = "EagleStrike",
			id = vfxId,
			origin = vfxOrigin,
			direction = direction,
			speed = EAGLESTRIKE_SPEED,
			lifetime = EAGLESTRIKE_DURATION,
		})

		-- 🔥 Auto-cleanup when eagle expires
		task.delay(EAGLESTRIKE_DURATION, function()
			if eagleStrikeState[player] == "active" then
				eagleStrikeState[player] = nil
				eagleStrikeProjectile[player] = nil
				eagleStrikeVfxId[player] = nil
			end
		end)

		return true, "launch"
	else
		local oldProjectile = eagleStrikeProjectile[player]
		if not oldProjectile or not oldProjectile.Parent then
			return false
		end

		local startPos = (oldProjectile and oldProjectile.Parent) and oldProjectile.Position or hrp.Position
		oldProjectile:Destroy()

		local targetPoint = RaycastModule.ReturnFacingPoint(character, 1500)
		if not targetPoint then
			warn("EagleStrike redirect: no facing point found")
			return false
		end

		local direction = (targetPoint - startPos).Unit

		local projectile = HitboxSpawner.spawnProjectile({
			Character = character,
			Damage = EAGLESTRIKE_DAMAGE,
			Size = EAGLESTRIKE_SIZE,
			Offset = Vector3.new(0, 0, 0),
			Color = BrickColor.new("Bright yellow"),
			Duration = 10,
			StunDuration = EAGLESTRIKE_STUN,
			Transparency = 1,
			Name = "Eagle Strike Redirected Hitbox",
			Speed = EAGLESTRIKE_REDIRECT_SPEED,
			Direction = direction,
			Origin = startPos,
			CanBlock = false,
		})

		-- === Redirect projectile ===
		SoundModule.PlaySound({
			Root = projectile,
			soundName = "EagleStrikeRedirect",
			soundID = "491270608",
			volume = 2,
			playbackSpeed = 1,
			looped = false,
			range = 160,
		})

		SpawnClientVfx:FireAllClients({
			type = "Projectile",
			deleteId = eagleStrikeVfxId[player], -- tells the client to delete
		})

		-- Spawn redirect VFX
		local newVfxId = HttpService:GenerateGUID(false)

		SpawnClientVfx:FireAllClients({
			type = "Projectile",
			effectName = "EagleStrike",
			id = newVfxId,
			origin = startPos,
			direction = direction,
			speed = EAGLESTRIKE_REDIRECT_SPEED,
			lifetime = EAGLESTRIKE_DURATION,
		})

		eagleStrikeState[player] = nil
		eagleStrikeProjectile[player] = nil
		eagleStrikeVfxId[player] = nil

		return true, "redirect"
	end
end

function GoldExperiment.TreeOfLife(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	-- this will elp determiune the direction of the projectile
	local direction
	local startPos = hrp.Position + Vector3.new(0, 4, 0)
	local player = Players:GetPlayerFromCharacter(character)

	local remote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("RequestCameraDirection")

	if player then
		local camDirection = remote:InvokeClient(player)
		local isClose = RaycastModule.CheckIfTargetIsClose(character, 10)
		if isClose then
			--direction = hrp:GetPivot().LookVector
			direction = camDirection
		else
			local maxDistance = 1500
			local targetPoint = RaycastModule.ReturnFacingPoint(character, maxDistance)
			if not targetPoint then
				warn("No target point found")
				return false
			end

			-- Determine direction to target
			direction = (targetPoint - startPos).Unit
		end
	else
		direction = hrp:GetPivot().LookVector
	end

	local id = HttpService:GenerateGUID(false)

	local hitbox = HitboxSpawner.spawnArcProjectile({
		Character = character,
		Size = TREEOFLIFE_SEED_SIZE,
		Damage = TREEOFLIFE_SEED_DAMAGE,
		Duration = TREEOFLIFE_SEED_DURATION,
		Speed = TREEOFLIFE_SEED_SPEED,
		Direction = direction,
		Origin = startPos,
		Color = BrickColor.new("Bright yellow"),
		Gravity = Vector3.new(0, TREEOFLIFE_SEED_GRAVITY, 0), -- optional tweak
		DetectSurface = true,
		CanBlock = false,
		Transparency = 1,
		StunDuration = TREEOFLIFE_SEED_STUN,

		OnSurfaceHit = function(projectile, hitResult, horizontalDirection)
			print("[GoldExperimentModule!!!] Projectile hit surface:", hitResult.Instance.Name)

			local hitBoxOffset = Vector3.new(0, 0, 0)

			-- Determine stationary hitbox position
			local hitPosition = hitResult.Position

			local soundRoot = HitboxSpawner.spawnStationaryHitbox({
				Position = hitPosition,
				Character = character,
				Size = TREEOFLIFE_SIZE,
				Offset = hitBoxOffset,
				Color = BrickColor.new("Bright red"),
				Duration = TREEOFLIFE_DURATION,
				StunDuration = 0,
				Transparency = 1,
				Name = "TreeOfLifeSoundRoot",
				Rotation = horizontalDirection, -- ensures horizontal facing of projectile
			})

			SoundModule.PlaySound({
				Root = soundRoot,
				soundName = "TreeOfLifeEffect1",
				soundID = "9125405369",
				volume = 1.5,
				playbackSpeed = 1,
				looped = false,
				range = 200,
			})
			SoundModule.PlaySound({
				Root = soundRoot,
				soundName = "TreeOfLifeEffect2",
				soundID = "9120839010",
				volume = 3,
				playbackSpeed = 1,
				looped = false,
				range = 200,
			})
			SoundModule.PlaySound({
				Root = soundRoot,
				soundName = "TreeOfLifeEffect3",
				soundID = "9120881528",
				volume = 2,
				playbackSpeed = 1,
				looped = false,
				range = 200,
			})

			-- Damage loop
			task.spawn(function()
				local startTime = tick()

				while tick() - startTime < TREEOFLIFE_DURATION do
					-- Spawn a stationary damage hitbox
					HitboxSpawner.spawnStationaryHitbox({
						Position = hitPosition,
						Character = character,
						Size = TREEOFLIFE_SIZE,
						Offset = hitBoxOffset,
						Color = BrickColor.new("Bright red"),
						Duration = 1,
						StunDuration = 0,
						Transparency = 1,
						Name = "TreeOfLifeHitbox",
						Rotation = horizontalDirection, -- ensures horizontal facing of projectile
						Heal = TREEOFLIFE_HEAL,
						CanSelfHit = true,
					})

					-- Wait until next pulse
					task.wait(TREEOFLIFE_DELAY)
				end
			end)

			SpawnClientVfx:FireAllClients({
				type = "Stationary",
				effectName = "TreeOfLife",
				cframe = CFrame.new(hitPosition),

				initialRotation = Vector3.new(
					0, -- X
					0, -- Y
					math.rad(90) -- Z
				),

				lifetime = TREEOFLIFE_DURATION,

				scale = 0.1, -- starting size

				expand = true,
				expandRate = 4,
				maxScale = 1,
			})

			SpawnClientVfx:FireAllClients({
				type = "Projectile",
				deleteId = id, -- tells the client to delete
			})
		end,
	})

	SpawnClientVfx:FireAllClients({
		type = "Projectile",
		effectName = "TreeOfLifeSeed",
		id = id,

		cframe = CFrame.new(startPos, startPos + direction),

		-- ✅ Arc motion
		arc = true,
		initialVelocity = direction.Unit * TREEOFLIFE_SEED_SPEED,
		gravity = Vector3.new(0, TREEOFLIFE_SEED_GRAVITY, 0),

		lifetime = TREEOFLIFE_SEED_DURATION,
	})

	SoundModule.PlaySound({
		Root = hitbox,
		soundName = "TreeOfLifeSeedEffect",
		soundID = "608600954",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	return true
end

local function applyVortex(model, center, radius, duration)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp or humanoid.Health <= 0 then
		return
	end

	-- Save state
	local originalPlatformStand = humanoid.PlatformStand
	local originalAutoRotate = humanoid.AutoRotate

	humanoid.PlatformStand = true
	humanoid.AutoRotate = false

	local attachment = Instance.new("Attachment")
	attachment.Parent = hrp

	local force = Instance.new("VectorForce")
	force.Attachment0 = attachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.ApplyAtCenterOfMass = true
	force.Parent = hrp

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not model.Parent or humanoid.Health <= 0 then
			connection:Disconnect()
			return
		end

		local offset = center - hrp.Position
		local distance = offset.Magnitude

		-- Outside influence radius
		if distance > radius then
			force.Force = Vector3.zero
			return
		end

		local velocity = hrp.AssemblyLinearVelocity

		-- =========================
		-- 1️⃣ CENTER DEAD ZONE
		-- =========================
		if distance <= DEAD_ZONE_RADIUS then
			-- Kill almost all motion near center
			hrp.AssemblyLinearVelocity = velocity * CENTER_DAMPING
			force.Force = Vector3.zero
			return
		end

		-- =========================
		-- 2️⃣ DIRECTIONAL PULL
		-- =========================
		local direction = offset.Unit
		local pullStrength = math.clamp(1 - (distance / radius), 0.25, 1)
		local desiredForce = direction * TRAP_PULL_FORCE * pullStrength

		-- =========================
		-- 3️⃣ VELOCITY DAMPING
		-- =========================
		local radialSpeed = velocity:Dot(direction)
		local tangentialVelocity = velocity - direction * radialSpeed

		-- Kill orbiting
		velocity -= tangentialVelocity * DAMPING

		-- Clamp inward speed
		if radialSpeed > MAX_PULL_SPEED then
			velocity -= direction * (radialSpeed - MAX_PULL_SPEED)
		end

		hrp.AssemblyLinearVelocity = velocity
		force.Force = desiredForce
	end)

	task.delay(duration, function()
		if connection then
			connection:Disconnect()
		end
		force:Destroy()
		attachment:Destroy()

		if humanoid then
			humanoid.PlatformStand = originalPlatformStand
			humanoid.AutoRotate = originalAutoRotate
		end
	end)
end

function GoldExperiment.CarnivorousTrap(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	-- this will elp determiune the direction of the projectile
	local direction
	local startPos = hrp.Position + Vector3.new(0, 4, 0)
	local player = Players:GetPlayerFromCharacter(character)

	local remote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("RequestCameraDirection")

	if player then
		local camDirection = remote:InvokeClient(player)
		local isClose = RaycastModule.CheckIfTargetIsClose(character, 10)
		if isClose then
			--direction = hrp:GetPivot().LookVector
			direction = camDirection
		else
			local maxDistance = 1500
			local targetPoint = RaycastModule.ReturnFacingPoint(character, maxDistance)
			if not targetPoint then
				warn("No target point found")
				return false
			end

			-- Determine direction to target
			direction = (targetPoint - startPos).Unit
		end
	else
		direction = hrp:GetPivot().LookVector
	end

	local id = HttpService:GenerateGUID(false)

	local projectile = HitboxSpawner.spawnArcProjectile({
		Character = character,
		Size = TREEOFLIFE_SEED_SIZE,
		Damage = TREEOFLIFE_SEED_DAMAGE,
		Duration = TREEOFLIFE_SEED_DURATION,
		Speed = TREEOFLIFE_SEED_SPEED,
		Direction = direction,
		Origin = startPos,
		Color = BrickColor.new("Bright yellow"),
		Gravity = Vector3.new(0, TREEOFLIFE_SEED_GRAVITY, 0), -- optional tweak
		DetectSurface = true,
		CanBlock = false,
		Transparency = 1,
		StunDuration = TREEOFLIFE_SEED_STUN,

		OnSurfaceHit = function(projectile, hitResult, horizontalDirection)
			print("[GoldExperiment] CarnivorousTrap activated")

			local hitBoxOffset = Vector3.new(0, 0, 0)

			-- Determine stationary hitbox position
			local hitPosition = hitResult.Position

			local center = hitResult.Position

			-- Pull PLAYERS
			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character and player.Character ~= character then
					local hrp = player.Character:FindFirstChild("HumanoidRootPart")
					if hrp and (hrp.Position - center).Magnitude <= TRAP_RADIUS then
						applyVortex(player.Character, center, TRAP_RADIUS, TRAP_DURATION)
					end
				end
			end

			-- Pull NPCs
			for _, npc in ipairs(ENEMY_NPC_FOLDER:GetChildren()) do
				local hrp = npc:FindFirstChild("HumanoidRootPart")
				if hrp and (hrp.Position - center).Magnitude <= TRAP_RADIUS then
					applyVortex(npc, center, TRAP_RADIUS, TRAP_DURATION)
				end
			end

			-- VFX
			SpawnClientVfx:FireAllClients({
				type = "Stationary",
				effectName = "CarnivorousTrap",
				cframe = CFrame.new(center),
				lifetime = TRAP_DURATION,
				scale = 0.1,
				expand = true,
				expandRate = 4,
				maxScale = 1,
			})

			SpawnClientVfx:FireAllClients({
				type = "Projectile",
				deleteId = id,
			})

			local soundRoot = HitboxSpawner.spawnStationaryHitbox({
				Position = hitPosition,
				Character = character,
				Size = TREEOFLIFE_SIZE,
				Offset = hitBoxOffset,
				Color = BrickColor.new("Bright red"),
				Duration = TRAP_DURATION,
				StunDuration = 0,
				Transparency = 1,
				Name = "CarnivorousTrapSoundRoot",
				Rotation = horizontalDirection, -- ensures horizontal facing of projectile
			})

			SoundModule.PlaySound({
				Root = soundRoot,
				soundName = "CarnivorousTrapLeavesEffect",
				soundID = "677921455",
				volume = 4,
				playbackSpeed = 1,
				looped = false,
				range = 240,
			})
		end,
	})

	SpawnClientVfx:FireAllClients({
		type = "Projectile",
		effectName = "CarnivorousTrapSeed",
		id = id,

		cframe = CFrame.new(startPos, startPos + direction),

		-- ✅ Arc motion
		arc = true,
		initialVelocity = direction.Unit * TREEOFLIFE_SEED_SPEED,
		gravity = Vector3.new(0, TREEOFLIFE_SEED_GRAVITY, 0),

		lifetime = TREEOFLIFE_SEED_DURATION,
	})

	SoundModule.PlaySound({
		Root = projectile,
		soundName = "CarnivorousTrapSeedEffect",
		soundID = "608600954",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 240,
	})

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "CarnivorousTrapCall",
		soundID = "6174593000",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 240,
	})

	task.delay(3, function()
		SoundModule.PlaySound({
			Root = hrp,
			soundName = "CarnivorousTrapCall2",
			soundID = "135077341189682",
			volume = 3,
			playbackSpeed = 1,
			looped = false,
			range = 240,
		})
	end)

	return true
end

return GoldExperiment
