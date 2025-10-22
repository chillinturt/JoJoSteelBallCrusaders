local HitboxSpawner = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local ProjectileManager = require(
	game.ServerScriptService:WaitForChild("BasicCombat"):WaitForChild("Managers"):WaitForChild("ProjectileManager")
)
local TeamsModule =
	require(game.ServerScriptService:WaitForChild("BasicCombat"):WaitForChild("Managers"):WaitForChild("TeamsModule"))

local Debris = game:GetService("Debris")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundUtils = require(ServerScriptService.Utilities.SoundUtils)

local activeFields = {} -- [player] = { [field] = true, ... }

local STUN_ANIMATION_ID = 107701450018900
local HIT_SOUND_ID = 8255306220
local BLOCK_SOUND_ID = 132615624053575

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

-- Utility function to detect overlaps
local function getOverlappingCharacters(part, overlapParams)
	local parts = workspace:GetPartsInPart(part, overlapParams)
	local characters = {}
	for _, p in ipairs(parts) do
		local char = p:FindFirstAncestorOfClass("Model")
		if char and char:FindFirstChild("Humanoid") then
			characters[char] = true
		end
	end
	return characters
end

local function tagHumanoid(humanoid, player)
	-- Remove old tag
	local creatorTag = humanoid:FindFirstChild("creator")
	if creatorTag then
		creatorTag:Destroy()
	end

	-- Create new tag
	creatorTag = Instance.new("ObjectValue")
	creatorTag.Name = "creator"
	creatorTag.Value = player
	creatorTag.Parent = humanoid

	-- Optional: auto-remove after some seconds (so old tags don’t stick forever)
	game.Debris:AddItem(creatorTag, 2)
end

--spawn a welded hitbox
function HitboxSpawner.spawnHitbox(params)
	local character = params.Character
	local damage = params.Damage or 10
	local size = params.Size or Vector3.new(4, 4, 7)
	local offset = params.Offset or CFrame.new(2, 0, -8)
	local color = params.Color or BrickColor.new("Bright yellow")
	local duration = params.Duration or 0.3
	local stunDuration = params.StunDuration
	local transparency = params.Transparency or 0.5
	local name = params.Name or "PunchHitbox"
	local damagePerTick = params.DamagePerTick
	local DOTTickInterval = params.DOTTickInterval
	local DOTDuration = params.DOTDuration

	if not character then
		return
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel or not standModel.PrimaryPart then
		warn("⚠️ No valid stand model found for", character.Name)
		return
	end

	local standRoot = standModel.PrimaryPart

	-- Create the hitbox
	local hitbox = Instance.new("Part")
	hitbox.Name = name
	hitbox.Size = size
	hitbox.CFrame = standRoot.CFrame * offset
	hitbox.Anchored = false
	hitbox.CanCollide = false
	hitbox.Massless = true
	hitbox.Transparency = transparency
	hitbox.BrickColor = color
	hitbox.Parent = standRoot
	hitbox.CastShadow = false

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = standRoot
	weld.Part1 = hitbox
	weld.Parent = hitbox

	-- Overlap setup
	local paramsFilter = OverlapParams.new()
	paramsFilter.FilterType = Enum.RaycastFilterType.Exclude
	paramsFilter.FilterDescendantsInstances = { character, hitbox }

	local hitPlayers = {}
	local startTime = tick()

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

		-- Check overlaps every frame
		local parts = workspace:GetPartBoundsInBox(hitbox.CFrame, hitbox.Size, paramsFilter)
		for _, other in ipairs(parts) do
			if other.Name == "Hurtbox" then
				local targetChar = other.Parent

				if targetChar and targetChar ~= character then
					local humanoid = targetChar:FindFirstChildOfClass("Humanoid")

					if not humanoid then
						local owner = targetChar.Parent
						if owner and owner:IsA("Model") then
							humanoid = owner:FindFirstChildOfClass("Humanoid")
							targetChar = owner
						end
					end

					if TeamsModule.AreTeammates(targetChar, character) then
						print("Both are on the same team. Not dealing damage")
						return
					end

					if humanoid and not hitPlayers[targetChar.Name] then
						local player = Players:GetPlayerFromCharacter(character)
						if player then
							tagHumanoid(humanoid, player)
						end

						hitPlayers[targetChar.Name] = true
						local newDamage = CombatUtils.ReturnDamage(targetChar, damage)
						humanoid:TakeDamage(newDamage)

						local sourcePlayer = Players:GetPlayerFromCharacter(character)

						--apply damage over time here
						if damagePerTick then
							HitboxSpawner.ApplyDamageOverTime(
								humanoid,
								damagePerTick,
								DOTTickInterval,
								DOTDuration,
								sourcePlayer
							)
							print("DOT Applied!")
						end

						if not CombatUtils.GetIsBlocking(targetChar).Value then
							if stunDuration then
								CombatUtils.applyStun(targetChar, stunDuration)
							end
							AnimationModule.PlayAnimation(targetChar, STUN_ANIMATION_ID)

							local volume, pitch = MapDamageToSound(damage)

							SoundUtils.PlaySound({
								Root = targetChar,
								soundName = "HitSound",
								soundID = HIT_SOUND_ID,
								volume = volume,
								playbackSpeed = 1,
								looped = false,
								range = 160,
								pitch = pitch,
							})
						else
							SoundUtils.PlaySound({
								Root = targetChar,
								soundName = "BlockHitSound",
								soundID = BLOCK_SOUND_ID,
								volume = 1,
								playbackSpeed = 1,
								looped = false,
								range = 160,
							})
						end
					end
				end
			end
		end
	end)

	Debris:AddItem(hitbox, duration)
	return hitbox
