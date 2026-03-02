local StarPurple = {}

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local BlockModule = require(game.ServerScriptService.BasicCombat:WaitForChild("BlockModule"))
local TeamsModule =
	require(game.ServerScriptService:WaitForChild("BasicCombat"):WaitForChild("Managers"):WaitForChild("TeamsModule"))

local MACH_ORA_DAMAGE = 12
local MACH_ORA_DASH_SPEED = 90 -- Speed of the dash
local MACH_ORA_DASH_DURATION = 0.7 -- How long the dash lasts in seconds
local MACH_ORA_ENDLAG = 0.4
local MACH_ORA_SIZE = Vector3.new(5, 6, 9)
local MACH_ORA_OFFSET = Vector3.new(2, 0, -8)
local MACH_ORA_STUN = 1.5

local GROUND_POUND_DAMAGE = 15
local GROUND_POUND_SIZE = Vector3.new(15, 15, 15)
local GROUND_POUND_OFFSET = Vector3.new(2, 0, -10)
local GROUND_POUND_ENDLAG = 0.5
local GROUNDPOUND_DURATION = 1

local GROUNDPOUND_ANIM_ID = 123871739409470

local STARFINGER_DAMAGE = 15
local STARFINGER_SIZE = Vector3.new(5, 7, 18)
local STARFINGER_OFFSET = Vector3.new(2, 0, -14)
local STARFINGER_ENDLAG = 1
local STARFINGER_STUN = 1.5
local STARFINGER_ANIM_ID = 90498591949232

-- CONFIG
local STOP_DURATION = 3 -- seconds
local IMMOBILE_ANCHOR_NAME = "StarPurpleTimeStopAnchor"
local TIME_STOP_DAMAGE_MULT = 1
local TIME_STOP_RANGE = 50

local ENEMY_NPC_FOLDER = game.Workspace:WaitForChild("NPCs"):WaitForChild("EnemyNPCs")

local SpawnClientVfx = ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")
local ScreenColorVfxEvent = ReplicatedStorage.UIs.RemoteEvents:WaitForChild("ScreenColorVfx")

local function timeStopBall(caster)
	SpawnClientVfx:FireAllClients({
		type = "Stationary",
		effectName = "TimeStopBall",

		-- Position
		cframe = caster.PrimaryPart.CFrame,

		-- Lifetime
		lifetime = 0.8,

		-- Visual style
		transparency = 0.5,
		scale = 0.8, -- starting size

		-- Optional flags for client expansion logic
		expand = true,
		expandRate = 70,
		maxScale = 20,
	})

	task.delay(0.3, function()
		SpawnClientVfx:FireAllClients({
			type = "Stationary",
			effectName = "TimeStopBall",

			-- Position
			cframe = caster.PrimaryPart.CFrame,

			-- Lifetime
			lifetime = 0.8,

			-- Visual style
			transparency = 0.5,
			scale = 0.8, -- starting size

			-- Optional flags for client expansion logic
			expand = true,
			expandRate = 70,
			maxScale = 20,
		})
	end)

	task.delay(0.6, function()
		SpawnClientVfx:FireAllClients({
			type = "Stationary",
			effectName = "TimeStopBall",

			-- Position
			cframe = caster.PrimaryPart.CFrame,

			-- Lifetime
			lifetime = 0.6,

			-- Visual style
			transparency = 0.5,
			scale = 0.8, -- starting size

			-- Optional flags for client expansion logic
			expand = true,
			expandRate = 70,
			maxScale = 20,
		})
	end)

	task.delay(1.2, function()
		SpawnClientVfx:FireAllClients({
			type = "Stationary",
			effectName = "TimeStopBall",

			-- Position
			cframe = caster.PrimaryPart.CFrame,

			-- Lifetime
			lifetime = 0.6,

			-- Visual style
			transparency = 0.5,
			scale = 20, -- starting size

			-- Optional flags for client expansion logic
			expand = true,
			expandRate = -60,
			maxScale = 0.2,
		})
	end)
end

