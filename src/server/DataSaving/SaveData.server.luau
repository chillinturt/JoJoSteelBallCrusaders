local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local inventoryItemsFolder = ReplicatedStorage.Items.StandItems:WaitForChild("InventoryTools")
local playerDataStore = DataStoreService:GetDataStore("PlayerData") -- inventory + hero + xp/level

-- Convert backpack into a savable table
local function serializeInventory(player)
	local data = {}

	for _, tool in ipairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			table.insert(data, {
				Name = tool.Name,
				Amount = tool:GetAttribute("amount") or 1,
			})
		end
	end

	return data
end

-- Restore tools from saved data
local function deserializeInventory(player, data)
	if not data then
		return
	end
	local backpack = player:WaitForChild("Backpack")

	-- Clear existing tools to prevent duplicates
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
		end
	end

	-- Restore from data
	for _, itemData in ipairs(data) do
		local toolTemplate = inventoryItemsFolder:FindFirstChild(itemData.Name)
		if toolTemplate then
			local tool = toolTemplate:Clone()
			tool:SetAttribute("amount", itemData.Amount or 1)
			tool.Parent = backpack
		else
			warn("⚠️ Could not find tool template for:", itemData.Name)
		end
	end
end

-- Save player data (inventory + hero + xp + level)
local function savePlayerData(player)
	local success, err = pcall(function()
		local heroValue = player:FindFirstChild("Hero")
		local specValue = player:FindFirstChild("Specialty")
		local stats = player:FindFirstChild("Stats")

		local data = {
			Inventory = serializeInventory(player),
			Hero = heroValue and heroValue.Value or "",
			Spec = specValue and specValue.Value or "",
			XP = stats and stats:FindFirstChild("XP") and stats.XP.Value or 0,
			Level = stats and stats:FindFirstChild("Level") and stats.Level.Value or 1,
			MaxXP = stats and stats:FindFirstChild("MaxXP") and stats.MaxXP.Value or 100,
		}

		playerDataStore:SetAsync(player.UserId .. "_Data", data)
	end)

	if not success then
		warn("⚠️ Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end
end

-- Load player data
local function loadPlayerData(player)
	local success, data = pcall(function()
		return playerDataStore:GetAsync(player.UserId .. "_Data")
	end)

	if success and data then
		return data
	else
		if not success then
			warn("⚠️ Failed to load data for " .. player.Name .. ": " .. tostring(data))
		end
		return nil
	end
end

-- Handle respawn (restore inventory after death)
local function setupCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Patch: Force equipped tools back into Backpack + save immediately on death
	humanoid.Died:Connect(function()
		-- Move any equipped tools back into Backpack
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") then
				tool.Parent = player.Backpack
			end
		end

		-- Save instantly
		savePlayerData(player)
	end)
end

-- Player connections
Players.PlayerAdded:Connect(function(player)
	-- Load saved data
	local savedData = loadPlayerData(player)

	-- Restore hero immediately
	if savedData and savedData.Hero and player:FindFirstChild("Hero") then
		player.Hero.Value = savedData.Hero
	end
	if savedData and savedData.Spec and player:FindFirstChild("Specialty") then
		player.Specialty.Value = savedData.Spec
	else
		print("no spec loaded")
	end

	-- Restore XP/Level immediately
	if savedData and player:FindFirstChild("Stats") then
		local stats = player.Stats
		if savedData.XP and stats:FindFirstChild("XP") then
			stats.XP.Value = savedData.XP
		end
		if savedData.Level and stats:FindFirstChild("Level") then
			stats.Level.Value = savedData.Level
		end
		if savedData.MaxXP and stats:FindFirstChild("MaxXP") then
			stats.MaxXP.Value = savedData.MaxXP
		end
	end

	-- CharacterAdded: restore inventory + setup death handling
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)

		-- Restore latest inventory
		local latestData = loadPlayerData(player)
		if latestData and latestData.Inventory then
			task.defer(function()
				deserializeInventory(player, latestData.Inventory)
			end)
		end
	end)

	-- Auto-save on Backpack changes
	player:WaitForChild("Backpack").ChildAdded:Connect(function()
		savePlayerData(player)
	end)
	player.Backpack.ChildRemoved:Connect(function()
		savePlayerData(player)
	end)

	-- Periodic autosave
	task.spawn(function()
		while player.Parent do
			task.wait(60)
			savePlayerData(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
end)
