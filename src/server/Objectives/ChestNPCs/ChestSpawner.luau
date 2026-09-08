local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CashSystem = require(game.ServerScriptService.DataSaving:WaitForChild("CashSystem"))
local InventoryManager = require(game.ServerScriptService.DataSaving.InventoryManager)

local ChestTemplateFolder = ReplicatedStorage:WaitForChild("Chests")

local WorkspaceChestFolder = workspace:WaitForChild("Chests"):WaitForChild("ActiveChests")

local ChestSpawner = {}
ChestSpawner.__index = ChestSpawner

function ChestSpawner.new(spawnPart, chestDefinitions)
	local self = setmetatable({}, ChestSpawner)

	self.SpawnPart = spawnPart
	self.ChestDefinitions = chestDefinitions

	self.ActiveChest = nil
	self.PromptConnection = nil

	self.IsActive = false
	self.CooldownUntil = 0

	self.SpawnToken = 0

	-- normalize spawn part
	spawnPart.Anchored = true
	spawnPart.Transparency = 1
	spawnPart.CanCollide = false

	return self
end

function ChestSpawner:IsAvailable()
	return not self.IsActive and time() >= self.CooldownUntil
end

function ChestSpawner:Cleanup()
	self.SpawnToken += 1

	if self.ActiveChest and self.ActiveChest.Parent then
		self.ActiveChest:Destroy()
	end

	self.ActiveChest = nil

	if self.PromptConnection then
		self.PromptConnection:Disconnect()
		self.PromptConnection = nil
	end
end

function ChestSpawner:GrantReward(player, config)
	local cashReward = config.CashReward

	if cashReward then
		local amount = math.random(cashReward.Min, cashReward.Max)
		CashSystem.AddCash(player, amount)
	end

	if config.ItemRewards then
		for _, itemReward in ipairs(config.ItemRewards) do
			if math.random() <= (itemReward.Chance or 1) then
				InventoryManager.AddItem(player, itemReward.Name, itemReward.Amount or 1)
			end
		end
	end
end

function ChestSpawner:Collect(player, chestType, config)
	self:GrantReward(player, config)

	self:Cleanup()

	self.IsActive = false
	self.CooldownUntil = time() + config.RespawnTime
end

function ChestSpawner:Activate(chestType)
	if self.IsActive then
		return
	end

	local config = self.ChestDefinitions[chestType]

	if not config then
		warn("Missing ChestDefinition for:", chestType)
		return
	end

	local template = ChestTemplateFolder:FindFirstChild(chestType)

	if not template then
		warn("Chest type not found:", chestType)
		return
	end

	self:Cleanup()

	local chest = template:Clone()

	local root = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")

	if not root then
		warn("Chest missing a primary/base part:", chest.Name)
		chest:Destroy()
		return
	end

	local radius = config.SpawnRadius or 0
	local offset = Vector3.new(math.random(-radius, radius), 0, math.random(-radius, radius))
	local targetCFrame = self.SpawnPart.CFrame + offset

	if chest.PrimaryPart then
		chest:PivotTo(targetCFrame)
	else
		root.CFrame = targetCFrame
	end

	chest.Parent = WorkspaceChestFolder

	self.ActiveChest = chest
	self.IsActive = true

	local pickupRadius = config.PickupRadius or 6

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Collect"
	prompt.ObjectText = chestType
	prompt.MaxActivationDistance = pickupRadius
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = root

	local token = self.SpawnToken
	local collected = false

	self.PromptConnection = prompt.Triggered:Connect(function(player)
		if token ~= self.SpawnToken or collected then
			return
		end

		collected = true
		self:Collect(player, chestType, config)
	end)
end

function ChestSpawner:Deactivate()
	if not self.IsActive then
		return
	end

	self.IsActive = false
	self:Cleanup()
end

return ChestSpawner
