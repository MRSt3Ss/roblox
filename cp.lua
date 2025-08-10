-- Modern Checkpoint Runner (Mewah, Neon Green)
-- Features: draggable, minimize->icon, map dropdown, add named CP, list, run, save/load per map, animations
-- Works with executors supporting file IO (writefile/readfile/isfile/isfolder/makefolder)
-- Author: (you) - tweak as needed

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:FindFirstChild("HumanoidRootPart")

-- update HRP on respawn
player.CharacterAdded:Connect(function(c)
    char = c
    hrp = char:WaitForChild("HumanoidRootPart")
end)

-- storage folder
local FOLDER = "CheckpointRunner"
if (isfolder and not isfolder(FOLDER)) then
    pcall(function() makefolder(FOLDER) end)
end

-- state
local checkpoints = {} -- { {pos = Vector3, name = string} }
local running = false
local minimized = false
local currentMap = "Default"
local uiParent = game.CoreGui -- some executors require CoreGui; change to PlayerGui if needed

-- util save/load
local function saveConfig(mapName)
    if not writefile then return false, "writefile not supported" end
    local data = {}
    for _, cp in ipairs(checkpoints) do
        table.insert(data, {x = cp.pos.X, y = cp.pos.Y, z = cp.pos.Z, name = cp.name})
    end
    local ok, err = pcall(function()
        writefile(FOLDER.."/"..mapName..".json", HttpService:JSONEncode(data))
    end)
    return ok, err
end

local function loadConfig(mapName)
    checkpoints = {}
    if not isfile then return false, "isfile not supported" end
    if not isfile(FOLDER.."/"..mapName..".json") then return false, "file not found" end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(FOLDER.."/"..mapName..".json"))
    end)
    if not ok then return false, decoded end
    for _, v in ipairs(decoded) do
        table.insert(checkpoints, {pos = Vector3.new(v.x, v.y, v.z), name = v.name})
    end
    return true
end

-- helper for nice tweens
local function tweenObject(obj, props, t, style, dir)
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    local info = TweenInfo.new(t or 0.2, style, dir)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

-- UI construction
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CheckpointRunnerUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = uiParent

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, 380, 0, 460)
mainFrame.Position = UDim2.new(0, 30, 0, 120)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 20, 10)
mainFrame.BackgroundTransparency = 0.12
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 14)
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(0,255,150)
mainStroke.Thickness = 2
mainStroke.Transparency = 0.2

-- header
local header = Instance.new("Frame", mainFrame)
header.Name = "Header"; header.Size = UDim2.new(1,0,0,56); header.Position = UDim2.new(0,0,0,0)
header.BackgroundTransparency = 1
local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.7, -10, 1, 0); title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⟡ Checkpoint Runner"
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(170, 255, 180)
title.TextXAlignment = Enum.TextXAlignment.Left

-- version / small label
local ver = Instance.new("TextLabel", header)
ver.Size = UDim2.new(0.3, -12, 1, 0); ver.Position = UDim2.new(0.7, 12, 0, 0)
ver.BackgroundTransparency = 1
ver.Text = "v1.0"
ver.Font = Enum.Font.GothamSemibold
ver.TextSize = 14
ver.TextColor3 = Color3.fromRGB(120,255,160)
ver.TextXAlignment = Enum.TextXAlignment.Right

-- minimize icon (true minimize)
local minIcon = Instance.new("TextButton", header)
minIcon.Size = UDim2.new(0, 36, 0, 36)
minIcon.Position = UDim2.new(1, -44, 0, 10)
minIcon.AnchorPoint = Vector2.new(0,0)
minIcon.Text = "━"
minIcon.Font = Enum.Font.SourceSansBold
minIcon.TextSize = 22
minIcon.TextColor3 = Color3.fromRGB(10,10,10)
minIcon.BackgroundColor3 = Color3.fromRGB(0,255,160)
minIcon.AutoButtonColor = false
minIcon.Name = "MinimizeBtn"
local minCorner = Instance.new("UICorner", minIcon)
minCorner.CornerRadius = UDim.new(0,8)
minIcon.Parent = header

-- container left (controls) and right (list)
local left = Instance.new("Frame", mainFrame)
left.Size = UDim2.new(0.5, -12, 1, -72); left.Position = UDim2.new(0,12,0,64)
left.BackgroundTransparency = 1

local right = Instance.new("Frame", mainFrame)
right.Size = UDim2.new(0.5, -12, 1, -72); right.Position = UDim2.new(0.5, 0, 0, 64)
right.BackgroundTransparency = 1

