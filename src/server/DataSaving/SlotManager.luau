-- SlotManager.lua
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local PlayerDataTemplate = require(game.ReplicatedStorage.Shared.Modules.PlayerData)

local SLOT_ACCESS = {
	Slot1 = "Free",
	Slot2 = "GamePass",
	Slot3 = "GamePass",
}

local SLOT_PASSES = {
	Slot2 = 1638250721, -- replace with your GamePass ID
	Slot3 = 1637797031,
}

local DEFAULT_SLOT_DATA = {
	Hero = "None",
	Specialty = "None",
	Race = "Human",

	XP = 0,
	Level = 1,
	MaxXP = 100,
	AbilityPoints = 0,

	Cash = 0,

	Inventory = {},
	Quests = {},
	CompletedQuests = {},
	CharacterUpgrades = {},

	HasStarted = false,
}

local SlotManager = {}

-- Table to track active slots and all slots per player
local ActiveSlots = {} -- [Player] = "Slot1"
local PlayerSlots = {} -- [Player] = { Slot1 = {...}, Slot2 = {...} }

-- Default slot name
local DEFAULT_SLOT = "Slot1"

---------------------------------------------------------------------
-- Initialize a player with default slot if none exist
---------------------------------------------------------------------
function SlotManager.InitPlayer(player: Player, profileData)
	-- Ensure tables exist
	profileData.Slots = profileData.Slots or {}

	-- Migration: old data → Slot1
	if not next(profileData.Slots) then
		profileData.Slots["Slot1"] = {
			Hero = profileData.Hero,
			Specialty = profileData.Specialty,
			Race = profileData.Race,
			XP = profileData.XP,
			Level = profileData.Level,
			MaxXP = profileData.MaxXP,
			AbilityPoints = profileData.AbilityPoints,
			Cash = profileData.Cash,
			Inventory = profileData.Inventory or {},
			Quests = profileData.Quests or {},
			CompletedQuests = profileData.CompletedQuests or {},
			CharacterUpgrades = profileData.CharacterUpgrades or {},
		}
	end

	-- Ensure CurrentSlot exists
	profileData.CurrentSlot = profileData.CurrentSlot or "Slot1"

	-- GUARANTEE active slot exists
	if not profileData.Slots[profileData.CurrentSlot] then
		profileData.Slots[profileData.CurrentSlot] = table.clone(profileData.Slots["Slot1"])
	end

	PlayerSlots[player] = profileData.Slots
	ActiveSlots[player] = profileData.CurrentSlot
end

local function DeepCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = typeof(v) == "table" and DeepCopy(v) or v
	end
	return copy
end

function SlotManager.GetAllSlots(player)
	return PlayerSlots[player]
end

function SlotManager.GetActiveSlotName(player)
	return ActiveSlots[player]
end

---------------------------------------------------------------------
-- Get active slot data for a player
---------------------------------------------------------------------
function SlotManager.GetActiveSlotData(player)
	local slots = PlayerSlots[player]
	if not slots then
		return nil
	end

	local slotName = ActiveSlots[player]
	return slots[slotName] or slots["Slot1"]
end

---------------------------------------------------------------------
-- Switch the active slot
---------------------------------------------------------------------
function SlotManager.SwitchSlot(player, slotName)
	if not SlotManager.PlayerHasAccess(player, slotName) then
		return false, "Slot locked"
	end

	local slots = PlayerSlots[player]
	if not slots then
		return false, "No slots table"
	end

	-- ✅ Create fresh slot if missing
	if not slots[slotName] then
		slots[slotName] = DeepCopy(DEFAULT_SLOT_DATA)
	end

	ActiveSlots[player] = slotName
	return true, slots[slotName]
end

---------------------------------------------------------------------
-- Get list of all slots for a player
---------------------------------------------------------------------
function SlotManager.GetSlots(player)
	local slots = PlayerSlots[player] or {}
	local names = {}
	for name, _ in pairs(slots) do
		table.insert(names, name)
	end
	return names
end

---------------------------------------------------------------------
-- Remove a player (cleanup on leave)
---------------------------------------------------------------------
function SlotManager.RemovePlayer(player)
	ActiveSlots[player] = nil
	PlayerSlots[player] = nil
end

---------------------------------------------------------------------
-- Utility: Get the active slot name
---------------------------------------------------------------------
function SlotManager.GetActiveSlotName(player)
	return ActiveSlots[player] or DEFAULT_SLOT
end

function SlotManager.PlayerHasAccess(player: Player, slotName: string)
	local rule = SLOT_ACCESS[slotName]

	if rule == "Free" then
		return true
	end

	if rule == "GamePass" then
		local passId = SLOT_PASSES[slotName]
		if not passId then
			return false
		end

		local success, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)

		return success and owns
	end

	return false
end

return SlotManager
