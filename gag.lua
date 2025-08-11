--// Pet & Item Spawner + Asset Scanner //--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- [CONFIG]
local spawnEventName = "SpawnPetEvent" -- Ganti kalau tahu nama eventnya
local duplicateEventName = "DuplicateItemEvent" -- Ganti kalau tahu nama eventnya

local spawnEvent = ReplicatedStorage:FindFirstChild(spawnEventName)
local duplicateEvent = ReplicatedStorage:FindFirstChild(duplicateEventName)

-- Data
local spawnList = {} -- Akan diisi otomatis
local scannedAssets = {} -- Hasil scan

-- Buat GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpawnerScannerGUI"
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 320, 0, 380)
Frame.Position = UDim2.new(0.5, -160, 0.5, -190)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Text = "Spawner & Asset Scanner"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = Frame

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

-- Scroll untuk list
local SpawnListFrame = Instance.new("ScrollingFrame")
SpawnListFrame.Size = UDim2.new(1, -20, 0, 150)
SpawnListFrame.Position = UDim2.new(0, 10, 0, 40)
SpawnListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
SpawnListFrame.ScrollBarThickness = 6
SpawnListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
SpawnListFrame.Parent = Frame

-- Button Scan Assets
local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(1, -20, 0, 30)
ScanBtn.Position = UDim2.new(0, 10, 0, 200)
ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 170)
ScanBtn.Text = "SCAN Assets"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Parent = Frame

-- Scroll hasil scan
local ScanListFrame = Instance.new("ScrollingFrame")
ScanListFrame.Size = UDim2.new(1, -20, 0, 100)
ScanListFrame.Position = UDim2.new(0, 10, 0, 240)
ScanListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScanListFrame.ScrollBarThickness = 6
ScanListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ScanListFrame.Parent = Frame

-- Fungsi untuk isi list spawn
local function updateSpawnList()
    SpawnListFrame:ClearAllChildren()
    local y = 0
    for _, name in ipairs(spawnList) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 25)
        btn.Position = UDim2.new(0, 2, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.Text = "Spawn: " .. name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = SpawnListFrame
        btn.MouseButton1Click:Connect(function()
            if spawnEvent then
                spawnEvent:FireServer(name)
                print("[LIVE] Spawn:", name)
            else
                warn("SpawnEvent tidak ditemukan!")
            end
        end)
        y = y + 28
    end
    SpawnListFrame.CanvasSize = UDim2.new(0, 0, 0, y)
end

-- Fungsi scan spawnable pets (misal dari ReplicatedStorage)
local function scanSpawnable()
    spawnList = {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            table.insert(spawnList, obj.Name)
        end
    end
    table.sort(spawnList)
    updateSpawnList()
end

-- Fungsi scan semua assets di Workspace
local function scanAssets()
    scannedAssets = {}
    ScanListFrame:ClearAllChildren()
    local y = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Tool") then
            table.insert(scannedAssets, obj)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -4, 0, 25)
            btn.Position = UDim2.new(0, 2, 0, y)
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btn.Text = "Clone: " .. obj.Name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Parent = ScanListFrame
            btn.MouseButton1Click:Connect(function()
                if duplicateEvent then
                    duplicateEvent:FireServer(obj.Name)
                    print("[LIVE] Duplicate asset:", obj.Name)
                else
                    warn("DuplicateEvent tidak ditemukan!")
                end
            end)
            y = y + 28
        end
    end
    ScanListFrame.CanvasSize = UDim2.new(0, 0, 0, y)
end

-- Saat klik scan
ScanBtn.MouseButton1Click:Connect(scanAssets)

-- Pertama kali load, langsung scan spawnable list
scanSpawnable()
