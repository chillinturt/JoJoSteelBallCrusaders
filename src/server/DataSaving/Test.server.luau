local Players = game:GetService("Players")

local PlayerDataService = require(script.Parent.PlayerData)

while true do
	for _, player in Players:GetChildren() do
		PlayerDataService.AddCash(player, -1)
	end

	task.wait(1)
end
