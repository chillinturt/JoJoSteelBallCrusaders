-- ServerScriptService/ForceBlockyAvatars.lua

local Players = game:GetService("Players")

-- Official R15 Blocky Rig IDs (Robloxian 1.0)
local BLOCKY_IDS = {
    Head = 86498066,
    Torso = 86498113,
    LeftArm = 86498126,
    RightArm = 86498143,
    LeftLeg = 86498152,
    RightLeg = 86498170,
}

local SCALE = 1 -- uniform size

local function applyBlockyDescription(humanoid)
    local desc = humanoid:GetAppliedDescription()

    -- Force blocky limbs
    desc.Head = BLOCKY_IDS.Head
    desc.Torso = BLOCKY_IDS.Torso
    desc.LeftArm = BLOCKY_IDS.LeftArm
    desc.RightArm = BLOCKY_IDS.RightArm
    desc.LeftLeg = BLOCKY_IDS.LeftLeg
    desc.RightLeg = BLOCKY_IDS.RightLeg

    -- Uniform scaling
    desc.HeightScale = SCALE
    desc.WidthScale = SCALE
    desc.DepthScale = SCALE
    desc.HeadScale = SCALE
    desc.BodyTypeScale = 0           -- blocky
    desc.ProportionScale = 0         -- blocky proportions

    humanoid:ApplyDescription(desc)
end

local function onCharacterAdded(char)
    local humanoid = char:WaitForChild("Humanoid")

    -- Force blocky avatar once fully spawned
    task.defer(function()
        applyBlockyDescription(humanoid)
    end)

    -- Only reapply if accessories/layers change
    char.ChildAdded:Connect(function(child)
        if child:IsA("Accessory") or child:IsA("Shirt") or child:IsA("Pants") then
            task.defer(function()
                applyBlockyDescription(humanoid)
            end)
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(onCharacterAdded)
end)
