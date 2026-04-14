local TheWorld = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local StandUtils = require(ServerScriptService.BasicCombat.StandUtils)
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local BlockModule = require(game.ServerScriptService.BasicCombat:WaitForChild("BlockModule"))
local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))
local TandemModule = require(game.ServerScriptService.BasicCombat.StandModules:WaitForChild("TandemMode"))

local ERASE_ENDLAG = 1

local THROWKNIVES_HITBOX_SIZE = Vector3.new(10, 6, 10)
local THROWKNIVES_DAMAGE = 20
local THROWKNIVES_DURATION = 3
local THROWKNIVES_OFFSET = Vector3.new(0, 0, 8)
local THROWKNIVES_ENDLAG = 0.8
local THROWKNIVES_STUN = 1.5
local THROWKNIVES_SPEED = 200

local BLAZINGSTRIKE_DAMAGE = 15
local BLAZINGSTRIKE_SIZE = Vector3.new(5, 7, 18)
local BLAZINGSTRIKE_OFFSET = Vector3.new(2, 0, -14)
local BLAZINGSTRIKE_ENDLAG = 1
local BLAZINGSTRIKE_STUN = 1.5

local ERASE_ANIM_ID = 90498591949232

local BLAZINGSTRIKE_KNOCKBACK_SPEED = 60
local BLAZINGSTRIKE_KNOCKBACK_DURATION = 1

local BLAZINGSTRIKE_KOCKBACK_DAMAGE = 15
local BLAZINGSTRIKE_KOCKBACK_SIZE = Vector3.new(20, 20, 20)
local BLAZINGSTRIKE_KOCKBACK_OFFSET = Vector3.new(0, 0, 0)

local TIME_STOP_BASE_DURATION = 3 -- seconds
local TIME_STOP_DURATION_SCALING = 0.1
local IMMOBILE_ANCHOR_NAME = "TheWorldTimeStopAnchor"
local TIME_STOP_DAMAGE_MULT = 0.8
local TIME_STOP_RANGE = 50

local ENEMY_NPC_FOLDER = game.Workspace:WaitForChild("NPCs"):WaitForChild("EnemyNPCs")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpawnClientVfx = ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")

local ScreenColorVfxEvent = ReplicatedStorage.UIs.RemoteEvents:WaitForChild("ScreenColorVfx")

local function ClientKnives(player, origin, direction)
	print("local function client knives start")
	SpawnClientVfx:FireAllClients({
		type = "Projectile",
		effectName = "ThrowKnives",
		origin = origin,
		direction = direction,
		speed = THROWKNIVES_SPEED,
		lifetime = THROWKNIVES_DURATION,
	})
	print("local function client knives end")
end

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

function TheWorld.ThrowKnives(standModel)
	local character = standModel.Parent
	local hrp = character:FindFirstChild("HumanoidRootPart")

	AnimationModule.PlayAnimation(standModel, ERASE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, THROWKNIVES_ENDLAG)

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "KnifeThrowCall",
		soundID = "6665704220",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "KnifeThrowEffect",
		soundID = "5789211405",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
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
		Damage = THROWKNIVES_DAMAGE,
		Size = THROWKNIVES_HITBOX_SIZE,
		Offset = THROWKNIVES_OFFSET,
		Color = BrickColor.new("Bright red"),
		Duration = THROWKNIVES_DURATION,
		StunDuration = THROWKNIVES_STUN,
		Transparency = 1,
		Name = "BarragePunchHitbox",
		Speed = THROWKNIVES_SPEED,
		Direction = direction,
		Origin = startPos,
	})
	print("Before clientKnives")
	ClientKnives(player, hrp.Position, direction)
	print("after client knives")
	return true
end

