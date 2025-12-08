-- CashSystem Module (Memory-based)
local CashSystem = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Max cash cap
local MAX_CASH = 1000000

-- RemoteEvent for cash gain
local MusicEvents = ReplicatedStorage:WaitForChild("MusicEvents")
local CashUpdateEvent = MusicEvents:FindFirstChild("CashGainedEvent")
if not CashUpdateEvent then
	CashUpdateEvent = Instance.new("RemoteEvent")
	CashUpdateEvent.Name = "CashGainedEvent"
	CashUpdateEvent.Parent = MusicEvents
end

-- Memory table to store cash for each player
local playerCash = {}

---------------------------------------------------------------------
-- Setup stats for a new player
---------------------------------------------------------------------
function CashSystem.SetupPlayer(player)
	playerCash[player] = 0
	CashUpdateEvent:FireClient(player, playerCash[player])
end

---------------------------------------------------------------------
-- Add cash (clamped to MAX_CASH)
---------------------------------------------------------------------
function CashSystem.AddCash(player, amount)
	if not playerCash[player] then
		return
	end
	if amount <= 0 then
		return
	end

	local newValue = playerCash[player] + amount
	if newValue > MAX_CASH then
		newValue = MAX_CASH
	end

	playerCash[player] = newValue

	-- Fire RemoteEvent for UI update
	CashUpdateEvent:FireClient(player, newValue)
end

---------------------------------------------------------------------
-- Spend cash safely
-- Returns true if success, false if player can't afford
---------------------------------------------------------------------
function CashSystem.SpendCash(player, amount)
	if not playerCash[player] then
		return false
	end
	if amount <= 0 then
		return false
	end

	if playerCash[player] < amount then
		return false
	end

	playerCash[player] -= amount

	CashUpdateEvent:FireClient(player, playerCash[player])
	return true
end

---------------------------------------------------------------------
-- Get current cash
---------------------------------------------------------------------
function CashSystem.GetCash(player)
	return playerCash[player] or 0
end

---------------------------------------------------------------------
-- Set current cash
---------------------------------------------------------------------

function CashSystem.SetCash(player, value)
	playerCash[player] = value or 0
	return playerCash[player] or 0
end

---------------------------------------------------------------------
-- Auto-setup on join and cleanup on leave
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	CashSystem.SetupPlayer(player)
	player.CharacterAdded:Connect(function()
		player:WaitForChild("PlayerGui")

		task.defer(function()
			wait(2)
			CashUpdateEvent:FireClient(player, playerCash[player])
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerCash[player] = nil
end)

return CashSystem
