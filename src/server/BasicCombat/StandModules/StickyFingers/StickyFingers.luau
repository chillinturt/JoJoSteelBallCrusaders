local StickyFingers = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HitboxSpawner = require(ServerScriptService.BasicCombat.HitboxSpawner)
local StandUtils = require(ServerScriptService.BasicCombat.StandUtils)
local AnimationModule = require(ServerScriptService.BasicCombat.AnimationModule)
local CombatUtils = require(ServerScriptService.BasicCombat.CombatUtils)
local SoundModule = require(ServerScriptService.Utilities.SoundUtils)

--------------------------------------------------
-- ZIPPER METER SYSTEM
--------------------------------------------------

local zipperData = {} -- [character] = meter

local MAX_METER = 100

local function GetMeter(char)
	return zipperData[char] or 0
end

local function SetMeter(char, value)
	value = math.clamp(value, 0, MAX_METER)
	zipperData[char] = value

	StickyFingers.UpdateZipperUI(char, value)

	-- Apply slow scaling
	local humanoid = char:FindFirstChild("Humanoid")
	if humanoid then
		local slowPercent = value / 100 * 0.5 -- max 50% slow
		humanoid.WalkSpeed = 16 * (1 - slowPercent)
	end

	-- FULL METER EFFECT
	if value >= MAX_METER then
		humanoid.WalkSpeed = 4
		task.delay(2, function()
			if char and char.Parent then
				SetMeter(char, 0)
				humanoid.WalkSpeed = 16
			end
		end)
	end
end

function StickyFingers.AddMeter(char, amount)
	SetMeter(char, GetMeter(char) + amount)
end

--------------------------------------------------
-- OVERHEAD GUI
--------------------------------------------------

function StickyFingers.AttachZipperUI(character)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	if head:FindFirstChild("ZipperUI") then
		return
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "ZipperUI"
	gui.Size = UDim2.new(4, 0, 0.5, 0)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.Parent = head

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 1, 0)
	bar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	bar.Parent = gui

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	fill.Parent = bar
end

function StickyFingers.UpdateZipperUI(character, value)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	local gui = head:FindFirstChild("ZipperUI")
	if not gui then
		return
	end

	local fill = gui.Frame:FindFirstChild("Fill")
	if fill then
		fill.Size = UDim2.new(value / 100, 0, 1, 0)
	end
end

--------------------------------------------------
-- ABILITY 1: ZIPPER BARRAGE
--------------------------------------------------

function StickyFingers.Barrage(standModel)
	local character = standModel.Parent

	AnimationModule.PlayAnimation(standModel, 123456, true, Enum.AnimationPriority.Action)

	HitboxSpawner.spawnHitbox({
		Character = character,
		Damage = 5,
		Size = Vector3.new(6, 6, 6),
		Offset = CFrame.new(0, 0, -5),
		Duration = 2,
		DamagePerTick = 2,
		DOTTickInterval = 0.2,
		Transparency = 0.5,

		OnHit = function(target)
			StickyFingers.AddMeter(target, 5)
		end,
	})
end

--------------------------------------------------
-- ABILITY 2: ZIPPER PULL
--------------------------------------------------

function StickyFingers.ZipperPull(standModel)
	local character = standModel.Parent
	local hrp = character:FindFirstChild("HumanoidRootPart")

	local target = CombatUtils.GetNearestTarget(character, 25, true)
	if not target then
		return
	end

	local targetHRP = target:FindFirstChild("HumanoidRootPart")
	if not targetHRP then
		return
	end

	-- Pull target
	targetHRP.CFrame = hrp.CFrame * CFrame.new(0, 0, -5)

	StickyFingers.AddMeter(target, 25)

	CombatUtils.applyStun(target, 1.2)
end

--------------------------------------------------
-- ABILITY 3: ZIPPER TRAP
--------------------------------------------------

function StickyFingers.ZipperTrap(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")

	local part = Instance.new("Part")
	part.Size = Vector3.new(6, 1, 6)
	part.Anchored = true
	part.CFrame = hrp.CFrame * CFrame.new(0, -3, 0)
	part.Parent = workspace

	game.Debris:AddItem(part, 8)

	part.Touched:Connect(function(hit)
		local enemy = hit.Parent
		if enemy and enemy ~= character then
			StickyFingers.AddMeter(enemy, 10)
		end
	end)
end

--------------------------------------------------
-- ABILITY 4: ZIPPER DASH
--------------------------------------------------

function StickyFingers.ZipperDash(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")

	local direction = hrp.CFrame.LookVector
	local distance = 40

	hrp.CFrame = hrp.CFrame + direction * distance

	-- Cleanse slow
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
	end
end

--------------------------------------------------

return StickyFingers
