-- ServerScriptService.DataSaving.ItemUse.StandArrow.lua
local InventoryManager = require(game.ServerScriptService.DataSaving.InventoryManager)
local HeroManager = require(game.ServerScriptService.DataSaving.HeroManager)
local StandUtils = require(game.ServerScriptService.BasicCombat.StandUtils)
local QuestManager = require(game.ServerScriptService.DataSaving.QuestManager)
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))
local AnimationModule = require(game.ServerScriptService.BasicCombat:WaitForChild("AnimationModule"))
local OceanService = require(game.ServerScriptService.OceanService:WaitForChild("OceanService"))

local StandArrow = {}
StandArrow.Cooldown = 3

local SpawnClientVfx = game.ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")

function StandArrow.Use(player)
	local inventory = InventoryManager.GetInventory(player)
	if not inventory then
		return false, "No profile data"
	end

	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local heroValue = HeroManager.GetField(player, "Hero")
	if heroValue ~= "None" and heroValue ~= "" then
		print("Player already has a stand!")
		return
	end

	-- find Stand Arrow
	local found = nil
	for _, entry in ipairs(inventory) do
		if entry.Name == "StandArrow" then
			found = entry
			break
		end
	end

	if not found or found.Amount <= 0 then
		return false, "No StandArrows!"
	end

	-- Remove ONE Stand Arrow
	InventoryManager.RemoveItem(player, "StandArrow", 1)

	local newHero = HeroManager.GetRandomStand()
	HeroManager.SetField(player, "Hero", newHero)

	local rightHand = char:FindFirstChild("RightHand")

	AnimationModule.PlayAnimation(char, 83818711540861, false, Enum.AnimationPriority.Action, 1)

	SpawnClientVfx:FireAllClients({
		type = "Attached",
		effectName = "StandArrowEffect",

		initialRotation = Vector3.new(
			0, -- X
			math.rad(90), -- Y
			math.rad(90) -- Z
		),

		offset = CFrame.new(0, -0.3, 0),
		scale = 1,
		attachTo = rightHand,
		lifetime = 3,
	})

	task.delay(1, function()
		SpawnClientVfx:FireAllClients({
			type = "Attached",
			effectName = "AwakenStand",

			offset = CFrame.new(0, 0, 0),
			scale = 1,
			transparency = 1,
			attachTo = hrp,
			lifetime = 3,
		})

		SoundModule.PlaySound({
			Root = hrp,
			soundName = "AwakenStandSlice",
			soundID = "	131696328850476",
			volume = 1,
			playbackSpeed = 1,
			looped = false,
		})

		SoundModule.PlaySound({
			Root = hrp,
			soundName = "AwakenStandSound",
			soundID = "7099913594",
			volume = 1,
			playbackSpeed = 1,
			looped = false,
		})
	end)

	task.delay(4, function()
		StandUtils.SummonStand(char, HeroManager.GetField(player, "Hero"))

		if OceanService:IsSwimming(char) then
			StandUtils.StartSwimmingCorrection(char)
		end

		-- complete the UseStandArrow tutorial quest if player has it
		if QuestManager.HasQuest(player, "UseStandArrowTutorial") then
			QuestManager.CompleteQuest(player, "UseStandArrowTutorial")
		end
	end)

	return true, newHero
end

return StandArrow
