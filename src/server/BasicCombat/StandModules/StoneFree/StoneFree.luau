local StoneFree = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local StandUtils = require(ServerScriptService.BasicCombat.StandUtils)
local AnimationModule = require(ServerScriptService.BasicCombat.AnimationModule)
local CombatUtils = require(ServerScriptService.BasicCombat.CombatUtils)
local SoundModule = require(ServerScriptService.Utilities.SoundUtils)
local RaycastModule = require(ServerScriptService.BasicCombat.RaycastModule)
local RaycastIgnoreModule = require(ReplicatedStorage.Shared.Modules.RaycastIgnoreModule)

local STRING_FORM_DURATION = 8
local GRAPPLE_RANGE = 80
local BARRAGE_DAMAGE = 4
local BARRAGE_TICKS = 10
local TRAP_DURATION = 6

local activeStringForm = {}

--------------------------------------------------
-- 🧵 STRING FORM (CORE ABILITY)
--------------------------------------------------
function StoneFree.StringForm(standModel)
	local character = standModel.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	if activeStringForm[player] then
		return
	end

	activeStringForm[player] = true

	-- Reduce collisions (simulate slipping through gaps)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end

	-- Speed boost
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.WalkSpeed *= 1.5
	end

	SoundModule.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "StringForm",
		soundID = "9120036335",
		volume = 2,
	})

	CombatUtils.SetActionInProgress(character, STRING_FORM_DURATION)

	task.delay(STRING_FORM_DURATION, function()
		if not activeStringForm[player] then
			return
		end

		-- Restore collisions
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end

		if humanoid then
			humanoid.WalkSpeed /= 1.5
		end

		activeStringForm[player] = nil
	end)
end

--------------------------------------------------
-- 🧵 STRING GRAPPLE
--------------------------------------------------
function StoneFree.Grapple(standModel)
	local character = standModel.Parent
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local direction = hrp.CFrame.LookVector

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = RaycastIgnoreModule.GetIgnoreList()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(hrp.Position, direction * GRAPPLE_RANGE, rayParams)

	if not result then
		return
	end

	local targetPos = result.Position

	local distance = (targetPos - hrp.Position).Magnitude

	-- Pull player
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bodyVelocity.Velocity = (targetPos - hrp.Position).Unit * 100
	bodyVelocity.Parent = hrp

	game.Debris:AddItem(bodyVelocity, distance / 100)

	SoundModule.PlaySound({
		Root = hrp,
		soundName = "Grapple",
		soundID = "12222216",
		volume = 2,
	})
end

--------------------------------------------------
-- 🧵 STRING BARRAGE
--------------------------------------------------
function StoneFree.Barrage(standModel)
	local character = standModel.Parent

	CombatUtils.SetActionInProgress(character, 1.5)

	for i = 1, BARRAGE_TICKS do
		HitboxSpawner.spawnHitbox({
			Character = character,
			Damage = BARRAGE_DAMAGE,
			Size = Vector3.new(6, 6, 6),
			Offset = CFrame.new(0, 0, -5),
			Duration = 0.1,
			StunDuration = 0.2,
			Name = "StringBarrage",
		})
		task.wait(0.1)
	end
end

--------------------------------------------------
-- 🧵 STRING TRAP
--------------------------------------------------
function StoneFree.StringTrap(standModel)
	local character = standModel.Parent
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local trapPosition = hrp.Position + hrp.CFrame.LookVector * 6

	local trap = Instance.new("Part")
	trap.Size = Vector3.new(10, 1, 10)
	trap.Position = trapPosition
	trap.Anchored = true
	trap.Transparency = 1
	trap.CanCollide = false
	trap.Parent = workspace

	local touched = {}

	trap.Touched:Connect(function(hit)
		local enemy = hit.Parent
		if touched[enemy] then
			return
		end
		touched[enemy] = true

		local humanoid = enemy:FindFirstChild("Humanoid")
		if humanoid then
			humanoid:TakeDamage(10)
			humanoid.WalkSpeed *= 0.5

			task.delay(2, function()
				if humanoid then
					humanoid.WalkSpeed *= 2
				end
			end)
		end
	end)

	game.Debris:AddItem(trap, TRAP_DURATION)
end

--------------------------------------------------
-- STATE CHECK
--------------------------------------------------
function StoneFree.IsStringForm(player)
	return activeStringForm[player] ~= nil
end

return StoneFree
