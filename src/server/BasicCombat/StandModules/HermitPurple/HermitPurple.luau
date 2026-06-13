local HermitPurpleModule = {}

local combatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local standUitls = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local PilotModule = require(game.ServerScriptService.BasicCombat:WaitForChild("PilotModule"))
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local hitboxSpawner = require(game.ServerScriptService.BasicCombat:WaitForChild("HitboxSpawner"))
local SoundUtils = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))

local originalC0s = {}
local grappleStates = {}
-- [character] = {
--     attached = true,
--     attachPoint = Vector3,
--     rope = constraint,
--     hookPart = part
-- }

local MAX_SPLASH_DURATION = 3 -- seconds
local SPLASH_INTERVAL = 0.1
local EMERALD_HITBOX_SIZE = Vector3.new(3, 3, 3)
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
local RunService = game:GetService("RunService")

local SpawnClientVfx = Instance.new("RemoteEvent")
SpawnClientVfx.Name = "SpawnVfx"
SpawnClientVfx.Parent = ReplicatedStorage.Shared.Events

local function FireEmerald(player, origin, direction)
	SpawnClientVfx:FireAllClients({
		type = "Projectile",
		effectName = "Emerald",
		origin = origin,
		direction = direction,
		speed = EMERALD_SPLASH_SPEED,
		lifetime = EMERALD_DURATION,
	})
end

local function SpawnBarrierVfx(origin, startingSize, maxSize, life)
	SpawnClientVfx:FireAllClients({
		type = "Stationary",
		effectName = "EmeraldBarrier",

		-- Position
		cframe = CFrame.new(origin),

		-- Lifetime
		lifetime = life,

		-- Visual style
		scale = startingSize, -- starting size

		-- Optional flags for client expansion logic
		expand = true,
		expandRate = 100,
		maxScale = maxSize,
	})
end

local CooldownUpdateEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("BasicCombat")
	:WaitForChild("UI")
	:WaitForChild("CooldownUpdateEvent")

-- Example cooldown trigger
local function startCooldown(player, abilityNumber, cooldownDuration)
	CooldownUpdateEvent:FireClient(player, abilityNumber, cooldownDuration)
end

function HermitPurpleModule.StartGrapple(character)
	print("Grapple started")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		return
	end

	if grappleStates[character] then
		return
	end

	local actionFlag = combatUtils.GetActionInProgress(character)
	if actionFlag then
		return
	end
	combatUtils.SetActionInProgress(character, 10)

	-- 🔍 Raycast
	local result = RaycastModule.RaycastFromCamera(character, 150)
	if not result then
		combatUtils.ResetActionInProgress(character)
		return
	end

	print("pass 1")

	-- Prevent grappling flat ground
	if result.Normal.Y > 0.8 then
		combatUtils.ResetActionInProgress(character)
		return
	end

	print("pass 2")

	local attachPoint = result.Position

	-- 🪝 Hook Part (visual anchor)
	local hook = Instance.new("Part")
	hook.Size = Vector3.new(0.5, 0.5, 0.5)
	hook.Anchored = true
	hook.CanCollide = false
	hook.Position = attachPoint
	hook.Transparency = 1
	hook.Parent = workspace

	-- 🔗 Attachments
	local att0 = Instance.new("Attachment")
	att0.Parent = hrp

	local att1 = Instance.new("Attachment")
	att1.Parent = hook

	-- 🪢 Rope
	local rope = Instance.new("RopeConstraint")
	rope.Attachment0 = att0
	rope.Attachment1 = att1
	rope.Length = (attachPoint - hrp.Position).Magnitude
	rope.Visible = true
	rope.Thickness = 0.2
	rope.Parent = hrp

	-- 💨 Swing Force
	local vectorForce = Instance.new("VectorForce")
	vectorForce.Attachment0 = att0
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vectorForce.Force = Vector3.zero
	vectorForce.Parent = hrp

	-- Disable auto rotate for smoother control
	humanoid.AutoRotate = false

	-- 💾 Save state
	grappleStates[character] = {
		rope = rope,
		hook = hook,
		force = vectorForce,
		attachment = att0,
	}

	-- 🌪️ SWING LOOP (THIS IS THE IMPORTANT PART)
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not grappleStates[character] then
			connection:Disconnect()
			return
		end

		local state = grappleStates[character]

		local pos = hrp.Position
		local toHook = (attachPoint - pos)
		local distance = toHook.Magnitude

		if distance < 2 then
			return
		end

		local dir = toHook.Unit

		-- 🔥 KEY: Tangential velocity (creates swing arc)
		local velocity = hrp.AssemblyLinearVelocity

		-- Remove radial component → leaves tangential motion
		local radial = dir * velocity:Dot(dir)
		local tangential = velocity - radial

		-- 🎯 Pull toward rope length (like tension)
		local tensionStrength = 4000
		local tensionForce = dir * (distance - rope.Length) * tensionStrength

		-- 🌀 Swing boost (keeps motion going)
		local swingBoost = tangential * 80

		-- ⬆️ Small upward assist (feels better)
		local lift = Vector3.new(0, 600, 0)

		state.force.Force = tensionForce + swingBoost + lift
	end)

	return true
