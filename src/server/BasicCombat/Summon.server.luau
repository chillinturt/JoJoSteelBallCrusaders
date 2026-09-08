-- ServerScriptService.BasicCombat.SummonHandler.lua

local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local summonEvent = Instance.new("RemoteEvent")
summonEvent.Name = "SummonEvent"
summonEvent.Parent = replicatedStorage.Shared.BasicCombat

local pilotModule = require(game.ServerScriptService.BasicCombat:WaitForChild("PilotModule"))
local physicsService = game:GetService("PhysicsService")

local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local HeroManager = require(game.ServerScriptService.DataSaving:WaitForChild("HeroManager"))
local OceanService = require(game.ServerScriptService.OceanService:WaitForChild("OceanService"))
local AbilityHandler =
	require(game.ServerScriptService.BasicCombat.StandModules.Handlers:WaitForChild("AbilityHandler"))

---------------------------------------------------------------------
-- Physics setup (unchanged)
---------------------------------------------------------------------
local success, errorMessage = pcall(function()
	physicsService:RegisterCollisionGroup("NoCollision")
end)

if success then
	print("Collision group 'NoCollision' registered successfully.")
else
	warn("Failed to register collision group 'NoCollision': " .. errorMessage)
end

---------------------------------------------------------------------
-- Summon logic
---------------------------------------------------------------------
local function onSummonRequested(player)
	local character = player.Character
	if not character then
		return
	end

	---------------------------------------------------------------
	-- 🌟 NEW: Get hero data from HeroManager instead of Folder
	---------------------------------------------------------------
	local hero = HeroManager.GetField(player, "Hero")

	if hero then
		print(hero)
	else
		print("no hero value found1!")
	end

	if not hero or hero == "None" or hero == "" then
		warn("⚠️ No Hero set for", player.Name)
		return
	end

	-- standTag is whatever your StandUtils expects
	local standTag = hero

	---------------------------------------------------------------
	-- Toggle summon / unsummon
	---------------------------------------------------------------
	local currentStand = StandUtils.getStandModel(character)

	if currentStand then
		StandUtils.RemoveStand(character)
		pilotModule.ExitPilotMode(character)

		-- Broadcast the off-stand ability types now that the stand is off. This
		-- lives here (not on StandUtils) because resolving the off registry
		-- pulls in CombatUtils, which already requires StandUtils -- doing it
		-- from inside StandUtils would create a require cycle.
		AbilityHandler.SendOffAbilityTypes(player)
		print("Removed stand / exited pilot")
	else
		StandUtils.SummonStand(character, standTag)

		if OceanService:IsSwimming(character) then
			StandUtils.StartSwimmingCorrection(character)
		end
		print("Summoned stand:", standTag)
	end
end

summonEvent.OnServerEvent:Connect(onSummonRequested)

---------------------------------------------------------------------
-- On spawn, players start with no stand summoned -- broadcast the off-stand
-- (bare-handed) ability types and clear any leftover cooldown bars. This is
-- a best-effort push; the client also actively pulls its current ability
-- types on join/respawn (see StandAbilities.client.luau) so it doesn't
-- depend on winning the race against this event.
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		AbilityHandler.SendOffAbilityTypes(player)
		StandUtils.ResetCooldownUI(player)
	end)
end)
