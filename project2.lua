-- Full Carry System Roblox (Fly client + Carry server-client sync)
-- Author: Bons (for you, boss)
-- Fitur:
-- 1. Fly client-side optimal
-- 2. Carry (gendong) player lain secara global (server handle weld)
-- 3. GUI fly & carry + scan player terdekat
-- 4. Minimize & exit GUI

-- ==== SERVER SCRIPT ====
-- Pasang script ini di ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Buat RemoteEvent jika belum ada
local CarryEvent = ReplicatedStorage:FindFirstChild("CarryEvent")
if not CarryEvent then
    CarryEvent = Instance.new("RemoteEvent")
    CarryEvent.Name = "CarryEvent"
    CarryEvent.Parent = ReplicatedStorage
end

local ReleaseEvent = ReplicatedStorage:FindFirstChild("ReleaseCarryEvent")
if not ReleaseEvent then
    ReleaseEvent = Instance.new("RemoteEvent")
    ReleaseEvent.Name = "ReleaseCarryEvent"
    ReleaseEvent.Parent = ReplicatedStorage
end

-- Simpan weld yang sedang aktif per player (key = player yang carry)
local activeWelds = {}

-- Fungsi untuk bersihkan weld lama kalo ada
local function releaseCarry(player)
    if activeWelds[player] then
        activeWelds[player]:Destroy()
        activeWelds[player] = nil
    end
end

CarryEvent.OnServerEvent:Connect(function(player, targetPlayer)
    -- Validasi target
    if not targetPlayer or not targetPlayer.Character or not player.Character then return end
    local root1 = player.Character:FindFirstChild("HumanoidRootPart")
    local root2 = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root1 or not root2 then return end

    -- Release dulu weld sebelumnya kalo ada
    releaseCarry(player)

    -- Buat weld baru
    local weld = Instance.new("WeldConstraint")
    weld.Name = "CarryWeld"
    weld.Part0 = root1
    weld.Part1 = root2
    weld.Parent = root1

    activeWelds[player] = weld

    -- Set PlatformStand supaya target gak bisa jalan sendiri
    local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    if targetHumanoid then
        targetHumanoid.PlatformStand = true
    end
end)

ReleaseEvent.OnServerEvent:Connect(function(player)
    releaseCarry(player)
    -- Lepas PlatformStand target juga
    -- Cari siapa yang sedang digendong player ini
    local weld = activeWelds[player]
    if weld and weld.Part1 then
        local targetHumanoid = weld.Part1.Parent:FindFirstChild("Humanoid")
        if targetHumanoid then
            targetHumanoid.PlatformStand = false
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    -- Bersihkan weld kalau player keluar
    releaseCarry(player)
end)


-- ==== CLIENT SCRIPT ====
-- Pasang LocalScript di StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local CarryEvent = ReplicatedStorage:WaitForChild("CarryEvent")
local ReleaseEvent = ReplicatedStorage:WaitForChild("ReleaseCarryEvent")

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ControlPanelGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 150)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = ScreenGui
mainFrame.Active = true
mainFrame.Draggable = true

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

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -30)
contentFrame.Position = UDim2.new(0, 0, 0, 30)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

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

local flyEnabled = false
local carryEnabled = false
local flySpeed = 80

local flyBodyVelocity
local flyBodyGyro

local carriedPlayer = nil

-- Fly Functions
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

-- Scan player terdekat
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

local function carryPlayer(targetPlayer)
    if not targetPlayer then return end
    CarryEvent:FireServer(targetPlayer)
    carriedPlayer = targetPlayer
end

local function releasePlayer()
    if carriedPlayer then
        ReleaseEvent:FireServer()
        carriedPlayer = nil
    end
end

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

local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    if minimized then
        mainFrame.Size = UDim2.new(0, 220, 0, 150)
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
    disableFly()
    releasePlayer()
end)

spawn(function()
    while ScreenGui.Parent do
        updatePlayerList()
        wait(2)
    end
end)
