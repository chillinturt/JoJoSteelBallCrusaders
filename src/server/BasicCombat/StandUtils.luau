-- ServerScriptService > StandUtils
local StandUtils = {}

-- Track active stands for each entity
local activeStands = {}

-- ServerScriptService.BasicCombat.StandUtils
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CameraEvent = ReplicatedStorage.Shared:WaitForChild("BasicCombat"):WaitForChild("PilotCameraEvent")
local exitPilotEvent = ReplicatedStorage.Shared.BasicCombat:WaitForChild("ExitPilotMode")

local StandModels = ReplicatedStorage:WaitForChild("StandModels")
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local SoundUtils = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))

local IDLE_ANIM_ID = 89452205434139
local HURTBOX_SIZE = Vector3.new(4, 6, 4) -- Adjust size as needed

function StandUtils.getStandModel(character)
	if not character then
		return nil
	end

	-- Customize this logic depending on how you parent your stands
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Model") and child:FindFirstChild("StandTag") then
			print("Found a model: " .. child.Name)
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

--create stand hurtbox
local function CreateStandHurtbox(standModel)
	local standRoot = standModel.PrimaryPart
	if not standRoot then
		return
	end

	-- Check if a hitbox already exists
	if standModel:FindFirstChild("Hitbox") then
		return
	end

	-- Create the hitbox part
	local hurtbox = Instance.new("Part")
	hurtbox.Name = "Hurtbox"
	hurtbox.Size = HURTBOX_SIZE -- Adjust size as needed
	hurtbox.Transparency = 1 -- Visible for debugging, make it 1 for invisibility
	hurtbox.CanCollide = false
	hurtbox.Massless = true
	hurtbox.Anchored = false
	hurtbox.Color = Color3.fromRGB(0, 255, 0) -- Green for debugging
	hurtbox.Position = standRoot.CFrame.Position

	-- ✅ Match position AND rotation of the stand root
	hurtbox.CFrame = standRoot.CFrame

	-- Parent hitbox to stand model
	hurtbox.Parent = standModel

	-- Weld hitbox to stand root
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = standModel:FindFirstChild("LowerTorso")
	weld.Part1 = hurtbox
	weld.Parent = hurtbox
end

--[[ Summon a stand for an NPC or Player
function StandUtils.SummonStand(entity: Model, standTag: string)
	-- Check if a stand already exists
	if activeStands[entity] then
		warn(entity.Name .. " already has a stand!")
		return activeStands[entity]
	end

	local standTemplate = StandModels:FindFirstChild(standTag .. "Model")
	if not standTemplate then
		warn("⚠️ No stand model found for tag:", standTag)
		return nil
	end

	local humanoidRootPart = entity:WaitForChild("HumanoidRootPart") -- Replace if NPC uses a different part
	if not humanoidRootPart then
		warn("⚠️ No HumanoidRootPart found for entity:", entity.Name)
		return nil
	end

	-- Clone stand model
	local standModel = standTemplate:Clone()
	standModel.Parent = entity
	standModel.Name = standTag .. "Stand"

	standModel:SetPrimaryPartCFrame(humanoidRootPart.CFrame * CFrame.new(-2, 1, 3))

	-- Set StandTag StringValue
	local tag = Instance.new("StringValue")
	tag.Name = "StandTag"
	tag.Value = standTag
	tag.Parent = standModel

	-- Configure physics
	for _, part in pairs(standModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Massless = true
			part.Anchored = false
			part.CollisionGroup = "NoCollision"
		end
	end

	local rotation = CFrame.Angles(0, 0, 0)
	local offset = CFrame.new(-2, 1, 3)
	if tag.Value == "Nuclear Rain" then
		offset = CFrame.new(0, 1, 0)
		rotation = CFrame.Angles(0, math.rad(90), 0)
	end

	offset = offset * rotation -- multiply offset by rotation

	-- Weld to HumanoidRootPart
	local humanoidRoot = entity:FindFirstChild("HumanoidRootPart")
	if humanoidRoot and standModel.PrimaryPart then
		local weld = Instance.new("Motor6D")
		weld.Part0 = humanoidRoot
		weld.Part1 = standModel.PrimaryPart
		weld.Parent = standModel.PrimaryPart
		weld.Name = "StandMotor"
		weld.C0 = offset
	end

	activeStands[entity] = standModel

	CreateStandHurtbox(standModel)

	local StandSummonSounds = {
		["Star Purple"] = "5371606324",
		["Hierophant Grand"] = "6191514689",
		["King Carmine"] = "6995205240",
		["Gold Experiment"] = "4959222677",
		["Kaiser Queen"] = "2652080817",
		["Crazed Diamond"] = "6678129999",
		["That Hand"] = "98271580708859",
		["Nuclear Rain"] = "5978825194",
		["Heavy Door"] = "7280545782",
		["White Sake"] = "72453705794819",
		["Tusk Act 1"] = "5024213083",
		["Tusk Act 2"] = "5024213083",
		["Tusk Act 3"] = "5024213083",
		["Tusk Act 4"] = "5024213083",
	}
	local vol = 1

	if standTag == "King Carmine" then
		vol = 3
	elseif standTag == "Kaiser Queen" then
		print("has kaiser queen")
		vol = 3
	elseif standTag == "Hierophant Grand" then
		vol = 0.75
	end

	SoundUtils.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "Summon Sound",
		soundID = StandSummonSounds[standTag],
		volume = vol,
		playbackSpeed = 1,
		looped = false,
		range = 100,
	})

	AnimationModule.PlayAnimation(standModel, IDLE_ANIM_ID, true, Enum.AnimationPriority.Action)

	return standModel
end

-- Remove a stand
function StandUtils.RemoveStand(entity: Model, player)
	local existingStand = activeStands[entity]
	if existingStand then
		existingStand:Destroy()
		activeStands[entity] = nil

		if player then
			CameraEvent:FireClient(player, "reset")
			exitPilotEvent:Fire(player.Character)
		end
	else
		--warn(entity.Name .. " has no active stand to remove!")
	end
end
]]

