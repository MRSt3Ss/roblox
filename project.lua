-- Auto TP Checkpoint + Admin Alert (fixed + UI clickable)
-- By GPT (update)
-- Paste ke executor (PC). GUI dibuat manual (tanpa library) supaya pasti muncul.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local UserInput = game:GetService("UserInputService")

-- cleanup old UI
pcall(function()
    local old = CoreGui:FindFirstChild("MountainTPGUI")
    if old then old:Destroy() end
end)

-- CONFIG: admin keywords and explicit admin names you want to monitor
local ADMIN_KEYWORDS = {"admin", "mod", "owner"}  -- any player name containing these (case-insensitive) will be flagged
local ADMIN_WHITELIST = { "irsad" } -- exact names to always flag (lowercase)

-- Utility: lowercase helper
local function lc(s) return tostring(s):lower() end

-- Notification helper (small temporary label)
local function notify(msg, t)
    t = t or 2
    pcall(function()
        local notif = Instance.new("TextLabel")
        notif.Size = UDim2.new(0, 340, 0, 32)
        notif.Position = UDim2.new(0.5, -170, 0.06, 0)
        notif.AnchorPoint = Vector2.new(0.5,0)
        notif.BackgroundColor3 = Color3.fromRGB(18,18,18)
        notif.BorderSizePixel = 0
        notif.TextColor3 = Color3.fromRGB(200,255,200)
        notif.Text = msg
        notif.TextWrapped = true
        notif.Parent = CoreGui
        task.delay(t, function()
            pcall(function() notif:Destroy() end)
        end)
    end)
end

-- create ScreenGui
local screen = Instance.new("ScreenGui")
screen.Name = "MountainTPGUI"
screen.ResetOnSpawn = false
screen.Parent = CoreGui

-- main frame
local frame = Instance.new("Frame", screen)
frame.Size = UDim2.new(0, 420, 0, 320)
frame.Position = UDim2.new(0.28, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
frame.BorderSizePixel = 0
frame.Active = true

-- draggable implementation (robust)
local dragging, dragStart, startPos = false, nil, nil
frame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = inp.Position
        startPos = frame.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInput.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement and dragStart and startPos then
        local delta = inp.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- header
local header = Instance.new("Frame", frame)
header.Size = UDim2.new(1,0,0,40)
header.BackgroundColor3 = Color3.fromRGB(28,28,28)
header.BorderSizePixel = 0

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1,-150,1,0)
title.Position = UDim2.new(0,12,0,0)
title.BackgroundTransparency = 1
title.Text = "Auto TP Checkpoint + Admin Alert"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(200,255,200)
title.TextXAlignment = Enum.TextXAlignment.Left

local btnClose = Instance.new("TextButton", header)
btnClose.Size = UDim2.new(0,120,0,28)
btnClose.Position = UDim2.new(1,-132,0,6)
btnClose.Text = "Close"
btnClose.Font = Enum.Font.GothamBold
btnClose.TextSize = 13
btnClose.BackgroundColor3 = Color3.fromRGB(160,40,40)
btnClose.TextColor3 = Color3.fromRGB(255,255,255)
btnClose.MouseButton1Click:Connect(function() pcall(function() screen:Destroy() end) end)

-- left panel: controls
local left = Instance.new("Frame", frame)
left.Size = UDim2.new(0.45, -10, 1, -50)
left.Position = UDim2.new(0,8,0,50)
left.BackgroundTransparency = 1

local scanBtn = Instance.new("TextButton", left)
scanBtn.Size = UDim2.new(1,0,0,34)
scanBtn.Position = UDim2.new(0,0,0,0)
scanBtn.Text = "Scan Checkpoints"
scanBtn.Font = Enum.Font.Gotham
scanBtn.BackgroundColor3 = Color3.fromRGB(0,120,200)
scanBtn.TextColor3 = Color3.fromRGB(255,255,255)

local autoTPBtn = Instance.new("TextButton", left)
autoTPBtn.Size = UDim2.new(1,0,0,34)
autoTPBtn.Position = UDim2.new(0,0,0,42)
autoTPBtn.Text = "Auto TP: OFF"
autoTPBtn.Font = Enum.Font.Gotham
autoTPBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
autoTPBtn.TextColor3 = Color3.fromRGB(230,230,230)

local intervalLabel = Instance.new("TextLabel", left)
intervalLabel.Size = UDim2.new(1,0,0,20)
intervalLabel.Position = UDim2.new(0,0,0,86)
intervalLabel.Text = "Interval (sec):"
intervalLabel.BackgroundTransparency = 1
intervalLabel.TextColor3 = Color3.fromRGB(220,220,220)
intervalLabel.Font = Enum.Font.Gotham
intervalLabel.TextSize = 14

