-- ServerScriptService/FengShuiModule.lua
local FengShuiModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local SoundUtils = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local HitboxSpawner = require(game.ServerScriptService.BasicCombat.HitboxSpawner)
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))

-- CONFIGURATION
local MAX_HAMON = 100
local CHARGE_RATE = 5 -- units per second
local UPDATE_INTERVAL = 0.1 -- seconds

-- Internal tracking
local hamonByCharacter = {} -- [character] = number

local ZOOM_PUNCH_ANIM_ID = 136847469830162
local ZOOM_PUNCH_ENDLAG = 0.5
local ZOOM_PUNCH_DAMAGE = 15
local ZOOM_PUNCH_SIZE = Vector3.new(7, 16, 10)
local ZOOM_PUNCH_OFFSET = Vector3.new(0, 4, -2)
local ZOOM_PUNCH_STUN = 1.4
local ZOOM_PUNCH_DURATION = 1

local sunlightYellowFlags = {}
local MAX_SUNLIGHT_YELLOW_DURATION = 5 -- seconds
local SUNLIGHT_YELLOW_DAMAGE = 0.7
local SUNLIGHT_YELLOW_SIZE = Vector3.new(7, 8, 14)
local SUNLIGHT_YELLOW_INTERVAL = 0.15
local SUNLIGHT_YELLOW_ANIM_ID = 127837357946102
local SUNLIGHT_YELLOW_COST = 2

local BUBBLECUTTER_ENDLAG = 0.5
local BUBBLECUTTER_DAMAGE = 6
local BUBBLECUTTER_SIZE = Vector3.new(12, 6, 10)
local BUBBLECUTTER_OFFSET = Vector3.new(0, 4, -2)
local BUBBLECUTTER_COST = 10
local BUBBLECUTTER_STUN = 0
local BUBBLECUTTER_SHOT_COUNT = 3
local BUBBLECUTTER_DELAY = 0.15 -- seconds between each shot
local BUBBLECUTTER_SPEED = 250
local BUBBLECUTTER_DURATION = 1.5

local RISINGFIST_ENDLAG = 0.5
local RISINGFIST_SIZE = Vector3.new(12, 10, 12)
local RISINGFIST_OFFSET = Vector3.new(0, 0, 0)
local RISINGFIST_STUN = 1
local RISINGFIST_ANIMID = 136847469830162
local RISINGFIST_DAMAGE = 10
local RISINGFIST_DURATION = 1
local RISINGFIST_HEAL = 40
local RISINGFIST_VELOCITY = 50
local RISINGFIST_KOCKBACK_DURATION = 0.2

local SpawnClientVfx = ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")

print("Hamon module required")

