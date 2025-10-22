-- ServerScriptService/BasicCombat/DashHandler.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local dashEvent = Instance.new("RemoteEvent")
dashEvent.Name = "DashEvent"
dashEvent.Parent = ReplicatedStorage.Shared.BasicCombat

local dashUpdateEvent = Instance.new("RemoteEvent")
dashUpdateEvent.Name = "DashUpdateEvent"
dashUpdateEvent.Parent = ReplicatedStorage.Shared.BasicCombat

local doubleJumpEvent = Instance.new("RemoteEvent") -- RemoteEvent
doubleJumpEvent.Name = "DoubleJumpEvent"
doubleJumpEvent.Parent = ReplicatedStorage.Shared.BasicCombat

local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))

local DashAnimations = {
	Forward = 116488788576301, -- replace with your Forward dash animation ID
	Backward = 71493580132157, -- replace with your Backward dash animation ID
	Left = 119476538755231, -- replace with your Left dash animation ID
	Right = 129728193718537, -- replace with your Right dash animation ID
}

-- Settings
local MAX_CHARGES = 3
local RECHARGE_TIME = 3 -- seconds per charge
local DASH_FORCE = 50
local DASH_DURATION = 0.5
local DASH_COOLDOWN = 0.75 -- new delay between dashes

local DOUBLE_JUMP_Y = 50 -- should match/approx client value
local DOUBLE_JUMP_DURATION = 0.1

-- Per-player dash state
local dashData = {}
local playerJumpData = {}

-- Initialize double jump state for a player
local function setupDoubleJump(player)
	playerJumpData[player] = {
		canDoubleJump = false,
	}
end

-- Helper to sync charges to client
local function updateClient(player)
	local data = dashData[player]
	if data then
		dashUpdateEvent:FireClient(player, data.charges)
	end
end

-- Recharge loop for each player
local function startRecharge(player)
	local data = dashData[player]
	if not data then
		return
	end

	-- already running?
	if data.recharging then
		return
	end
	data.recharging = true

	task.spawn(function()
		while data and data.charges < MAX_CHARGES do
			task.wait(RECHARGE_TIME)
			if not data then
				return
			end
			data.charges = math.min(MAX_CHARGES, data.charges + 1)
			updateClient(player)
		end
		if data then
			data.recharging = false
		end
	end)
end

local function onDashRequested(player, dirLabel)
	-- Validate player & character
	local character = player and player.Character
	if not character then
		return
	end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end
	if CombatUtils.GetStun(character) then
		return
	end
	if CombatUtils.GetIsBlocking(character).Value then
		return
	end

	local data = dashData[player]
	if not data then
		return
	end

	-- cooldown check
	local now = tick()
	if data.lastDashTime and (now - data.lastDashTime) < DASH_COOLDOWN then
		return -- too soon
	end

	-- Not enough charges
	if data.charges <= 0 then
		return
	end

	-- Validate dirLabel
	if typeof(dirLabel) ~= "string" then
		dirLabel = "Forward"
	end

	-- consume a charge and inform client
	data.charges = data.charges - 1
	data.lastDashTime = now -- record last dash time
	updateClient(player)

	-- Compute world-space dash direction
	local dashDir = Vector3.new(0, 0, 0)

	if dirLabel == "Forward" then
		dashDir = Vector3.new(0, 0, -1)
	elseif dirLabel == "Backward" then
		dashDir = Vector3.new(0, 0, 1)
	elseif dirLabel == "Left" then
		dashDir = Vector3.new(-1, 0, 0)
	elseif dirLabel == "Right" then
		dashDir = Vector3.new(1, 0, 0)
	else
		dashDir = Vector3.new(0, 0, -1)
	end

	CombatUtils.ApplyTurningVelocity(
		character,
		DASH_FORCE,
		DASH_DURATION,
		dashDir -- Local direction
	)

	AnimationModule.PlayAnimation(character, DashAnimations[dirLabel], false, 1, 1)
	SoundModule.PlaySound({
		Root = humanoidRootPart,
		soundName = "Dash",
		soundID = "6128977275",
		volume = 1.5,
		playbackSpeed = 1,
		looped = false,
		range = 100,
	})

	-- Start recharge if not full
	if data.charges < MAX_CHARGES then
		startRecharge(player)
	end
end

local function isAirborne(rootPart)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { rootPart.Parent }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local result = workspace:Raycast(rootPart.Position, Vector3.new(0, -4, 0), params)
	return result == nil
end

local function onDoubleJumpRequest(player)
	local character = player.Character
	if not character then
		return
	end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoidRootPart or not humanoid then
		return
	end

	if CombatUtils.GetStun(character) then
		return
	end

	if CombatUtils.GetIsBlocking(character).Value then
		return
	end

	-- quick airborne verification
	if not isAirborne(humanoidRootPart) then
		return
	end

	local dashInfo = dashData[player]
	if not dashInfo then
		return
	end

	-- Ensure they have a charge
	if dashInfo.charges <= 0 then
		-- you could also fire a reject RemoteEvent to tell client to cancel/rollback
		return
	end

	-- Consume 1 stamina/dash charge server-side and sync the UI
	dashInfo.charges -= 1
	updateClient(player)

	-- Authoritative re-apply: ensure server state matches client. Defer one frame to reduce Humanoid overwrite fights.
	task.defer(function()
		if humanoidRootPart and humanoidRootPart.Parent then
			CombatUtils.ApplyTimedVelocity(
				character,
				DOUBLE_JUMP_Y,
				DOUBLE_JUMP_DURATION,
				"DoubleJump",
				Vector3.new(0, 1, 0)
			)
		end
	end)

	AnimationModule.PlayAnimation(character, "121074387087243", false, 1, 1)

	SoundModule.PlaySound({
		Root = humanoidRootPart,
		soundName = "DoubleJump",
		soundID = "7043834737",
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 100,
	})

	print("Double jump on server")

	-- start recharge if needed
	if dashInfo.charges < MAX_CHARGES then
		startRecharge(player)
	end
end

-- Initialize when player joins
Players.PlayerAdded:Connect(function(player)
	dashData[player] = {
		charges = MAX_CHARGES,
		recharging = false,
		lastDashTime = 0,
	}
	setupDoubleJump(player)

	updateClient(player)

	player.CharacterAdded:Connect(function()
		updateClient(player) -- refresh UI on respawn
		setupDoubleJump(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	dashData[player] = nil
	playerJumpData[player] = nil
end)

-- Listen for dash requests
dashEvent.OnServerEvent:Connect(onDashRequested)
doubleJumpEvent.OnServerEvent:Connect(onDoubleJumpRequest)
