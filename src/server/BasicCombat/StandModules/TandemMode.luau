local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))
local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))
local CombatUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("CombatUtils"))

local TandemMode = {}

local tandemData = {}
local tandemConnections = {}

-- Tunables
local TANDEM_SPEED = 45
local CLOSE_DISTANCE = 10
local MAX_DISTANCE = 1500

local CameraEvent = replicatedStorage.Shared:WaitForChild("BasicCombat"):WaitForChild("PilotCameraEvent")
local RequestCameraDirection = replicatedStorage.Shared.BasicCombat:FindFirstChild("RequestCameraDirection")

---------------------------------------------------
-- ENTER TANDEM MODE
---------------------------------------------------
function TandemMode.EnterTandemMode(character, stand, followCamera, directionMethod, disableMovement)
	followCamera = followCamera or false -- ✅ default to false
	directionMethod = directionMethod or "Raycast" -- default
	disableMovement = disableMovement or false

	local canTandem = stand:FindFirstChild("CanTandemMode")
	if not canTandem then
		return
	end

	local standRoot = stand.PrimaryPart
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not standRoot or not hrp then
		return
	end

	-- Clear old data
	if tandemConnections[character] then
		tandemConnections[character]:Disconnect()
	end
	tandemConnections[character] = nil
	tandemData[character] = nil

	-- Find Motor6D
	local motor = standRoot:FindFirstChildWhichIsA("Motor6D", true)
	if not motor then
		return
	end

	-- Initial stand position
	stand:PivotTo(hrp.CFrame * CFrame.new(-2, 1, 3))

	-- Save state
	tandemData[character] = {
		stand = stand,
		standRoot = standRoot,
		standTag = stand:FindFirstChild("StandTag").Value,
		tandemMode = true,
		targetCF = standRoot.CFrame,
		disableMovement = disableMovement, -- ✅ store option
	}

	-- Detach stand
	motor.Part0 = stand:FindFirstChild("Collision")

	-- Disable collisions
	for _, part in ipairs(stand:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			if part.Name == "ProjectileSpawnPoint" then
				part.Anchored = true
			end
		end
		if part.Name == "Hurtbox" then
			part.CanTouch = false
			part.CanQuery = true
		end
	end

	-- Anchor ONLY the root
	standRoot.Anchored = true

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if disableMovement and humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end

	local player = Players:GetPlayerFromCharacter(character)
	local pilotCameraOrigin = stand:FindFirstChild("PilotCameraOrigin")

	-- ✅ Camera follow now optional
	if followCamera and player and pilotCameraOrigin then
		CameraEvent:FireClient(player, "follow", pilotCameraOrigin)
	end

	---------------------------------------------------
	-- Movement Loop
	---------------------------------------------------
	tandemConnections[character] = RunService.Heartbeat:Connect(function(dt)
		local data = tandemData[character]
		if not data or not data.tandemMode then
			return
		end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if data.disableMovement and humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end

		-- Safety reapply
		for _, part in ipairs(data.stand:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = true
			end
		end

		---------------------------------------------------
		-- Determine direction
		---------------------------------------------------

		local direction

		if directionMethod == "Screen" then
			-- Screen direction method
			local player = Players:GetPlayerFromCharacter(character)

			if player then
				local camDir = RequestCameraDirection:InvokeClient(player)

				if typeof(camDir) == "Vector3" then
					direction = camDir.Unit
				else
					direction = hrp:GetPivot().LookVector
				end
			else
				direction = hrp:GetPivot().LookVector
			end
		else
			-- Default: Raycast method
			local isClose = RaycastModule.CheckIfTargetIsClose(character, 10)

			if isClose then
				direction = hrp:GetPivot().LookVector
			else
				local targetPoint = RaycastModule.ReturnFacingPoint(character, 1500)
				if targetPoint then
					direction = (targetPoint - data.standRoot.Position).Unit
				else
					direction = hrp:GetPivot().LookVector
				end
			end
		end

		---------------------------------------------------
		-- Move targetCF
		---------------------------------------------------
		local speed = TANDEM_SPEED
		local moveDelta = direction * speed * dt

		data.targetCF = data.targetCF + moveDelta
		data.targetCF = CFrame.lookAt(data.targetCF.Position, data.targetCF.Position + direction)

		---------------------------------------------------
		-- Force position
		---------------------------------------------------
		data.stand:PivotTo(data.targetCF)
	end)
end

---------------------------------------------------
-- EXIT TANDEM MODE
---------------------------------------------------
function TandemMode.ExitTandemMode(character)
	if tandemConnections[character] then
		tandemConnections[character]:Disconnect()
		tandemConnections[character] = nil
	end

	local data = tandemData[character]
	if not data or not data.stand then
		tandemData[character] = nil
		return
	end

	-- Resummon stand cleanly
	StandUtils.RemoveStand(character)
	StandUtils.SummonStand(character, data.standTag)

	-- Restore movement if it was disabled
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and data.disableMovement then
		humanoid.WalkSpeed = CombatUtils.GetMoveSpeed(character)
		humanoid.JumpPower = CombatUtils.GetJumpHeight(character)
	end

	tandemData[character] = nil

	--restore cam
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		-- Tell client camera to follow stand
		CameraEvent:FireClient(player, "reset")
	end
end

return TandemMode
