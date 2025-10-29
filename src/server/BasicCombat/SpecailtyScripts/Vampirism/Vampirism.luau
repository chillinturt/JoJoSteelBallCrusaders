-- ServerScriptService/VampirismModule.lua
local VampirismModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local HitboxSpawner = require(game.ServerScriptService.BasicCombat.HitboxSpawner)
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))

-- CONFIGURATION
local MAX_BLOOD = 100
local DRAIN_RATE = 2.5 -- units per second

-- Internal tracking
local chargingFlags = {} -- [character] = true/false
local activeBloodValues = {} -- [character] = NumberValue

local DIVINE_DRINK_ANIM_ID = 136847469830162
local DIVINE_DRINK_ENDLAG = 1
local DIVINE_DRINK_DAMAGE = 25
local DIVINE_DRINK_SIZE = Vector3.new(7, 16, 10)
local DIVINE_DRINK_OFFSET = Vector3.new(0, 4, -2)
local DIVINE_DRINK_BLOOD = 40
local DIVINE_DRINK_STUN = 1
local DIVINE_DRINK_DURATION = 1

local sunlightYellowFlags = {}
local MAX_SUNLIGHT_YELLOW_DURATION = 5 -- seconds
local SUNLIGHT_YELLOW_DAMAGE = 1
local SUNLIGHT_YELLOW_SIZE = Vector3.new(7, 8, 9)
local SUNLIGHT_YELLOW_INTERVAL = 0.15
local SUNLIGHT_YELLOW_ANIM_ID = 127837357946102
local SUNLIGHT_YELLOW_COST = 1

local BUBBLECUTTER_ENDLAG = 1
local BUBBLECUTTER_DAMAGE = 9
local BUBBLECUTTER_SIZE = Vector3.new(12, 6, 10)
local BUBBLECUTTER_OFFSET = Vector3.new(0, 4, -2)
local BUBBLECUTTER_COST = 10
local BUBBLECUTTER_STUN = 0
local BUBBLECUTTER_SHOT_COUNT = 3
local BUBBLECUTTER_DELAY = 0.15 -- seconds between each shot

local LIFEFORCEAURA_ENDLAG = 1
local LIFEFORCEAURA_SIZE = Vector3.new(12, 10, 12)
local LIFEFORCEAURA_OFFSET = Vector3.new(0, 0, 0)
local LIFEFORCEAURA_COST = 20
local LIFEFORCEAURA_STUN = 0.5
local LIFEFORCEAURA_ANIMID = 136847469830162
local LIFEFORCEAURA_DAMAGE = 10
local LIFEFORCEAURA_DURATION = 1
local LIFEFORCEAURA_HEAL = 40

-- Utility: get or create BloodMeter NumberValue
function VampirismModule.getBloodValue(character)
	if not character then
		return
	end
	local val = character:FindFirstChild("BloodMeter")
	if not val then
		val = Instance.new("NumberValue")
		val.Name = "BloodMeter"
		val.Value = 0
		val.Parent = character
	end
	return val
end

local function spendBlood(character, cost)
	if not character or typeof(cost) ~= "number" then
		return false -- invalid input
	end

	local bloodVal = VampirismModule.getBloodValue(character)
	if not bloodVal then
		return false
	end

	-- Check if the player has enough Blood
	if bloodVal.Value >= cost then
		bloodVal.Value -= cost
		return true -- success
	else
		return false -- not enough Blood
	end
end

local function addBlood(character, amount)
	print("add blood function called")
	if not character or typeof(amount) ~= "number" then
		print("Invalid arguments in add blood")
		return false -- invalid input
	end

	local bloodVal = VampirismModule.getBloodValue(character)
	if not bloodVal then
		print("cannot get blood value")
		return false
	end

	-- Add blood, but don't exceed MAX_BLOOD
	local newValue = math.min(bloodVal.Value + amount, MAX_BLOOD)
	bloodVal.Value = newValue

	return true -- success
end