end

function HitboxSpawner.spawnStandOffHitbox(params)
	local character = params.Character
	local damage = params.Damage or 10
	local size = params.Size or Vector3.new(4, 4, 7)
	local offset = params.Offset or CFrame.new(2, 0, -8)
	local color = params.Color or BrickColor.new("Bright yellow")
	local duration = params.Duration or 0.3
	local stunDuration = params.StunDuration
	local transparency = params.Transparency or 0.5
	local name = params.Name or "PunchHitbox"

	if not character then
		return
	end

	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	-- Create the hitbox
	local hitbox = Instance.new("Part")
	hitbox.Name = name
	hitbox.Size = size
	hitbox.CFrame = humanoidRootPart.CFrame * offset
	hitbox.Anchored = false
	hitbox.CanCollide = false
	hitbox.Massless = true
	hitbox.Transparency = transparency
	hitbox.BrickColor = color
	hitbox.Parent = humanoidRootPart

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = humanoidRootPart
	weld.Part1 = hitbox
	weld.Parent = hitbox

	-- Overlap setup
	local paramsFilter = OverlapParams.new()
	paramsFilter.FilterType = Enum.RaycastFilterType.Exclude
	paramsFilter.FilterDescendantsInstances = { character, hitbox }

	local hitPlayers = {}
	local startTime = tick()

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

		-- Check overlaps every frame
		local parts = workspace:GetPartBoundsInBox(hitbox.CFrame, hitbox.Size, paramsFilter)
		for _, other in ipairs(parts) do
			if other.Name == "Hurtbox" then
				local targetChar = other.Parent
				if targetChar and targetChar ~= character then
					local humanoid = targetChar:FindFirstChildOfClass("Humanoid")

					if not humanoid then
						local owner = targetChar.Parent
						if owner and owner:IsA("Model") then
							humanoid = owner:FindFirstChildOfClass("Humanoid")
							targetChar = owner
						end
					end

					if TeamsModule.AreTeammates(targetChar, character) then
						print("Both are on the same team. Not dealing damage")
						return
					end

					if humanoid and not hitPlayers[targetChar.Name] then
						local player = Players:GetPlayerFromCharacter(character)
						if player then
							tagHumanoid(humanoid, player)
						end

						hitPlayers[targetChar.Name] = true
						local newDamage = CombatUtils.ReturnDamage(targetChar, damage)
						humanoid:TakeDamage(newDamage)

						if not CombatUtils.GetIsBlocking(targetChar).Value then
							CombatUtils.applyStun(targetChar, stunDuration)
							AnimationModule.PlayAnimation(targetChar, STUN_ANIMATION_ID)

							local volume, pitch = MapDamageToSound(damage)

							SoundUtils.PlaySound({
								Root = targetChar,
								soundName = "HitSound",
								soundID = HIT_SOUND_ID,
								volume = volume,
								playbackSpeed = 1,
								looped = false,
								range = 160,
								pitch = pitch,
							})
						else
							SoundUtils.PlaySound({
								Root = targetChar,
								soundName = "BlockHitSound",
								soundID = BLOCK_SOUND_ID,
								volume = 1,
								playbackSpeed = 1,
								looped = false,
								range = 160,
							})
						end
					end
				end
			end
		end
	end)

	Debris:AddItem(hitbox, duration)
	return hitbox
