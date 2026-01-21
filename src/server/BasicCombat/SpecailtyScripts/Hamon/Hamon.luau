-- ServerScriptService/HamonModule.lua
local HamonModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local HeroManager = require(ServerScriptService.DataSaving.HeroManager)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
local ZOOM_PUNCH_ENDLAG = 0.8
local ZOOM_PUNCH_DAMAGE = 15
local ZOOM_PUNCH_SIZE = Vector3.new(7, 16, 10)
local ZOOM_PUNCH_OFFSET = Vector3.new(0, 4, -2)
local ZOOM_PUNCH_COST = 20
local ZOOM_PUNCH_STUN = 1.4
local ZOOM_PUNCH_DURATION = 1

local sunlightYellowFlags = {}
local MAX_SUNLIGHT_YELLOW_DURATION = 5 -- seconds
local SUNLIGHT_YELLOW_DAMAGE = 0.7
local SUNLIGHT_YELLOW_SIZE = Vector3.new(7, 8, 14)
local SUNLIGHT_YELLOW_INTERVAL = 0.15
local SUNLIGHT_YELLOW_ANIM_ID = 127837357946102
local SUNLIGHT_YELLOW_COST = 2

local BUBBLECUTTER_ENDLAG = 1
local BUBBLECUTTER_DAMAGE = 6
local BUBBLECUTTER_SIZE = Vector3.new(12, 6, 10)
local BUBBLECUTTER_OFFSET = Vector3.new(0, 4, -2)
local BUBBLECUTTER_COST = 10
local BUBBLECUTTER_STUN = 0
local BUBBLECUTTER_SHOT_COUNT = 3
local BUBBLECUTTER_DELAY = 0.15 -- seconds between each shot
local BUBBLECUTTER_SPEED = 250
local BUBBLECUTTER_DURATION = 1.5

local LIFEFORCEAURA_ENDLAG = 1
local LIFEFORCEAURA_SIZE = Vector3.new(12, 10, 12)
local LIFEFORCEAURA_OFFSET = Vector3.new(0, 0, 0)
local LIFEFORCEAURA_COST = 35
local LIFEFORCEAURA_STUN = 1
local LIFEFORCEAURA_ANIMID = 136847469830162
local LIFEFORCEAURA_DAMAGE = 10
local LIFEFORCEAURA_DURATION = 1
local LIFEFORCEAURA_HEAL = 40

local SpawnClientVfx = ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")
local HamonUpdated = ReplicatedStorage.UIs.RemoteEvents:WaitForChild("HamonUpdated")

print("Hamon module required")

-- Utility: get or create HamonMeter NumberValue
function HamonModule.GetHamon(character)
	return hamonByCharacter[character] or 0
end

function HamonModule.SetHamon(character, value)
	hamonByCharacter[character] = math.clamp(value, 0, MAX_HAMON)

	local player = Players:GetPlayerFromCharacter(character)
	if player then
		HamonUpdated:FireClient(player, hamonByCharacter[character], MAX_HAMON)
	end
end

function HamonModule.SpendHamon(character, cost)
	if not character or typeof(cost) ~= "number" then
		return false
	end

	local current = hamonByCharacter[character] or 0
	if current < cost then
		return false
	end

	hamonByCharacter[character] = current - cost

	local player = Players:GetPlayerFromCharacter(character)
	if player then
		HamonUpdated:FireClient(player, hamonByCharacter[character], MAX_HAMON)
	end

	return true
end