function TheWorld.BlazingStrike(standModel)
	local character = standModel.Parent

	AnimationModule.PlayAnimation(standModel, ERASE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, BLAZINGSTRIKE_ENDLAG)

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "BlazingStrikeCall",
		soundID = "135072981745363",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "BlazingStrikeEffect",
		soundID = "6185097708",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = BLAZINGSTRIKE_DAMAGE or 0.1,
		Size = BLAZINGSTRIKE_SIZE,
		Offset = CFrame.new(BLAZINGSTRIKE_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = 0.75,
		StunDuration = BLAZINGSTRIKE_STUN,
		Transparency = 1,
		Name = "BlazingStrikeHitbox",
		CanBlock = false,

		OnHit = function(targetChar, newDamage)
			local hitHumanoid = targetChar:FindFirstChild("Humanoid")
			local targetRootPart = targetChar:FindFirstChild("HumanoidRootPart")
			local attackerRoot = character:FindFirstChild("HumanoidRootPart")

			if not (hitHumanoid and targetRootPart and attackerRoot) then
				return
			end

			-- Lock rotation
			hitHumanoid.AutoRotate = false

			local rootJoint = targetRootPart:FindFirstChild("RootJoint")
			local originalC0 = rootJoint and rootJoint.C0

			-- 🔹 Horizontal-only knockback direction
			-- Forward-based knockback (NOT radial)
			local worldDirection = attackerRoot.CFrame.LookVector
			worldDirection = Vector3.new(worldDirection.X, 0, worldDirection.Z).Unit

			-- Convert WORLD → TARGET LOCAL
			local localDirection = targetRootPart.CFrame:VectorToObjectSpace(worldDirection)

			CombatUtils.ApplyTurningVelocity({
				Character = targetChar,
				Speed = BLAZINGSTRIKE_KNOCKBACK_SPEED,
				Duration = BLAZINGSTRIKE_KNOCKBACK_DURATION,
				Name = "BlazingStrikeVelocity",
				Direction = localDirection,
			})

			-- Restore rotation
			task.delay(BLAZINGSTRIKE_KNOCKBACK_DURATION, function()
				if hitHumanoid then
					hitHumanoid.AutoRotate = true
				end
				if rootJoint and originalC0 then
					rootJoint.C0 = originalC0
				end

				local hitbox = HitboxSpawner.spawnStationaryHitbox({
					Position = targetRootPart.CFrame,
					Stand = standModel,
					Character = character,
					Damage = BLAZINGSTRIKE_KOCKBACK_DAMAGE,
					Size = BLAZINGSTRIKE_KOCKBACK_SIZE,
					Offset = BLAZINGSTRIKE_KOCKBACK_OFFSET,
					Color = BrickColor.new("Bright red"),
					Duration = 1,
					StunDuration = 1,
					Transparency = 1,
					Name = "BarrierDamageHitbox",
				})

				SpawnClientVfx:FireAllClients({
					type = "Stationary",
					effectName = "GroundPound",

					-- Position
					cframe = hitbox.CFrame,

					-- Lifetime
					lifetime = 1,

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
					maxScale = 1.5,
				})
			end)
		end,
	})
end

function TheWorld.KickBarrage(standModel)
	local character = standModel.Parent

	--CombatUtils.SetActionInProgress(character, TEAR_SPACE_DURATION)

	AnimationModule.StopAllAnimations(standModel)
	AnimationModule.PlayAnimationThenIdle(standModel, ERASE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "KickBarrageCall",
		soundID = "2553980292",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	TandemModule.EnterTandemMode(character, standModel)
	task.wait(3)
	TandemModule.ExitTandemMode(character)
end

function TheWorld.TimeStop(caster)
	if not caster then
		return
	end

	local affectedPlayersVfx = {}

	local standModel = StandUtils.getStandModel(caster)

	print(caster.Name .. " has stopped time!")

	SoundModule.PlaySound({
		Root = caster:FindFirstChild("HumanoidRootPart"),
		soundName = "TimeStopEffects",
		soundID = "119688469417636",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
	})

	SoundModule.PlaySound({
		Root = caster:FindFirstChild("HumanoidRootPart"),
		soundName = "TimeStopCall",
		soundID = "4523066727",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
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

	local power = CombatUtils.GetPower(casterPlayer)
	local amplifiedDuration = TIME_STOP_BASE_DURATION
	if power > 0 then
		amplifiedDuration = power * TIME_STOP_DURATION_SCALING + TIME_STOP_BASE_DURATION
	end

	-- Freeze all players except caster
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char ~= caster and char:FindFirstChild("HumanoidRootPart") then
			local root = char.HumanoidRootPart
			local distance = (root.Position - casterRoot.Position).Magnitude

			if distance <= TIME_STOP_RANGE then
				CombatUtils.applyStun(char, amplifiedDuration)

				BlockModule.StopBlocking(char)
				CombatUtils.ApplyDamageMult(char, TIME_STOP_DAMAGE_MULT, amplifiedDuration)

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
		ScreenColorVfxEvent:FireClient(plr, "TimeStop.Start", amplifiedDuration)
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

				CombatUtils.applyStun(npc, amplifiedDuration)

				CombatUtils.ApplyDamageMult(npc, 2, amplifiedDuration)
			end
		end
	end

	-- Resume everything after STOP_DURATION
	task.delay(amplifiedDuration, function()
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

return TheWorld
