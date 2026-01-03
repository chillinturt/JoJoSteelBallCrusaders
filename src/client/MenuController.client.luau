local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MenuState = require(player.PlayerScripts.MenuState)

local OpenMenuEvent = ReplicatedStorage.Bindables.OpenMainMenu
local ExitMenuEvent = ReplicatedStorage.Bindables.ExitMainMenu

-- Store button connections so we can disconnect old ones
local openButtonConnection, closeButtonConnection

-- Helpers to hide/show other UIs
local function hideGameplayUIs()
	for _, ui in ipairs(playerGui:GetChildren()) do
		if ui:IsA("ScreenGui") and ui.Name ~= "MainMenu" then
			ui.Enabled = false
		end
	end
end

local function showGameplayUIs()
	for _, ui in ipairs(playerGui:GetChildren()) do
		if ui:IsA("ScreenGui") and ui.Name ~= "MainMenu" then
			ui.Enabled = true
		end
	end
end

-- Apply MenuState to UI
local function applyState()
	local mainMenu = playerGui:FindFirstChild("MainMenu")
	if not mainMenu then
		return -- could optionally wait or retry
	end

	mainMenu.Enabled = MenuState.MenuOpen

	if MenuState.MenuOpen then
		hideGameplayUIs()
		OpenMenuEvent:Fire()
	else
		showGameplayUIs()
		ExitMenuEvent:Fire()
	end
end

-- Bind buttons (Open from SettingsGUI, Close from MainMenu)
local function bindButtons()
	-- Bind Open Menu button from SettingsGUI
	local openButton
	local settings = playerGui:FindFirstChild("SettingsGUI")
	if settings then
		local window = settings:FindFirstChild("SettingsWindow")
		if window then
			local scrolling = window:FindFirstChild("ScrollingFrame")
			if scrolling then
				openButton = scrolling:FindFirstChild("MainMenu") -- this is your Open button
			end
		end
	end

	-- Bind Close Menu button from MainMenu
	local mainMenu = playerGui:FindFirstChild("MainMenu")
	local closeButton
	if mainMenu then
		closeButton = mainMenu:FindFirstChild("CloseButton")
	end

	-- Disconnect previous connections if they exist
	if openButtonConnection then
		openButtonConnection:Disconnect()
	end
	if closeButtonConnection then
		closeButtonConnection:Disconnect()
	end

	-- Connect buttons if they exist
	if openButton then
		openButtonConnection = openButton.MouseButton1Click:Connect(function()
			MenuState:SetOpen(true)
		end)
	end

	if closeButton then
		closeButtonConnection = closeButton.MouseButton1Click:Connect(function()
			MenuState:SetOpen(false)
		end)
	end
end

local function bindOpenMenuButton()
	local settings = playerGui:FindFirstChild("SettingsGUI")
	if not settings then
		return
	end
	local window = settings:FindFirstChild("SettingsWindow")
	if not window then
		return
	end
	local scrolling = window:FindFirstChild("ScrollingFrame")
	if not scrolling then
		return
	end
	local openButton = scrolling:FindFirstChild("MainMenu")
	if not openButton then
		return
	end

	-- Disconnect previous connection if it exists
	if openButtonConnection then
		openButtonConnection:Disconnect()
	end

	openButtonConnection = openButton.MouseButton1Click:Connect(function()
		MenuState:SetOpen(true)
	end)
end

-- React to state changes
MenuState.Changed.Event:Connect(applyState)

-- Rebind buttons and re-apply state whenever relevant UI is added
playerGui.ChildAdded:Connect(function(child)
	task.defer(function()
		bindButtons()
		applyState()
	end)
	if child.Name == "SettingsGUI" then
		task.defer(function()
			bindOpenMenuButton()
		end)
	end
end)

-- Apply state on respawn
player.CharacterAdded:Connect(function()
	MenuState:SetOpen(true)
	task.defer(applyState)
end)

-- Initial setup
bindButtons()
bindOpenMenuButton()
MenuState:SetOpen(true) -- start menu closed
