-- cp_advanced_fixed.lua by Bons - Fly optimal + Gendong fix + GUI minimalize & exit

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ControlPanelGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 150)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = ScreenGui
mainFrame.Active = true
mainFrame.Draggable = true

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 30)
header.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
header.Parent = mainFrame

local headerLabel = Instance.new("TextLabel")
headerLabel.Size = UDim2.new(1, -60, 1, 0)
headerLabel.Position = UDim2.new(0, 10, 0, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.Text = "Control Panel"
headerLabel.TextColor3 = Color3.new(1, 1, 1)
headerLabel.Font = Enum.Font.SourceSansBold
headerLabel.TextSize = 18
headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.Parent = header

-- Minimize button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
minimizeBtn.Position = UDim2.new(1, -55, 0, 2)
minimizeBtn.Text = "-"
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 20
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = header

-- Exit button
local exitBtn = Instance.new("TextButton")
exitBtn.Size = UDim2.new(0, 25, 0, 25)
exitBtn.Position = UDim2.new(1, -25, 0, 2)
exitBtn.Text = "X"
exitBtn.Font = Enum.Font.SourceSansBold
exitBtn.TextSize = 20
exitBtn.TextColor3 = Color3.new(1, 1, 1)
exitBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
exitBtn.BorderSizePixel = 0
exitBtn.Parent = header

-- Content Frame (untuk toggle & player list)
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -30)
contentFrame.Position = UDim2.new(0, 0, 0, 30)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Fly toggle button
local flyToggle = Instance.new("TextButton")
flyToggle.Size = UDim2.new(0, 180, 0, 35)
flyToggle.Position = UDim2.new(0, 20, 0, 10)
flyToggle.Text = "Fly: OFF"
flyToggle.Font = Enum.Font.SourceSansBold
flyToggle.TextSize = 18
flyToggle.TextColor3 = Color3.new(1, 1, 1)
flyToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
flyToggle.BorderSizePixel = 0
flyToggle.Parent = contentFrame

-- Gendong toggle button
local carryToggle = Instance.new("TextButton")
carryToggle.Size = UDim2.new(0, 180, 0, 35)
carryToggle.Position = UDim2.new(0, 20, 0, 55)
carryToggle.Text = "Gendong: OFF"
carryToggle.Font = Enum.Font.SourceSansBold
carryToggle.TextSize = 18
carryToggle.TextColor3 = Color3.new(1, 1, 1)
carryToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
carryToggle.BorderSizePixel = 0
carryToggle.Parent = contentFrame

-- Player List Label
local playerListLabel = Instance.new("TextLabel")
playerListLabel.Size = UDim2.new(0, 180, 0, 20)
playerListLabel.Position = UDim2.new(0, 20, 0, 100)
playerListLabel.Text = "Player terdekat:"
playerListLabel.Font = Enum.Font.SourceSansBold
playerListLabel.TextSize = 16
playerListLabel.TextColor3 = Color3.new(1, 1, 1)
playerListLabel.BackgroundTransparency = 1
playerListLabel.TextXAlignment = Enum.TextXAlignment.Left
playerListLabel.Parent = contentFrame

-- Player List Frame (Scroll)
local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Size = UDim2.new(0, 180, 0, 40)
playerListFrame.Position = UDim2.new(0, 20, 0, 120)
playerListFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
playerListFrame.BorderSizePixel = 0
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListFrame.ScrollBarThickness = 6
playerListFrame.Parent = contentFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = playerListFrame

-- Variables
local flyEnabled = false
local carryEnabled = false
local flySpeed = 80

local flyBodyVelocity
local flyBodyGyro

local carriedPlayer = nil
local weldToRoot

-- Functions

