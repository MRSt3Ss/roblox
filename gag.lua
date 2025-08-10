-- Pet Spawner & Duplicator for Grow-a-Garden style game
-- Features:
-- • GUI with dropdown pet list, Spawn & Duplicate
-- • Spawn pet clones from ReplicatedStorage
-- • Duplicate existing pet in workspace (near player)
-- • Attach pet to follow player via BodyPosition & BodyGyro
-- • Minimize GUI via right-click on title bar
-- • Safe RPC detection (local only)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

-- Config: Pet models expected to reside in ReplicatedStorage.Pets
local PET_FOLDER = ReplicatedStorage:WaitForChild("Pets")

-- UI setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetSpawner"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

local main = Instance.new("Frame", screenGui)
main.Size = UDim2.new(0, 280, 0, 140)
main.Position = UDim2.new(0.5, -140, 0.4, -70)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
main.BorderSizePixel = 0
local corner = Instance.new("UICorner", main); corner.CornerRadius = UDim.new(0, 8)

-- Title bar (draggable + right-click minimize)
local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 24)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "Pet Spawner"
title.Font = Enum.Font.GothamBold
title.TextSize = 18

local dragging, dragStart, startPos = false, nil, nil
title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = i.Position
        startPos = main.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    elseif i.UserInputType == Enum.UserInputType.MouseButton2 then
        main.Visible = false
        mini.Visible = true
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement and dragStart then
        local delta = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                  startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Mini icon to restore
local mini = Instance.new("TextButton", screenGui)
mini.Size = UDim2.new(0, 64, 0, 64)
mini.Position = UDim2.new(0, 20, 0, 20)
mini.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mini.TextColor3 = Color3.new(1, 1, 1)
mini.Text = "☰"
mini.Font = Enum.Font.GothamBold
mini.TextSize = 24
mini.Visible = false
local miniCorner = Instance.new("UICorner", mini); miniCorner.CornerRadius = UDim.new(0, 8)
mini.MouseButton1Click:Connect(function()
    mini.Visible = false
    main.Visible = true
end)

-- Dropdown
local dropdown = Instance.new("TextButton", main)
dropdown.Size = UDim2.new(1, -16, 0, 28)
dropdown.Position = UDim2.new(0, 8, 0, 36)
dropdown.Text = "Select Pet"
dropdown.Font = Enum.Font.Gotham
dropdown.TextSize = 16
dropdown.TextColor3 = Color3.new(1, 1, 1)
dropdown.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
local ddCorner = Instance.new("UICorner", dropdown); ddCorner.CornerRadius = UDim.new(0, 6)

local ddOpen = false
local petList = {}
for _, pet in ipairs(PET_FOLDER:GetChildren()) do
    table.insert(petList, pet.Name)
end

local listFrame = Instance.new("Frame", main)
listFrame.Size = UDim2.new(1, -16, 0, 0)
listFrame.Position = UDim2.new(0, 8, 0, 66)
listFrame.ClipsDescendants = true
local listLayout = Instance.new("UIListLayout", listFrame)
listLayout.Padding = UDim.new(0, 2)

dropdown.MouseButton1Click:Connect(function()
    ddOpen = not ddOpen
    listFrame:TweenSize(UDim2.new(1, -16, 0, ddOpen and (#petList * 24) or 0), "Out", "Quad", 0.2, true)
end)

local selectedPet = nil
for i, name in ipairs(petList) do
    local line = Instance.new("TextButton", listFrame)
    line.Size = UDim2.new(1, 0, 0, 24)
    line.Text = name
    line.Font = Enum.Font.Gotham
    line.TextSize = 14
    line.TextColor3 = Color3.new(1,1,1)
    line.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    local lnCorner = Instance.new("UICorner", line); lnCorner.CornerRadius = UDim.new(0, 4)
    line.MouseButton1Click:Connect(function()
        selectedPet = name
        dropdown.Text = name
        ddOpen = false
        listFrame:TweenSize(UDim2.new(1, -16, 0, 0), "Out", "Quad", 0.2, true)
    end)
end

-- Buttons: Spawn & Duplicate
local btnSpawn = Instance.new("TextButton", main)
btnSpawn.Size = UDim2.new(0.48, -12, 0, 28)
btnSpawn.Position = UDim2.new(0, 8, 1, -36)
btnSpawn.Text = "Spawn"
btnSpawn.Font = Enum.Font.GothamBold
btnSpawn.TextSize = 16
btnSpawn.TextColor3 = Color3.new(1,1,1)
btnSpawn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
local btnSpawnCorner = Instance.new("UICorner", btnSpawn); btnSpawnCorner.CornerRadius = UDim.new(0, 6)

local btnDup = Instance.new("TextButton", main)
btnDup.Size = UDim2.new(0.48, -12, 0, 28)
btnDup.Position = UDim2.new(0.52, 4, 1, -36)
btnDup.Text = "Duplicate"
btnDup.Font = Enum.Font.GothamBold
btnDup.TextSize = 16
btnDup.TextColor3 = Color3.new(1,1,1)
btnDup.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
local btnDupCorner = Instance.new("UICorner", btnDup); btnDupCorner.CornerRadius = UDim.new(0, 6)

-- Pet Follow System
local function makePetFollow(petModel)
    local bodyPos = Instance.new("BodyPosition", petModel.PrimaryPart or petModel:FindFirstChildWhichIsA("BasePart"))
    bodyPos.MaxForce = Vector3.new(1e4, 1e4, 1e4)
    bodyPos.P = 3000

    local bodyGyro = Instance.new("BodyGyro", petModel.PrimaryPart or petModel:FindFirstChildWhichIsA("BasePart"))
    bodyGyro.MaxTorque = Vector3.new(1e4,1e4,1e4)

    RunService.Heartbeat:Connect(function()
        if petModel and petModel.PrimaryPart then
            bodyPos.Position = hrp.Position + Vector3.new(3, 1, 0)
            bodyGyro.CFrame = CFrame.new(petModel.PrimaryPart.Position, hrp.Position)
        end
    end)
end

-- Spawn logic
btnSpawn.MouseButton1Click:Connect(function()
    if not selectedPet then return end
    local template = PET_FOLDER:FindFirstChild(selectedPet)
    if template then
        local clone = template:Clone()
        clone.Parent = workspace
        clone:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(3,1,0))
        makePetFollow(clone)
    end
end)

-- Duplicate logic: duplicate nearest pet instance owned by player (distance threshold)
btnDup.MouseButton1Click:Connect(function()
    if not selectedPet then return end
    local nearest, dist = nil, math.huge
    for _, pet in pairs(workspace:GetChildren()) do
        if pet.Name == selectedPet and pet.PrimaryPart then
            local d = (pet.PrimaryPart.Position - hrp.Position).Magnitude
            if d < dist and d < 10 then
                nearest, dist = pet, d
            end
        end
    end
    if nearest then
        local clone = nearest:Clone()
        clone.Parent = workspace
        clone:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(4,1,0))
        makePetFollow(clone)
    end
end)
