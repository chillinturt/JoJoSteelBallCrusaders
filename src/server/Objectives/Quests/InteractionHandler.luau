local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local QuestManager = require(ServerScriptService.DataSaving.QuestManager)
local QuestDefinitions = require(ServerScriptService.DataSaving.QuestDefinitions)
local XPSystem = require(ServerScriptService.DataSaving.XPSystem)
local BoatService = require(ServerScriptService.VehicleSystem.BoatService)

local interactionEvents = ReplicatedStorage:WaitForChild("InteractionEvents")
local OpenInteraction = interactionEvents:WaitForChild("OpenInteraction")
local InteractionResponse = interactionEvents:WaitForChild("InteractionResponse")

local activeInteractions = {}

local InteractionHandler = {}

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function getQuestsForNpc(npcName)
	local quests = {}

	for questId, questData in pairs(QuestDefinitions) do
		if questData.Giver == npcName and not questData._isUnlockQuest then
			table.insert(quests, {
				Id = questId,
				Data = questData,
			})
		end
	end

	return quests
end

local function getNpcName(npcModel)
	local npcName = npcModel:FindFirstChild("NPCName")

	if not npcName or not npcName:IsA("StringValue") then
		warn("NPC missing NPCName:", npcModel:GetFullName())
		return nil
	end

	return npcName.Value
end

--------------------------------------------------
-- Boat shop UI
--------------------------------------------------

local function openBoatShop(player, npcModel)
	local npcName = getNpcName(npcModel)
	if not npcName then return end

	local boats = BoatService.GetBoatsForDealer(npcName)
	local buttons = {}

	for _, boatInfo in ipairs(boats) do
		local priceText = boatInfo.Data.Price == 0 and "(FREE)" or ("($" .. boatInfo.Data.Price .. ")")
		table.insert(buttons, {
			Text = boatInfo.Data.Name .. " " .. priceText,
			Action = "ShowBoat:" .. boatInfo.Id,
		})
	end

	if BoatService.HasBoat(player) then
		table.insert(buttons, {
			Text = "Despawn My Boat",
			Action = "DespawnBoat",
		})
	end

	table.insert(buttons, { Text = "Nevermind", Close = true })

	OpenInteraction:FireClient(player, {
		InteractionId = npcModel.Name,
		Text = "Welcome to the marina! What can I do for you?",
		Buttons = buttons,
	})
end

local function openBoatPage(player, npcModel, boatId)
	local def = BoatService.GetBoatDefinition(boatId)
	if not def then
		warn("Unknown boat:", boatId)
		return
	end

	local priceText = def.Price == 0
		and '<font color="#55FF55">FREE</font>'
		or '<font color="#55FF55">$' .. def.Price .. "</font>"

	local text = "<b>" .. def.Name .. "</b>"
		.. "\n\n" .. def.Description
		.. "\n\nPrice: " .. priceText
		.. "\nTop Speed: " .. def.MaxSpeed

	OpenInteraction:FireClient(player, {
		InteractionId = npcModel.Name,
		Text = text,
		Buttons = {
			{ Text = "Buy",     Action = "BuyBoat:" .. boatId },
			{ Text = "Return",  Action = "ReturnToBoatShop" },
			{ Text = "Nevermind", Close = true },
		},
	})
end

--------------------------------------------------
-- Quest list UI
--------------------------------------------------

local function openQuestList(player, npcModel)
	local npcName = getNpcName(npcModel)

	if not npcName then
		return
	end

	local buttons = {}

	for _, questInfo in ipairs(getQuestsForNpc(npcName)) do
		local label = questInfo.Data.Name
		if questInfo.Data.MinimumLevel then
			label = label .. " (Lv. " .. questInfo.Data.MinimumLevel .. ")"
		end
		table.insert(buttons, {
			Text = label,
			Action = "ShowQuest:" .. questInfo.Id,
		})
	end

	table.insert(buttons, {
		Text = "Nevermind",
		Close = true,
	})

	OpenInteraction:FireClient(player, {
		InteractionId = npcModel.Name,
		Text = "Select a quest.",
		Buttons = buttons,
	})
end

