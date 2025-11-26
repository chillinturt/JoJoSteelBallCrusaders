-- SaveData.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")

-- References
local StandItemsFolder = ReplicatedStorage.Items.StandItems:WaitForChild("InventoryTools")
local RaceItemsFolder = ReplicatedStorage.Items.RaceItems:WaitForChild("InventoryTools")
local playerDataStore = DataStoreService:GetDataStore("PlayerData")
local QuestManager = require(ServerScriptService.DataSaving:WaitForChild("QuestManager"))

---------------------------------------------------------------------
-- INVENTORY SERIALIZATION
---------------------------------------------------------------------
local function serializeInventory(player)
	local data = {}
	for _, tool in ipairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			table.insert(data, {
				Name = tool.Name,
				Amount = tool:GetAttribute("amount") or 1,
			})
		end
	end
	return data
end

local function deserializeInventory(player, data)
	if not data then
		return
	end
	local backpack = player:WaitForChild("Backpack")

	-- Clear existing tools
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
		end
	end

	-- Restore saved tools
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

---------------------------------------------------------------------
-- QUESTS SERIALIZATION
---------------------------------------------------------------------
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

---------------------------------------------------------------------
-- PLAYER DATA SAVE / LOAD
---------------------------------------------------------------------
local function savePlayerData(player)
	local stats = player:FindFirstChild("Stats")
	local powers = player:FindFirstChild("Powers")
	local upgradeFolder = player:FindFirstChild("UpgradeData")

	-- Build UpgradeData table
	local upgradeTable = {}
	if upgradeFolder then
		for _, upgrade in ipairs(upgradeFolder:GetChildren()) do
			if upgrade:IsA("IntValue") then
				upgradeTable[upgrade.Name] = upgrade.Value
			end
		end
	end

	local data = {
		Inventory = serializeInventory(player),
		Hero = powers and powers:FindFirstChild("Hero") and powers.Hero.Value or "",
		Specialty = powers and powers:FindFirstChild("Specialty") and powers.Specialty.Value or "",
		Race = powers and powers:FindFirstChild("Race") and powers.Race.Value or "Human",
		XP = stats and stats:FindFirstChild("XP") and stats.XP.Value or 0,
		Level = stats and stats:FindFirstChild("Level") and stats.Level.Value or 1,
		AbilityPoints = stats and stats:FindFirstChild("AbilityPoints") and stats.AbilityPoints.Value or 0,
		MaxXP = stats and stats:FindFirstChild("MaxXP") and stats.MaxXP.Value or 100,
		Cash = stats and stats:FindFirstChild("Cash") and stats.Cash.Value or 0,
		Quests = serializeQuests(player),
		CompletedQuests = serializeCompletedQuests(player),
		UpgradeData = upgradeTable,
	}

	local success, err = pcall(function()
		playerDataStore:SetAsync(player.UserId .. "_Data", data)
	end)
	if not success then
		warn("⚠️ Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end
end

local function loadPlayerData(player)
	local success, data
	for i = 1, 3 do
		success, data = pcall(function()
			return playerDataStore:GetAsync(player.UserId .. "_Data")
		end)
		if success then
			return data
		else
			warn("Attempt " .. i .. " failed to load data for " .. player.Name)
			task.wait(0.5)
		end
	end
	warn("Failed to load data for " .. player.Name .. ". Using defaults.")
	return nil
end

---------------------------------------------------------------------
-- CHARACTER SETUP
---------------------------------------------------------------------
local function setupCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Ensure character Powers folder
	local charPowers = character:FindFirstChild("Powers")
	if not charPowers then
		charPowers = Instance.new("Folder")
		charPowers.Name = "Powers"
		charPowers.Parent = character
	end

	-- Copy values from player.Powers
	local playerPowers = player:WaitForChild("Powers")
	for _, statName in ipairs({ "Hero", "Specialty", "Race" }) do
		local value = charPowers:FindFirstChild(statName)
		if not value then
			value = Instance.new("StringValue")
			value.Name = statName
			value.Value = playerPowers[statName] and playerPowers[statName].Value or ""
			value.Parent = charPowers
		end
		-- Keep in sync with player.Powers
		playerPowers[statName].Changed:Connect(function()
			value.Value = playerPowers[statName].Value
		end)
	end

	-- Restore tools on death
	humanoid.Died:Connect(function()
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") then
				tool.Parent = player.Backpack
			end
		end
		savePlayerData(player)
	end)
end

local function ensurePowersFolder(player)
	-- Try to find existing folder
	local powers = player:FindFirstChild("Powers")
	if not powers then
		powers = Instance.new("Folder")
		powers.Name = "Powers"
		powers.Parent = player
	end

	-- Ensure each StringValue exists
	for _, statName in ipairs({ "Hero", "Specialty", "Race" }) do
		local value = powers:FindFirstChild(statName)
		if not value then
			value = Instance.new("StringValue")
			value.Name = statName
			value.Value = "" -- default, will be overwritten if loading data
			value.Parent = powers
		end
	end

	return powers
end

---------------------------------------------------------------------
-- PLAYER CONNECTIONS
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	-- ✅ Immediately ensure Powers exists
	local powersFolder = player:FindFirstChild("Powers")
	if not powersFolder then
		powersFolder = Instance.new("Folder")
		powersFolder.Name = "Powers"
		powersFolder.Parent = player

		for _, statName in ipairs({ "Hero", "Specialty", "Race" }) do
			if not powersFolder:FindFirstChild(statName) then
				local val = Instance.new("StringValue")
				val.Name = statName
				val.Value = "" -- default
				val.Parent = powersFolder
			end
		end
	end

	-- ✅ Now spawn async code safely
	task.spawn(function()
		local success, err = pcall(function()
			-- Load saved data
			local savedData = loadPlayerData(player)
			if savedData then
				powersFolder.Hero.Value = savedData.Hero or ""
				powersFolder.Specialty.Value = savedData.Specialty or ""
				powersFolder.Race.Value = savedData.Race or "Human"
			end

			-- Restore completed quests
			if savedData and savedData.CompletedQuests then
				deserializeCompletedQuests(player, savedData.CompletedQuests)
			else
				QuestManager.SetCompletedQuests(player, {})
			end

			-- Restore active quests
			if savedData and savedData.Quests then
				deserializeQuests(player, savedData.Quests)
			end

			-- Add starting quest
			if
				not QuestManager.HasPlayerCompletedQuest(player, "TalkToGiorno1")
				and not QuestManager.GetQuests(player)["TalkToGiorno1"]
			then
				QuestManager.AddQuest(player, "TalkToGiorno1")
			end

			-- Restore stats
			local stats = player:FindFirstChild("Stats")
			if savedData and stats then
				stats.XP.Value = savedData.XP or stats.XP.Value
				stats.Level.Value = savedData.Level or stats.Level.Value
				stats.AbilityPoints.Value = savedData.AbilityPoints or stats.AbilityPoints.Value
				stats.MaxXP.Value = savedData.MaxXP or stats.MaxXP.Value
				stats.Cash.Value = savedData.Cash or stats.Cash.Value
			end

			-- Restore UpgradeData
			local upgradeFolder = player:FindFirstChild("UpgradeData")
			if upgradeFolder and savedData and savedData.UpgradeData then
				for upgradeName, value in pairs(savedData.UpgradeData) do
					local upgradeValue = upgradeFolder:FindFirstChild(upgradeName)
					if upgradeValue and upgradeValue:IsA("IntValue") then
						upgradeValue.Value = value
					else
						local newUpgrade = Instance.new("IntValue")
						newUpgrade.Name = upgradeName
						newUpgrade.Value = value
						newUpgrade.Parent = upgradeFolder
					end
				end
			end

			-- Connect character setup
			player.CharacterAdded:Connect(function(character)
				setupCharacter(player, character)
				-- Restore inventory
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
		end)
		if not success then
			warn("❌ PlayerAdded crashed for", player.Name, err)
		end
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
