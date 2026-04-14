local Tusk = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local StandUtils = require(ServerScriptService.BasicCombat.StandUtils)
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))
local HeroManager = require(game.ServerScriptService.DataSaving.HeroManager)
local TandemModule = require(game.ServerScriptService.BasicCombat.StandModules:WaitForChild("TandemMode"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))

local ERASE_ANIM_ID = 90498591949232

local NAILSHOT_SPEED = 400
local NAILSHOT_GRAVITY = 0.2
local NAILSHOT_OFFSET = Vector3.new(0, 0, 8)
local NAILSHOT_SIZE = Vector3.new(7, 7, 7)
local NAILSHOT_DURATION = 5
local NAILSHOT_ENDLAG = 1

local GUIDEDNAIL_SPEED = 100
local GUIDEDNAIL_AOE_SIZE = Vector3.new(15, 15, 15)
local GUIDEDNAIL_AOE_DAMAGE = 20

local TELEPORT_DURATION = 8
local TELEPORT_COOLDOWN = 0.4

local INFINITEROTATION_OFFSET = CFrame.new(0, 0, -2)
local INFINITEROTATION_DURATION = 10

local SpawnClientVfx = ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")

function Tusk.NailShot(character)
	print("Nail shot on module!")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	CombatUtils.SetActionInProgress(character, NAILSHOT_ENDLAG)

	-- this will elp determiune the direction of the projectile
	local direction
	local startPos = hrp.Position
	local player = Players:GetPlayerFromCharacter(character)

	local remote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("RequestCameraDirection")
	local camDirection = remote:InvokeClient(player)

	if player then
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

	if player then
		local heroValue = HeroManager.GetField(player, "Hero")
		if heroValue then
			--HeroManager.SetField(player, "Hero", "TuskAct1")
			--heroValue = HeroManager.GetField(player, "Hero")
			print(player.Name .. " is now TuskAct1!")
		end

		StandUtils.RemoveStand(character)
		StandUtils.SummonStand(character, "TuskAct1")
	end

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "NailShotEffect",
		soundID = "89805684001014",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	local id = HttpService:GenerateGUID(false)

	HitboxSpawner.spawnArcProjectile({
		Character = character,
		Size = NAILSHOT_SIZE,
		Damage = 25,
		Duration = NAILSHOT_DURATION,
		Speed = NAILSHOT_SPEED,
		Direction = direction,
		Origin = startPos,
		Offset = NAILSHOT_OFFSET,
		Color = BrickColor.new("Bright yellow"),
		Gravity = Vector3.new(0, -workspace.Gravity * NAILSHOT_GRAVITY, 0), -- optional tweak
		DetectSurface = true,
		CanBlock = false,
		Transparency = 1,

		OnSurfaceHit = function(projectile, hitResult, horizontalDirection)
			SpawnClientVfx:FireAllClients({
				type = "Projectile",
				deleteId = id, -- tells the client to delete
			})
			print("Tusk Module Projectile hit surface:", hitResult.Instance.Name)
		end,
	})

	SpawnClientVfx:FireAllClients({
		type = "Projectile",
		effectName = "TuskPink",
		id = id,

		cframe = CFrame.new(startPos, startPos + direction),
		scale = NAILSHOT_SIZE,

		-- ✅ Arc motion
		arc = true,
		initialVelocity = direction.Unit * NAILSHOT_SPEED,
		gravity = Vector3.new(0, NAILSHOT_GRAVITY, 0),

		lifetime = NAILSHOT_DURATION,
	})

	return true
end

