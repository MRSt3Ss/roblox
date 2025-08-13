-- Bons Server Dumper + Spawn Pets V1
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Hapus GUI lama
if PlayerGui:FindFirstChild("BonsSpawnGUI") then
    PlayerGui.BonsSpawnGUI:Destroy()
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
local sg = create("ScreenGui", {Parent = PlayerGui, Name = "BonsSpawnGUI", ResetOnSpawn = false})
local main = create("Frame", {
    Size = UDim2.new(0, 400, 0, 500),
    Position = UDim2.new(0.3,0,0.2,0),
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
    Text = "Server Dumper + Spawn Pets",
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
    Text = "Klik 'Dump Server' untuk melihat semua pets/objek",
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
    Size = UDim2.new(1,-20,0,350),
    BackgroundTransparency = 0.5,
    BackgroundColor3 = Color3.fromRGB(60,60,60),
    CanvasSize = UDim2.new(0,0,0,0),
    ScrollBarThickness = 8,
    Parent = body
})
create("UIListLayout", {Parent = scroll, Padding = UDim.new(0,5), SortOrder = Enum.SortOrder.LayoutOrder})

local btnDump = create("TextButton", {
    Text = "Dump Server",
    Size = UDim2.new(0,120,0,30),
    Position = UDim2.new(0,10,0,410),
    BackgroundColor3 = Color3.fromRGB(50,150,50),
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    Parent = body
})
create("UICorner", {CornerRadius=UDim.new(0,5)}, btnDump)

local selectedObj = nil
local objects = {}

-- Dump server
btnDump.MouseButton1Click:Connect(function()
    scroll:ClearAllChildren()
    objects = {}
    local function scanContainer(container)
        for _,v in pairs(container:GetChildren()) do
            if v:IsA("Model") or v:IsA("Tool") then
                table.insert(objects,v)
                local btn = create("TextButton", {
                    Text = v.Name,
                    Size = UDim2.new(1,-10,0,30),
                    BackgroundColor3 = Color3.fromRGB(100,100,100),
                    TextColor3 = Color3.new(1,1,1),
                    Font = Enum.Font.GothamBold,
                    TextSize = 14,
                    Parent = scroll
                })
                btn.MouseButton1Click:Connect(function()
                    selectedObj = v
                    infoLabel.Text = "Selected: "..v.Name
                end)
            end
            scanContainer(v)
        end
    end

    scanContainer(ReplicatedStorage)
    scanContainer(Workspace)
    scroll.CanvasSize = UDim2.new(0,0,#objects*35,0)
    infoLabel.Text = "Dump selesai! Pilih pet/objek untuk spawn."
    showNotif("Server dump berhasil!")
end)

-- Spawn button
local btnSpawn = create("TextButton", {
    Text = "Spawn Selected",
    Size = UDim2.new(0,120,0,30),
    Position = UDim2.new(0,150,0,410),
    BackgroundColor3 = Color3.fromRGB(150,50,50),
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    Parent = body
})
create("UICorner", {CornerRadius=UDim.new(0,5)}, btnSpawn)

btnSpawn.MouseButton1Click:Connect(function()
    if not selectedObj then
        infoLabel.Text = "Pilih pet/objek dulu!"
        return
    end
    local clone = selectedObj:Clone()
    clone.Parent = Workspace
    clone:SetPrimaryPartCFrame(LocalPlayer.Character.PrimaryPart.CFrame * CFrame.new(3,0,0))
    infoLabel.Text = "Spawned: "..selectedObj.Name
    showNotif("Spawned: "..selectedObj.Name)
end)
