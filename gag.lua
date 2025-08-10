-- Pet Spawner & Duplicator (FULL CUSTOM GUI)
-- By BonsCodes-style (no external libs)
-- Requirements: ReplicatedStorage.Pets contains pet models (PrimaryPart set recommended)

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInput = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local function getHRP()
    character = player.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end

-- wait pets folder
local PET_FOLDER
repeat
    PET_FOLDER = ReplicatedStorage:FindFirstChild("Pets")
    RunService.Heartbeat:Wait()
until PET_FOLDER and #PET_FOLDER:GetChildren() > 0

-- create safe ScreenGui (try CoreGui then PlayerGui)
local uiParent = game:GetService("CoreGui")
pcall(function()
    if not uiParent then uiParent = nil end
end)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Bons_PetSpawner"
screenGui.ResetOnSpawn = false
-- try CoreGui first (some executors allow), otherwise PlayerGui
local ok, err = pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
if not ok or not screenGui.Parent then
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

-- remove previous instance if exists
pcall(function()
    local prev = screenGui.Parent:FindFirstChild("Bons_PetSpawner")
    if prev and prev ~= screenGui then prev:Destroy() end
end)

-- UI Styling helpers
local function make(parent, class, props)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            obj[k] = v
        end
    end
    obj.Parent = parent
    return obj
end

-- Main frame
local main = make(screenGui, "Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0,380,0,220),
    Position = UDim2.new(0,28,0,120),
    BackgroundColor3 = Color3.fromRGB(6,16,6),
    BackgroundTransparency = 0.06,
    BorderSizePixel = 0
})
make(main, "UICorner", {CornerRadius = UDim.new(0,12)})
make(main, "UIStroke", {Color = Color3.fromRGB(0,255,150), Thickness = 2, Transparency = 0.16})

-- Header
local header = make(main, "Frame", {Size = UDim2.new(1,0,0,56), BackgroundTransparency = 1})
local title = make(header, "TextLabel", {
    Size = UDim2.new(0.7,-8,1,0),
    Position = UDim2.new(0,12,0,0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBlack,
    TextSize = 18,
    Text = "⟡ Pet Spawner & Duplicator",
    TextColor3 = Color3.fromRGB(170,255,190),
    TextXAlignment = Enum.TextXAlignment.Left
})
local closeBtn = make(header, "TextButton", {
    Size = UDim2.new(0,36,0,36),
    Position = UDim2.new(1,-44,0,10),
    BackgroundColor3 = Color3.fromRGB(0,200,120),
    Text = "━",
    Font = Enum.Font.GothamBold,
    TextSize = 18
})
make(closeBtn, "UICorner", {CornerRadius = UDim.new(0,8)})

-- Minimize icon (button)
local iconFrame = make(screenGui, "TextButton", {
    Name = "MiniIcon",
    Size = UDim2.new(0,56,0,56),
    Position = UDim2.new(0,12,0,12),
    Visible = false,
    BackgroundColor3 = Color3.fromRGB(0,30,12),
    Text = "PS",
    Font = Enum.Font.GothamBlack,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(170,255,190)
})
make(iconFrame, "UICorner", {CornerRadius = UDim.new(0,10)})

-- Left / Right panels
local left = make(main, "Frame", {Size = UDim2.new(0.48,-12,1,-80), Position = UDim2.new(0,12,0,68), BackgroundTransparency = 1})
local right = make(main, "Frame", {Size = UDim2.new(0.5,-12,1,-80), Position = UDim2.new(0.5,6,0,68), BackgroundTransparency = 1})

-- Map-like controls (adapted)
local selectLabel = make(left,"TextLabel",{Size=UDim2.new(1,0,0,18), BackgroundTransparency=1, Text="Select Pet:", Font=Enum.Font.GothamSemibold, TextSize=14, TextColor3=Color3.fromRGB(190,255,200)})
local selectBtn = make(left,"TextButton",{Size=UDim2.new(1,0,0,34), Position=UDim2.new(0,0,0,22), Text="Select Pet", Font=Enum.Font.Gotham, TextSize=14, BackgroundColor3=Color3.fromRGB(0,36,14), TextColor3=Color3.fromRGB(200,255,200)})
make(selectBtn, "UICorner", {CornerRadius = UDim.new(0,8)})
local selectArrow = make(selectBtn,"TextLabel",{Size=UDim2.new(0,32,1,0), Position=UDim2.new(1,-32,0,0), BackgroundTransparency=1, Text="▾", Font=Enum.Font.GothamBold, TextColor3=Color3.fromRGB(200,255,200)})

-- dropdown frame (hidden initially)
local ddFrame = make(left,"Frame",{Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,64), BackgroundTransparency=1, ClipsDescendants=true})
local ddLayout = make(ddFrame,"UIListLayout",{Padding=UDim.new(0,6)})

