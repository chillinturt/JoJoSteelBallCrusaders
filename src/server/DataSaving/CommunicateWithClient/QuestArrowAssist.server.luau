local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestManager = require(game.ServerScriptService.DataSaving:WaitForChild("QuestManager"))

local QuestEventsFolder = ReplicatedStorage:WaitForChild("QuestEvents")
local arrowVisible = Instance.new("BindableEvent")
arrowVisible.Name = "QuestArrowVisible"
arrowVisible.Parent = QuestEventsFolder

Players.PlayerAdded:Connect(function(player)
	-- Wait for character to load
	local char = player.Character or player.CharacterAdded:Wait()

	-- Optional: wait a short moment to ensure client scripts ran
	task.wait(5)

	QuestManager.Sync(player)
end)
