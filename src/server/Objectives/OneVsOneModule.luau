-- ModuleScript for 1v1 Gamemode Management

local OneVsOneModule = {}

local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")

local winsStore = DataStoreService:GetDataStore("OneVsOne_Wins_V1")
local orderedStore = DataStoreService:GetOrderedDataStore("OneVsOne_Wins_Ordered_V1")

local UPDATE_TOPIC = "OneVsOneLeaderboardUpdate"

local FootstepSystem = require(game.ServerScriptService.Utilities.FootstepSystem)

-- Internal state
OneVsOneModule.Queue = {} -- List of players in queue
OneVsOneModule.ActiveGame = false -- Boolean to track if a game is currently active
OneVsOneModule.ActivePlayers = {} -- Table to hold the two players in the current game
OneVsOneModule.Wins = {} -- Dictionary to track wins: {player = winCount}

-- Spawn locations (adjust paths if needed)
local Arena1 = workspace:WaitForChild("Arena1")
local Model = Arena1:WaitForChild("Model")
local Spawn1 = Model:WaitForChild("1v1Spawn1")
local Spawn2 = Model:WaitForChild("1v1Spawn2")

-- 🔔 Internal: handles persistence + global update
function OneVsOneModule:_OnWinsUpdated(player)
	local userId = player.UserId
	local wins = self.Wins[player] or 0

	-- Save to normal DataStore
	task.spawn(function()
		pcall(function()
			winsStore:SetAsync(userId, wins)
		end)
	end)

	-- Update OrderedDataStore (global leaderboard)
	task.spawn(function()
		pcall(function()
			orderedStore:SetAsync(userId, wins)
		end)
	end)

	-- Fire BindableEvent (local server UI refresh)
	local event = game.ReplicatedStorage.UIs.RemoteEvents:FindFirstChild("GetOneVsOneData")
	if event then
		event:Fire()
	end

	-- Publish cross-server update
	task.spawn(function()
		pcall(function()
			MessagingService:PublishAsync(UPDATE_TOPIC, "Update")
		end)
	end)
end

-- Function to queue a player
function OneVsOneModule:QueuePlayer(player)
	if not table.find(self.Queue, player) and not self:IsPlayerInGame(player) then
		table.insert(self.Queue, player)
		self:CheckForMatch()
	end
end

-- Function to check if player is already in an active game
function OneVsOneModule:IsPlayerInGame(player)
	return table.find(self.ActivePlayers, player) ~= nil
end

-- Function to check queue and start game if possible
function OneVsOneModule:CheckForMatch()
	if #self.Queue >= 2 and not self.ActiveGame then
		self:StartGame()
	end
end

-- Function to start a 1v1 game
function OneVsOneModule:StartGame()
	if #self.Queue < 2 or self.ActiveGame then
		return
	end

	self.ActiveGame = true
	local player1 = table.remove(self.Queue, 1)
	local player2 = table.remove(self.Queue, 1)

	table.insert(self.ActivePlayers, player1)
	table.insert(self.ActivePlayers, player2)

	-- Initialize wins if not present
	if not self.Wins[player1] then
		self.Wins[player1] = 0
	end
	if not self.Wins[player2] then
		self.Wins[player2] = 0
	end

	-- Teleport players to arena
	self:TeleportPlayer(player1, Spawn1)
	self:TeleportPlayer(player2, Spawn2)

	-- You can fire events or start game logic here (e.g., start countdown, enable PVP, etc.)
	print("1v1 game started between " .. player1.Name .. " and " .. player2.Name)
end

-- Function to teleport a player to a spawn
function OneVsOneModule:TeleportPlayer(player, spawnPart)
	if not player or not spawnPart then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	-- Simple, reliable teleport (mirror of working function)
	FootstepSystem.Disable(player, 0.5)

	hrp.CFrame = spawnPart.CFrame + Vector3.new(0, 8, 0)

	FootstepSystem.Reset(player, character)
end

-- Function to end the game and award win
function OneVsOneModule:EndGame(winner, loser)
	if not self.ActiveGame then
		return
	end

	-- Award win
	if self.Wins[winner] then
		self.Wins[winner] += 1
		self:_OnWinsUpdated(winner)
	end

	-- Reset state
	self.ActiveGame = false
	self.ActivePlayers = {}

	-- Teleport players back or handle post-game (optional)
	-- For example, teleport to lobby or respawn

	print("1v1 game ended. Winner: " .. winner.Name .. " with " .. self.Wins[winner] .. " wins")

	-- Check queue again for next match
	self:CheckForMatch()
end

-- Function to get a player's wins
function OneVsOneModule:GetWins(player)
	return self.Wins[player] or 0
end

-- Returns leaderboard sorted by wins (highest first)
function OneVsOneModule:GetGlobalLeaderboard(limit)
	limit = limit or 25

	local success, pages = pcall(function()
		return orderedStore:GetSortedAsync(false, limit)
	end)

	if not success then
		warn("Failed to retrieve global leaderboard")
		return {}
	end

	return pages:GetCurrentPage()
end

-- Function to remove a player from queue (e.g., if they leave)
function OneVsOneModule:DequeuePlayer(player)
	local index = table.find(self.Queue, player)
	if index then
		table.remove(self.Queue, index)
	end
end

OneVsOneModule.Spawn1 = Spawn1
OneVsOneModule.Spawn2 = Spawn2

-- 📥 Load wins when player joins
Players.PlayerAdded:Connect(function(player)
	local success, data = pcall(function()
		return winsStore:GetAsync(player.UserId)
	end)

	if success and data then
		OneVsOneModule.Wins[player] = data
	else
		OneVsOneModule.Wins[player] = 0
	end

	-- Ensure OrderedDataStore has correct value
	task.spawn(function()
		pcall(function()
			orderedStore:SetAsync(player.UserId, OneVsOneModule.Wins[player])
		end)
	end)
end)

-- 🧹 Cleanup when leaving
Players.PlayerRemoving:Connect(function(player)
	OneVsOneModule.Wins[player] = nil
end)

return OneVsOneModule