-- left elements: map selector, name input, add button, run/save/load controls
local mapLabel = Instance.new("TextLabel", left)
mapLabel.Size = UDim2.new(1,0,0,20); mapLabel.Position = UDim2.new(0,0,0,0)
mapLabel.BackgroundTransparency = 1
mapLabel.Text = "Map:"
mapLabel.TextColor3 = Color3.fromRGB(180,255,190)
mapLabel.Font = Enum.Font.GothamSemibold
mapLabel.TextSize = 14
mapLabel.TextXAlignment = Enum.TextXAlignment.Left

-- map dropdown frame
local dropdown = Instance.new("Frame", left)
dropdown.Size = UDim2.new(1, -0, 0, 36)
dropdown.Position = UDim2.new(0,0,0,26)
dropdown.BackgroundColor3 = Color3.fromRGB(0, 40, 16)
dropdown.BackgroundTransparency = 0.05
local ddCorner = Instance.new("UICorner", dropdown); ddCorner.CornerRadius = UDim.new(0,8)
local ddStroke = Instance.new("UIStroke", dropdown); ddStroke.Color = Color3.fromRGB(0,255,150); ddStroke.Transparency = 0.3

local ddLabel = Instance.new("TextLabel", dropdown)
ddLabel.Size = UDim2.new(0.7, -8, 1, 0)
ddLabel.Position = UDim2.new(0, 8, 0, 0)
ddLabel.BackgroundTransparency = 1
ddLabel.Text = currentMap
ddLabel.Font = Enum.Font.Gotham
ddLabel.TextSize = 14
ddLabel.TextColor3 = Color3.fromRGB(200,255,200)
ddLabel.TextXAlignment = Enum.TextXAlignment.Left

local ddBtn = Instance.new("TextButton", dropdown)
ddBtn.Size = UDim2.new(0, 36, 0, 26)
ddBtn.Position = UDim2.new(1, -44, 0, 5)
ddBtn.Text = "▾"
ddBtn.Font = Enum.Font.GothamBold
ddBtn.TextSize = 18
ddBtn.TextColor3 = Color3.fromRGB(10,10,10)
ddBtn.BackgroundColor3 = Color3.fromRGB(0,255,150)
ddBtn.AutoButtonColor = false
local ddCornerBtn = Instance.new("UICorner", ddBtn); ddCornerBtn.CornerRadius = UDim.new(0,6)

-- dropdown menu hidden panel
local ddPanel = Instance.new("Frame", left)
ddPanel.Size = UDim2.new(1,0,0,0)
ddPanel.Position = UDim2.new(0,0,0,64)
ddPanel.ClipsDescendants = true
ddPanel.BackgroundTransparency = 1

local ddList = Instance.new("Frame", ddPanel)
ddList.Size = UDim2.new(1,0,0,0)
ddList.Position = UDim2.new(0,0,0,0)
ddList.BackgroundColor3 = Color3.fromRGB(0,30,12)
local ddListCorner = Instance.new("UICorner", ddList); ddListCorner.CornerRadius = UDim.new(0,8)
local ddListStroke = Instance.new("UIStroke", ddList); ddListStroke.Color = Color3.fromRGB(0,255,150); ddListStroke.Transparency = 0.35

local ddLayout = Instance.new("UIListLayout", ddList)
ddLayout.SortOrder = Enum.SortOrder.LayoutOrder
ddLayout.Padding = UDim.new(0,6)

-- name box
local nameBox = Instance.new("TextBox", left)
nameBox.Size = UDim2.new(1,0,0,34)
nameBox.Position = UDim2.new(0,0,0,64)
nameBox.PlaceholderText = "Nama checkpoint (optional)"
nameBox.BackgroundColor3 = Color3.fromRGB(0,40,14)
nameBox.TextColor3 = Color3.fromRGB(220,255,220)
nameBox.Font = Enum.Font.Gotham
nameBox.TextSize = 14
local nameCorner = Instance.new("UICorner", nameBox); nameCorner.CornerRadius = UDim.new(0,8)
local nameStroke = Instance.new("UIStroke", nameBox); nameStroke.Color = Color3.fromRGB(0,255,150); nameStroke.Transparency = 0.5

