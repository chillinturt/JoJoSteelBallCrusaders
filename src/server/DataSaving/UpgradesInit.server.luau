local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- require the module so it actually runs
local CharacterUpgrades = require(ServerScriptService.DataSaving:WaitForChild("CharacterUpdgrades"))

---------------------------------------------------------------------
-- CLEANUP ON PLAYER JOIN
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	-- Ensure folder exists
	CharacterUpgrades.getUpgradeFolder(player)
end)
