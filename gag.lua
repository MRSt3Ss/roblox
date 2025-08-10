-- Pet Spawner & Duplicator with Bypass & Anti-Delete
-- By BonsCodes-style (custom GUI, no external libs)
-- Requirements: ReplicatedStorage.Pets models

-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInput = game:GetService("UserInputService")

-- HELPERS
local player = Players.LocalPlayer
assert(player, "LocalPlayer not found")

-- ensure game loaded & small safety wait
if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(0.15)

-- wait PlayerGui
local PlayerGui = player:WaitForChild("PlayerGui")

-- wait pets folder
local PET_FOLDER
repeat
    PET_FOLDER = ReplicatedStorage:FindFirstChild("Pets")
    RunService.Heartbeat:Wait()
until PET_FOLDER and #PET_FOLDER:GetChildren() > 0

-- utility create function
local function make(parent, class, props)
    local obj = Instance.new(class)
    if props then for k,v in pairs(props) do obj[k] = v end end
    obj.Parent = parent
    return obj
end

-- notification (small)
local function notify(text, t)
    t = t or 1.6
    if not _G.__PetNotifGui then
        -- create simple persistent notif holder in PlayerGui
        local sg = Instance.new("ScreenGui")
        sg.Name = "__PetNotifGui"
        sg.ResetOnSpawn = false
        sg.Parent = PlayerGui
        _G.__PetNotifGui = sg
    end
    local sg = _G.__PetNotifGui
    local frame = make(sg, "Frame", {
        Size = UDim2.new(0,260,0,44),
        Position = UDim2.new(0.5,-130,0.08,0),
        BackgroundTransparency = 0.12,
        BackgroundColor3 = Color3.fromRGB(6,18,8),
        ZIndex = 9999
    })
    make(frame, "UICorner", {CornerRadius = UDim.new(0,8)})
    local lbl = make(frame, "TextLabel", {
        Size = UDim2.new(1,-16,1,-8),
        Position = UDim2.new(0,8,0,6),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(200,255,200),
        TextWrapped = true
    })
    task.delay(t, function()
        pcall(function() frame:Destroy() end)
    end)
end

