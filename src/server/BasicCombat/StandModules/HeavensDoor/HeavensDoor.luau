local HeavensDoor = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local AnimationModule = require(ServerScriptService.BasicCombat.AnimationModule)
local CombatUtils = require(ServerScriptService.BasicCombat.CombatUtils)
local SoundModule = require(ServerScriptService.Utilities.SoundUtils)

local SpawnClientVfx = ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")
local BookMeterEvent = ReplicatedStorage.UIs.RemoteEvents:FindFirstChild("BookMeterUpdate")
if not BookMeterEvent then
	BookMeterEvent = Instance.new("RemoteEvent")
	BookMeterEvent.Name = "BookMeterUpdate"
	BookMeterEvent.Parent = ReplicatedStorage.UIs.RemoteEvents
end

local PAGESLASH_SIZE = Vector3.new(5, 7, 28)
local PAGESLASH_OFFSET = Vector3.new(2, 0, -20)

local MEMORYBURN_OFFSET = Vector3.new(2, 0, -8)

local MEMORYBURN_KNOCKBACK_SPEED = 60
local MEMORYBURN_KNOCKBACK_DURATION = 1

-- =========================
-- 📖 BOOK METER SYSTEM
-- =========================
local bookStacks = {} -- [character] = 0–100

local lastStackTime = {} -- [character] = last time stacks were added
local DECAY_DELAY = 5 -- seconds before decay starts
local DECAY_RATE = 5 -- stacks per second

local function GetStacks(target)
	return bookStacks[target] or 0
end

local function SetStacks(target, value)
	value = math.clamp(value, 0, 100)

	if bookStacks[target] == value then
		return
	end

	bookStacks[target] = value
	BookMeterEvent:FireAllClients(target, value)
end

local function AddStacks(target, amount)
	lastStackTime[target] = tick()
	SetStacks(target, GetStacks(target) + amount)

	local stacks = GetStacks(target)
	local head = target:FindFirstChild("Head")

	if stacks >= 40 and head then
		SpawnClientVfx:FireAllClients({
			type = "Attached",
			effectName = "HeavensDoorBookEffect",
			offset = CFrame.new(0, 0, 0),
			attachTo = head,
			lifetime = 10,
		})
	end
end

local function ResetStacks(target)
	bookStacks[target] = 0
	BookMeterEvent:FireAllClients(target, 0)
end

local function ApplyBookDamageAmp(target)
	local stacks = GetStacks(target)

	if stacks <= 0 then
		return
	end

	local mult = 1 + (stacks * 0.0075) -- capped ~1.75

	CombatUtils.ApplyDamageMult(target, mult, 10, "Book")
end

-- =========================
-- ✍️ ABILITY 1: PAGE SLASH
-- Fast combo builder
-- =========================
function HeavensDoor.PageSlash(standModel)
	local character = standModel.Parent

	AnimationModule.PlayAnimationThenIdle(standModel, 133528931317091, false, Enum.AnimationPriority.Action, 1)
	CombatUtils.SetActionInProgress(character, 0.3)

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "WriteCommandCall",
		soundID = "101189706707372",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
	})

	HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = 10,
		Size = PAGESLASH_SIZE,
		Offset = CFrame.new(PAGESLASH_OFFSET),
		Duration = 0.9,
		StunDuration = 0.5,
		Transparency = 1,
		OnHit = function(target)
			AddStacks(target, 10)
			ApplyBookDamageAmp(target)
		end,
	})

	local head = standModel:FindFirstChild("Head")

	local vfxId = HttpService:GenerateGUID(false)
	head:SetAttribute("VFX_ID", vfxId)

	SpawnClientVfx:FireAllClients({
		type = "Attached",
		effectName = "HeavensDoorTrail",
		attachId = vfxId,
		offset = CFrame.new(0, 0, -12),
		attachTo = head,
		lifetime = 1,
	})
end

-- =========================
-- 📖 ABILITY 2: FORCE READ
-- Opens enemy like a book
-- =========================
function HeavensDoor.ForceRead(standModel)
	local character = standModel.Parent

	CombatUtils.SetActionInProgress(character, 1)
	AnimationModule.PlayAnimationThenIdle(standModel, 117096419135889, false, Enum.AnimationPriority.Action, 1)

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "ForceReadCall",
		soundID = "7280544801",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
	})

	HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = 25,
		Size = Vector3.new(6, 6, 9),
		Offset = CFrame.new(MEMORYBURN_OFFSET),
		Duration = 0.5,
		StunDuration = 1.5,
		Transparency = 1,

		OnHit = function(target)
			AddStacks(target, 30)

			ApplyBookDamageAmp(target)

			SpawnClientVfx:FireAllClients({
				type = "Overhead",
				effectName = "BookOpen",
				target = target,
			})
		end,
	})

	SpawnClientVfx:FireAllClients({
		type = "TextBurst",
		attachTo = standModel.RightHand,
		offset = Vector3.new(0, 2, 0),
		count = 8,
		lifetime = 2,
		textPool = { "ド", "ッ", "ラ" },
	})
end

