-- SaveData.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreManager = require(script.Parent.DataStoreManager)
local PlayerProfile = require(script.Parent.PlayerProfile)
local InventoryManager = require(script.Parent.InventoryManager)
local QuestSerializer = require(script.Parent.QuestSerializer)
local QuestManager = require(script.Parent.QuestManager)

---------------------------------------------------------------------
-- ITEM FOLDERS (TOOLS THAT WILL BE CLONED WHEN BACKPACK IS REPLICATED)
---------------------------------------------------------------------
local StandItemsFolder = ReplicatedStorage.Items.StandItems.InventoryTools
local RaceItemsFolder = ReplicatedStorage.Items.RaceItems.InventoryTools

local itemFolders = {
	Stand = StandItemsFolder,
	Race = RaceItemsFolder,
}

---------------------------------------------------------------------
-- 🧠 MEMORY DATA (never store Instances)
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
	-- DEEP COPY (prevents accidental mutation)
	----------------------------------------------------
	local function deepCopy(tbl)
		local copy = {}
		for k, v in pairs(tbl) do
			if typeof(v) == "table" then
				copy[k] = deepCopy(v)
			else
				copy[k] = v
			end
		end
		return copy
	end

	----------------------------------------------------
	-- 🔥 POWERS
	----------------------------------------------------
	local powers = player:FindFirstChild("Powers")
	if powers then
		profile.Race = powers.Race.Value
		profile.Hero = powers.Hero.Value
		profile.Specialty = powers.Specialty.Value
	else
		warn("[SaveData] Powers folder missing for", player.Name)
	end

	----------------------------------------------------
	-- 🔥 STATS
	----------------------------------------------------
	local stats = player:FindFirstChild("Stats")
	if stats then
		profile.XP = stats.XP.Value
		profile.Level = stats.Level.Value
		profile.AbilityPoints = stats.AbilityPoints.Value
		profile.MaxXP = stats.MaxXP.Value
		profile.Cash = stats.Cash.Value
	else
		warn("[SaveData] Stats folder missing for", player.Name)
	end

	----------------------------------------------------
	-- 🔥 UPGRADES
	----------------------------------------------------
	local upgradeFolder = player:FindFirstChild("UpgradeData")
	if upgradeFolder then
		profile.UpgradeData = {}
		for _, obj in ipairs(upgradeFolder:GetChildren()) do
			if obj:IsA("IntValue") then
				profile.UpgradeData[obj.Name] = obj.Value
			end
		end
	end

	----------------------------------------------------
	-- 🔥 QUESTS
	----------------------------------------------------
	profile.Quests = QuestSerializer.SerializeActive(QuestManager, player)
	profile.CompletedQuests = QuestSerializer.SerializeCompleted(QuestManager, player)

	----------------------------------------------------
	-- 🔥 INVENTORY (FROM MEMORY ONLY!)
	----------------------------------------------------
	local invTable = InventoryManager.GetInventory(player)
	profile.Inventory = deepCopy(invTable)

	----------------------------------------------------
	-- FINAL PROFILE COPY SAFE FOR DATASTORE
	----------------------------------------------------
	local safeProfile = deepCopy(profile)

	----------------------------------------------------
	-- 💾 SAVE WITH RETRY
	----------------------------------------------------
	local key = tostring(player.UserId)
	local maxRetries = 3
	local success, err

	for attempt = 1, maxRetries do
		success, err = pcall(function()
			DataStoreManager:Set(key, safeProfile)
		end)

		if success then
			print("[SaveData] Saved profile for", player.Name, "(attempt", attempt, ")")
			break
		else
			warn("[SaveData] Save failed for", player.Name, "attempt", attempt, "/", maxRetries, ":", err)
			task.wait(0.5)
		end
	end

	if not success then
		warn("[SaveData] ⚠️ FAILED to save profile after retries for", player.Name)
	end
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

	----------------------------------------------------
	-- Initialize inventory memory
	----------------------------------------------------
	InventoryManager.InitPlayer(player)
	InventoryManager.SetInventory(player, profile.Inventory)

	----------------------------------------------------
	-- Stats / Powers / Upgrades
	----------------------------------------------------
	ApplyProfile(player, profile)

	----------------------------------------------------
	-- Quests
	----------------------------------------------------
	QuestSerializer.DeserializeCompleted(QuestManager, player, profile.CompletedQuests)
	QuestSerializer.DeserializeActive(QuestManager, player, profile.Quests)

	-- First quest
	local hasActive = next(QuestManager.GetQuests(player)) ~= nil
	local hasCompleted = next(QuestManager.GetCompletedQuests(player)) ~= nil

	if not hasActive and not hasCompleted then
		QuestManager.AddQuest(player, "TalkToGiorno1")
	end

	----------------------------------------------------
	-- Backpack replication
	----------------------------------------------------
	player.CharacterAdded:Connect(function()
		task.wait(0.25)
		--InventoryManager.ReplicateToBackpack(player, itemFolders)
	end)

	----------------------------------------------------
	-- AUTO SAVE
	----------------------------------------------------
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

	InventoryManager.RemovePlayer(player)
	MemoryData[player] = nil
end)
