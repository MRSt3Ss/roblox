--// GUI Manual Versi Nyata | Pet & Plant Spawner //--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Ganti ini sesuai nama RemoteEvent di game lu
local spawnEvent = ReplicatedStorage:FindFirstChild("SpawnPetEvent") -- <== EDIT
local duplicateEvent = ReplicatedStorage:FindFirstChild("DuplicateItemEvent") -- <== EDIT

-- Buat ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PetPlantSpawnerGUI"
ScreenGui.Parent = game:GetService("CoreGui")

-- Frame Utama
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 300)
Frame.Position = UDim2.new(0.5, -150, 0.5, -150)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Parent = ScreenGui

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Title.Text = "Pet & Plant Spawner"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = Frame

-- Tombol Close
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Parent = Frame
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Dropdown Pet/Tanaman
local Dropdown = Instance.new("TextButton")
Dropdown.Size = UDim2.new(1, -20, 0, 30)
Dropdown.Position = UDim2.new(0, 10, 0, 40)
Dropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
Dropdown.Text = "Pilih Pet/Tanaman"
Dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
Dropdown.Parent = Frame

local pets = {"Raccoon", "CuteDog", "GoldenCat", "MagicTree", "Sunflower"}
local selectedPet = pets[1]
Dropdown.MouseButton1Click:Connect(function()
    local idx = table.find(pets, selectedPet) or 1
    idx = idx % #pets + 1
    selectedPet = pets[idx]
    Dropdown.Text = "Dipilih: " .. selectedPet
end)

-- Slider Jumlah Spawn
local spawnAmount = 1
local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(1, -20, 0, 20)
SliderLabel.Position = UDim2.new(0, 10, 0, 80)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "Jumlah Spawn: 1"
SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SliderLabel.Parent = Frame

-- Tombol Spawn
local SpawnBtn = Instance.new("TextButton")
SpawnBtn.Size = UDim2.new(1, -20, 0, 30)
SpawnBtn.Position = UDim2.new(0, 10, 0, 110)
SpawnBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
SpawnBtn.Text = "SPAWN Sekarang"
SpawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SpawnBtn.Parent = Frame

SpawnBtn.MouseButton1Click:Connect(function()
    if spawnEvent then
        for i = 1, spawnAmount do
            spawnEvent:FireServer(selectedPet) -- Ganti argumen sesuai game
        end
        print("[LIVE] Spawn:", selectedPet, "Sebanyak:", spawnAmount)
    else
        warn("Spawn Event tidak ditemukan!")
    end
end)

-- Tombol Duplicate
local DupBtn = Instance.new("TextButton")
DupBtn.Size = UDim2.new(1, -20, 0, 30)
DupBtn.Position = UDim2.new(0, 10, 0, 150)
DupBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 170)
DupBtn.Text = "DUPLICATE yang Ada"
DupBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DupBtn.Parent = Frame

DupBtn.MouseButton1Click:Connect(function()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then
        warn("Kamu harus memegang item untuk duplicate!")
        return
    end
    if duplicateEvent then
        duplicateEvent:FireServer(tool.Name) -- Ganti argumen sesuai game
        print("[LIVE] Duplicate item:", tool.Name)
    else
        warn("Duplicate Event tidak ditemukan!")
    end
end)
