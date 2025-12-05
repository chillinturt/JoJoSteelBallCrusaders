---------------------------------------------------------------------
-- ItemUseManager.lua  (ModuleScript)
---------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ItemUseManager = {}

---------------------------------------------------------------------
-- Remote Event
---------------------------------------------------------------------
local remoteFolder = ReplicatedStorage:WaitForChild("UIs"):WaitForChild("RemoteEvents")
local UseItemEvent = remoteFolder:FindFirstChild("UseItem")

if not UseItemEvent then
	UseItemEvent = Instance.new("RemoteEvent")
	UseItemEvent.Name = "UseItem"
	UseItemEvent.Parent = remoteFolder
end

---------------------------------------------------------------------
-- Item modules loader
---------------------------------------------------------------------
local itemsFolder = script.Parent:WaitForChild("Items")
local itemModules = {}

for _, moduleScript in ipairs(itemsFolder:GetChildren()) do
	if moduleScript:IsA("ModuleScript") then
		local module = require(moduleScript)
		itemModules[moduleScript.Name] = module
	end
end

---------------------------------------------------------------------
-- Cooldown state
---------------------------------------------------------------------
-- Keeps track of last usage time per player per item
local cooldowns = {} -- [player.UserId] = { [itemName] = os.clock() }

---------------------------------------------------------------------
-- Item dispatcher function with cooldown check
---------------------------------------------------------------------
function ItemUseManager.Use(player, itemName)
	local handler = itemModules[itemName]
	if not handler then
		warn("⚠️ No item handler found for:", itemName)
		return false, "No handler"
	end

	-- Initialize player cooldown table
	local userId = player.UserId
	cooldowns[userId] = cooldowns[userId] or {}

	local lastUsed = cooldowns[userId][itemName] or 0
	local now = os.clock()
	local itemCooldown = handler.Cooldown or 0 -- seconds

	if now - lastUsed < itemCooldown then
		return false, "Item on cooldown"
	end

	-- Update cooldown timestamp
	cooldowns[userId][itemName] = now

	-- Call item module Use function
	local ok, result = handler.Use(player)
	if not ok then
		warn("⚠️ Item use failed:", result)
	end

	return ok, result
end

---------------------------------------------------------------------
-- RemoteEvent listener
---------------------------------------------------------------------
UseItemEvent.OnServerEvent:Connect(function(player, itemName)
	itemName = tostring(itemName or "")

	if itemName == "" then
		warn("⚠️ nil or empty item name from client, ignoring.")
		return
	end

	local ok, result = ItemUseManager.Use(player, itemName)

	if not ok then
		-- Optionally: notify client of failure
		print(player.Name, "failed to use item:", itemName, "-", result)
	end
end)

---------------------------------------------------------------------
return ItemUseManager
