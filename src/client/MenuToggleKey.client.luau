local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIController = require(ReplicatedStorage.Shared.Modules:WaitForChild("UIController"))

--------------------------------------------------
-- ACTION NAMES
--------------------------------------------------

local TOGGLE_MENU_ACTION = "ToggleMenu"
local CLOSE_UI_ACTION = "CloseUI"

--------------------------------------------------
-- ACTION HANDLERS
--------------------------------------------------

local function onToggleMenu(actionName, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return
	end

	UIController.Toggle("Menu")
end

local function onCloseUI(actionName, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return
	end

	UIController.CloseAll()
end

--------------------------------------------------
-- BIND INPUTS
--------------------------------------------------

-- Toggle Menu (PC + Console)
ContextActionService:BindAction(
	TOGGLE_MENU_ACTION,
	onToggleMenu,
	false,
	Enum.KeyCode.M, -- PC
	Enum.KeyCode.ButtonStart -- Console (Start/Menu button)
)

-- Close UI (ESC + B button)
ContextActionService:BindAction(
	CLOSE_UI_ACTION,
	onCloseUI,
	false,
	Enum.KeyCode.Escape, -- PC
	Enum.KeyCode.ButtonB -- Console (Back / Cancel)
)