-- add button
local addBtn = Instance.new("TextButton", left)
addBtn.Size = UDim2.new(1,0,0,40)
addBtn.Position = UDim2.new(0,0,0,108)
addBtn.Text = "Add Checkpoint"
addBtn.Font = Enum.Font.GothamBold
addBtn.TextSize = 16
addBtn.TextColor3 = Color3.fromRGB(10,10,10)
addBtn.AutoButtonColor = false
addBtn.BackgroundColor3 = Color3.fromRGB(0,255,150)
local addCorner = Instance.new("UICorner", addBtn); addCorner.CornerRadius = UDim.new(0,8)

-- run/stop button
local runBtn = Instance.new("TextButton", left)
runBtn.Size = UDim2.new(1,0,0,40)
runBtn.Position = UDim2.new(0,0,0,156)
runBtn.Text = "Run"
runBtn.Font = Enum.Font.GothamBlack
runBtn.TextSize = 16
runBtn.TextColor3 = Color3.fromRGB(10,10,10)
runBtn.AutoButtonColor = false
runBtn.BackgroundColor3 = Color3.fromRGB(0,255,140)
local runCorner = Instance.new("UICorner", runBtn); runCorner.CornerRadius = UDim.new(0,8)

-- save/load container
local saveBtn = Instance.new("TextButton", left)
saveBtn.Size = UDim2.new(0.48, -6, 0, 34)
saveBtn.Position = UDim2.new(0,0,0,208)
saveBtn.Text = "Save"
saveBtn.Font = Enum.Font.GothamSemibold
saveBtn.TextSize = 14
saveBtn.TextColor3 = Color3.fromRGB(10,10,10)
saveBtn.AutoButtonColor = false
saveBtn.BackgroundColor3 = Color3.fromRGB(0,220,110)
local saveCorner = Instance.new("UICorner", saveBtn); saveCorner.CornerRadius = UDim.new(0,8)

local loadBtn = Instance.new("TextButton", left)
loadBtn.Size = UDim2.new(0.48, -6, 0, 34)
loadBtn.Position = UDim2.new(0.52, 6, 0, 208)
loadBtn.Text = "Load"
loadBtn.Font = Enum.Font.GothamSemibold
loadBtn.TextSize = 14
loadBtn.TextColor3 = Color3.fromRGB(10,10,10)
loadBtn.AutoButtonColor = false
loadBtn.BackgroundColor3 = Color3.fromRGB(0,220,160)
local loadCorner = Instance.new("UICorner", loadBtn); loadCorner.CornerRadius = UDim.new(0,8)

-- right: CP list area with header and scroll
local cpLabel = Instance.new("TextLabel", right)
cpLabel.Size = UDim2.new(1,0,0,20); cpLabel.Position = UDim2.new(0,0,0,0)
cpLabel.BackgroundTransparency = 1
cpLabel.Text = "Checkpoints (0)"
cpLabel.TextColor3 = Color3.fromRGB(200,255,200)
cpLabel.Font = Enum.Font.GothamSemibold
cpLabel.TextSize = 14
cpLabel.TextXAlignment = Enum.TextXAlignment.Left

local cpScroll = Instance.new("ScrollingFrame", right)
cpScroll.Size = UDim2.new(1,0,1,-8); cpScroll.Position = UDim2.new(0,0,0,28)
cpScroll.CanvasSize = UDim2.new(0,0,0,0)
cpScroll.ScrollBarThickness = 8
cpScroll.BackgroundTransparency = 0.05
cpScroll.BackgroundColor3 = Color3.fromRGB(0,30,10)
local cpCorner = Instance.new("UICorner", cpScroll); cpCorner.CornerRadius = UDim.new(0,8)
local cpLayout = Instance.new("UIListLayout", cpScroll)
cpLayout.Padding = UDim.new(0,8)

