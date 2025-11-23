-- SaveData.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")

local StandItemsFolder = ReplicatedStorage.Items.StandItems:WaitForChild("InventoryTools")
local RaceItemsFolder = ReplicatedStorage.Items.RaceItems:WaitForChild("InventoryTools")
local playerDataStore = DataStoreService:GetDataStore("PlayerData")

local QuestManager = require(ServerScriptService.DataSaving:WaitForChild("QuestManager"))

-- Inventory serialization
local function serializeInventory(player)
	local data = {}
	for _, tool in ipairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			table.insert(data, { Name = tool.Name, Amount = tool:GetAttribute("amount") or 1 })
		end
	end
	return data
end

local function deserializeInventory(player, data)
	if not data then
		return
	end
	local backpack = player:WaitForChild("Backpack")

	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
		end
	end

	for _, itemData in ipairs(data) do
		local toolTemplate = StandItemsFolder:FindFirstChild(itemData.Name)
			or RaceItemsFolder:FindFirstChild(itemData.Name)
		if toolTemplate then
			local tool = toolTemplate:Clone()
			tool:SetAttribute("amount", itemData.Amount or 1)
			tool.Parent = backpack
		else
			warn("⚠️ Missing tool template for", itemData.Name)
		end
	end
end

-- Quests serialization
local function serializeQuests(player)
	local quests = QuestManager.GetQuests(player)
	local data = {}
	for questId, quest in pairs(quests) do
		data[questId] = {
			Completed = quest.Completed or false,
			ReadyToTurnIn = quest.ReadyToTurnIn or false,
			Objectives = {},
		}
		for i, obj in ipairs(quest.Objectives or {}) do
			data[questId].Objectives[i] = {
				Type = obj.Type,
				Target = obj.Target,
				Completed = obj.Completed,
				Progress = obj.Progress or 0,
				Required = obj.Required or 0,
			}
		end
	end
	return data
end

local function deserializeQuests(player, questData)
	if not questData then
		return
	end
	for questId, questInfo in pairs(questData) do
		QuestManager.AddQuest(player, questId)
		local playerQuest = QuestManager.GetQuests(player)[questId]
		if playerQuest then
			playerQuest.Completed = questInfo.Completed
			playerQuest.ReadyToTurnIn = questInfo.ReadyToTurnIn or false
			for i, objInfo in ipairs(questInfo.Objectives) do
				if playerQuest.Objectives[i] then
					playerQuest.Objectives[i].Completed = objInfo.Completed
					playerQuest.Objectives[i].Progress = objInfo.Progress
				end
			end
		end
	end
end

-- Completed quests serialization
local function serializeCompletedQuests(player)
	local completed = QuestManager.GetCompletedQuests(player) or {}
	local data = {}
	for questId in pairs(completed) do
		data[questId] = true
	end
	return data
end

local function deserializeCompletedQuests(player, data)
	if not data then
		return
	end
	QuestManager.SetCompletedQuests(player, data)
end

-- Save all player data
local function savePlayerData(player)
	local stats = player:FindFirstChild("Stats")
	local powers = player:FindFirstChild("Powers")
	local data = {
		Inventory = serializeInventory(player),
		Hero = powers and powers:FindFirstChild("Hero") and powers.Hero.Value or "",
		Specialty = powers and powers:FindFirstChild("Specialty") and powers.Specialty.Value or "",
		Race = powers and powers:FindFirstChild("Race") and powers.Race.Value or "Human",
		XP = stats and stats:FindFirstChild("XP") and stats.XP.Value or 0,
		Level = stats and stats:FindFirstChild("Level") and stats.Level.Value or 1,
		MaxXP = stats and stats:FindFirstChild("MaxXP") and stats.MaxXP.Value or 100,
		Cash = stats and stats:FindFirstChild("Cash") and stats.Cash.Value or 0,
		Quests = serializeQuests(player),
		CompletedQuests = serializeCompletedQuests(player),
	}

	local success, err = pcall(function()
		playerDataStore:SetAsync(player.UserId .. "_Data", data)
	end)
	if not success then
		warn("⚠️ Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end
end

-- Load all player data
local function loadPlayerData(player)
	local success, data = pcall(function()
		return playerDataStore:GetAsync(player.UserId .. "_Data")
	end)
	if not success then
		warn("⚠️ Failed to load data for " .. player.Name .. ": " .. tostring(data))
		return nil
	end
	return data
end

-- Handle character respawn
local function setupCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	local powersFolder = player:FindFirstChild("Powers")
	if not powersFolder then
		powersFolder = Instance.new("Folder")
		powersFolder.Name = "Powers"
		powersFolder.Parent = player
	end

	local charPowers = Instance.new("Folder")
	charPowers.Name = "Powers"
	charPowers.Parent = character

	for _, statName in ipairs({ "Hero", "Specialty", "Race" }) do
		local value = Instance.new("StringValue")
		value.Name = statName
		value.Value = powersFolder and powersFolder:FindFirstChild(statName) and powersFolder[statName].Value or ""
		value.Parent = charPowers
		if powersFolder and powersFolder:FindFirstChild(statName) then
			powersFolder[statName].Changed:Connect(function()
				value.Value = powersFolder[statName].Value
			end)
		end
	end

	-- Restore equipped tools on death + save
	humanoid.Died:Connect(function()
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") then
				tool.Parent = player.Backpack
			end
		end
		savePlayerData(player)
	end)
end

-- Player connections
Players.PlayerAdded:Connect(function(player)
	local savedData = loadPlayerData(player)

	-- Create powers folder
	local powersFolder = Instance.new("Folder")
	powersFolder.Name = "Powers"
	powersFolder.Parent = player
	for _, statName in ipairs({ "Hero", "Specialty", "Race" }) do
		local value = Instance.new("StringValue")
		value.Name = statName
		value.Value = savedData and savedData[statName] or ""
		value.Parent = powersFolder
	end

	-- Restore completed quests first
	if savedData and savedData.CompletedQuests then
		deserializeCompletedQuests(player, savedData.CompletedQuests)
	else
		-- Initialize empty table to avoid nil
		QuestManager.SetCompletedQuests(player, {})
	end

	-- Restore active quests
	if savedData and savedData.Quests then
		deserializeQuests(player, savedData.Quests)
	end

	-- Add starting quest only if not completed and not already active
	if
		not QuestManager.HasPlayerCompletedQuest(player, "TalkToGiorno1")
		and not QuestManager.GetQuests(player)["TalkToGiorno1"]
	then
		QuestManager.AddQuest(player, "TalkToGiorno1")
	end

	-- Restore XP/Level
	if savedData and player:FindFirstChild("Stats") then
		local stats = player.Stats
		stats.XP.Value = savedData.XP or stats.XP.Value
		stats.Level.Value = savedData.Level or stats.Level.Value
		stats.MaxXP.Value = savedData.MaxXP or stats.MaxXP.Value
		stats.Cash.Value = savedData.Cash or stats.Cash.Value
	end

	-- Character setup
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
		local latestData = loadPlayerData(player)
		if latestData and latestData.Inventory then
			task.defer(function()
				deserializeInventory(player, latestData.Inventory)
			end)
		end
	end)

	-- Auto-save backpack changes
	local backpack = player:WaitForChild("Backpack")
	backpack.ChildAdded:Connect(function()
		savePlayerData(player)
	end)
	backpack.ChildRemoved:Connect(function()
		savePlayerData(player)
	end)

	-- Periodic autosave
	task.spawn(function()
		while player.Parent do
			task.wait(60)
			savePlayerData(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
end)
