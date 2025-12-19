-- ServerScriptService.DataSaving.ItemUse.PurpleRokakaka.lua
local InventoryManager = require(game.ServerScriptService.DataSaving.InventoryManager)
local HeroManager = require(game.ServerScriptService.DataSaving.HeroManager)
local StandUtils = require(game.ServerScriptService.BasicCombat.StandUtils)

local PurpleRokakaka = {}
PurpleRokakaka.Cooldown = 3

function PurpleRokakaka.Use(player)
	local inventory = InventoryManager.GetInventory(player)
	if not inventory then
		return false, "No profile data"
	end

	local char = player.Character
	if not char then
		return
	end

	local heroValue = HeroManager.GetField(player, "Hero")
	if heroValue == "None" then
		print("Player already has no stand! didn't use purpleroka")
		return
	end

	-- find Stand PurpleRokakaka
	local found = nil
	for _, entry in ipairs(inventory) do
		if entry.Name == "PurpleRokakaka" then
			found = entry
			break
		end
	end

	if not found or found.Amount <= 0 then
		return false, "No PurpleRokakakas!"
	end

	-- Remove ONE PurpleRokakaka
	InventoryManager.RemoveItem(player, "PurpleRokakaka", 1)

	HeroManager.SetField(player, "Hero", "None")

	StandUtils.RemoveStand(char, player)

	print("PurpleRokakaka used, reset stand")

	return true
end

return PurpleRokakaka
