local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local RaycastModule = require(game.ServerScriptService.BasicCombat:WaitForChild("RaycastModule"))
local StandUtils = require(game.ServerScriptService.BasicCombat:WaitForChild("StandUtils"))

local TandemMode = {}

local tandemData = {}
local tandemConnections = {}

-- Tunables
local TANDEM_SPEED = 45
local CLOSE_DISTANCE = 10
local MAX_DISTANCE = 1500

---------------------------------------------------
-- ENTER TANDEM MODE
---------------------------------------------------
function TandemMode.EnterTandemMode(character, stand)
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
		targetCF = standRoot.CFrame, -- IMPORTANT
	}

	-- Detach stand
	motor.Part0 = stand:FindFirstChild("Collision")

	-- Server owns physics
	standRoot:SetNetworkOwner(nil)

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

		-- Safety reapply (same as PilotMode)
		for _, part in ipairs(data.stand:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = true
			end
		end

		---------------------------------------------------
		-- Determine direction (your raycast logic)
		---------------------------------------------------
		local direction
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

		---------------------------------------------------
		-- Move targetCF (NOT physics!)
		---------------------------------------------------
		local speed = TANDEM_SPEED
		local moveDelta = direction * speed * dt

		data.targetCF = data.targetCF + moveDelta

		-- Face movement direction
		data.targetCF = CFrame.lookAt(data.targetCF.Position, data.targetCF.Position + direction)

		---------------------------------------------------
		-- FORCE POSITION (gravity-proof)
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

	tandemData[character] = nil
end

return TandemMode