-- =========================
-- 📝 ABILITY 3: WRITE COMMAND
-- Requires high meter
-- =========================
function HeavensDoor.WriteCommand(standModel)
	local character = standModel.Parent

	CombatUtils.SetActionInProgress(character, 0.6)
	AnimationModule.PlayAnimationThenIdle(standModel, 117096419135889, false, Enum.AnimationPriority.Action, 1)

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "WriteCommandCall",
		soundID = "7281133906",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
	})

	HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = 20,
		Size = Vector3.new(6, 6, 6),
		Offset = CFrame.new(MEMORYBURN_OFFSET),
		Duration = 0.5,
		StunDuration = 1,
		Transparency = 1,

		OnHit = function(target)
			local stacks = GetStacks(target)
			if stacks < 40 then
				return
			end

			-- BIG temporary vulnerability
			CombatUtils.ApplyDamageMult(target, 2.0, 3, "Command")

			SpawnClientVfx:FireAllClients({
				type = "Overhead",
				effectName = "WrittenCommand",
				target = target,
			})

			ResetStacks(target)
		end,
	})

	SpawnClientVfx:FireAllClients({
		type = "TextBurst",
		attachTo = standModel.HumanoidRootPart,
		style = "WriteCommand",
		textPool = { "読", "解", "開" }, -- “read/open”
	})
end

-- =========================
-- 📚 ABILITY 4: MEMORY BURN
-- Big finisher
-- =========================
function HeavensDoor.MemoryBurn(standModel)
	local character = standModel.Parent

	CombatUtils.SetActionInProgress(character, 1.5)
	AnimationModule.PlayAnimationThenIdle(standModel, 117096419135889, false, Enum.AnimationPriority.Action, 1)

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "MemoryBurnCall",
		soundID = "5708108166",
		volume = 2,
		playbackSpeed = 1,
		looped = false,
	})

	HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = 40,
		Size = Vector3.new(8, 8, 8),
		Offset = CFrame.new(MEMORYBURN_OFFSET),
		Duration = 0.4,
		StunDuration = 2,
		Transparency = 1,
		RemoveOnStun = false,

		OnHit = function(target)
			local stacks = GetStacks(target)

			local humanoid = target:FindFirstChild("Humanoid")
			local targetRootPart = target:FindFirstChild("HumanoidRootPart")
			local attackerRoot = character:FindFirstChild("HumanoidRootPart")

			if not (humanoid and targetRootPart and attackerRoot) then
				return
			end

			-- Lock rotation
			humanoid.AutoRotate = false

			local rootJoint = targetRootPart:FindFirstChild("RootJoint")
			local originalC0 = rootJoint and rootJoint.C0

			local worldDirection = attackerRoot.CFrame.LookVector
			worldDirection = Vector3.new(worldDirection.X, 0, worldDirection.Z).Unit

			-- Convert WORLD → TARGET LOCAL
			local localDirection = targetRootPart.CFrame:VectorToObjectSpace(worldDirection)

			CombatUtils.ApplyTurningVelocity({
				Character = target,
				Speed = MEMORYBURN_KNOCKBACK_SPEED,
				Duration = MEMORYBURN_KNOCKBACK_DURATION,
				Name = "BlazingStrikeVelocity",
				Direction = localDirection,
			})

			local bonus = stacks * 0.5

			-- apply multiplier BEFORE damage
			CombatUtils.ApplyDamageMult(target, 1 + (stacks * 0.01), 1, "Finisher")

			humanoid:TakeDamage(30 + bonus)

			if stacks >= 100 then
				SpawnClientVfx:FireAllClients({
					type = "Overhead",
					effectName = "CriticalRead",
					target = target,
				})
			end

			ResetStacks(target)

			-- Restore rotation
			task.delay(MEMORYBURN_KNOCKBACK_DURATION, function()
				if humanoid then
					humanoid.AutoRotate = true
				end
				if rootJoint and originalC0 then
					rootJoint.C0 = originalC0
				end
			end)
		end,
	})

	SpawnClientVfx:FireAllClients({
		type = "TextBurst",
		attachTo = standModel.HumanoidRootPart,
		offset = Vector3.new(0, 2, -4),
		style = "MemoryBurn",
		textPool = { "ド", "ド", "ド", "ド", "ゴゴゴゴ" },
		count = 15,
	})
end

task.spawn(function()
	while true do
		local now = tick()

		for target, stacks in pairs(bookStacks) do
			if stacks > 0 then
				local lastTime = lastStackTime[target] or 0
				local timeSinceLastStack = now - lastTime

				-- ONLY decay if full delay has passed
				if timeSinceLastStack >= DECAY_DELAY then
					local decayAmount = DECAY_RATE * 0.1
					local newStacks = math.max(0, stacks - decayAmount)

					SetStacks(target, newStacks)

					if newStacks <= 0 then
						bookStacks[target] = nil
						lastStackTime[target] = nil
					end
				end
			end
		end

		task.wait(0.1)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local char = player.Character
	if char then
		bookStacks[char] = nil
		lastStackTime[char] = nil
	end
end)

return HeavensDoor
