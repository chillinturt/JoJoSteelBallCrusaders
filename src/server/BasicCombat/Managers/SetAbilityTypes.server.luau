local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HeroManager = require(game.ServerScriptService.DataSaving.HeroManager)

local SpecialtyAbilityTypesRemote = ReplicatedStorage.Shared.BasicCombat:WaitForChild("SpecialtyAbilityTypes")
local SpecialtyScriptsFolder = ServerScriptService.BasicCombat:WaitForChild("SpecailtyScripts")

-- Sends the player's ability types to their client based on their specialty
local function SendSpecialtyAbilityTypes(player)
	local specValue = HeroManager.GetField(player, "Specialty")
	if specValue == nil or specValue == "None" then
		warn("Specialty value missing for", player.Name)
		return
	end

	-- Check if specialty folder exists
	local specFolder = SpecialtyScriptsFolder:FindFirstChild(specValue)
	if not specFolder then
		warn("No specialty folder for", specValue, "→ Player:", player.Name)
		return
	end

	print("[SpecialtyUtils] Specialty folder found:", specValue)

	local registryModule = specFolder:FindFirstChild("AbilityRegistry")
	if not registryModule then
		warn("No AbilityRegistry found for specialty:", specValue)
		return
	end

	print("[SpecialtyUtils] Found AbilityRegistry for:", specValue)

	local registry = require(registryModule)
	if registry.AbilityTypes then
		print("[SpecialtyUtils] AbilityTypes found! Sending to client...")
		SpecialtyAbilityTypesRemote:FireClient(player, registry.AbilityTypes)
		print("[SpecialtyUtils] Sent ability types to", player.Name, "for specialty", specValue)
	else
		warn("AbilityRegistry has no AbilityTypes for", specValue)
	end
end

-------------------------------------------------------------------
-- PLAYER ADDED
-------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	print("[SpecialtyUtils] Player added:", player.Name)

	-- CharacterAdded fires immediately if character already exists
	player.CharacterAdded:Connect(function(character)
		print("[SpecialtyUtils] Character added for:", player.Name)

		-- Delay 1 frame to ensure StarterCharacter data (e.g., Powers folder cloning) is loaded
		task.wait(3)

		SendSpecialtyAbilityTypes(player)
	end)
end)
