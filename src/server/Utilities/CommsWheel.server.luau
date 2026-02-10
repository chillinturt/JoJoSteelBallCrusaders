local Chat = game:GetService("Chat")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpawnClientVfx = ReplicatedStorage.Shared.Events:WaitForChild("SpawnVfx")
local SoundModule = require(game.ServerScriptService.Utilities:WaitForChild("SoundUtils"))

-- Whitelisted emoji definitions
local Emojis = {
	Happy = {
		head = "rbxassetid://78055771186770",
		face = "rbxassetid://1045016255",
		sound = "139727004722004",
	},
	Angry = {
		head = "rbxassetid://125929239739902",
		face = "rbxassetid://1045016322",
		sound = "107965930411767",
	},
	Laugh = {
		head = "rbxassetid://78055771186770",
		face = "rbxassetid://1872695902",
		sound = "7995127481",
	},
	Cry = {
		head = "rbxassetid://78055771186770",
		face = "rbxassetid://673659571",
		sound = "113637926299016",
	},
	Cat = {
		head = "rbxassetid://78055771186770",
		face = "rbxassetid://50445120",
		sound = "121872049322539",
	},
	Confused = {
		head = "rbxassetid://78055771186770",
		face = "rbxassetid://176441801",
		sound = "124024385219334",
	},
	Scared = {
		head = "rbxassetid://78055771186770",
		face = "rbxassetid://171384974",
		sound = "123941729714056",
	},
}

--[[
if the emoji has a sound, then play it using the sound module
	SoundModule.PlaySound({
		Root = root, -- hrp
		soundName = "Laugh/Angry/ etc",
		soundID = givenID,
		volume = 1,
		playbackSpeed = 1,
		looped = false,
		range = 160,
	})
]]

game.ReplicatedStorage.CWheelEvent.OnServerEvent:Connect(function(player, data)
	if typeof(data) ~= "table" then
		return
	end
	if not data.type or not data.value then
		return
	end

	local character = player.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	-- TEXT
	if data.type == "Text" then
		Chat:Chat(head, tostring(data.value), Enum.ChatColor.White)
		return
	end

	-- EMOJI
	if data.type == "Emoji" then
		print("Comms wheel emoji event fired")
		local emojiName = data.value
		local emoji = Emojis[emojiName]
		if not emoji then
			return
		end

		-- 🔊 Play emoji sound (if any)
		if emoji.sound then
			SoundModule.PlaySound({
				Root = root,
				soundName = emojiName,
				soundID = emoji.sound,
				volume = 1,
				playbackSpeed = 1,
				looped = false,
				range = 160,
			})
		end

		SpawnClientVfx:FireAllClients({
			type = "Emoji",
			character = character,
			headImage = emoji.head,
			faceImage = emoji.face,
			duration = 2.5,
		})
	end
end)