-- MAIN GUI CREATION
local function CreatePetGUI()
    -- Build ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "Bons_PetSpawner_v1"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 9999

    -- Try parent to CoreGui first (pcall), else PlayerGui
    local ok = pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not ok or not sg.Parent then
        sg.Parent = PlayerGui
    end

    -- main frame
    local main = make(sg, "Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0,380,0,220),
        Position = UDim2.new(0,28,0,120),
        BackgroundColor3 = Color3.fromRGB(6,16,6),
        BackgroundTransparency = 0.06,
        ZIndex = 9999
    })
    make(main, "UICorner", {CornerRadius = UDim.new(0,12)})
    make(main, "UIStroke", {Color = Color3.fromRGB(0,255,150), Thickness = 2, Transparency = 0.16})

    -- header
    local header = make(main, "Frame", {Size = UDim2.new(1,0,0,56), BackgroundTransparency = 1})
    local title = make(header, "TextLabel", {
        Size = UDim2.new(0.7,-8,1,0),
        Position = UDim2.new(0,12,0,0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        TextSize = 18,
        Text = "⟡ Pet Spawner & Duplicator (Bons)",
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

    local miniIcon = make(sg, "TextButton", {
        Name = "MiniIcon",
        Size = UDim2.new(0,56,0,56),
        Position = UDim2.new(0,12,0,12),
        Visible = false,
        BackgroundColor3 = Color3.fromRGB(0,30,12),
        Text = "PS",
        Font = Enum.Font.GothamBlack,
        TextSize = 20,
        TextColor3 = Color3.fromRGB(170,255,190),
        ZIndex = 9999
    })
    make(miniIcon, "UICorner", {CornerRadius = UDim.new(0,10)})

    -- left / right
    local left = make(main, "Frame", {Size = UDim2.new(0.48,-12,1,-80), Position = UDim2.new(0,12,0,68), BackgroundTransparency = 1})
    local right = make(main, "Frame", {Size = UDim2.new(0.5,-12,1,-80), Position = UDim2.new(0.5,6,0,68), BackgroundTransparency = 1})

    -- dropdown
    local selLabel = make(left, "TextLabel", {Size=UDim2.new(1,0,0,18), BackgroundTransparency=1, Text="Select Pet:", Font=Enum.Font.GothamSemibold, TextSize=14, TextColor3=Color3.fromRGB(190,255,200)})
    local selBtn = make(left, "TextButton", {Size=UDim2.new(1,0,0,34), Position=UDim2.new(0,0,0,22), Text="Select Pet", Font=Enum.Font.Gotham, TextSize=14, BackgroundColor3=Color3.fromRGB(0,36,14), TextColor3=Color3.fromRGB(200,255,200)})
    make(selBtn,"UICorner",{CornerRadius=UDim.new(0,8)})
    local selArrow = make(selBtn,"TextLabel",{Size=UDim2.new(0,32,1,0), Position=UDim2.new(1,-32,0,0), BackgroundTransparency=1, Text="▾", Font=Enum.Font.GothamBold, TextColor3=Color3.fromRGB(200,255,200)})

    local ddFrame = make(left,"Frame",{Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,64), ClipsDescendants=true})
    make(ddFrame,"UIListLayout",{Padding=UDim.new(0,6)})

    -- buttons
    local spawnBtn = make(left,"TextButton",{Size=UDim2.new(1,0,0,40), Position=UDim2.new(0,0,0,108), Text="Spawn Selected Pet", Font=Enum.Font.GothamBold, TextSize=16, BackgroundColor3=Color3.fromRGB(0,200,140)})
    make(spawnBtn,"UICorner",{CornerRadius=UDim.new(0,8)})
    local dupeBtn = make(left,"TextButton",{Size=UDim2.new(1,0,0,34), Position=UDim2.new(0,0,0,158), Text="Duplicate Nearest Pet", Font=Enum.Font.GothamSemibold, TextSize=14, BackgroundColor3=Color3.fromRGB(0,180,110)})
    make(dupeBtn,"UICorner",{CornerRadius=UDim.new(0,8)})

    -- right: spawned list
    local infoLabel = make(right,"TextLabel",{Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Text="Spawned Pets", Font=Enum.Font.GothamSemibold, TextSize=14, TextColor3=Color3.fromRGB(200,255,200)})
    local petScroll = make(right,"ScrollingFrame",{Size=UDim2.new(1,0,1,-8), Position=UDim2.new(0,0,0,28), CanvasSize=UDim2.new(0,0,0,0), ScrollBarThickness=8, BackgroundTransparency=0.06, BackgroundColor3=Color3.fromRGB(0,28,10)})
    make(petScroll,"UICorner",{CornerRadius=UDim.new(0,8)})
    make(petScroll,"UIListLayout",{Padding=UDim.new(0,8)})

    -- state
    local petNames = {}
    for _,v in ipairs(PET_FOLDER:GetChildren()) do table.insert(petNames, v.Name) end
    table.sort(petNames)
    local selected = petNames[1]
    local ddOpen = false
    local spawned = {}

    -- helper: populate dropdown
    local function populateDropdown()
        for _,c in ipairs(ddFrame:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
        for _,nm in ipairs(petNames) do
            local row = make(ddFrame,"TextButton",{Size=UDim2.new(1,0,0,30), BackgroundColor3=Color3.fromRGB(0,22,10), Text=nm, Font=Enum.Font.Gotham, TextSize=14, TextColor3=Color3.fromRGB(200,255,200)})
            make(row,"UICorner",{CornerRadius=UDim.new(0,6)})
            row.MouseButton1Click:Connect(function()
                selected = nm
                selBtn.Text = "Pet: "..nm
                ddOpen = false
                ddFrame:TweenSize(UDim2.new(1,0,0,0),"Out","Quad",0.18,true)
            end)
        end
        ddFrame:TweenSize(UDim2.new(1,0,0,0),"Out","Quad",0.01,true)
    end
    populateDropdown()
    selBtn.Text = "Pet: "..tostring(selected or "None")

    -- spawned list refresh
    local function refreshSpawned()
        for _,c in ipairs(petScroll:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
        for i,entry in ipairs(spawned) do
            local m = entry.model
            if m and m.PrimaryPart then
                local row = make(petScroll,"Frame",{Size=UDim2.new(1,-12,0,44), BackgroundColor3=Color3.fromRGB(0,18,8)})
                make(row,"UICorner",{CornerRadius=UDim.new(0,8)})
                local lbl = make(row,"TextLabel",{Size=UDim2.new(0.68,0,1,0), Position=UDim2.new(0,8,0,0), BackgroundTransparency=1, Text=tostring(i)..". "..m.Name, Font=Enum.Font.Gotham, TextSize=14, TextColor3=Color3.fromRGB(190,255,190), TextXAlignment=Enum.TextXAlignment.Left})
                local tp = make(row,"TextButton",{Size=UDim2.new(0.22,-10,0,28), Position=UDim2.new(0.7,6,0.12,0), Text="Bring", BackgroundColor3=Color3.fromRGB(0,255,150)})
                make(tp,"UICorner",{CornerRadius=UDim.new(0,6)})
                local rem = make(row,"TextButton",{Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-36,0.12,0), Text="✕", BackgroundColor3=Color3.fromRGB(200,40,40)})
                make(rem,"UICorner",{CornerRadius=UDim.new(0,6)})
                tp.MouseButton1Click:Connect(function()
                    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and m.PrimaryPart then
                        m:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(3,1,0))
                    end
                end)
                rem.MouseButton1Click:Connect(function()
                    pcall(function() if entry.model then entry.model:Destroy() end end)
                    table.remove(spawned, i)
                    refreshSpawned()
                end)
            end
        end
        petScroll.CanvasSize = UDim2.new(0,0,0, math.max(1, #spawned * 56))
    end

    -- follow routine
    local function startFollow(model)
        if not model then return end
        local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        if not primary then return end
        local bp = Instance.new("BodyPosition", primary)
        bp.MaxForce = Vector3.new(1e5,1e5,1e5)
        bp.P = 3000
        local bg = Instance.new("BodyGyro", primary)
        bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
        local co = coroutine.create(function()
            while primary.Parent and model.Parent do
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local target = hrp.Position + hrp.CFrame.RightVector * 3 + Vector3.new(0,1,0)
                    bp.Position = target
                    bg.CFrame = CFrame.new(primary.Position, hrp.Position)
                end
                RunService.Heartbeat:Wait()
            end
            pcall(function() bp:Destroy() end)
            pcall(function() bg:Destroy() end)
        end)
        coroutine.resume(co)
        return co
    end

    -- spawn & duplicate
    local function spawnPet(name)
        if not name then notify("No pet selected",1.4); return end
        local tmpl = PET_FOLDER:FindFirstChild(name)
        if not tmpl then notify("Template not found: "..tostring(name),1.6); return end
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then notify("Character not ready",1.2); return end
        local clone = tmpl:Clone()
        clone.Parent = workspace
        if not clone.PrimaryPart then
            local p = clone:FindFirstChildWhichIsA("BasePart", true)
            if p then clone.PrimaryPart = p end
        end
        if clone.PrimaryPart then clone:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(3,1,0)) end
        local thread = startFollow(clone)
        table.insert(spawned, {model = clone, followerThread = thread})
        refreshSpawned()
        notify("Spawned "..tostring(name),1.2)
    end

    local function duplicateNearest(name)
        if not name then notify("No pet selected",1.4); return end
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then notify("Character not ready",1.2); return end
        local nearest, dmin = nil, math.huge
        for _,c in ipairs(workspace:GetChildren()) do
            if c.Name == name and c.PrimaryPart then
                local d = (c.PrimaryPart.Position - hrp.Position).Magnitude
                if d < dmin and d < 12 then nearest, dmin = c, d end
            end
        end
        if not nearest then notify("No nearby pet (12 studs)",1.4); return end
        local clone = nearest:Clone()
        clone.Parent = workspace
        if not clone.PrimaryPart then
            local p = clone:FindFirstChildWhichIsA("BasePart", true)
            if p then clone.PrimaryPart = p end
        end
        if clone.PrimaryPart then clone:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(4,1,0)) end
        local thread = startFollow(clone)
        table.insert(spawned, {model = clone, followerThread = thread})
        refreshSpawned()
        notify("Duplicated "..tostring(name),1.2)
    end

    -- UI bindings
    selBtn.MouseButton1Click:Connect(function()
        ddOpen = not ddOpen
        ddFrame:TweenSize(UDim2.new(1,0,0, ddOpen and (#petNames * 36) or 0 ), "Out", "Quad", 0.18, true)
    end)
    spawnBtn.MouseButton1Click:Connect(function() spawnPet(selected) end)
    dupeBtn.MouseButton1Click:Connect(function() duplicateNearest(selected) end)

    -- close / minimize
    closeBtn.MouseButton1Click:Connect(function()
        notify("UI closed",1.0)
        pcall(function() sg:Destroy() end)
    end)
    closeBtn.MouseButton2Click:Connect(function()
        main.Visible = false
        miniIcon.Visible = true
    end)
    miniIcon.MouseButton1Click:Connect(function()
        main.Visible = true
        miniIcon.Visible = false
    end)

    -- drag header
    do
        local dragging, ds, sp = false, nil, nil
        header.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; ds = i.Position; sp = main.Position
                i.Changed:Connect(function()
                    if i.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInput.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement and ds and sp then
                local delta = i.Position - ds
                main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y)
            end
        end)
    end

    -- monitor & bypass: if GUI removed, try to recreate (lightweight)
    local function ensureAlive()
        if not sg.Parent then
            -- recreate by calling CreatePetGUI again once
            task.spawn(function()
                task.wait(0.06)
                pcall(function() CreatePetGUI() end)
            end)
            return false
        end
        return true
    end

    -- connect ancestrychanged to auto-restore
    sg.AncestryChanged:Connect(function()
        task.delay(0.06, function() ensureAlive() end)
    end)

    return sg
end

-- create once
local ok, err = pcall(function() CreatePetGUI() end)
if not ok then
    warn("[PetSpawner] Create failed:", err)
else
    notify("Pet Spawner loaded", 1.4)
end

-- small watchdog that ensures ScreenGui exists every few seconds (light)
task.spawn(function()
    while task.wait(3) do
        -- try to keep a stable GUI; if user deliberately closed, respect: only recreate if no GUI at all with same name in PlayerGui/CoreGui
        local function found()
            for _,g in ipairs(PlayerGui:GetChildren()) do if g.Name == "Bons_PetSpawner_v1" then return true end end
            local core = game:GetService("CoreGui")
            for _,g in ipairs(core:GetChildren()) do if g.Name == "Bons_PetSpawner_v1" then return true end end
            return false
        end
        if not found() then
            -- try recreate once
            pcall(function() CreatePetGUI() end)
        end
    end
end)
