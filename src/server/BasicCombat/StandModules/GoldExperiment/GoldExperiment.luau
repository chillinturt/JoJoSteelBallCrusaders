local GoldExperiment = {}

local ServerScriptService = game:GetService("ServerScriptService")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))

local ERASE_DAMAGE = 35
local ERASE_ENDLAG = 1
local ERASE_SIZE = Vector3.new(4, 4, 7)
local ERASE_OFFSET = Vector3.new(2, 0, -8)

local ERASE_ANIM_ID = 90498591949232

local TEAR_SPACE_SPEED = 50
local TEAR_SPACE_DURATION = 2

local splashingFlags = {}
local LAST_STAND_DURATION = 8
local LAST_STAND_INTERVAL = 0.8
local LAST_STAND_HITBOX_SIZE = Vector3.new(8, 6, 7)
local LAST_STAND_DAMAGE = 10
local LAST_STAND_HITBOX_DURATION = 1
local LAST_STAND_OFFSET = CFrame.new(2, 0, -8)

--[[
function GoldExperiment.Erase(standModel)
	local character = standModel.Parent
	local hrp = character:FindFirstChild("HumanoidRootPart")

	AnimationModule.PlayAnimation(standModel, ERASE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, ERASE_ENDLAG)

	SoundModule.PlaySound(hrp, "EraseEffect", "1228181736", 1, 1, false, 3)

	HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = ERASE_DAMAGE or 0.1,
		Size = ERASE_SIZE,
		Offset = CFrame.new(ERASE_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = 0.75,
		StunDuration = 0.3,
		Transparency = 0.3,
		Name = "EraseHitbox",
	})
end

function GoldExperiment.TearSpace(standModel)
	local character = standModel.Parent
	local hrp = character:FindFirstChild("HumanoidRootPart")

	CombatUtils.SetActionInProgress(character, TEAR_SPACE_DURATION)

	AnimationModule.StopAllAnimations(standModel)
	AnimationModule.PlayAnimation(standModel, ERASE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	SoundModule.PlaySound(standModel.PrimaryPart, "TearSpaceEffects", "1228181736", 2, 1, false, 3)

	CombatUtils.ApplyTimedVelocity(
		hrp,
		TEAR_SPACE_SPEED,
		TEAR_SPACE_DURATION,
		"TearSpaceVelocity",
		hrp.CFrame.LookVector
	)
end

function GoldExperiment.LastStand(standModel)
	print("Last stand fired in module")
	local character = standModel.Parent

	-- Set barrage flag
	splashingFlags[standModel.Parent] = true

	CombatUtils.SetActionInProgress(character, LAST_STAND_DURATION)

	-- Auto-stop barrage after max duration
	task.delay(LAST_STAND_DURATION, function()
		if splashingFlags[standModel.Parent] then
			splashingFlags[standModel.Parent] = false
		end
	end)

	--play sound
	SoundModule.PlaySound(standModel.PrimaryPart, "LastStandCall", "5375544504", 2, 1, false, 3)

	-- Start spawning hitboxes
	task.spawn(function()
		while splashingFlags[standModel.Parent] do
			HitboxSpawner.spawnHitbox({
				Stand = standModel,
				Character = character,
				Damage = LAST_STAND_DAMAGE,
				Size = LAST_STAND_HITBOX_SIZE,
				Offset = LAST_STAND_OFFSET,
				Color = BrickColor.new("Bright red"),
				Duration = LAST_STAND_HITBOX_DURATION,
				StunDuration = 1,
				Transparency = 0.3,
				Name = "LastStandHitbox",
			})
			AnimationModule.StopAllAnimations(standModel)
			AnimationModule.PlayAnimation(standModel, ERASE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
			SoundModule.PlaySound(standModel.PrimaryPart, "LastStandEffects", "1228181736", 2, 1, false, 3)
			task.wait(LAST_STAND_INTERVAL)
		end
	end)
end
]]
return GoldExperiment
