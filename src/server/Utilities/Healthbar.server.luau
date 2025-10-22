-- ServerScriptService/EnableHealthbars.server.lua
local Players = game:GetService("Players")

-- Function to apply settings to a character's humanoid
local function setupHealthDisplay(character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
		humanoid.HealthDisplayDistance = 100
		humanoid.NameDisplayDistance = 100
	end
end

-- When a player's character is added (including respawns)
local function onCharacterAdded(character)
	setupHealthDisplay(character)
end

-- When a player joins the game
local function onPlayerAdded(player)
	-- Connect to character added
	player.CharacterAdded:Connect(onCharacterAdded)

	-- In case their character already exists (rare, but happens in Play Solo)
	if player.Character then
		setupHealthDisplay(player.Character)
	end
end

-- Listen for new players
Players.PlayerAdded:Connect(onPlayerAdded)

-- Also apply to any players already in-game (for Studio test)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
