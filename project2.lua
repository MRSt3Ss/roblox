-- Bons Player Item Dup GUI
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")

-- Hapus GUI lama
if PlayerGui:FindFirstChild("BonsPlayerDupGUI") then
    PlayerGui.BonsPlayerDupGUI:Destroy()
end

local function create(class, props, parent)
    local obj = Instance.new(class)
    if props then for k,v in pairs(props) do obj[k]=v end end
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
local sg = create("ScreenGui", {Parent = PlayerGui, Name = "BonsPlayerDupGUI", ResetOnSpawn=false})
local main = create("Frame", {Size=UDim2.new(0,360,0,500), Position=UDim2.new(0.3,0,0.2,0), BackgroundColor3=Color3.fromRGB(40,40,40)}, sg)
create("UICorner",{CornerRadius=UDim.new(0,10)},main)

-- Header
local header = create("Frame",{Size=UDim2.new(1,0,0,40), BackgroundColor3=Color3.fromRGB(70,70,70), Parent=main})
create("UICorner",{CornerRadius=UDim.new(0,10)},header)
create("TextLabel",{Text="Player Item Dup", BackgroundTransparency=1, TextSize=16, TextColor3=Color3.fromRGB(255,200,150), Font=Enum.Font.GothamBold, Size=UDim2.new(1,0,1,0), Parent=header})
local btnClose = create("TextButton",{Text="X", Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-35,0,5), BackgroundColor3=Color3.fromRGB(200,50,50), TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=16, Parent=header})
create("UICorner",{CornerRadius=UDim.new(0,5)},btnClose)
btnClose.MouseButton1Click:Connect(function() sg:Destroy() end)

-- Drag
do
    local dragging=false; local dragStart; local startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=input.Position; startPos=main.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
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
local body=create("Frame",{Position=UDim2.new(0,0,0,40), Size=UDim2.new(1,0,1,-40), BackgroundTransparency=1, Parent=main})

local infoLabel = create("TextLabel",{Text="Pilih player untuk scan item", BackgroundTransparency=1, TextColor3=Color3.fromRGB(200,200,200), Font=Enum.Font.Gotham, TextSize=14, Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0,10), Parent=body})

local scrollPlayers=create("ScrollingFrame",{Position=UDim2.new(0,10,0,50), Size=UDim2.new(1,-20,0,120), BackgroundTransparency=0.5, BackgroundColor3=Color3.fromRGB(60,60,60), CanvasSize=UDim2.new(0,0,0,0), ScrollBarThickness=8, Parent=body})
create("UIListLayout",{Parent=scrollPlayers, Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder})

local scrollItems=create("ScrollingFrame",{Position=UDim2.new(0,10,0,180), Size=UDim2.new(1,-20,0,200), BackgroundTransparency=0.5, BackgroundColor3=Color3.fromRGB(60,60,60), CanvasSize=UDim2.new(0,0,0,0), ScrollBarThickness=8, Parent=body})
create("UIListLayout",{Parent=scrollItems, Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder})

local inputAmount=create("TextBox",{PlaceholderText="Masukkan jumlah dupe", Size=UDim2.new(0,150,0,30), Position=UDim2.new(0,10,0,390), BackgroundColor3=Color3.fromRGB(80,80,80), TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=14, ClearTextOnFocus=true, Parent=body})
create("UICorner",{CornerRadius=UDim.new(0,5)},inputAmount)

local btnDup=create("TextButton",{Text="Duplicate Item", Size=UDim2.new(0,150,0,30), Position=UDim2.new(0,180,0,390), BackgroundColor3=Color3.fromRGB(150,50,50), TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=14, Parent=body})
create("UICorner",{CornerRadius=UDim.new(0,5)},btnDup)

local selectedPlayer = nil
local items = {}
local selectedItem = nil

-- List Player
for i,plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        local btn = create("TextButton",{Text=plr.Name, Size=UDim2.new(1,-10,0,30), BackgroundColor3=Color3.fromRGB(100,100,100), TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=14, Parent=scrollPlayers})
        btn.MouseButton1Click:Connect(function()
            selectedPlayer = plr
            infoLabel.Text = "Selected player: "..plr.Name
            -- Scan items
            scrollItems:ClearAllChildren()
            items={}
            local function addItems(container)
                for _,v in pairs(container:GetChildren()) do
                    if v:IsA("Tool") then
                        table.insert(items,v)
                        local itBtn=create("TextButton",{Text=v.Name, Size=UDim2.new(1,-10,0,30), BackgroundColor3=Color3.fromRGB(120,120,120), TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=14, Parent=scrollItems})
                        itBtn.MouseButton1Click:Connect(function()
                            selectedItem = v
                            infoLabel.Text = "Selected item: "..v.Name
                        end)
                    end
                end
            end
            addItems(plr:FindFirstChild("Backpack") or {})
            addItems(plr:FindFirstChild("StarterGear") or {})
            if plr.Character then addItems(plr.Character) end
            scrollItems.CanvasSize = UDim2.new(0,0,#items*35,0)
        end)
    end
end

-- Duplicate ke inv kita
btnDup.MouseButton1Click:Connect(function()
    if not selectedItem then
        infoLabel.Text = "Pilih item dulu!"
        return
    end
    local amount = tonumber(inputAmount.Text)
    if not amount or amount <1 then
        infoLabel.Text = "Jumlah tidak valid!"
        return
    end

    local success = false
    for i=1,amount do
        local clone = selectedItem:Clone()
        clone.Parent = LocalPlayer:FindFirstChild("Backpack")
        success = true
    end

    if success then
        infoLabel.Text = "Dupe sukses: "..selectedItem.Name.." x"..amount
        showNotif("Dupe asli "..selectedItem.Name.." x"..amount)
    else
        infoLabel.Text = "Gagal dupe"
    end
end)
