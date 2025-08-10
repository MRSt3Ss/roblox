-- Pet Spawner & Duplicator (GUI Fix Version)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

-- Tunggu folder Pets di ReplicatedStorage
local PET_FOLDER
repeat
    PET_FOLDER = ReplicatedStorage:FindFirstChild("Pets")
    RunService.Heartbeat:Wait()
until PET_FOLDER and #PET_FOLDER:GetChildren() > 0

-- Buat ScreenGui aman (fallback ke PlayerGui)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetSpawner"
screenGui.ResetOnSpawn = false
pcall(function()
    screenGui.Parent = game:GetService("CoreGui")
end)
if not screenGui.Parent then
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

-- Frame utama
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 280, 0, 140)
main.Position = UDim2.new(0.5, -140, 0.4, -70)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
main.BorderSizePixel = 0
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

-- Title bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 24)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "Pet Spawner"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = main

-- Drag system
local dragging, dragStart, startPos
title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = i.Position
        startPos = main.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                  startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Dropdown pets
local dropdown = Instance.new("TextButton")
dropdown.Size = UDim2.new(1, -16, 0, 28)
dropdown.Position = UDim2.new(0, 8, 0, 36)
dropdown.Text = "Select Pet"
dropdown.Font = Enum.Font.Gotham
dropdown.TextSize = 16
dropdown.TextColor3 = Color3.new(1, 1, 1)
dropdown.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 6)
dropdown.Parent = main

local ddOpen = false
local petList = {}
for _, pet in ipairs(PET_FOLDER:GetChildren()) do
    table.insert(petList, pet.Name)
end

local listFrame = Instance.new("Frame")
listFrame.Size = UDim2.new(1, -16, 0, 0)
listFrame.Position = UDim2.new(0, 8, 0, 66)
listFrame.ClipsDescendants = true
listFrame.Parent = main
local listLayout = Instance.new("UIListLayout", listFrame)
listLayout.Padding = UDim.new(0, 2)

local selectedPet = nil
dropdown.MouseButton1Click:Connect(function()
    ddOpen = not ddOpen
    listFrame:TweenSize(UDim2.new(1, -16, 0, ddOpen and (#petList * 24) or 0), "Out", "Quad", 0.2, true)
end)

for _, name in ipairs(petList) do
    local line = Instance.new("TextButton")
    line.Size = UDim2.new(1, 0, 0, 24)
    line.Text = name
    line.Font = Enum.Font.Gotham
    line.TextSize = 14
    line.TextColor3 = Color3.new(1,1,1)
    line.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Instance.new("UICorner", line).CornerRadius = UDim.new(0, 4)
    line.Parent = listFrame
    line.MouseButton1Click:Connect(function()
        selectedPet = name
        dropdown.Text = name
        ddOpen = false
        listFrame:TweenSize(UDim2.new(1, -16, 0, 0), "Out", "Quad", 0.2, true)
    end)
end

-- Follow pet function
local function makePetFollow(petModel)
    local primary = petModel.PrimaryPart or petModel:FindFirstChildWhichIsA("BasePart")
    if not primary then return end

    local bp = Instance.new("BodyPosition", primary)
    bp.MaxForce = Vector3.new(1e4, 1e4, 1e4)
    bp.P = 3000

    local bg = Instance.new("BodyGyro", primary)
    bg.MaxTorque = Vector3.new(1e4, 1e4, 1e4)

    RunService.Heartbeat:Connect(function()
        if primary and primary.Parent then
            bp.Position = hrp.Position + Vector3.new(3, 1, 0)
            bg.CFrame = CFrame.new(primary.Position, hrp.Position)
        end
    end)
end

-- Spawn button
local spawnBtn = Instance.new("TextButton")
spawnBtn.Size = UDim2.new(0.48, -12, 0, 28)
spawnBtn.Position = UDim2.new(0, 8, 1, -36)
spawnBtn.Text = "Spawn"
spawnBtn.Font = Enum.Font.GothamBold
spawnBtn.TextSize = 16
spawnBtn.TextColor3 = Color3.new(1,1,1)
spawnBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
Instance.new("UICorner", spawnBtn).CornerRadius = UDim.new(0, 6)
spawnBtn.Parent = main

spawnBtn.MouseButton1Click:Connect(function()
    if not selectedPet then return end
    local template = PET_FOLDER:FindFirstChild(selectedPet)
    if template then
        local clone = template:Clone()
        clone.Parent = workspace
        if clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(3, 1, 0))
            makePetFollow(clone)
        end
    end
end)

-- Duplicate button
local dupBtn = Instance.new("TextButton")
dupBtn.Size = UDim2.new(0.48, -12, 0, 28)
dupBtn.Position = UDim2.new(0.52, 4, 1, -36)
dupBtn.Text = "Duplicate"
dupBtn.Font = Enum.Font.GothamBold
dupBtn.TextSize = 16
dupBtn.TextColor3 = Color3.new(1,1,1)
dupBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
Instance.new("UICorner", dupBtn).CornerRadius = UDim.new(0, 6)
dupBtn.Parent = main

dupBtn.MouseButton1Click:Connect(function()
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
        if clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(4, 1, 0))
            makePetFollow(clone)
        end
    end
end)
