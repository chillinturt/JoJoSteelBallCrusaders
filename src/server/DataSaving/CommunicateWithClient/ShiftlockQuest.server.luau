local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestManager = require(game.ServerScriptService.DataSaving.QuestManager)

local ShiftLockEvent = ReplicatedStorage:WaitForChild("QuestEvents"):WaitForChild("ShiftLockUsed")

ShiftLockEvent.OnServerEvent:Connect(function(player)
	print("shiftlock event connected on server")
	if QuestManager.HasQuest(player, "ShiftLockTutorial") then
		QuestManager.CompleteQuest(player, "ShiftLockTutorial")
		print("Quest complete")
	end
end)
