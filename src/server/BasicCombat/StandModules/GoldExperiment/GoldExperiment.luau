local GoldExperiment = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local StandUtils = require(ServerScriptService.BasicCombat.StandUtils)
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))

local LIFE_OVERFLOW_DAMAGE = 15
local LIFE_OVERFLOW_ENDLAG = 1
local LIFE_OVERFLOW_SIZE = Vector3.new(4, 4, 7)
local LIFE_OVERFLOW_OFFSET = Vector3.new(2, 0, -8)
local LIFE_OVERFLOW_HEAL = 30
local LIFE_OVERFLOW_STUN = 2

local ERASE_ANIM_ID = 90498591949232

local EAGLESTRIKE_DAMAGE = 13
local EAGLESTRIKE_SIZE = Vector3.new(4, 4, 7)
local EAGLESTRIKE_OFFSET = Vector3.new(0, 4, -2)
local EAGLESTRIKE_STUN = 1
local EAGLESTRIKE_SPEED = 40
local EAGLESTRIKE_REDIRECT_SPEED = 70
local EAGLESTRIKE_ENDLAG = 0.5
local EAGLESTRIKE_COOLDOWN = 8

local TREEOFLIFE_DURATION = 4
local TREEOFLIFE_SIZE = Vector3.new(30, 30, 30)
local TREEOFLIFE_DELAY = 1
local TREEOFLIFE_HEAL = 4
local TREEOFLIFE_SEED_DAMAGE = 15

-- track projectile state per player
local eagleStrikeState = {} -- [player] = "first" | "redirect"
local eagleStrikeProjectile = {} -- [player] = projectile instance

function GoldExperiment.LifeOverflow(standModel)
	local character = standModel.Parent

	AnimationModule.PlayAnimation(standModel, ERASE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, LIFE_OVERFLOW_ENDLAG)

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "LifeOverflowEffect",
		soundID = "4567255304",
		volume = 5,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "LifeOverflowCall",
		soundID = "4748348740",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = LIFE_OVERFLOW_DAMAGE or 0.1,
		Size = LIFE_OVERFLOW_SIZE,
		Offset = CFrame.new(LIFE_OVERFLOW_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = 0.75,
		StunDuration = LIFE_OVERFLOW_STUN,
		Transparency = 1,
		Name = "LifeOverflowHitbox",
		Heal = LIFE_OVERFLOW_HEAL,
	})
end

