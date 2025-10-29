local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local teleportEvent = replicatedStorage.Shared.BasicCombat.KingCarmine:FindFirstChild("Teleport")
local RequestTeleportTarget = replicatedStorage.Shared.BasicCombat.KingCarmine:FindFirstChild("RequestTeleportTarget")
local RaycastIgnoreModule = require(replicatedStorage.Shared.Modules:WaitForChild("RaycastIgnoreModule"))

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local MAX_TELEPORT_DISTANCE = 60

-- Detect T press and send request to server
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Z then
		teleportEvent:InvokeServer() -- Request summon from the server
	end
end)

RequestTeleportTarget.OnClientInvoke = function()
	local camera = workspace.CurrentCamera
	local origin = camera.CFrame.Position
	local mouseRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local maxDistance = MAX_TELEPORT_DISTANCE
	local direction = mouseRay.Direction * maxDistance

	-- Build ignore list
	local ignoreList = {}
	for _, inst in ipairs(RaycastIgnoreModule.GetIgnoreList()) do
		if inst:IsDescendantOf(workspace) then
			table.insert(ignoreList, inst)
		end
	end
	table.insert(ignoreList, player.Character)

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = ignoreList
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(origin, direction, params)

	if result then
		-- Return just beyond the ignored surface
		local buffer = 1
		return result.Position + mouseRay.Direction.Unit * buffer
	else
		return origin + direction
	end
end
