local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local QuestManager = require(ServerScriptService.DataSaving.QuestManager)

local QuestDefinitions = require(ServerScriptService.DataSaving.QuestDefinitions)

local interactionEvents = ReplicatedStorage:WaitForChild("InteractionEvents")

local OpenInteraction = interactionEvents:WaitForChild("OpenInteraction")

local InteractionResponse = interactionEvents:WaitForChild("InteractionResponse")

print("Server InteractionResponse:", InteractionResponse:GetFullName())

local banditQuest = QuestDefinitions.DefeatBanditsRepeatable

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function openQuestList(player)
	OpenInteraction:FireClient(player, {

		InteractionId = "BanditQuestNPC",

		Text = "Select a quest.",

		Buttons = {

			{
				Text = "Bandits",
				Action = "ShowBanditQuest",
			},

			{
				Text = "Nevermind",
				Close = true,
			},
		},
	})
end

local function openBanditQuestPage(player)
	local rewardCash = banditQuest.RewardCash
	local rewardXP = banditQuest.RewardXP

	local text = "Level Required: 0\n"
		.. "Description: "
		.. banditQuest.Description
		.. "\n\nReward:\n"
		.. '<font color="#55FF55">$'
		.. rewardCash
		.. "</font>\n"
		.. '<font color="#FFDC50">'
		.. rewardXP
		.. " Exp</font>"

	OpenInteraction:FireClient(player, {
		InteractionId = "BanditQuestNPC",
		--InstantText = true,
		Text = text,
		Buttons = {
			{ Text = "Confirm", Action = "AcceptBanditQuest" },
			{ Text = "Return", Action = "ReturnToQuestList" },
			{ Text = "Nevermind", Close = true },
		},
	})
end

--------------------------------------------------
-- Responses
--------------------------------------------------

InteractionResponse.OnServerEvent:Connect(function(player, interactionId, action)
	if interactionId ~= "BanditQuestNPC" then
		return
	end

	if action == "ShowBanditQuest" then
		print("Opening bandit quest page")
		openBanditQuestPage(player)
	elseif action == "ReturnToQuestList" then
		print("Returning to list")
		openQuestList(player)
	elseif action == "AcceptBanditQuest" then
		print("Accepting quest")
		if not QuestManager.HasQuest(player, "DefeatBanditsRepeatable") then
			QuestManager.AddQuest(player, "DefeatBanditsRepeatable")
		end

		OpenInteraction:FireClient(player, {

			InteractionId = "BanditQuestNPC",

			Text = "Good luck. Come back when you've defeated 5 Bandits.",

			Buttons = {

				{
					Text = "Close",
					Close = true,
				},
			},
		})
	end
end)
