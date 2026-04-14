local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local MenuState = require(player.PlayerScripts.MenuState)

-- Remotes
local QuestEventsFolder = ReplicatedStorage:WaitForChild("QuestEvents")
local QuestUpdatedEvent = QuestEventsFolder:WaitForChild("QuestUpdated")
local ArrowVisible = QuestEventsFolder:WaitForChild("QuestArrowVisible")

-- Arrow asset
local ArrowTemplate = ReplicatedStorage.Effects.QuestEffects:WaitForChild("ArrowModel")
local QuestDataEvent = QuestEventsFolder:WaitForChild("GetQuestData")

-- State
local arrow
local connection
local currentTarget -- BasePart or Model.PrimaryPart

local function getNPCPrimaryPart(name)
	if not name then
		return nil
	end

	local npc = workspace.NPCs.QuestGivers:FindFirstChild(name)
	if npc and npc.PrimaryPart then
		return npc.PrimaryPart
	end

	return nil
end

local function setArrowVisible(state)
	for _, obj in ipairs(arrow:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name ~= "MainPart" then
			obj.Transparency = state and 0 or 1
		elseif obj:IsA("BillboardGui") then
			obj.Enabled = state
		end
	end
end

local function getClosestEnemy(enemyName, fromPosition)
	local closest
	local closestDist = math.huge

	for _, enemy in ipairs(workspace.NPCs.EnemyNPCs:GetChildren()) do
		if enemy.Name == enemyName and enemy.PrimaryPart then
			local humanoid = enemy:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local dist = (enemy.PrimaryPart.Position - fromPosition).Magnitude
				if dist < closestDist then
					closestDist = dist
					closest = enemy.PrimaryPart
				end
			end
		end
	end

	return closest
end

------------------------------------------------
-- Utility: resolve quest → world target
------------------------------------------------
local function resolveQuestTarget(quest, character)
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end

	local definition = quest.Definition or quest -- fallback if you store raw definition
	local objectives = quest.Objectives or {}

	-- 🔹 Check objectives first
	for i, objectiveState in ipairs(objectives) do
		local objectiveDef = definition.Objectives[i]
		if not objectiveDef then
			continue
		end

		if objectiveDef.Type == "Defeat" then
			if objectiveState.Progress < (objectiveDef.Required or 1) then
				return getClosestEnemy(objectiveDef.Target, hrp.Position)
			end
		end

		if objectiveDef.Type == "Talk" and not objectiveState.Completed then
			local npc = workspace.NPCs.QuestGivers:FindFirstChild(objectiveDef.Target)
			if npc and npc.PrimaryPart then
				return npc.PrimaryPart
			end
		end

		if objectiveDef.Type == "CheckPowers" and not objectiveState.Completed then
			-- Point to TurnIn NPC since that's where the check happens
			return getNPCPrimaryPart(definition.TurnInNpc)
		end

		if objectiveDef.Type == "Interact" and not objectiveState.Completed then
			local interactable = workspace.Objectives.QuestInteractables:FindFirstChild(objectiveDef.Target, true) -- recursive search
			if interactable then
				-- Prefer PrimaryPart (models)
				if interactable:IsA("Model") and interactable.PrimaryPart then
					return interactable.PrimaryPart
				end

				-- Fallback for parts
				if interactable:IsA("BasePart") then
					return interactable
				end
			end
		end
	end

	-- 🔹 All objectives complete → Turn-in NPC
	if definition.TurnInNpc then
		return getNPCPrimaryPart(definition.TurnInNpc)
	end

	return nil
end

------------------------------------------------
-- Pick which quest to track
------------------------------------------------
local function chooseQuestTarget(quests, character)
	for _, quest in pairs(quests) do
		if quest.Status ~= "Completed" then
			local target = resolveQuestTarget(quest, character)
			if target then
				return target
			end
		end
	end
	return nil
end

local function makeModelNonPhysical(model)
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = true
			obj.CanCollide = false
			obj.CanTouch = false
			obj.CanQuery = false
			obj.Massless = true
		end
	end
end

------------------------------------------------
-- Arrow attachment
------------------------------------------------
local function attachArrow(character)
	local hrp = character:WaitForChild("HumanoidRootPart")

	-- Clean old
	if connection then
		connection:Disconnect()
		connection = nil
	end

	if arrow then
		arrow:Destroy()
		arrow = nil
	end

	arrow = ArrowTemplate:Clone()
	arrow.Name = "QuestArrow"
	arrow.Parent = character

	makeModelNonPhysical(arrow)

	-- 🔥 Hide initially
	setArrowVisible(false)

	connection = RunService.RenderStepped:Connect(function()
		if not arrow or not arrow.PrimaryPart then
			return
		end
		if not hrp.Parent then
			return
		end

		local offset = Vector3.new(0, 0, 0)
		local arrowPosition = hrp.Position + offset

		if currentTarget and currentTarget.Parent then
			arrow:SetPrimaryPartCFrame(CFrame.lookAt(arrowPosition, currentTarget.Position))
		else
			-- 🔥 Just follow position WITHOUT resetting rotation
			local currentCFrame = arrow.PrimaryPart.CFrame
			arrow:SetPrimaryPartCFrame(CFrame.new(arrowPosition) * (currentCFrame - currentCFrame.Position))
		end
	end)
end

------------------------------------------------
-- Quest updates
------------------------------------------------
QuestUpdatedEvent.OnClientEvent:Connect(function(quests)
	if not player.Character then
		return
	end
	currentTarget = chooseQuestTarget(quests, player.Character)

	-- 🔥 Only show if we have a valid target
	if currentTarget then
		setArrowVisible(true)
	else
		setArrowVisible(false)
	end
end)

ArrowVisible.Event:Connect(function(visible)
	setArrowVisible(visible)
end)

------------------------------------------------
-- Character lifecycle
------------------------------------------------
if player.Character then
	attachArrow(player.Character)
end

player.CharacterAdded:Connect(function(character)
	attachArrow(character)

	-- 🔥 IMMEDIATELY request quest data
	local success, quests = pcall(function()
		return QuestDataEvent:InvokeServer()
	end)

	if success and quests then
		currentTarget = chooseQuestTarget(quests, character)
	end

	task.wait(3)
	local questUIOpen = MenuState:IsOpen("QuestGUI")
	setArrowVisible(questUIOpen)
end)
