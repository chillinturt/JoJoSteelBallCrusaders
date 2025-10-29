-- ExtraHealthServer.lua
-- Gives players extra maximum and current HP on spawn and respawn

local Players = game:GetService("Players")

-- === CONFIG ===
local EXTRA_HEALTH = 100 -- amount of extra HP to add
local INITIAL_HEALTH = 100 -- Roblox default Humanoid health

-- === FUNCTIONS ===
local function applyExtraHealth(character)
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- Wait until humanoid loads its properties
	humanoid.MaxHealth = INITIAL_HEALTH + EXTRA_HEALTH
	humanoid.Health = humanoid.MaxHealth
end

-- Called when the player’s character spawns
local function onCharacterAdded(character)
	-- Wait briefly to ensure Humanoid exists
	character:WaitForChild("Humanoid")
	task.wait(0.1)
	applyExtraHealth(character)
end

-- Called when a new player joins
Players.PlayerAdded:Connect(function(player)
	-- For their initial character
	player.CharacterAdded:Connect(onCharacterAdded)

	-- If character already exists (e.g., studio test)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end)
