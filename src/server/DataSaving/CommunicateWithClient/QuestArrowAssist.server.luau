local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestManager = require(game.ServerScriptService.DataSaving:WaitForChild("QuestManager"))

local QuestEventsFolder = ReplicatedStorage:WaitForChild("QuestEvents")
local arrowVisible = Instance.new("BindableEvent")
arrowVisible.Name = "QuestArrowVisible"
arrowVisible.Parent = QuestEventsFolder

Players.PlayerAdded:Connect(function(player)
	-- Wait for character to load
	player.CharacterAdded:Connect(function()
		task.delay(3, function()
			QuestManager.Sync(player)
		end)
	end)
end)
