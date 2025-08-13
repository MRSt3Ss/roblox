-- Fake VR Controller v5 - Dual Analog Hand Control (PC)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Hapus GUI lama
if PlayerGui:FindFirstChild("FakeVRGUI") then
    PlayerGui.FakeVRGUI:Destroy()
end

-- Utils
local function create(class, props, parent)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do obj[k]=v end
    end
    if parent then obj.Parent = parent end
    return obj
end

-- Main GUI
local sg = create("ScreenGui",{Parent=PlayerGui,Name="FakeVRGUI",ResetOnSpawn=false})
local main = create("Frame",{Size=UDim2.new(0,400,0,300),Position=UDim2.new(0.3,0,0.3,0),BackgroundColor3=Color3.fromRGB(40,40,40)},sg)
create("UICorner",{CornerRadius=UDim.new(0,10)},main)

-- Header
local header = create("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=Color3.fromRGB(70,70,70),Parent=main},sg)
create("UICorner",{CornerRadius=UDim.new(0,10)},header)
create("TextLabel",{Text="Fake VR v5 - Dual Analog",BackgroundTransparency=1,TextSize=16,TextColor3=Color3.fromRGB(255,200,150),Font=Enum.Font.GothamBold,Size=UDim2.new(1,0,1,0),Parent=header})
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

-- Body GUI
local body = create("Frame",{Position=UDim2.new(0,0,0,40),Size=UDim2.new(1,0,1,-40),BackgroundTransparency=1,Parent=main})

-- Left and Right Analog
local leftAnalog = create("Frame",{Position=UDim2.new(0,20,0,50),Size=UDim2.new(0,150,0,150),BackgroundColor3=Color3.fromRGB(80,80,80),Parent=body})
create("UICorner",{CornerRadius=UDim.new(0,75)},leftAnalog)
local rightAnalog = create("Frame",{Position=UDim2.new(0,220,0,50),Size=UDim2.new(0,150,0,150),BackgroundColor3=Color3.fromRGB(80,80,80),Parent=body})
create("UICorner",{CornerRadius=UDim.new(0,75)},rightAnalog)

-- Thumbstick indicators
local leftThumb = create("Frame",{Size=UDim2.new(0,30,0,30),Position=UDim2.new(0.5,-15,0.5,-15),BackgroundColor3=Color3.fromRGB(200,200,200),Parent=leftAnalog})
create("UICorner",{CornerRadius=UDim.new(0,15)},leftThumb)
local rightThumb = create("Frame",{Size=UDim2.new(0,30,0,30),Position=UDim2.new(0.5,-15,0.5,-15),BackgroundColor3=Color3.fromRGB(200,200,200),Parent=rightAnalog})
create("UICorner",{CornerRadius=UDim.new(0,15)},rightThumb)

-- VR Hands
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local rightHand = character:WaitForChild("RightHand")
local leftHand = character:WaitForChild("LeftHand")

local leftPos, rightPos = leftHand.Position, rightHand.Position

-- Control Variables
local leftInput = Vector3.new()
local rightInput = Vector3.new()

-- Analog input
local function updateAnalog(analog, thumb, inputVector)
    thumb.Position = UDim2.new(0.5, inputVector.X*50,0.5, inputVector.Y*50)
end

-- Mouse drag analog
local draggingAnalog = nil
local dragStartPos = nil
local function onInputBegan(analogFrame, thumb)
    thumb.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            draggingAnalog=thumb
            dragStartPos=input.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then draggingAnalog=nil end
            end)
        end
    end)
end
onInputBegan(leftAnalog,leftThumb)
onInputBegan(rightAnalog,rightThumb)

UserInputService.InputChanged:Connect(function(input)
    if draggingAnalog then
        local delta = (input.Position - dragStartPos)/50
        dragStartPos = input.Position
        if draggingAnalog==leftThumb then
            leftInput = leftInput + Vector3.new(delta.X,0,delta.Y)
            updateAnalog(leftAnalog,leftThumb,leftInput)
        elseif draggingAnalog==rightThumb then
            rightInput = rightInput + Vector3.new(delta.X,0,delta.Y)
            updateAnalog(rightAnalog,rightThumb,rightInput)
        end
    end
end)

-- Update hands
RunService.RenderStepped:Connect(function(dt)
    if leftHand then leftHand.CFrame = leftHand.CFrame + leftInput end
    if rightHand then rightHand.CFrame = rightHand.CFrame + rightInput end
end)