-- Buttons spawn / duplicate
local spawnBtn = make(left,"TextButton",{Size=UDim2.new(1,0,0,40), Position=UDim2.new(0,0,0,108), Text="Spawn Selected Pet", Font=Enum.Font.GothamBold, TextSize=16, BackgroundColor3=Color3.fromRGB(0,200,140), TextColor3=Color3.fromRGB(10,10,10)})
make(spawnBtn,"UICorner",{CornerRadius=UDim.new(0,8)})
local dupBtn = make(left,"TextButton",{Size=UDim2.new(1,0,0,34), Position=UDim2.new(0,0,0,158), Text="Duplicate Nearest Pet", Font=Enum.Font.GothamSemibold, TextSize=14, BackgroundColor3=Color3.fromRGB(0,180,110), TextColor3=Color3.fromRGB(10,10,10)})
make(dupBtn,"UICorner",{CornerRadius=UDim.new(0,8)})

-- Right panel: info + list of spawned pets
local infoLabel = make(right,"TextLabel",{Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Text="Spawned Pets", Font=Enum.Font.GothamSemibold, TextSize=14, TextColor3=Color3.fromRGB(200,255,200)})
local petScroll = make(right,"ScrollingFrame",{Size=UDim2.new(1,0,1,-8), Position=UDim2.new(0,0,0,28), CanvasSize=UDim2.new(0,0,0,0), ScrollBarThickness=8, BackgroundTransparency=0.06, BackgroundColor3=Color3.fromRGB(0,28,10)})
make(petScroll,"UICorner",{CornerRadius=UDim.new(0,8)})
local petLayout = make(petScroll,"UIListLayout",{Padding=UDim.new(0,8)})

-- state
local petNames = {}
for _,v in ipairs(PET_FOLDER:GetChildren()) do table.insert(petNames, v.Name) end
table.sort(petNames)
local selectedPet = petNames[1] or nil
local ddOpen = false
local spawnedPets = {} -- list of {model = Model, followerThread = thread}

-- helper: notify (small popup)
local function notify(text, time)
    time = time or 1.6
    if not screenGui or not screenGui.Parent then return end
    local n = make(screenGui,"Frame",{Size=UDim2.new(0,260,0,44), Position=UDim2.new(0.5,-130,0.06,0), BackgroundColor3=Color3.fromRGB(6,18,8), BackgroundTransparency=0.12})
    make(n,"UICorner",{CornerRadius=UDim.new(0,8)})
    make(n,"UIStroke",{Color=Color3.fromRGB(0,255,150), Transparency=0.4})
    local lbl = make(n,"TextLabel",{Size=UDim2.new(1,-16,1,-8), Position=UDim2.new(0,8,0,6), BackgroundTransparency=1, Text=text, Font=Enum.Font.Gotham, TextSize=14, TextColor3=Color3.fromRGB(200,255,200), TextWrapped=true})
    delay(time, function()
        pcall(function() n:Destroy() end)
    end)
end

