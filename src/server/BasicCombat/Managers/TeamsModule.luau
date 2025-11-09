--// TeamsModule.lua
-- Centralized team management system (supports both Players and NPCs/Models)

local TeamsModule = {}

-- Internal data store
local EntityTeams = {} -- [Entity] = "TeamA" or "TeamB"
local AutoCleanupConnections = {} -- [Model] = connection
local PlayerCharacterConnections = {} -- [Player] = connection

-- Team constants
TeamsModule.TeamA = "TeamA"
TeamsModule.TeamB = "TeamB"
TeamsModule.TeamC = "TeamC"

-- Helper: get a consistent key for entity (Player or Model)
local function getEntityKey(entity)
	if entity:IsA("Player") then
		return entity
	elseif entity:IsA("Model") then
		return entity
	else
		warn("TeamsModule: Unsupported entity type ->", entity)
		return nil
	end
end

-- Internal helper to assign player's character to team and track respawns
local function trackPlayerCharacter(player, team)
	-- Clean up any existing listener for this player
	if PlayerCharacterConnections[player] then
		PlayerCharacterConnections[player]:Disconnect()
		PlayerCharacterConnections[player] = nil
	end

	-- Assign team to current character if present
	if player.Character then
		TeamsModule.SetTeam(player.Character, team)
	end

	-- Re-assign on every respawn
	local conn = player.CharacterAdded:Connect(function(character)
		TeamsModule.SetTeam(character, team)
	end)
	PlayerCharacterConnections[player] = conn
end

-- Assign entity to a team
function TeamsModule.SetTeam(entity, teamName)
	assert(entity, "SetTeam: entity cannot be nil")
	assert(teamName == TeamsModule.TeamA or teamName == TeamsModule.TeamB or TeamsModule.TeamC, "Invalid team name")

	local key = getEntityKey(entity)
	if not key then
		return
	end

	EntityTeams[key] = teamName

	if entity:IsA("Player") then
		-- Automatically track their character
		trackPlayerCharacter(entity, teamName)
	else
		-- Auto-cleanup for NPCs/Models
		if AutoCleanupConnections[entity] then
			AutoCleanupConnections[entity]:Disconnect()
		end

		local conn
		conn = entity.AncestryChanged:Connect(function(_, parent)
			if not parent then
				EntityTeams[key] = nil
				if AutoCleanupConnections[entity] then
					AutoCleanupConnections[entity]:Disconnect()
					AutoCleanupConnections[entity] = nil
				end
			end
		end)
		AutoCleanupConnections[entity] = conn
	end
end

-- Remove entity from team
function TeamsModule.RemoveEntity(entity)
	local key = getEntityKey(entity)
	if not key then
		return
	end

	EntityTeams[key] = nil

	if entity:IsA("Player") then
		-- Clean up tracking connection
		if PlayerCharacterConnections[entity] then
			PlayerCharacterConnections[entity]:Disconnect()
			PlayerCharacterConnections[entity] = nil
		end
	else
		-- Disconnect auto-cleanup for NPCs
		if AutoCleanupConnections[entity] then
			AutoCleanupConnections[entity]:Disconnect()
			AutoCleanupConnections[entity] = nil
		end
	end
end

-- Get team of an entity
function TeamsModule.GetTeam(entity)
	local key = getEntityKey(entity)
	if not key then
		return nil
	end
	return EntityTeams[key]
end

-- Check if two entities are teammates
function TeamsModule.AreTeammates(entity1, entity2)
	if entity1 == entity2 then
		return true
	end
	local key1 = getEntityKey(entity1)
	local key2 = getEntityKey(entity2)

	if not (key1 and key2) then
		return false
	end
	return EntityTeams[key1] ~= nil and EntityTeams[key1] == EntityTeams[key2]
end

-- Auto-balance assignment (optional)
function TeamsModule.AutoAssign(entity)
	local key = getEntityKey(entity)
	if not key then
		return
	end

	local countA, countB, countC = 0, 0
	for _, t in pairs(EntityTeams) do
		if t == TeamsModule.TeamA then
			countA += 1
		elseif t == TeamsModule.TeamB then
			countB += 1
		elseif t == TeamsModule.TeamC then
			countC += 1
		end
	end

	if countA <= countB then
		EntityTeams[key] = TeamsModule.TeamA
	else
		EntityTeams[key] = TeamsModule.TeamB
	end

	local assignedTeam = EntityTeams[key]
	if entity:IsA("Player") then
		trackPlayerCharacter(entity, assignedTeam)
	end

	return assignedTeam
end

-- Clean up on player leave
game.Players.PlayerRemoving:Connect(function(player)
	EntityTeams[player] = nil
	if PlayerCharacterConnections[player] then
		PlayerCharacterConnections[player]:Disconnect()
		PlayerCharacterConnections[player] = nil
	end
end)

return TeamsModule
