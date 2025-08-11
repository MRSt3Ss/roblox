--// Full Spawn & Duplicate Tool dengan Scan RemoteEvent //--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Data
local remoteEvents = {}
local selectedSpawnEvent
local selectedDuplicateEvent
local spawnList = {}
local scannedAssets = {}

-- GUI Utama
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpawnerScannerGUI"
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 360, 0, 420)
Frame.Position = UDim2.new(0.5, -180, 0.5, -210)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Text = "Pet & Item Spawner + Remote Scanner"
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

-- Fungsi buat bikin button list
local function makeList(parent, listData, callback)
    parent:ClearAllChildren()
    local y = 0
    for _, v in ipairs(listData) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 25)
        btn.Position = UDim2.new(0, 2, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.Text = tostring(v)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = parent
        btn.MouseButton1Click:Connect(function()
            callback(v)
        end)
        y += 28
    end
    parent.CanvasSize = UDim2.new(0, 0, 0, y)
end

-- Scroll List RemoteEvent
local RemoteFrame = Instance.new("ScrollingFrame")
RemoteFrame.Size = UDim2.new(1, -20, 0, 100)
RemoteFrame.Position = UDim2.new(0, 10, 0, 40)
RemoteFrame.ScrollBarThickness = 6
RemoteFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
RemoteFrame.Parent = Frame

-- Tombol scan RemoteEvent
local ScanRemoteBtn = Instance.new("TextButton")
ScanRemoteBtn.Size = UDim2.new(1, -20, 0, 25)
ScanRemoteBtn.Position = UDim2.new(0, 10, 0, 150)
ScanRemoteBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 170)
ScanRemoteBtn.Text = "SCAN RemoteEvent"
ScanRemoteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanRemoteBtn.Parent = Frame

ScanRemoteBtn.MouseButton1Click:Connect(function()
    remoteEvents = {}
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            table.insert(remoteEvents, obj:GetFullName())
        end
    end
    table.sort(remoteEvents)
    makeList(RemoteFrame, remoteEvents, function(v)
        if not selectedSpawnEvent then
            selectedSpawnEvent = game:GetService("Workspace"):FindFirstChild(v) or game:GetService("ReplicatedStorage"):FindFirstChild(v) or game:GetService("Players"):FindFirstChild(v) or game:GetService("CoreGui"):FindFirstChild(v) or game:GetService("StarterGui"):FindFirstChild(v) or game:GetService("Lighting"):FindFirstChild(v)
        end
        print("Selected Remote:", v)
    end)
end)

-- Scroll list spawnable
local SpawnListFrame = Instance.new("ScrollingFrame")
SpawnListFrame.Size = UDim2.new(1, -20, 0, 100)
SpawnListFrame.Position = UDim2.new(0, 10, 0, 185)
SpawnListFrame.ScrollBarThickness = 6
SpawnListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
SpawnListFrame.Parent = Frame

-- Scan spawnable objects
local function scanSpawnable()
    spawnList = {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            table.insert(spawnList, obj.Name)
        end
    end
    table.sort(spawnList)
    makeList(SpawnListFrame, spawnList, function(name)
        if selectedSpawnEvent then
            selectedSpawnEvent:FireServer(name)
            print("[LIVE] Spawn:", name)
        else
            warn("SpawnEvent belum dipilih!")
        end
    end)
end
scanSpawnable()

-- Button Scan Assets
local ScanAssetsBtn = Instance.new("TextButton")
ScanAssetsBtn.Size = UDim2.new(1, -20, 0, 25)
ScanAssetsBtn.Position = UDim2.new(0, 10, 0, 290)
ScanAssetsBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
ScanAssetsBtn.Text = "SCAN Assets"
ScanAssetsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanAssetsBtn.Parent = Frame

-- Scroll hasil scan asset
local ScanListFrame = Instance.new("ScrollingFrame")
ScanListFrame.Size = UDim2.new(1, -20, 0, 100)
ScanListFrame.Position = UDim2.new(0, 10, 0, 320)
ScanListFrame.ScrollBarThickness = 6
ScanListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ScanListFrame.Parent = Frame

-- Scan semua assets di workspace
ScanAssetsBtn.MouseButton1Click:Connect(function()
    scannedAssets = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Tool") then
            table.insert(scannedAssets, obj)
        end
    end
    makeList(ScanListFrame, scannedAssets, function(obj)
        if selectedDuplicateEvent then
            selectedDuplicateEvent:FireServer(obj.Name)
            print("[LIVE] Duplicate via event:", obj.Name)
        else
            local clone = obj:Clone()
            clone.Parent = LocalPlayer.Backpack
            print("[LIVE] Duplicate direct to Backpack:", obj.Name)
        end
    end)
end)
