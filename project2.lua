-- Bons Player Carry GUI v2
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Hapus GUI lama
if PlayerGui:FindFirstChild("BonsCarryGUI") then
    PlayerGui.BonsCarryGUI:Destroy()
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
local sg = create("ScreenGui", {Parent = PlayerGui, Name = "BonsCarryGUI", ResetOnSpawn = false})
local main = create("Frame", {
    Size = UDim2.new(0, 380, 0, 450),
    Position = UDim2.new(0.3,0,0.2,0),
    BackgroundColor3 = Color3.fromRGB(40,40,40)
}, sg)
create("UICorner", {CornerRadius=UDim.new(0,10)}, main)

-- Header
local header = create("Frame", {
    Size = UDim2.new(1,0,0,40),
    BackgroundColor3 = Color3.fromRGB(70,70,70),
    Parent = main
})
create("UICorner", {CornerRadius=UDim.new(0,10)}, header)

create("TextLabel", {
    Text = "Player Carry GUI v2",
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

-- Drag GUI
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
    Text = "Pilih player untuk carry",
    BackgroundTransparency = 1,
    TextColor3 = Color3.fromRGB(200,200,200),
    Font = Enum.Font.Gotham,
    TextSize = 14,
    Size = UDim2.new(1,0,0,30),
    Position = UDim2.new(0,0,0,10),
    Parent = body
})

local scroll = create("ScrollingFrame", {
    Position = UDim2.new(0,10,0,50),
    Size = UDim2.new(1,-20,0,300),
    BackgroundTransparency = 0.5,
    BackgroundColor3 = Color3.fromRGB(60,60,60),
    CanvasSize = UDim2.new(0,0,0,0),
    ScrollBarThickness = 8,
    Parent = body
})
create("UIListLayout", {Parent = scroll, Padding = UDim.new(0,5), SortOrder = Enum.SortOrder.LayoutOrder})

local playersList = {}
local carrying = nil

-- Tombol release
local btnRelease = create("TextButton", {
    Text = "Release Player",
    Size = UDim2.new(0,120,0,30),
    Position = UDim2.new(0,130,0,360),
    BackgroundColor3 = Color3.fromRGB(50,150,50),
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    Parent = body
})
create("UICorner",{CornerRadius=UDim.new(0,5)}, btnRelease)

btnRelease.MouseButton1Click:Connect(function()
    if carrying then
        showNotif("Player released: "..carrying.DisplayName)
        carrying = nil
        infoLabel.Text = "Pilih player untuk carry"
    else
        infoLabel.Text = "Tidak ada player yang di carry"
    end
end)

-- Tombol refresh
local btnRefresh = create("TextButton", {
    Text = "Refresh Players",
    Size = UDim2.new(0,120,0,30),
    Position = UDim2.new(0,10,0,360),
    BackgroundColor3 = Color3.fromRGB(100,100,200),
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    Parent = body
})
create("UICorner",{CornerRadius=UDim.new(0,5)}, btnRefresh)

local function refreshPlayers()
    scroll:ClearAllChildren()
    playersList = {}
    for i,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = create("TextButton", {
                Text = plr.DisplayName,
                Size = UDim2.new(1,0,0,30),
                BackgroundColor3 = Color3.fromRGB(100,100,100),
                TextColor3 = Color3.new(1,1,1),
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                Parent = scroll
            })
            btn.MouseButton1Click:Connect(function()
                carrying = plr
                infoLabel.Text = "Carrying: "..plr.DisplayName
                showNotif("Carry aktif: "..plr.DisplayName)
            end)
        end
    end
    scroll.CanvasSize = UDim2.new(0,0,#Players:GetPlayers()*35,0)
end

btnRefresh.MouseButton1Click:Connect(refreshPlayers)
refreshPlayers()
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)

-- Loop carry player
RunService.RenderStepped:Connect(function()
    if carrying and carrying.Character and LocalPlayer.Character then
        local targetRoot = carrying.Character:FindFirstChild("HumanoidRootPart")
        local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot and localRoot then
            targetRoot.CFrame = localRoot.CFrame * CFrame.new(0,0,5)
        end
    end
end)
