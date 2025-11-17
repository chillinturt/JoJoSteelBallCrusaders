local StarPurple = {}

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local BlockModule = require(game.ServerScriptService.BasicCombat:WaitForChild("BlockModule"))
local TeamsModule =
	require(game.ServerScriptService:WaitForChild("BasicCombat"):WaitForChild("Managers"):WaitForChild("TeamsModule"))

local cooldownTime = 8 -- MachOra cooldown in seconds
local machOra2Delay = 0.6 -- Time after MachOra before MachOra2 can be used
local machOra2Cooldown = 8 -- MachOra2 cooldown after use
local lastMachOraUse = {} -- Tracks last activation time per player
local lastMachOra2Use = {} -- Tracks last use time for MachOra2 per player
local machOra2Window = {} -- Stores the short window where MachOra2 is valid

local MACH_ORA_DAMAGE = 12
local MACH_ORA_DASH_SPEED = 50 -- Speed of the dash
local MACH_ORA_DASH_DURATION = 0.4 -- How long the dash lasts in seconds
local MACH_ORA_ENDLAG = 0.4
local MACH_ORA_SIZE = Vector3.new(5, 6, 9)
local MACH_ORA_OFFSET = Vector3.new(2, 0, -8)
local MACH_ORA_STUN = 1.5

local GROUND_POUND_DAMAGE = 15
local GROUND_POUND_SIZE = Vector3.new(10, 10, 10)
local GROUND_POUND_OFFSET = Vector3.new(2, 0, -10)
local GROUND_POUND_ENDLAG = 1

local GROUNDPOUND_ANIM_ID = 90498591949232

local STARFINGER_DAMAGE = 15
local STARFINGER_SIZE = Vector3.new(5, 7, 18)
local STARFINGER_OFFSET = Vector3.new(2, 0, -14)
local STARFINGER_ENDLAG = 1
local STARFINGER_STUN = 1.5

local HIT_SOUND_ID = 8255306220
local BLOCK_SOUND_ID = 132615624053575

-- CONFIG
local STOP_DURATION = 3 -- seconds
local IMMOBILE_ANCHOR_NAME = "TimeStopAnchor"
local TIME_STOP_DAMAGE_MULT = 1.25

local ENEMY_NPC_FOLDER = game.Workspace:WaitForChild("NPCs"):WaitForChild("EnemyNPCs")

local function MapDamageToSound(damage: number)
	-- Clamp damage to a reasonable range (so extreme values don’t explode)
	local minDamage, maxDamage = 0, 50
	damage = math.clamp(damage, minDamage, maxDamage)

	-- Normalize to 0–1
	local t = (damage - minDamage) / (maxDamage - minDamage)

	-- Lerp volume (directly proportional)
	local minVolume, maxVolume = 0.1, 2
	local volume = minVolume + (maxVolume - minVolume) * t

	-- Lerp pitch (inversely proportional)
	local minPitch, maxPitch = 0.1, 2.0
	local pitch = maxPitch - (maxPitch - minPitch) * t

	return volume, pitch
end

