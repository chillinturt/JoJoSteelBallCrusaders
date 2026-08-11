local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local QuestManager = require(game.ServerScriptService.DataSaving:WaitForChild("QuestManager"))
local QuestDefinitions = require(game.ServerScriptService.DataSaving:WaitForChild("QuestDefinitions"))

local QuestEventsFolder = ReplicatedStorage:WaitForChild("QuestEvents")

-- Created here so it exists in ReplicatedStorage before UI scripts look it up.
-- Fired client-side by UIController when the Questlog opens/closes, and
-- consumed by QuestArrow.client.luau to gate arrow visibility.
local arrowVisible = Instance.new("BindableEvent")
arrowVisible.Name = "QuestArrowVisible"
arrowVisible.Parent = QuestEventsFolder

local SetArrowTarget = Instance.new("RemoteEvent")
SetArrowTarget.Name = "SetArrowTarget"
SetArrowTarget.Parent = QuestEventsFolder

local UPDATE_INTERVAL = 0.5

------------------------------------------------
-- World lookups (server has full workspace access)
------------------------------------------------

local function getNPCPosition(npcName)
	if not npcName then return nil end
	local npc = workspace.NPCs.QuestGivers:FindFirstChild(npcName)
	if npc and npc.PrimaryPart then
		return npc.PrimaryPart.Position
	end
	return nil
end

local function getClosestEnemyPosition(enemyName, fromPosition)
	local closest
	local closestDist = math.huge

	for _, enemy in ipairs(workspace.NPCs.EnemyNPCs:GetChildren()) do
		if enemy.Name == enemyName and enemy.PrimaryPart then
			local humanoid = enemy:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local dist = (enemy.PrimaryPart.Position - fromPosition).Magnitude
				if dist < closestDist then
					closestDist = dist
					closest = enemy.PrimaryPart.Position
				end
			end
		end
	end

	return closest
end

------------------------------------------------
-- Target resolution
------------------------------------------------

local function resolveTargetPosition(player)
	local character = player.Character
	if not character then return nil end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local quests = QuestManager.GetQuests(player)

	for questId, quest in pairs(quests) do
		if quest.Completed then continue end

		local def = QuestDefinitions[questId]
		if not def then continue end

		local allComplete = true

		for _, obj in ipairs(quest.Objectives or {}) do
			if obj.Completed then continue end
			allComplete = false

			if obj.Type == "Defeat" then
				return getClosestEnemyPosition(obj.Target, hrp.Position)

			elseif obj.Type == "Talk" then
				return getNPCPosition(obj.Target)

			elseif obj.Type == "CheckPowers" then
				local turnIn = type(def.TurnInNpc) == "table" and def.TurnInNpc[1] or def.TurnInNpc
				return getNPCPosition(turnIn)

			elseif obj.Type == "Interact" then
				local interactable = workspace.Objectives.QuestInteractables:FindFirstChild(obj.Target, true)
				if interactable then
					if interactable:IsA("Model") and interactable.PrimaryPart then
						return interactable.PrimaryPart.Position
					elseif interactable:IsA("BasePart") then
						return interactable.Position
					end
				end
				return nil
			end
		end

		-- All objectives done → turn-in NPC
		if allComplete and def.TurnInNpc then
			local turnIn = type(def.TurnInNpc) == "table" and def.TurnInNpc[1] or def.TurnInNpc
			return getNPCPosition(turnIn)
		end
	end

	return nil
end

------------------------------------------------
-- Player tracking
------------------------------------------------

local activePlayers = {}

Players.PlayerAdded:Connect(function(player)
	activePlayers[player] = true
	player.CharacterAdded:Connect(function()
		task.delay(3, function()
			QuestManager.Sync(player)
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	activePlayers[player] = nil
end)

-- Periodic push to all active players
local timer = 0
RunService.Heartbeat:Connect(function(dt)
	timer += dt
	if timer < UPDATE_INTERVAL then return end
	timer = 0

	for player in pairs(activePlayers) do
		local position = resolveTargetPosition(player)
		SetArrowTarget:FireClient(player, position)
	end
end)
