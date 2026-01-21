local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local HeroManager = require(ServerScriptService.DataSaving.HeroManager)

local AbilityTypesFunction = ReplicatedStorage.Shared.BasicCombat:WaitForChild("SpecialtyAbilityTypes")

local SpecialtyScriptsFolder = ServerScriptService.BasicCombat:WaitForChild("SpecailtyScripts")

local function getAbilityTypesForPlayer(player)
	local specValue = HeroManager.GetField(player, "Specialty")
	if not specValue or specValue == "None" then
		return {}
	end

	local specFolder = SpecialtyScriptsFolder:FindFirstChild(specValue)
	if not specFolder then
		return {}
	end

	local registryModule = specFolder:FindFirstChild("AbilityRegistry")
	if not registryModule then
		return {}
	end

	local registry = require(registryModule)
	return registry.AbilityTypes or {}
end

AbilityTypesFunction.OnServerInvoke = function(player)
	return getAbilityTypesForPlayer(player)
end

local function hookCharacter(character, player)
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.Died:Connect(function()
		task.defer(function()
			if player.Parent then
				print("[SpecialtyUtils] Resyncing ability types after death for", player.Name)
				AbilityTypesFunction:InvokeClient(player, getAbilityTypesForPlayer(player))
			end
		end)
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		hookCharacter(character, player)

		-- Optional initial push (not strictly required if client pulls)
		task.defer(function()
			AbilityTypesFunction:InvokeClient(player, getAbilityTypesForPlayer(player))
		end)
	end)
end)
