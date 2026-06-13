local Players = game:GetService("Players")

local MAX_ZOOM = 30
local MIN_ZOOM = 5 -- optional, remove if you don't want to limit zoom-in

local function applyZoom(player)
	if not player then
		return
	end

	player.CameraMaxZoomDistance = MAX_ZOOM
	player.CameraMinZoomDistance = MIN_ZOOM
end

local function onPlayerAdded(player)
	-- Apply immediately
	applyZoom(player)

	-- Reapply on character spawn (covers resets)
	player.CharacterAdded:Connect(function()
		applyZoom(player)
	end)
end

-- 🔁 Handle players that joined BEFORE this script ran
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- 🔁 Handle players that join AFTER
Players.PlayerAdded:Connect(onPlayerAdded)