end

--[[
function HitboxSpawner.spawnProjectile(params)
	-- Validate required parameters
	assert(params.Stand, "Origin (a Model with PrimaryPart) is required")
	assert(params.Size, "Size (Vector3) is required")
	assert(params.Duration, "Duration (number) is required")

	local stand = params.Stand
	local character = params.Character
	local damage = params.Damage or 0
	local stunDuration = params.StunDuration
	local size = params.Size
	local offset = params.Offset or Vector3.new()
	local color = params.Color or BrickColor.new("Really red")
	local duration = params.Duration
	local transparency = params.Transparency or 0
	local name = params.Name or "Hitbox"
	local speed = params.Speed or 50

	-- Create the hitbox part (invisible placeholder, or you can make it visible for debugging)
	local hitbox = Instance.new("Part")
	hitbox.Name = name
	hitbox.Size = size
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanQuery = false
	hitbox.CanTouch = false -- no longer using .Touched
	hitbox.Transparency = transparency
	hitbox.BrickColor = color
	hitbox.CFrame = stand:GetPivot() * CFrame.new(offset)
	hitbox.Parent = workspace

	-- Movement parameters
	local direction = stand:GetPivot().LookVector

	-- Setup overlap params (ignore the attacker and hitbox itself)
	local paramsFilter = OverlapParams.new()
	paramsFilter.FilterType = Enum.RaycastFilterType.Exclude
	paramsFilter.FilterDescendantsInstances = { character, hitbox }

	-- Track who was hit already
	local hitPlayers = {}

	-- Time tracking
	local startTime = tick()
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		local elapsed = tick() - startTime
		if elapsed > duration then
			conn:Disconnect()
			hitbox:Destroy()
			return
		end

		-- Move smoothly
		local step = direction * speed * dt
		hitbox.CFrame = hitbox.CFrame + step

		-- Query overlaps
		local parts = workspace:GetPartBoundsInBox(hitbox.CFrame, hitbox.Size, paramsFilter)
		for _, other in ipairs(parts) do
			if other.Name == "Hurtbox" then
				local targetChar = other.Parent
				if targetChar and targetChar ~= character then
					local humanoid = targetChar:FindFirstChildOfClass("Humanoid")

					if not humanoid then
						local owner = targetChar.Parent
						if owner and owner:IsA("Model") then
							humanoid = owner:FindFirstChildOfClass("Humanoid")
							targetChar = owner
						end
					end

					if humanoid and not hitPlayers[targetChar.Name] then
						local player = Players:GetPlayerFromCharacter(character)
						if player then
							tagHumanoid(humanoid, player)
						end

						hitPlayers[targetChar.Name] = true
						local newDamage = CombatUtils.ReturnDamage(targetChar, damage)
						humanoid:TakeDamage(newDamage)

						if not CombatUtils.GetIsBlocking(targetChar).Value then
							CombatUtils.applyStun(targetChar, stunDuration)
							AnimationModule.PlayAnimation(targetChar, STUN_ANIMATION_ID)

							local volume, pitch = MapDamageToSound(damage)

							SoundUtils.PlaySound({
								Root = targetChar,
								soundName = "HitSound",
								soundID = HIT_SOUND_ID,
								volume = volume,
								playbackSpeed = 1,
								looped = false,
								range = 160,
								pitch = pitch,
							})
						else
							SoundUtils.PlaySound({
								Root = targetChar,
								soundName = "BlockHitSound",
								soundID = BLOCK_SOUND_ID,
								volume = 1,
								playbackSpeed = 1,
								looped = false,
								range = 160,
							})
						end
					end
				end
			end
		end
	end)

	return hitbox
end
]]

