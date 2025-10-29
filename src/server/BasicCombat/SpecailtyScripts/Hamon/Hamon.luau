-- ServerScriptService/HamonModule.lua
local HamonModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundUtils = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))

local HitboxSpawner = require(game.ServerScriptService.BasicCombat.HitboxSpawner)
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))

-- CONFIGURATION
local MAX_HAMON = 100
local CHARGE_RATE = 15 -- units per second
local DRAIN_RATE = 2.5 -- units per second
local UPDATE_INTERVAL = 0.1 -- seconds

-- Internal tracking
local chargingFlags = {} -- [character] = true/false
local activeHamonValues = {} -- [character] = NumberValue

local ZOOM_PUNCH_ANIM_ID = 136847469830162
local ZOOM_PUNCH_ENDLAG = 1
local ZOO_PUNCH_DAMAGE = 25
local ZOOM_PUNCH_SIZE = Vector3.new(7, 16, 10)
local ZOOM_PUNCH_OFFSET = Vector3.new(0, 4, -2)
local ZOOM_PUNCH_COST = 10
local ZOOM_PUNCH_STUN = 1
local ZOOM_PUNCH_DURATION = 1

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

-- Utility: get or create HamonMeter NumberValue
function HamonModule.getHamonValue(character)
	if not character then
		return
	end
	local val = character:FindFirstChild("HamonMeter")
	if not val then
		val = Instance.new("NumberValue")
		val.Name = "HamonMeter"
		val.Value = 0
		val.Parent = character
	end
	return val
end

local function spendHamon(character, cost)
	if not character or typeof(cost) ~= "number" then
		return false -- invalid input
	end

	local hamonVal = HamonModule.getHamonValue(character)
	if not hamonVal then
		return false
	end

	-- Check if the player has enough Hamon
	if hamonVal.Value >= cost then
		hamonVal.Value -= cost
		return true -- success
	else
		return false -- not enough Hamon
	end
end

-- Start or stop charging
function HamonModule.StartCharge(character)
	print("Hamon charge in module")
	if not character or not character.Parent then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	-- Prevent re-entry
	if chargingFlags[character] then
		-- Toggle off (stop charging)
		chargingFlags[character] = nil
		return
	end

	chargingFlags[character] = true

	local hamonValue = HamonModule.getHamonValue(character)
	activeHamonValues[character] = hamonValue

	-- Start charge loop
	task.spawn(function()
		while character.Parent and chargingFlags[character] do
			local dt = UPDATE_INTERVAL
			hamonValue.Value = math.clamp(hamonValue.Value + CHARGE_RATE * dt, 0, MAX_HAMON)
			task.wait(UPDATE_INTERVAL)
		end
	end)

	SoundUtils.PlaySound({
		Root = hrp,
		soundName = "ChargeHamon",
		soundID = "18421707745",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})
end

function HamonModule.StopCharge(character)
	-- Clear SunlightYellow flag
	chargingFlags[character] = nil
	print("Charging stopped in module")
end

function HamonModule.ZoomPunch(character)
	if not spendHamon(character, ZOOM_PUNCH_COST) then
		return
	end

	AnimationModule.PlayAnimation(character, ZOOM_PUNCH_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, ZOOM_PUNCH_ENDLAG)

	local hrp = character:FindFirstChild("HumanoidRootPart")

	HitboxSpawner.spawnStandOffHitbox({
		Character = character,
		Damage = ZOO_PUNCH_DAMAGE or 0.1,
		Size = ZOOM_PUNCH_SIZE,
		Offset = CFrame.new(ZOOM_PUNCH_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = ZOOM_PUNCH_DURATION,
		StunDuration = ZOOM_PUNCH_STUN,
		Transparency = 0.3,
		Name = "Zoom Punch Hitbox",
	})

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "ZoomPunchCall",
		soundID = "8291662851",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "ZoomPunchEffect",
		soundID = "4403634269",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})
