local MagiciansRed = {}

local CoreGui = game:GetService("CoreGui")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local BlockModule = require(ServerScriptService.BasicCombat.BlockModule)
local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local StandUtils = require(ServerScriptService.BasicCombat.StandUtils)
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))

local FLAMESHOT_SPEED = 400
local FLAMESHOT_GRAVITY = 0.2
local FLAMESHOT_OFFSET = Vector3.new(0, 0, 8)
local FLAMESHOT_SIZE = Vector3.new(7, 7, 7)
local FLAMESHOT_DAMAGE = 5
local FLAMESHOT_DURATION = 5

local REDBIND_DAMAGE = 5
local REDBIND_ENDLAG = 1
local REDBIND_SIZE = Vector3.new(8, 8, 9)
local REDBIND_OFFSET = Vector3.new(2, 0, -8)
local REDBIND_DPS = 1
local REDBIND_TICK_INTERVAL = 0.33
local REDBIND_DURATION = 5
local REDBIND_STUN = 1.5
local REDBIND_ANIM_ID = 90498591949232

local CROSSFIREHURRICANE_SPEED = 100
local CROSSFIREHURRICANE_GRAVITY = 0.05
local CROSSFIREHURRICANE_OFFSET = Vector3.new(0, 0, 8)
local CROSSFIREHURRICANE_SIZE = Vector3.new(13, 15, 13)
local CROSSFIREHURRICANE_DAMAGE = 10
local CROSSFIREHURRICANE_DURATION = 5

local CROSSFIREHURRICANE_EXPLOSION_SIZE = Vector3.new(40, 40, 40)
local CROSSFIREHURRICANE_EXPLOSION_DAMAGE = 5
local CROSSFIREHURRICANE_EXPLOSION_STUN = 1.5
local CROSSFIREHURRICANE_EXPLOSION_DPS = 2
local CROSSFIREHURRICANE_EXPLOSION_DURATION = 1

local HELLFIRE_DAMAGE = 10
local HELLFIRE_DPS = 3
local HELLFIRE_EXPLOSION_SIZE = Vector3.new(70, 70, 70)
local HELLFIRE_EXPLOSION_DURATION = 1

local HIT_SOUND_ID = 8255306220

local activeBurns = {}

local SpawnClientVfx = ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")

local function ClientFlameShotVfx(player, origin, direction)
	SpawnClientVfx:FireAllClients({
		type = "Projectile",
		effectName = "FlameShot",

		cframe = CFrame.new(origin, origin + direction),

		-- 🔧 FIX ORIENTATION OFFSET
		initialRotation = Vector3.new(
			math.rad(90),
			0, -- example, adjust as needed
			0
		),

		-- ✅ Arc motion
		arc = true,
		initialVelocity = direction.Unit * FLAMESHOT_SPEED,
		gravity = Vector3.new(0, -workspace.Gravity * FLAMESHOT_GRAVITY, 0),

		lifetime = FLAMESHOT_DURATION,
	})
end

local function ClientHellfireVfx(player, origin)
	SpawnClientVfx:FireAllClients({
		type = "Stationary",
		effectName = "Hellfire",

		-- Position
		cframe = CFrame.new(origin),

		-- Lifetime
		lifetime = HELLFIRE_EXPLOSION_DURATION,

		-- Rotation (slow spin)
		rotationSpeed = Vector3.new(
			0,
			math.rad(120), -- Y-axis spin
			0
		),

		-- Visual style
		transparency = 0.5,
		scale = 0.8, -- starting size

		-- Optional flags for client expansion logic
		expand = true,
		expandRate = 30,
		maxScale = 7,
	})

	print("[VFX] Hellfire end")
end

local function ClientCrossfireHurricaneVfx(player, origin, direction)
	SpawnClientVfx:FireAllClients({
		type = "Projectile",
		effectName = "CrossfireHurricane",

		cframe = CFrame.new(origin, origin + direction),

		-- ✅ Arc motion
		arc = true,
		initialVelocity = direction.Unit * CROSSFIREHURRICANE_SPEED,
		gravity = Vector3.new(0, -workspace.Gravity * CROSSFIREHURRICANE_GRAVITY, 0),

		lifetime = CROSSFIREHURRICANE_DURATION,
	})
end

