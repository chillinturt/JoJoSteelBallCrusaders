-- StarterPlayerScripts: InventoryUIController.client.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryUpdatedEvent =
	ReplicatedStorage:WaitForChild("UIs"):WaitForChild("RemoteEvents"):WaitForChild("InventoryUpdated")

local player = Players.LocalPlayer

local InventoryState = require(player.PlayerScripts:WaitForChild("InventoryState"))

---------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------

local inventoryGui -- ScreenGui
local connection -- OnClientEvent connection (so we can avoid duplicates)

---------------------------------------------------------------------
-- UI REFRESH FUNCTION (you fill this in later)
---------------------------------------------------------------------

local function RefreshUI(inventory)
	-- 🔹 Find UI container
	local playerGui = player:WaitForChild("PlayerGui")
	local inventoryGui = playerGui:WaitForChild("Inventory")
	local baseFrame = inventoryGui:WaitForChild("Frame")
	local scrollingFrame = baseFrame:WaitForChild("ScrollingFrame")
	local template = baseFrame:WaitForChild("ItemTemplate")

	InventoryState:Clear()

	-- 🔹 Clear existing items
	for _, child in ipairs(scrollingFrame:GetChildren()) do
		if child:IsA("Frame") and child ~= template then
			child:Destroy()
		end
	end

	-----------------------------------------------------------------
	-- 🔥 Rebuild UI with clickable items
	-----------------------------------------------------------------
	for itemId, itemData in pairs(inventory) do
		local itemFrame = template:Clone()
		itemFrame.Visible = true
		itemFrame.Name = tostring(itemId)
		itemFrame.Parent = scrollingFrame

		-- update UI text
		local itemNameLabel = itemFrame:FindFirstChild("ItemName")
		local itemAmountLabel = itemFrame:FindFirstChild("Amount")

		local itemName = itemData.name or itemData.Name or tostring(itemId)
		local itemAmt = itemData.Amount or itemData.quantity or 1

		if itemNameLabel then
			itemNameLabel.Text = itemName
		end

		if itemAmountLabel then
			itemAmountLabel.Text = "x " .. tostring(itemAmt)
		end

		-----------------------------------------------------------------
		-- 👇 ADD CLICK HANDLER (required after respawn)
		-----------------------------------------------------------------
		itemFrame.MouseButton1Click:Connect(function()
			InventoryState.SelectedItem = {
				Name = itemName,
				Amount = itemAmt,
			}

			print("Selected:", InventoryState.SelectedItem.Name, "x" .. InventoryState.SelectedItem.Amount)

			-- (Optional UI feedback)
			local selectedLabel = baseFrame:WaitForChild("SelectedItem"):WaitForChild("TextLabel")
			selectedLabel.Text = InventoryState.SelectedItem.Name
				.. " (x"
				.. tostring(InventoryState.SelectedItem.Amount)
				.. ")"
		end)
	end
end
---------------------------------------------------------------------
-- BIND UI (called on join + every respawn)
---------------------------------------------------------------------

local function bindUI()
	local playerGui = player:WaitForChild("PlayerGui")

	-- Wait for UI to exist
	inventoryGui = playerGui:WaitForChild("Inventory", 5)
	if not inventoryGui then
		warn("[Inventory UI] Inventory ScreenGui not found.")
		return
	end

	-----------------------------------------------------------------
	-- Prevent multiple event listeners (CRITICAL)
	-----------------------------------------------------------------
	if connection then
		connection:Disconnect()
		connection = nil
	end

	-----------------------------------------------------------------
	-- Connect remote event once
	-----------------------------------------------------------------
	connection = InventoryUpdatedEvent.OnClientEvent:Connect(function(inventory)
		RefreshUI(inventory)
	end)

	print("[Inventory UI] Bound to remote event.")
end

---------------------------------------------------------------------
-- INITIAL RUN
---------------------------------------------------------------------

-- Bind on first spawn
bindUI()

-- Bind again every time character respawns
player.CharacterAdded:Connect(bindUI)