-- Summon a stand for an NPC or Player
function StandUtils.SummonStand(entity: Model, standTag: string)
	-- Check if a stand already exists
	if activeStands[entity] then
		warn(entity.Name .. " already has a stand!")
		return activeStands[entity]
	end

	local standTemplate = StandModels:FindFirstChild(standTag .. "Model")
	if not standTemplate then
		warn("⚠️ No stand model found for tag:", standTag)
		return nil
	end

	local humanoidRootPart = entity:WaitForChild("HumanoidRootPart") -- Replace if NPC uses a different part
	if not humanoidRootPart then
		warn("⚠️ No HumanoidRootPart found for entity:", entity.Name)
		return nil
	end

	-- Clone stand model
	local standModel = standTemplate:Clone()
	standModel.Parent = entity
	standModel.Name = standTag .. "Stand"

	standModel:SetPrimaryPartCFrame(humanoidRootPart.CFrame * CFrame.new(-2, 1, 3))

	-- Set StandTag StringValue
	local tag = Instance.new("StringValue")
	tag.Name = "StandTag"
	tag.Value = standTag
	tag.Parent = standModel

	-- Configure physics
	for _, part in pairs(standModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Massless = true
			part.Anchored = false
			part.CollisionGroup = "NoCollision"
		end
	end

	-- After summoning the stand and setting up the StandTag:
	local player = Players:GetPlayerFromCharacter(entity)
	if player then
		print("player summoned stand...")
		if standTag == "TuskAct1" or standTag == "TuskAct2" or standTag == "TuskAct3" or standTag == "TuskAct4" then
			standTag = "Tusk"
		end
		local standFolder = game.ServerScriptService.BasicCombat.StandModules:FindFirstChild(standTag)

		if standFolder then
			print("stand folder found!")
			local registryModule = standFolder:FindFirstChild("AbilityRegistry")
			if registryModule then
				print("Found ability registry...")
				local registry = require(registryModule)
				if registry.AbilityTypes then
					print("found ability types in registry!")
					-- Fire the ability types to the client immediately
					local StandAbilityTypesRemote =
						game.ReplicatedStorage.Shared.BasicCombat:WaitForChild("StandAbilityTypes")
					StandAbilityTypesRemote:FireClient(player, registry.AbilityTypes)
					print("[StandUtils] Sent ability types to", player.Name, "for stand", standTag)
				end
			end
		end
	end

	local rotation = CFrame.Angles(0, 0, 0)
	local offset = CFrame.new(-2, 1, 3)
	if tag.Value == "NuclearRain" then
		offset = CFrame.new(0, 1, 0)
		rotation = CFrame.Angles(0, math.rad(90), 0)
	end

	offset = offset * rotation -- multiply offset by rotation

	-- Weld to HumanoidRootPart
	local humanoidRoot = entity:FindFirstChild("HumanoidRootPart")
	if humanoidRoot and standModel.PrimaryPart then --primart part is normally the stand's HRP
		local weld = Instance.new("Motor6D")
		weld.Part0 = humanoidRoot
		weld.Part1 = standModel.PrimaryPart
		weld.Parent = standModel.PrimaryPart
		weld.Name = "StandMotor"
		weld.C0 = offset
	end

	activeStands[entity] = standModel

	CreateStandHurtbox(standModel)

	local StandSummonSounds = {
		["StarPurple"] = "5371606324",
		["HierophantGrand"] = "6191514689",
		["KingCarmine"] = "6995205240",
		["GoldExperiment"] = "4959222677",
		["KaiserQueen"] = "2652080817",
		["CrazedDiamond"] = "6678129999",
		["ThatHand"] = "98271580708859",
		["NuclearRain"] = "5978825194",
		["HeavyDoor"] = "7280545782",
		["WhiteSake"] = "72453705794819",
		["TuskAct1"] = "5024213083",
		["TuskAct2"] = "5024213083",
		["TuskAct3"] = "5024213083",
		["TuskAct4"] = "5024213083",
		["Tusk"] = "5024213083",
		["MagiciansRed"] = "4732804275",
	}
	local vol = 1

	if standTag == "KingCarmine" then
		vol = 3
	elseif standTag == "KaiserQueen" then
		vol = 3
	elseif standTag == "HierophantGrand" then
		vol = 0.75
	end

	SoundUtils.PlaySound({
		Root = standModel.PrimaryPart,
		soundName = "Summon Sound",
		soundID = StandSummonSounds[standTag],
		volume = vol,
		playbackSpeed = 1,
		looped = false,
		range = 100,
	})

	AnimationModule.PlayAnimation(standModel, IDLE_ANIM_ID, true, Enum.AnimationPriority.Action)

	return standModel
end

-- Remove a stand
function StandUtils.RemoveStand(entity: Model, player)
	local existingStand = activeStands[entity]
	if existingStand then
		existingStand:Destroy()
		activeStands[entity] = nil

		if player then
			CameraEvent:FireClient(player, "reset")
			exitPilotEvent:Fire(player.Character)
		end
	else
		warn(entity.Name .. " has no active stand to remove!")
	end
end

-- Check if entity has a stand
function StandUtils.GetActiveStand(entity: Model)
	return activeStands[entity]
end

return StandUtils
