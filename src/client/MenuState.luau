local Players = game:GetService("Players")

local player = Players.LocalPlayer

local MenuState = {}

MenuState.Changed = Instance.new("BindableEvent")

-- Default UI states
local DEFAULT_STATES = {
	MainMenu = true,
	QuestGUI = true,
}

local function getAttributeName(uiName)
	return "UI_" .. uiName .. "_Open"
end

local function ensureAttribute(uiName)
	local attr = getAttributeName(uiName)

	if player:GetAttribute(attr) == nil then
		local default = DEFAULT_STATES[uiName] or false
		player:SetAttribute(attr, default)
	end
end

function MenuState:IsOpen(uiName)
	ensureAttribute(uiName)
	return player:GetAttribute(getAttributeName(uiName))
end

function MenuState:SetOpen(uiName, isOpen)
	ensureAttribute(uiName)

	player:SetAttribute(getAttributeName(uiName), isOpen)

	MenuState.Changed:Fire(uiName, isOpen)

	print("UI state changed:", uiName, isOpen)
end

return MenuState
