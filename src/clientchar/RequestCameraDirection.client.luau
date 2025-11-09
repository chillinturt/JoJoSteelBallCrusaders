local replicatedStorage = game:GetService("ReplicatedStorage")
local RequestCameraDirection = replicatedStorage.Shared.BasicCombat:FindFirstChild("RequestCameraDirection")

RequestCameraDirection.OnClientInvoke = function()
	local camera = workspace.CurrentCamera
	if not camera then
		warn("No camera found on client")
		return Vector3.new(0, 0, 0)
	end

	-- Just return the camera's facing direction
	return camera.CFrame.LookVector
end
