local NuclearRain = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local StandUtils = require(ServerScriptService.BasicCombat.StandUtils)
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))
local BlockModule = require(ServerScriptService.BasicCombat.BlockModule)

local RAIN_REGEN = 2
local REGEN_INTERVAL = 1

local TORRENTIALDOWNPOUR_DAMAGE = 5
local TORRENTIALDOWNPOUR_SIZE = Vector3.new(30, 30, 30)
local TORRENTIALDOWNPOUR_OFFSET = Vector3.new(0, 0, 0)
local TORRENTIALDOWNPOUR_ENDLAG = 0.5
local TORRENTIALDOWNPOUR_INTERVAL = 0.75
local TORRENTIALDOWNPOUR_COST = 3

local HEAVYRAINDROP_DAMAGE = 25
local HEAVYRAINDROP_DURATION = 2
local HEAVYRAINDROP_SIZE = Vector3.new(10, 10, 10)
local HEAVYRAINDROP_SPEED = 100
local HEAVYRAINDROP_STUN = 1.4
local HEAVYRAINDROP_GRAVITY = -workspace.Gravity * 0.3

local EXPELBARRIER_SPEED = 160
local EXPELBARRIER_ANIM_ID = 136847469830162
local EXPELBARRIER_HITBOX_SIZE = Vector3.new(10, 6, 10)
local EXPELBARRIER_ENDLAG = 0.5
local EXPELBARRIER_OFFSET = Vector3.new(0, 0, 8)
local EXPELBARRIER_DURATION = 3
local EXPELBARRIER_STUN = 1.5

local LIQUIDCAGE_DURATION = 6
local LIQUIDCAGE_RADIUS = 25

local WALL_COUNT = 32 -- more = smoother circle
local WALL_THICKNESS = 1.5
local WALL_HEIGHT = 40

local RAINBARRIER_CONSTANT = 3 --damage taken / RAINBARRIER_CONSTANT amount of barrier
local RAINBARRIER_DECAY_RATE = 0.1
local RAINBARRIER_DECAY_DELAY = 12
local RAINBARRIER_MAX = 100

-- State tracking
local activeDownpours = {}
-- activeDownpours[character] = {
--     vfxRoot = BasePart,
--     vfxId = string,
-- }

local regenTasks = {} -- [character] = task reference

local SpawnClientVfx = ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")

-- Utility: get or create HamonMeter NumberValue
function NuclearRain.getRainValue(character)
	if not character then
		return
	end
	local val = character:FindFirstChild("RainMeter")
	if not val then
		val = Instance.new("NumberValue")
		val.Name = "RainMeter"
		val.Value = 100
		val.Parent = character
	end
	return val
end

function NuclearRain.initRainForPlayer(player)
	-- When the character spawns, ensure it has a HamonMeter
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid") -- wait until the character is fully loaded

		-- ✅ Safe access to Powers folder
		local powersFolder = player:WaitForChild("Powers")
		if not powersFolder then
			warn("⚠ NuclearRain: Powers folder missing for player", player.Name)
			return
		end

		-- ✅ Safe access to Hero value
		local heroValue = powersFolder:FindFirstChild("Hero")
		if heroValue and heroValue.Value == "NuclearRain" then
			NuclearRain.getRainValue(character)
			NuclearRain.StartRainRegen(character)
		end
		NuclearRain.StartRainRegen(character)
	end)
end

-- Spend rain if possible
function NuclearRain.SpendRain(character, amount)
	local rain = NuclearRain.getRainValue(character)
	if not rain then
		return false
	end
	if rain.Value >= amount then
		rain.Value -= amount
		return true
	else
		return false
	end
end

-- Start continuous rain regeneration for a character
function NuclearRain.StartRainRegen(character)
	if regenTasks[character] then
		return -- already regenerating
	end

	local rain = NuclearRain.getRainValue(character)
	if not rain then
		return
	end

	regenTasks[character] = task.spawn(function()
		while character.Parent do
			-- Only regen if not in active downpour
			if not activeDownpours[character] and rain.Value < 100 then
				rain.Value = math.min(rain.Value + RAIN_REGEN, 100)
			end
			task.wait(REGEN_INTERVAL)
		end
		regenTasks[character] = nil
	end)
end

-- Stop rain regeneration for a character
function NuclearRain.StopRainRegen(character)
	if regenTasks[character] then
		task.cancel(regenTasks[character])
		regenTasks[character] = nil
	end
end

