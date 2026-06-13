local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")

local TimePlayedModule = {}

local UPDATE_TOPIC = "TimePlayedLeaderboardUpdate"

-- Ordered datastore for leaderboard ranking
local playtimeStore = DataStoreService:GetOrderedDataStore("GlobalPlaytime")

-- Session tracking
local joinTimes = {}

-- Save playtime for a player
function TimePlayedModule:SavePlayer(player)
	local userId = player.UserId
	local joinTime = joinTimes[userId]

	if not joinTime then
		return
	end

	local sessionSeconds = math.floor(os.time() - joinTime)

	local success, err = pcall(function()
		local current = playtimeStore:GetAsync(tostring(userId)) or 0
		local newTime = current + sessionSeconds

		playtimeStore:SetAsync(tostring(userId), newTime)
	end)

	if not success then
		warn("Failed to save playtime for", player.Name, err)
	end

	joinTimes[userId] = nil

	-- Notify leaderboard servers to refresh
	pcall(function()
		MessagingService:PublishAsync(UPDATE_TOPIC, true)
	end)
end

-- Get top leaderboard entries
function TimePlayedModule:GetGlobalLeaderboard(limit)
	limit = limit or 25

	local success, pages = pcall(function()
		return playtimeStore:GetSortedAsync(false, limit)
	end)

	if not success then
		warn("Failed to fetch playtime leaderboard")
		return {}
	end

	return pages:GetCurrentPage()
end

-- Get a player's total playtime
function TimePlayedModule:GetPlayerTime(userId)
	local success, value = pcall(function()
		return playtimeStore:GetAsync(tostring(userId))
	end)

	if success then
		return value or 0
	end

	return 0
end

-- Track joins
Players.PlayerAdded:Connect(function(player)
	joinTimes[player.UserId] = os.time()
end)

-- Track leaves
Players.PlayerRemoving:Connect(function(player)
	TimePlayedModule:SavePlayer(player)
end)

-- Server shutdown save
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		TimePlayedModule:SavePlayer(player)
	end
end)

return TimePlayedModule