local function openQuestPage(player, npcModel, questId)
	local quest = QuestDefinitions[questId]

	if not quest then
		warn("Unknown quest:", questId)
		return
	end

	local levelText = ""
	if quest.MinimumLevel then
		levelText = '\n\n<font color="#FF5555">Required Level: ' .. quest.MinimumLevel .. "</font>"
	end

	local text = "Description: "
		.. quest.Description
		.. "\n\nReward:\n"
		.. '<font color="#55FF55">$'
		.. quest.RewardCash
		.. "</font>\n"
		.. '<font color="#FFDC50">'
		.. quest.RewardXP
		.. " Exp</font>"
		.. levelText

	OpenInteraction:FireClient(player, {
		InteractionId = npcModel.Name,
		Text = text,

		Buttons = {
			{
				Text = "Confirm",
				Action = "AcceptQuest:" .. questId,
			},

			{
				Text = "Return",
				Action = "ReturnToQuestList",
			},

			{
				Text = "Nevermind",
				Close = true,
			},
		},
	})
end

-- module functions

function InteractionHandler.OpenNPCInteraction(player, npcModel)
	activeInteractions[player] = npcModel

	-- Silently complete any active unlock quest for this NPC before opening the UI.
	-- These quests are never shown in the selection list; interacting with the NPC is enough.
	local npcName = getNpcName(npcModel)
	if npcName then
		local unlockId = "Unlock_" .. npcName
		if QuestDefinitions[unlockId] and QuestManager.HasQuest(player, unlockId) then
			QuestManager.CompleteQuest(player, unlockId)
		end
	end

	if npcName and BoatService.IsBoatDealer(npcName) then
		openBoatShop(player, npcModel)
		return
	end

	openQuestList(player, npcModel)
end

--------------------------------------------------
-- Responses
--------------------------------------------------

InteractionResponse.OnServerEvent:Connect(function(player, interactionId, action)
	local npcModel = activeInteractions[player]
	if not npcModel then return end

	------------------------------------------------
	-- No-argument actions
	------------------------------------------------
	if action == "ReturnToQuestList" then
		openQuestList(player, npcModel)
		return
	end

	if action == "ReturnToBoatShop" then
		openBoatShop(player, npcModel)
		return
	end

	if action == "DespawnBoat" then
		local _, msg = BoatService.DespawnBoat(player)
		OpenInteraction:FireClient(player, {
			InteractionId = npcModel.Name,
			Text = msg,
			Buttons = {
				{ Text = "Browse Boats", Action = "ReturnToBoatShop" },
				{ Text = "Close", Close = true },
			},
		})
		return
	end

	------------------------------------------------
	-- Actions with an ID  (type:id)
	------------------------------------------------
	local actionType, actionId = string.match(action, "([^:]+):(.+)")
	if not actionType or not actionId then return end

	-- Boat actions
	if actionType == "ShowBoat" then
		openBoatPage(player, npcModel, actionId)
		return
	end

	if actionType == "BuyBoat" then
		local _, msg = BoatService.BuyBoat(player, actionId, npcModel)
		OpenInteraction:FireClient(player, {
			InteractionId = npcModel.Name,
			Text = msg,
			Buttons = {
				{ Text = "Browse Boats", Action = "ReturnToBoatShop" },
				{ Text = "Close", Close = true },
			},
		})
		return
	end

	-- Quest actions
	local quest = QuestDefinitions[actionId]
	if not quest then
		warn("InteractionHandler: unknown quest/action id:", actionId)
		return
	end

	if actionType == "ShowQuest" then
		openQuestPage(player, npcModel, actionId)

	elseif actionType == "AcceptQuest" then
		if quest.MinimumLevel then
			local level = XPSystem.GetStats(player).Level
			if level < quest.MinimumLevel then
				OpenInteraction:FireClient(player, {
					InteractionId = npcModel.Name,
					Text = 'You must be level ' .. quest.MinimumLevel .. ' to accept "' .. quest.Name .. '".',
					Buttons = {
						{ Text = "Return", Action = "ReturnToQuestList" },
						{ Text = "Nevermind", Close = true },
					},
				})
				return
			end
		end

		if not QuestManager.HasQuest(player, actionId) then
			QuestManager.AddQuest(player, actionId)
		end

		OpenInteraction:FireClient(player, {
			InteractionId = npcModel.Name,
			Text = quest.Dialog.Offer[1] or ('Good luck completing "' .. quest.Name .. '".'),
			Buttons = {
				{ Text = "Close", Close = true },
			},
		})
	end
end)

Players.PlayerRemoving:Connect(function(player)
	activeInteractions[player] = nil
end)

return InteractionHandler
