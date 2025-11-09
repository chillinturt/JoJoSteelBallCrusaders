local KingCarmine = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local BlockModule = require(game.ServerScriptService.BasicCombat:WaitForChild("BlockModule"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local RaycastIgnoreModule = require(game.ReplicatedStorage.Shared.Modules:WaitForChild("RaycastIgnoreModule"))
local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))

local MAX_TELEPORT_DISTANCE = 60 -- studs

local TIME_ERASE_DURATION = 10

local CHOP_DAMAGE = 10
local CHOP_ENDLAG = 1
local CHOP_SIZE = Vector3.new(5, 6, 7)
local CHOP_OFFSET = Vector3.new(2, 0, -8)
local CHOP_DPS = 1
local CHOP_TICK_INTERVAL = 0.25
local CHOP_DURATION = 5

local CHOP_ANIM_ID = 90498591949232

local SPLATTER_HITBOX_SIZE = Vector3.new(3, 3, 3)
local SPLATTER_DAMAGE = 15
local SPLATTER_DURATION = 3
local SPLATTER_OFFSET = Vector3.new(0, 0, 8)

function KingCarmine.Teleport(character)
	print("Teleport called on module")

	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	-- === TELEPORT SETTINGS ===
	local MAX_TELEPORT_DISTANCE = 100 -- adjust if needed
	local origin = humanoidRootPart.Position

	-- === Get camera direction from client ===
	local remote = ReplicatedStorage.Shared.BasicCombat.KingCarmine:WaitForChild("RequestTeleportTarget")
	local cameraDirection = remote:InvokeClient(player)

	-- If client didn’t respond properly, fall back to character look direction
	if not cameraDirection or cameraDirection.Magnitude == 0 then
		cameraDirection = humanoidRootPart.CFrame.LookVector
	else
		cameraDirection = cameraDirection.Unit
	end

	-- === Raycast setup ===
	local rayParams = RaycastParams.new()
	local ignoreList = RaycastIgnoreModule.GetIgnoreList()
	table.insert(ignoreList, character) -- ignore self
	rayParams.FilterDescendantsInstances = ignoreList
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local rayResult = workspace:Raycast(origin, cameraDirection * MAX_TELEPORT_DISTANCE, rayParams)

	-- === Determine teleport destination ===
	local finalTarget
	if rayResult then
		-- Hit something — teleport just before surface
		finalTarget = rayResult.Position - cameraDirection * 2
	else
		-- Nothing hit — teleport to max distance
		finalTarget = origin + cameraDirection * MAX_TELEPORT_DISTANCE
	end

	-- === Teleport effect ===
	SoundModule.PlaySound({
		Root = character,
		soundName = "TeleportEffect",
		soundID = "3373991228",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	-- Project the camera direction onto the XZ plane so the player stands upright
	local horizontalDirection = Vector3.new(cameraDirection.X, 0, cameraDirection.Z)
	if horizontalDirection.Magnitude < 0.1 then
		-- fallback: keep previous facing direction if camera is nearly vertical
		horizontalDirection = humanoidRootPart.CFrame.LookVector
	else
		horizontalDirection = horizontalDirection.Unit
	end

	-- Keep the player standing upright, looking horizontally
	humanoidRootPart.CFrame = CFrame.lookAt(finalTarget, finalTarget + horizontalDirection)
end

function KingCarmine.TimeErase(standModel)
	print("Time Erase called on module")
	local character = standModel.Parent

	local characterHurtbox = character:FindFirstChild("Hurtbox")
	local standHurtbox = standModel:FindFirstChild("Hurtbox")

	characterHurtbox.CanQuery = false
	standHurtbox.CanQuery = false

	CombatUtils.SetActionInProgress(character, TIME_ERASE_DURATION)
	BlockModule.BlockOn(character) --I turn the lbock on and off simply to prevent barraging

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "TimeEraseEffect",
		soundID = "89498716177477",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "TimeEraseCall",
		soundID = "4251553413",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	task.wait(TIME_ERASE_DURATION)

	BlockModule.BlockOff(character)
	characterHurtbox.CanQuery = true
	standHurtbox.CanQuery = true
end

function KingCarmine.Chop(standModel)
	print("Time Erase called on module")
	local character = standModel.Parent

	AnimationModule.PlayAnimation(standModel, CHOP_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, CHOP_ENDLAG)

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "ChopEffect",
		soundID = "74238153433253",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "ChopCall",
		soundID = "6665054578",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = CHOP_DAMAGE or 0.1,
		Size = CHOP_SIZE,
		Offset = CFrame.new(CHOP_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = 0.75,
		StunDuration = 1,
		Transparency = 0.3,
		Name = "BasicPunchHitbox",
		DamagePerTick = CHOP_DPS,
		DOTTickInterval = CHOP_TICK_INTERVAL,
		DOTDuration = CHOP_DURATION,
	})
end

function KingCarmine.Splatter(standModel)
	print("Splatter fired in Module")
	local character = standModel.Parent
	local hrp = character:FindFirstChild("HumanoidRootPart")

	AnimationModule.PlayAnimation(standModel, CHOP_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, CHOP_ENDLAG)

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "SplatterEffect",
		soundID = "18816874251",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "SplatterCall",
		soundID = "5669008914",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

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
		Stand = standModel,
		Character = character,
		Damage = SPLATTER_DAMAGE,
		Size = SPLATTER_HITBOX_SIZE,
		Offset = SPLATTER_OFFSET,
		Color = BrickColor.new("Bright red"),
		Duration = SPLATTER_DURATION,
		StunDuration = 2,
		Transparency = 0.3,
		Name = "BarragePunchHitbox",
		Speed = 200,
		Direction = direction,
		Origin = startPos,
	})
	return true
end

return KingCarmine
