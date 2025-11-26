local Tusk = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local StandUtils = require(ServerScriptService.BasicCombat.StandUtils)
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))

local ERASE_ANIM_ID = 90498591949232

local NAILSHOT_SPEED = 400
local NAILSHOT_GRAVITY = 0.2
local NAILSHOT_OFFSET = Vector3.new(0, 0, 8)
local NAILSHOT_SIZE = Vector3.new(7, 7, 7)

local GUIDEDNAIL_SPEED = 100
local GUIDEDNAIL_AOE_SIZE = Vector3.new(15, 15, 15)
local GUIDEDNAIL_AOE_DAMAGE = 20

function Tusk.NailShot(character)
	print("Nail shot on module!")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	-- this will elp determiune the direction of the projectile
	local direction
	local startPos = hrp.Position
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

	if player then
		local powersFolder = player:FindFirstChild("Powers")
		local heroValue = powersFolder:FindFirstChild("Hero")
		if heroValue then
			heroValue.Value = "TuskAct1"
			print(player.Name .. " is now TuskAct1!")
		end

		StandUtils.RemoveStand(character)
		StandUtils.SummonStand(character, heroValue.Value)
	end

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "NailShotEffect",
		soundID = "89805684001014",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	HitboxSpawner.spawnArcProjectile({
		Character = character,
		Size = NAILSHOT_SIZE,
		Damage = 25,
		Duration = 5,
		Speed = NAILSHOT_SPEED,
		Direction = direction,
		Origin = startPos,
		Offset = NAILSHOT_OFFSET,
		Color = BrickColor.new("Bright yellow"),
		Gravity = Vector3.new(0, -workspace.Gravity * NAILSHOT_GRAVITY, 0), -- optional tweak
		DetectSurface = true,
		CanBlock = false,

		OnSurfaceHit = function(projectile, hitResult, horizontalDirection)
			print("Tusk Module Projectile hit surface:", hitResult.Instance.Name)
		end,
	})

	return true
end

function Tusk.GuidedNail(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	-- this will elp determiune the direction of the projectile
	local direction
	local startPos = hrp.Position

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

	if player then
		local powersFolder = player:FindFirstChild("Powers")
		local heroValue = powersFolder:FindFirstChild("Hero")
		if heroValue then
			heroValue.Value = "TuskAct2"
			print(player.Name .. " is now TuskAct2!")
		end

		StandUtils.RemoveStand(character)
		StandUtils.SummonStand(character, heroValue.Value)
	end

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "GuidedNailEffect",
		soundID = "89805684001014",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	HitboxSpawner.spawnGuidedProjectile({
		Character = character,
		Size = NAILSHOT_SIZE,
		Damage = 25,
		Duration = 5,
		Speed = GUIDEDNAIL_SPEED,
		Direction = direction,
		Origin = startPos,
		Offset = NAILSHOT_OFFSET,
		Color = BrickColor.new("Bright yellow"),
		Gravity = Vector3.new(0, -workspace.Gravity * NAILSHOT_GRAVITY, 0), -- optional tweak
		DetectSurface = true,
		CanBlock = false,

		OnSurfaceHit = function(projectile, hitResult, horizontalDirection)
			print("[GoldExperimentModule!!!] Projectile hit surface:", hitResult.Instance.Name)

			local hitBoxOffset = Vector3.new(0, 3, 0)

			-- Determine stationary hitbox position
			local hitPosition = hitResult.Position

			-- Spawn a stationary damage hitbox
			HitboxSpawner.spawnStationaryHitbox({
				Position = hitPosition,
				Character = character,
				Size = GUIDEDNAIL_AOE_SIZE,
				Damage = GUIDEDNAIL_AOE_DAMAGE,
				Offset = hitBoxOffset,
				Color = BrickColor.new("Bright red"),
				Duration = 1,
				StunDuration = 0,
				Transparency = 0.3,
				Name = "GuidedNailAOEHitbox",
				Rotation = horizontalDirection, -- ensures horizontal facing of projectile
				Shape = Enum.PartType.Ball,
			})
		end,
	})

	return true
end

function Tusk.SpinWormhole(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	-- this will elp determiune the direction of the projectile
	local direction
	local startPos = hrp.Position

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

	if player then
		local powersFolder = player:FindFirstChild("Powers")
		local heroValue = powersFolder:FindFirstChild("Hero")
		if heroValue then
			heroValue.Value = "TuskAct3"
			print(player.Name .. " is now TuskAct3!")
		end

		StandUtils.RemoveStand(character)
		StandUtils.SummonStand(character, heroValue.Value)
	end

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "GuidedNailEffect",
		soundID = "89805684001014",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	HitboxSpawner.spawnGuidedProjectile({
		Character = character,
		Size = NAILSHOT_SIZE,
		Damage = 25,
		Duration = 5,
		Speed = GUIDEDNAIL_SPEED,
		Direction = direction,
		Origin = startPos,
		Offset = NAILSHOT_OFFSET,
		Color = BrickColor.new("Bright yellow"),
		Gravity = Vector3.new(0, -workspace.Gravity * NAILSHOT_GRAVITY, 0), -- optional tweak
		DetectSurface = true,
		CanBlock = false,

		OnSurfaceHit = function(projectile, hitResult, horizontalDirection)
			print("[GoldExperimentModule!!!] Projectile hit surface:", hitResult.Instance.Name)

			local hitBoxOffset = Vector3.new(0, 3, 0)

			-- Determine stationary hitbox position
			local hitPosition = hitResult.Position

			-- Spawn a stationary damage hitbox
			HitboxSpawner.spawnStationaryHitbox({
				Position = hitPosition,
				Character = character,
				Size = GUIDEDNAIL_AOE_SIZE,
				Damage = GUIDEDNAIL_AOE_DAMAGE,
				Offset = hitBoxOffset,
				Color = BrickColor.new("Bright red"),
				Duration = 1,
				StunDuration = 0,
				Transparency = 0.3,
				Name = "GuidedNailAOEHitbox",
				Rotation = horizontalDirection, -- ensures horizontal facing of projectile
				Shape = Enum.PartType.Ball,
			})
		end,
	})

	return true
end

function Tusk.InfiniteRotation(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	-- this will elp determiune the direction of the projectile
	local direction
	local startPos = hrp.Position
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

	if player then
		local powersFolder = player:FindFirstChild("Powers")
		local heroValue = powersFolder:FindFirstChild("Hero")
		if heroValue then
			heroValue.Value = "TuskAct4"
			print(player.Name .. " is now TuskAct4!")
		end

		StandUtils.RemoveStand(character)
		StandUtils.SummonStand(character, heroValue.Value)
	end

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "GuidedNailEffect",
		soundID = "89805684001014",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	HitboxSpawner.spawnArcProjectile({
		Character = character,
		Size = NAILSHOT_SIZE,
		Damage = 25,
		Duration = 5,
		Speed = NAILSHOT_SPEED,
		Direction = direction,
		Offset = NAILSHOT_OFFSET,
		Origin = startPos,
		Color = BrickColor.new("Bright yellow"),
		Gravity = Vector3.new(0, -workspace.Gravity * NAILSHOT_GRAVITY, 0), -- optional tweak
		DetectSurface = true,
		CanBlock = false,

		OnSurfaceHit = function(projectile, hitResult, horizontalDirection)
			print("Tusk Module Projectile hit surface:", hitResult.Instance.Name)
		end,
	})

	return true
end

return Tusk
