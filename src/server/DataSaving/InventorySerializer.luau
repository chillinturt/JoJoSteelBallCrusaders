local InventorySerializer = {}

---------------------------------------------------------
-- SERIALIZE: READ ONLY MEMORY, NEVER BACKPACK
---------------------------------------------------------
function InventorySerializer.Serialize(memoryInventory)
	-- deep copy to avoid mutation
	local data = {}
	for _, entry in ipairs(memoryInventory) do
		table.insert(data, {
			Name = entry.Name,
			Amount = entry.Amount or 1,
		})
	end
	return data
end

---------------------------------------------------------
-- DESERIALIZE: APPLY MEMORY TO BACKPACK
---------------------------------------------------------
function InventorySerializer.Deserialize(player, memoryInventory, itemFolders)
	if not memoryInventory then
		return
	end

	local backpack = player:WaitForChild("Backpack")

	-- Clear backpack
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
		end
	end

	-- Rebuild inventory from memory table
	for _, entry in ipairs(memoryInventory) do
		local template = (itemFolders.Stand and itemFolders.Stand:FindFirstChild(entry.Name))
			or (itemFolders.Race and itemFolders.Race:FindFirstChild(entry.Name))

		if template then
			local clone = template:Clone()
			clone:SetAttribute("amount", entry.Amount or 1)
			clone.Parent = backpack
		else
			warn("Inventory item missing template:", entry.Name)
		end
	end
end

return InventorySerializer
