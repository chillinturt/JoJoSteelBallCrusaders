-- ServerScriptService > OneVsOneManager.lua

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Require the module (adjust path if needed)
local OneVsOne = require(ServerScriptService.Objectives.OneVsOneModule)

-- **IMPORTANT**: Ensure your OneVsOneModule has these lines at the bottom (if not already added):
-- OneVsOne.Spawn1 = Spawn1
-- OneVsOne.Spawn2 = Spawn2

-- Create or get the RemoteEvent for queuing
local EventsFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Events")

local queueEvent = EventsFolder:FindFirstChild("QueueOneVsOne")
if not queueEvent then
	queueEvent = Instance.new("RemoteEvent")
	queueEvent.Name = "QueueOneVsOne"
	queueEvent.Parent = EventsFolder
end

-- Track lives and spawns for the current active game
local CurrentGameLives = {}
local PlayerSpawns = {} -- {player = spawnPart}

-- ========================================
-- Queue Handling
-- ========================================
queueEvent.OnServerEvent:Connect(function(player)
	OneVsOne:QueuePlayer(player)
end)

-- ========================================
-- Game Start Hook
-- ========================================
local function OnGameStarted(player1, player2)
	CurrentGameLives = {
		[player1] = 3,
		[player2] = 3,
	}
	PlayerSpawns = {
		[player1] = OneVsOne.Spawn1,
		[player2] = OneVsOne.Spawn2,
	}

	print("New 1v1 match started: " .. player1.Name .. " vs " .. player2.Name .. " (3 lives each)")
end

-- Override StartGame to hook into it
local originalStartGame = OneVsOne.StartGame
OneVsOne.StartGame = function(self)
	originalStartGame(self)

	if #self.ActivePlayers == 2 then
		OnGameStarted(self.ActivePlayers[1], self.ActivePlayers[2])
	end
end

-- ========================================
-- Game End Hook
-- ========================================
local function OnGameEnded(winner, loser)
	CurrentGameLives = {}
	PlayerSpawns = {}

	-- Respawn both players to kick them out of the arena (back to default lobby spawn)
	task.spawn(function()
		task.wait(1) -- Brief delay for cleanup
		if winner and winner.Parent then
			winner:LoadCharacter()
		end
		if loser and loser.Parent then
			loser:LoadCharacter()
		end
	end)

	print("1v1 post-game cleanup complete")
end

-- Override EndGame to hook into it
local originalEndGame = OneVsOne.EndGame
OneVsOne.EndGame = function(self, winner, loser)
	originalEndGame(self, winner, loser)
	OnGameEnded(winner, loser)
end

-- ========================================
-- Death Detection
-- ========================================
local function OnPlayerDied(player)
	-- Only care if this player is in an active 1v1 game
	if not CurrentGameLives[player] then
		return
	end

	-- Decrease lives
	CurrentGameLives[player] -= 1
	print(player.Name .. " died. Lives left: " .. CurrentGameLives[player])

	-- Respawn handled automatically by Roblox + CharacterAdded hook below

	-- Check if this player is out
	if CurrentGameLives[player] <= 0 then
		-- Find the winner (the other active player)
		local winner = OneVsOne.ActivePlayers[1] == player and OneVsOne.ActivePlayers[2] or OneVsOne.ActivePlayers[1]
		print("Match over! Winner: " .. winner.Name)

		-- Award win and end game
		OneVsOne:EndGame(winner, player)
	end
end

-- Listen for character death and handle arena respawns
local function SetupCharacterConnections(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			task.defer(OnPlayerDied, player)
		end)

		-- **Key: Respawn to arena spawn if in active game and has lives left**
		task.spawn(function()
			task.wait(0.5) -- Wait for character to fully load (joints, animations, etc.)
			if CurrentGameLives[player] and PlayerSpawns[player] and CurrentGameLives[player] > 0 then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.CFrame = PlayerSpawns[player].CFrame + Vector3.new(0, 3, 0) -- Offset to prevent spawnkill
					print(player.Name .. " respawned in arena (lives: " .. CurrentGameLives[player] .. ")")
				end
			end
		end)
	end)
end

-- Connect for new players
Players.PlayerAdded:Connect(SetupCharacterConnections)

-- Connect for existing players
for _, player in ipairs(Players:GetPlayers()) do
	SetupCharacterConnections(player)

	-- Also connect Died to current character if it exists
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				task.defer(OnPlayerDied, player)
			end)
		end
	end
end

-- ========================================
-- Cleanup on Player Leaving
-- ========================================
Players.PlayerRemoving:Connect(function(player)
	-- Remove from queue
	OneVsOne:DequeuePlayer(player)

	-- If they were in an active game, end it (forfeit)
	if CurrentGameLives[player] then
		local opponent = OneVsOne.ActivePlayers[1] == player and OneVsOne.ActivePlayers[2] or OneVsOne.ActivePlayers[1]
		if opponent and opponent.Parent then
			print(player.Name .. " left. " .. opponent.Name .. " wins by forfeit!")
			OneVsOne:EndGame(opponent, player)
		end
		-- Clear tracking (EndGame hook will also handle)
		CurrentGameLives = {}
		PlayerSpawns = {}
	end
end)

print("1v1 Manager loaded and ready!")
