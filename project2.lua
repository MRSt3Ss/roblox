-- Fake VR Controller v2 (Smooth + GUI + Hands)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- GUI Setup
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
if PlayerGui:FindFirstChild("FakeVRGui") then
    PlayerGui.FakeVRGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "FakeVRGui"

local mainFrame = Instance.new("Frame", ScreenGui)
mainFrame.Size = UDim2.new(0,200,0,120)
mainFrame.Position = UDim2.new(0,20,0,20)
mainFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
mainFrame.Active = true
mainFrame.Draggable = true

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1,0,0,30)
title.BackgroundTransparency = 1
title.Text = "Fake VR Controller v2"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16

local toggleBtn = Instance.new("TextButton", mainFrame)
toggleBtn.Size = UDim2.new(0,180,0,40)
toggleBtn.Position = UDim2.new(0,10,0,50)
toggleBtn.Text = "Toggle Fake VR: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14

-- Hands
local function createHand(name,color)
    local hand = Instance.new("Part")
    hand.Name = name
    hand.Size = Vector3.new(0.4,0.4,0.4)
    hand.Shape = Enum.PartType.Ball
    hand.Anchored = true
    hand.CanCollide = false
    hand.Color = color
    hand.Material = Enum.Material.Neon
    hand.Parent = workspace
    return hand
end

local leftHand = createHand("LeftHand", Color3.fromRGB(0,0,255))
local rightHand = createHand("RightHand", Color3.fromRGB(255,0,0))

-- Control variables
local fakeVROn = false
local leftPos = Vector3.new(-1,1,-2)
local rightPos = Vector3.new(1,1,-2)
local speed = 0.15

toggleBtn.MouseButton1Click:Connect(function()
    fakeVROn = not fakeVROn
    toggleBtn.Text = fakeVROn and "Toggle Fake VR: ON" or "Toggle Fake VR: OFF"
    if not fakeVROn then
        leftHand.Position = Vector3.new(0,1000,0)
        rightHand.Position = Vector3.new(0,1000,0)
    end
end)

-- Smooth movement function
local function lerpVec(a,b,t)
    return a:Lerp(b,t)
end

-- Update loop
RunService.RenderStepped:Connect(function(delta)
    if not fakeVROn then return end

    local camPos = Camera.CFrame.Position
    local moveLeft = Vector3.new()
    local moveRight = Vector3.new()

    -- Arrow keys for left hand
    if UserInputService:IsKeyDown(Enum.KeyCode.Up) then moveLeft = moveLeft + Vector3.new(0,0,-speed) end
    if UserInputService:IsKeyDown(Enum.KeyCode.Down) then moveLeft = moveLeft + Vector3.new(0,0,speed) end
    if UserInputService:IsKeyDown(Enum.KeyCode.Left) then moveLeft = moveLeft + Vector3.new(-speed,0,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.Right) then moveLeft = moveLeft + Vector3.new(speed,0,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then moveLeft = moveLeft + Vector3.new(0,speed,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then moveLeft = moveLeft + Vector3.new(0,-speed,0) end

    -- WASD for right hand
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveRight = moveRight + Vector3.new(0,0,-speed) end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveRight = moveRight + Vector3.new(0,0,speed) end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveRight = moveRight + Vector3.new(-speed,0,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveRight = moveRight + Vector3.new(speed,0,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveRight = moveRight + Vector3.new(0,speed,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveRight = moveRight + Vector3.new(0,-speed,0) end

    -- Update target positions
    leftPos = leftPos + moveLeft
    rightPos = rightPos + moveRight

    -- Smooth lerp to position
    leftHand.Position = lerpVec(leftHand.Position, camPos + leftPos, 0.3)
    rightHand.Position = lerpVec(rightHand.Position, camPos + rightPos, 0.3)
end)
