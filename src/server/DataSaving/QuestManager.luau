local QuestManager = {}

-- Active and completed quests per player
local playerQuests = {}
local playerCompletedQuests = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryManager = require(script.Parent.InventoryManager)
local QuestDefinitions = require(script.Parent:WaitForChild("QuestDefinitions"))
local XPSystem = require(game.ServerScriptService.DataSaving:WaitForChild("XPSystem"))
local CashSystem = require(game.ServerScriptService.DataSaving:WaitForChild("CashSystem"))
local HeroManager = require(game.ServerScriptService.DataSaving:WaitForChild("HeroManager"))

-- Remote events/functions for client sync
local QuestEventsFolder = ReplicatedStorage:WaitForChild("QuestEvents")

local QuestDataEvent = Instance.new("RemoteFunction")
QuestDataEvent.Name = "GetQuestData"
QuestDataEvent.Parent = QuestEventsFolder

local QuestUpdatedEvent = Instance.new("RemoteEvent")
QuestUpdatedEvent.Name = "QuestUpdated"
QuestUpdatedEvent.Parent = QuestEventsFolder

-- Initialize player quest data safely
local function InitPlayerData(player)
	playerQuests[player] = playerQuests[player] or {}
	playerCompletedQuests[player] = playerCompletedQuests[player] or {}
end

local function deepCopy(value)
	if type(value) == "table" then
		local copy = {}
		for k, v in pairs(value) do
			copy[k] = deepCopy(v)
		end
		return copy
	end
	return value
end

-- 🔹 Utility functions
function QuestManager.HasQuest(player, questId)
	return playerQuests[player] and playerQuests[player][questId] ~= nil
end

function QuestManager.HasPlayerCompletedQuest(player, questId)
	return playerCompletedQuests[player] and playerCompletedQuests[player][questId] == true
end

function QuestManager.MarkQuestCompleted(player, questId)
	playerCompletedQuests[player] = playerCompletedQuests[player] or {}
	playerCompletedQuests[player][questId] = true
end

function QuestManager.GetQuests(player)
	return playerQuests[player] or {}
end

function QuestManager.GetCompletedQuests(player)
	return playerCompletedQuests[player] or {}
end

function QuestManager.SetCompletedQuests(player, data)
	playerCompletedQuests[player] = data or {}
end

function QuestManager.ResetQuestline(player)
	playerCompletedQuests[player] = {}
	playerQuests[player] = {}
	QuestManager.AddQuest(player, "TalkToGiorno1")
end

function QuestManager.Clear(player)
	playerCompletedQuests[player] = {}
	playerQuests[player] = {}
end

-- 🔹 Add quest
function QuestManager.AddQuest(player, questId)
	InitPlayerData(player)

	local def = QuestDefinitions[questId]
	if not def then
		warn("Quest ID not found:", questId)
		return
	end

	if QuestManager.HasQuest(player, questId) then
		return
	end

	if not def.Repeatable and QuestManager.HasPlayerCompletedQuest(player, questId) then
		return
	end

	playerQuests[player][questId] = deepCopy(def)

	QuestManager.Sync(player)
end

-- 🔹 Remove quest
function QuestManager.RemoveQuest(player, questId)
	if playerQuests[player] then
		playerQuests[player][questId] = nil
	end
	QuestManager.Sync(player)
end

-- 🔹 Complete a quest
function QuestManager.CompleteQuest(player, questId)
	local quests = playerQuests[player]
	if not quests or not quests[questId] then
		return
	end

	local quest = quests[questId]

	quest.Completed = true

	if not quest.Repeatable then
		QuestManager.MarkQuestCompleted(player, questId)
	end

	-- Rewards
	if quest.RewardXP then
		XPSystem.AddXP(player, quest.RewardXP)
	end

	if quest.RewardCash then
		CashSystem.AddCash(player, quest.RewardCash)
	end

	if quest.RewardItems then
		for _, itemName in ipairs(quest.RewardItems) do
			InventoryManager.AddItem(player, itemName, 1)
		end
	end

	-- Remove quest AFTER rewards
	QuestManager.RemoveQuest(player, questId)

	-- Queue next quests
	if quest.NextQuest then
		if typeof(quest.NextQuest) == "table" then
			for _, nextId in ipairs(quest.NextQuest) do
				QuestManager.AddQuest(player, nextId)
			end
		else
			QuestManager.AddQuest(player, quest.NextQuest)
		end
	end

	QuestManager.Sync(player)
end

-- 🔹 Check if a quest is complete
function QuestManager.CheckCompletion(player, questId)
	local quests = playerQuests[player]
	if not quests then
		return false
	end

	local quest = quests[questId]
	if not quest then
		return false
	end

	for _, obj in ipairs(quest.Objectives or {}) do
		if not obj.Completed then
			return false
		end
	end

	-- If TurnInNpc exists, set ReadyToTurnIn; else complete immediately
	if quest.TurnInNpc then
		quest.ReadyToTurnIn = true
	else
		QuestManager.CompleteQuest(player, questId)
	end

	return true
end

local function HasActiveQuestFromNPC(player, npcName)
	local quests = playerQuests[player]
	if not quests then
		return false
	end

	for questId, questData in pairs(quests) do
		local def = QuestDefinitions[questId]
		if def and def.Giver == npcName and not questData.Completed then
			return true
		end
	end

	return false