function HitboxSpawner.spawnProjectile(params)
	assert(params.Stand, "Stand (Model with PrimaryPart) is required")
	assert(params.Size, "Size (Vector3) is required")
	assert(params.Duration, "Duration (number) is required")

	local stand = params.Stand
	local character = params.Character
	local damage = params.Damage or 0
	local stunDuration = params.StunDuration or 0
	local size = params.Size
	local offset = params.Offset or Vector3.new()
	local color = params.Color or BrickColor.new("Really red")
	local duration = params.Duration
	local transparency = params.Transparency or 0
	local name = params.Name or "Hitbox"
	local speed = params.Speed or 50

	-- Create projectile part
	local hitbox = Instance.new("Part")
	hitbox.Name = name
	hitbox.Size = size
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanQuery = false
	hitbox.CanTouch = false
	hitbox.Transparency = transparency
	hitbox.BrickColor = color
	hitbox.CFrame = stand:GetPivot() * CFrame.new(offset)
	hitbox.Parent = workspace:FindFirstChild("Projectiles") or workspace

	-- Direction (use current stand facing)
	local direction = stand:GetPivot().LookVector

	-- Overlap params
	local paramsFilter = OverlapParams.new()
	paramsFilter.FilterType = Enum.RaycastFilterType.Exclude
	paramsFilter.FilterDescendantsInstances = { character, hitbox }

	-- Track who was hit
	local hitPlayers = {}

	-- Register projectile in manager
	ProjectileManager.Register({
		hitbox = hitbox,
		direction = direction,
		speed = speed,
		owner = character,
		createdAt = tick(),
		duration = duration,
		paramsFilter = paramsFilter,
		character = character,
		hitPlayers = hitPlayers,
		damage = damage,
		stunDuration = stunDuration,

		-- wrapped dependencies for safety
		damageFunc = function(target)
			return CombatUtils.ReturnDamage(target, damage)
		end,

		getIsBlocking = function(target)
			return CombatUtils.GetIsBlocking(target)
		end,

		applyStun = function(target, duration)
			if target and target.Parent then
				CombatUtils.applyStun(target, duration)
				AnimationModule.PlayAnimation(target, STUN_ANIMATION_ID)
			end
		end,

		playSound = function(targetChar, dmg)
			if not targetChar or not targetChar.Parent then
				return
			end
			local isBlocking = CombatUtils.GetIsBlocking(targetChar).Value
			if isBlocking then
				SoundUtils.PlaySound({
					Root = targetChar,
					soundName = "BlockHitSound",
					soundID = BLOCK_SOUND_ID,
					volume = 1,
					playbackSpeed = 1,
					looped = false,
					range = 160,
				})
			else
				local volume, pitch = MapDamageToSound(dmg)
				SoundUtils.PlaySound({
					Root = targetChar,
					soundName = "HitSound",
					soundID = HIT_SOUND_ID,
					volume = volume,
					playbackSpeed = 1,
					looped = false,
					range = 160,
					pitch = pitch,
				})
			end
		end,
	})

	return hitbox
end

