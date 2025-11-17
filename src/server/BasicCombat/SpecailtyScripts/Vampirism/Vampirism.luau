-- ServerScriptService/VampirismModule.lua
local VampirismModule = {}

local Players = game:GetService("Players")

local HitboxSpawner = require(game.ServerScriptService.BasicCombat.HitboxSpawner)
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local VampireModule = require(game.ServerScriptService.BasicCombat.RaceScripts:WaitForChild("Vampire"))
local BlockModule = require(game.ServerScriptService.BasicCombat:WaitForChild("BlockModule"))
local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))

local DIVINE_DRINK_ANIM_ID = 136847469830162
local DIVINE_DRINK_ENDLAG = 0.7
local DIVINE_DRINK_DAMAGE = 18
local DIVINE_DRINK_SIZE = Vector3.new(7, 16, 10)
local DIVINE_DRINK_OFFSET = Vector3.new(0, 4, -2)
local DIVINE_DRINK_BLOOD = 20
local DIVINE_DRINK_STUN = 1.4
local DIVINE_DRINK_DURATION = 1

local VAPORIZATION_FREEZE_ANIM_ID = 136847469830162
local VAPORIZATION_FREEZE_ENDLAG = 1
local VAPORIZATION_FREEZE_DAMAGE = 15
local VAPORIZATION_FREEZE_SIZE = Vector3.new(9, 10, 10)
local VAPORIZATION_FREEZE_OFFSET = Vector3.new(0, 4, -2)
local VAPORIZATION_FREEZE_BLOOD = 1
local VAPORIZATION_FREEZE_STUN = 1.8
local VAPORIZATION_FREEZE_DURATION = 1

local SPACE_RIPPER_STINGY_EYES_ENDLAG = 0.1
local SPACE_RIPPER_STINGY_EYES_DAMAGE = 2.0
local SPACE_RIPPER_STINGY_EYES_SIZE = Vector3.new(6, 6, 6)
local SPACE_RIPPER_STINGY_EYES_OFFSET = Vector3.new(0, 4, 2)
local SPACE_RIPPER_STINGY_EYES_COST = 10
local SPACE_RIPPER_STINGY_EYES_STUN = 0
local SPACE_RIPPER_STINGY_EYES_SHOT_COUNT = 10
local SPACE_RIPPER_STINGY_EYES_DELAY = 0.04 -- seconds between each shot
local SPACE_RIPPER_STINGY_EYES_STARTUP = 0.6

local BLOOD_RUSH_ENDLAG = 1
local BLOOD_RUSH_COST = 20
local BLOOD_RUSH_ANIMID = 136847469830162
local BLOOD_RUSH_HEAL = 30
local BLOOD_RUSH_METER = 1
local BLOOD_RUSH_BARRIER_DECAY = 1
local BLOOD_RUSH_BARRIER_DELAY = 8

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
		Transparency = 1,
		Name = "DivineDrinkHitbox",
		CanBlock = false, -- ✅ Unblockable
		OnHit = function(targetChar, humanoid)
			print(character.Name .. " drained " .. targetChar.Name .. " successfully!")
			VampireModule.addBlood(character, DIVINE_DRINK_BLOOD)
			--BlockModule.StopBlocking(targetChar)
		end,
	})

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "DivineDrinkEffect",
		soundID = "6594869919",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "DivineDrinkEffect2",
		soundID = "7188240609",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})
end

function VampirismModule.VaporizationFreeze(character)
	AnimationModule.PlayAnimation(character, VAPORIZATION_FREEZE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, VAPORIZATION_FREEZE_ENDLAG)

	local hrp = character:FindFirstChild("HumanoidRootPart")

	HitboxSpawner.spawnStandOffHitbox({
		Character = character,
		Damage = VAPORIZATION_FREEZE_DAMAGE,
		Size = VAPORIZATION_FREEZE_SIZE,
		Offset = CFrame.new(VAPORIZATION_FREEZE_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = VAPORIZATION_FREEZE_DURATION,
		StunDuration = VAPORIZATION_FREEZE_STUN,
		Transparency = 1,
		Name = "VaporizationFreezeHitbox",
		OnHit = function(targetChar, humanoid)
			print(character.Name .. " drained " .. targetChar.Name .. " successfully!")
			VampireModule.addBlood(character, VAPORIZATION_FREEZE_BLOOD)
		end,
	})

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "VaporizationFreezeCall",
		soundID = "71670337007708",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "VaporizationFreezeEffect",
		soundID = "116492135471818",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})
end

function VampirismModule.SpaceRipperStingyEyes(character)
	if not VampireModule.spendBlood(character, SPACE_RIPPER_STINGY_EYES_COST) then
		return
	end

	AnimationModule.PlayAnimation(character, DIVINE_DRINK_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, SPACE_RIPPER_STINGY_EYES_ENDLAG)

	local hrp = character:FindFirstChild("HumanoidRootPart")

	--// Function to fire 3 projectiles in sequence
	task.spawn(function()
		wait(SPACE_RIPPER_STINGY_EYES_STARTUP)
		for i = 1, SPACE_RIPPER_STINGY_EYES_SHOT_COUNT do
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
				Damage = SPACE_RIPPER_STINGY_EYES_DAMAGE or 0.1,
				Size = SPACE_RIPPER_STINGY_EYES_SIZE,
				Offset = SPACE_RIPPER_STINGY_EYES_OFFSET,
				Color = BrickColor.new("Bright red"),
				Duration = 1.5,
				StunDuration = SPACE_RIPPER_STINGY_EYES_STUN,
				Transparency = 0.3,
				Name = "Bubble Cutter Hitbox",
				Speed = 250,
				Direction = direction,
				Origin = startPos,
			})
			if i < SPACE_RIPPER_STINGY_EYES_SHOT_COUNT then
				task.wait(SPACE_RIPPER_STINGY_EYES_DELAY)
			end
		end
	end)

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "SpaceRipperStingyEyesEffect",
		soundID = "109874197616407",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})
end

function VampirismModule.BloodRush(character)
	if not VampireModule.spendBlood(character, BLOOD_RUSH_COST) then
		return
	end

	AnimationModule.PlayAnimation(character, BLOOD_RUSH_ANIMID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, BLOOD_RUSH_ENDLAG)

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	-- Calculate intended healing
	local healAmount = BLOOD_RUSH_HEAL * BLOOD_RUSH_METER
	local maxHealth = humanoid.MaxHealth
	local currentHealth = humanoid.Health

	-- Apply healing normally
	local newHealth = math.min(currentHealth + healAmount, maxHealth)
	humanoid.Health = newHealth

	-- Calculate surplus (overheal)
	local surplus = (currentHealth + healAmount) - maxHealth
	if surplus > 0 then
		-- Grant the overheal as a temporary barrier
		CombatUtils.AddBarrier(character, surplus, BLOOD_RUSH_BARRIER_DECAY, BLOOD_RUSH_BARRIER_DELAY)
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "BloodRushCall",
		soundID = "6177204732",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "BloodRushEffct",
		soundID = "121586099520003",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})
end

return VampirismModule
