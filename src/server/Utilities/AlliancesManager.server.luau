local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TeamsModule = require(game.ServerScriptService.BasicCombat.Managers:WaitForChild("TeamsModule"))

local remotes = ReplicatedStorage:WaitForChild("AllianceRemotes")

local refreshEvent = remotes:WaitForChild("RefreshAllianceUI")
local inviteEvent = remotes:WaitForChild("InvitePlayer")
local acceptEvent = remotes:WaitForChild("AcceptRequest")
local removeEvent = remotes:WaitForChild("RemovePlayer")

--------------------------------------------------
-- DATA
--------------------------------------------------

-- [allianceId] = {
--     Leader = player,
--     Members = {[player] = true}
-- }
local Alliances = {}

-- [player] = allianceId
local PlayerAlliance = {}

-- [targetPlayer] = {
--      [inviterUserId] = true
-- }
local PendingInvites = {}

local allianceCounter = 0

--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function setSoloTeam(player)
	if not player then
		return
	end

	local soloTeam = "Solo_" .. player.UserId
	TeamsModule.SetTeam(player, soloTeam)
end

local function generateAllianceId()
	allianceCounter += 1
	return "Alliance_" .. tostring(allianceCounter)
end

local function getAlliance(player)
	local allianceId = PlayerAlliance[player]

	if not allianceId then
		return nil
	end

	return Alliances[allianceId]
end

local function getAllianceMembers(player)
	local alliance = getAlliance(player)

	if not alliance then
		return {}
	end

	local result = {}

	for member in pairs(alliance.Members) do
		table.insert(result, member)
	end

	return result
end

local function syncAllianceTeams(allianceId)
	local alliance = Alliances[allianceId]

	if not alliance then
		return
	end

	for member in pairs(alliance.Members) do
		TeamsModule.SetTeam(member, allianceId)
	end
end

--------------------------------------------------
-- UI REFRESH
--------------------------------------------------

local function refreshPlayerUI(player)
	if not player then
		return
	end

	local alliedPlayers = {}
	local pendingInvites = {}
	local incomingRequests = {}

	local alliance = getAlliance(player)

	if alliance then
		for member in pairs(alliance.Members) do
			if member ~= player then
				table.insert(alliedPlayers, member.UserId)
			end
		end
	end

	if PendingInvites[player] then
		for inviterUserId in pairs(PendingInvites[player]) do
			table.insert(incomingRequests, inviterUserId)
		end
	end

	refreshEvent:FireClient(player, {
		alliedPlayers = alliedPlayers,
		pendingInvites = pendingInvites,
		incomingRequests = incomingRequests,
		isLeader = alliance and alliance.Leader == player,
	})
end

local function refreshAllianceUI(player)
	refreshPlayerUI(player)

	local alliance = getAlliance(player)

	if alliance then
		for member in pairs(alliance.Members) do
			refreshPlayerUI(member)
		end
	end
end

--------------------------------------------------
-- CREATE ALLIANCE
--------------------------------------------------

local function createAlliance(leader)
	local allianceId = generateAllianceId()

	Alliances[allianceId] = {
		Leader = leader,
		Members = {
			[leader] = true,
		},
	}

	PlayerAlliance[leader] = allianceId

	TeamsModule.SetTeam(leader, allianceId)

	return allianceId
end

--------------------------------------------------
-- ADD MEMBER
--------------------------------------------------

local function addToAlliance(player, allianceId)
	local alliance = Alliances[allianceId]

	if not alliance then
		return
	end

	alliance.Members[player] = true
	PlayerAlliance[player] = allianceId

	TeamsModule.SetTeam(player, allianceId)

	syncAllianceTeams(allianceId)
end

--------------------------------------------------
-- REMOVE MEMBER
--------------------------------------------------

local function removeFromAlliance(target)
	local allianceId = PlayerAlliance[target]

	if not allianceId then
		return
	end

	local alliance = Alliances[allianceId]

	if not alliance then
		return
	end

	--------------------------------------------------
	-- Remove member
	--------------------------------------------------

	alliance.Members[target] = nil
	PlayerAlliance[target] = nil

	--------------------------------------------------
	-- Move player to solo team
	--------------------------------------------------

	setSoloTeam(target)

	--------------------------------------------------
	-- Leader promotion
	--------------------------------------------------

	if alliance.Leader == target then
		local newLeader

		for member in pairs(alliance.Members) do
			newLeader = member
			break
		end

		alliance.Leader = newLeader
	end

	--------------------------------------------------
	-- Delete empty alliance
	--------------------------------------------------

	local memberCount = 0

	for _ in pairs(alliance.Members) do
		memberCount += 1
	end

	if memberCount == 0 then
		Alliances[allianceId] = nil
		return
	end

	--------------------------------------------------
	-- Re-sync remaining alliance
	--------------------------------------------------

	syncAllianceTeams(allianceId)

	for member in pairs(alliance.Members) do
		refreshPlayerUI(member)
	end

	refreshPlayerUI(target)
end

--------------------------------------------------
-- INVITE PLAYER
--------------------------------------------------

inviteEvent.OnServerEvent:Connect(function(sender, target)
	if not sender or not target then
		return
	end

	if sender == target then
		return
	end

	-- Can't invite allied player
	if TeamsModule.AreTeammates(sender, target) then
		return
	end

	PendingInvites[target] = PendingInvites[target] or {}

	PendingInvites[target][sender.UserId] = true

	refreshPlayerUI(sender)
	refreshPlayerUI(target)
end)

--------------------------------------------------
-- ACCEPT INVITE
--------------------------------------------------

acceptEvent.OnServerEvent:Connect(function(receiver, inviter)
	if not inviter then
		return
	end

	if not PendingInvites[receiver] or not PendingInvites[receiver][inviter.UserId] then
		return
	end

	PendingInvites[receiver][inviter.UserId] = nil

	local inviterAllianceId = PlayerAlliance[inviter]

	-- inviter has no alliance
	if not inviterAllianceId then
		inviterAllianceId = createAlliance(inviter)
	end

	-- receiver already in alliance
	if PlayerAlliance[receiver] then
		removeFromAlliance(receiver)
	end

	addToAlliance(receiver, inviterAllianceId)

	refreshAllianceUI(inviter)
	refreshAllianceUI(receiver)
end)

--------------------------------------------------
-- REMOVE PLAYER
--------------------------------------------------

removeEvent.OnServerEvent:Connect(function(player, target)
	local alliance = getAlliance(player)

	if not alliance then
		return
	end

	--------------------------------------------------
	-- LEADER REMOVES PLAYER
	--------------------------------------------------

	if alliance.Leader == player then
		if target and target ~= player then
			removeFromAlliance(target)
		end

		return
	end

	--------------------------------------------------
	-- MEMBER LEAVES ALLIANCE
	--------------------------------------------------

	removeFromAlliance(player)
end)

--------------------------------------------------
-- MANUAL REFRESH
--------------------------------------------------

refreshEvent.OnServerEvent:Connect(function(player)
	refreshPlayerUI(player)
end)

--------------------------------------------------
-- CLEANUP
--------------------------------------------------

Players.PlayerRemoving:Connect(function(player)
	removeFromAlliance(player)

	PendingInvites[player] = nil
end)
