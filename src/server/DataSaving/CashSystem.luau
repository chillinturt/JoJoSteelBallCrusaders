-- CashSystem Module
local CashSystem = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Max cash cap
local MAX_CASH = 50000

-- RemoteEvent for cash gain
local MusicEvents = ReplicatedStorage:WaitForChild("MusicEvents")
local CashGainedEvent = MusicEvents:FindFirstChild("CashGainedEvent")
if not CashGainedEvent then
	CashGainedEvent = Instance.new("RemoteEvent")
	CashGainedEvent.Name = "CashGainedEvent"
	CashGainedEvent.Parent = MusicEvents
end

---------------------------------------------------------------------
-- Setup stats for a new player
---------------------------------------------------------------------
function CashSystem.SetupPlayer(player)
	local stats = player:FindFirstChild("Stats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "Stats"
		stats.Parent = player
	end

	local cash = stats:FindFirstChild("Cash")
	if not cash then
		cash = Instance.new("IntValue")
		cash.Name = "Cash"
		cash.Value = 0
		cash.Parent = stats
	end
end

---------------------------------------------------------------------
-- Add cash (clamped to MAX_CASH)
---------------------------------------------------------------------
function CashSystem.AddCash(player, amount)
	local stats = player:FindFirstChild("Stats")
	if not stats then
		return
	end

	local cash = stats:FindFirstChild("Cash")
	if not cash then
		return
	end

	if amount <= 0 then
		return
	end

	-- Clamp to max
	local newValue = cash.Value + amount
	if newValue > MAX_CASH then
		newValue = MAX_CASH
	end

	cash.Value = newValue

	CashGainedEvent:FireClient(player)
end

---------------------------------------------------------------------
-- Spend cash safely
-- Returns true if success, false if player can't afford
---------------------------------------------------------------------
function CashSystem.SpendCash(player, amount)
	local stats = player:FindFirstChild("Stats")
	if not stats then
		return false
	end

	local cash = stats:FindFirstChild("Cash")
	if not cash then
		return false
	end

	if amount <= 0 then
		return false
	end

	-- Not enough money?
	if cash.Value < amount then
		return false
	end

	-- Deduct the amount
	cash.Value -= amount
	return true
end

---------------------------------------------------------------------
-- Auto-setup on join
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	CashSystem.SetupPlayer(player)
end)

return CashSystem
