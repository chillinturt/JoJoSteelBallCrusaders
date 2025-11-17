local HierophantModule = {}

local combatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local standUitls = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local PilotModule = require(game.ServerScriptService.BasicCombat:WaitForChild("PilotModule"))
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local hitboxSpawner = require(game.ServerScriptService.BasicCombat:WaitForChild("HitboxSpawner"))
local SoundUtils = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))

local originalC0s = {}
local splashingFlags = {}

local MAX_SPLASH_DURATION = 3 -- seconds
local SPLASH_INTERVAL = 0.1
local EMERALD_HITBOX_SIZE = Vector3.new(2, 2, 2)
local EMERALD_DAMAGE = 0.8
local EMERALD_DURATION = 3
local EMERALD_SPLASH_SPEED = 300
local EMERALD_SPLASH_COOLDOWN = 10 -- the cooldown is kept track of in this module due to a glitch.
--When the player desummons their stand during emerald splash, the cooldown UI won't work unless I do it this way
local EMERALD_SPLASH_STUN = 0.5

local BARRIER_DURATION = 6
local BARRIER_SIZE = Vector3.new(24, 24, 24)
local BARRIER_DAMAGE_DELAY = 0.5
local BARRIER_DAMAGE = 20

local PUPPETMASTER_DAMAGE = 15
local PUPPETMASTER_ENDLAG = 1
local PUPPETMASTER_STUN = 2
local PUPPETMASTER_SIZE = Vector3.new(5, 6, 7)
local PUPPETMASTER_DURATION = 5
local PUPPETMASTER_ANIM_ID = 90498591949232
local PUPPETMASTER_PILOT_ANIM_ID = 136847469830162

local TWENTY_METER_BARRIER_DURATION = 8
local TWENTY_METER_BARRIER_SIZE = Vector3.new(50, 50, 50)
local TWENTY_METER_BARRIER_DAMAGE_DELAY = 1
local TWENTY_METER_BARRIER_DAMAGE = 10
local TWENTY_METER_BARRIER_STUN = 0

local IDLE_ANIM_ID = 89452205434139

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

function HierophantModule.StartSplash(character)
	local standModel = standUitls.getStandModel(character)
	local primaryParty = standModel.PrimaryPart
	if not primaryParty or not character then
		return false
	end
	local motor = primaryParty:FindFirstChild("StandMotor", true)

	local standTag = standModel:FindFirstChild("StandTag")
	if not standTag then
		return false
	end

	local actionFlag = combatUtils.GetActionInProgress(character)
	if actionFlag.Value then
		return
	end
	actionFlag.Value = true

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	-- Cache original motor position
	if not originalC0s[standModel] then
		originalC0s[standModel] = motor.C0
	end

	local STAND_BARRAGE_ANIMID = 103626308901658
	local AnimSpeed = 1.5
	local hitBoxOffset = Vector3.new(0, 0, 8)

	-- Shift forward for barrage
	if PilotModule.GetBoolPilotMode(character) then
		print("IN PILOT MODE!")

		STAND_BARRAGE_ANIMID = 127837357946102
		AnimSpeed = 2
		hitBoxOffset = Vector3.new(0, 0, 8)
	else
		print("barrage detects not in pilot mode")
		motor.C0 = originalC0s[standModel] * CFrame.new(2, 0, 0)
	end

	-- Stop idle and play barrage animation
	AnimationModule.StopAllAnimations(standModel)
	AnimationModule.PlayAnimation(standModel, STAND_BARRAGE_ANIMID, false, Enum.AnimationPriority.Action, AnimSpeed)

	-- Set barrage flag
	splashingFlags[character] = true

	-- Auto-stop barrage after max duration
	task.delay(MAX_SPLASH_DURATION, function()
		if splashingFlags[character] then
			HierophantModule.StopSplash(character)
		end
	end)

	SoundUtils.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "BarrageEffects",
		soundID = "129949908820890",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundUtils.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "EmeraldSplashCall",
		soundID = "5786101618",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	-- Start spawning hitboxes
	task.spawn(function()
		while splashingFlags[character] do
			-- this will help determiune the direction of the projectile
			local direction
			local startPos = hrp.Position
			local player = Players:GetPlayerFromCharacter(character)

			if player then
				if PilotModule.GetBoolPilotMode(character) then
					direction = standModel:GetPivot().LookVector
					startPos = standModel.PrimaryPart.Position
				else
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
				end
			else
				direction = hrp:GetPivot().LookVector
			end

			hitboxSpawner.spawnProjectile({
				Stand = standModel,
				Character = character,
				Damage = EMERALD_DAMAGE,
				Size = EMERALD_HITBOX_SIZE,
				Offset = hitBoxOffset,
				Color = BrickColor.new("Bright red"),
				Duration = EMERALD_DURATION,
				StunDuration = EMERALD_SPLASH_STUN,
				Transparency = 0.3,
				Name = "BarragePunchHitbox",
				Speed = EMERALD_SPLASH_SPEED,
				Direction = direction,
				Origin = startPos,
			})
			task.wait(SPLASH_INTERVAL)
		end
	end)

	local conn
	conn = standModel.AncestryChanged:Connect(function(_, parent)
		if not parent then -- stand got removed from workspace
			HierophantModule.StopSplash(character)
			if conn then
				conn:Disconnect()
			end
		end
	end)

	return true
