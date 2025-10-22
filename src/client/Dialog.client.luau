local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventsFolder = ReplicatedStorage:WaitForChild("DialogEvents")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Grab/create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DialogGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.4, 0, 0.25, 0)
frame.Position = UDim2.new(0.3, 0, 0.7, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Visible = false
frame.Parent = screenGui

local dialogText = Instance.new("TextLabel")
dialogText.Size = UDim2.new(1, 0, 0.6, 0)
dialogText.BackgroundTransparency = 1
dialogText.TextColor3 = Color3.fromRGB(255, 255, 255)
dialogText.Font = Enum.Font.GothamBold
dialogText.TextScaled = true
dialogText.Text = ""
dialogText.Parent = frame

-- Buttons
local nextButton = Instance.new("TextButton")
nextButton.Size = UDim2.new(0.5, 0, 0.4, 0)
nextButton.Position = UDim2.new(0, 0, 0.6, 0)
nextButton.Text = "Next"
nextButton.Parent = frame

local endButton = Instance.new("TextButton")
endButton.Size = UDim2.new(0.5, 0, 0.4, 0)
endButton.Position = UDim2.new(0.5, 0, 0.6, 0)
endButton.Text = "End"
endButton.Parent = frame

local currentDialogLines = {} -- the active NPC's lines
local currentLine = 1

-- Dialog data
local JosephDialogLines = {
	"Hello there! I'm Joseph Joestar!",
	"So you want to learn about stands, eh?",
	"Heh... next, you'll say 'Of course I do!'",
}
local GiornoDialogLines = {
	"Hey there. I’ve been keeping an eye on the city… things are getting rough.",
	"There are dangerous thugs roaming the streets. You need to be careful.",
	"I can’t deal with them all myself. You should go speak to Jotaro… he knows what to do.",
	"Don’t take this lightly. The city can be unforgiving if you’re unprepared.",
	"Go find Jotaro and tell him I sent you. He’ll guide you from there.",
	"And take this ARROW with you. It will bring out your true potential!",
}
local JotaroDialogLines = {
	"So, Giorno sent you? Good… we’ve got a problem on our hands.",
	"These thugs you’ve seen aren’t your average street punks. They’re unusually well armed.",
	"I’ve been watching closely, and I suspect the RO Bank is supplying them… but I don’t have proof yet.",
	"If we’re going to confirm their involvement, I’ll need you to take action.",
	"Head over to the motor store. Take out 5 of those thugs and see if they’re carrying anything suspicious.",
	"Bring me the evidence. With it, I’ll finally be able to prove the bank’s connection to all this.",
}
local CrimeBossDialogLines = {
	"Tch… so you’re the one who’s been taking out my men. You don’t know what you’re getting yourself into.",
	"Yeah, that’s right… we’ve been working with the RO Bank. They pay us, we cause chaos. Simple deal.",
	"You think anyone in this city cares where the guns and cash come from? As long as the money flows, nobody asks questions.",
	"Hah… Jotaro was right to suspect us. But it’s too late now. The bank’s influence runs deeper than you can imagine.",
	"Go ahead, take what you want from our stash. It won’t matter. There’s always more money where that came from…",
	"But remember this — crossing the RO Bank is a death wish. You’ve just painted a target on your back.",
	"My men are POWERFUL STAND USERS! They will defeat you EASILY!",
}

-- Remote Event listener
local JosephDialogEvent = EventsFolder:WaitForChild("JosephDialogEvent")
local GiornoDialogEvent = EventsFolder:WaitForChild("GiornoDialogEvent")
local JotaroDialogEvent = EventsFolder:WaitForChild("JotaroDialogEvent")
local CrimeBossDialogEvent = EventsFolder:WaitForChild("CrimeBossDialogEvent")

-- Update RemoteEvent listeners to set the currentDialogLines
JosephDialogEvent.OnClientEvent:Connect(function()
	currentDialogLines = JosephDialogLines
	currentLine = 1
	dialogText.Text = currentDialogLines[currentLine]
	frame.Visible = true
end)

GiornoDialogEvent.OnClientEvent:Connect(function()
	currentDialogLines = GiornoDialogLines
	currentLine = 1
	dialogText.Text = currentDialogLines[currentLine]
	frame.Visible = true
end)

JotaroDialogEvent.OnClientEvent:Connect(function()
	currentDialogLines = JotaroDialogLines
	currentLine = 1
	dialogText.Text = currentDialogLines[currentLine]
	frame.Visible = true
end)

CrimeBossDialogEvent.OnClientEvent:Connect(function()
	currentDialogLines = CrimeBossDialogLines
	currentLine = 1
	dialogText.Text = currentDialogLines[currentLine]
	frame.Visible = true
end)

-- Update nextButton logic
nextButton.MouseButton1Click:Connect(function()
	if currentLine < #currentDialogLines then
		currentLine += 1
		dialogText.Text = currentDialogLines[currentLine]
	else
		frame.Visible = false -- end if no more lines
	end
end)

endButton.MouseButton1Click:Connect(function()
	frame.Visible = false
end)
