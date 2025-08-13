-- Fake VR FP Mode v6 - Tangan Toggle & First Person
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- Hapus GUI lama
if PlayerGui:FindFirstChild("FakeVRFPGUI") then
    PlayerGui.FakeVRFPGUI:Destroy()
end

-- Utils
local function create(class, props, parent)
    local obj = Instance.new(class)
    if props then for k,v in pairs(props) do obj[k]=v end end
    if parent then obj.Parent = parent end
    return obj
end

-- Main GUI
local sg = create("ScreenGui",{Parent=PlayerGui,Name="FakeVRFPGUI",ResetOnSpawn=false})
local main = create("Frame",{Size=UDim2.new(0,300,0,200),Position=UDim2.new(0.35,0,0.35,0),BackgroundColor3=Color3.fromRGB(40,40,40)},sg)
create("UICorner",{CornerRadius=UDim.new(0,10)},main)

-- Header
local header = create("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=Color3.fromRGB(70,70,70),Parent=main})
create("UICorner",{CornerRadius=UDim.new(0,10)},header)
create("TextLabel",{Text="Fake VR FP Mode",BackgroundTransparency=1,TextSize=16,TextColor3=Color3.fromRGB(255,200,150),Font=Enum.Font.GothamBold,Size=UDim2.new(1,0,1,0),Parent=header})
local btnClose = create("TextButton",{Text="X",Size=UDim2.new(0,30,0,30),Position=UDim2.new(1,-35,0,5),BackgroundColor3=Color3.fromRGB(200,50,50),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=16,Parent=header})
create("UICorner",{CornerRadius=UDim.new(0,5)},btnClose)
btnClose.MouseButton1Click:Connect(function() sg:Destroy() end)

-- Drag
do
    local dragging=false; local dragStart; local startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
        end
    end)
end

-- Body
local body = create("Frame",{Position=UDim2.new(0,0,0,40),Size=UDim2.new(1,0,1,-40),BackgroundTransparency=1,Parent=main})

-- Toggles
local leftToggle = create("TextButton",{Text="Left Hand: OFF",Size=UDim2.new(0,120,0,30),Position=UDim2.new(0,20,0,20),BackgroundColor3=Color3.fromRGB(80,80,80),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=14,Parent=body})
create("UICorner",{CornerRadius=UDim.new(0,5)},leftToggle)
local rightToggle = create("TextButton",{Text="Right Hand: OFF",Size=UDim2.new(0,120,0,30),Position=UDim2.new(0,160,0,20),BackgroundColor3=Color3.fromRGB(80,80,80),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=14,Parent=body})
create("UICorner",{CornerRadius=UDim.new(0,5)},rightToggle)

-- VR Hands
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local leftHand = character:WaitForChild("LeftHand")
local rightHand = character:WaitForChild("RightHand")

local hands = {Left=false,Right=false}

leftToggle.MouseButton1Click:Connect(function()
    hands.Left = not hands.Left
    leftToggle.Text = "Left Hand: "..(hands.Left and "ON" or "OFF")
    leftHand.Transparency = hands.Left and 0 or 1
end)
rightToggle.MouseButton1Click:Connect(function()
    hands.Right = not hands.Right
    rightToggle.Text = "Right Hand: "..(hands.Right and "ON" or "OFF")
    rightHand.Transparency = hands.Right and 0 or 1
end)

-- Activate First Person FOV
local camDefaultType = Camera.CameraType
local camDefaultCFrame = Camera.CFrame
local firstPersonOn = false

local btnFP = create("TextButton",{Text="Toggle First Person",Size=UDim2.new(0,260,0,30),Position=UDim2.new(0,20,0,70),BackgroundColor3=Color3.fromRGB(50,150,50),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=14,Parent=body})
create("UICorner",{CornerRadius=UDim.new(0,5)},btnFP)

btnFP.MouseButton1Click:Connect(function()
    firstPersonOn = not firstPersonOn
    if firstPersonOn then
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CFrame = character.Head.CFrame
    else
        Camera.CameraType = camDefaultType
        Camera.CFrame = camDefaultCFrame
    end
end)

-- Update hands positions
RunService.RenderStepped:Connect(function()
    if firstPersonOn then
        if hands.Left then leftHand.CFrame = Camera.CFrame * CFrame.new(-0.5,-0.5,-1) end
        if hands.Right then rightHand.CFrame = Camera.CFrame * CFrame.new(0.5,-0.5,-1) end
    end
end)