-- Start the Torrential Downpour ability
function NuclearRain.StartTorrentialDownpour(standModel)
	print("Started downpour in module")
	local character = standModel.Parent
	if not character or activeDownpours[character] then
		return -- already active or invalid
	end
	-- Create state
	activeDownpours[character] = {}

	-- Animation and sound
	CombatUtils.SetActionInProgress(character, TORRENTIALDOWNPOUR_ENDLAG)

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "TorrentialDownpourEffect",
		soundID = "4961240438",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	-- Continuous hitbox + drain loop
	task.spawn(function()
		while activeDownpours[character] do
			local rainMeter = NuclearRain.getRainValue(character)
			if not rainMeter or rainMeter.Value < TORRENTIALDOWNPOUR_COST then
				NuclearRain.StopTorrentialDownpour(standModel)
				break
			end

			-- Spawn the hitbox
			HitboxSpawner.spawnHitbox({
				Character = character,
				Damage = TORRENTIALDOWNPOUR_DAMAGE,
				Size = TORRENTIALDOWNPOUR_SIZE,
				Offset = CFrame.new(TORRENTIALDOWNPOUR_OFFSET),
				Color = BrickColor.new("Bright red"),
				Duration = 0.75,
				Transparency = 1,
				Name = "TorrentialDownpourHitbox",
				Shape = Enum.PartType.Cylinder,
				Rotation = CFrame.Angles(0, 0, math.rad(90)),
				RemoveOnStun = false,

				OnHit = function(target, trueDamage)
					print("💥 NuclearRain hit " .. target.Name .. " for " .. trueDamage .. " damage!")
					CombatUtils.AddBarrier(character, {
						Id = "RainBarrier",
						Amount = trueDamage / RAINBARRIER_CONSTANT,
						MaxCap = RAINBARRIER_MAX,

						DecayRate = RAINBARRIER_DECAY_RATE,
						DecayDelay = RAINBARRIER_DECAY_DELAY,

						Priority = 10, -- example priority (tune as needed)
					})
				end,
			})

			-- Drain the rain meter
			rainMeter.Value -= TORRENTIALDOWNPOUR_COST

			task.wait(TORRENTIALDOWNPOUR_INTERVAL)
		end
	end)

	local vfxRoot = HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = 0,
		Size = Vector3.new(1, 1, 1),
		Offset = CFrame.new(0, 0, 0),
		Color = BrickColor.new("Bright red"),
		Duration = 30,
		Transparency = 1,
		Name = "TorrentialDownpourVfxRoot",
		RemoveOnStun = false,
	})

	local vfxId = HttpService:GenerateGUID(false)
	vfxRoot:SetAttribute("VFX_ID", vfxId)

	-- Store references
	activeDownpours[character].vfxRoot = vfxRoot
	activeDownpours[character].vfxId = vfxId

	SpawnClientVfx:FireAllClients({
		type = "Attached",
		effectName = "TorrentialDownpour",
		attachId = vfxId,
		offset = CFrame.new(0, 6, 0),
		attachTo = vfxRoot,
	})
end

-- Stop the Torrential Downpour ability
function NuclearRain.StopTorrentialDownpour(standModel)
	print("Stopped downpour in module")
	local character = standModel.Parent
	if not character then
		return
	end

	local state = activeDownpours[character]
	if not state then
		return
	end

	-- 🧨 Kill VFX root
	if state.vfxRoot and state.vfxRoot.Parent then
		state.vfxRoot:Destroy()
	end

	activeDownpours[character] = nil

	-- Optionally stop any looping animation or sound here
	SoundModule.StopSound(standModel.PrimaryPart, "TorrentialDownpourEffect")
end

