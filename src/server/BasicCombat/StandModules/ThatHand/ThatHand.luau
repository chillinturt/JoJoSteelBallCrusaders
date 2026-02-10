local ThatHand = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))

local ERASE_DAMAGE = 50
local ERASE_ENDLAG = 1
local ERASE_STUN = 1.7
local ERASE_SIZE = Vector3.new(5, 8, 9)
local ERASE_OFFSET = Vector3.new(2, 0, -8)

local ERASEVFX_OFFSET = Vector3.new(2, 0, -5)

local ERASE_ANIM_ID = 90498591949232

local VOID_SHIELDING_AMOUNT = 40
local VOID_SHIELDING_DECAY_RATE = 1
local VOID_SHIELDING_DECAY_DELAY = 1

local TEAR_SPACE_SPEED = 60
local TEAR_SPACE_DURATION = 2.5

local lastStandFlags = {}
local LAST_STAND_DURATION = 5
local LAST_STAND_INTERVAL = 0.6
local LAST_STAND_HITBOX_SIZE = Vector3.new(18, 14, 20)
local LAST_STAND_DAMAGE = 8
local LAST_STAND_HITBOX_DURATION = 1
local LAST_STAND_OFFSET = CFrame.new(2, 0, -12)

local SpawnClientVfx = ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")

local function SpawnStationaryEraseVfx(origin, startingSize, maxSize)
	SpawnClientVfx:FireAllClients({
		type = "Stationary",
		effectName = "ThatHandEraseStationary",

		-- Position
		cframe = CFrame.new(origin),

		-- Lifetime
		lifetime = 0.75,

		-- Visual style
		transparency = 0.5,
		scale = startingSize, -- starting size

		-- Optional flags for client expansion logic
		expand = true,
		expandRate = 100,
		maxScale = maxSize,
	})
end

function ThatHand.Erase(standModel)
	local character = standModel.Parent

	AnimationModule.PlayAnimation(standModel, ERASE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, ERASE_ENDLAG)

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "EraseEffect",
		soundID = "1228181736",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	local hitbox = HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = ERASE_DAMAGE or 0.1,
		Size = ERASE_SIZE,
		Offset = CFrame.new(ERASE_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = 0.75,
		StunDuration = ERASE_STUN,
		Transparency = 1,
		Name = "EraseHitbox",
	})

	local vfxId = HttpService:GenerateGUID(false)
	hitbox:SetAttribute("VFX_ID", vfxId)

	SpawnClientVfx:FireAllClients({
		type = "Attached",
		effectName = "ThatHandErase",
		attachId = vfxId,
		offset = CFrame.new(0, 0, -3),
		scale = 8,
		transparency = 0.7,
	})

	local rightPalm = standModel:FindFirstChild("RightHand")

	local loop = 0
	while loop < 15 do
		SpawnStationaryEraseVfx(rightPalm.Position, 0.8, 4)
		loop += 1
		task.wait(0.05)
	end
end

function ThatHand.VoidShielding(character)
	CombatUtils.AddBarrier(character, {
		Id = "RainBarrier",
		Amount = VOID_SHIELDING_AMOUNT,
		MaxCap = 200,

		DecayRate = VOID_SHIELDING_DECAY_RATE,
		DecayDelay = VOID_SHIELDING_DECAY_DELAY,

		Priority = 10, -- example priority (tune as needed)
	})

	local hrp = character:FindFirstChild("HumanoidRootPart")

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "EraseEffect",
		soundID = "108584054686428",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})
end

function ThatHand.TearSpace(standModel)
	local character = standModel.Parent

	--CombatUtils.SetActionInProgress(character, TEAR_SPACE_DURATION)

	AnimationModule.StopAllAnimations(standModel)
	AnimationModule.PlayAnimationThenIdle(standModel, ERASE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "TearSpaceEffects",
		soundID = "1228181736",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "TearSpaceCall",
		soundID = "13037428174",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	CombatUtils.ApplyTurningVelocity({
		Character = character,
		Speed = TEAR_SPACE_SPEED,
		Duration = TEAR_SPACE_DURATION,
		Name = "TearSpaceVelocity",
	})

	CombatUtils.SetIsDashing(character, TEAR_SPACE_DURATION)

	local rightPalm = standModel:FindFirstChild("RightHand")
	local loop = 0
	while loop < 20 do
		SpawnStationaryEraseVfx(rightPalm.Position, 0.8, 4)
		loop += 1
		task.wait(0.05)
	end
end

function ThatHand.LastStand(standModel)
	print("Last stand fired in module")
	local character = standModel.Parent

	-- Set barrage flag
	lastStandFlags[standModel.Parent] = true

	--CombatUtils.SetActionInProgress(character, LAST_STAND_DURATION)

	-- Auto-stop barrage after max duration
	task.delay(LAST_STAND_DURATION, function()
		if lastStandFlags[standModel.Parent] then
			lastStandFlags[standModel.Parent] = false
		end
	end)

	--play sound
	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "LastStandCall",
		soundID = "5375544504",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	local standCF = standModel.PrimaryPart.CFrame

	HitboxSpawner.SpawnSlowingField({
		StandModel = standModel,
		Size = LAST_STAND_HITBOX_SIZE,
		Duration = LAST_STAND_DURATION,
		SlowMultiplier = 0.4,
		Offset = LAST_STAND_OFFSET,
		Caster = character,
		Shape = Enum.PartType.Block,
		Transparency = 1,
	})

	-- Start spawning hitboxes
	task.spawn(function()
		while lastStandFlags[standModel.Parent] do
			local hitbox = HitboxSpawner.spawnHitbox({
				Stand = standModel,
				Character = character,
				Damage = LAST_STAND_DAMAGE,
				Size = LAST_STAND_HITBOX_SIZE,
				Offset = LAST_STAND_OFFSET,
				Color = BrickColor.new("Bright red"),
				Duration = LAST_STAND_HITBOX_DURATION,
				Transparency = 1,
				Name = "LastStandHitbox",
			})

			local vfxId = HttpService:GenerateGUID(false)
			hitbox:SetAttribute("VFX_ID", vfxId)

			SpawnClientVfx:FireAllClients({
				type = "Attached",
				effectName = "ThatHandErase",
				attachId = vfxId,
				offset = CFrame.new(0, 0, -3),
				scale = 20,
				transparency = 0.7,
			})

			local vfxAttachment = Instance.new("Attachment")
			vfxAttachment.Name = "LastStandVfxAttachment"
			vfxAttachment.Position = Vector3.new(0, 0, -4) -- LOCAL offset relative to hitbox
			vfxAttachment.Parent = hitbox

			AnimationModule.StopAllAnimations(standModel)
			AnimationModule.PlayAnimationThenIdle(standModel, ERASE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)

			SoundModule.PlaySound({
				Root = standModel.PrimaryPart,
				soundName = "LastStandEffects",
				soundID = "1228181736",
				volume = 2,
				playbackSpeed = 1,
				looped = false,
				range = 160,
			})

			-- 🔥 VFX runs independently
			task.spawn(function()
				for i = 1, 20 do
					if not hitbox or not hitbox.Parent then
						break
					end

					SpawnStationaryEraseVfx(vfxAttachment.WorldPosition, 4, 10)
					task.wait(0.05)
				end
			end)

			task.wait(LAST_STAND_INTERVAL)
		end
	end)
end

return ThatHand
