-- Fake VR v4 Analog Controller for PC
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Clear old GUI
if PlayerGui:FindFirstChild("FakeVRGUI") then PlayerGui.FakeVRGUI:Destroy() end

-- Utils
local function create(class, props, parent)
    local obj = Instance.new(class)
    if props then for k,v in pairs(props) do obj[k]=v end end
    if parent then obj.Parent=parent end
    return obj
end

-- Main GUI
local sg=create("ScreenGui",{Parent=PlayerGui,Name="FakeVRGUI",ResetOnSpawn=false})
local main=create("Frame",{Size=UDim2.new(0,320,0,240),Position=UDim2.new(0.35,0,0.35,0),BackgroundColor3=Color3.fromRGB(30,30,30)},sg)
create("UICorner",{CornerRadius=UDim.new(0,10)},main)

-- Header
local header=create("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=Color3.fromRGB(60,60,60),Parent=main})
create("UICorner",{CornerRadius=UDim.new(0,10)},header)
create("TextLabel",{Text="Fake VR v4 Analog",BackgroundTransparency=1,TextSize=16,TextColor3=Color3.fromRGB(255,200,150),Font=Enum.Font.GothamBold,Size=UDim2.new(1,0,1,0),Parent=header})
local btnClose=create("TextButton",{Text="X",Size=UDim2.new(0,30,0,30),Position=UDim2.new(1,-35,0,5),BackgroundColor3=Color3.fromRGB(200,50,50),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=16,Parent=header})
create("UICorner",{CornerRadius=UDim.new(0,5)},btnClose)
btnClose.MouseButton1Click:Connect(function() sg:Destroy() end)

-- Drag
do
    local dragging=false; local dragStart; local startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=input.Position; startPos=main.Position
            input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
            local delta=input.Position-dragStart
            main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)
end

-- Body
local body=create("Frame",{Position=UDim2.new(0,0,0,40),Size=UDim2.new(1,0,1,-40),BackgroundTransparency=1,Parent=main})

-- Toggle VR
local toggleVR=create("TextButton",{Text="Fake VR: OFF",Size=UDim2.new(0,120,0,30),Position=UDim2.new(0,10,0,10),BackgroundColor3=Color3.fromRGB(50,150,50),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=14,Parent=body})
create("UICorner",{CornerRadius=UDim.new(0,5)},toggleVR)

-- Info
local infoLabel=create("TextLabel",{Text="Analog control: drag circles for hands",BackgroundTransparency=1,TextColor3=Color3.fromRGB(200,200,200),Font=Enum.Font.Gotham,TextSize=12,Size=UDim2.new(1,0,0,40),Position=UDim2.new(0,0,0,50),Parent=body})

-- Hands
local leftHand = Character:FindFirstChild("LeftHand") or Character:FindFirstChildWhichIsA("BasePart")
local rightHand = Character:FindFirstChild("RightHand") or Character:FindFirstChildWhichIsA("BasePart")

local vrEnabled=false
toggleVR.MouseButton1Click:Connect(function()
    vrEnabled = not vrEnabled
    toggleVR.Text = "Fake VR: "..(vrEnabled and "ON" or "OFF")
end)

-- Analog circles
local leftCircle=create("Frame",{Size=UDim2.new(0,100,0,100),Position=UDim2.new(0,20,0,100),BackgroundColor3=Color3.fromRGB(80,80,80),Parent=body})
create("UICorner",{CornerRadius=UDim.new(0,50)},leftCircle)
local leftKnob=create("Frame",{Size=UDim2.new(0,40,0,40),Position=UDim2.new(0.5,-20,0.5,-20),BackgroundColor3=Color3.fromRGB(150,150,150),Parent=leftCircle})
create("UICorner",{CornerRadius=UDim.new(0,20)},leftKnob)

local rightCircle=create("Frame",{Size=UDim2.new(0,100,0,100),Position=UDim2.new(0,200,0,100),BackgroundColor3=Color3.fromRGB(80,80,80),Parent=body})
create("UICorner",{CornerRadius=UDim.new(0,50)},rightCircle)
local rightKnob=create("Frame",{Size=UDim2.new(0,40,0,40),Position=UDim2.new(0.5,-20,0.5,-20),BackgroundColor3=Color3.fromRGB(150,150,150),Parent=rightCircle})
create("UICorner",{CornerRadius=UDim.new(0,20)},rightKnob)

local leftDelta=Vector3.new(0,0,0)
local rightDelta=Vector3.new(0,0,0)

-- Drag function
local function setupKnob(knob,circle,deltaRef)
    local dragging=false
    local center=circle.AbsolutePosition + Vector2.new(circle.AbsoluteSize.X/2,circle.AbsoluteSize.Y/2)
    knob.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=false
            knob.Position=UDim2.new(0.5,-20,0.5,-20)
            deltaRef.Value=Vector3.new(0,0,0)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
            local pos=input.Position - center
            local maxRange=circle.AbsoluteSize.X/2-20
            pos=Vector2.new(math.clamp(pos.X,-maxRange,maxRange),math.clamp(pos.Y,-maxRange,maxRange))
            knob.Position=UDim2.new(0.5,-20,0.5,-20) + UDim2.new(0,pos.X,0,pos.Y)
            deltaRef.Value=Vector3.new(pos.X/20,0, -pos.Y/20)
        end
    end)
end

-- Wrapper for delta
local leftRef={Value=Vector3.new(0,0,0)}
local rightRef={Value=Vector3.new(0,0,0)}
setupKnob(leftKnob,leftCircle,leftRef)
setupKnob(rightKnob,rightCircle,rightRef)

-- Vertical control via keys
local leftY=0
local rightY=0
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode==Enum.KeyCode.U then leftY=1 end
    if input.KeyCode==Enum.KeyCode.O then leftY=-1 end
    if input.KeyCode==Enum.KeyCode.R then rightY=1 end
    if input.KeyCode==Enum.KeyCode.Y then rightY=-1 end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode==Enum.KeyCode.U or input.KeyCode==Enum.KeyCode.O then leftY=0 end
    if input.KeyCode==Enum.KeyCode.R or input.KeyCode==Enum.KeyCode.Y then rightY=0 end
end)

-- Update loop
RunService.RenderStepped:Connect(function(delta)
    if vrEnabled then
        if leftHand then
            local target=leftHand.Position + Vector3.new(leftRef.Value.X,leftY,leftRef.Value.Z)*delta*5
            leftHand.CFrame = leftHand.CFrame:Lerp(CFrame.new(target),0.2)
        end
        if rightHand then
            local target=rightHand.Position + Vector3.new(rightRef.Value.X,rightY,rightRef.Value.Z)*delta*5
            rightHand.CFrame = rightHand.CFrame:Lerp(CFrame.new(target),0.2)
        end
    end
end)