function NuclearRain.HeavyRaindrop(character)
	print("Heavy raindrop fired on module")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	local player = game.Players:GetPlayerFromCharacter(character)
	if not player then
		return false
	end

	-- Find where the player is looking
	local maxDistance = 1500
	local targetPoint = RaycastModule.ReturnFacingPoint(character, maxDistance)
	if not targetPoint then
		warn("No target point found for HeavyRaindrop")
		return false
	end

	-- Spawn position: directly above the target point (like a drop from the sky)
	local spawnHeight = 50 -- adjust for how high above you want the drop to start
	local spawnPos = targetPoint + Vector3.new(0, spawnHeight, 0)

	-- Direction: straight down
	local direction = Vector3.new(0, -1, 0)

	local id = HttpService:GenerateGUID(false)

	-- Create the projectile
	local hitbox = HitboxSpawner.spawnArcProjectile({
		Character = character,
		Size = HEAVYRAINDROP_SIZE,
		Damage = HEAVYRAINDROP_DAMAGE,
		Duration = HEAVYRAINDROP_DURATION,
		Speed = HEAVYRAINDROP_SPEED,
		Direction = direction,
		Origin = spawnPos,
		Color = BrickColor.new("Bright yellow"),
		Gravity = Vector3.new(0, HEAVYRAINDROP_GRAVITY, 0), -- full gravity
		CanBlock = false,
		Shape = Enum.PartType.Ball,
		Rotation = CFrame.Angles(0, 0, 0),
		StunDuration = HEAVYRAINDROP_STUN,
		Transparency = 1,

		OnHit = function(target, trueDamage)
			print("💥 NuclearRain hit " .. target.Name .. " for " .. trueDamage .. " damage!")
			CombatUtils.AddBarrier(character, {
				Id = "RainBarrier",
				Amount = trueDamage / RAINBARRIER_CONSTANT,
				MaxCap = RAINBARRIER_MAX,

				DecayRate = RAINBARRIER_DECAY_RATE,
				DecayDelay = RAINBARRIER_DECAY_DELAY,

				Priority = 10, -- example priority (tune as needed)
			})

			BlockModule.StopBlocking(target)
		end,

		OnSurfaceHit = function(projectile, hitResult, horizontalDirection)
			print("hit surface:", hitResult.Instance.Name)
			SpawnClientVfx:FireAllClients({
				type = "Projectile",
				deleteId = id, -- tells the client to delete
			})
		end,
	})

	-- === Sound effects ===
	SoundModule.PlaySound({
		Root = hitbox,
		soundName = "HeavyRaindropEffect",
		soundID = "102332681553777",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})
	SoundModule.PlaySound({
		Root = hitbox,
		soundName = "HeavyRaindropEffect2",
		soundID = "9113070119",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	-- Optional: add sound or visual effect at the spawn position
	-- SoundModule.PlaySound({ Root = hrp, soundID = "YOUR_SOUND_ID_HERE", volume = 1, range = 120 })
	SpawnClientVfx:FireAllClients({
		type = "Projectile",
		effectName = "HeavyRaindrop",
		id = id,

		cframe = CFrame.new(spawnPos, spawnPos + direction),

		-- 🔧 FIX ORIENTATION OFFSET
		initialRotation = Vector3.new(
			math.rad(90),
			0, -- example, adjust as needed
			0
		),

		-- ✅ Arc motion
		arc = true,
		initialVelocity = direction.Unit * HEAVYRAINDROP_SPEED,
		gravity = Vector3.new(0, HEAVYRAINDROP_GRAVITY, 0),

		lifetime = HEAVYRAINDROP_DURATION,
	})

	return true
end

function NuclearRain.ExpelBarrier(character)
	print("ExpelBarrier fired in Module")

	-- 1️⃣ Read barrier FIRST
	local barrierDamage = CombatUtils.GetTotalBarrier(character)
	if barrierDamage < 0 then
		return false
	end

	-- 2️⃣ Remove all barriers
	CombatUtils.RemoveAllBarriers(character)

	local hrp = character:FindFirstChild("HumanoidRootPart")

	AnimationModule.PlayAnimation(character, EXPELBARRIER_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, EXPELBARRIER_ENDLAG)

	-- this will help determiune the direction of the projectile
	local direction
	local startPos = hrp.Position
	local player = Players:GetPlayerFromCharacter(character)

	if player then
		local isClose = RaycastModule.CheckIfTargetIsClose(character, 10)
		if isClose then
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

	local hitbox = HitboxSpawner.spawnProjectile({
		Character = character,
		Damage = barrierDamage,
		Size = EXPELBARRIER_HITBOX_SIZE,
		Offset = EXPELBARRIER_OFFSET,
		Color = BrickColor.new("Bright red"),
		Duration = EXPELBARRIER_DURATION,
		StunDuration = EXPELBARRIER_STUN,
		Transparency = 1,
		Name = "BarragePunchHitbox",
		Speed = EXPELBARRIER_SPEED,
		Direction = direction,
		Origin = startPos,
	})
	SpawnClientVfx:FireAllClients({
		type = "Projectile",
		effectName = "ExpelBarrier",

		initialRotation = Vector3.new(
			0,
			math.rad(90), -- example, adjust as needed
			0
		),

		origin = startPos,
		direction = direction,
		speed = EXPELBARRIER_SPEED,
		lifetime = EXPELBARRIER_DURATION,
	})
	SoundModule.PlaySound({
		Root = hitbox,
		soundName = "ExpelBarrierEffect",
		soundID = "127515642083654",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})
	return true
end

local function ensureCollisionGroup(name)
	local exists = false
	for _, group in ipairs(PhysicsService:GetCollisionGroups()) do
		if group.name == name then
			exists = true
			break
		end
	end

	if not exists then
		PhysicsService:CreateCollisionGroup(name)
	end
end

-- Ensure groups exist
ensureCollisionGroup("CageWall")
ensureCollisionGroup("NPC")
ensureCollisionGroup("PlayerCharacter")

-- Set collision rules
PhysicsService:CollisionGroupSetCollidable("CageWall", "NPC", true)
PhysicsService:CollisionGroupSetCollidable("CageWall", "PlayerCharacter", true)

local function createHollowCage(center, radius, duration)
	local folder = Instance.new("Folder")
	folder.Name = "LiquidCage"
	folder.Parent = workspace

	-- Cage walls
	for i = 1, WALL_COUNT do
		local angle = (i / WALL_COUNT) * math.pi * 2
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius

		local wall = Instance.new("Part")
		wall.Size = Vector3.new(WALL_THICKNESS, WALL_HEIGHT, radius * 0.35)
		wall.Anchored = true
		wall.CanCollide = true
		wall.Transparency = 1
		wall.CastShadow = false
		wall.Name = "CageWall"

		wall.CFrame = CFrame.new(center + Vector3.new(x, WALL_HEIGHT / 2, z)) * CFrame.Angles(0, -angle, 0)

		wall.Parent = folder
		PhysicsService:SetPartCollisionGroup(wall, "CageWall")

		SpawnClientVfx:FireAllClients({
			type = "Stationary",
			effectName = "Waterfall",

			-- Position
			cframe = wall.CFrame * CFrame.new(0, 20, 0),

			-- Lifetime
			lifetime = LIQUIDCAGE_DURATION,

			-- Visual style
			transparency = 1,
			scale = 1, -- starting size
		})
	end

	-- Cage roof (thin horizontal cylinder)
	local roof = Instance.new("Part")
	roof.Name = "CageRoof"
	roof.Shape = Enum.PartType.Cylinder
	roof.Size = Vector3.new(1.2, radius * 2, radius * 2) -- thin height
	roof.Anchored = true
	roof.CanCollide = true
	roof.CastShadow = false
	roof.Transparency = 1

	roof.CFrame = CFrame.new(center + Vector3.new(0, WALL_HEIGHT + 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90))

	roof.Parent = folder
	PhysicsService:SetPartCollisionGroup(roof, "CageWall")

	SpawnClientVfx:FireAllClients({
		type = "Stationary",
		effectName = "Plunge",

		-- Position
		cframe = roof.CFrame,

		-- Lifetime
		lifetime = LIQUIDCAGE_DURATION,

		-- Visual style
		transparency = 1,
		scale = 1, -- starting size
	})

	-- Cage floor (thin horizontal cylinder)
	local floor = Instance.new("Part")
	floor.Name = "CageRoof"
	floor.Shape = Enum.PartType.Cylinder
	floor.Size = Vector3.new(1.2, radius * 2, radius * 2) -- thin height
	floor.Anchored = true
	floor.CanCollide = true
	floor.CastShadow = false
	floor.Transparency = 1

	floor.CFrame = CFrame.new(center + Vector3.new(0, -WALL_HEIGHT * 0, 0)) * CFrame.Angles(0, 0, math.rad(90))

	floor.Parent = folder
	PhysicsService:SetPartCollisionGroup(floor, "CageWall")

	SpawnClientVfx:FireAllClients({
		type = "Stationary",
		effectName = "Plunge",

		-- Position
		cframe = floor.CFrame,

		-- Lifetime
		lifetime = LIQUIDCAGE_DURATION,

		-- Visual style
		transparency = 1,
		scale = 1, -- starting size
	})

	SoundModule.PlaySound({
		Root = floor,
		soundName = "LiquidCageEffect",
		soundID = "6679062776",
		volume = 0.5,
		playbackSpeed = 1,
		looped = false,
		range = 240,
	})

	SoundModule.PlaySound({
		Root = floor,
		soundName = "LiquidCageEffect2",
		soundID = "137086424700822",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 240,
	})

	game:GetService("Debris"):AddItem(folder, duration)
	return folder
end

function NuclearRain.LiquidCage(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local center = root.Position - Vector3.new(0, 15, 0)

	createHollowCage(center, LIQUIDCAGE_RADIUS, LIQUIDCAGE_DURATION)
end

local function setCharacterCollisionGroup(character, groupName)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(part, groupName)
		end
	end
end

-- Initialize for existing and future players
Players.PlayerAdded:Connect(function(player)
	NuclearRain.initRainForPlayer(player)
	player.CharacterAdded:Connect(function(character)
		setCharacterCollisionGroup(character, "PlayerCharacter")
	end)
end)

return NuclearRain
