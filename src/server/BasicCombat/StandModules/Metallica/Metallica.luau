local Metallica = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local StandUtils = require(ServerScriptService.BasicCombat.StandUtils)
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))

local RAIN_REGEN = 1
local REGEN_INTERVAL = 1

local MagneticAura_DAMAGE = 0
local MagneticAura_SIZE = Vector3.new(45, 30, 45)
local MagneticAura_OFFSET = Vector3.new(0, 0, 0)
local MagneticAura_ENDLAG = 0.5
local MagneticAura_INTERVAL = 0.75
local MagneticAura_COST = 3

local ScalpelDaggers_DAMAGE = 25
local ScalpelDaggers_DURATION = 25
local ScalpelDaggers_SIZE = Vector3.new(10, 10, 10)
local ScalpelDaggers_SPEED = 100
local ScalpelDaggers_STUN = 1.4

local RAINBARRIER_CONSTANT = 3 --damage taken / RAINBARRIER_CONSTANT amount of barrier
local RAINBARRIER_DECAY_RATE = 0.1
local RAINBARRIER_DECAY_DELAY = 12
local RAINBARRIER_MAX = 50

local ERASE_ANIM_ID = 90498591949232

local HIT_SOUND_ID = 8255306220

-- State tracking
local activeMagneticAura = {} -- [character] = true while active
local activeMagnets = {}

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

function Metallica.ApplyMagnetStack(humanoid, damagePerTick, tickInterval, duration, sourcePlayer)
	print("burn applied")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	-- ensure table exists
	if not activeMagnets[humanoid] then
		activeMagnets[humanoid] = {}
	end

	local stackID = makeStackKey()
	local totalTicks = math.max(1, math.floor(duration / tickInterval))

	activeMagnets[humanoid][stackID] = {
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
			local stack = activeMagnets[humanoid] and activeMagnets[humanoid][stackID]

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

			-- increment tick
			stack.tickCount += 1

			task.wait(stack.tickInterval)
		end

		-- cleanup stack
		if activeMagnets[humanoid] then
			activeMagnets[humanoid][stackID] = nil
			if next(activeMagnets[humanoid]) == nil then
				activeMagnets[humanoid] = nil
			end
		end
	end)
end

-- ✅ Reset a humanoid’s burn stacks back to full duration
function Metallica.ResetBurns(humanoid)
	print("Burn reset called")
	local burns = activeMagnets[humanoid]
	if not burns then
		return
	end

	for _, stack in pairs(burns) do
		stack.tickCount = 0
		stack.totalTicks = math.max(1, math.floor(stack.duration / stack.tickInterval))
	end
end

-- Optional: helper to clear all burns on a humanoid completely
function Metallica.ClearAllMagnets(humanoid)
	if not humanoid then
		return
	end
	local list = activeMagnets[humanoid]
	if not list then
		return
	end
	for stackID, stack in pairs(list) do
		stack.alive = false
		activeMagnets[humanoid][stackID] = nil
	end
	activeMagnets[humanoid] = nil
end

-- Start the Torrential Downpour ability
function Metallica.StartMagneticAura(standModel)
	print("Started downpour in module")
	local character = standModel.Parent
	if not character or activeMagneticAura[character] then
		return -- already active or invalid
	end
	activeMagneticAura[character] = true

	-- sound
	CombatUtils.SetActionInProgress(character, MagneticAura_ENDLAG)

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "MagneticAuraEffect",
		soundID = "4961240438",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	-- Continuous hitbox + drain loop
	task.spawn(function()
		while activeMagneticAura[character] do
			-- Spawn the hitbox
			HitboxSpawner.spawnHitbox({
				Character = character,
				Damage = MagneticAura_DAMAGE,
				Size = MagneticAura_SIZE,
				Offset = CFrame.new(MagneticAura_OFFSET),
				Color = BrickColor.new("Bright red"),
				Duration = 0.75,
				Transparency = 0.7,
				Name = "MagneticAuraHitbox",
				Shape = Enum.PartType.Cylinder,
				Rotation = CFrame.Angles(0, 0, math.rad(90)),

				OnHit = function(target, trueDamage)
					print("💥 Metallica hit " .. target.Name .. " for " .. trueDamage .. " damage!")
				end,
			})

			task.wait(MagneticAura_INTERVAL)
		end
	end)
end

-- Stop the Torrential Downpour ability
function Metallica.StopMagneticAura(standModel)
	print("Stopped downpour in module")
	local character = standModel.Parent
	if not character then
		return
	end

	activeMagneticAura[character] = nil

	-- Optionally stop any looping animation or sound here
end

function Metallica.ScalpelDaggers(character)
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
		warn("No target point found for ScalpelDaggers")
		return false
	end

	-- Spawn position: directly above the target point (like a drop from the sky)
	local spawnHeight = 50 -- adjust for how high above you want the drop to start
	local spawnPos = targetPoint + Vector3.new(0, spawnHeight, 0)

	-- Direction: straight down
	local direction = Vector3.new(0, -1, 0)

	-- Create the projectile
	HitboxSpawner.spawnArcProjectile({
		Character = character,
		Size = ScalpelDaggers_SIZE,
		Damage = ScalpelDaggers_DAMAGE,
		Duration = ScalpelDaggers_DURATION,
		Speed = ScalpelDaggers_SPEED,
		Direction = direction,
		Origin = spawnPos,
		Color = BrickColor.new("Bright yellow"),
		Gravity = Vector3.new(0, -workspace.Gravity * 0.3, 0), -- full gravity
		CanBlock = false,
		Shape = Enum.PartType.Ball,
		Rotation = CFrame.Angles(0, 0, 0),
		StunDuration = ScalpelDaggers_STUN,

		OnHit = function(target, trueDamage)
			print("💥 Metallica hit " .. target.Name .. " for " .. trueDamage .. " damage!")
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

	-- Optional: add sound or visual effect at the spawn position
	-- SoundModule.PlaySound({ Root = hrp, soundID = "YOUR_SOUND_ID_HERE", volume = 1, range = 120 })

	return true
end

return Metallica
