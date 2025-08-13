-- Fake VR Controller v1
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- GUI Toggle
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "FakeVRGui"

local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0,120,0,40)
ToggleBtn.Position = UDim2.new(0,20,0,20)
ToggleBtn.Text = "Toggle Fake VR"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
ToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14

-- Tangan
local function createHand(name, color)
    local hand = Instance.new("Part")
    hand.Size = Vector3.new(0.4,0.4,0.4)
    hand.Shape = Enum.PartType.Ball
    hand.Color = color
    hand.Material = Enum.Material.Neon
    hand.Anchored = true
    hand.CanCollide = false
    hand.Name = name
    hand.Parent = workspace
    return hand
end

local leftHand = createHand("LeftHand", Color3.fromRGB(0,0,255))
local rightHand = createHand("RightHand", Color3.fromRGB(255,0,0))

-- Toggle ON/OFF
local fakeVROn = false
ToggleBtn.MouseButton1Click:Connect(function()
    fakeVROn = not fakeVROn
    ToggleBtn.Text = fakeVROn and "Fake VR: ON" or "Fake VR: OFF"
end)

-- Control Vars
local leftPos = Vector3.new(-1,1,-2)
local rightPos = Vector3.new(1,1,-2)

-- Update setiap frame
RunService.RenderStepped:Connect(function(delta)
    if not fakeVROn then return end

    local camCFrame = Camera.CFrame
    -- Head simulation
    Camera.CFrame = camCFrame * CFrame.new(0,0,0)

    -- Hand movement (WASD untuk kanan, Arrow keys untuk kiri)
    local moveLeft = Vector3.new(0,0,0)
    local moveRight = Vector3.new(0,0,0)
    if UserInputService:IsKeyDown(Enum.KeyCode.Up) then moveLeft = moveLeft + Vector3.new(0,0,-0.1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.Down) then moveLeft = moveLeft + Vector3.new(0,0,0.1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.Left) then moveLeft = moveLeft + Vector3.new(-0.1,0,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.Right) then moveLeft = moveLeft + Vector3.new(0.1,0,0) end

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveRight = moveRight + Vector3.new(0,0,-0.1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveRight = moveRight + Vector3.new(0,0,0.1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveRight = moveRight + Vector3.new(-0.1,0,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveRight = moveRight + Vector3.new(0.1,0,0) end

    leftPos = leftPos + moveLeft
    rightPos = rightPos + moveRight

    leftHand.Position = Camera.CFrame.Position + leftPos
    rightHand.Position = Camera.CFrame.Position + rightPos
end)