-- Fly Improved: gunakan BodyGyro + BodyVelocity untuk kontrol arah lebih smooth
local function enableFly()
    if flyEnabled then return end
    flyEnabled = true
    flyToggle.Text = "Fly: ON"

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.Parent = rootPart

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBodyGyro.CFrame = rootPart.CFrame
    flyBodyGyro.Parent = rootPart

    humanoid.PlatformStand = true

    RunService:BindToRenderStep("FlyControl", Enum.RenderPriority.Character.Value, function()
        if not flyEnabled then return end
        local moveVec = Vector3.new()

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVec = moveVec + workspace.CurrentCamera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVec = moveVec - workspace.CurrentCamera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVec = moveVec - workspace.CurrentCamera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVec = moveVec + workspace.CurrentCamera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVec = moveVec + Vector3.new(0,1,0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveVec = moveVec - Vector3.new(0,1,0)
        end

        if moveVec.Magnitude > 0 then
            flyBodyVelocity.Velocity = moveVec.Unit * flySpeed
            flyBodyGyro.CFrame = workspace.CurrentCamera.CFrame
        else
            flyBodyVelocity.Velocity = Vector3.new(0,0,0)
        end
    end)
end

local function disableFly()
    if not flyEnabled then return end
    flyEnabled = false
    flyToggle.Text = "Fly: OFF"

    humanoid.PlatformStand = false

    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
    if flyBodyGyro then
        flyBodyGyro:Destroy()
        flyBodyGyro = nil
    end

    RunService:UnbindFromRenderStep("FlyControl")
end

flyToggle.MouseButton1Click:Connect(function()
    if flyEnabled then
        disableFly()
    else
        enableFly()
    end
end)

-- Scan player terdekat dalam radius 20 stud
local function getClosestPlayers(radius)
    radius = radius or 20
    local playersNearby = {}

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (player.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
            if dist <= radius then
                table.insert(playersNearby, {player = player, distance = dist})
            end
        end
    end

    table.sort(playersNearby, function(a,b) return a.distance < b.distance end)
    return playersNearby
end

-- Carry player (gendong)
local function carryPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    local targetRoot = targetPlayer.Character.HumanoidRootPart

    -- Buat WeldConstraint ke rootPart kita
    weldToRoot = Instance.new("WeldConstraint")
    weldToRoot.Part0 = rootPart
    weldToRoot.Part1 = targetRoot
    weldToRoot.Parent = rootPart

    local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    if targetHumanoid then
        targetHumanoid.PlatformStand = true
    end

    carriedPlayer = targetPlayer
end

local function releasePlayer()
    if weldToRoot then
        weldToRoot:Destroy()
        weldToRoot = nil
    end

    if carriedPlayer and carriedPlayer.Character then
        local targetHumanoid = carriedPlayer.Character:FindFirstChild("Humanoid")
        if targetHumanoid then
            targetHumanoid.PlatformStand = false
        end
    end

    carriedPlayer = nil
end

-- Update player list UI dengan tombol klik untuk carry
local function createPlayerButton(player)
    local pBtn = Instance.new("TextButton")
    pBtn.Size = UDim2.new(1, 0, 0, 30)
    pBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    pBtn.TextColor3 = Color3.new(1,1,1)
    pBtn.Font = Enum.Font.SourceSansBold
    pBtn.TextSize = 16
    pBtn.Text = player.Name
    pBtn.Parent = playerListFrame

    pBtn.MouseButton1Click:Connect(function()
        if carryEnabled then
            releasePlayer()
        end
        carryToggle.Text = "Gendong: ON"
        carryEnabled = true
        carryPlayer(player)
    end)
end

local function updatePlayerList()
    for _, child in pairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local playersNearby = getClosestPlayers(20)
    for _, data in ipairs(playersNearby) do
        createPlayerButton(data.player)
    end

    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, #playersNearby * 35)
end

carryToggle.MouseButton1Click:Connect(function()
    if carryEnabled then
        -- matikan carry
        carryToggle.Text = "Gendong: OFF"
        carryEnabled = false
        releasePlayer()
    else
        updatePlayerList()
        local playersNearby = getClosestPlayers(20)
        if #playersNearby > 0 then
            carryToggle.Text = "Gendong: ON"
            carryEnabled = true
            carryPlayer(playersNearby[1].player)
        else
            carryToggle.Text = "Gendong: OFF"
            carryEnabled = false
            warn("Tidak ada player terdekat untuk digendong.")
        end
    end
end)

-- Minimize & Exit Functions
local minimized = false

minimizeBtn.MouseButton1Click:Connect(function()
    if minimized then
        -- restore
        mainFrame.Size = UDim2.new(0, 220, 0, 150)
        contentFrame.Visible = true
        minimized = false
        minimizeBtn.Text = "-"
    else
        -- minimize
        mainFrame.Size = UDim2.new(0, 100, 0, 30)
        contentFrame.Visible = false
        minimized = true
        minimizeBtn.Text = "+"
    end
end)

exitBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    disableFly()
    releasePlayer()
end)

-- Auto update player list tiap 2 detik supaya list player terdekat selalu up to date
spawn(function()
    while ScreenGui.Parent do
        updatePlayerList()
        wait(2)
    end
end)
