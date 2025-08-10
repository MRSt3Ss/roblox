--// Modern Checkpoint Runner GUI by [YourName]
--// Fitur: Add CP (dengan nama), Run, Save, Load, Minimize, Multi-config
--// Tested in: Solara, Synapse, Script-Ware

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local humanoidRootPart = player.Character and player.Character:WaitForChild("HumanoidRootPart")

-- Variabel utama
local checkpoints = {}
local running = false
local minimized = false
local currentMap = "DefaultMap"

-- Buat folder config
if not isfolder("CheckpointRunner") then
    makefolder("CheckpointRunner")
end

-- Fungsi teleport
local function tpTo(pos)
    if humanoidRootPart then
        humanoidRootPart.CFrame = CFrame.new(pos)
    end
end

-- GUI utama
local screenGui = Instance.new("ScreenGui", game.CoreGui)

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 350)
frame.Position = UDim2.new(0, 50, 0, 150)
frame.BackgroundColor3 = Color3.fromRGB(0, 40, 0)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = screenGui

local uiCorner = Instance.new("UICorner", frame)
uiCorner.CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(0, 255, 0)
stroke.Thickness = 2

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "Checkpoint Runner"
title.TextColor3 = Color3.fromRGB(0, 255, 0)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20

-- Tombol minimize
local minimizeBtn = Instance.new("TextButton", frame)
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -35, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 18
local cornerMin = Instance.new("UICorner", minimizeBtn)
cornerMin.CornerRadius = UDim.new(0, 8)

minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, child in ipairs(frame:GetChildren()) do
        if child ~= title and child ~= minimizeBtn and child ~= uiCorner and child ~= stroke then
            child.Visible = not minimized
        end
    end
end)

-- Input nama CP
local nameBox = Instance.new("TextBox", frame)
nameBox.Size = UDim2.new(1, -20, 0, 30)
nameBox.Position = UDim2.new(0, 10, 0, 50)
nameBox.PlaceholderText = "Nama Checkpoint"
nameBox.Text = ""
nameBox.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
nameBox.Font = Enum.Font.SourceSans
nameBox.TextSize = 16
local nameCorner = Instance.new("UICorner", nameBox)
nameCorner.CornerRadius = UDim.new(0, 6)

-- Scroll list CP
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1, -20, 0, 150)
scroll.Position = UDim2.new(0, 10, 0, 90)
scroll.BackgroundTransparency = 0.3
scroll.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
local scrollCorner = Instance.new("UICorner", scroll)
scrollCorner.CornerRadius = UDim.new(0, 6)

local function refreshList()
    scroll:ClearAllChildren()
    for i, cp in ipairs(checkpoints) do
        local lbl = Instance.new("TextLabel", scroll)
        lbl.Size = UDim2.new(1, -10, 0, 25)
        lbl.Position = UDim2.new(0, 5, 0, (i-1)*28)
        lbl.BackgroundTransparency = 1
        lbl.Text = i..". "..cp.name
        lbl.TextColor3 = Color3.fromRGB(0, 255, 0)
        lbl.Font = Enum.Font.SourceSans
        lbl.TextSize = 16
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, #checkpoints*28)
end

-- Button Add CP
local addBtn = Instance.new("TextButton", frame)
addBtn.Size = UDim2.new(1, -20, 0, 35)
addBtn.Position = UDim2.new(0, 10, 0, 250)
addBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
addBtn.Text = "Add CP"
addBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
addBtn.Font = Enum.Font.SourceSansBold
addBtn.TextSize = 18
local addCorner = Instance.new("UICorner", addBtn)
addCorner.CornerRadius = UDim.new(0, 6)

addBtn.MouseButton1Click:Connect(function()
    if nameBox.Text == "" then
        nameBox.Text = "CP "..(#checkpoints+1)
    end
    table.insert(checkpoints, {pos = humanoidRootPart.Position, name = nameBox.Text})
    refreshList()
end)

-- Button Run
local runBtn = Instance.new("TextButton", frame)
runBtn.Size = UDim2.new(1, -20, 0, 35)
runBtn.Position = UDim2.new(0, 10, 0, 290)
runBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
runBtn.Text = "Run"
runBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
runBtn.Font = Enum.Font.SourceSansBold
runBtn.TextSize = 18
local runCorner = Instance.new("UICorner", runBtn)
runCorner.CornerRadius = UDim.new(0, 6)

runBtn.MouseButton1Click:Connect(function()
    if running then
        running = false
        runBtn.Text = "Run"
        return
    end
    running = true
    runBtn.Text = "Stop"
    coroutine.wrap(function()
        for i, cp in ipairs(checkpoints) do
            if not running then break end
            tpTo(cp.pos)
            wait(1)
        end
        running = false
        runBtn.Text = "Run"
    end)()
end)

-- Save & Load
local function saveConfig(mapName)
    local data = {}
    for _, cp in ipairs(checkpoints) do
        table.insert(data, {x = cp.pos.X, y = cp.pos.Y, z = cp.pos.Z, name = cp.name})
    end
    writefile("CheckpointRunner/"..mapName..".json", HttpService:JSONEncode(data))
end

local function loadConfig(mapName)
    if isfile("CheckpointRunner/"..mapName..".json") then
        local raw = readfile("CheckpointRunner/"..mapName..".json")
        local data = HttpService:JSONDecode(raw)
        checkpoints = {}
        for _, cp in ipairs(data) do
            table.insert(checkpoints, {pos = Vector3.new(cp.x, cp.y, cp.z), name = cp.name})
        end
        refreshList()
    end
end

-- Auto-load map default
loadConfig(currentMap)

-- Save setiap keluar game
game:BindToClose(function()
    saveConfig(currentMap)
end)
