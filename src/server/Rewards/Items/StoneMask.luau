-- ServerScriptService.DataSaving.ItemUse.StoneMask.lua
local InventoryManager = require(game.ServerScriptService.DataSaving.InventoryManager)
local HeroManager = require(game.ServerScriptService.DataSaving.HeroManager)
local StandUtils = require(game.ServerScriptService.BasicCombat.StandUtils)

local StoneMask = {}
StoneMask.Cooldown = 3

function StoneMask.Use(player)
	local inventory = InventoryManager.GetInventory(player)
	if not inventory then
		return false, "No profile data"
	end

	local char = player.Character
	if not char then
		return
	end

	local raceValue = HeroManager.GetField(player, "Race")
	if raceValue == "Vampire" then
		print("Player already a vampire!")
		return
	end

	local specValue = HeroManager.GetField(player, "Specialty")
	if specValue == "Hamon" then
		print("Player already has Hamon! Cannot become Vampire")
		return
	end

	-- find Stand StoneMask
	local found = nil
	for _, entry in ipairs(inventory) do
		if entry.Name == "StoneMask" then
			found = entry
			break
		end
	end

	if not found or found.Amount <= 0 then
		return false, "No StoneMasks!"
	end

	-- Remove ONE StoneMask
	InventoryManager.RemoveItem(player, "StoneMask", 1)

	HeroManager.SetField(player, "Race", "Vampire")

	print("StoneMask used, became a vampire")

	return true
end

return StoneMask
