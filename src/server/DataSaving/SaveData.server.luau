-- SaveData.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreManager = require(script.Parent.DataStoreManager)
local PlayerProfile = require(script.Parent.PlayerProfile)
local InventorySerializer = require(script.Parent.InventorySerializer)
local QuestSerializer = require(script.Parent.QuestSerializer)

local QuestManager = require(script.Parent.QuestManager)

---------------------------------------------------------------------
-- ITEM FOLDERS (TOOLS THAT WILL BE CLONED ON DESERIALIZE)
---------------------------------------------------------------------
local StandItemsFolder = ReplicatedStorage.Items.StandItems.InventoryTools
local RaceItemsFolder = ReplicatedStorage.Items.RaceItems.InventoryTools

local itemFolders = {
	Stand = StandItemsFolder,
	Race = RaceItemsFolder,
}

---------------------------------------------------------------------
-- 🧠 MEMORY DATA
-- Everything is stored here and saved from here (never Backpack)
---------------------------------------------------------------------
local MemoryData = {} -- [player] = profile table

---------------------------------------------------------------------
-- LOAD PROFILE FROM DATASTORE → INTO MEMORY
---------------------------------------------------------------------
local function LoadProfile(player)
	local key = tostring(player.UserId)
	local stored = DataStoreManager:Get(key)

	if stored then
		MemoryData[player] = stored
		return stored
	end

	local fresh = PlayerProfile.New()
	MemoryData[player] = fresh
	return fresh
end

---------------------------------------------------------------------
-- SAVE MEMORY PROFILE → INTO DATASTORE
---------------------------------------------------------------------
local function SaveProfile(player)
	local profile = MemoryData[player]
	if not profile then
		warn("[SaveData] No memory profile for", player.Name)
		return
	end

	----------------------------------------------------
	-- SERIALIZE STATS + QUESTS FROM CURRENT INSTANCES
	----------------------------------------------------
	profile.Quests = QuestSerializer.SerializeActive(QuestManager, player)
	profile.CompletedQuests = QuestSerializer.SerializeCompleted(QuestManager, player)

	----------------------------------------------------
	-- 🔥 INVENTORY SAVED FROM MEMORY ONLY
	-- NEVER read from Backpack here
	----------------------------------------------------
	-- (profile.Inventory is already stored IN MEMORY)
	-- Nothing with Backpack involved anymore

	DataStoreManager:Set(tostring(player.UserId), profile)
end

---------------------------------------------------------------------
-- APPLY PROFILE DATA → PLAYER INSTANCES
---------------------------------------------------------------------
local function ApplyProfile(player, profile)
	local powers = player:WaitForChild("Powers")
	local stats = player:WaitForChild("Stats")
	local upgrades = player:WaitForChild("UpgradeData")

	-- Powers
	powers.Hero.Value = profile.Hero
	powers.Specialty.Value = profile.Specialty
	powers.Race.Value = profile.Race

	-- Stats
	stats.XP.Value = profile.XP
	stats.Level.Value = profile.Level
	stats.AbilityPoints.Value = profile.AbilityPoints
	stats.MaxXP.Value = profile.MaxXP
	stats.Cash.Value = profile.Cash

	-- Upgrades
	for name, val in pairs(profile.UpgradeData) do
		local obj = upgrades:FindFirstChild(name)
		if not obj then
			obj = Instance.new("IntValue")
			obj.Name = name
			obj.Parent = upgrades
		end
		obj.Value = val
	end
end

---------------------------------------------------------------------
-- PLAYER JOIN
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	local profile = LoadProfile(player)

	-- Apply permanent data into stats
	ApplyProfile(player, profile)

	-- Load quest data
	QuestSerializer.DeserializeCompleted(QuestManager, player, profile.CompletedQuests)
	QuestSerializer.DeserializeActive(QuestManager, player, profile.Quests)

	---------------------------------------------------------
	-- Starting Quest Rule
	---------------------------------------------------------
	local hasActive = next(QuestManager.GetQuests(player)) ~= nil
	local hasCompleted = next(QuestManager.GetCompletedQuests(player)) ~= nil

	if not hasActive and not hasCompleted then
		QuestManager.AddQuest(player, "TalkToGiorno1")
	end

	---------------------------------------------------------
	-- CHARACTER SPAWN → DESERIALIZE INVENTORY
	---------------------------------------------------------
	player.CharacterAdded:Connect(function()
		local memoryProfile = MemoryData[player]
		task.wait(0.25)
		InventorySerializer.Deserialize(player, memoryProfile.Inventory, itemFolders)
	end)

	---------------------------------------------------------
	-- AUTO SAVE LOOP (EVERY 60 SECONDS)
	---------------------------------------------------------
	task.spawn(function()
		while player.Parent do
			task.wait(60)
			SaveProfile(player)
		end
	end)
end)

---------------------------------------------------------------------
-- PLAYER LEAVE
---------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	SaveProfile(player)
	QuestManager.Cleanup(player)
	MemoryData[player] = nil -- prevent memory leaks
end)