function VampirismModule.DivineDrink(character)
	AnimationModule.PlayAnimation(character, DIVINE_DRINK_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, DIVINE_DRINK_ENDLAG)

	local hrp = character:FindFirstChild("HumanoidRootPart")

	HitboxSpawner.spawnStandOffHitbox({
		Character = character,
		Damage = DIVINE_DRINK_DAMAGE,
		Size = DIVINE_DRINK_SIZE,
		Offset = CFrame.new(DIVINE_DRINK_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = DIVINE_DRINK_DURATION,
		StunDuration = DIVINE_DRINK_STUN,
		Transparency = 0.3,
		Name = "DivineDrinkHitbox",
		CanBlock = false, -- ✅ Unblockable
		OnHit = function(targetChar, humanoid)
			print(character.Name .. " drained " .. targetChar.Name .. " successfully!")
			addBlood(character, DIVINE_DRINK_BLOOD)
		end,
	})

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "DivineDrinkCall",
		soundID = "8291662851",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "DivineDrinkEffect",
		soundID = "4403634269",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})
end

function VampirismModule.BubbleCutter(character)
	if not spendBlood(character, BUBBLECUTTER_COST) then
		return
	end

	AnimationModule.PlayAnimation(character, DIVINE_DRINK_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, BUBBLECUTTER_ENDLAG)

	local hrp = character:FindFirstChild("HumanoidRootPart")

	--// Function to fire 3 projectiles in sequence
	task.spawn(function()
		for i = 1, BUBBLECUTTER_SHOT_COUNT do
			HitboxSpawner.spawnProjectile({
				Character = character,
				Damage = BUBBLECUTTER_DAMAGE or 0.1,
				Size = BUBBLECUTTER_SIZE,
				Offset = BUBBLECUTTER_OFFSET,
				Color = BrickColor.new("Bright red"),
				Duration = 1.5,
				StunDuration = BUBBLECUTTER_STUN,
				Transparency = 0.3,
				Name = "Bubble Cutter Hitbox",
				Speed = 250,
			})
			if i < BUBBLECUTTER_SHOT_COUNT then
				task.wait(BUBBLECUTTER_DELAY)
			end
		end
	end)

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "BubbleCutterCall",
		soundID = "6149095382",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "BubbleCutterEffect",
		soundID = "9125644905",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})
end

function VampirismModule.LifeForceAura(character)
	if not spendBlood(character, LIFEFORCEAURA_COST) then
		return
	end

	AnimationModule.PlayAnimation(character, LIFEFORCEAURA_ANIMID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, LIFEFORCEAURA_ENDLAG)

	HitboxSpawner.spawnStandOffHitbox({
		Character = character,
		Damage = LIFEFORCEAURA_DAMAGE or 0.1,
		Size = LIFEFORCEAURA_SIZE,
		Offset = CFrame.new(LIFEFORCEAURA_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = LIFEFORCEAURA_DURATION,
		StunDuration = LIFEFORCEAURA_STUN,
		Transparency = 0.3,
		Name = "Zoom Punch Hitbox",
		Heal = LIFEFORCEAURA_HEAL,
	})

	local humanoid = character:FindFirstChild("Humanoid")
	local newHealth = math.min(humanoid.Health + LIFEFORCEAURA_HEAL / 3, humanoid.MaxHealth)
	humanoid.Health = newHealth
end

function VampirismModule.initHamonForPlayer(player)
	-- When the character spawns, ensure it has a HamonMeter
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid") -- wait until the character is fully loaded
		VampirismModule.getBloodValue(character)
	end)
end

Players.PlayerAdded:Connect(function(player)
	VampirismModule.initHamonForPlayer(player)
end)

-- Constant drain when not charging
RunService.Heartbeat:Connect(function(dt)
	for char, bloodVal in pairs(activeBloodValues) do
		if char and char.Parent and not chargingFlags[char] then
			bloodVal.Value = math.clamp(bloodVal.Value - DRAIN_RATE * dt, 0, MAX_BLOOD)
		end
	end
end)

-- Cleanup when character despawns
Players.PlayerRemoving:Connect(function(player)
	local char = player.Character
	if char then
		chargingFlags[char] = nil
		activeBloodValues[char] = nil
	end
end)

return VampirismModule
