local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local HIGHLIGHT_DISTANCE = 18
local UPDATE_RATE = 0.1

local activeHighlights = {}
local activeInteractUIs = {}

local highlightColors = {
	Shop = Color3.fromRGB(60, 255, 60),
	Quest = Color3.fromRGB(255, 220, 50),
	Neutral = Color3.fromRGB(255, 255, 255),
	Important = Color3.fromRGB(255, 120, 120),
}

local function getCharacterRoot()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

-------------------------------------------------
-- Highlight Logic
-------------------------------------------------

local function createHighlight(npc)
	if activeHighlights[npc] then
		return
	end

	local highlightType = npc:GetAttribute("HighlightType") or "Neutral"

	local color = highlightColors[highlightType] or Color3.new(1, 1, 1)

	local highlight = Instance.new("Highlight")
	highlight.Name = "LocalNPCHighlight"

	highlight.FillColor = color
	highlight.OutlineColor = color

	highlight.FillTransparency = 0.7
	highlight.OutlineTransparency = 0

	highlight.DepthMode = Enum.HighlightDepthMode.Occluded

	highlight.Adornee = npc
	highlight.Parent = npc

	activeHighlights[npc] = highlight
end

local function removeHighlight(npc)
	local highlight = activeHighlights[npc]

	if highlight then
		highlight:Destroy()
		activeHighlights[npc] = nil
	end
end

-------------------------------------------------
-- Interact UI
-------------------------------------------------

local function createInteractUI(npc)
	if activeInteractUIs[npc] then
		return
	end

	local torso = npc:FindFirstChild("UpperTorso") or npc:FindFirstChild("HumanoidRootPart")

	if not torso then
		return
	end

	local billboard = Instance.new("BillboardGui")

	billboard.Name = "LocalInteractGui"

	billboard.Adornee = torso
	billboard.Size = UDim2.new(0, 150, 0, 40)

	billboard.StudsOffset = Vector3.new(0, 0, 0)

	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 30
	billboard.Parent = npc

	local text = Instance.new("TextLabel")

	text.Size = UDim2.fromScale(1, 1)

	text.BackgroundTransparency = 1

	text.Text = "Interact"

	text.TextScaled = true
	text.Font = Enum.Font.GothamBold

	text.TextColor3 = Color3.new(1, 1, 1)

	text.TextStrokeTransparency = 0
	text.TextStrokeColor3 = Color3.new(0, 0, 0)

	text.Parent = billboard

	activeInteractUIs[npc] = billboard
end

local function removeInteractUI(npc)
	local ui = activeInteractUIs[npc]

	if ui then
		ui:Destroy()
		activeInteractUIs[npc] = nil
	end
end

-------------------------------------------------
-- Main Loop
-------------------------------------------------

local elapsed = 0

RunService.RenderStepped:Connect(function(deltaTime)
	elapsed += deltaTime

	if elapsed < UPDATE_RATE then
		return
	end

	elapsed = 0

	local root = getCharacterRoot()

	if not root then
		return
	end

	for _, npc in ipairs(CollectionService:GetTagged("InteractableNPC")) do
		local npcRoot = npc:FindFirstChild("HumanoidRootPart")

		if npcRoot then
			local distance = (root.Position - npcRoot.Position).Magnitude

			local inRange = distance <= HIGHLIGHT_DISTANCE

			if inRange then
				createHighlight(npc)
				createInteractUI(npc)
			else
				removeHighlight(npc)
				removeInteractUI(npc)
			end
		end
	end
end)
