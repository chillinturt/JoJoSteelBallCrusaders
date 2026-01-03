local NuclearRain = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

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
local HEAVYRAINDROP_DURATION = 25
local HEAVYRAINDROP_SIZE = Vector3.new(10, 10, 10)
local HEAVYRAINDROP_SPEED = 100
local HEAVYRAINDROP_STUN = 1.4
local HEAVYRAINDROP_GRAVITY = -workspace.Gravity * 0.3

local RAINBARRIER_CONSTANT = 3 --damage taken / RAINBARRIER_CONSTANT amount of barrier
local RAINBARRIER_DECAY_RATE = 0.1
local RAINBARRIER_DECAY_DELAY = 12
local RAINBARRIER_MAX = 100

local ERASE_ANIM_ID = 90498591949232

-- State tracking
local activeDownpours = {} -- [character] = true while active
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
	activeDownpours[character] = true

	-- Animation and sound
	AnimationModule.PlayAnimation(standModel, ERASE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
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
				Transparency = 0.7,
				Name = "TorrentialDownpourHitbox",
				Shape = Enum.PartType.Cylinder,
				Rotation = CFrame.Angles(0, 0, math.rad(90)),

				OnHit = function(target, trueDamage)
					print("💥 NuclearRain hit " .. target.Name .. " for " .. trueDamage .. " damage!")
					CombatUtils.AddBarrier(
						character,
						trueDamage / RAINBARRIER_CONSTANT,
						RAINBARRIER_DECAY_RATE,
						RAINBARRIER_DECAY_DELAY,
						"RainBarrier",
						RAINBARRIER_MAX
					)
				end,
			})

			-- Drain the rain meter
			rainMeter.Value -= TORRENTIALDOWNPOUR_COST

			task.wait(TORRENTIALDOWNPOUR_INTERVAL)
		end
	end)
end

-- Stop the Torrential Downpour ability
function NuclearRain.StopTorrentialDownpour(standModel)
	print("Stopped downpour in module")
	local character = standModel.Parent
	if not character then
		return
	end

	activeDownpours[character] = nil

	-- Optionally stop any looping animation or sound here
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
	HitboxSpawner.spawnArcProjectile({
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
			CombatUtils.AddBarrier(
				character,
				trueDamage / RAINBARRIER_CONSTANT,
				RAINBARRIER_DECAY_RATE,
				RAINBARRIER_DECAY_DELAY,
				"RainBarrier",
				RAINBARRIER_MAX
			)
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

-- Initialize for existing and future players
Players.PlayerAdded:Connect(function(player)
	NuclearRain.initRainForPlayer(player)
end)

return NuclearRain
