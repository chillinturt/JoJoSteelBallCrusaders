-- ServerScriptService.DataSaving.ItemUse.StandArrow.lua

local ProfileStore = require(game.ServerScriptService.DataSaving.ProfileStore)
local StandManager = require(game.ServerScriptService.DataSaving.StandManager)

local StandArrow = {}
StandArrow.Cooldown = 3 -- seconds

function StandArrow.Use(player)
	-- Get the player's profile
	local profile = ProfileStore.Get(player)
	if not profile then
		return false, "Profile not loaded!"
	end

	local data = profile.Data

	-- Check inventory
	if not data.Inventory["Stand Arrow"] or data.Inventory["Stand Arrow"] <= 0 then
		return false, "No Stand Arrows!"
	end

	-- Consume one arrow
	data.Inventory["Stand Arrow"] -= 1

	-- Assign a random Hero value
	data.Hero = StandManager.GetRandomStand()

	-- Optional: save immediately
	ProfileStore.Save(player)

	return true, data.Hero
end

return StandArrow
