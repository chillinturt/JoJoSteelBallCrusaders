local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BadgeHandler = {}

local BADGES = {
	[10] = 42293895701872,
	[20] = 882214333296858,
	[30] = 3553840121209906,
	[40] = 2851466358360664,
	[50] = 2398786127998893,
}

-- 🧠 Cache: [userId] = { [badgeId] = true }
local awardedCache = {}

local MusicEvents = ReplicatedStorage:WaitForChild("MusicEvents")
local PlaySoundEvent = MusicEvents:FindFirstChild("PlaySoundEvent")
if not PlaySoundEvent then
	PlaySoundEvent = Instance.new("RemoteEvent")
	PlaySoundEvent.Name = "PlaySoundEvent"
	PlaySoundEvent.Parent = MusicEvents
end

function BadgeHandler:AwardLevelBadge(player, level)
	local badgeId = BADGES[level]
	if not badgeId then
		return
	end

	-- Init cache for player
	awardedCache[player.UserId] = awardedCache[player.UserId] or {}

	-- 🚫 Skip if already processed this badge
	if awardedCache[player.UserId][badgeId] then
		return
	end

	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
	end)

	if success and not hasBadge then
		pcall(function()
			BadgeService:AwardBadge(player.UserId, badgeId)

			-- Optional: feedback
			PlaySoundEvent:FireClient(player, {
				id = "rbxassetid://17511192247",
				volume = 1.2,
				pitch = 1,
			})

			print("Awarded badge for level", level, "to", player.Name)
		end)
	end

	-- ✅ Mark as processed regardless (prevents repeat calls)
	awardedCache[player.UserId][badgeId] = true
end

function BadgeHandler:CheckAllBadges(player, level)
	-- Loop through all milestone badges
	for requiredLevel, badgeId in pairs(BADGES) do
		if level >= requiredLevel then
			self:AwardLevelBadge(player, requiredLevel)
		end
	end
end

game.Players.PlayerRemoving:Connect(function(player)
	awardedCache[player.UserId] = nil
end)

return BadgeHandler