end

-- 🔹 Unified NPC interaction
function QuestManager.InteractWithNPC(player, npcName)
	local quests = playerQuests[player] or {}
	local completedQuests = playerCompletedQuests[player] or {}

	-- Helper: true if all objectives completed
	local function objectivesCompleted(questData)
		for _, obj in ipairs(questData.Objectives) do
			if not obj.Completed then
				return false
			end
		end
		return true
	end

	--------------------------------------------------------------------
	-- 1️⃣ Check ACTIVE quests first (Talk objectives, Turn-ins)
	--------------------------------------------------------------------
	for questId, questData in pairs(quests) do
		local def = QuestDefinitions[questId]

		-- TALK objectives
		for _, obj in ipairs(questData.Objectives) do
			if obj.Type == "Talk" and obj.Target == npcName and not obj.Completed then
				obj.Completed = true
				QuestManager.CheckCompletion(player, questId)
				return def.Dialog.InProgress or { "Thanks." }, "InProgress", questId
			end

			if obj.Type == "CheckPowers" and not obj.Completed then
				-- Replace this with your actual player specialty check
				if HeroManager.GetField(player, obj.Target) == obj.Value then
					obj.Completed = true
					QuestManager.CheckCompletion(player, questId)
					return def.Dialog.InProgress or { "You have proven your power." }, "InProgress", questId
				end
			end
		end

		-- TURN-IN CHECK
		if def.TurnInNpc then
			local list = (typeof(def.TurnInNpc) == "table") and def.TurnInNpc or { def.TurnInNpc }

			if table.find(list, npcName) then
				-- If all objectives done → complete quest
				if objectivesCompleted(questData) then
					QuestManager.CompleteQuest(player, questId)
					return def.Dialog.TurnIn or { "Quest completed." }, "TurnIn", questId
				else
					-- Talking to turn-in NPC but not done
					return def.Dialog.InProgress or { "You're not done yet." }, "InProgress", questId
				end
			end
		end
	end

	--------------------------------------------------------------------
	-- 2️⃣ If the player has no ACTIVE quest from this NPC → offer a quest
	--------------------------------------------------------------------

	-- The player has 0 or more active quests, but none from THIS npc → allow offers.
	for questId, def in pairs(QuestDefinitions) do
		if def.Giver == npcName then
			local alreadyCompleted = completedQuests[questId] == true
			local isRepeatable = def.Repeatable == true

			-- Offer repeatable quests EVEN if completed
			if isRepeatable then
				-- Don't offer again if the player already has this quest active
				if quests[questId] == nil then
					QuestManager.AddQuest(player, questId)
					return def.Dialog.Offer, "Offer", questId
				end
			end

			-- Offer normal quests ONLY if not completed yet
			if not isRepeatable and not alreadyCompleted then
				if quests[questId] == nil then
					QuestManager.AddQuest(player, questId)
					return def.Dialog.Offer, "Offer", questId
				end
			end
		end
	end

	--------------------------------------------------------------------
	-- 3️⃣ If we are here, NPC has nothing for this player
	--------------------------------------------------------------------
	return npcName .. " has nothing for you.", "None", nil
end

-- 🔹 Handle defeating enemies for any quest type
function QuestManager.DefeatedEnemy(player, enemyName)
	local quests = playerQuests[player]
	if not quests then
		return
	end

	local questChanged = false

	for questId, quest in pairs(quests) do
		if not quest.Completed then
			for _, obj in ipairs(quest.Objectives or {}) do
				if obj.Type == "Defeat" and obj.Target == enemyName and not obj.Completed then
					obj.Progress = (obj.Progress or 0) + 1
					questChanged = true

					if obj.Progress >= (obj.Required or 1) then
						obj.Completed = true
					end

					-- 🔥 THIS WAS MISSING
					QuestManager.CheckCompletion(player, questId)
				end
			end
		end
	end

	if questChanged then
		QuestManager.Sync(player)
	end
end

-- 🔹 NPC dialog state
function QuestManager.GetNpcDialog(player, npcName)
	local quests = playerQuests[player]
	if not quests then
		return "repeat", nil
	end

	for questId, quest in pairs(quests) do
		local def = QuestDefinitions[questId]
		if def and def.Giver == npcName then
			-- 1️⃣ Ready to turn the quest in
			if quest.ReadyToTurnIn then
				return "Completed", questId

			-- 2️⃣ Started but not complete
			elseif quest.Started and not quest.Completed then
				return "InProgress", questId

			-- 3️⃣ Never started
			elseif not quest.Started then
				return "Offer", questId
			end
		end
	end

	-- 4️⃣ NPC not related to a quest
	return "repeat", nil
end

function QuestManager.Sync(player)
	print("sync and update event fired")
	QuestUpdatedEvent:FireClient(player, QuestManager.GetQuests(player))
	print("sync fully working")
end

-- Cleanup on player leave
function QuestManager.Cleanup(player)
	playerQuests[player] = nil
	playerCompletedQuests[player] = nil
end

-- RemoteFunction handler for clients
QuestDataEvent.OnServerInvoke = function(player)
	return QuestManager.GetQuests(player)
end

return QuestManager
