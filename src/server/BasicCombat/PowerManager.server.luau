local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	-- Create the StringValue
	local heroValue = Instance.new("StringValue")
	heroValue.Name = "Hero"
	heroValue.Value = "" -- default value (empty string, can change later)
	heroValue.Parent = player

	local specValue = Instance.new("StringValue")
	specValue.Name = "Specialty"
	specValue.Value = ""
	specValue.Parent = player
end)
