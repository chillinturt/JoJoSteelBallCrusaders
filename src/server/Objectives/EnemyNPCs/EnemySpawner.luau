local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TeamsModule = require(game.ServerScriptService.BasicCombat.Managers:WaitForChild("TeamsModule"))

local EnemyFolder = ReplicatedStorage:WaitForChild("EnemyNPCs")

local WorkspaceEnemyFolder = workspace.NPCs:WaitForChild("EnemyNPCs")

local EnemySpawner = {}
EnemySpawner.__index = EnemySpawner

function EnemySpawner.new(spawnPart, enemyType, config)
	local self = setmetatable({}, EnemySpawner)

	self.SpawnPart = spawnPart
	self.EnemyType = enemyType
	self.Config = config

	self.ActiveEnemy = nil
	self.MonitorConnection = nil

	-- normalize spawn part
	spawnPart.Anchored = true
	spawnPart.Transparency = 1
	spawnPart.CanCollide = false

	self.IsActive = false

	self.SpawnToken = 0

	return self
end

function EnemySpawner:CleanupEnemy()
	self.SpawnToken += 1

	if self.ActiveEnemy and self.ActiveEnemy.Parent then
		self.ActiveEnemy:Destroy()
	end

	self.ActiveEnemy = nil

	if self.MonitorConnection then
		self.MonitorConnection:Disconnect()
		self.MonitorConnection = nil
	end
end

function EnemySpawner:SpawnEnemy()
	self:CleanupEnemy()

	local enemyTemplate = EnemyFolder:FindFirstChild(self.EnemyType)

	if not enemyTemplate then
		warn("Enemy type not found:", self.EnemyType)
		return
	end

	local enemy = enemyTemplate:Clone()

	local root = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart")

	if not root then
		warn("Enemy missing root:", enemy.Name)
		enemy:Destroy()
		return
	end

	local radius = self.Config.SpawnRadius or 0

	local offset = Vector3.new(math.random(-radius, radius), 0, math.random(-radius, radius))

	root.CFrame = self.SpawnPart.CFrame + offset

	enemy.Parent = WorkspaceEnemyFolder
	self.ActiveEnemy = enemy

	TeamsModule.SetTeam(enemy, TeamsModule.NPCTeam)

	local humanoid = enemy:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid.Died:Connect(function()
			local token = self.SpawnToken

			task.delay(self.Config.RespawnTime, function()
				if token ~= self.SpawnToken then
					return
				end
				if self.IsActive then
					self:SpawnEnemy()
				end
			end)
		end)
	end

	local spawnPos = self.SpawnPart.Position

	self.MonitorConnection = RunService.Heartbeat:Connect(function()
		if not enemy.Parent or not root.Parent then
			return
		end

		local dist = (root.Position - spawnPos).Magnitude

		if dist > self.Config.MaxDistance then
			print(enemy.Name, "wandered too far.")

			self:CleanupEnemy()

			local token = self.SpawnToken

			task.delay(self.Config.RespawnTime, function()
				if token ~= self.SpawnToken then
					return
				end

				if self.IsActive then
					self:SpawnEnemy()
				end
			end)
		end
	end)
end

function EnemySpawner:IsPlayerNearby()
	local activationRadius = self.Config.ActivationRadius or 1000

	local spawnPos = self.SpawnPart.Position

	for _, player in ipairs(game.Players:GetPlayers()) do
		local character = player.Character

		if character then
			local root = character:FindFirstChild("HumanoidRootPart")

			if root then
				local dist = (root.Position - spawnPos).Magnitude

				if dist <= activationRadius then
					return true
				end
			end
		end
	end

	return false
end

function EnemySpawner:Activate()
	if self.IsActive then
		return
	end

	self.IsActive = true

	if not self.ActiveEnemy then
		self:SpawnEnemy()
	end
end

function EnemySpawner:Deactivate()
	if not self.IsActive then
		return
	end

	self.IsActive = false

	self:CleanupEnemy()
end

function EnemySpawner:Update()
	local nearby = self:IsPlayerNearby()

	if nearby then
		self:Activate()
	else
		self:Deactivate()
	end
end

return EnemySpawner
