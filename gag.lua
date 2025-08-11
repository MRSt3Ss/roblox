--// GUI Manual, 100% Muncul di PC Solara //--

-- Buat ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PetPlantSpawnerGUI"
ScreenGui.Parent = game:GetService("CoreGui")

-- Buat Frame
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 250)
Frame.Position = UDim2.new(0.5, -150, 0.5, -125)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Title.Text = "Pet & Plant Spawner | Simulasi"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = Frame

-- Dropdown (simulasi list pet/tanaman)
local Dropdown = Instance.new("TextButton")
Dropdown.Size = UDim2.new(1, -20, 0, 30)
Dropdown.Position = UDim2.new(0, 10, 0, 40)
Dropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
Dropdown.Text = "Pilih Pet/Tanaman"
Dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
Dropdown.Parent = Frame

-- Slider Label
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

-- Tombol Duplicate
local DupBtn = Instance.new("TextButton")
DupBtn.Size = UDim2.new(1, -20, 0, 30)
DupBtn.Position = UDim2.new(0, 10, 0, 150)
DupBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 170)
DupBtn.Text = "DUPLICATE yang Ada"
DupBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DupBtn.Parent = Frame

-- Tombol Kill All
local KillBtn = Instance.new("TextButton")
KillBtn.Size = UDim2.new(1, -20, 0, 30)
KillBtn.Position = UDim2.new(0, 10, 0, 190)
KillBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
KillBtn.Text = "KILL Semua Spawn"
KillBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KillBtn.Parent = Frame

-- Fungsi tombol (simulasi)
SpawnBtn.MouseButton1Click:Connect(function()
    print("[SIMULASI] Spawn dipanggil!")
end)
DupBtn.MouseButton1Click:Connect(function()
    print("[SIMULASI] Duplicate dipanggil!")
end)
KillBtn.MouseButton1Click:Connect(function()
    print("[SIMULASI] Kill All dipanggil!")
end)
