local KaiserQueen = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local StandUtils = require(ServerScriptService.BasicCombat.StandUtils)
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))

local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local BlockModule = require(game.ServerScriptService.BasicCombat:WaitForChild("BlockModule"))
local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))
local TandemModule = require(game.ServerScriptService.BasicCombat.StandModules:WaitForChild("TandemMode"))

local MACH_ORA_SIZE = Vector3.new(10, 6, 10)
local PLANT_BOMB_DAMAGE = 15
local PLANT_BOMB_OFFSET = Vector3.new(2, 0, -8)
local PLANT_BOMB_ENDLAG = 0.8
local PLANT_BOMB_STUN = 1.5
local PLANT_BOMB_DURATION = 1
local BOMB_STUN = 1.5

local BOMB_DAMAGE = 30
local BOMB_SIZE = Vector3.new(20, 20, 20)

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

local STARYCATBUBBLE_HITBOX_SIZE = Vector3.new(10, 6, 10)
local STARYCATBUBBLE_DAMAGE = 20
local STARYCATBUBBLE_DURATION = 3
local STARYCATBUBBLE_OFFSET = Vector3.new(0, 0, 8)
local STARYCATBUBBLE_ENDLAG = 0.8
local STARYCATBUBBLE_STUN = 1.5
local STARYCATBUBBLE_SPEED = 200

local STOP_DURATION = 3 -- seconds
local IMMOBILE_ANCHOR_NAME = "TheWorldTimeStopAnchor"
local TIME_STOP_DAMAGE_MULT = 1.25
local TIME_STOP_RANGE = 50

local ENEMY_NPC_FOLDER = game.Workspace:WaitForChild("NPCs"):WaitForChild("EnemyNPCs")

local SpawnClientVfx = ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")

local affectedPlayersVfx = {}

local function getBombFolder(character)
	local folder = character:FindFirstChild("ActiveBombs")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "ActiveBombs"
		folder.Parent = character
	end
	return folder
end

local function createBomb(character, position, attachedTo)
	local bombFolder = getBombFolder(character)

	local bomb = Instance.new("Part")
	bomb.Name = "KQ_Bomb"
	bomb.Size = Vector3.new(0.6, 0.6, 0.6)
	bomb.Transparency = 1
	bomb.Anchored = true
	bomb.CanCollide = false
	bomb.Position = position
	bomb.Parent = bombFolder

	-- If attached to a target, weld it
	if attachedTo then
		bomb.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = bomb
		weld.Part1 = attachedTo
		weld.Parent = bomb
	end

	return bomb
end

function KaiserQueen.DetonateBombs(standModel)
	local character = standModel.Parent
	local bombFolder = character:FindFirstChild("ActiveBombs")
	if not bombFolder then
		return false
	end

	local bombs = bombFolder:GetChildren()
	if #bombs == 0 then
		return false
	end

	for _, bomb in ipairs(bombs) do
		if bomb:IsA("BasePart") then
			local pos = bomb.Position

			-- Spawn explosion hitbox
			HitboxSpawner.spawnStationaryHitbox({
				Position = pos,
				Character = character,
				Damage = BOMB_DAMAGE or 25,
				Size = BOMB_SIZE or Vector3.new(10, 10, 10),
				Offset = CFrame.new(),
				Color = BrickColor.new("Bright red"),
				Duration = 0.25,
				StunDuration = BOMB_STUN or 2,
				Transparency = 0.5,
				Name = "KQ_BombExplosion",
			})

			bomb:Destroy()
		end
	end

	return true
end

function KaiserQueen.PlantBomb(standModel)
	local character = standModel.Parent

	-- If bombs exist → detonate instead
	local bombFolder = character:FindFirstChild("ActiveBombs")
	if bombFolder and #bombFolder:GetChildren() > 0 then
		return KaiserQueen.DetonateBombs(standModel)
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")

	AnimationModule.PlayAnimation(standModel, ERASE_ANIM_ID, false, Enum.AnimationPriority.Action, 1)
	--CombatUtils.SetActionInProgress(character, THROWKNIVES_ENDLAG)

	-- sfx
	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "PlantBombCall",
		soundID = "6665704220",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "PlantBombEffect",
		soundID = "6665704220",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
	})

	local hitbox = HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = PLANT_BOMB_DAMAGE or 0.1,
		Size = MACH_ORA_SIZE,
		Offset = CFrame.new(PLANT_BOMB_OFFSET),
		Color = BrickColor.new("Bright red"),
		Duration = PLANT_BOMB_DURATION,
		StunDuration = PLANT_BOMB_STUN,
		Transparency = 0.5,
		Name = "BasicPunchHitbox",
		RemoveOnStun = false,

		OnHit = function(targetChar)
			local bombPosition
			local attachedPart = nil

			if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
				-- 🎯 Attach bomb to target
				local targetHRP = targetChar.HumanoidRootPart
				bombPosition = targetHRP.Position
				attachedPart = targetHRP
			else
				-- 💣 Missed → place bomb in front of caster
				local forwardOffset = hrp.CFrame.LookVector * 5
				bombPosition = hrp.Position + forwardOffset
			end

			local bomb = createBomb(character, bombPosition, attachedPart)

			-- Optional debug
			print("Bomb planted:", bomb, attachedPart and "ON TARGET" or "ON GROUND")
		end,

		task.delay(PLANT_BOMB_DURATION, function()
			local bombFolder = character:FindFirstChild("ActiveBombs")
			if not bombFolder or #bombFolder:GetChildren() == 0 then
				-- No hits occurred → plant fallback bomb
				local forwardOffset = hrp.CFrame.LookVector * 5
				local fallbackPos = hrp.Position + forwardOffset
				createBomb(character, fallbackPos, nil)
			end
		end),
	})

	--allow for a second input to detonate the bomb if there is at least one bomb active
	--[[
	hitboxSpawner.spawnStationaryHitbox({
		Position = bombposition,
		Character = character,
		Damage = BARRIER_DAMAGE,
		Size = BARRIER_SIZE,
		Offset = hitBoxOffset,
		Color = BrickColor.new("Bright red"),
		Duration = 1,
		StunDuration = 2,
		Transparency = 1,
		Name = "BarragePunchHitbox",
	})
	]]

	return true
