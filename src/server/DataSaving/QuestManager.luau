local QuestManager = {}

-- Store active quests per player
local playerQuests = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestDefinitions = require(script.Parent:WaitForChild("QuestDefinitions"))

-- Remote events/functions for client sync
local QuestEventsFolder = ReplicatedStorage:WaitForChild("QuestEvents")

local QuestDataEvent = Instance.new("RemoteFunction")
QuestDataEvent.Name = "GetQuestData"
QuestDataEvent.Parent = QuestEventsFolder

local QuestUpdatedEvent = Instance.new("RemoteEvent")
QuestUpdatedEvent.Name = "QuestUpdated"
QuestUpdatedEvent.Parent = QuestEventsFolder

-- 🔹 Utility: check if player has quest
function QuestManager.HasQuest(player, questId)
	return playerQuests[player] and playerQuests[player][questId] ~= nil
end

-- 🔹 Add quest
function QuestManager.AddQuest(player, questId)
	playerQuests[player] = playerQuests[player] or {}

	if not QuestManager.HasQuest(player, questId) then
		local questTemplate = QuestDefinitions[questId]
		if not questTemplate then
			warn("Quest ID not found in QuestDefinitions:", questId)
			return
		end

		-- Deep copy template to avoid modifying global definition
		local function deepCopy(value)
			if type(value) == "table" then
				local copy = {}
				for k, v in pairs(value) do
					copy[k] = deepCopy(v)
				end
				return copy
			else
				return value
			end
		end

		local questCopy = deepCopy(questTemplate)
		playerQuests[player][questId] = questCopy

		-- Notify client
		QuestUpdatedEvent:FireClient(player)
	end
end

-- 🔹 Remove quest
function QuestManager.RemoveQuest(player, questId)
	if playerQuests[player] and playerQuests[player][questId] then
		playerQuests[player][questId] = nil
		-- Notify client
		QuestUpdatedEvent:FireClient(player)
	end
end

-- 🔹 Get all active quests
function QuestManager.GetQuests(player)
	return playerQuests[player] or {}
end

-- 🔹 Check if quest is completed (all objectives done)
function QuestManager.CheckCompletion(player, questId)
	local quests = playerQuests[player]
	if not quests then
		return false
	end

	local quest = quests[questId]
	if not quest then
		return false
	end

	-- Check if all objectives are done
	for _, obj in ipairs(quest.Objectives) do
		if not obj.Completed then
			return false
		end
	end

	-- Mark completed
	quest.Completed = true

	-- Rewards
	local stats = player:FindFirstChild("Stats")
	if stats then
		local xp = stats:FindFirstChild("XP")
		if xp then
			xp.Value += (quest.RewardXP or 0)
		end
	end

	-- Reward items
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, itemName in ipairs(quest.RewardItems or {}) do
			local template = ReplicatedStorage.Items.StandItems.InventoryTools:FindFirstChild(itemName)
			if template then
				local existing = backpack:FindFirstChild(itemName)
				if existing then
					local currentAmount = existing:GetAttribute("amount") or 1
					existing:SetAttribute("amount", currentAmount + 1)
				else
					local newItem = template:Clone()
					newItem.Parent = backpack
					newItem:SetAttribute("amount", 1)
				end
			end
		end
	end

	-- Remove the quest
	QuestManager.RemoveQuest(player, questId)

	-- Add NextQuest if defined
	if quest.NextQuest then
		QuestManager.AddQuest(player, quest.NextQuest)
	end

	return true
end

-- 🔹 Objective updates
function QuestManager.TalkedTo(player, npcName)
	local quests = playerQuests[player]
	if not quests then
		return
	end

	for questId, quest in pairs(quests) do
		if not quest.Completed then
			for _, obj in ipairs(quest.Objectives) do
				if obj.Type == "Talk" and obj.Target == npcName and not obj.Completed then
					obj.Completed = true
				end
			end
			-- Auto check quest after progress
			QuestManager.CheckCompletion(player, questId)
		end
	end
end

function QuestManager.DefeatedEnemy(player, enemyName)
	local quests = playerQuests[player]
	if not quests then
		return
	end

	for questId, quest in pairs(quests) do
		if not quest.Completed then
			for _, obj in ipairs(quest.Objectives) do
				if obj.Type == "Defeat" and obj.Target == enemyName and not obj.Completed then
					obj.Progress = (obj.Progress or 0) + 1
					-- Inside QuestManager.DefeatedEnemy
					if obj.Progress >= obj.Required then
						obj.Completed = true

						-- If quest requires turn-in, mark it ready
						if quest.TurnInNpc then
							quest.ReadyToTurnIn = true
						else
							QuestManager.CompleteQuest(player, questId)
						end
					end
				end
			end
		end
	end
end

-- 🔹 Cleanup
Players.PlayerRemoving:Connect(function(player)
	playerQuests[player] = nil
end)

-- 🔹 Give starting quest
Players.PlayerAdded:Connect(function(player)
	task.defer(function()
		local quests = QuestManager.GetQuests(player)
		if next(quests) == nil then
			QuestManager.AddQuest(player, "TalkToGiorno1")
		end
	end)
end)

-- 🔹 RemoteFunction handler for clients
QuestDataEvent.OnServerInvoke = function(player)
	return QuestManager.GetQuests(player)
end

-- 🔹 Complete quest
function QuestManager.CompleteQuest(player, questId)
	local quests = playerQuests[player]
	if not quests or not quests[questId] then
		warn("Player does not have quest:", questId)
		return
	end

	local quest = quests[questId]

	-- ✅ Reward XP
	if quest.RewardXP and quest.RewardXP > 0 then
		local stats = player:FindFirstChild("Stats")
		if stats then
			local xp = stats:FindFirstChild("XP")
			if xp then
				xp.Value += quest.RewardXP
			end
		end
	end

	-- ✅ Reward Items
	if quest.RewardItems then
		for _, itemName in ipairs(quest.RewardItems) do
			-- Fire an inventory add event, or just put in Backpack/leaderstats
			-- Example:
			local backpack = player:FindFirstChild("Backpack")
			if backpack and ReplicatedStorage.Items:FindFirstChild(itemName) then
				ReplicatedStorage.Items[itemName]:Clone().Parent = backpack
			end
		end
	end

	-- ✅ Remove quest from active list
	quests[questId] = nil

	-- ✅ Add next quest(s)
	if quest.NextQuest then
		if typeof(quest.NextQuest) == "table" then
			for _, nextId in ipairs(quest.NextQuest) do
				QuestManager.AddQuest(player, nextId)
			end
		else
			QuestManager.AddQuest(player, quest.NextQuest)
		end
	end

	-- ✅ Notify client
	QuestUpdatedEvent:FireClient(player)
end

return QuestManager
