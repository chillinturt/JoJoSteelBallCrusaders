-- InventorySerializer.lua
local InventorySerializer = {}

function InventorySerializer.Serialize(backpack)
	local data = {}
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			table.insert(data, {
				Name = tool.Name,
				Amount = tool:GetAttribute("amount") or 1,
			})
		end
	end
	return data
end

function InventorySerializer.Deserialize(player, savedList, itemFolders)
	if not savedList then
		return
	end
	local backpack = player:WaitForChild("Backpack")

	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
		end
	end

	for _, entry in ipairs(savedList) do
		local template = itemFolders.Stand:FindFirstChild(entry.Name) or itemFolders.Race:FindFirstChild(entry.Name)

		if template then
			local clone = template:Clone()
			clone:SetAttribute("amount", entry.Amount or 1)
			clone.Parent = backpack
		else
			warn("Missing tool:", entry.Name)
		end
	end
end

return InventorySerializer
