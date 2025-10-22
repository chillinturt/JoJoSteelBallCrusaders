local KingCarmine = {}

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local BlockModule = require(game.ServerScriptService.BasicCombat:WaitForChild("BlockModule"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))

local MAX_TELEPORT_DISTANCE = 60 -- studs

local TIME_ERASE_DURATION = 10

local CHOP_DAMAGE = 10
local CHOP_ENDLAG = 1
local CHOP_SIZE = Vector3.new(4, 4, 7)
local CHOP_OFFSET = Vector3.new(2, 0, -8)
local CHOP_DPS = 1
local CHOP_TICK_INTERVAL = 0.25
local CHOP_DURATION = 5

local CHOP_ANIM_ID = 90498591949232

local SPLATTER_HITBOX_SIZE = Vector3.new(2, 2, 2)
local SPLATTER_DAMAGE = 15
local SPLATTER_DURATION = 3
local SPLATTER_OFFSET = Vector3.new(2, 0, -8)

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

	-- Get mouse target position (from client)
	local remote = ReplicatedStorage.Shared.BasicCombat.KingCarmine:WaitForChild("RequestTeleportTarget")
	local targetPosition = remote:InvokeClient(player) -- safely ask client for mouse position
	if not targetPosition then
		return
	end

	-- Clamp distance to max range
	local direction = (targetPosition - humanoidRootPart.Position)
	local distance = math.min(direction.Magnitude, MAX_TELEPORT_DISTANCE)
	local finalTarget = humanoidRootPart.Position + direction.Unit * distance

	-- Raycast to make sure we don’t go through walls

	--[[
	]]
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character }
	params.FilterType = Enum.RaycastFilterType.Exclude

	local rayResult = workspace:Raycast(humanoidRootPart.Position, direction.Unit * distance, params)

	if rayResult then
		-- Hit something solid → teleport just before the surface
		finalTarget = rayResult.Position - direction.Unit * 2 -- back off a bit so we don't clip inside
	end

	-- Play teleport sound
	SoundModule.PlaySound({
		Root = character,
		soundName = "TeleportEffect",
		soundID = "3373991228",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	-- Actually move the player
	humanoidRootPart.CFrame = CFrame.new(finalTarget, finalTarget + humanoidRootPart.CFrame.LookVector)
end

function KingCarmine.TimeErase(standModel)
	print("Time Erase called on module")
	local character = standModel.Parent
	local hrp = character:FindFirstChild("HumanoidRootPart")

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
	local hrp = character:FindFirstChild("HumanoidRootPart")

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

	HitboxSpawner.spawnProjectile({
		Stand = standModel,
		Character = character,
		Damage = SPLATTER_DAMAGE,
		Size = SPLATTER_HITBOX_SIZE,
		Offset = SPLATTER_OFFSET,
		Color = BrickColor.new("Bright red"),
		Duration = SPLATTER_DURATION,
		StunDuration = 1,
		Transparency = 0.3,
		Name = "BarragePunchHitbox",
	})
end

return KingCarmine
