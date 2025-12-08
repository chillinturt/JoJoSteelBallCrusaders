-- ServerScriptService.BasicCombat.SummonHandler.lua

local replicatedStorage = game:GetService("ReplicatedStorage")
local summonEvent = Instance.new("RemoteEvent")
summonEvent.Name = "SummonEvent"
summonEvent.Parent = replicatedStorage.Shared.BasicCombat

local pilotModule = require(game.ServerScriptService.BasicCombat:WaitForChild("PilotModule"))
local physicsService = game:GetService("PhysicsService")

local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local HeroManager = require(game.ServerScriptService.DataSaving:WaitForChild("HeroManager"))

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
	print("Summon fired on server")

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
		print("Removed stand / exited pilot")
	else
		StandUtils.SummonStand(character, standTag)
		print("Summoned stand:", standTag)
	end
end

summonEvent.OnServerEvent:Connect(onSummonRequested)