--[[
local function spawnHitbox(character, offset, rightOffset, upOffset, damage)
	-- Locate the stand model
	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		warn("⚠️ No stand model found for", character.Name)
		return
	end

	-- Locate the stand’s PrimaryPart
	local standRoot = standModel.PrimaryPart
	if not standRoot then
		warn("⚠️ No PrimaryPart found in stand model!")
		return
	end

	-- Calculate offset position
	local forwardDirection = standRoot.CFrame.LookVector
	local rightDirection = standRoot.CFrame.RightVector
	local upDirection = standRoot.CFrame.UpVector

	local positionInFront = standRoot.Position
		+ (forwardDirection * offset)
		+ (rightDirection * rightOffset)
		+ (upDirection * upOffset)

	-- Create hitbox
	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Size = MACH_ORA_SIZE
	hitbox.Anchored = false
	hitbox.CanCollide = false
	hitbox.CanTouch = false
	hitbox.Massless = true
	hitbox.Transparency = 0.5
	hitbox.BrickColor = BrickColor.new("Bright red")
	hitbox.CFrame = CFrame.new(positionInFront, positionInFront + forwardDirection)
	hitbox.Parent = workspace

	-- Weld to stand
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = standRoot
	weld.Part1 = hitbox
	weld.Parent = hitbox

	-- Hit tracking
	local hitPlayers = {}
	local paramsFilter = OverlapParams.new()
	paramsFilter.FilterType = Enum.RaycastFilterType.Exclude
	paramsFilter.FilterDescendantsInstances = { character, hitbox }

	-- Timer
	local startTime = tick()
	local duration = 0.4 -- matches Debris lifetime
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		if elapsed > duration then
			conn:Disconnect()
			if hitbox then
				hitbox:Destroy()
			end
			return
		end

		-- Overlap check
		local parts = workspace:GetPartBoundsInBox(hitbox.CFrame, hitbox.Size, paramsFilter)
		for _, other in ipairs(parts) do
			if other.Name == "Hurtbox" then
				local targetCharacter = other.Parent
				if targetCharacter and targetCharacter ~= character then
					local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")

					-- Redirect stand hitboxes back to owner
					if not humanoid then
						local standOwner = targetCharacter.Parent
						if standOwner and standOwner:IsA("Model") then
							humanoid = standOwner:FindFirstChildOfClass("Humanoid")
							targetCharacter = standOwner
							print("✅ Redirecting damage to:", targetCharacter.Name)
						end
					end

					if TeamsModule.AreTeammates(targetCharacter, character) then
						print("Both are on the same team. Not dealing damage")
						return
					end

					if humanoid and not hitPlayers[targetCharacter.Name] then
						hitPlayers[targetCharacter.Name] = true

						local newDamage = CombatUtils.ReturnDamage(targetCharacter, damage, true, character)
						humanoid:TakeDamage(newDamage)

						local volume, pitch = MapDamageToSound(damage)

						if not CombatUtils.GetIsBlocking(targetCharacter).Value then
							SoundModule.PlaySound({
								Root = targetCharacter,
								soundName = "HitSound",
								soundID = HIT_SOUND_ID,
								volume = volume,
								playbackSpeed = 1,
								looped = false,
								range = 160,
								pitch = pitch,
							})
						else
							SoundModule.PlaySound({
								Root = targetCharacter,
								soundName = "BlockHitSound",
								soundID = BLOCK_SOUND_ID,
								volume = 1,
								playbackSpeed = 1,
								looped = false,
								range = 160,
							})
						end

						print(targetCharacter.Name .. " was hit for " .. newDamage .. " damage!")

						-- Destroy MachOraVelocity if it exists
						local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
						if humanoidRootPart then
							local machOraVelocity = humanoidRootPart:FindFirstChild("MachOraVelocity")
							if machOraVelocity then
								machOraVelocity:Destroy()
								print("MachOraVelocity has been destroyed!")
							end
						end
					end
				end
			end
		end
	end)

	Debris:AddItem(hitbox, duration)
	return hitbox
end
]]

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

	-- Check MachOra cooldown
	local currentTime = tick()
	local lastUseTime = lastMachOraUse[character] or 0
	if currentTime - lastUseTime < cooldownTime then
		local remainingTime = cooldownTime - (currentTime - lastUseTime)
		print(
			character.Name .. " tried to use MachOra but is on cooldown! Time left: " .. math.ceil(remainingTime) .. "s"
		)
		return
	end

	-- ✅ Set cooldown & prevent MachOra2 until its window opens
	lastMachOraUse[character] = currentTime
	machOra2Window[character] = nil -- Reset window until enabled

	-- Locate the stand
	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		warn("⚠️ No summoned stand model found for", character.Name)
		return
	else
		local standName = standModel:FindFirstChild("StandTag").Value
		if standName ~= "Star Purple" then
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
	AnimationModule.PlayAnimation(standModel, 117096419135889, false, Enum.AnimationPriority.Action, 1)

	-- ✅ Enable MachOra2 only within 0.6s window
	task.delay(machOra2Delay, function()
		machOra2Window[character] = { start = tick(), duration = 2 }
	end)

	-- ⏳ Wait 0.6s, then play punch animation & sound
	task.wait(0.2)
	--hitbox spawn
	--spawnHitbox(character, 5, 2, 0, MACH_ORA_DAMAGE)
	HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = MACH_ORA_DAMAGE or 0.1,
		Size = MACH_ORA_SIZE,
		Offset = CFrame.new(MACH_ORA_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = 0.75,
		StunDuration = MACH_ORA_STUN,
		Transparency = 1,
		Name = "BasicPunchHitbox",

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

	-- Fire second animation (idle)
	AnimationModule.PlayAnimation(standModel, 89452205434139, false, Enum.AnimationPriority.Action, 1)
end

function StarPurple.onMachOra2Requested(character)
	-- ✅ Check if MachOra2 has been enabled in the window
	local currentTime = tick()
	local lastMachOra2Time = lastMachOra2Use[character] or 0
	local window = machOra2Window[character]

	-- 🔒 Reject if MachOra2 is on cooldown
	if currentTime - lastMachOra2Time < machOra2Cooldown then
		return
	end

	-- 🔒 Reject if the window is not active or expired
	if not window or currentTime > (window.start + window.duration) then
		return
	end

	-- ✅ Allow MachOra2 & start cooldown
	print("MachOra2 Fired On Server for", character.Name)
	lastMachOra2Use[character] = currentTime -- Start cooldown
	machOra2Window[character] = nil -- Disable future MachOra2 usage until MachOra is used again

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
	AnimationModule.PlayAnimation(standModel, 116753187024506, false, Enum.AnimationPriority.Action, 1)

	--momentum
	applyMachOraDash(character)

	--hitbox spawn
	--spawnHitbox(character, 5, 2, 0, MACH_ORA_DAMAGE)
	HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = MACH_ORA_DAMAGE or 0.1,
		Size = MACH_ORA_SIZE,
		Offset = CFrame.new(MACH_ORA_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = 0.75,
		StunDuration = MACH_ORA_STUN,
		Transparency = 1,
		Name = "BasicPunchHitbox",

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

	-- ⏳ Wait 0.6s, then fire idle animation
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

	-- Fire animation
	AnimationModule.PlayAnimation(standModel, 89452205434139, false, Enum.AnimationPriority.Action, 1)
end

function StarPurple.GroundPound(standModel)
	local character = standModel.Parent

	AnimationModule.PlayAnimation(standModel, GROUNDPOUND_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, GROUND_POUND_ENDLAG)

	task.wait(0.5)

	HitboxSpawner.spawnStationaryHitbox({
		Position = standModel.PrimaryPart.CFrame,
		Stand = standModel,
		Character = character,
		Damage = GROUND_POUND_DAMAGE,
		Size = GROUND_POUND_SIZE,
		Offset = GROUND_POUND_OFFSET,
		Color = BrickColor.new("Bright red"),
		Duration = 1,
		StunDuration = 1,
		Transparency = 0.3,
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
end

function StarPurple.StarFinger(standModel)
	local character = standModel.Parent

	AnimationModule.PlayAnimation(standModel, GROUNDPOUND_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, STARFINGER_ENDLAG)

	HitboxSpawner.spawnHitbox({
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
end

function StarPurple.TimeStop(caster)
	if not caster then
		return
	end

	print(caster.Name .. " has stopped time!")

	SoundModule.PlaySound({
		Root = caster:FindFirstChild("HumanoidRootPart"),
		soundName = "TimeStopSound",
		soundID = "6969510608",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})

	-- Freeze all players except caster
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char ~= caster and char:FindFirstChild("HumanoidRootPart") then
			CombatUtils.applyStun(char, STOP_DURATION)

			BlockModule.StopBlocking(char)
			CombatUtils.ApplyDamageMult(char, TIME_STOP_DAMAGE_MULT, STOP_DURATION)

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

				local root = char:FindFirstChild("HumanoidRootPart")
				if root then
					root.Anchored = true
					root:SetAttribute(IMMOBILE_ANCHOR_NAME, true)
				end
			end
		end
	end

	-- Freeze all enemy NPCs
	for _, npc in ipairs(ENEMY_NPC_FOLDER:GetChildren()) do
		if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
			local humanoid = npc:FindFirstChildOfClass("Humanoid")
			local animator = humanoid:FindFirstChildOfClass("Animator")
			local root = npc:FindFirstChild("HumanoidRootPart")

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

	-- Resume everything after STOP_DURATION
	task.delay(STOP_DURATION, function()
		print("⏰ Time resumes for everyone.")

		-- Resume players
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				local root = char:FindFirstChild("HumanoidRootPart")

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

		-- Resume NPCs
		for _, npc in ipairs(ENEMY_NPC_FOLDER:GetChildren()) do
			if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
				local humanoid = npc:FindFirstChildOfClass("Humanoid")
				local animator = humanoid:FindFirstChildOfClass("Animator")
				local root = npc:FindFirstChild("HumanoidRootPart")

				if humanoid then
					local moveSpeed = npc:FindFirstChild("MoveSpeed")
					-- resume movement
					if moveSpeed then
						local baseSpeed = CombatUtils.GetMoveSpeed(npc).Value
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