function HitboxSpawner.spawnStationaryHitbox(params)
	local position = params.Position or Vector3.new(0, 5, 0)
	local size = params.Size or Vector3.new(6, 6, 6)
	local duration = params.Duration or 0.5
	local damage = params.Damage or 10
	local stunDuration = params.StunDuration or 0
	local transparency = params.Transparency or 0.5
	local color = params.Color or BrickColor.new("Bright red")
	local name = params.Name or "StationaryHitbox"
	local character = params.Character -- attacker (to exclude from hits)
	local stand = params.Stand
	local offset = params.Offset

	print("Stationary hitbox called")

	-- Create the hitbox
	local hitbox = Instance.new("Part")
	hitbox.Name = name
	hitbox.Size = size
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.Massless = true
	hitbox.Transparency = transparency
	hitbox.BrickColor = color
	hitbox.Parent = workspace
	hitbox.CastShadow = false

	-- If stand is provided and has a PrimaryPart, use its rotation
	if params.Position then
		hitbox.CFrame = position * CFrame.new(offset)
	else
		hitbox.CFrame = stand.PrimaryPart.CFrame * CFrame.new(offset)
	end

	-- Overlap setup
	local paramsFilter = OverlapParams.new()
	paramsFilter.FilterType = Enum.RaycastFilterType.Exclude
	paramsFilter.FilterDescendantsInstances = { character, hitbox }

	local hitPlayers = {}
	local startTime = tick()

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

		-- Check overlaps every frame
		local parts = workspace:GetPartBoundsInBox(hitbox.CFrame, hitbox.Size, paramsFilter)
		for _, other in ipairs(parts) do
			if other.Name == "Hurtbox" then
				local targetChar = other.Parent
				if targetChar and targetChar ~= character then
					local humanoid = targetChar:FindFirstChildOfClass("Humanoid")

					if not humanoid then
						local owner = targetChar.Parent
						if owner and owner:IsA("Model") then
							humanoid = owner:FindFirstChildOfClass("Humanoid")
							targetChar = owner
						end
					end

					if TeamsModule.AreTeammates(targetChar, character) then
						print("Both are on the same team. Not dealing damage")
						return
					end

					if humanoid and not hitPlayers[targetChar.Name] then
						local player = Players:GetPlayerFromCharacter(character)
						if player then
							tagHumanoid(humanoid, player)
						end

						hitPlayers[targetChar.Name] = true
						local newDamage = CombatUtils.ReturnDamage(targetChar, damage)
						humanoid:TakeDamage(newDamage)

						if not CombatUtils.GetIsBlocking(targetChar).Value then
							CombatUtils.applyStun(targetChar, stunDuration)
							AnimationModule.PlayAnimation(targetChar, STUN_ANIMATION_ID)

							local volume, pitch = MapDamageToSound(damage)

							SoundUtils.PlaySound({
								Root = targetChar,
								soundName = "HitSound",
								soundID = HIT_SOUND_ID,
								volume = volume,
								playbackSpeed = 1,
								looped = false,
								range = 160,
								pitch = pitch,
							})
						else
							SoundUtils.PlaySound({
								Root = targetChar,
								soundName = "BlockHitSound",
								soundID = BLOCK_SOUND_ID,
								volume = 1,
								playbackSpeed = 1,
								looped = false,
								range = 160,
							})
						end
					end
				end
			end
		end
	end)

	Debris:AddItem(hitbox, duration)
	return hitbox
end

-- Spawn a slowing field
-- Utility: get or create SlowingEffects folder
local function getSlowingFolder(character)
	local folder = character:FindFirstChild("SlowingEffects")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "SlowingEffects"
		folder.Parent = character
	end
	return folder
end

-- Utility: recompute WalkSpeed based on all active slows
local function updateWalkSpeed(character, baseSpeed)
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end

	local folder = character:FindFirstChild("SlowingEffects")
	if not folder then
		hum.WalkSpeed = baseSpeed
		return
	end

	local multiplier = 1
	for _, slowValue in ipairs(folder:GetChildren()) do
		if slowValue:IsA("NumberValue") then
			multiplier *= slowValue.Value
		end
	end

	hum.WalkSpeed = baseSpeed * multiplier
end

function HitboxSpawner.SpawnSlowingField(params)
	local standModel = params.StandModel
	local size = params.Size or Vector3.new(6, 6, 6)
	local duration = params.Duration or 3
	local slowFactor = params.SlowFactor or 0.5
	local transparency = params.Transparency or 0.5
	local color = params.Color or BrickColor.new("Bright blue")
	local name = params.Name or "SlowingField"
	local offset = params.Offset or CFrame.new(2, 0, -8)
	local caster = params.Caster -- ✅ Player who created the field

	local standRoot = standModel.PrimaryPart
	local standCF = standRoot.CFrame

	local field = Instance.new("Part")
	field.Name = name
	field.Size = size
	field.Anchored = false
	field.CanCollide = false
	field.Massless = true
	field.Transparency = transparency
	field.BrickColor = color
	field.CFrame = standCF * offset
	field.Parent = workspace
	field.CastShadow = false

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = standRoot
	weld.Part1 = field
	weld.Parent = field

	-- 🧹 Helper: restore player speed
	local function restoreSpeed(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = CombatUtils.GetMoveSpeed(character).Value
		end
	end

	-- 🧹 Helper: remove this field’s effects
	local function cleanupField()
		for character, fields in pairs(activeFields) do
			if fields[field] then
				fields[field] = nil
				if next(fields) == nil then
					activeFields[character] = nil
					restoreSpeed(character)
				end
			end
		end
	end

	-- 🔁 Main loop
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not field.Parent then
			connection:Disconnect()
			return
		end

		local touching = workspace:GetPartsInPart(field)
		local seenCharacters = {}

		for _, part in ipairs(touching) do
			local character = part:FindFirstAncestorWhichIsA("Model")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				-- ✅ Skip the caster’s character
				if character and character == caster then
					continue
				end

				seenCharacters[character] = true

				activeFields[character] = activeFields[character] or {}

				if not activeFields[character][field] then
					activeFields[character][field] = true

					-- ✅ Apply slow
					humanoid.WalkSpeed = CombatUtils.GetMoveSpeed(character).Value * slowFactor
				end
			end
		end

		-- 🧩 Handle those who left
		for character, fields in pairs(activeFields) do
			if fields[field] and not seenCharacters[character] then
				fields[field] = nil
				if next(fields) == nil then
					activeFields[character] = nil
					restoreSpeed(character)
				end
			end
		end
	end)

	-- ⏰ End of life
	task.delay(duration, function()
		connection:Disconnect()
		cleanupField()
		field:Destroy()
	end)

	return field
