--// Simple Checkpoint Runner with GUI (Green Glow)
--// by [YourName]

-- Table untuk checkpoint
local checkpoints = {}
local running = false
local player = game.Players.LocalPlayer
local humanoidRootPart = player.Character and player.Character:WaitForChild("HumanoidRootPart")

-- Fungsi teleport
local function tpTo(pos)
    if humanoidRootPart then
        humanoidRootPart.CFrame = CFrame.new(pos)
    end
end

-- Buat GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 250)
frame.Position = UDim2.new(0, 20, 0, 200)
frame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
frame.BorderSizePixel = 0
frame.BackgroundTransparency = 0.2
frame.Parent = screenGui

-- Glow effect
local uiStroke = Instance.new("UIStroke", frame)
uiStroke.Thickness = 2
uiStroke.Color = Color3.fromRGB(0, 255, 0)

local uiCorner = Instance.new("UICorner", frame)
uiCorner.CornerRadius = UDim.new(0, 10)

-- Template fungsi buat button
local function makeButton(text, posY, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.Parent = frame
    btn.MouseButton1Click:Connect(callback)
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 8)
end

-- Add Checkpoint
makeButton("Add CP", 20, function()
    local pos = humanoidRootPart.Position
    table.insert(checkpoints, pos)
    print("[Checkpoint Runner] Added CP #" .. #checkpoints)
end)

-- Run Checkpoints
makeButton("Run", 70, function()
    if running then
        running = false
        print("[Checkpoint Runner] Stopped.")
        return
    end
    running = true
    print("[Checkpoint Runner] Running through checkpoints...")
    coroutine.wrap(function()
        for i, cp in ipairs(checkpoints) do
            if not running then break end
            tpTo(cp)
            wait(1) -- delay antar CP
        end
        running = false
        print("[Checkpoint Runner] Finished.")
    end)()
end)

-- Save Config
makeButton("Save", 120, function()
    if writefile then
        local data = {}
        for _, pos in ipairs(checkpoints) do
            table.insert(data, {x = pos.X, y = pos.Y, z = pos.Z})
        end
        writefile("checkpoints.json", game:GetService("HttpService"):JSONEncode(data))
        print("[Checkpoint Runner] Saved to checkpoints.json")
    else
        print("[Checkpoint Runner] writefile not supported on this executor.")
    end
end)

-- Load Config (otomatis load kalau file ada)
if isfile and isfile("checkpoints.json") then
    local raw = readfile("checkpoints.json")
    local data = game:GetService("HttpService"):JSONDecode(raw)
    for _, pos in ipairs(data) do
        table.insert(checkpoints, Vector3.new(pos.x, pos.y, pos.z))
    end
    print("[Checkpoint Runner] Loaded", #checkpoints, "checkpoints from file.")
end