--adds momentum
local function applyMachOraDash(character)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	-- Check if there's an existing DashVelocity and remove it
	local existingDashVelocity = humanoidRootPart:FindFirstChild("DashVelocity")
	if existingDashVelocity then
		existingDashVelocity:Destroy() -- Destroy the existing DashVelocity
	end

	CombatUtils.SetIsDashing(character, MACH_ORA_DASH_DURATION)

	-- Create new BodyVelocity for MachOra
	local machOraVelocity = Instance.new("BodyVelocity")
	machOraVelocity.Name = "MachOraVelocity"
	machOraVelocity.MaxForce = Vector3.new(1e5, 0, 1e5) -- X and Z only
	machOraVelocity.P = 1250
	machOraVelocity.Velocity = humanoidRootPart.CFrame.LookVector * MACH_ORA_DASH_SPEED
	machOraVelocity.Parent = humanoidRootPart

	-- Keep updating the velocity WITHOUT adding extra force
	local timeElapsed = 0
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if timeElapsed >= MACH_ORA_DASH_DURATION then
			machOraVelocity:Destroy()
			connection:Disconnect()
			return
		end

		timeElapsed = timeElapsed + deltaTime
		-- **SET** velocity instead of adding to it
		machOraVelocity.Velocity = humanoidRootPart.CFrame.LookVector * MACH_ORA_DASH_SPEED
	end)
end

function StarPurple.onMachOraRequested(character)
	print("🚀 MachOra Fired On Server")

	CombatUtils.SetActionInProgress(character, MACH_ORA_ENDLAG)

	-- Locate the stand
	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		warn("⚠️ No summoned stand model found for", character.Name)
		return
	else
		local standName = standModel:FindFirstChild("StandTag").Value
		if standName ~= "StarPurple" then
			return
		end
	end

	-- Locate the stand’s PrimaryPart
	local standRoot = standModel.PrimaryPart
	if not standRoot then
		warn("⚠️ No PrimaryPart found in stand model!")
		return
	end

	--momentum
	applyMachOraDash(character)

	-- 🔊 Find or create Sound objects
	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "ChargeSound",
		soundID = "6186280987",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	-- Fire first animation (charge-up)
	AnimationModule.PlayAnimationThenIdle(standModel, 117096419135889, false, Enum.AnimationPriority.Action, 1)

	-- ⏳ Wait 0.6s, then play punch animation & sound
	--task.wait(0.2)
	--hitbox spawn
	--spawnHitbox(character, 5, 2, 0, MACH_ORA_DAMAGE)
	local hitbox = HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = MACH_ORA_DAMAGE or 0.1,
		Size = MACH_ORA_SIZE,
		Offset = CFrame.new(MACH_ORA_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = MACH_ORA_DASH_DURATION,
		StunDuration = MACH_ORA_STUN,
		Transparency = 1,
		Name = "BasicPunchHitbox",
		RemoveOnStun = false,

		OnHit = function(projectile, hitResult, horizontalDirection)
			-- Destroy MachOraVelocity if it exists
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				local machOraVelocity = humanoidRootPart:FindFirstChild("MachOraVelocity")
				if machOraVelocity then
					machOraVelocity:Destroy()
					print("MachOraVelocity has been destroyed!")
				end
			end
		end,
	})

	local vfxId = HttpService:GenerateGUID(false)
	hitbox:SetAttribute("VFX_ID", vfxId)

	SpawnClientVfx:FireAllClients({
		type = "Attached",
		effectName = "MachOra",
		attachId = vfxId,

		initialRotation = Vector3.new(
			0, -- X
			math.rad(90), -- Y
			math.rad(90) -- Z
		),

		offset = CFrame.new(0, 0, 0),
		scale = 1,
		transparency = 0.7,
		attachTo = hitbox,
	})

	task.wait(0.2)

	-- 🔊 Play punch sound
	SoundModule.PlaySound({
		Root = standRoot,
		soundName = "PunchSound",
		soundID = "6164853733",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})
end

