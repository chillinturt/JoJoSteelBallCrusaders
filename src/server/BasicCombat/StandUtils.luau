-- ServerScriptService > StandUtils
local StandUtils = {}

-- Track active stands for each entity
local activeStands = {}
local vineConnections = {}

-- ServerScriptService.BasicCombat.StandUtils
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CameraEvent = ReplicatedStorage.Shared:WaitForChild("BasicCombat"):WaitForChild("PilotCameraEvent")
local exitPilotEvent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("ExitPilotMode")

local StandModels = ReplicatedStorage:WaitForChild("StandModels")
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local SoundUtils = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local QuestManager = require(game.ServerScriptService.DataSaving.QuestManager)
local HeroGroups = require(game.ServerScriptService.BasicCombat.StandModules.Handlers:WaitForChild("HeroGroups"))

local IDLE_ANIM_ID = 89452205434139
local DEFAULT_HURTBOX_SIZE = Vector3.new(3, 5, 3) -- Adjust size as needed

local standSwimConnections = {}

function StandUtils.getStandModel(character)
	if not character then
		return nil
	end

	-- Customize this logic depending on how you parent your stands
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Model") and child:FindFirstChild("StandTag") then
			return child
		end
	end

	return nil
end

function StandUtils.getStandTag(character)
	if not character then
		return nil
	end

	local standModel = StandUtils.getStandModel(character)
	if not standModel then
		return nil
	end

	-- Wait for the StandTag if it might not exist yet
	local tag = standModel:FindFirstChild("StandTag") or standModel:WaitForChild("StandTag", 2)
	return tag
end

local function AttachVineToArm(character, vineModel, armPart, rotationOffset)
	if not vineModel.PrimaryPart then
		warn("Vine model missing PrimaryPart")
		return
	end

	vineModel.Parent = character

	local motor = Instance.new("Motor6D")
	motor.Name = "VineMotor"
	motor.Part0 = armPart
	motor.Part1 = vineModel.PrimaryPart
	motor.Parent = armPart

	motor.C0 = CFrame.new(0, 0, 0) * rotationOffset

	local angle = 0

	local connection = RunService.Heartbeat:Connect(function(dt)
		-- Minimal safety check only (NOT your main cleanup)
		if not motor.Parent then
			return
		end

		angle += dt * 2
		local wobble = math.sin(time() * 4) * 0.2

		motor.C0 = CFrame.new(0, 0.2, 0) * CFrame.Angles(wobble, angle, 0) * rotationOffset
	end)

	-- ✅ Store connection per entity
	vineConnections[character] = vineConnections[character] or {}
	table.insert(vineConnections[character], connection)

	return motor
end

local function CreateStandHurtbox(standModel)
	local standRoot = standModel.PrimaryPart
	if not standRoot then
		return
	end

	-- Prevent duplicates
	if standModel:FindFirstChild("Hurtbox") then
		return
	end

	local character = standModel.Parent
	local standTag = StandUtils.getStandTag(character)
	local size = DEFAULT_HURTBOX_SIZE
	if standTag.Value == "HeavensDoor" then
		size = Vector3.new(1.5, 2.5, 1.5)
	end

	local hurtbox = Instance.new("Part")
	hurtbox.Name = "Hurtbox"
	hurtbox.Size = size
	hurtbox.Transparency = 1
	hurtbox.CanCollide = false
	hurtbox.Massless = true
	hurtbox.Anchored = false
	hurtbox.Color = Color3.fromRGB(0, 255, 0)

	hurtbox.Parent = standModel

	-- ✅ Use Motor6D instead of WeldConstraint
	local LowerTorso = standModel:FindFirstChild("LowerTorso")
	local joint = Instance.new("Motor6D")
	joint.Name = "HurtboxMotor"
	joint.Part0 = LowerTorso
	joint.Part1 = hurtbox
	joint.Parent = standRoot

	-- ✅ Keep it aligned with root (no offset)
	joint.C0 = CFrame.new()
end

local standAurasEvent = Instance.new("RemoteEvent")
standAurasEvent.Name = "StandAurasEvent"
standAurasEvent.Parent = ReplicatedStorage.Shared.Events