end

function HermitPurpleModule.StopGrapple(character)
	local state = grappleStates[character]
	if not state then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = true
	end

	if state.rope then
		state.rope:Destroy()
	end
	if state.hook then
		state.hook:Destroy()
	end
	if state.force then
		state.force:Destroy()
	end
	if state.attachment then
		state.attachment:Destroy()
	end

	grappleStates[character] = nil

	combatUtils.ResetActionInProgress(character)

	local player = Players:GetPlayerFromCharacter(character)
	if player then
		startCooldown(player, 2, 6)
	end

	return true
end

function HermitPurpleModule.ActivateBarrier(standModel)
	print("barrier activated on server!")

	local character = standModel.Parent
	local hitBoxOffset = CFrame.new(0, 0, 0)
	local hrp = character:FindFirstChild("HumanoidRootPart")

	local placement_position = hrp.CFrame
	if PilotModule.GetBoolPilotMode(character) then
		placement_position = standModel.PrimaryPart.CFrame
	end

	local slowingField = hitboxSpawner.SpawnStationarySlowingField({
		StandModel = standModel,
		Size = BARRIER_SIZE,
		Duration = BARRIER_DURATION,
		SlowFactor = 0.6,
		Offset = hitBoxOffset,
		Caster = character,
		Position = placement_position,
		Transparency = 1,
	})

	SoundUtils.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "EmeraldBarrierCall",
		soundID = "125158491947057",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	SpawnBarrierVfx(slowingField.Position, 0.3, 1, BARRIER_DURATION)

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
		Transparency = 1,
		Name = "BarragePunchHitbox",
	})
end

function HermitPurpleModule.PuppetMaster(standModel)
	local character = standModel.Parent

	local PUPPETMASTER_OFFSET = Vector3.new(2, 0, -8)
	local animID = PUPPETMASTER_ANIM_ID
	if PilotModule.GetBoolPilotMode(character) then
		animID = PUPPETMASTER_PILOT_ANIM_ID
		PUPPETMASTER_OFFSET = Vector3.new(0, 0, -5)
	end

	AnimationModule.PlayAnimationThenIdle(standModel, animID, false, Enum.AnimationPriority.Action, 1)
	combatUtils.SetActionInProgress(character, PUPPETMASTER_ENDLAG)

	SoundUtils.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "PuppetMasterEffect",
		soundID = "74238153433253",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	SoundUtils.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "PuppetMasterCall",
		soundID = "6191516032",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
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

function HermitPurpleModule.TwentyMeterBarrier(standModel)
	print("barrier activated on server!")

	local character = standModel.Parent
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local hitBoxOffset = Vector3.new(0, 0, 0)

	local placement_position = hrp.CFrame
	if PilotModule.GetBoolPilotMode(character) then
		placement_position = standModel.PrimaryPart.CFrame
	end

	-- Spawn the slowing field (lasts full duration)
	local slowingField = hitboxSpawner.SpawnStationarySlowingField({
		StandModel = standModel,
		Size = TWENTY_METER_BARRIER_SIZE,
		Duration = TWENTY_METER_BARRIER_DURATION,
		SlowFactor = 0.6,
		Offset = hitBoxOffset,
		Caster = character,
		Position = placement_position,
		Transparency = 1,
	})

	SpawnBarrierVfx(slowingField.Position, 1, 2, TWENTY_METER_BARRIER_DURATION)

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

				StatScaling = {
					Power = 0.5,
				},

				Size = TWENTY_METER_BARRIER_SIZE,
				Offset = hitBoxOffset,
				Color = BrickColor.new("Bright red"),
				Duration = 1,
				StunDuration = TWENTY_METER_BARRIER_STUN,
				Transparency = 1,
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
	})
end

return HermitPurpleModule
