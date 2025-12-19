-- ServerScriptService.DataSaving.ItemUse.StandArrow.lua
local InventoryManager = require(game.ServerScriptService.DataSaving.InventoryManager)
local HeroManager = require(game.ServerScriptService.DataSaving.HeroManager)
local StandUtils = require(game.ServerScriptService.BasicCombat.StandUtils)

local StandArrow = {}
StandArrow.Cooldown = 3

function StandArrow.Use(player)
	local inventory = InventoryManager.GetInventory(player)
	if not inventory then
		return false, "No profile data"
	end

	local char = player.Character
	if not char then
		return
	end

	local heroValue = HeroManager.GetField(player, "Hero")
	if heroValue ~= "None" and heroValue ~= "" then
		print("Player already has a stand!")
		return
	end

	-- find Stand Arrow
	local found = nil
	for _, entry in ipairs(inventory) do
		if entry.Name == "StandArrow" then
			found = entry
			break
		end
	end

	if not found or found.Amount <= 0 then
		return false, "No StandArrows!"
	end

	-- Remove ONE Stand Arrow
	InventoryManager.RemoveItem(player, "StandArrow", 1)

	local newHero = HeroManager.GetRandomStand()
	HeroManager.SetField(player, "Hero", newHero)

	wait(1)

	StandUtils.SummonStand(char, HeroManager.GetField(player, "Hero"))
	print("Arrow rolls new hero: " .. newHero)

	return true, newHero
end

return StandArrow
