-- Bons Auto Scan & Dup Pets
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Hapus GUI lama
if PlayerGui:FindFirstChild("BonsDupPetsGUI") then
    PlayerGui.BonsDupPetsGUI:Destroy()
end

-- Utils
local function create(class, props, parent)
    local obj = Instance.new(class)
    if props then for k,v in pairs(props) do obj[k] = v end end
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

-- GUI
local sg = create("ScreenGui", {Parent=PlayerGui, Name="BonsDupPetsGUI", ResetOnSpawn=false})
local main = create("Frame",{Size=UDim2.new(0,400,0,500), Position=UDim2.new(0.3,0,0.2,0), BackgroundColor3=Color3.fromRGB(40,40,40)}, sg)
create("UICorner",{CornerRadius=UDim.new(0,10)}, main)

local header = create("Frame",{Size=UDim2.new(1,0,0,40), BackgroundColor3=Color3.fromRGB(70,70,70), Parent=main}, sg)
create("UICorner",{CornerRadius=UDim.new(0,10)}, header)
create("TextLabel",{Text="Auto Scan & Dup Pets", BackgroundTransparency=1, TextColor3=Color3.fromRGB(255,200,150), Font=Enum.Font.GothamBold, TextSize=16, Size=UDim2.new(1,0,1,0), Parent=header})

local btnClose = create("TextButton",{Text="X", Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-35,0,5), BackgroundColor3=Color3.fromRGB(200,50,50), TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=16, Parent=header})
create("UICorner",{CornerRadius=UDim.new(0,5)}, btnClose)
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
local body = create("Frame",{Position=UDim2.new(0,0,0,40), Size=UDim2.new(1,0,1,-40), BackgroundTransparency=1, Parent=main})
local infoLabel = create("TextLabel",{Text="Klik 'Scan Map' untuk mendeteksi pets", BackgroundTransparency=1, TextColor3=Color3.fromRGB(200,200,200), Font=Enum.Font.Gotham, TextSize=14, Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0,10), Parent=body})
local scroll = create("ScrollingFrame",{Position=UDim2.new(0,10,0,50), Size=UDim2.new(1,-20,0,350), BackgroundTransparency=0.5, BackgroundColor3=Color3.fromRGB(60,60,60), CanvasSize=UDim2.new(0,0,0,0), ScrollBarThickness=8, Parent=body})
create("UIListLayout",{Parent=scroll, Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder})

local btnScan = create("TextButton",{Text="Scan Map", Size=UDim2.new(0,120,0,30), Position=UDim2.new(0,10,0,410), BackgroundColor3=Color3.fromRGB(50,150,50), TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=14, Parent=body})
create("UICorner",{CornerRadius=UDim.new(0,5)}, btnScan)

local btnDup = create("TextButton",{Text="Duplicate", Size=UDim2.new(0,120,0,30), Position=UDim2.new(0,150,0,410), BackgroundColor3=Color3.fromRGB(150,50,50), TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=14, Parent=body})
create("UICorner",{CornerRadius=UDim.new(0,5)}, btnDup)

local selectedPet = nil
local pets = {}

-- Scan map untuk pets
btnScan.MouseButton1Click:Connect(function()
    scroll:ClearAllChildren()
    pets = {}
    local function scanContainer(container)
        for _,v in pairs(container:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") then -- kemungkinan pets
                table.insert(pets,v)
                local btn = create("TextButton",{Text=v.Name, Size=UDim2.new(1,-10,0,30), BackgroundColor3=Color3.fromRGB(100,100,100), TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=14, Parent=scroll})
                btn.MouseButton1Click:Connect(function()
                    selectedPet = v
                    infoLabel.Text = "Selected: "..v.Name
                end)
            end
            scanContainer(v)
        end
    end
    scanContainer(Workspace)
    scroll.CanvasSize = UDim2.new(0,0,#pets*35,0)
    infoLabel.Text = "Scan selesai! Pilih pet untuk duplicate."
    showNotif("Scan Map Selesai!")
end)

-- Duplicate
btnDup.MouseButton1Click:Connect(function()
    if not selectedPet then
        infoLabel.Text = "Pilih pet dulu!"
        return
    end
    local amount = 1 -- default 1, bisa dimodifikasi pakai TextBox
    local success = false
    for i=1,amount do
        local clone = selectedPet:Clone()
        clone.Parent = Workspace
        clone:SetPrimaryPartCFrame(LocalPlayer.Character.PrimaryPart.CFrame * CFrame.new(3*i,0,0))
        success = true
    end
    if success then
        infoLabel.Text = "Dup berhasil: "..selectedPet.Name.." x"..amount
        showNotif("Dup Berhasil: "..selectedPet.Name.." x"..amount)
    else
        infoLabel.Text = "Dup gagal!"
    end
end)
