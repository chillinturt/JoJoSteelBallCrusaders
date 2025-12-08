-- ServerScriptService.DataSaving.ItemUse.BlueRokakaka.lua
local InventoryManager = require(game.ServerScriptService.DataSaving.InventoryManager)
local HeroManager = require(game.ServerScriptService.DataSaving.HeroManager)

local BlueRokakaka = {}
BlueRokakaka.Cooldown = 3

function BlueRokakaka.Use(player)
	local inventory = InventoryManager.GetInventory(player)
	if not inventory then
		return false, "No profile data"
	end

	local char = player.Character
	if not char then
		return
	end

	local raceValue = HeroManager.GetField(player, "Race")
	local specValue = HeroManager.GetField(player, "Specialty")
	if raceValue == "Human" and specValue == "None" then
		print("Player already a human with no spec!")
		return
	end

	-- find Stand BlueRokakaka
	local found = nil
	for _, entry in ipairs(inventory) do
		if entry.Name == "BlueRokakaka" then
			found = entry
			break
		end
	end

	if not found or found.Amount <= 0 then
		return false, "No BlueRokakakas!"
	end

	-- Remove ONE BlueRokakaka
	InventoryManager.RemoveItem(player, "BlueRokakaka", 1)

	HeroManager.SetField(player, "Race", "Human")
	HeroManager.SetField(player, "Specialty", "None")

	print("BlueRokakaka used, became a human with no spec")

	return true
end

return BlueRokakaka
