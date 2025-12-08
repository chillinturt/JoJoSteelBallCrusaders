-- ServerScriptService/HeroRemoteHandler.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HeroManager = require(ServerScriptService.DataSaving.HeroManager)

local GetHeroData = Instance.new("RemoteFunction")
GetHeroData.Name = "GetHeroData"
GetHeroData.Parent = ReplicatedStorage.UIs.RemoteEvents

GetHeroData.OnServerInvoke = function(player)
	return {
		Specialty = HeroManager.GetField(player, "Specialty"),
		Race = HeroManager.GetField(player, "Race"),
		Hero = HeroManager.GetField(player, "Hero"),
	}
end
