local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local shopEvents = ReplicatedStorage:WaitForChild("ShopEvents")
local openShopDialogEvent = shopEvents:WaitForChild("OpenShopDialog")
local closeUIsEvent = shopEvents:WaitForChild("CloseShopUIs")

----------------------------------------------------------------------
-- SETTINGS
----------------------------------------------------------------------

local activeSessions = {}
local WALK_AWAY_DISTANCE = 25 -- bigger than REQUIRED_DISTANCE
local REQUIRED_DISTANCE = 12 -- Extra server safety check

local function MonitorPlayerDistance(player, npcModel)
	activeSessions[player] = npcModel

	task.spawn(function()
		while activeSessions[player] == npcModel do
			task.wait(0.25)

			local character = player.Character
			if not character then
				break
			end

			local hrp = character:FindFirstChild("HumanoidRootPart")
			local npcRoot = npcModel:FindFirstChild("HumanoidRootPart")

			if not hrp or not npcRoot then
				break
			end

			local distance = (hrp.Position - npcRoot.Position).Magnitude

			if distance > WALK_AWAY_DISTANCE then
				closeUIsEvent:FireClient(player)
				activeSessions[player] = nil
				break
			end
		end
	end)
end

----------------------------------------------------------------------
-- GET PLAYER DISTANCE FROM NPC
----------------------------------------------------------------------

local function IsPlayerNearNPC(player, npcModel)
	if not player.Character then
		return false
	end

	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	local npcRoot = npcModel:FindFirstChild("HumanoidRootPart")

	if not hrp or not npcRoot then
		return false
	end

	local distance = (hrp.Position - npcRoot.Position).Magnitude
	return distance <= REQUIRED_DISTANCE
end

----------------------------------------------------------------------
-- CONNECT ALL SHOP NPC PROMPTS
----------------------------------------------------------------------

local function ConnectNPC(npcModel)
	local root = npcModel:FindFirstChild("HumanoidRootPart")
	if not root then
		print("No hrp found for shop npc")
		return
	end

	local prompt = root:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		print("no promp found in shop npc")
		return
	end

	prompt.Triggered:Connect(function(player)
		-- Extra security distance check (never trust only prompt)
		if not IsPlayerNearNPC(player, npcModel) then
			return
		end

		-- Example dialog (customize per NPC if desired)
		local dialogText = "Welcome traveler. Looking to buy something or fast travel?"

		openShopDialogEvent:FireClient(player, npcModel.Name, dialogText)

		-- Start walk-away monitoring
		MonitorPlayerDistance(player, npcModel)
	end)
end

----------------------------------------------------------------------
-- AUTO-CONNECT EXISTING NPCS
----------------------------------------------------------------------

-- Put all shop NPCs in a folder:
-- Workspace.ShopNPCs

local shopNPCFolder = workspace.NPCs:WaitForChild("ShopNPCs")

for _, npc in ipairs(shopNPCFolder:GetChildren()) do
	if npc:IsA("Model") then
		ConnectNPC(npc)
	end
end

----------------------------------------------------------------------
-- AUTO-CONNECT FUTURE NPCS (if spawned dynamically)
----------------------------------------------------------------------

shopNPCFolder.ChildAdded:Connect(function(npc)
	if npc:IsA("Model") then
		ConnectNPC(npc)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	activeSessions[player] = nil
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function()
		activeSessions[player] = nil
	end)
end)
