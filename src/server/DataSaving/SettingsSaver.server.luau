-- ServerScriptService/MusicSettingsManager
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local musicStore = DataStoreService:GetDataStore("PlayerMusicSettings")

-- RemoteEvent for client communication
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local eventFolder = ReplicatedStorage:FindFirstChild("MusicEvents") or Instance.new("Folder", ReplicatedStorage)
eventFolder.Name = "MusicEvents"

local musicSettingsEvent = Instance.new("RemoteEvent")
musicSettingsEvent.Name = "MusicSettingsEvent"
musicSettingsEvent.Parent = eventFolder

-- When player joins: load saved setting
Players.PlayerAdded:Connect(function(player)
	local enabled = true -- default
	local success, result = pcall(function()
		return musicStore:GetAsync(tostring(player.UserId))
	end)
	if success and type(result) == "boolean" then
		enabled = result
	end
	musicSettingsEvent:FireClient(player, enabled)
end)

-- When client updates music setting
musicSettingsEvent.OnServerEvent:Connect(function(player, enabled)
	if typeof(enabled) ~= "boolean" then return end
	pcall(function()
		musicStore:SetAsync(tostring(player.UserId), enabled)
	end)
end)