local function ClientCrossfireHurricaneExplosionVfx(player, origin)
	SpawnClientVfx:FireAllClients({
		type = "Stationary",
		effectName = "CrossfireHurricaneExplosion",

		-- Position
		cframe = CFrame.new(origin),

		-- 🔥 FIX ORIENTATION
		initialRotation = Vector3.new(
			0, -- X
			0, -- Y
			math.rad(90) -- Z
		),

		-- Lifetime
		lifetime = CROSSFIREHURRICANE_EXPLOSION_DURATION,

		-- Rotation (fast spin)
		rotationSpeed = Vector3.new(
			math.rad(450),
			0, -- Y-axis spin
			0
		),

		-- Visual style
		transparency = 0.5,
		scale = 0.8, -- starting size

		-- Optional flags for client expansion logic
		expand = true,
		expandRate = 20,
		maxScale = 4,
	})

	print("[VFX] Hellfire end")
end

local function MapDamageToSound(damage: number)
	-- Clamp damage to a reasonable range (so extreme values don’t explode)
	local minDamage, maxDamage = 0, 50
	damage = math.clamp(damage, minDamage, maxDamage)

	-- Normalize to 0–1
	local t = (damage - minDamage) / (maxDamage - minDamage)

	-- Lerp volume (directly proportional)
	local minVolume, maxVolume = 0.1, 2
	local volume = minVolume + (maxVolume - minVolume) * t

	-- Lerp pitch (inversely proportional)
	local minPitch, maxPitch = 0.1, 2.0
	local pitch = maxPitch - (maxPitch - minPitch) * t

	return volume, pitch
end

local function makeStackKey()
	-- unique id for stacks; os.time()/tick() collisions are unlikely but we can combine
	return tostring(tick()) .. "-" .. tostring(math.random(1, 999999))
end

function MagiciansRed.ApplyBurnStack(humanoid, damagePerTick, tickInterval, duration, sourcePlayer)
	print("burn applied")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	-- ensure table exists
	if not activeBurns[humanoid] then
		activeBurns[humanoid] = {}
	end

	local stackID = makeStackKey()
	local totalTicks = math.max(1, math.floor(duration / tickInterval))

	activeBurns[humanoid][stackID] = {
		tickCount = 0,
		totalTicks = totalTicks,
		damagePerTick = damagePerTick,
		tickInterval = tickInterval,
		duration = duration, -- ✅ store this!
		sourcePlayer = sourcePlayer,
		alive = true,
	}

	task.spawn(function()
		while true do
			local stack = activeBurns[humanoid] and activeBurns[humanoid][stackID]

			if not humanoid or humanoid.Health <= 0 then
				break
			end
			if not stack or not stack.alive then
				break
			end
			if stack.tickCount >= stack.totalTicks then
				break
			end

			-- apply credit tag
			if stack.sourcePlayer then
				local tag = Instance.new("ObjectValue")
				tag.Name = "creator"
				tag.Value = stack.sourcePlayer
				tag.Parent = humanoid
				Debris:AddItem(tag, 1)
			end

			-- apply the burn damage
			humanoid:TakeDamage(stack.damagePerTick)

			-- Sound
			local ok, volume, pitch = pcall(function()
				return MapDamageToSound(stack.damagePerTick)
			end)
			if ok and volume then
				pcall(function()
					SoundModule.PlaySound({
						Root = humanoid.Parent,
						soundName = "HitSound",
						soundID = HIT_SOUND_ID,
						volume = volume,
						playbackSpeed = 1,
						looped = false,
						range = 160,
						pitch = pitch,
					})
				end)
			end

			-- increment tick
			stack.tickCount += 1

			task.wait(stack.tickInterval)
		end

		-- cleanup stack
		if activeBurns[humanoid] then
			activeBurns[humanoid][stackID] = nil
			if next(activeBurns[humanoid]) == nil then
				activeBurns[humanoid] = nil
			end
		end
	end)
end

-- ✅ Reset a humanoid’s burn stacks back to full duration
function MagiciansRed.ResetBurns(humanoid)
	print("Burn reset called")
	local burns = activeBurns[humanoid]
	if not burns then
		return
	end

	for _, stack in pairs(burns) do
		stack.tickCount = 0
		stack.totalTicks = math.max(1, math.floor(stack.duration / stack.tickInterval))
	end
end