-- template function for CP entries
local function makeCPEntry(index, cp)
    local btn = Instance.new("Frame")
    btn.Size = UDim2.new(1, -12, 0, 44)
    btn.BackgroundTransparency = 0.6
    btn.BackgroundColor3 = Color3.fromRGB(0, 20, 8)

    local label = Instance.new("TextLabel", btn)
    label.Size = UDim2.new(0.68, 0, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(index)..". "..(cp.name or ("CP "..index))
    label.TextColor3 = Color3.fromRGB(180,255,180)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    local goBtn = Instance.new("TextButton", btn)
    goBtn.Size = UDim2.new(0.28, -8, 0, 30)
    goBtn.Position = UDim2.new(0.7, 0, 0.12, 0)
    goBtn.Text = "Go"
    goBtn.Font = Enum.Font.GothamBold
    goBtn.TextSize = 14
    goBtn.BackgroundColor3 = Color3.fromRGB(0,255,150)
    goBtn.TextColor3 = Color3.fromRGB(10,10,10)
    local goCorner = Instance.new("UICorner", goBtn); goCorner.CornerRadius = UDim.new(0,6)

    local remBtn = Instance.new("TextButton", btn)
    remBtn.Size = UDim2.new(0, 24, 0, 24)
    remBtn.Position = UDim2.new(1, -32, 0, 10)
    remBtn.Text = "✕"
    remBtn.Font = Enum.Font.GothamBold
    remBtn.TextSize = 14
    remBtn.BackgroundColor3 = Color3.fromRGB(200,40,40)
    remBtn.TextColor3 = Color3.fromRGB(255,255,255)
    local remCorner = Instance.new("UICorner", remBtn); remCorner.CornerRadius = UDim.new(0,6)

    -- callbacks
    goBtn.MouseButton1Click:Connect(function()
        if hrp then
            hrp.CFrame = CFrame.new(cp.pos)
        end
    end)
    remBtn.MouseButton1Click:Connect(function()
        table.remove(checkpoints, index)
        refreshList()
    end)

    return btn
end

-- functions for dropdown map list
local function getSavedMaps()
    local maps = {}
    if isfolder then
        local ok, files = pcall(function() return listfiles(FOLDER) end)
        if ok and files then
            for _, f in ipairs(files) do
                local name = f:match("([^/\\]+)%.json$")
                if name then table.insert(maps, name) end
            end
        end
    end
    -- ensure Default exists
    local foundDefault = false
    for _, m in ipairs(maps) do if m == "Default" then foundDefault = true end end
    if not foundDefault then table.insert(maps, 1, "Default") end
    return maps
end

-- populate dropdown
local function populateDropdown()
    ddList:ClearAllChildren()
    local maps = getSavedMaps()
    ddList.Size = UDim2.new(1, 0, 0, (#maps * 36) + 8)
    for i, m in ipairs(maps) do
        local row = Instance.new("TextButton", ddList)
        row.Size = UDim2.new(1, -12, 0, 28)
        row.Position = UDim2.new(0, 6, 0, (i-1)*36 + 6)
        row.BackgroundColor3 = Color3.fromRGB(0, 40, 16)
        row.TextColor3 = Color3.fromRGB(200,255,200)
        row.Text = m
        row.Font = Enum.Font.Gotham
        row.TextSize = 14
        local rc = Instance.new("UICorner", row); rc.CornerRadius = UDim.new(0,6)
        row.MouseButton1Click:Connect(function()
            -- select
            currentMap = m
            ddLabel.Text = currentMap
            -- close dropdown
            tweenObject(ddPanel, {Size = UDim2.new(1,0,0,0)}, 0.18)
        end)
    end
end

-- refresh CP list
function refreshList()
    cpScroll:ClearAllChildren()
    for i, cp in ipairs(checkpoints) do
        local entry = makeCPEntry(i, cp)
        entry.Parent = cpScroll
    end
    cpScroll.CanvasSize = UDim2.new(0, 0, 0, (#checkpoints * 52) + 12)
    cpLabel.Text = "Checkpoints ("..tostring(#checkpoints)..")"
end

-- UI interactions
ddBtn.MouseButton1Click:Connect(function()
    local open = ddPanel.Size.Y.Offset > 0
    if open then
        tweenObject(ddPanel, {Size = UDim2.new(1,0,0,0)}, 0.18)
    else
        populateDropdown()
        tweenObject(ddPanel, {Size = UDim2.new(1,0,0, (#getSavedMaps()*36) + 8)}, 0.22)
    end
end)

-- add CP
addBtn.MouseButton1Click:Connect(function()
    if not hrp then return end
    local nm = nameBox.Text
    if nm == "" then nm = "CP "..tostring(#checkpoints + 1) end
    table.insert(checkpoints, {pos = hrp.Position, name = nm})
    nameBox.Text = ""
    refreshList()
    -- small highlight tween on addBtn
    addBtn.BackgroundColor3 = Color3.fromRGB(0,200,120)
    tweenObject(addBtn, {BackgroundColor3 = Color3.fromRGB(0,255,150)}, 0.25)
end)

-- run/stop
runBtn.MouseButton1Click:Connect(function()
    if running then
        running = false
        runBtn.Text = "Run"
        runBtn.BackgroundColor3 = Color3.fromRGB(0,255,140)
        return
    end
    if #checkpoints == 0 then
        -- flash red
        runBtn.BackgroundColor3 = Color3.fromRGB(220,70,70)
        tweenObject(runBtn, {BackgroundColor3 = Color3.fromRGB(0,255,140)}, 0.5)
        return
    end
    running = true
    runBtn.Text = "Stop"
    runBtn.BackgroundColor3 = Color3.fromRGB(240,80,80)
    coroutine.wrap(function()
        for i, cp in ipairs(checkpoints) do
            if not running then break end
            if hrp then
                -- smooth teleport (tween to position)
                local start = hrp.CFrame
                local target = CFrame.new(cp.pos)
                -- instant move to avoid anti-cheat; adjust method if prefer tweened movement
                hrp.CFrame = target
            end
            -- small wait; could be configurable later
            local elapsed = 0
            while elapsed < 0.9 and running do
                elapsed = elapsed + RunService.Heartbeat:Wait()
            end
        end
        running = false
        runBtn.Text = "Run"
        runBtn.BackgroundColor3 = Color3.fromRGB(0,255,140)
    end)()
end)

-- save/load handlers
saveBtn.MouseButton1Click:Connect(function()
    local ok, err = saveConfig(currentMap)
    if ok then
        saveBtn.Text = "Saved"
        tweenObject(saveBtn, {BackgroundColor3 = Color3.fromRGB(0,200,120)}, 0.3)
        wait(0.9)
        saveBtn.Text = "Save"
        tweenObject(saveBtn, {BackgroundColor3 = Color3.fromRGB(0,220,110)}, 0.3)
    else
        saveBtn.Text = "Err"
        tweenObject(saveBtn, {BackgroundColor3 = Color3.fromRGB(200,40,40)}, 0.3)
        wait(0.9)
        saveBtn.Text = "Save"
        tweenObject(saveBtn, {BackgroundColor3 = Color3.fromRGB(0,220,110)}, 0.3)
    end
    populateDropdown()
end)

loadBtn.MouseButton1Click:Connect(function()
    local ok, err = loadConfig(currentMap)
    if ok then
        loadBtn.Text = "Loaded"
        tweenObject(loadBtn, {BackgroundColor3 = Color3.fromRGB(0,200,120)}, 0.3)
        refreshList()
        wait(0.9)
        loadBtn.Text = "Load"
        tweenObject(loadBtn, {BackgroundColor3 = Color3.fromRGB(0,220,160)}, 0.3)
    else
        loadBtn.Text = "No File"
        tweenObject(loadBtn, {BackgroundColor3 = Color3.fromRGB(200,40,40)}, 0.3)
        wait(0.9)
        loadBtn.Text = "Load"
        tweenObject(loadBtn, {BackgroundColor3 = Color3.fromRGB(0,220,160)}, 0.3)
    end
end)

-- minimize behavior: shrink to icon
minIcon.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        -- animate shrink
        tweenObject(mainFrame, {Size = UDim2.new(0, 60, 0, 60)}, 0.25)
        -- hide children except minIcon area (we'll create an icon frame)
        for _, v in ipairs(mainFrame:GetChildren()) do
            if v ~= minIcon and v ~= header then
                v.Visible = false
            end
        end
        -- shrink header text
        tweenObject(title, {TextTransparency = 1}, 0.2)
        -- move minIcon to center of small frame
        tweenObject(minIcon, {Position = UDim2.new(0.5, -18, 0.5, -18)}, 0.25)
        minIcon.Text = "▢"
    else
        -- restore
        tweenObject(mainFrame, {Size = UDim2.new(0,380,0,460)}, 0.28)
        for _, v in ipairs(mainFrame:GetChildren()) do
            v.Visible = true
        end
        tweenObject(title, {TextTransparency = 0}, 0.25)
        minIcon.Text = "━"
        -- return minIcon position
        tweenObject(minIcon, {Position = UDim2.new(1, -44, 0, 10)}, 0.25)
    end
end)

-- make UI draggable (header drag)
local dragging = false
local dragInput, dragStart, startPos
local function inputBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end
local function inputChanged(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end

header.InputBegan:Connect(inputBegan)
header.InputChanged:Connect(inputChanged)
game:GetService("UserInputService").InputChanged:Connect(function(i)
    inputChanged(i)
end)

-- initial population
populateDropdown()
refreshList()

-- auto-load Default map if exists
pcall(function() loadConfig("Default"); refreshList() end)

-- safety: cleanup on unload if needed
screenGui.Destroying:Connect(function()
    running = false
end)

-- final ready print
print("[CheckpointRunner] UI ready. Map:", currentMap)
