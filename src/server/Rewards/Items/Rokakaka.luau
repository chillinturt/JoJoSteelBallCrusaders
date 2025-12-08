-- ServerScriptService.DataSaving.ItemUse.Rokakaka.lua
local InventoryManager = require(game.ServerScriptService.DataSaving.InventoryManager)
local HeroManager = require(game.ServerScriptService.DataSaving.HeroManager)
local StandUtils = require(game.ServerScriptService.BasicCombat.StandUtils)

local Rokakaka = {}
Rokakaka.Cooldown = 3

function Rokakaka.Use(player)
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
		print("Player already has no stand!")
		return
	end

	-- find Stand Rokakaka
	local found = nil
	for _, entry in ipairs(inventory) do
		if entry.Name == "Rokakaka" then
			found = entry
			break
		end
	end

	if not found or found.Amount <= 0 then
		return false, "No Rokakakas!"
	end

	-- Remove ONE Rokakaka
	InventoryManager.RemoveItem(player, "Rokakaka", 1)

	HeroManager.SetField(player, "Hero", "None")
	HeroManager.SetField(player, "Specialty", "None")
	HeroManager.SetField(player, "Race", "None")

	StandUtils.RemoveStand(char, player)
	print("Rokakaka used, hero values reset")

	return true
end

return Rokakaka