function Tusk.GuidedNail(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	CombatUtils.SetActionInProgress(character, NAILSHOT_ENDLAG)

	-- this will elp determiune the direction of the projectile
	local direction
	local startPos = hrp.Position

	local player = Players:GetPlayerFromCharacter(character)

	local remote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("RequestCameraDirection")
	local camDirection = remote:InvokeClient(player)

	if player then
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

	if player then
		local heroValue = HeroManager.GetField(player, "Hero")
		if heroValue then
			--HeroManager.SetField(player, "Hero", "TuskAct2")
			--heroValue = HeroManager.GetField(player, "Hero")
			print(player.Name .. " is now TuskAct2!")
		end

		StandUtils.RemoveStand(character)
		StandUtils.SummonStand(character, "TuskAct2")
	end

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "GuidedNailEffect",
		soundID = "89805684001014",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	local projectile = HitboxSpawner.spawnGuidedProjectile({
		Character = character,
		Size = NAILSHOT_SIZE,
		Damage = 25,
		Duration = 5,
		Speed = GUIDEDNAIL_SPEED,
		Direction = direction,
		Origin = startPos,
		Offset = NAILSHOT_OFFSET,
		Color = BrickColor.new("Bright yellow"),
		Gravity = Vector3.new(0, -workspace.Gravity * NAILSHOT_GRAVITY, 0), -- optional tweak
		DetectSurface = true,
		CanBlock = false,
		Transparency = 1,

		OnSurfaceHit = function(projectile, hitResult, horizontalDirection)
			print("[GoldExperimentModule!!!] Projectile hit surface:", hitResult.Instance.Name)

			local hitBoxOffset = Vector3.new(0, 3, 0)

			-- Determine stationary hitbox position
			local hitPosition = hitResult.Position

			-- Spawn a stationary damage hitbox
			local explosion = HitboxSpawner.spawnStationaryHitbox({
				Position = hitPosition,
				Character = character,
				Size = GUIDEDNAIL_AOE_SIZE,
				Damage = GUIDEDNAIL_AOE_DAMAGE,
				Offset = hitBoxOffset,
				Color = BrickColor.new("Bright red"),
				Duration = 1,
				StunDuration = 0,
				Transparency = 1,
				Name = "GuidedNailAOEHitbox",
				Rotation = horizontalDirection, -- ensures horizontal facing of projectile
				Shape = Enum.PartType.Ball,
			})

			SpawnClientVfx:FireAllClients({
				type = "Stationary",
				effectName = "GuidedNailExplosion",

				-- Position
				cframe = CFrame.new(explosion.Position),

				-- Lifetime
				lifetime = 1,

				-- Visual style
				scale = 1, -- starting size
			})
		end,
	})

	local vfxId = HttpService:GenerateGUID(false)
	projectile:SetAttribute("VFX_ID", vfxId)

	SpawnClientVfx:FireAllClients({
		type = "Attached",
		effectName = "GuidedNail",
		attachId = vfxId,
		scale = NAILSHOT_SIZE,
		attachTo = projectile,
	})

	return true
end

local function CreateWormholePair(character, posA, posB)
	local Players = game:GetService("Players")
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	local function createAnchor(position)
		local part = Instance.new("Part")
		part.Size = Vector3.new(4, 4, 4)
		part.Shape = Enum.PartType.Ball
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Color = Color3.fromRGB(255, 221, 0)
		part.Material = Enum.Material.Neon
		part.CFrame = CFrame.new(position)
		part.Name = "SpinWormholeAnchor"
		part.Parent = workspace

		local prompt = Instance.new("ProximityPrompt")
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.5
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 10
		prompt.ObjectText = "Spin Wormhole"
		prompt.ActionText = "Enter"
		prompt.Parent = part

		return part, prompt
	end

	local anchorA, promptA = createAnchor(posA)
	local anchorB, promptB = createAnchor(posB)

	local teleportDebounce = false

	local function teleportTo(targetPos)
		if teleportDebounce then
			return
		end
		teleportDebounce = true

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
		end

		task.delay(TELEPORT_COOLDOWN, function()
			teleportDebounce = false
		end)
	end

	promptA.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer ~= player then
			--return --add this line back to prevent other's using the teleport
			print("another player took the wormhole!")
		end
		teleportTo(anchorB.Position)
	end)

	promptB.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer ~= player then
			--return --add this line back to prevent other's using the teleport
			print("another player took the wormhole!")
		end
		teleportTo(anchorA.Position)
	end)

	SpawnClientVfx:FireAllClients({
		type = "Stationary",
		effectName = "TuskWormhole",

		-- Position
		cframe = CFrame.new(posA),

		-- Lifetime
		lifetime = TELEPORT_DURATION,

		-- Visual style
		transparency = 0.5,
		scale = 0.5, -- starting size

		-- Optional flags for client expansion logic
		expand = true,
		expandRate = 10,
		maxScale = 2,
	})

	SpawnClientVfx:FireAllClients({
		type = "Stationary",
		effectName = "TuskWormhole",

		-- Position
		cframe = CFrame.new(posB),

		-- Lifetime
		lifetime = TELEPORT_DURATION,

		-- Visual style
		transparency = 0.5,
		scale = 0.5, -- starting size

		-- Optional flags for client expansion logic
		expand = true,
		expandRate = 10,
		maxScale = 2,
	})

	-- Auto cleanup
	task.delay(TELEPORT_DURATION, function()
		if anchorA then
			anchorA:Destroy()
		end
		if anchorB then
			anchorB:Destroy()
		end
	end)
end

