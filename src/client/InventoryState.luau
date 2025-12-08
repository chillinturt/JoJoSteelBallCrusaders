-- InventoryState.lua (ModuleScript)

local InventoryState = {
	SelectedItem = nil,
	Inventory = {}, -- optional but useful
}

function InventoryState:SetSelected(itemData)
	self.SelectedItem = itemData
end

function InventoryState:ClearSelection()
	self.SelectedItem = nil
end

return InventoryState
