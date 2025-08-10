-- Pet Spawner & Duplicator | Custom GUI
-- 100% manual GUI tanpa library eksternal

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart") or player.CharacterAdded:Wait():WaitForChild("HumanoidRootPart")

-- Pastikan folder pets ada
local PET_FOLDER
repeat
    PET_FOLDER = ReplicatedStorage:FindFirstChild("Pets")
    RunService.Heartbeat:Wait()
until PET_FOLDER and #PET_FOLDER:GetChildren() > 0

-- Ambil daftar pets
local petList = {}
for _, pet in ipairs(PET_FOLDER:GetChildren()) do
    table.insert(petList, pet.Name)
end

local selectedPet = petList[1]

-- Fungsi buat pet follow
local function makePetFollow(petModel)
    local primary = petModel.PrimaryPart or petModel:FindFirstChildWhichIsA("BasePart")
    if not primary then return end

    local bp = Instance.new("BodyPosition", primary)
    bp.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bp.P = 5000

    local bg = Instance.new("BodyGyro", primary)
    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)

    RunService.Heartbeat:Connect(function()
        if primary and primary.Parent then
            bp.Position = hrp.Position + Vector3.new(3, 1, 0)
            bg.CFrame = CFrame.new(primary.Position, hrp.Position)
        end
    end)
end

-- Fungsi spawn
local function spawnPet(name)
    local template = PET_FOLDER:FindFirstChild(name)
    if template then
        local clone = template:Clone()
        clone.Parent = workspace
        if clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(3, 1, 0))
            makePetFollow(clone)
        end
    end
end

-- Fungsi duplicate
local function duplicatePet(name)
    local nearest, dist = nil, math.huge
    for _, pet in pairs(workspace:GetChildren()) do
        if pet.Name == name and pet.PrimaryPart then
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
end

-- ===== GUI BUATAN SENDIRI =====
local gui = Instance.new("ScreenGui")
gui.Name = "PetSpawnerGUI"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 180)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -90)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
title.Text = "Pet Spawner & Duplicator"
title.TextColor3 = Color3.new(1, 1, 1)
title.Parent = mainFrame

-- Dropdown pet
local dropdown = Instance.new("TextButton")
dropdown.Size = UDim2.new(1, -20, 0, 30)
dropdown.Position = UDim2.new(0, 10, 0, 40)
dropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
dropdown.TextColor3 = Color3.new(1, 1, 1)
dropdown.Text = "Selected Pet: " .. selectedPet
dropdown.Parent = mainFrame

dropdown.MouseButton1Click:Connect(function()
    selectedPet = petList[(table.find(petList, selectedPet) % #petList) + 1]
    dropdown.Text = "Selected Pet: " .. selectedPet
end)

-- Tombol spawn
local spawnBtn = Instance.new("TextButton")
spawnBtn.Size = UDim2.new(0.5, -15, 0, 30)
spawnBtn.Position = UDim2.new(0, 10, 0, 80)
spawnBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
spawnBtn.Text = "Spawn"
spawnBtn.TextColor3 = Color3.new(1, 1, 1)
spawnBtn.Parent = mainFrame
spawnBtn.MouseButton1Click:Connect(function()
    spawnPet(selectedPet)
end)

-- Tombol duplicate
local dupeBtn = Instance.new("TextButton")
dupeBtn.Size = UDim2.new(0.5, -15, 0, 30)
dupeBtn.Position = UDim2.new(0.5, 5, 0, 80)
dupeBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
dupeBtn.Text = "Duplicate"
dupeBtn.TextColor3 = Color3.new(1, 1, 1)
dupeBtn.Parent = mainFrame
dupeBtn.MouseButton1Click:Connect(function()
    duplicatePet(selectedPet)
end)
