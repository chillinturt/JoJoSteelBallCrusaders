local EncodingService = game:GetService("EncodingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SerializationService = game:GetService("SerializationService")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataTemplate = require(ReplicatedStorage.Shared.Modules.PlayerData)
local InventoryManager = require(ServerScriptService.DataSaving.InventoryManager)
local HeroManager = require(ServerScriptService.DataSaving.HeroManager)
local QuestSerializer = require(ServerScriptService.DataSaving.QuestSerializer)
local QuestManager = require(ServerScriptService.DataSaving.QuestManager)
local XPSystem = require(ServerScriptService.DataSaving.XPSystem)
local CharacterUpgrades = require(ServerScriptService.DataSaving.Upgrades:WaitForChild("CharacterUpdgrades"))
local CashSystem = require(ServerScriptService.DataSaving:WaitForChild("CashSystem"))
local SlotManager = require(ServerScriptService.DataSaving:WaitForChild("SlotManager"))

local ProfileStore = require(ServerScriptService.DataSaving.ProfileStore)

local DATA_STORE_KEY = "Production"
if RunService:IsStudio() then
	DATA_STORE_KEY = "Test"
end

local PlayerStore = ProfileStore.New(DATA_STORE_KEY, PlayerDataTemplate.DEFAULT_PLAYER_DATA)
local Profiles: { [Player]: any } = {}

local Local = {}
local PlayerData = {}

---------------------------------------------------------------------
-- STARTUP
---------------------------------------------------------------------

function Local.OnStart()
	for _, player in Players:GetPlayers() do
		task.spawn(Local.LoadProfile, player)
	end
	Players.PlayerAdded:Connect(Local.LoadProfile)
	Players.PlayerRemoving:Connect(Local.RemoveProfile)
end

---------------------------------------------------------------------
-- LOAD PROFILE (NO workspace values)
---------------------------------------------------------------------

function Local.LoadProfile(player: Player)
	local profile = PlayerStore:StartSessionAsync(tostring(player.UserId), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if not profile then
		return player:Kick("Profile load fail. Please rejoin.")
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		player:Kick("Profile session ended. Please rejoin.")
	end)

	Profiles[player] = profile

	--------------------------------------------------------
	-- NOW WE HANDLE SLOT MIGRATION
	--------------------------------------------------------
	local data = profile.Data

	-- Initialize slot system, migrate old data if needed
	SlotManager.InitPlayer(player, data)

	-- Get active slot data
	local activeData = SlotManager.GetActiveSlotData(player)
	assert(activeData, "Active slot data missing after InitPlayer")

	--------------------------------------------------------
	-- INITIALIZE MANAGERS WITH ACTIVE SLOT DATA
	--------------------------------------------------------
	InventoryManager.InitPlayer(player)
	InventoryManager.SetInventory(player, activeData.Inventory)

	HeroManager.InitPlayer(player)
	HeroManager.SetField(player, "Hero", activeData.Hero)
	HeroManager.SetField(player, "Specialty", activeData.Specialty)
	HeroManager.SetField(player, "Race", activeData.Race)

	QuestSerializer.DeserializeCompleted(QuestManager, player, activeData.CompletedQuests)
	QuestSerializer.DeserializeActive(QuestManager, player, activeData.Quests)

	local quests = QuestManager.GetQuests(player)
	if next(quests) == nil then
		QuestManager.ResetQuestline(player)
	end

	XPSystem.SetField(player, "XP", activeData.XP)
	XPSystem.SetField(player, "Level", activeData.Level)
	XPSystem.SetField(player, "MaxXP", activeData.MaxXP)
	XPSystem.SetField(player, "AbilityPoints", activeData.AbilityPoints)

	CashSystem.SetCash(player, activeData.Cash)

	CharacterUpgrades.SetStats(player, activeData.CharacterUpgrades)

	return true
end

---------------------------------------------------------------------
-- REMOVE PROFILE (NO workspace reads)
---------------------------------------------------------------------

function Local.RemoveProfile(player: Player)
	local profile = Profiles[player]
	if not profile then
		return
	end

	local profileData = profile.Data
	local activeSlot = SlotManager.GetActiveSlotName(player)
	local slots = SlotManager.GetAllSlots(player)

	------------------------------------------------------------------
	-- SAVE CURRENT SLOT INTO SLOTS TABLE
	------------------------------------------------------------------
	local slotData = slots[activeSlot]

	slotData.Inventory = InventoryManager.GetInventory(player)
	slotData.Hero = HeroManager.GetField(player, "Hero")
	slotData.Specialty = HeroManager.GetField(player, "Specialty")
	slotData.Race = HeroManager.GetField(player, "Race")
	slotData.Quests = QuestSerializer.SerializeActive(QuestManager, player)
	slotData.CompletedQuests = QuestSerializer.SerializeCompleted(QuestManager, player)
	slotData.XP = XPSystem.GetField(player, "XP")
	slotData.Level = XPSystem.GetField(player, "Level")
	slotData.MaxXP = XPSystem.GetField(player, "MaxXP")
	slotData.AbilityPoints = XPSystem.GetField(player, "AbilityPoints")
	slotData.Cash = CashSystem.GetCash(player)
	slotData.CharacterUpgrades = CharacterUpgrades.GetStats(player)

	------------------------------------------------------------------
	-- WRITE SLOT STATE BACK TO PROFILESTORE
	------------------------------------------------------------------
	profileData.Slots = slots
	profileData.CurrentSlot = activeSlot

	profile:EndSession()
	Profiles[player] = nil
	SlotManager.RemovePlayer(player)
end

function PlayerData.SafeSwitchSlot(player: Player, slotName: string)
	-- Step 0: validation
	if type(slotName) ~= "string" or slotName == "" then
		return false, "Invalid slot name"
	end

	local currentData = SlotManager.GetActiveSlotData(player)
	if not currentData then
		return false, "No active slot data"
	end

	-- STEP 0.5: ACCESS CHECK
	if not SlotManager.PlayerHasAccess(player, slotName) then
		return false, "Slot locked"
	end

	------------------------------------------------------------------
	-- STEP 1: SAVE CURRENT SLOT FROM MANAGERS
	------------------------------------------------------------------
	currentData.Inventory = InventoryManager.GetInventory(player)
	currentData.Hero = HeroManager.GetField(player, "Hero")
	currentData.Specialty = HeroManager.GetField(player, "Specialty")
	currentData.Race = HeroManager.GetField(player, "Race")
	currentData.Quests = QuestSerializer.SerializeActive(QuestManager, player)
	currentData.CompletedQuests = QuestSerializer.SerializeCompleted(QuestManager, player)
	currentData.XP = XPSystem.GetField(player, "XP")
	currentData.Level = XPSystem.GetField(player, "Level")
	currentData.MaxXP = XPSystem.GetField(player, "MaxXP")
	currentData.AbilityPoints = XPSystem.GetField(player, "AbilityPoints")
	currentData.Cash = CashSystem.GetCash(player)
	currentData.CharacterUpgrades = CharacterUpgrades.GetStats(player)

	------------------------------------------------------------------
	-- STEP 2: SWITCH SLOT (creates if missing)
	------------------------------------------------------------------
	local success, newSlotData = SlotManager.SwitchSlot(player, slotName)
	if not success then
		return false, newSlotData
	end

	------------------------------------------------------------------
	-- STEP 3: LOAD NEW SLOT INTO MANAGERS
	------------------------------------------------------------------
	InventoryManager.SetInventory(player, newSlotData.Inventory)

	HeroManager.SetField(player, "Hero", newSlotData.Hero)
	HeroManager.SetField(player, "Specialty", newSlotData.Specialty)
	HeroManager.SetField(player, "Race", newSlotData.Race)

	QuestManager.Clear(player)
	QuestSerializer.DeserializeCompleted(QuestManager, player, newSlotData.CompletedQuests)
	QuestSerializer.DeserializeActive(QuestManager, player, newSlotData.Quests)

	if next(QuestManager.GetQuests(player)) == nil then
		QuestManager.AddQuest(player, "TalkToGiorno1")
	end

	XPSystem.SetField(player, "XP", newSlotData.XP)
	XPSystem.SetField(player, "Level", newSlotData.Level)
	XPSystem.SetField(player, "MaxXP", newSlotData.MaxXP)
	XPSystem.SetField(player, "AbilityPoints", newSlotData.AbilityPoints)

	CashSystem.SetCash(player, newSlotData.Cash)
	CharacterUpgrades.SetStats(player, newSlotData.CharacterUpgrades)

	local char = player.Character
	local hum = char:FindFirstChild("Humanoid")

	if hum then
		hum.Health = 0
	end

	return true
end

---------------------------------------------------------------------
-- API FUNCTIONS
---------------------------------------------------------------------

function PlayerData.GetData(player: Player)
	local profile = Profiles[player]
	return profile and profile.Data or nil
end

-- 💰 Example: upgrade one stat
function PlayerData.AddCash(player: Player, amount: number)
	local data = PlayerData.GetData(player)
	if not data then
		return
	end
	data.Cash += amount
end

---------------------------------------------------------------------
-- 🦸‍♂️ NEW: Set hero power (NO workspace references)
---------------------------------------------------------------------

function PlayerData.SetHero(player: Player, newHero: string)
	local data = PlayerData.GetData(player)
	if not data then
		return false, "No player data found"
	end

	data.Hero = newHero
	return true
end

---------------------------------------------------------------------

Local.OnStart()
return PlayerData
