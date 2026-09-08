-- Connects Innkeeper NPC ProximityPrompts to InteractionHandler.
-- Innkeeper NPCs must live in workspace.NPCs.Innkeepers.
-- Each NPC model must have a NPCName StringValue whose value matches a key
-- in SpawnConfig.InnkeeperNpcs (e.g. "LowLevelSpawn").

local ServerScriptService = game:GetService("ServerScriptService")

local InteractionHandler = require(ServerScriptService.Objectives.Quests:WaitForChild("InteractionHandler"))

local function connectInnkeeper(npcModel: Model)
	local root = npcModel:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local prompt = root:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then return end

	prompt.Triggered:Connect(function(player: Player)
		InteractionHandler.OpenNPCInteraction(player, npcModel)
	end)
end

local innkeeperFolder = workspace:WaitForChild("NPCs"):WaitForChild("Innkeepers")

for _, npc in ipairs(innkeeperFolder:GetChildren()) do
	if npc:IsA("Model") then
		connectInnkeeper(npc)
	end
end

innkeeperFolder.ChildAdded:Connect(function(npc: Instance)
	if npc:IsA("Model") then
		connectInnkeeper(npc)
	end
end)
