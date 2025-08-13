-- Fake VR v3 Controller for PC
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Hapus GUI lama
if PlayerGui:FindFirstChild("FakeVRGUI") then
    PlayerGui.FakeVRGUI:Destroy()
end

-- Utils
local function create(class, props, parent)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do obj[k] = v end
    end
    if parent then obj.Parent = parent end
    return obj
end

-- Main GUI
local sg = create("ScreenGui",{Parent=PlayerGui,Name="FakeVRGUI",ResetOnSpawn=false})
local main = create("Frame",{Size=UDim2.new(0,300,0,180),Position=UDim2.new(0.35,0,0.3,0),BackgroundColor3=Color3.fromRGB(30,30,30)},sg)
create("UICorner",{CornerRadius=UDim.new(0,10)},main)

-- Header
local header = create("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=Color3.fromRGB(60,60,60),Parent=main},main)
create("UICorner",{CornerRadius=UDim.new(0,10)},header)
create("TextLabel",{Text="Fake VR Controller v3",BackgroundTransparency=1,TextSize=16,TextColor3=Color3.fromRGB(255,200,150),Font=Enum.Font.GothamBold,Size=UDim2.new(1,0,1,0),Parent=header})

local btnClose = create("TextButton",{Text="X",Size=UDim2.new(0,30,0,30),Position=UDim2.new(1,-35,0,5),BackgroundColor3=Color3.fromRGB(200,50,50),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=16,Parent=header})
create("UICorner",{CornerRadius=UDim.new(0,5)},btnClose)
btnClose.MouseButton1Click:Connect(function() sg:Destroy() end)

-- Drag
do
    local dragging=false; local dragStart; local startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true
            dragStart=input.Position
            startPos=main.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
            local delta=input.Position - dragStart
            main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)
end

-- Body
local body = create("Frame",{Position=UDim2.new(0,0,0,40),Size=UDim2.new(1,0,1,-40),BackgroundTransparency=1,Parent=main})

-- Toggle Fake VR
local toggleVR = create("TextButton",{Text="Fake VR: OFF",Size=UDim2.new(0,120,0,30),Position=UDim2.new(0,10,0,10),BackgroundColor3=Color3.fromRGB(50,150,50),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=14,Parent=body})
create("UICorner",{CornerRadius=UDim.new(0,5)},toggleVR)

-- Info Label
local infoLabel = create("TextLabel",{Text="Use WASD/Arrow for movement, QE for vertical, IJKL/UO for hand movement",BackgroundTransparency=1,TextColor3=Color3.fromRGB(200,200,200),Font=Enum.Font.Gotham,TextSize=12,Size=UDim2.new(1,0,0,50),Position=UDim2.new(0,0,0,50),Parent=body})

-- Hands
local leftHand = Character:FindFirstChild("LeftHand") or Character:FindFirstChildWhichIsA("BasePart")
local rightHand = Character:FindFirstChild("RightHand") or Character:FindFirstChildWhichIsA("BasePart")

local vrEnabled = false
toggleVR.MouseButton1Click:Connect(function()
    vrEnabled = not vrEnabled
    toggleVR.Text = "Fake VR: "..(vrEnabled and "ON" or "OFF")
end)

-- Input state
local leftInput = Vector3.new(0,0,0)
local rightInput = Vector3.new(0,0,0)

UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.I then leftInput = leftInput + Vector3.new(0,0,-1) end
    if input.KeyCode==Enum.KeyCode.K then leftInput = leftInput + Vector3.new(0,0,1) end
    if input.KeyCode==Enum.KeyCode.J then leftInput = leftInput + Vector3.new(-1,0,0) end
    if input.KeyCode==Enum.KeyCode.L then leftInput = leftInput + Vector3.new(1,0,0) end
    if input.KeyCode==Enum.KeyCode.U then leftInput = leftInput + Vector3.new(0,1,0) end
    if input.KeyCode==Enum.KeyCode.O then leftInput = leftInput + Vector3.new(0,-1,0) end

    if input.KeyCode==Enum.KeyCode.T then rightInput = rightInput + Vector3.new(0,0,-1) end
    if input.KeyCode==Enum.KeyCode.G then rightInput = rightInput + Vector3.new(0,0,1) end
    if input.KeyCode==Enum.KeyCode.F then rightInput = rightInput + Vector3.new(-1,0,0) end
    if input.KeyCode==Enum.KeyCode.H then rightInput = rightInput + Vector3.new(1,0,0) end
    if input.KeyCode==Enum.KeyCode.R then rightInput = rightInput + Vector3.new(0,1,0) end
    if input.KeyCode==Enum.KeyCode.Y then rightInput = rightInput + Vector3.new(0,-1,0) end
end)

UserInputService.InputEnded:Connect(function(input,processed)
    if input.KeyCode==Enum.KeyCode.I then leftInput = leftInput - Vector3.new(0,0,-1) end
    if input.KeyCode==Enum.KeyCode.K then leftInput = leftInput - Vector3.new(0,0,1) end
    if input.KeyCode==Enum.KeyCode.J then leftInput = leftInput - Vector3.new(-1,0,0) end
    if input.KeyCode==Enum.KeyCode.L then leftInput = leftInput - Vector3.new(1,0,0) end
    if input.KeyCode==Enum.KeyCode.U then leftInput = leftInput - Vector3.new(0,1,0) end
    if input.KeyCode==Enum.KeyCode.O then leftInput = leftInput - Vector3.new(0,-1,0) end

    if input.KeyCode==Enum.KeyCode.T then rightInput = rightInput - Vector3.new(0,0,-1) end
    if input.KeyCode==Enum.KeyCode.G then rightInput = rightInput - Vector3.new(0,0,1) end
    if input.KeyCode==Enum.KeyCode.F then rightInput = rightInput - Vector3.new(-1,0,0) end
    if input.KeyCode==Enum.KeyCode.H then rightInput = rightInput - Vector3.new(1,0,0) end
    if input.KeyCode==Enum.KeyCode.R then rightInput = rightInput - Vector3.new(0,1,0) end
    if input.KeyCode==Enum.KeyCode.Y then rightInput = rightInput - Vector3.new(0,-1,0) end
end)

-- Update Loop
RunService.RenderStepped:Connect(function(delta)
    if vrEnabled then
        if leftHand then
            leftHand.CFrame = leftHand.CFrame:Lerp(leftHand.CFrame + CFrame.new(leftInput * delta * 5),0.2)
        end
        if rightHand then
            rightHand.CFrame = rightHand.CFrame:Lerp(rightHand.CFrame + CFrame.new(rightInput * delta * 5),0.2)
        end
    end
end)