-- Optional: helper to clear all burns on a humanoid completely
function MagiciansRed.ClearAllBurns(humanoid)
	if not humanoid then
		return
	end
	local list = activeBurns[humanoid]
	if not list then
		return
	end
	for stackID, stack in pairs(list) do
		stack.alive = false
		activeBurns[humanoid][stackID] = nil
	end
	activeBurns[humanoid] = nil
end

function MagiciansRed.FlameShot(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

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

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "FlameShotEffect",
		soundID = "89805684001014",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	HitboxSpawner.spawnArcProjectile({
		Character = character,
		Size = FLAMESHOT_SIZE,
		Damage = FLAMESHOT_DAMAGE,
		Duration = FLAMESHOT_DURATION,
		Speed = FLAMESHOT_SPEED,
		Direction = direction,
		Origin = startPos,
		Offset = FLAMESHOT_OFFSET,
		Color = BrickColor.new("Bright yellow"),
		Gravity = Vector3.new(0, -workspace.Gravity * FLAMESHOT_GRAVITY, 0), -- optional tweak
		DetectSurface = true,
		CanBlock = false,
		Transparency = 1,

		OnHit = function(targetChar, newDamage)
			local hitHumanoid = targetChar:FindFirstChild("Humanoid")

			-- Apply a burn stack (damage over time)
			MagiciansRed.ResetBurns(hitHumanoid)
		end,

		OnSurfaceHit = function(projectile, hitResult, horizontalDirection)
			print("MagiciansRed Module Projectile hit surface:", hitResult.Instance.Name)
		end,
	})

	--local vfxSpawn = startPos * CROSSFIREHURRICANE_OFFSET

	ClientFlameShotVfx(player, startPos, direction)

	return true
end

function MagiciansRed.RedBind(standModel)
	local character = standModel.Parent

	AnimationModule.PlayAnimation(standModel, REDBIND_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, REDBIND_ENDLAG)

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "RedBindEffect",
		soundID = "79475957308532",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = REDBIND_DAMAGE or 0.1,
		Size = REDBIND_SIZE,
		Offset = CFrame.new(REDBIND_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = 0.75,
		StunDuration = REDBIND_STUN,
		Transparency = 0.7,
		Name = "RedBindHitbox",

		OnHit = function(targetChar, newDamage)
			local hitHumanoid = targetChar:FindFirstChild("Humanoid")
			-- Apply normal hit damage
			if hitHumanoid and hitHumanoid.Health > 0 then
				hitHumanoid:TakeDamage(REDBIND_DAMAGE or 0.1)
			end

			-- Apply a burn stack (damage over time)
			MagiciansRed.ApplyBurnStack(
				hitHumanoid, -- The humanoid being hit
				REDBIND_DPS, -- Damage per tick
				REDBIND_TICK_INTERVAL, -- Tick interval (seconds)
				REDBIND_DURATION, -- Duration (seconds)
				Players:GetPlayerFromCharacter(character) -- Source player
			)
		end,
	})
end