-- populate dropdown items
local function refreshDropdown()
    for _,c in ipairs(ddFrame:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
    for i,name in ipairs(petNames) do
        local row = make(ddFrame,"TextButton",{Size=UDim2.new(1,0,0,30), BackgroundColor3=Color3.fromRGB(0,22,10), Text=name, Font=Enum.Font.Gotham, TextSize=14, TextColor3=Color3.fromRGB(200,255,200)})
        make(row,"UICorner",{CornerRadius=UDim.new(0,6)})
        row.MouseButton1Click:Connect(function()
            selectedPet = name
            selectBtn.Text = "Pet: "..tostring(name)
            ddOpen = false
            ddFrame:TweenSize(UDim2.new(1,0,0,0),"Out","Quad",0.18,true)
        end)
    end
    ddFrame:TweenSize(UDim2.new(1,0,0,0),"Out","Quad",0.01,true)
end
refreshDropdown()
selectBtn.Text = "Pet: "..(selectedPet or "None")

-- update spawned pet list UI
local function refreshSpawnedList()
    for _,c in ipairs(petScroll:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
    for i,entry in ipairs(spawnedPets) do
        local m = entry.model
        if m and m.PrimaryPart then
            local row = make(petScroll,"Frame",{Size=UDim2.new(1,-12,0,44), BackgroundColor3=Color3.fromRGB(0,18,8)})
            make(row,"UICorner",{CornerRadius=UDim.new(0,8)})
            local lbl = make(row,"TextLabel",{Size=UDim2.new(0.68,0,1,0), Position=UDim2.new(0,8,0,0), BackgroundTransparency=1, Text=tostring(i)..". "..m.Name, Font=Enum.Font.Gotham, TextSize=14, TextColor3=Color3.fromRGB(190,255,190), TextXAlignment=Enum.TextXAlignment.Left})
            local tpBtn = make(row,"TextButton",{Size=UDim2.new(0.22,-10,0,28), Position=UDim2.new(0.7,6,0.12,0), Text="Bring", BackgroundColor3=Color3.fromRGB(0,255,150), Font=Enum.Font.Gotham, TextSize=14})
            make(tpBtn,"UICorner",{CornerRadius=UDim.new(0,6)})
            local rem = make(row,"TextButton",{Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-36,0.12,0), Text="✕", BackgroundColor3=Color3.fromRGB(200,40,40)})
            make(rem,"UICorner",{CornerRadius=UDim.new(0,6)})
            tpBtn.MouseButton1Click:Connect(function()
                local hrp = getHRP()
                if hrp and m.PrimaryPart then
                    m:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(3,1,0))
                end
            end)
            rem.MouseButton1Click:Connect(function()
                -- destroy model and remove from table
                pcall(function() if entry.followerThread and typeof(entry.followerThread) == "thread" then end end)
                pcall(function() if entry.model then entry.model:Destroy() end end)
                table.remove(spawnedPets, i)
                refreshSpawnedList()
            end)
        end
    end
    petScroll.CanvasSize = UDim2.new(0,0,0, math.max(1, #spawnedPets * 56))
end

-- pet follow routine (per pet)
local function startFollow(model)
    if not model or not model.PrimaryPart then return end
    -- add BodyPosition & BodyGyro on PrimaryPart
    local primary = model.PrimaryPart
    local bp = Instance.new("BodyPosition")
    bp.MaxForce = Vector3.new(1e5,1e5,1e5)
    bp.P = 3000
    bp.Parent = primary
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
    bg.Parent = primary

    -- coroutine follow
    local co = coroutine.create(function()
        while model.Parent and primary.Parent do
            local hrp = getHRP()
            if hrp then
                -- follow to player's right side with slight above offset
                local target = hrp.Position + hrp.CFrame.RightVector * 3 + Vector3.new(0,1,0)
                bp.Position = target
                bg.CFrame = CFrame.new(primary.Position, hrp.Position)
            end
            RunService.Heartbeat:Wait()
        end
        -- cleanup when model removed
        pcall(function() bp:Destroy() end)
        pcall(function() bg:Destroy() end)
    end)
    coroutine.resume(co)
    return co
end

-- spawn function
local function spawnPet(name)
    if not name then notify("No pet selected.",1.4); return end
    local template = PET_FOLDER:FindFirstChild(name)
    if not template then notify("Template not found: "..tostring(name),1.6); return end
    local hrp = getHRP()
    if not hrp then notify("Character not ready.",1.4); return end
    local clone = template:Clone()
    clone.Parent = workspace
    -- ensure PrimaryPart exists; if not try set first BasePart
    if not clone.PrimaryPart then
        local p = clone:FindFirstChildWhichIsA("BasePart", true)
        if p then clone.PrimaryPart = p end
    end
    if clone.PrimaryPart then
        clone:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(3,1,0))
    end
    local thread = startFollow(clone)
    table.insert(spawnedPets, {model = clone, followerThread = thread})
    refreshSpawnedList()
    notify("Spawned: "..tostring(name),1.2)
end

-- duplicate function (nearest)
local function duplicatePet(name)
    if not name then notify("No pet selected.",1.4); return end
    local hrp = getHRP()
    if not hrp then notify("Character not ready.",1.4); return end
    local nearest, dmin = nil, math.huge
    for _,c in ipairs(workspace:GetChildren()) do
        if c.Name == name and c.PrimaryPart then
            local d = (c.PrimaryPart.Position - hrp.Position).Magnitude
            if d < dmin and d < 12 then
                nearest, dmin = c, d
            end
        end
    end
    if not nearest then notify("Nearest pet not found within 12 studs.",1.6); return end
    local clone = nearest:Clone()
    clone.Parent = workspace
    if not clone.PrimaryPart then
        local p = clone:FindFirstChildWhichIsA("BasePart", true)
        if p then clone.PrimaryPart = p end
    end
    if clone.PrimaryPart then
        clone:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(4,1,0))
    end
    local thread = startFollow(clone)
    table.insert(spawnedPets, {model = clone, followerThread = thread})
    refreshSpawnedList()
    notify("Duplicated: "..tostring(name),1.2)
end

-- UI callbacks
selectBtn.MouseButton1Click:Connect(function()
    ddOpen = not ddOpen
    ddFrame:TweenSize(UDim2.new(1,0,0, ddOpen and (#petNames * 36) or 0 ), "Out", "Quad", 0.18, true)
end)

spawnBtn.MouseButton1Click:Connect(function()
    spawnPet(selectedPet)
end)

dupBtn.MouseButton1Click:Connect(function()
    duplicatePet(selectedPet)
end)

closeBtn.MouseButton1Click:Connect(function()
    notify("UI closed", 1.0)
    pcall(function() screenGui:Destroy() end)
end)

-- minimize by right-click on header
closeBtn.MouseButton2Click:Connect(function()
    main.Visible = false
    iconFrame.Visible = true
end)
iconFrame.MouseButton1Click:Connect(function()
    main.Visible = true
    iconFrame.Visible = false
end)

-- draggable header (like CP script)
local dragging, dragStart, startPos = false, nil, nil
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInput.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging and dragStart and startPos then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- initial UI state
refreshSpawnedList()
notify("Pet Spawner ready", 1.6)
