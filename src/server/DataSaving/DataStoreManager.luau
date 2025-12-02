-- DataStoreManager.lua
local DataStoreService = game:GetService("DataStoreService")

local DataStoreManager = {}
local STORE_NAME = "PlayerData"

local store = DataStoreService:GetDataStore(STORE_NAME)

-- Safe wrapper
function DataStoreManager:Get(key)
	local success, result = pcall(function()
		return store:GetAsync(key)
	end)

	if success then
		return result
	else
		warn("[DataStore] Get failed:", result)
		return nil
	end
end

function DataStoreManager:Set(key, data)
	local success, err = pcall(function()
		store:SetAsync(key, data)
	end)

	if not success then
		warn("[DataStore] Set failed:", err)
		return false
	end

	return true
end

return DataStoreManager