function MagiciansRed.CrossfireHurricane(character)
	print("flame shot on module")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	-- this will elp determiune the direction of the projectile
	local direction
	local startPos = hrp.Position
	local player = Players:GetPlayerFromCharacter(character)

	local remote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("RequestCameraDirection")

	--local camDirection = remote:InvokeClient(player)

	if player then
		local isClose = RaycastModule.CheckIfTargetIsClose(character, 10)
		if isClose then
			--direction = hrp:GetPivot().LookVector
			direction = hrp:GetPivot().LookVector
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

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "CrossfireHurricaneCall",
		soundID = "77997049374880",
		volume = 4,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	HitboxSpawner.spawnArcProjectile({
		Character = character,
		Size = CROSSFIREHURRICANE_SIZE,
		Damage = CROSSFIREHURRICANE_DAMAGE,
		Duration = CROSSFIREHURRICANE_DURATION,
		Speed = CROSSFIREHURRICANE_SPEED,
		Direction = direction,
		Origin = startPos,
		Offset = CROSSFIREHURRICANE_OFFSET,
		Color = BrickColor.new("Bright yellow"),
		Gravity = Vector3.new(0, -workspace.Gravity * CROSSFIREHURRICANE_GRAVITY, 0), -- optional tweak
		DetectSurface = true,
		CanBlock = false,
		Transparency = 1,

		OnHit = function(targetChar, newDamage)
			BlockModule.StopBlocking(targetChar)
		end,

		OnSurfaceHit = function(projectile, hitResult, horizontalDirection)
			print("MagiciansRed Module Projectile hit surface:", hitResult.Instance.Name)

			print("[GoldExperimentModule!!!] Projectile hit surface:", hitResult.Instance.Name)

			local hitBoxOffset = Vector3.new(0, 0, 0)

			-- Determine stationary hitbox position
			local hitPosition = hitResult.Position

			-- Spawn a stationary damage hitbox
			local hitbox = HitboxSpawner.spawnStationaryHitbox({
				Position = hitPosition,
				Character = character,
				Size = CROSSFIREHURRICANE_EXPLOSION_SIZE,
				Offset = hitBoxOffset,
				Color = BrickColor.new("Bright red"),
				Duration = CROSSFIREHURRICANE_EXPLOSION_DURATION,
				StunDuration = CROSSFIREHURRICANE_EXPLOSION_STUN,
				Transparency = 1,
				Name = "CrossfireHurricaneExplosionHitbox",
				Rotation = horizontalDirection, -- ensures horizontal facing of projectile
				Damage = CROSSFIREHURRICANE_EXPLOSION_DAMAGE,

				OnHit = function(targetChar, newDamage)
					local hitHumanoid = targetChar:FindFirstChild("Humanoid")
					-- Apply normal hit damage
					if hitHumanoid and hitHumanoid.Health > 0 then
						hitHumanoid:TakeDamage(REDBIND_DAMAGE or 0.1)
					end

					-- Apply a burn stack (damage over time)
					MagiciansRed.ApplyBurnStack(
						hitHumanoid, -- The humanoid being hit
						CROSSFIREHURRICANE_EXPLOSION_DPS, -- Damage per tick
						REDBIND_TICK_INTERVAL, -- Tick interval (seconds)
						REDBIND_DURATION, -- Duration (seconds)
						Players:GetPlayerFromCharacter(character) -- Source player
					)
				end,
			})

			SoundModule.PlaySound({
				Root = hitbox,
				soundName = "CrossfireHurricaneExplosionEffect",
				soundID = "126319648004597",
				volume = 2,
				playbackSpeed = 1,
				looped = false,
				range = 160,
			})

			ClientCrossfireHurricaneExplosionVfx(player, hitPosition)
		end,
	})

	--local vfxSpawn = startPos * CROSSFIREHURRICANE_OFFSET

	ClientCrossfireHurricaneVfx(player, startPos, direction)

	return true
end

function MagiciansRed.Hellfire(character)
	local player = Players:GetPlayerFromCharacter(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "HellfireStartupEffect",
		soundID = "4633141679",
		volume = 10,
		playbackSpeed = 1,
		looped = false,
		range = 300,
	})

	task.wait(3)

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "HellfireExplosionEffect",
		soundID = "90854697257230",
		volume = 10,
		playbackSpeed = 1,
		looped = false,
		range = 300,
	})

	local hrpCFrame = hrp.CFrame

	local standModel = StandUtils.getStandModel(character)

	HitboxSpawner.spawnStationaryHitbox({
		Position = hrpCFrame,
		Stand = standModel,
		Character = character,
		Damage = HELLFIRE_DAMAGE,
		Size = HELLFIRE_EXPLOSION_SIZE,
		Color = BrickColor.new("Bright red"),
		Duration = HELLFIRE_EXPLOSION_DURATION,
		StunDuration = 1,
		Transparency = 0.9,
		Name = "HellfireHitbox",

		OnHit = function(targetChar, newDamage)
			local hitHumanoid = targetChar:FindFirstChild("Humanoid")

			if not CombatUtils.GetIsBlocking(targetChar).Value then
				-- Apply a burn stack (damage over time)
				MagiciansRed.ApplyBurnStack(
					hitHumanoid, -- The humanoid being hit
					HELLFIRE_DPS, -- Damage per tick
					REDBIND_TICK_INTERVAL, -- Tick interval (seconds)
					REDBIND_DURATION, -- Duration (seconds)
					Players:GetPlayerFromCharacter(character) -- Source player
				)
			end
		end,
	})

	ClientHellfireVfx(player, hrp.Position)
end

return MagiciansRed
