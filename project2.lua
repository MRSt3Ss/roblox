-- ESP Hack Simple for Roblox (Solara executor compatible)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SimpleESP"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 140)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = ScreenGui
mainFrame.Active = true
mainFrame.Draggable = true

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 30)
header.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
header.Parent = mainFrame

local headerLabel = Instance.new("TextLabel")
headerLabel.Size = UDim2.new(1, -60, 1, 0)
headerLabel.Position = UDim2.new(0, 10, 0, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.Text = "Simple ESP"
headerLabel.TextColor3 = Color3.new(1,1,1)
headerLabel.Font = Enum.Font.SourceSansBold
headerLabel.TextSize = 18
headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.Parent = header

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
minimizeBtn.Position = UDim2.new(1, -55, 0, 2)
minimizeBtn.Text = "-"
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 20
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = header

local exitBtn = Instance.new("TextButton")
exitBtn.Size = UDim2.new(0, 25, 0, 25)
exitBtn.Position = UDim2.new(1, -25, 0, 2)
exitBtn.Text = "X"
exitBtn.Font = Enum.Font.SourceSansBold
exitBtn.TextSize = 20
exitBtn.TextColor3 = Color3.new(1,1,1)
exitBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
exitBtn.BorderSizePixel = 0
exitBtn.Parent = header

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -30)
contentFrame.Position = UDim2.new(0, 0, 0, 30)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local espToggle = Instance.new("TextButton")
espToggle.Size = UDim2.new(0, 180, 0, 40)
espToggle.Position = UDim2.new(0, 20, 0, 20)
espToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
espToggle.TextColor3 = Color3.new(1,1,1)
espToggle.Font = Enum.Font.SourceSansBold
espToggle.TextSize = 18
espToggle.Text = "ESP: OFF"
espToggle.Parent = contentFrame

-- Variables
local espEnabled = false
local espBoxes = {}

-- Function to create esp box for a player
local function createEspBox(player)
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESPBox"
    box.Adornee = nil
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Transparency = 0.5
    box.Color3 = Color3.new(1, 0, 0) -- red color
    box.Size = Vector3.new(4, 6, 1)
    box.Parent = workspace.Terrain -- parent to terrain to avoid filtering issues
    
    espBoxes[player] = box
end

-- Remove esp box
local function removeEspBox(player)
    if espBoxes[player] then
        espBoxes[player]:Destroy()
        espBoxes[player] = nil
    end
end

-- Update esp boxes every frame
RunService.RenderStepped:Connect(function()
    if not espEnabled then return end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart
            if not espBoxes[player] then
                createEspBox(player)
            end
            espBoxes[player].Adornee = rootPart
        else
            removeEspBox(player)
        end
    end
end)

-- Toggle ESP button clicked
espToggle.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espToggle.Text = espEnabled and "ESP: ON" or "ESP: OFF"
    if not espEnabled then
        for player, box in pairs(espBoxes) do
            box:Destroy()
            espBoxes[player] = nil
        end
    end
end)

-- Minimize & Exit functionality
local minimized = false

minimizeBtn.MouseButton1Click:Connect(function()
    if minimized then
        mainFrame.Size = UDim2.new(0, 220, 0, 140)
        contentFrame.Visible = true
        minimized = false
        minimizeBtn.Text = "-"
    else
        mainFrame.Size = UDim2.new(0, 100, 0, 30)
        contentFrame.Visible = false
        minimized = true
        minimizeBtn.Text = "+"
    end
end)

exitBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)
