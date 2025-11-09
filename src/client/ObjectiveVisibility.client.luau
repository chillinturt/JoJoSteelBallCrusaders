local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local VISIBILITY_DISTANCE = 150 -- distance threshold
local controlPointFolder = workspace:WaitForChild("Objectives")
local KOTHFolder = controlPointFolder:WaitForChild("KOTH")
local ThreeTeamKothFolder = controlPointFolder:WaitForChild("ThreeTeamKOTH")

-- Keep a reference to all BillboardGuis in a table
local controlPointGUIs = {}

-- Helper function to register a control point GUI
local function registerControlPoint(point)
	if not point or not point.Parent then
		return
	end

	-- Find the WorldModel inside this KOTH part/model
	local worldModel = point:FindFirstChildWhichIsA("WorldModel")
	if not worldModel then
		worldModel = point:WaitForChild("WorldModel", 10)
	end

	if worldModel then
		local gui = worldModel:FindFirstChild("BillboardGui") or worldModel:WaitForChild("BillboardGui", 10)
		if gui then
			controlPointGUIs[point] = gui
			gui.Enabled = false -- start hidden until player is close
			print("[Client] Registered BillboardGui for:", point.Name)
		else
			warn("[Client] No BillboardGui found inside WorldModel for:", point.Name)
		end
	else
		warn("[Client] No WorldModel found inside:", point.Name)
	end
end

-- Initial scan for any pre-existing control points
for _, koth in ipairs(KOTHFolder:GetChildren()) do
	if koth:IsA("BasePart") or koth:IsA("Model") then
		registerControlPoint(koth)
	end
end

-- Initial scan for any pre-existing control points
for _, koth in ipairs(ThreeTeamKothFolder:GetChildren()) do
	if koth:IsA("BasePart") or koth:IsA("Model") then
		registerControlPoint(koth)
	end
end

-- Automatically track new control points added later
ThreeTeamKothFolder.ChildAdded:Connect(function(point)
	registerControlPoint(point)
end)

-- Automatically track new control points added later
KOTHFolder.ChildAdded:Connect(function(point)
	registerControlPoint(point)
end)

-- Main visibility loop
RunService.Heartbeat:Connect(function()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	for point, gui in pairs(controlPointGUIs) do
		if point and point.Parent and gui then
			-- Get world position of the point (use part position or model primary part)
			local pos
			if point:IsA("Model") then
				pos = point.PrimaryPart and point.PrimaryPart.Position
			else
				pos = point.Position
			end

			if pos then
				local distance = (pos - root.Position).Magnitude
				gui.Enabled = distance <= VISIBILITY_DISTANCE
			end
		end
	end
end)
