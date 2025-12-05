local EncodingService = game:GetService("EncodingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataTemplate = require(ReplicatedStorage.Shared.Modules.PlayerData)
local InventoryManager = require(ServerScriptService.DataSaving.InventoryManager)
local QuestSerializer = require(ServerScriptService.DataSaving.QuestSerializer)
local QuestManager = require(ServerScriptService.DataSaving.QuestManager)

local ProfileStore = require(ServerScriptService.DataSaving.ProfileStore)

local DATA_STORE_KEY = "Production"
if RunService:IsStudio() then
	DATA_STORE_KEY = "Test"
end

local PlayerStore = ProfileStore.New(DATA_STORE_KEY, PlayerDataTemplate.DEFAULT_PLAYER_DATA)
local Profiles: { [Player]: any } = {}

local Local = {}
local Shared = {}

function Local.OnStart()
	for _, player in Players:GetPlayers() do
		task.spawn(Local.LoadProfile, player)
	end
	Players.PlayerAdded:Connect(Local.LoadProfile)
	Players.PlayerRemoving:Connect(Local.RemoveProfile)
end

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
	-- APPLY DATA TO GAME OBJECTS (Stats, Inventory, Quests)
	--------------------------------------------------------

	local data = profile.Data

	-- 💰 Stats / Powers
	local powers = player:WaitForChild("Powers")
	local stats = player:WaitForChild("Stats")
	local upgrades = player:WaitForChild("UpgradeData")

	powers.Hero.Value = data.Hero
	powers.Race.Value = data.Race
	powers.Specialty.Value = data.Specialty

	stats.Cash.Value = data.Cash
	stats.XP.Value = data.XP
	stats.Level.Value = data.Level
	stats.AbilityPoints.Value = data.AbilityPoints
	stats.MaxXP.Value = data.MaxXP

	-- 🔼 Upgrades
	for name, val in pairs(data.UpgradeData) do
		local obj = upgrades:FindFirstChild(name) or Instance.new("IntValue")
		obj.Name = name
		obj.Value = val
		obj.Parent = upgrades
	end

	-- 🧰 Inventory (uses memory manager)
	InventoryManager.InitPlayer(player)
	InventoryManager.SetInventory(player, data.Inventory)

	-- 🧭 Quests
	QuestSerializer.DeserializeCompleted(QuestManager, player, data.CompletedQuests)
	QuestSerializer.DeserializeActive(QuestManager, player, data.Quests)

	--[[
	player.CharacterAdded:Connect(function()
		task.wait(0.25)
		InventoryManager.ReplicateToBackpack(player)
	end)
	]]
end

function Local.RemoveProfile(player: Player)
	local profile = Profiles[player]
	if not profile then
		return
	end

	local data = profile.Data

	-------------------------------
	-- COPY LIVE GAME DATA INTO DATASTORE
	-------------------------------

	-- Stats
	local stats = player:FindFirstChild("Stats")
	if stats then
		data.Cash = stats.Cash.Value
		data.XP = stats.XP.Value
		data.Level = stats.Level.Value
		data.AbilityPoints = stats.AbilityPoints.Value
		data.MaxXP = stats.MaxXP.Value
	end

	-- Powers
	local powers = player:FindFirstChild("Powers")
	if powers then
		data.Hero = powers.Hero.Value
		data.Race = powers.Race.Value
		data.Specialty = powers.Specialty.Value
	end

	-- Upgrades
	local upgradeFolder = player:FindFirstChild("UpgradeData")
	data.UpgradeData = {}
	if upgradeFolder then
		for _, obj in ipairs(upgradeFolder:GetChildren()) do
			if obj:IsA("IntValue") then
				data.UpgradeData[obj.Name] = obj.Value
			end
		end
	end

	-- Inventory
	data.Inventory = InventoryManager.GetInventory(player)

	-- Quests
	data.Quests = QuestSerializer.SerializeActive(QuestManager, player)
	data.CompletedQuests = QuestSerializer.SerializeCompleted(QuestManager, player)

	----------------------------------
	-- END THE PROFILE SESSION
	----------------------------------
	profile:EndSession()

	Profiles[player] = nil
end

function Shared.GetData(player: Player)
	local profile = Profiles[player]
	return profile and profile.Data or nil
end

-- Example: upgrade one stat
function Shared.AddCash(player: Player, amount: number)
	local data = Shared.GetData(player)
	if not data then
		return
	end
	data.Cash += amount
end

Local.OnStart()

return Shared