end

function HitboxSpawner.SpawnStationarySlowingField(params)
	local standModel = params.StandModel
	local size = params.Size or Vector3.new(6, 6, 6)
	local duration = params.Duration or 3
	local slowFactor = params.SlowFactor or 0.5
	local transparency = params.Transparency or 0.5
	local color = params.Color or BrickColor.new("Bright blue")
	local name = params.Name or "SlowingField"
	local offset = params.Offset or CFrame.new(2, 0, -8)
	local caster = params.Caster -- ✅ Player who created the field

	local standRoot = standModel.PrimaryPart
	local standCF = standRoot.CFrame

	local field = Instance.new("Part")
	field.Name = name
	field.Size = size
	field.Anchored = true
	field.CanCollide = false
	field.Massless = true
	field.Transparency = transparency
	field.BrickColor = color
	field.CFrame = standCF * CFrame.new(offset)
	field.Parent = workspace
	field.CastShadow = false

	-- 🧹 Helper: restore player speed
	local function restoreSpeed(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = CombatUtils.GetMoveSpeed(character).Value
		end
	end

	-- 🧹 Helper: remove this field’s effects
	local function cleanupField()
		for character, fields in pairs(activeFields) do
			if fields[field] then
				fields[field] = nil
				if next(fields) == nil then
					activeFields[character] = nil
					restoreSpeed(character)
				end
			end
		end
	end

	-- 🔁 Main loop
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not field.Parent then
			connection:Disconnect()
			return
		end

		local touching = workspace:GetPartsInPart(field)
		local seenCharacters = {}

		for _, part in ipairs(touching) do
			local character = part:FindFirstAncestorWhichIsA("Model")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				if character and character == caster then
					continue
				end

				seenCharacters[character] = true

				activeFields[character] = activeFields[character] or {}

				if not activeFields[character][field] then
					activeFields[character][field] = true

					-- ✅ Apply slow
					humanoid.WalkSpeed = CombatUtils.GetMoveSpeed(character).Value * slowFactor
				end
			end
		end

		-- 🧩 Handle those who left
		for character, fields in pairs(activeFields) do
			if fields[field] and not seenCharacters[character] then
				fields[field] = nil
				if next(fields) == nil then
					activeFields[character] = nil
					restoreSpeed(character)
				end
			end
		end
	end)

	-- ⏰ End of life
	task.delay(duration, function()
		connection:Disconnect()
		cleanupField()
		field:Destroy()
	end)

	return field
end

function HitboxSpawner.ApplyDamageOverTime(humanoid, damagePerTick, tickInterval, duration, sourcePlayer)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local totalTicks = math.floor(duration / tickInterval)
	local tickCount = 0

	-- Run damage loop
	task.spawn(function()
		while tickCount < totalTicks and humanoid and humanoid.Health > 0 do
			-- Apply one tick of damage
			if sourcePlayer then
				-- Tag humanoid for kill credit
				local tag = Instance.new("ObjectValue")
				tag.Name = "creator"
				tag.Value = sourcePlayer
				tag.Parent = humanoid
				game:GetService("Debris"):AddItem(tag, 1) -- auto-clean
			end

			humanoid:TakeDamage(damagePerTick)

			local volume, pitch = MapDamageToSound(damagePerTick)

			SoundUtils.PlaySound({
				Root = humanoid.Parent,
				soundName = "HitSound",
				soundID = HIT_SOUND_ID,
				volume = volume,
				playbackSpeed = 1,
				looped = false,
				range = 160,
				pitch = pitch,
			})

			tickCount += 1
			task.wait(tickInterval)
		end
	end)
end

return HitboxSpawner