function StandUtils.SummonStand(entity: Model, standTag: string)
	-- Prevent duplicates
	if activeStands[entity] then
		warn(entity.Name .. " already has a stand!")
		return activeStands[entity]
	end

	local standTemplate = StandModels:FindFirstChild(standTag .. "Model")
	if not standTemplate then
		warn("⚠️ No stand model found for tag:", standTag)
		return nil
	end

	local humanoidRootPart = entity:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		warn("⚠️ No HumanoidRootPart found for entity:", entity.Name)
		return nil
	end

	local humanoid = entity:FindFirstChildOfClass("Humanoid")

	-- Prevent the SeatWeld from fighting the StandMotor when summoning.
	if humanoid and humanoid.SeatPart then
		humanoid.Sit = false
		task.wait(0.05)
	end

	local standModel
	local standRoot

	----------------------------------------------------------------
	-- 🌿 HERMIT PURPLE (SPECIAL CASE)
	----------------------------------------------------------------
	if standTag == "HermitPurple" then
		local leftArm = entity:FindFirstChild("LeftLowerArm") or entity:FindFirstChild("Left Arm")
		local rightArm = entity:FindFirstChild("RightLowerArm") or entity:FindFirstChild("Right Arm")

		if not leftArm or not rightArm then
			warn("Arms not found for Hermit Purple")
			return nil
		end

		-- Create container
		local container = Instance.new("Model")
		container.Name = "HermitPurpleStand"
		container.Parent = entity

		-- Clone vines
		local vine1 = standTemplate:Clone()
		local vine2 = standTemplate:Clone()

		vine1.Name = "HermitVineLeft"
		vine2.Name = "HermitVineRight"

		vine1.Parent = container
		vine2.Parent = container

		-- Attach vines
		AttachVineToArm(entity, vine1, leftArm, CFrame.Angles(0, 0, 0))
		AttachVineToArm(entity, vine2, rightArm, CFrame.Angles(0, math.rad(180), 0))

		-- Tag
		local tag = Instance.new("StringValue")
		tag.Name = "StandTag"
		tag.Value = standTag
		tag.Parent = container

		standModel = container

		-- Cleanup on death
		local humanoid = entity:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				if vineConnections[entity] then
					for _, conn in ipairs(vineConnections[entity]) do
						if conn.Connected then
							conn:Disconnect()
						end
					end
					vineConnections[entity] = nil
				end
			end)
		end
	else
		----------------------------------------------------------------
		-- 💥 NORMAL STANDS
		----------------------------------------------------------------
		standModel = standTemplate:Clone()
		standModel.Name = standTag .. "Stand"
		standModel.Parent = entity

		standRoot = standModel.PrimaryPart

		if standRoot then
			local weld = Instance.new("Motor6D")
			weld.Name = "StandMotor"
			weld.Part0 = humanoidRootPart
			weld.Part1 = standRoot
			weld.Parent = standRoot

			local offset = CFrame.new(-2, 1, 3)
			local rotation = CFrame.Angles(0, 0, 0)

			if standTag == "NuclearRain" then
				offset = CFrame.new(0, 1, 0)
				rotation = CFrame.Angles(0, math.rad(90), 0)
			elseif standTag == "Metallica" then
				offset = CFrame.new(0, 0, 0)
			end

			weld.C0 = offset * rotation
		end

		-- Tag
		local tag = Instance.new("StringValue")
		tag.Name = "StandTag"
		tag.Value = standTag
		tag.Parent = standModel

		-- Physics setup
		for _, part in ipairs(standModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Massless = true
				part.Anchored = false
				part.CollisionGroup = "NoCollision"
			end
		end
	end

	----------------------------------------------------------------
	-- 🔊 SHARED LOGIC (ALL STANDS)
	----------------------------------------------------------------
	activeStands[entity] = standModel

	local player = Players:GetPlayerFromCharacter(entity)

	if player then
		print("player summoned stand...")

		local StandSummonSounds = {
			["HermitPurple"] = "6148935445",
			["StarPurple"] = "5371606324",
			["HierophantGrand"] = "6191514689",
			["KingCarmine"] = "6995205240",
			["GoldExperiment"] = "4959222677",
			["KaiserQueen"] = "2652080817",
			["CrazedDiamond"] = "6678129999",
			["ThatHand"] = "98271580708859",
			["NuclearRain"] = "5978825194",
			["HeavensDoor"] = "7280545782",
			["WhiteSake"] = "72453705794819",
			["TuskAct4"] = "5024213083",
			["TuskAct1"] = "89805684001014",
			["TuskAct2"] = "89805684001014",
			["TuskAct3"] = "89805684001014",
			["MagiciansRed"] = "4732804275",
			["TheWorld"] = "4580055091",
			["Metallica"] = "101898166770177",
			["Cream"] = "7897536914",
			["StoneFree"] = "86796685861992",
			["StickyFingers"] = "6181672221",
		}

		local root = standModel.PrimaryPart or humanoidRootPart

		local standName = HeroGroups.GetHeroGroup(standTag)

		SoundUtils.PlaySound({
			Root = root,
			soundName = "Summon Sound",
			soundID = StandSummonSounds[standTag],
			volume = 1,
			playbackSpeed = 1,
			looped = false,
		})

		-- Normalize Tusk variants
		local lookupTag = standTag
		if lookupTag:find("TuskAct") then
			lookupTag = "Tusk"
		end

		local standFolder = game.ServerScriptService.BasicCombat.StandModules:FindFirstChild(lookupTag)
		if standFolder then
			local registryModule = standFolder:FindFirstChild("AbilityRegistry")
			if registryModule then
				local registry = require(registryModule)
				if registry.AbilityTypes then
					local remote = game.ReplicatedStorage.Shared.BasicCombat:WaitForChild("StandAbilityTypes")
					remote:FireClient(player, registry.AbilityTypes)
				end
			end
		end
	end

	----------------------------------------------------------------
	-- 🧱 FINAL SETUP
	----------------------------------------------------------------
	CreateStandHurtbox(standModel)

	if standModel.PrimaryPart then
		AnimationModule.PlayAnimation(standModel, IDLE_ANIM_ID, true, Enum.AnimationPriority.Movement)
	end

	standAurasEvent:FireAllClients(entity, standTag, true)

	if player and QuestManager.HasQuest(player, "SummonStandTutorial") then
		QuestManager.CompleteQuest(player, "SummonStandTutorial")
	end

	return standModel
end

-- Remove a stand
function StandUtils.RemoveStand(entity: Model, player)
	local existingStand = activeStands[entity]

	if not existingStand then
		warn(entity.Name .. " has no active stand to remove!")
		return
	end

	-- Get tag safely
	local tagObj = existingStand:FindFirstChild("StandTag")
	local standTag = tagObj and tagObj.Value

	-- Remove aura
	if standTag then
		standAurasEvent:FireAllClients(entity, standTag, false)
	end

	--------------------------------------------------
	-- ✅ HERMit PURPLE CLEANUP (CRITICAL)
	--------------------------------------------------
	if standTag == "HermitPurple" then
		-- 🔥 1. Destroy all vine motors on arms
		for _, part in ipairs(entity:GetDescendants()) do
			if part:IsA("Motor6D") and part.Name == "VineMotor" then
				part:Destroy()
			end
		end

		-- 🔥 2. Destroy any leftover vine models
		for _, child in ipairs(entity:GetChildren()) do
			if child:IsA("Model") and (child.Name == "HermitVineLeft" or child.Name == "HermitVineRight") then
				child:Destroy()
			end
		end
	end

	--------------------------------------------------
	-- ✅ CLEAN HEARTBEAT CONNECTIONS
	--------------------------------------------------
	if vineConnections[entity] then
		for _, conn in ipairs(vineConnections[entity]) do
			if conn and conn.Connected then
				conn:Disconnect()
			end
		end
		vineConnections[entity] = nil
	end

	if standSwimConnections[entity] then
		standSwimConnections[entity]:Disconnect()
		standSwimConnections[entity] = nil
	end

	--------------------------------------------------
	-- ✅ DESTROY MAIN STAND CONTAINER
	--------------------------------------------------
	StandUtils.StopSwimmingCorrection(entity)
	existingStand:Destroy()
	activeStands[entity] = nil

	--------------------------------------------------
	-- ✅ RESET PLAYER STATE
	--------------------------------------------------
	if player then
		CameraEvent:FireClient(player, "reset")
		exitPilotEvent:Fire(player.Character)
	end
end

-- Check if entity has a stand
function StandUtils.GetActiveStand(entity: Model)
	return activeStands[entity]
end

function StandUtils.StartSwimmingCorrection(character)
	local stand = activeStands[character]
	if not stand then
		return
	end

	local standRoot = stand.PrimaryPart
	local root = character:FindFirstChild("HumanoidRootPart")

	if not standRoot or not root then
		return
	end

	local motor = standRoot:FindFirstChild("StandMotor")
	if not motor then
		return
	end

	if standSwimConnections[character] then
		return
	end

	local originalC0 = motor.C0

	standSwimConnections[character] = RunService.Heartbeat:Connect(function()
		if activeStands[character] ~= stand then
			return
		end

		if not root.Parent then
			return
		end

		-- Keep the player's facing direction,
		-- but remove swimming pitch/roll
		local _, yaw, _ = root.CFrame:ToOrientation()

		local uprightRoot = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)

		-- Maintain the original stand offset
		local desiredStand = uprightRoot * originalC0

		-- Solve:
		-- root.CFrame * C0 * Transform = desiredStand
		motor.Transform = originalC0:Inverse() * root.CFrame:ToObjectSpace(desiredStand)
	end)
end

function StandUtils.StopSwimmingCorrection(character)
	local connection = standSwimConnections[character]

	if connection then
		connection:Disconnect()
		standSwimConnections[character] = nil
	end

	local stand = activeStands[character]

	if not stand then
		return
	end

	local root = stand.PrimaryPart

	if not root then
		return
	end

	local motor = root:FindFirstChild("StandMotor")

	if motor then
		motor.Transform = CFrame.identity
	end
end

return StandUtils