function GoldExperiment.EagleStrike(character)
	local player = game.Players:GetPlayerFromCharacter(character)
	if not player then
		return false
	end

	local standModel = StandUtils.getStandModel(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	-- === Play animation & set endlag ===
	AnimationModule.PlayAnimation(standModel, ERASE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, EAGLESTRIKE_ENDLAG)

	-- === Determine whether this is the first use or redirect ===
	local isRedirect = eagleStrikeState[player] == "first"

	if not isRedirect then
		-- === Sound effects ===
		SoundModule.PlaySound({
			Root = hrp,
			soundName = "EagleStrikeEffect",
			soundID = "3378924410",
			volume = 2,
			playbackSpeed = 1,
			looped = false,
			range = 160,
		})
		SoundModule.PlaySound({
			Root = hrp,
			soundName = "EagleStrikeEffect2",
			soundID = "139887585493497",
			volume = 2,
			playbackSpeed = 1,
			looped = false,
			range = 160,
		})

		-- === Direction ===
		local startPos = hrp.Position
		local direction
		local isClose = RaycastModule.CheckIfTargetIsClose(character, 10)
		if isClose then
			direction = hrp:GetPivot().LookVector
		else
			local targetPoint = RaycastModule.ReturnFacingPoint(character, 1500)
			if not targetPoint then
				warn("No target point found")
				return false
			end
			direction = (targetPoint - startPos).Unit
		end

		-- === Spawn first projectile ===
		local projectile = HitboxSpawner.spawnProjectile({
			Character = character,
			Damage = EAGLESTRIKE_DAMAGE,
			Size = EAGLESTRIKE_SIZE,
			Offset = EAGLESTRIKE_OFFSET,
			Color = BrickColor.new("Bright red"),
			Duration = 10,
			StunDuration = EAGLESTRIKE_STUN,
			Transparency = 0.3,
			Name = "Eagle Strike Hitbox",
			Speed = EAGLESTRIKE_SPEED,
			Direction = direction,
			Origin = startPos,
		})

		eagleStrikeProjectile[player] = projectile
		eagleStrikeState[player] = "first"

		return true, "launch"
	else
		-- === Redirect projectile ===
		SoundModule.PlaySound({
			Root = hrp,
			soundName = "EagleStrikeRedirect",
			soundID = "491270608",
			volume = 2,
			playbackSpeed = 1,
			looped = false,
			range = 160,
		})

		local targetPoint = RaycastModule.ReturnFacingPoint(character, 1500)
		if not targetPoint then
			warn("EagleStrike redirect: no facing point found")
			return false
		end

		local oldProjectile = eagleStrikeProjectile[player]
		local startPos = (oldProjectile and oldProjectile.Parent) and oldProjectile.Position or hrp.Position
		if oldProjectile then
			oldProjectile:Destroy()
		end

		local direction = (targetPoint - startPos).Unit

		HitboxSpawner.spawnProjectile({
			Character = character,
			Damage = EAGLESTRIKE_DAMAGE,
			Size = EAGLESTRIKE_SIZE,
			Offset = Vector3.new(0, 0, 0),
			Color = BrickColor.new("Bright yellow"),
			Duration = 10,
			StunDuration = EAGLESTRIKE_STUN,
			Transparency = 0.3,
			Name = "Eagle Strike Redirected Hitbox",
			Speed = EAGLESTRIKE_REDIRECT_SPEED,
			Direction = direction,
			Origin = startPos,
			CanBlock = false,
		})

		eagleStrikeState[player] = nil
		eagleStrikeProjectile[player] = nil

		return true, "redirect"
	end
end

function GoldExperiment.TreeOfLife(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	-- this will elp determiune the direction of the projectile
	local direction
	local startPos = hrp.Position + Vector3.new(0, 4, 0)
	local player = Players:GetPlayerFromCharacter(character)

	local remote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("RequestCameraDirection")
	local camDirection = remote:InvokeClient(player)

	if player then
		local isClose = RaycastModule.CheckIfTargetIsClose(character, 10)
		if isClose then
			--direction = hrp:GetPivot().LookVector
			direction = camDirection
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

	HitboxSpawner.spawnArcProjectile({
		Character = character,
		Size = Vector3.new(5, 5, 5),
		Damage = TREEOFLIFE_SEED_DAMAGE,
		Duration = 5,
		Speed = 100,
		Direction = direction,
		Origin = startPos,
		Color = BrickColor.new("Bright yellow"),
		Gravity = Vector3.new(0, -workspace.Gravity * 0.8, 0), -- optional tweak
		DetectSurface = true,
		CanBlock = false,

		OnSurfaceHit = function(projectile, hitResult, horizontalDirection)
			print("[GoldExperimentModule!!!] Projectile hit surface:", hitResult.Instance.Name)

			local hitBoxOffset = Vector3.new(0, 0, 0)

			-- Determine stationary hitbox position
			local hitPosition = hitResult.Position

			-- Damage loop
			task.spawn(function()
				local startTime = tick()

				while tick() - startTime < TREEOFLIFE_DURATION do
					-- Spawn a stationary damage hitbox
					HitboxSpawner.spawnStationaryHitbox({
						Position = hitPosition,
						Character = character,
						Size = TREEOFLIFE_SIZE,
						Offset = hitBoxOffset,
						Color = BrickColor.new("Bright red"),
						Duration = 1,
						StunDuration = 0,
						Transparency = 0.3,
						Name = "TreeOfLifeHitbox",
						Rotation = horizontalDirection, -- ensures horizontal facing of projectile
						Heal = TREEOFLIFE_HEAL,
						CanSelfHit = true,
					})

					-- Wait until next pulse
					task.wait(TREEOFLIFE_DELAY)
				end
			end)
		end,
	})

	return true
end

return GoldExperiment