function Tusk.SpinWormhole(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	CombatUtils.SetActionInProgress(character, NAILSHOT_ENDLAG)

	-- this will elp determiune the direction of the projectile
	local direction
	local startPos = hrp.Position

	local player = Players:GetPlayerFromCharacter(character)

	local remote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("RequestCameraDirection")
	local camDirection = remote:InvokeClient(player)

	if player then
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

	if player then
		local heroValue = HeroManager.GetField(player, "Hero")
		if heroValue then
			--HeroManager.SetField(player, "Hero", "TuskAct3")
			--heroValue = HeroManager.GetField(player, "Hero")
			print(player.Name .. " is now TuskAct3!")
		end

		StandUtils.RemoveStand(character)
		StandUtils.SummonStand(character, "TuskAct3")
	end

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "GuidedNailEffect",
		soundID = "89805684001014",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	local projectile = HitboxSpawner.spawnGuidedProjectile({
		Character = character,
		Size = NAILSHOT_SIZE,
		Damage = 25,
		Duration = 5,
		Speed = GUIDEDNAIL_SPEED,
		Direction = direction,
		Origin = startPos,
		Offset = NAILSHOT_OFFSET,
		Color = BrickColor.new("Bright yellow"),
		Gravity = Vector3.new(0, -workspace.Gravity * NAILSHOT_GRAVITY, 0), -- optional tweak
		DetectSurface = true,
		CanBlock = false,
		Transparency = 1,

		OnSurfaceHit = function(projectile, hitResult, horizontalDirection)
			print("[SpinWormhole] Projectile hit surface:", hitResult.Instance.Name)

			local hitPosition = hitResult.Position
			local originPosition = hrp.Position

			CreateWormholePair(character, originPosition, hitPosition)
		end,
	})

	local vfxId = HttpService:GenerateGUID(false)
	projectile:SetAttribute("VFX_ID", vfxId)

	SpawnClientVfx:FireAllClients({
		type = "Attached",
		effectName = "GuidedNail",
		attachId = vfxId,
		scale = NAILSHOT_SIZE,
		attachTo = projectile,
	})

	return true
end

function Tusk.InfiniteRotation(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	CombatUtils.SetActionInProgress(character, INFINITEROTATION_DURATION + 0.5)

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return
	end

	-- this will elp determiune the direction of the projectile
	local player = Players:GetPlayerFromCharacter(character)

	if player then
		local heroValue = HeroManager.GetField(player, "Hero")
		if heroValue then
			--HeroManager.SetField(player, "Hero", "TuskAct4")
			--heroValue = HeroManager.GetField(player, "Hero")
			print(player.Name .. " is now TuskAct4!")
		end

		StandUtils.RemoveStand(character)
		standModel = StandUtils.SummonStand(character, "TuskAct4")
	end

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "GuidedNailEffect",
		soundID = "89805684001014",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	task.wait(0.5)
	TandemModule.EnterTandemMode(character, standModel, true, "Screen", true)

	local hitbox = HitboxSpawner.spawnHitbox({
		Character = character,
		Size = Vector3.new(6, 6, 6),
		Damage = 30,
		Duration = INFINITEROTATION_DURATION,
		DetectSurface = true,
		Transparency = 1,
		Offset = INFINITEROTATION_OFFSET,
		RemoveOnStun = false,

		OnSurfaceHit = function(hitbox, hitResult, horizontalDirection)
			print("Act 4 hit surface:", hitResult.Instance.Name)

			TandemModule.ExitTandemMode(character)

			HitboxSpawner.spawnStationaryHitbox({
				Character = character,
				Position = hitResult.Position,
				Size = Vector3.new(25, 25, 25),
				Damage = 70,
				Duration = 1,
			})

			SpawnClientVfx:FireAllClients({
				type = "Stationary",
				effectName = "TuskBomb",

				-- Position
				cframe = CFrame.new(hitResult.Position),

				-- Lifetime
				lifetime = 1,

				-- Visual style
				scale = 0.3, -- starting size

				-- Optional flags for client expansion logic
				expand = true,
				expandRate = 10,
				maxScale = 2.5,
			})

			CombatUtils.ResetActionInProgress(character)
		end,
	})

	local vfxId = HttpService:GenerateGUID(false)
	hitbox:SetAttribute("VFX_ID", vfxId)

	SpawnClientVfx:FireAllClients({
		type = "Attached",
		effectName = "StarParticles",
		attachId = vfxId,
		scale = NAILSHOT_SIZE,
		attachTo = hitbox,
	})

	task.wait(INFINITEROTATION_DURATION)
	TandemModule.ExitTandemMode(character)

	return true
end

return Tusk
