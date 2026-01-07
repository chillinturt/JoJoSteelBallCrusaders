-- ModuleScript for 1v1 Gamemode Management

local OneVsOneModule = {}

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
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		player.Character.HumanoidRootPart.CFrame = spawnPart.CFrame
	else
		-- Handle if character not loaded (optional: wait or respawn)
		player:LoadCharacter()
		wait(1) -- Wait for character to load
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
		end
	end
end

-- Function to end the game and award win
function OneVsOneModule:EndGame(winner, loser)
	if not self.ActiveGame then
		return
	end

	-- Award win
	if self.Wins[winner] then
		self.Wins[winner] += 1
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

-- Function to remove a player from queue (e.g., if they leave)
function OneVsOneModule:DequeuePlayer(player)
	local index = table.find(self.Queue, player)
	if index then
		table.remove(self.Queue, index)
	end
end

OneVsOneModule.Spawn1 = Spawn1
OneVsOneModule.Spawn2 = Spawn2

return OneVsOneModule
