local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")

local CREATOR_USER_ID = 9966064759 -- replace with your UserId
local BADGE_ID = 4237056252337282 -- replace with your badge ID

-- Track whether creator is in the server
local creatorInGame = false

-- Function to safely award badge
local function awardBadge(player)
	if not player or player.UserId == CREATOR_USER_ID then
		return
	end

	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, BADGE_ID)
	end)

	if success and not hasBadge then
		pcall(function()
			BadgeService:AwardBadge(player.UserId, BADGE_ID)
		end)
	end
end

-- When a player joins
Players.PlayerAdded:Connect(function(player)
	-- Check if this is the creator
	if player.UserId == CREATOR_USER_ID then
		creatorInGame = true

		-- Award badge to everyone already in game
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			awardBadge(otherPlayer)
		end
	else
		-- If creator is already in game, award immediately
		if creatorInGame then
			awardBadge(player)
		end
	end
end)

-- When a player leaves
Players.PlayerRemoving:Connect(function(player)
	if player.UserId == CREATOR_USER_ID then
		creatorInGame = false
	end
end)