end

function KaiserQueen.SheerHeartAttack(standModel)
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

				HitboxSpawner.spawnStationaryHitbox({
					Position = targetRootPart.CFrame,
					Stand = standModel,
					Character = character,
					Damage = BLAZINGSTRIKE_KOCKBACK_DAMAGE,
					Size = BLAZINGSTRIKE_KOCKBACK_SIZE,
					Offset = BLAZINGSTRIKE_KOCKBACK_OFFSET,
					Color = BrickColor.new("Bright red"),
					Duration = 1,
					StunDuration = 1,
					Transparency = 0.3,
					Name = "BarrierDamageHitbox",
				})
			end)
		end,
	})
end

function KaiserQueen.StrayCatBubble(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	CombatUtils.SetActionInProgress(character, STARYCATBUBBLE_ENDLAG)

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

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "GuidedNailEffect",
		soundID = "89805684001014",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	local projectile = HitboxSpawner.spawnGuidedProjectile({
		Character = character,
		Size = STARYCATBUBBLE_HITBOX_SIZE,
		Damage = 25,
		Duration = 5,
		Speed = STARYCATBUBBLE_SPEED,
		Direction = direction,
		Origin = startPos,
		Offset = STARYCATBUBBLE_OFFSET,
		Color = BrickColor.new("Bright yellow"),
		Gravity = Vector3.new(0, 0, 0), -- optional tweak
		DetectSurface = true,
		CanBlock = false,
		Transparency = 1,

		OnSurfaceHit = function(projectile, hitResult, horizontalDirection)
			print("[GoldExperimentModule!!!] Projectile hit surface:", hitResult.Instance.Name)

			local hitBoxOffset = Vector3.new(0, 3, 0)

			-- Determine stationary hitbox position
			local hitPosition = hitResult.Position

			-- Spawn a stationary damage hitbox
			local explosion = HitboxSpawner.spawnStationaryHitbox({
				Position = hitPosition,
				Character = character,
				Size = STARYCATBUBBLE_HITBOX_SIZE,
				Damage = STARYCATBUBBLE_DAMAGE,
				Offset = hitBoxOffset,
				Color = BrickColor.new("Bright red"),
				Duration = 1,
				StunDuration = 0,
				Transparency = 1,
				Name = "GuidedNailAOEHitbox",
				Rotation = horizontalDirection, -- ensures horizontal facing of projectile
				Shape = Enum.PartType.Ball,
			})

			SpawnClientVfx:FireAllClients({
				type = "Stationary",
				effectName = "GuidedNailExplosion",

				-- Position
				cframe = CFrame.new(explosion.Position),

				-- Lifetime
				lifetime = 1,

				-- Visual style
				scale = 1, -- starting size
			})
		end,
	})

	local vfxId = HttpService:GenerateGUID(false)
	projectile:SetAttribute("VFX_ID", vfxId)

	SpawnClientVfx:FireAllClients({
		type = "Attached",
		effectName = "GuidedNail",
		attachId = vfxId,
		scale = STARYCATBUBBLE_HITBOX_SIZE,
		attachTo = projectile,
	})

	return true
end

function KaiserQueen.BitesTheDust(caster)
	if not caster then
		return
	end

	local standModel = StandUtils.getStandModel(caster)

	print(caster.Name .. " has stopped time!")

	SoundModule.PlaySound({
		Root = caster:FindFirstChild("HumanoidRootPart"),
		soundName = "TimeStopSound",
		soundID = "6969510608",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
	})

	HitboxSpawner.spawnStationaryHitbox({
		Position = caster.PrimaryPart.CFrame,
		Stand = standModel,
		Character = caster,
		Damage = 0,
		Size = Vector3.new(100, 100, 100),
		Offset = Vector3.new(0, 0, 0),
		Color = BrickColor.new("White"),
		Duration = 1,
		StunDuration = 0,
		Transparency = 0.8,
		Name = "TimeStopRangeHitbox",
	})

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
		--TimeStopVfxEvent:FireClient(plr, "Start", STOP_DURATION)
	end

	-- Freeze all enemy NPCs
	for _, npc in ipairs(ENEMY_NPC_FOLDER:GetChildren()) do
		if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
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
			--TimeStopVfxEvent:FireClient(plr, "End")
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

return KaiserQueen