function HamonModule.ZoomPunch(character)
	if not HamonModule.SpendHamon(character, ZOOM_PUNCH_COST) then
		return
	end

	AnimationModule.PlayAnimation(character, ZOOM_PUNCH_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, ZOOM_PUNCH_ENDLAG)

	local hrp = character:FindFirstChild("HumanoidRootPart")

	HitboxSpawner.spawnStandOffHitbox({
		Character = character,
		Damage = ZOOM_PUNCH_DAMAGE or 0.1,
		Size = ZOOM_PUNCH_SIZE,
		Offset = CFrame.new(ZOOM_PUNCH_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = ZOOM_PUNCH_DURATION,
		StunDuration = ZOOM_PUNCH_STUN,
		Transparency = 1,
		Name = "StandardHitbox",
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
	local isBlocking = CombatUtils.IsBlocking(character)
	if isBlocking then
		return
	end

	local actionFlag = CombatUtils.GetActionInProgress(character)
	if actionFlag then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local AnimSpeed = 2
	local hitBoxOffset = CFrame.new(0, 0, -2)

	-- Stop idle and play SunlightYellow animation
	AnimationModule.StopAllAnimations(character)
	AnimationModule.PlayAnimation(character, SUNLIGHT_YELLOW_ANIM_ID, true, Enum.AnimationPriority.Action, AnimSpeed)

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
			if not HamonModule.SpendHamon(character, SUNLIGHT_YELLOW_COST) then
				HamonModule.StopSunlightYellow(character)
				return
			end

			HitboxSpawner.spawnStandOffHitbox({
				Character = character,
				Damage = SUNLIGHT_YELLOW_DAMAGE or 0.1,
				Size = SUNLIGHT_YELLOW_SIZE,
				Offset = hitBoxOffset,
				Color = BrickColor.new("Bright red"),
				Duration = 0.4,
				StunDuration = 0.4,
				Transparency = 1,
				Name = "SunlightYellowPunchHitbox",
				CanBlock = false,
			})
			task.wait(SUNLIGHT_YELLOW_INTERVAL)
		end
	end)

	return true
end

function HamonModule.StopSunlightYellow(character)
	sunlightYellowFlags[character] = false

	CombatUtils.ResetActionInProgress(character)

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
	if not HamonModule.SpendHamon(character, BUBBLECUTTER_COST) then
		return
	end

	AnimationModule.PlayAnimation(character, ZOOM_PUNCH_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, BUBBLECUTTER_ENDLAG)

	local hrp = character:FindFirstChild("HumanoidRootPart")

	--// Function to fire 3 projectiles in sequence
	task.spawn(function()
		for i = 1, BUBBLECUTTER_SHOT_COUNT do
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

			HitboxSpawner.spawnProjectile({
				Character = character,
				Damage = BUBBLECUTTER_DAMAGE or 0.1,
				Size = BUBBLECUTTER_SIZE,
				Offset = BUBBLECUTTER_OFFSET,
				Color = BrickColor.new("Bright red"),
				Duration = BUBBLECUTTER_DURATION,
				StunDuration = BUBBLECUTTER_STUN,
				Transparency = 1,
				Name = "Bubble Cutter Hitbox",
				Speed = BUBBLECUTTER_SPEED,
				Direction = direction,
				Origin = startPos,
				CanBlock = false,
			})

			SpawnClientVfx:FireAllClients({
				type = "Projectile",
				effectName = "BubbleCutter",
				origin = startPos,
				direction = direction,
				speed = BUBBLECUTTER_SPEED,
				lifetime = BUBBLECUTTER_DURATION,
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
	if not HamonModule.SpendHamon(character, LIFEFORCEAURA_COST) then
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

local function initCharacter(player, character)
	hamonByCharacter[character] = 0
	HamonUpdated:FireClient(player, 0, MAX_HAMON)
end

local function initPlayer(player)
	-- Handle current character
	if player.Character then
		initCharacter(player, player.Character)
	end

	-- Handle future spawns
	player.CharacterAdded:Connect(function(character)
		initCharacter(player, character)
	end)

	player.CharacterRemoving:Connect(function(character)
		hamonByCharacter[character] = nil
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	initPlayer(player)
end

function HamonModule.initHamonForPlayer(player)
	player.CharacterAdded:Connect(function(character)
		hamonByCharacter[character] = 0
		HamonUpdated:FireClient(player, hamonByCharacter[character], MAX_HAMON)
	end)
end

local function cleanupCharacter(character)
	hamonByCharacter[character] = nil
end

-- Handle future players
Players.PlayerAdded:Connect(initPlayer)

--[[
Players.PlayerAdded:Connect(function(player)
	-- Initialize already-connected players (CRITICAL)
	for _, player in ipairs(Players:GetPlayers()) do
		HamonModule.initHamonForPlayer(player)
		player.CharacterRemoving:Connect(cleanupCharacter)

		if player.Character then
			hamonByCharacter[player.Character] = 0
			HamonUpdated:FireClient(player, 0, MAX_HAMON)
		end
	end

	HamonModule.initHamonForPlayer(player)
	player.CharacterRemoving:Connect(cleanupCharacter)
end)
]]

-- Constant drain when not charging
RunService.Heartbeat:Connect(function(dt)
	for character, value in pairs(hamonByCharacter) do
		if not (character and character.Parent) then
			hamonByCharacter[character] = nil
			continue
		end

		-- Passive regeneration
		local newValue = math.clamp(value + CHARGE_RATE * dt, 0, MAX_HAMON)

		if newValue ~= value then
			hamonByCharacter[character] = newValue
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				HamonUpdated:FireClient(player, hamonByCharacter[character], MAX_HAMON)
			end
		end
	end
end)

-- Cleanup when character despawns
Players.PlayerRemoving:Connect(function(player)
	if player.Character then
		cleanupCharacter(player.Character)
	end
end)

return HamonModule