function FengShuiModule.FlowLikeWater(character)
	CombatUtils.SetActionInProgress(character, ZOOM_PUNCH_ENDLAG)

	local hrp = character:FindFirstChild("HumanoidRootPart")

	local player = Players:GetPlayerFromCharacter(character)
	if player then
		CombatUtils.StartSlide(player, true, 1.2)
	end

	local hitbox = HitboxSpawner.spawnStandOffHitbox({
		Character = character,
		Damage = ZOOM_PUNCH_DAMAGE or 0.1,
		Size = ZOOM_PUNCH_SIZE,
		Offset = CFrame.new(ZOOM_PUNCH_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = ZOOM_PUNCH_DURATION,
		StunDuration = ZOOM_PUNCH_STUN,
		Transparency = 0.6,
		Name = "StandardHitbox",
	})

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "FlowLikeWaterEffect",
		soundID = "9126047319",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	local vfxId = HttpService:GenerateGUID(false)
	hitbox:SetAttribute("VFX_ID", vfxId)

	SpawnClientVfx:FireAllClients({
		type = "Attached",
		effectName = "HamonAttack",
		attachId = vfxId,
		offset = CFrame.new(ZOOM_PUNCH_OFFSET),
		scale = ZOOM_PUNCH_SIZE,
		attachTo = hitbox,
	})
end

function FengShuiModule.StartSunlightYellow(character)
	local isBlocking = CombatUtils.IsBlocking(character)
	if isBlocking then
		return
	end

	local actionFlag = CombatUtils.GetActionInProgress(character)
	if actionFlag then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or sunlightYellowFlags[character] then
		return
	end
	CombatUtils.SetActionInProgress(character, MAX_SUNLIGHT_YELLOW_DURATION)

	sunlightYellowFlags[character] = {}

	local AnimSpeed = 2
	local hitBoxOffset = CFrame.new(0, 0, -2)

	-- Stop idle and play SunlightYellow animation
	AnimationModule.StopAllAnimations(character)
	AnimationModule.PlayAnimation(character, SUNLIGHT_YELLOW_ANIM_ID, true, Enum.AnimationPriority.Action, AnimSpeed)

	-- Auto-stop SunlightYellow after max duration
	task.delay(MAX_SUNLIGHT_YELLOW_DURATION, function()
		if sunlightYellowFlags[character] then
			FengShuiModule.StopSunlightYellow(character)
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
	})

	SoundUtils.PlaySound({
		Root = hrp,
		soundName = "SunlightYellowEffects",
		soundID = "129949908820890",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	local vfxRoot = HitboxSpawner.spawnStandOffHitbox({
		Character = character,
		Damage = 0,
		Size = Vector3.new(1, 1, 1),
		Offset = CFrame.new(0, 0, 0),
		Color = BrickColor.new("Bright red"),
		Duration = 30,
		Transparency = 0.6,
		Name = "TorrentialDownpourVfxRoot",
		RemoveOnStun = false,

		StatScaling = {
			Stregnth = 0,
		},
	})

	local vfxId = HttpService:GenerateGUID(false)
	vfxRoot:SetAttribute("VFX_ID", vfxId)

	-- Store references
	sunlightYellowFlags[character].vfxRoot = vfxRoot
	sunlightYellowFlags[character].vfxId = vfxId

	SpawnClientVfx:FireAllClients({
		type = "Attached",
		effectName = "HamonAttack",
		attachId = vfxId,
		offset = hitBoxOffset,
		attachTo = vfxRoot,
		scale = SUNLIGHT_YELLOW_SIZE,
	})

	-- Start spawning hitboxes
	task.spawn(function()
		while sunlightYellowFlags[character] do
			HitboxSpawner.spawnStandOffHitbox({
				Character = character,
				Damage = SUNLIGHT_YELLOW_DAMAGE or 0.1,

				StatScaling = {
					Strength = 0.2,
				},
				Size = SUNLIGHT_YELLOW_SIZE,
				Offset = hitBoxOffset,
				Color = BrickColor.new("Bright red"),
				Duration = 0.4,
				StunDuration = 0.4,
				Transparency = 0.6,
				Name = "SunlightYellowPunchHitbox",
				CanBlock = false,
				RemoveOnStun = false,
			})
			task.wait(SUNLIGHT_YELLOW_INTERVAL)
		end
	end)

	return true
end

function FengShuiModule.StopSunlightYellow(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local state = sunlightYellowFlags[character]
	if not state then
		print("no state")
		return
	end

	-- 🧨 Kill VFX root
	if state.vfxRoot and state.vfxRoot.Parent then
		state.vfxRoot:Destroy()
	end

	CombatUtils.ResetActionInProgress(character)

	-- Clear barrage flag
	sunlightYellowFlags[character] = nil
	CombatUtils.ResetActionInProgress(character)

	-- Reset animation
	AnimationModule.StopAllAnimations(character)

	SoundUtils.StopSound(hrp, "SunlightYellowEffects")
	SoundUtils.StopSound(hrp, "SunlightYellowCall")
	return true
end

function FengShuiModule.FlyLikeWind(character)
	AnimationModule.PlayAnimation(character, ZOOM_PUNCH_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, BUBBLECUTTER_ENDLAG)

	local hrp = character:FindFirstChild("HumanoidRootPart")

	CombatUtils.ApplyTurningVelocity({
		Character = character,
		Speed = 110,
		Duration = 0.8,
		Direction = Vector3.new(0, 0, -1),
		LockVertical = true,
	})

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "FlyLikeWindEffect",
		soundID = "9126048349",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})
end

function FengShuiModule.RisingFist(character)
	AnimationModule.PlayAnimation(character, RISINGFIST_ANIMID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, RISINGFIST_ENDLAG)

	local hitbox = HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = RISINGFIST_DAMAGE or 0.1,
		Size = RISINGFIST_SIZE,
		Offset = CFrame.new(RISINGFIST_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = 0.75,
		StunDuration = RISINGFIST_STUN,
		Transparency = 0.6,
		Name = "BlazingStrikeHitbox",
		CanBlock = false,

		OnHit = function(targetChar, newDamage)
			local hitHumanoid = targetChar:FindFirstChild("Humanoid")
			local targetRootPart = targetChar:FindFirstChild("HumanoidRootPart")
			local attackerRoot = character:FindFirstChild("HumanoidRootPart")

			if not (hitHumanoid and targetRootPart and attackerRoot) then
				return
			end

			CombatUtils.ApplyTimedVelocity(
				targetRootPart,
				RISINGFIST_VELOCITY,
				RISINGFIST_KOCKBACK_DURATION,
				"RisingFist",
				Vector3.new(0, 1, 0)
			)
		end,
	})

	local hrp = character:FindFirstChild("HumanoidRootPart")

	CombatUtils.ApplyTimedVelocity(
		hrp,
		RISINGFIST_VELOCITY,
		RISINGFIST_KOCKBACK_DURATION,
		"RisingFist",
		Vector3.new(0, 1, 0)
	)

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "RisingUppercutEffect",
		soundID = "9126046056",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	local humanoid = character:FindFirstChild("Humanoid")
	local newHealth = math.min(humanoid.Health + RISINGFIST_HEAL / 3, humanoid.MaxHealth)
	humanoid.Health = newHealth

	local vfxId = HttpService:GenerateGUID(false)
	hitbox:SetAttribute("VFX_ID", vfxId)

	SpawnClientVfx:FireAllClients({
		type = "Attached",
		effectName = "HamonAttack",
		attachId = vfxId,
		offset = CFrame.new(RISINGFIST_OFFSET),
		scale = RISINGFIST_SIZE,
		attachTo = hitbox,
	})
end

return FengShuiModule
