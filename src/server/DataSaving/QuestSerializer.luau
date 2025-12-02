-- QuestSerializer.lua
local QuestSerializer = {}

function QuestSerializer.SerializeActive(questManager, player)
	local quests = questManager.GetQuests(player)
	local result = {}

	for questId, quest in pairs(quests) do
		result[questId] = {
			Completed = quest.Completed or false,
			ReadyToTurnIn = quest.ReadyToTurnIn or false,
			Objectives = {},
		}

		for i, obj in ipairs(quest.Objectives) do
			result[questId].Objectives[i] = {
				Type = obj.Type,
				Target = obj.Target,
				Completed = obj.Completed,
				Progress = obj.Progress,
				Required = obj.Required,
			}
		end
	end

	return result
end

function QuestSerializer.DeserializeActive(questManager, player, data)
	if not data then
		return
	end

	for questId, info in pairs(data) do
		questManager.AddQuest(player, questId)
		local q = questManager.GetQuests(player)[questId]
		if q then
			q.Completed = info.Completed
			q.ReadyToTurnIn = info.ReadyToTurnIn
			for i, obj in ipairs(info.Objectives) do
				if q.Objectives[i] then
					q.Objectives[i].Completed = obj.Completed
					q.Objectives[i].Progress = obj.Progress
				end
			end
		end
	end
end

function QuestSerializer.SerializeCompleted(questManager, player)
	return questManager.GetCompletedQuests(player) or {}
end

function QuestSerializer.DeserializeCompleted(questManager, player, data)
	if data then
		questManager.SetCompletedQuests(player, data)
	end
end

return QuestSerializer
