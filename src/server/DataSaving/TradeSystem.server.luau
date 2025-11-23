-- ServerScriptService > TradeSystem
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- RemoteEvent for trade submissions
local tradeEvent = Instance.new("RemoteEvent")
tradeEvent.Name = "TradeSubmitted"
tradeEvent.Parent = ReplicatedStorage

-- Example: simple list of tradable items (can be expanded)
local TRADABLE_ITEMS = {
	["StandArrow"] = true,
	["CashBundle"] = true,
	["StoneMask"] = true,
	-- Add more items here
}

-- Utility: trim whitespace from string
local function trim(str)
	return str:match("^%s*(.-)%s*$")
end

-- Helper to get player's Powers folder
local function getPowersFolder(player)
	return player:FindFirstChild("Powers")
end

-- Helper to get player's inventory (Backpack)
local function getBackpackFolder(player)
	return player:FindFirstChild("Backpack")
end

-- Trade handler
tradeEvent.OnServerEvent:Connect(function(player, targetPlayerName)
	if typeof(targetPlayerName) ~= "string" then
		return
	end
	targetPlayerName = trim(targetPlayerName)

	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then
		-- Target player not found
		tradeEvent:FireClient(player, false, targetPlayerName)
		return
	end

	-- Example: trade can be customized; here we give the target player's Hero (Stand) to the trader if they have one
	local powers = getPowersFolder(player)
	local targetPowers = getPowersFolder(targetPlayer)
	if not powers or not targetPowers then
		tradeEvent:FireClient(player, false, targetPlayerName)
		return
	end

	local playerHero = powers:FindFirstChild("Hero")
	local targetHero = targetPowers:FindFirstChild("Hero")

	-- Example trade logic: swap Heroes if target has one
	if targetHero and targetHero.Value ~= "" then
		local oldHero = playerHero and playerHero.Value or ""
		if not playerHero then
			playerHero = Instance.new("StringValue")
			playerHero.Name = "Hero"
			playerHero.Value = ""
			playerHero.Parent = powers
		end

		playerHero.Value = targetHero.Value
		targetHero.Value = oldHero

		tradeEvent:FireClient(player, true, targetPlayerName)
		tradeEvent:FireClient(targetPlayer, true, player.Name)
	else
		-- Target has no stand to trade
		tradeEvent:FireClient(player, false, targetPlayerName)
	end

	-- Optional: Extend this logic for items in a Backpack
	local backpack = getBackpackFolder(player)
	local targetBackpack = getBackpackFolder(targetPlayer)
	if backpack and targetBackpack then
		-- Swap the first tradable item as a demo
		local playerItem, targetItem
		for _, v in ipairs(backpack:GetChildren()) do
			if TRADABLE_ITEMS[v.Name] then
				playerItem = v
				break
			end
		end
		for _, v in ipairs(targetBackpack:GetChildren()) do
			if TRADABLE_ITEMS[v.Name] then
				targetItem = v
				break
			end
		end

		if playerItem or targetItem then
			if playerItem then
				playerItem.Parent = targetBackpack
			end
			if targetItem then
				targetItem.Parent = backpack
			end
		end
	end
end)