end

function HierophantModule.StopSplash(character)
	local standModel = standUitls.getStandModel(character)

	local actionFlag = combatUtils.GetActionInProgress(character)
	local player = Players:GetPlayerFromCharacter(character)

	if player then
		startCooldown(player, 2, EMERALD_SPLASH_COOLDOWN) -- CD1, 8 seconds
	end
	splashingFlags[character] = nil

	if not standModel then
		actionFlag.Value = false
		return true
	end

	local motor = standModel:FindFirstChild("StandMotor", true)
	if motor and motor:IsA("Motor6D") and originalC0s[standModel] then
		motor.C0 = originalC0s[standModel]
	end

	if actionFlag then
		actionFlag.Value = false
	end

	-- Reset animation
	AnimationModule.StopAllAnimations(standModel)
	AnimationModule.PlayAnimation(standModel, IDLE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)

	-- Optional: clear cache if stand is despawned frequently
	originalC0s[standModel] = nil

	SoundUtils.StopSound(standModel.PrimaryPart, "BarrageEffects")
	return true
end

function HierophantModule.ActivateBarrier(standModel)
	print("barrier activated on server!")

	local character = standModel.Parent
	local hitBoxOffset = CFrame.new(0, 0, 0)
	local hrp = character:FindFirstChild("HumanoidRootPart")

	local placement_position = hrp.CFrame
	if PilotModule.GetBoolPilotMode(character) then
		placement_position = standModel.PrimaryPart.CFrame
	end

	hitboxSpawner.SpawnStationarySlowingField({
		StandModel = standModel,
		Size = BARRIER_SIZE,
		Duration = BARRIER_DURATION,
		SlowFactor = 0.6,
		Offset = hitBoxOffset,
		Caster = character,
		Position = placement_position,
	})

	task.wait(BARRIER_DAMAGE_DELAY)

	hitboxSpawner.spawnStationaryHitbox({
		Position = placement_position,
		Character = character,
		Damage = BARRIER_DAMAGE,
		Size = BARRIER_SIZE,
		Offset = hitBoxOffset,
		Color = BrickColor.new("Bright red"),
		Duration = 1,
		StunDuration = 2,
		Transparency = 0.3,
		Name = "BarragePunchHitbox",
	})
end

function HierophantModule.PuppetMaster(standModel)
	local character = standModel.Parent

	local PUPPETMASTER_OFFSET = Vector3.new(2, 0, -8)
	local animID = PUPPETMASTER_ANIM_ID
	if PilotModule.GetBoolPilotMode(character) then
		animID = PUPPETMASTER_PILOT_ANIM_ID
		PUPPETMASTER_OFFSET = Vector3.new(0, 0, -5)
	end

	AnimationModule.PlayAnimation(standModel, animID, false, Enum.AnimationPriority.Action, 1)
	combatUtils.SetActionInProgress(character, PUPPETMASTER_ENDLAG)

	SoundUtils.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "PuppetMasterEffect",
		soundID = "74238153433253",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundUtils.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "PuppetMasterCall",
		soundID = "6191516032",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	hitboxSpawner.spawnHitbox({
		Character = character,
		Damage = PUPPETMASTER_DAMAGE or 0.1,
		Size = PUPPETMASTER_SIZE,
		Offset = CFrame.new(PUPPETMASTER_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = 0.75,
		StunDuration = PUPPETMASTER_STUN,
		Transparency = 1,
		Name = "BasicPunchHitbox",
		CanBlock = false,
	})
end

function HierophantModule.TwentyMeterBarrier(standModel)
	print("barrier activated on server!")

	local character = standModel.Parent
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local hitBoxOffset = Vector3.new(0, 0, 0)

	local placement_position = hrp.CFrame
	if PilotModule.GetBoolPilotMode(character) then
		placement_position = standModel.PrimaryPart.CFrame
	end

	-- Spawn the slowing field (lasts full duration)
	hitboxSpawner.SpawnStationarySlowingField({
		StandModel = standModel,
		Size = TWENTY_METER_BARRIER_SIZE,
		Duration = TWENTY_METER_BARRIER_DURATION,
		SlowFactor = 0.6,
		Offset = hitBoxOffset,
		Caster = character,
		Position = placement_position,
	})

	-- Damage loop
	task.spawn(function()
		local startTime = tick()

		while tick() - startTime < TWENTY_METER_BARRIER_DURATION do
			-- Spawn a stationary damage hitbox
			hitboxSpawner.spawnStationaryHitbox({
				Position = placement_position,
				Stand = standModel,
				Character = character,
				Damage = TWENTY_METER_BARRIER_DAMAGE,
				Size = TWENTY_METER_BARRIER_SIZE,
				Offset = hitBoxOffset,
				Color = BrickColor.new("Bright red"),
				Duration = 1,
				StunDuration = TWENTY_METER_BARRIER_STUN,
				Transparency = 0.3,
				Name = "BarrierDamageHitbox",
			})

			-- Wait until next pulse
			task.wait(TWENTY_METER_BARRIER_DAMAGE_DELAY)
		end
	end)

	SoundUtils.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "TwentyMeterBarrierCall",
		soundID = "6995673021",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})
end

return HierophantModule
