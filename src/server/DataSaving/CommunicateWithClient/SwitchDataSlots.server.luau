local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerData = require(ServerScriptService.DataSaving.PlayerData)
local SlotManager = require(ServerScriptService.DataSaving.SlotManager)

local EventsFolder = ReplicatedStorage.Shared:WaitForChild("Events")

---------------------------------------------------------
-- RemoteEvent: Switch Slot
---------------------------------------------------------
local slotSwitchEvent = Instance.new("RemoteEvent")
slotSwitchEvent.Name = "SwitchSlot"
slotSwitchEvent.Parent = EventsFolder

slotSwitchEvent.OnServerEvent:Connect(function(player, slotName)
	-- Validate input
	if typeof(slotName) ~= "string" or slotName == "" then
		return
	end

	local success, err = PlayerData.SafeSwitchSlot(player, slotName)
	if not success then
		warn(("Slot switch failed for %s → %s (%s)"):format(player.Name, slotName, err))
	end
end)

---------------------------------------------------------
-- RemoteFunction: Check Slot Access
---------------------------------------------------------
local CheckSlotAccess = Instance.new("RemoteFunction")
CheckSlotAccess.Name = "CheckSlotAccess"
CheckSlotAccess.Parent = EventsFolder

CheckSlotAccess.OnServerInvoke = function(player, slotName)
	if typeof(slotName) ~= "string" then
		return false
	end

	return SlotManager.PlayerHasAccess(player, slotName)
end
