-- InventoryManager.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local InventoryUpdatedEvent = Instance.new("RemoteEvent")
InventoryUpdatedEvent.Name = "InventoryUpdated"
InventoryUpdatedEvent.Parent = ReplicatedStorage:WaitForChild("UIs"):WaitForChild("RemoteEvents")

local InventoryManager = {}

---------------------------------------------------------------------
-- CONFIGURATION
---------------------------------------------------------------------

local DEFAULT_MAX_STACK = 20 -- global configurable flat stack
local STACK_MULTIPLIER = 1 -- later, if player owns gamepass: = 2 (or more)

-- If later you store multipliers per player, move this into a lookup

---------------------------------------------------------------------
-- IN-MEMORY STORAGE
-- Key: player.UserId
-- Value: array of { Name = string, Amount = number }
---------------------------------------------------------------------

local playerInventories = {}

---------------------------------------------------------------------
-- PRIVATE HELPERS
---------------------------------------------------------------------

local function getMaxStack()
	return DEFAULT_MAX_STACK * STACK_MULTIPLIER
end

local function findItemIndex(inventory, itemName)
	for i, entry in ipairs(inventory) do
		if entry.Name == itemName then
			return i
		end
	end
	return nil
end

---------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------

-- Initialize an empty inventory for a player
function InventoryManager.InitPlayer(player)
	playerInventories[player.UserId] = {}
end

-- Remove a player's inventory from memory
function InventoryManager.RemovePlayer(player)
	playerInventories[player.UserId] = nil
end

-- Get a deep copy suitable for saving
function InventoryManager.GetInventory(player)
	local inv = playerInventories[player.UserId]
	if not inv then
		return {}
	end

	-- Deep copy (important!)
	local result = {}
	for _, entry in ipairs(inv) do
		table.insert(result, { Name = entry.Name, Amount = entry.Amount })
	end
	return result
end

-- Load inventory from saved data
function InventoryManager.SetInventory(player, savedData)
	local inv = {}
	for _, entry in ipairs(savedData or {}) do
		table.insert(inv, {
			Name = entry.Name,
			Amount = entry.Amount or 1,
		})
	end
	playerInventories[player.UserId] = inv

	InventoryUpdatedEvent:FireClient(player, InventoryManager.GetInventory(player))
end

---------------------------------------------------------------------
-- STACKING
---------------------------------------------------------------------

function InventoryManager.AddItem(player, itemName, amount)
	if amount <= 0 then
		return
	end

	local inv = playerInventories[player.UserId]
	if not inv then
		return
	end

	local maxStack = getMaxStack()
	local index = findItemIndex(inv, itemName)

	if index then
		-- Stack into existing entry
		local entry = inv[index]
		entry.Amount += amount

		-- Enforce max stack
		if entry.Amount > maxStack then
			entry.Amount = maxStack
		end
	else
		-- Insert new item
		table.insert(inv, {
			Name = itemName,
			Amount = math.min(amount, maxStack),
		})
	end

	InventoryUpdatedEvent:FireClient(player, InventoryManager.GetInventory(player))
end

function InventoryManager.RemoveItem(player, itemName, amount)
	if amount <= 0 then
		return
	end

	local inv = playerInventories[player.UserId]
	if not inv then
		return
	end

	local index = findItemIndex(inv, itemName)
	if not index then
		return
	end

	local entry = inv[index]
	entry.Amount -= amount

	-- Remove if zero or below
	if entry.Amount <= 0 then
		table.remove(inv, index)
	end

	InventoryUpdatedEvent:FireClient(player, InventoryManager.GetInventory(player))
end

---------------------------------------------------------------------
-- DEBUG PRINT
---------------------------------------------------------------------

function InventoryManager.DebugPrint(player)
	local inv = playerInventories[player.UserId]
	if not inv then
		print("No inventory")
		return
	end

	print("Inventory for", player.Name)
	for _, entry in ipairs(inv) do
		print("  > ", entry.Name, "x", entry.Amount)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		-- wait for PlayerGui to exist on respawn
		local playerGui = player:WaitForChild("PlayerGui")

		-- now UI exists, safe to fire
		task.defer(function()
			local inventory = InventoryManager.GetInventory(player)
			InventoryUpdatedEvent:FireClient(player, inventory)
			--print("🔄 Sent inventory after respawn")
		end)
	end)
end)

return InventoryManager
