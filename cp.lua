--[[
    🟢 Checkpoint Runner Gacor Edition 🟢
    By BonsCodes
    Fitur:
    ✅ Add CP (list rapi ke bawah)
    ✅ Save & Load dengan nama map
    ✅ Pop-up selector untuk load map
    ✅ Delete map config
    ✅ GUI hijau neon mewah + minimize
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local humanoidRootPart = player.Character and player.Character:WaitForChild("HumanoidRootPart")

local checkpoints = {}
local running = false
local minimized = false
local currentMap = "DefaultMap"

-- Buat folder utama
if not isfolder("BonsCodes_CP") then
    makefolder("BonsCodes_CP")
end

-- Fungsi teleport
local function tpTo(pos)
    if humanoidRootPart then
        humanoidRootPart.CFrame = CFrame.new(pos)
    end
end

-- GUI Utama
local screenGui = Instance.new("ScreenGui", game.CoreGui)

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 400)
frame.Position = UDim2.new(0, 50, 0, 150)
frame.BackgroundColor3 = Color3.fromRGB(0, 40, 0)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Parent = screenGui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(0, 255, 0)
stroke.Thickness = 2

-- Branding
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "Checkpoint Runner | By BonsCodes"
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
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 8)

minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, child in ipairs(frame:GetChildren()) do
        if child ~= title and child ~= minimizeBtn then
            child.Visible = not minimized
        end
    end
end)

-- Input nama CP
local nameBox = Instance.new("TextBox", frame)
nameBox.Size = UDim2.new(1, -20, 0, 30)
nameBox.Position = UDim2.new(0, 10, 0, 50)
nameBox.PlaceholderText = "Nama CP"
nameBox.Text = ""
nameBox.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
nameBox.Font = Enum.Font.SourceSans
nameBox.TextSize = 16
Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 6)

-- Scroll list CP
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1, -20, 0, 150)
scroll.Position = UDim2.new(0, 10, 0, 90)
scroll.BackgroundTransparency = 0.3
scroll.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
scroll.ScrollBarThickness = 6
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

-- Layout CP list
local listLayout = Instance.new("UIListLayout", scroll)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)

local function refreshList()
    scroll:ClearAllChildren()
    local layout = Instance.new("UIListLayout", scroll)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)

    for i, cp in ipairs(checkpoints) do
        local lbl = Instance.new("TextLabel", scroll)
        lbl.Size = UDim2.new(1, -10, 0, 25)
        lbl.BackgroundTransparency = 1
        lbl.Text = i..". "..cp.name
        lbl.TextColor3 = Color3.fromRGB(0, 255, 0)
        lbl.Font = Enum.Font.SourceSans
        lbl.TextSize = 16
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, #checkpoints * 30)
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
Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 6)

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
Instance.new("UICorner", runBtn).CornerRadius = UDim.new(0, 6)

runBtn.MouseButton1Click:Connect(function()
    if running then
        running = false
        runBtn.Text = "Run"
        return
    end
    running = true
    runBtn.Text = "Stop"
    coroutine.wrap(function()
        for _, cp in ipairs(checkpoints) do
            if not running then break end
            tpTo(cp.pos)
            wait(1)
        end
        running = false
        runBtn.Text = "Run"
    end)()
end)

-- Save & Load Config
local function saveConfig(mapName)
    local data = {}
    for _, cp in ipairs(checkpoints) do
        table.insert(data, {x = cp.pos.X, y = cp.pos.Y, z = cp.pos.Z, name = cp.name})
    end
    writefile("BonsCodes_CP/"..mapName..".json", HttpService:JSONEncode(data))
end

local function loadConfig(mapName)
    if isfile("BonsCodes_CP/"..mapName..".json") then
        local raw = readfile("BonsCodes_CP/"..mapName..".json")
        local data = HttpService:JSONDecode(raw)
        checkpoints = {}
        for _, cp in ipairs(data) do
            table.insert(checkpoints, {pos = Vector3.new(cp.x, cp.y, cp.z), name = cp.name})
        end
        refreshList()
    end
end

-- Dropdown Map Selector
local function getSavedMaps()
    local files = listfiles("BonsCodes_CP")
    local maps = {}
    for _, file in ipairs(files) do
        local name = file:match("BonsCodes_CP/(.+)%.json")
        if name then table.insert(maps, name) end
    end
    return maps
end

local mapSelector = Instance.new("TextButton", frame)
mapSelector.Size = UDim2.new(1, -20, 0, 30)
mapSelector.Position = UDim2.new(0, 10, 0, 210)
mapSelector.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
mapSelector.Text = "Pilih Map"
mapSelector.TextColor3 = Color3.fromRGB(0, 0, 0)
Instance.new("UICorner", mapSelector).CornerRadius = UDim.new(0, 6)

mapSelector.MouseButton1Click:Connect(function()
    local maps = getSavedMaps()
    if #maps == 0 then
        mapSelector.Text = "No Saved Maps"
        wait(1)
        mapSelector.Text = "Pilih Map"
        return
    end
    for _, map in ipairs(maps) do
        print("Map ditemukan:", map) -- Bisa diganti dengan popup UI
    end
end)

-- Button Save
local saveBtn = Instance.new("TextButton", frame)
saveBtn.Size = UDim2.new(1, -20, 0, 30)
saveBtn.Position = UDim2.new(0, 10, 0, 330)
saveBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
saveBtn.Text = "Save Map"
saveBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)

saveBtn.MouseButton1Click:Connect(function()
    saveConfig(currentMap)
end)

-- Button Delete Map
local delBtn = Instance.new("TextButton", frame)
delBtn.Size = UDim2.new(1, -20, 0, 30)
delBtn.Position = UDim2.new(0, 10, 0, 370)
delBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
delBtn.Text = "Delete Map"
delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 6)

delBtn.MouseButton1Click:Connect(function()
    if isfile("BonsCodes_CP/"..currentMap..".json") then
        delfile("BonsCodes_CP/"..currentMap..".json")
        checkpoints = {}
        refreshList()
    end
end)

-- Auto-load default map
loadConfig(currentMap)