local intervalBox = Instance.new("TextBox", left)
intervalBox.Size = UDim2.new(1,0,0,30)
intervalBox.Position = UDim2.new(0,0,0,108)
intervalBox.PlaceholderText = "2"
intervalBox.Text = "2"
intervalBox.ClearTextOnFocus = false
intervalBox.BackgroundColor3 = Color3.fromRGB(55,55,55)
intervalBox.TextColor3 = Color3.fromRGB(230,230,230)
intervalBox.Font = Enum.Font.Gotham

local tpBtn = Instance.new("TextButton", left)
tpBtn.Size = UDim2.new(1,0,0,34)
tpBtn.Position = UDim2.new(0,0,0,152)
tpBtn.Text = "Teleport to Selected"
tpBtn.BackgroundColor3 = Color3.fromRGB(0,160,120)
tpBtn.Font = Enum.Font.Gotham
tpBtn.TextColor3 = Color3.fromRGB(0,0,0)

-- admin display
local adminLabel = Instance.new("TextLabel", left)
adminLabel.Size = UDim2.new(1,0,0,28)
adminLabel.Position = UDim2.new(0,0,0,196)
adminLabel.BackgroundColor3 = Color3.fromRGB(30,30,30)
adminLabel.Text = "Admin: None"
adminLabel.TextColor3 = Color3.fromRGB(255,160,160)
adminLabel.Font = Enum.Font.GothamSemibold
adminLabel.TextSize = 14

local refreshEveryLabel = Instance.new("TextLabel", left)
refreshEveryLabel.Size = UDim2.new(1,0,0,18)
refreshEveryLabel.Position = UDim2.new(0,0,0,230)
refreshEveryLabel.BackgroundTransparency = 1
refreshEveryLabel.Text = "Auto-scan every (sec) - 0 = off"
refreshEveryLabel.TextColor3 = Color3.fromRGB(200,200,200)
refreshEveryLabel.Font = Enum.Font.Gotham

local autoscanBox = Instance.new("TextBox", left)
autoscanBox.Size = UDim2.new(1,0,0,26)
autoscanBox.Position = UDim2.new(0,0,0,248)
autoscanBox.PlaceholderText = "0"
autoscanBox.Text = "0"
autoscanBox.ClearTextOnFocus = false
autoscanBox.BackgroundColor3 = Color3.fromRGB(55,55,55)
autoscanBox.TextColor3 = Color3.fromRGB(230,230,230)

-- right panel: list
local right = Instance.new("Frame", frame)
right.Size = UDim2.new(0.55, -16, 1, -50)
right.Position = UDim2.new(0.45, 8, 0, 50)
right.BackgroundTransparency = 1

local rightTitle = Instance.new("TextLabel", right)
rightTitle.Size = UDim2.new(1,0,0,24)
rightTitle.Position = UDim2.new(0,0,0,0)
rightTitle.BackgroundTransparency = 1
rightTitle.Text = "Found Checkpoints"
rightTitle.Font = Enum.Font.GothamSemibold
rightTitle.TextColor3 = Color3.fromRGB(200,200,200)

local listFrame = Instance.new("ScrollingFrame", right)
listFrame.Size = UDim2.new(1,0,1,-30)
listFrame.Position = UDim2.new(0,0,0,28)
listFrame.BackgroundTransparency = 1
listFrame.ScrollBarThickness = 8

