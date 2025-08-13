-- Bons Auto Fish GUI
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Hapus GUI lama
if PlayerGui:FindFirstChild("BonsAutoFishGUI") then
    PlayerGui.BonsAutoFishGUI:Destroy()
end

-- Utils
local function create(class, props, parent)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            obj[k] = v
        end
    end
    if parent then obj.Parent = parent end
    return obj
end

-- Notif kecil
local function showNotif(text)
    local notif = create("TextLabel", {
        Text = text,
        BackgroundColor3 = Color3.fromRGB(50,50,50),
        TextColor3 = Color3.new(1,1,1),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Size = UDim2.new(0,250,0,30),
        Position = UDim2.new(0.5,-125,0.05,0),
        Parent = PlayerGui,
        BackgroundTransparency = 0.3,
    })
    create("UICorner",{CornerRadius=UDim.new(0,5)},notif)
    local tween = TweenService:Create(notif, TweenInfo.new(2), {Position=UDim2.new(0.5,-125,0,50), BackgroundTransparency=1})
    tween:Play()
    tween.Completed:Connect(function() notif:Destroy() end)
end

-- Main GUI
local sg = create("ScreenGui", {Parent = PlayerGui, Name = "BonsAutoFishGUI", ResetOnSpawn = false})
local main = create("Frame", {
    Size = UDim2.new(0, 360, 0, 300),
    Position = UDim2.new(0.3,0,0.3,0),
    BackgroundColor3 = Color3.fromRGB(40,40,40)
}, sg)
create("UICorner", {CornerRadius = UDim.new(0,10)}, main)

-- Header
local header = create("Frame", {
    Size = UDim2.new(1,0,0,40),
    BackgroundColor3 = Color3.fromRGB(70,70,70),
    Parent = main
})
create("UICorner", {CornerRadius=UDim.new(0,10)}, header)
create("TextLabel", {
    Text = "Auto Fish",
    BackgroundTransparency = 1,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255,200,150),
    Font = Enum.Font.GothamBold,
    Size = UDim2.new(1,0,1,0),
    Parent = header
})
local btnClose = create("TextButton", {
    Text = "X",
    Size = UDim2.new(0,30,0,30),
    Position = UDim2.new(1,-35,0,5),
    BackgroundColor3 = Color3.fromRGB(200,50,50),
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    Parent = header
})
create("UICorner", {CornerRadius=UDim.new(0,5)}, btnClose)
btnClose.MouseButton1Click:Connect(function() sg:Destroy() end)

-- Dragging
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
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Body
local body = create("Frame", {
    Position = UDim2.new(0,0,0,40),
    Size = UDim2.new(1,0,1,-40),
    BackgroundTransparency = 1,
    Parent = main
})

local infoLabel = create("TextLabel", {
    Text = "Status: OFF",
    BackgroundTransparency = 1,
    TextColor3 = Color3.fromRGB(200,200,200),
    Font = Enum.Font.Gotham,
    TextSize = 14,
    Size = UDim2.new(1,0,0,30),
    Position = UDim2.new(0,0,0,10),
    Parent = body
})

local btnToggle = create("TextButton", {
    Text = "Toggle Auto Fish",
    Size = UDim2.new(0,150,0,30),
    Position = UDim2.new(0,10,0,50),
    BackgroundColor3 = Color3.fromRGB(50,150,50),
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    Parent = body
})
create("UICorner", {CornerRadius=UDim.new(0,5)}, btnToggle)

-- Auto Fish Logic
local autoFish = false
local fishCaught = 0

btnToggle.MouseButton1Click:Connect(function()
    autoFish = not autoFish
    infoLabel.Text = "Status: "..(autoFish and "ON" or "OFF")
end)

-- Function to get nearest fishing spot
local function getNearestFishingSpot()
    local nearest = nil
    local dist = math.huge
    for _,v in pairs(workspace:GetDescendants()) do
        if v.Name:lower():find("fish") and v:IsA("Part") then
            local d = (v.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if d < dist then
                dist = d
                nearest = v
            end
        end
    end
    return nearest
end

-- Main loop
spawn(function()
    while true do
        RunService.RenderStepped:Wait()
        if autoFish and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local spot = getNearestFishingSpot()
            if spot then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(spot.Position + Vector3.new(0,2,0))
                -- Simulate fishing (replace dengan event game spesifik)
                -- Misal: trigger remote event
                local success, err = pcall(function()
                    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("CatchFish")
                    if remote then
                        remote:FireServer()
                        fishCaught = fishCaught + 1
                        infoLabel.Text = "Status: ON | Fish caught: "..fishCaught
                        showNotif("Ikan ditangkap! Total: "..fishCaught)
                    end
                end)
                if not success then
                    infoLabel.Text = "Status: ON | Error menangkap ikan"
                end
            end
        end
    end
end)