end

function HamonModule.StartSunlightYellow(character)
	local isBlocking = CombatUtils.GetIsBlocking(character)
	if isBlocking.Value then
		return
	end

	local actionFlag = CombatUtils.GetActionInProgress(character)
	if not actionFlag then
		return
	end
	if actionFlag.Value then
		return
	end
	actionFlag.Value = true

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local AnimSpeed = 1.5
	local hitBoxOffset = CFrame.new(0, 0, -2)

	-- Stop idle and play SunlightYellow animation
	AnimationModule.StopAllAnimations(character)
	AnimationModule.PlayAnimation(character, SUNLIGHT_YELLOW_ANIM_ID, false, Enum.AnimationPriority.Action, AnimSpeed)

	-- Set SunlightYellow flag
	sunlightYellowFlags[character] = true

	-- Auto-stop SunlightYellow after max duration
	task.delay(MAX_SUNLIGHT_YELLOW_DURATION, function()
		if sunlightYellowFlags[character] then
			HamonModule.StopSunlightYellow(character)
		end
	end)

	--play sound
	SoundUtils.PlaySound({
		Root = hrp,
		soundName = "SunlightYellowCall",
		soundID = "5331665137",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundUtils.PlaySound({
		Root = hrp,
		soundName = "SunlightYellowEffects",
		soundID = "129949908820890",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	-- Start spawning hitboxes
	task.spawn(function()
		while sunlightYellowFlags[character] do
			if not spendHamon(character, SUNLIGHT_YELLOW_COST) then
				HamonModule.StopSunlightYellow(character)
				return
			end

			HitboxSpawner.spawnStandOffHitbox({
				Character = character,
				Damage = SUNLIGHT_YELLOW_DAMAGE or 0.1,
				Size = SUNLIGHT_YELLOW_SIZE,
				Offset = hitBoxOffset,
				Color = BrickColor.new("Bright red"),
				Duration = 0.1,
				StunDuration = 0.2,
				Transparency = 0.3,
				Name = "SunlightYellowPunchHitbox",
			})
			task.wait(SUNLIGHT_YELLOW_INTERVAL)
		end
	end)

	return true
end

function HamonModule.StopSunlightYellow(character)
	sunlightYellowFlags[character] = false

	local actionFlag = CombatUtils.GetActionInProgress(character)
	if actionFlag then
		actionFlag.Value = false
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	-- Clear barrage flag
	sunlightYellowFlags[character] = nil

	-- Reset animation
	AnimationModule.StopAllAnimations(character)

	SoundUtils.StopSound(hrp, "SunlightYellowEffects")
	SoundUtils.StopSound(hrp, "SunlightYellowCall")
	return true
end

function HamonModule.BubbleCutter(character)
	if not spendHamon(character, BUBBLECUTTER_COST) then
		return
	end

	AnimationModule.PlayAnimation(character, ZOOM_PUNCH_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
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

function HamonModule.LifeForceAura(character)
	if not spendHamon(character, LIFEFORCEAURA_COST) then
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

function HamonModule.initHamonForPlayer(player)
	-- When the character spawns, ensure it has a HamonMeter
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid") -- wait until the character is fully loaded
		HamonModule.getHamonValue(character)
	end)
end

Players.PlayerAdded:Connect(function(player)
	HamonModule.initHamonForPlayer(player)
end)

-- Constant drain when not charging
RunService.Heartbeat:Connect(function(dt)
	for char, hamonVal in pairs(activeHamonValues) do
		if char and char.Parent and not chargingFlags[char] then
			hamonVal.Value = math.clamp(hamonVal.Value - DRAIN_RATE * dt, 0, MAX_HAMON)
		end
	end
end)

-- Cleanup when character despawns
Players.PlayerRemoving:Connect(function(player)
	local char = player.Character
	if char then
		chargingFlags[char] = nil
		activeHamonValues[char] = nil
	end
end)

return HamonModule