local listLayout = Instance.new("UIListLayout", listFrame)
listLayout.Padding = UDim.new(0,6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- state
local checkpoints = {}            -- array of {part = Instance, name=string, pos=Vector3}
local selectedIndex = nil
local autoTP = false
local autoTPThread = nil

-- heuristics: checkpoint name patterns (case-insensitive)
local NAME_PATTERNS = { "checkpoint", "cp", "flag", "spawn" }

-- helper: find if name matches
local function nameMatches(name)
    local s = lc(name)
    for _,p in ipairs(NAME_PATTERNS) do
        if s:find(p) then return true end
    end
    return false
end

-- scan function
local function scanCheckpoints()
    checkpoints = {}
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("SpawnLocation") then
            local okName = false
            if obj.Name and obj.Name ~= "" and nameMatches(obj.Name) then okName = true end
            -- also consider if object has an attribute "Checkpoint" or BoolValue child named "IsCheckpoint"
            if not okName then
                if obj:GetAttribute and obj:GetAttribute("Checkpoint") then okName = true end
                local child = obj:FindFirstChild("IsCheckpoint")
                if child and child:IsA("BoolValue") and child.Value then okName = true end
            end
            if okName then
                table.insert(checkpoints, { part = obj, name = obj.Name or "<part>", pos = (obj:IsA("BasePart") and obj.Position) or (obj:IsA("SpawnLocation") and obj.Position) or obj:GetModelCFrame and obj:GetModelCFrame().p or (obj.CFrame and obj.CFrame.p) or Vector3.new() })
            end
        end
    end
    -- sort by Y (optional) then name
    table.sort(checkpoints, function(a,b)
        if a.pos.Y == b.pos.Y then return a.name < b.name end
        return a.pos.Y < b.pos.Y
    end)
    -- rebuild UI
    for _,c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for i,cp in ipairs(checkpoints) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-12,0,32)
        btn.Position = UDim2.new(0,6,0,(i-1)*38)
        btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        btn.TextColor3 = Color3.fromRGB(230,230,230)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Text = string.format("%d) %s (x:%.1f y:%.1f z:%.1f)", i, cp.name, cp.pos.X, cp.pos.Y, cp.pos.Z)
        btn.Parent = listFrame
        btn.LayoutOrder = i
        btn.MouseButton1Click:Connect(function()
            selectedIndex = i
            -- highlight selection
            for _,ch in ipairs(listFrame:GetChildren()) do
                if ch:IsA("TextButton") then ch.BackgroundColor3 = Color3.fromRGB(60,60,60) end
            end
            btn.BackgroundColor3 = Color3.fromRGB(40,140,40)
        end)
    end
    notify(("[SCAN] %d checkpoint(s) found"):format(#checkpoints), 1.6)
end

-- initial scan
scanCheckpoints()

-- select by function for console if needed
_G.selectCheckpoint = function(n)
    n = tonumber(n)
    if not n or not checkpoints[n] then
        print("Invalid index")
        return
    end
    selectedIndex = n
    print("Selected checkpoint", n, checkpoints[n].name)
end

-- teleport helper
local function teleportTo(pos)
    local ok, err = pcall(function()
        local ch = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso")
        if not hrp then error("HRP not found") end
        -- safe pivot
        hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0))
    end)
    if not ok then notify("Teleport failed: "..tostring(err), 2) end
end

-- TP button
tpBtn.MouseButton1Click:Connect(function()
    if not selectedIndex then
        notify("No checkpoint selected", 1.4); return
    end
    local cp = checkpoints[selectedIndex]
    if cp and cp.pos then
        teleportTo(cp.pos)
        notify("Teleported to: "..cp.name, 1.4)
    end
end)

-- auto-tp coroutine
local function startAutoTP()
    if autoTP then return end
    if #checkpoints == 0 then notify("No checkpoints to TP", 1.4); return end
    autoTP = true
    autoTPBtn.Text = "Auto TP: ON"
    autoTPBtn.BackgroundColor3 = Color3.fromRGB(0,160,120)
    autoTPThread = coroutine.create(function()
        while autoTP do
            for i,cp in ipairs(checkpoints) do
                if not autoTP then break end
                teleportTo(cp.pos)
                task.wait( tonumber(intervalBox.Text) or 2 )
            end
        end
    end)
    coroutine.resume(autoTPThread)
end

local function stopAutoTP()
    autoTP = false
    autoTPBtn.Text = "Auto TP: OFF"
    autoTPBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    notify("Auto TP stopped", 1.2)
end

autoTPBtn.MouseButton1Click:Connect(function()
    if autoTP then stopAutoTP() else startAutoTP() end
end)

-- scan button
scanBtn.MouseButton1Click:Connect(function()
    scanCheckpoints()
end)

-- autoscan interval handler
spawn(function()
    while true do
        local s = tonumber(autoscanBox.Text) or 0
        if s > 0 then
            scanCheckpoints()
            task.wait(s)
        else
            task.wait(1)
        end
    end
end)

-- Admin detector
local function checkAdmins()
    local found = {}
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local name = lc(plr.Name)
            local flagged = false
            for _,k in ipairs(ADMIN_KEYWORDS) do if name:find(k) then flagged = true; break end end
            for _,a in ipairs(ADMIN_WHITELIST) do if name == lc(a) then flagged = true; break end end
            if flagged then table.insert(found, plr.Name) end
        end
    end
    if #found > 0 then
        adminLabel.Text = "Admin: " .. table.concat(found, ", ")
        notify("Admin detected: "..table.concat(found, ", "), 2.2)
    else
        adminLabel.Text = "Admin: None"
    end
end

Players.PlayerAdded:Connect(function(plr) task.wait(0.8); checkAdmins() end)
Players.PlayerRemoving:Connect(function(plr) task.wait(0.8); checkAdmins() end)

-- autoscan on map load (small delay to ensure map populated)
task.delay(0.8, function() scanCheckpoints() checkAdmins() end)

-- final note
print("[MountainTPGUI] Ready. Use Scan -> select -> Teleport. Auto-TP loops checkpoints.")
