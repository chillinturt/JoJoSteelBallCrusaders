local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local function getPowersFolder(player)
	local powersFolder = player:FindFirstChild("Powers")
	if not powersFolder then
		powersFolder = Instance.new("Folder")
		powersFolder.Name = "Powers"
		powersFolder.Parent = player

		local hero = Instance.new("StringValue")
		hero.Name = "Hero"
		hero.Value = ""
		hero.Parent = powersFolder

		local specialty = Instance.new("StringValue")
		specialty.Name = "Specialty"
		specialty.Value = ""
		specialty.Parent = powersFolder

		local race = Instance.new("StringValue")
		race.Name = "Race"
		race.Value = ""
		race.Parent = powersFolder
	end

	return powersFolder
end

Players.PlayerAdded:Connect(function(player)
	local powersFolder = getPowersFolder(player)

	player.CharacterAdded:Connect(function(character)
		-- Clone powers folder onto new character
		local charPowers = powersFolder:Clone()
		charPowers.Parent = character
	end)
end)
