-- cp_advanced_invisible.lua by Bons - Fly optimal + Invisible toggle + GUI minimalize & exit

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

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
mainFrame.Size = UDim2.new(0, 220, 0, 130)
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

-- Content Frame (untuk toggle)
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -30)
contentFrame.Position = UDim2.new(0, 0, 0, 30)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Fly toggle button
local flyToggle = Instance.new("TextButton")
flyToggle.Size = UDim2.new(0, 180, 0, 40)
flyToggle.Position = UDim2.new(0, 20, 0, 10)
flyToggle.Text = "Fly: OFF"
flyToggle.Font = Enum.Font.SourceSansBold
flyToggle.TextSize = 18
flyToggle.TextColor3 = Color3.new(1, 1, 1)
flyToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
flyToggle.BorderSizePixel = 0
flyToggle.Parent = contentFrame

-- Invisible toggle button
local invisibleToggle = Instance.new("TextButton")
invisibleToggle.Size = UDim2.new(0, 180, 0, 40)
invisibleToggle.Position = UDim2.new(0, 20, 0, 60)
invisibleToggle.Text = "Invisible: OFF"
invisibleToggle.Font = Enum.Font.SourceSansBold
invisibleToggle.TextSize = 18
invisibleToggle.TextColor3 = Color3.new(1, 1, 1)
invisibleToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
invisibleToggle.BorderSizePixel = 0
invisibleToggle.Parent = contentFrame

-- Variables
local flyEnabled = false
local invisibleEnabled = false
local flySpeed = 80

local flyBodyVelocity
local flyBodyGyro

-- Fly functions
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

-- Invisible functions
local function enableInvisible()
    invisibleEnabled = true
    invisibleToggle.Text = "Invisible: ON"
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = 1
            part.CanCollide = false
        elseif part:IsA("Decal") then
            part.Transparency = 1
        elseif part:IsA("ParticleEmitter") or part:IsA("Trail") then
            part.Enabled = false
        end
    end
end

local function disableInvisible()
    invisibleEnabled = false
    invisibleToggle.Text = "Invisible: OFF"
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = 0
            part.CanCollide = true
        elseif part:IsA("Decal") then
            part.Transparency = 0
        elseif part:IsA("ParticleEmitter") or part:IsA("Trail") then
            part.Enabled = true
        end
    end
end

invisibleToggle.MouseButton1Click:Connect(function()
    if invisibleEnabled then
        disableInvisible()
    else
        enableInvisible()
    end
end)

-- Minimize & Exit Functions
local minimized = false

minimizeBtn.MouseButton1Click:Connect(function()
    if minimized then
        mainFrame.Size = UDim2.new(0, 220, 0, 130)
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
    disableInvisible()
end)
