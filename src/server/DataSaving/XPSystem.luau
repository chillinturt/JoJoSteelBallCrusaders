-- XPSystem Module
local XPSystem = {}

local Players = game:GetService("Players")

-- Max level cap
local MAX_LEVEL = 50

-- Formula for XP required to level up
local function getXPRequirement(level)
	return 100 + 20 * ((level - 1) ^ 2)
end

-- Public function to set up stats on a new player
function XPSystem.SetupPlayer(player)
	local stats = player:FindFirstChild("Stats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "Stats"
		stats.Parent = player
	end

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = 1
	level.Parent = stats

	local xp = Instance.new("IntValue")
	xp.Name = "XP"
	xp.Value = 0
	xp.Parent = stats

	local maxXP = Instance.new("IntValue")
	maxXP.Name = "MaxXP"
	maxXP.Value = getXPRequirement(level.Value)
	maxXP.Parent = stats
end

-- Public function to add XP (with rollover + level cap)
function XPSystem.AddXP(player, amount)
	local stats = player:FindFirstChild("Stats")
	if not stats then
		return
	end

	local xp = stats:FindFirstChild("XP")
	local level = stats:FindFirstChild("Level")
	local maxXP = stats:FindFirstChild("MaxXP")

	if not (xp and level and maxXP) then
		return
	end

	if level.Value >= MAX_LEVEL then
		-- Max level reached, cap XP at requirement
		xp.Value = maxXP.Value
		return
	end

	xp.Value += amount

	-- Handle rollover leveling
	while xp.Value >= maxXP.Value and level.Value < MAX_LEVEL do
		xp.Value -= maxXP.Value
		level.Value += 1
		maxXP.Value = getXPRequirement(level.Value)
	end

	-- Cap XP if player just reached max level
	if level.Value >= MAX_LEVEL then
		xp.Value = maxXP.Value
	end
end

Players.PlayerAdded:Connect(function(player)
	XPSystem.SetupPlayer(player)
end)

return XPSystem
