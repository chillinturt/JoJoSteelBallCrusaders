-- MenuState.lua
local MenuState = {}

MenuState.MenuOpen = false
MenuState.Changed = Instance.new("BindableEvent")

-- Use this setter instead of directly setting MenuOpen
function MenuState:SetOpen(isOpen)
	self.MenuOpen = isOpen
	self.Changed:Fire(isOpen)
end

return MenuState
