local EncodingService = game:GetService("EncodingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataTemplate = require(ReplicatedStorage.Shared.Modules.PlayerData)
local InventoryManager = require(ServerScriptService.DataSaving.InventoryManager)
local HeroManager = require(ServerScriptService.DataSaving.HeroManager)
local QuestSerializer = require(ServerScriptService.DataSaving.QuestSerializer)
local QuestManager = require(ServerScriptService.DataSaving.QuestManager)
local XPSystem = require(ServerScriptService.DataSaving.XPSystem)
local CharacterUpgrades = require(ServerScriptService.DataSaving.Upgrades:WaitForChild("CharacterUpdgrades"))
local CashSystem = require(ServerScriptService.DataSaving:WaitForChild("CashSystem"))

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
	-- NOTHING IS APPLIED TO WORKSPACE
	-- WE KEEP ALL DATA IN MEMORY ONLY
	--------------------------------------------------------

	local data = profile.Data

	-- 🧰 Inventory
	InventoryManager.InitPlayer(player)
	InventoryManager.SetInventory(player, data.Inventory)

	HeroManager.InitPlayer(player)
	HeroManager.SetField(player, "Hero", data.Hero)
	HeroManager.SetField(player, "Specialty", data.Specialty)
	HeroManager.SetField(player, "Race", data.Race)

	-- 🧭 Quests
	QuestSerializer.DeserializeCompleted(QuestManager, player, data.CompletedQuests)
	QuestSerializer.DeserializeActive(QuestManager, player, data.Quests)

	-- 🧮 XP / Leveling
	XPSystem.SetField(player, "XP", data.XP)
	XPSystem.SetField(player, "Level", data.Level)
	XPSystem.SetField(player, "MaxXP", data.MaxXP)
	XPSystem.SetField(player, "AbilityPoints", data.AbilityPoints)

	CashSystem.SetCash(player, data.Cash)

	CharacterUpgrades.SetStats(player, data.CharacterUpgrades)

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

	local data = profile.Data

	--------------------------------------------------------
	-- COPY DATA IN MEMORY ONLY
	-- (Inventory and Quests still need serialization)
	--------------------------------------------------------

	data.Inventory = InventoryManager.GetInventory(player)

	data.Hero = HeroManager.GetField(player, "Hero")
	data.Specialty = HeroManager.GetField(player, "Specialty")
	data.Race = HeroManager.GetField(player, "Race")

	data.Quests = QuestSerializer.SerializeActive(QuestManager, player)
	data.CompletedQuests = QuestSerializer.SerializeCompleted(QuestManager, player)

	data.XP = XPSystem.GetField(player, "XP")
	data.Level = XPSystem.GetField(player, "Level")
	data.MaxXP = XPSystem.GetField(player, "MaxXP")
	data.AbilityPoints = XPSystem.GetField(player, "AbilityPoints")

	data.Cash = CashSystem.GetCash(player)

	data.CharacterUpgrades = CharacterUpgrades.GetStats(player)

	profile:EndSession()
	Profiles[player] = nil
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