function StarPurple.onMachOra2Requested(character)
	-- Locate the stand
	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		warn("⚠️ No summoned stand model found for", character.Name)
		return
	end

	-- Locate the stand’s PrimaryPart
	local standRoot = standModel.PrimaryPart
	if not standRoot then
		warn("⚠️ No PrimaryPart found in stand model!")
		return
	end

	-- Fire animation
	AnimationModule.PlayAnimationThenIdle(standModel, 116753187024506, false, Enum.AnimationPriority.Action, 1)

	--momentum
	applyMachOraDash(character)

	--hitbox spawn
	--spawnHitbox(character, 5, 2, 0, MACH_ORA_DAMAGE)
	local hitbox = HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = MACH_ORA_DAMAGE or 0.1,
		Size = MACH_ORA_SIZE,
		Offset = CFrame.new(MACH_ORA_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = MACH_ORA_DASH_DURATION,
		StunDuration = MACH_ORA_STUN,
		Transparency = 1,
		Name = "BasicPunchHitbox",
		RemoveOnStun = false,

		OnHit = function(projectile, hitResult, horizontalDirection)
			-- Destroy MachOraVelocity if it exists
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				local machOraVelocity = humanoidRootPart:FindFirstChild("MachOraVelocity")
				if machOraVelocity then
					machOraVelocity:Destroy()
					print("MachOraVelocity has been destroyed!")
				end
			end
		end,
	})

	local vfxId = HttpService:GenerateGUID(false)
	hitbox:SetAttribute("VFX_ID", vfxId)

	SpawnClientVfx:FireAllClients({
		type = "Attached",
		effectName = "MachOra",
		attachId = vfxId,

		initialRotation = Vector3.new(
			0, -- X
			math.rad(90), -- Y
			math.rad(90) -- Z
		),

		offset = CFrame.new(0, 0, 0),
		scale = 1,
		transparency = 0.7,
		attachTo = hitbox,
	})

	-- 🔊 Find or create Sound objects
	SoundModule.PlaySound({
		Root = standRoot,
		soundName = "ChargeSound",
		soundID = "6186280987",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	task.wait(0.6)

	-- 🔊 Play punch sound

	SoundModule.PlaySound({
		Root = standRoot,
		soundName = "PunchSound",
		soundID = "6164853733",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})
end

function StarPurple.GroundPound(standModel)
	local character = standModel.Parent
	local hrp = character:FindFirstChild("HumanoidRootPart")

	AnimationModule.PlayAnimationThenIdle(standModel, GROUNDPOUND_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, GROUND_POUND_ENDLAG)

	HitboxSpawner.spawnStationaryHitbox({
		Position = standModel.PrimaryPart.CFrame,
		Stand = standModel,
		Character = character,
		Damage = GROUND_POUND_DAMAGE,
		Size = GROUND_POUND_SIZE,
		Offset = GROUND_POUND_OFFSET,
		Color = BrickColor.new("Bright red"),
		Duration = GROUNDPOUND_DURATION,
		StunDuration = 1,
		Transparency = 1,
		Name = "BarrierDamageHitbox",
	})

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "GroundPoundCall",
		soundID = "129575721366476",
		volume = 3,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "GroundPoundEffect",
		soundID = "8275560362",
		volume = 0.5,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SpawnClientVfx:FireAllClients({
		type = "Stationary",
		effectName = "GroundPound",

		-- Position
		cframe = hrp.CFrame * CFrame.new(GROUND_POUND_OFFSET) * CFrame.new(-2, 0, 2),

		-- Lifetime
		lifetime = GROUNDPOUND_DURATION,

		-- Rotation (slow spin)
		rotationSpeed = Vector3.new(
			0,
			math.rad(720), -- Y-axis spin
			0
		),

		-- Visual style
		transparency = 0.5,
		scale = 1, -- starting size

		-- Optional flags for client expansion logic
		expand = true,
		expandRate = 30,
		maxScale = 1.2,
	})
end

function StarPurple.StarFinger(standModel)
	local character = standModel.Parent

	AnimationModule.PlayAnimation(standModel, STARFINGER_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, STARFINGER_ENDLAG)

	local hitbox = HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = STARFINGER_DAMAGE or 0.1,
		Size = STARFINGER_SIZE,
		Offset = CFrame.new(STARFINGER_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = 0.75,
		StunDuration = STARFINGER_STUN,
		Transparency = 1,
		Name = "StarFingerHitbox",
	})

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "StarFingerCall",
		soundID = "3895246074",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "StarFingerEffect",
		soundID = "88802652828110",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	local vfxId = HttpService:GenerateGUID(false)
	hitbox:SetAttribute("VFX_ID", vfxId)

	SpawnClientVfx:FireAllClients({
		type = "Attached",
		effectName = "StarFingerSlash",
		attachId = vfxId,

		initialRotation = Vector3.new(
			0, -- X
			0, -- Y
			0 -- Z
		),

		offset = CFrame.new(0, 0, -4),
		attachTo = hitbox,
		scale = Vector3.new(1, 1, 1),
	})
end

function StarPurple.TimeStop(caster)
	if not caster then
		return
	end

	local affectedPlayersVfx = {}

	local standModel = StandUtils.getStandModel(caster)

	print(caster.Name .. " has stopped time!")

	SoundModule.PlaySound({
		Root = caster:FindFirstChild("HumanoidRootPart"),
		soundName = "TimeStopSound",
		soundID = "6969510608",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 240,
	})

	timeStopBall(caster)

	local casterRoot = caster:FindFirstChild("HumanoidRootPart")
	if not casterRoot then
		return
	end

	local casterPlayer = Players:GetPlayerFromCharacter(caster)
	if casterPlayer then
		table.insert(affectedPlayersVfx, casterPlayer)
	end

	-- Freeze all players except caster
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char ~= caster and char:FindFirstChild("HumanoidRootPart") then
			local root = char.HumanoidRootPart
			local distance = (root.Position - casterRoot.Position).Magnitude

			if distance <= TIME_STOP_RANGE then
				CombatUtils.applyStun(char, STOP_DURATION)

				BlockModule.StopBlocking(char)
				CombatUtils.ApplyDamageMult(char, TIME_STOP_DAMAGE_MULT, STOP_DURATION)

				table.insert(affectedPlayersVfx, player)

				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = 0
					humanoid.JumpPower = 0

					local animator = humanoid:FindFirstChildOfClass("Animator")
					if animator then
						for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
							track:AdjustSpeed(0)
						end
					end

					if root then
						root.Anchored = true
						root:SetAttribute(IMMOBILE_ANCHOR_NAME, true)
					end
				end
			end
		end
	end

	for _, plr in ipairs(affectedPlayersVfx) do
		ScreenColorVfxEvent:FireClient(plr, "TimeStop.Start", STOP_DURATION)
	end

	-- Freeze all enemy NPCs
	for _, npc in ipairs(ENEMY_NPC_FOLDER:GetChildren()) do
		if
			npc:IsA("Model")
			and npc:FindFirstChild("Humanoid")
			and npc:FindFirstChild("HumanoidRootPart")
			and npc ~= caster
		then
			local root = npc:FindFirstChild("HumanoidRootPart")
			local distance = (root.Position - casterRoot.Position).Magnitude

			if distance <= TIME_STOP_RANGE then
				local humanoid = npc:FindFirstChildOfClass("Humanoid")
				local animator = humanoid:FindFirstChildOfClass("Animator")

				-- Stop animations and movement
				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0
				if animator then
					for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
						track:AdjustSpeed(0)
					end
				end
				root.Anchored = true
				root:SetAttribute(IMMOBILE_ANCHOR_NAME, true)

				CombatUtils.applyStun(npc, STOP_DURATION)

				CombatUtils.ApplyDamageMult(npc, 2, STOP_DURATION)
			end
		end
	end

	-- Resume everything after STOP_DURATION
	task.delay(STOP_DURATION, function()
		print("⏰ Time resumes for everyone.")

		-- Resume players
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				local root = char:FindFirstChild("HumanoidRootPart")

				if not root:GetAttribute(IMMOBILE_ANCHOR_NAME) then
					continue
				end

				if humanoid and player ~= Players:GetPlayerFromCharacter(caster) then
					local moveSpeed = char:FindFirstChild("MoveSpeed")
					local jumpHeight = char:FindFirstChild("JumpHeight")
					-- resume movement
					if moveSpeed then
						local baseSpeed = CombatUtils.GetMoveSpeed(char).Value
						local mult = CombatUtils.GetSlowMultiplier(char)
						humanoid.WalkSpeed = baseSpeed * mult
					end
					humanoid.JumpPower = jumpHeight and jumpHeight.Value or 40.996
				end

				if root and root:GetAttribute(IMMOBILE_ANCHOR_NAME) then
					root.Anchored = false
					root:SetAttribute(IMMOBILE_ANCHOR_NAME, nil)
				end

				local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
				if animator then
					for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
						track:AdjustSpeed(1)
					end
				end
			end
		end

		for _, plr in ipairs(affectedPlayersVfx) do
			ScreenColorVfxEvent:FireClient(plr, "TimeStop.End")
		end

		-- Resume NPCs
		for _, npc in ipairs(ENEMY_NPC_FOLDER:GetChildren()) do
			if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
				local humanoid = npc:FindFirstChildOfClass("Humanoid")
				local animator = humanoid:FindFirstChildOfClass("Animator")
				local root = npc:FindFirstChild("HumanoidRootPart")

				if not root:GetAttribute(IMMOBILE_ANCHOR_NAME) then
					continue
				end

				if humanoid then
					local moveSpeed = npc:FindFirstChild("MoveSpeed")
					-- resume movement
					if moveSpeed then
						local baseSpeed = CombatUtils.GetMoveSpeed(npc)
						local mult = CombatUtils.GetSlowMultiplier(npc)
						humanoid.WalkSpeed = baseSpeed * mult
					end

					humanoid.JumpPower = npc:FindFirstChild("JumpHeight").Value or 40.996
				end

				if root and root:GetAttribute(IMMOBILE_ANCHOR_NAME) then
					root.Anchored = false
					root:SetAttribute(IMMOBILE_ANCHOR_NAME, nil)
				end

				if animator then
					for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
						track:AdjustSpeed(1)
					end
				end
			end
		end
	end)
end

return StarPurple
