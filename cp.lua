-- Checkpoint Runner - BonsCodes (Mewah & Stable) - FIXED
-- Improvements: fixed closure/index bugs, reliable UI list recreation,
-- safer file checks, better notifications, draggable header fix, minimize as button,
-- small teleport offset to avoid embedding in floor, and general cleanup.

-- ==== Services & Utils ==== 
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInput = game:GetService("UserInputService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local function getHRP()
    char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local FOLDER = "BonsCodes_CP"
-- safe folder creation
if (isfolder and makefolder) then
    pcall(function()
        if not isfolder(FOLDER) then makefolder(FOLDER) end
    end)
end

local function safe_listfiles(path)
    if not listfiles then return {} end
    local ok, res = pcall(listfiles, path)
    if ok and type(res)=="table" then return res end
    return {}
end

local function basename_from_path(path)
    local s = path:match("([^/\\]+)%.json$")
    return s
end

-- helpers: file io
local function save_map(name, checkpoints)
    if not writefile then return false, "writefile not supported" end
    local ok, err = pcall(function()
        local data = {}
        for _,cp in ipairs(checkpoints) do
            table.insert(data, {x=cp.pos.X,y=cp.pos.Y,z=cp.pos.Z,name=cp.name})
        end
        writefile(FOLDER.."/"..name..".json", HttpService:JSONEncode(data))
    end)
    if not ok then return false, err end
    return true
end

local function load_map(name)
    if not isfile then return false, "isfile not supported" end
    local path = FOLDER.."/"..name..".json"
    local okExists, is_exists = pcall(isfile, path)
    if not okExists or not is_exists then return false, "file not found" end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok then return false, data end
    local out = {}
    for _,v in ipairs(data) do
        table.insert(out, {pos = Vector3.new(v.x, v.y, v.z), name = v.name})
    end
    return true, out
end

local function delete_map(name)
    if not isfile or not delfile then return false, "delete not supported" end
    local path = FOLDER.."/"..name..".json"
    local okExists, is_exists = pcall(isfile, path)
    if not okExists or not is_exists then return false, "file not exists" end
    local ok, err = pcall(function() delfile(path) end)
    return ok, err
end

local function get_saved_maps()
    local out = {}
    if not isfolder or not listfiles then
        return out
    end
    local files = safe_listfiles(FOLDER)
    for _,f in ipairs(files) do
        local n = basename_from_path(f)
        if n then table.insert(out, n) end
    end
    -- ensure Default exists in list (optional)
    local hasDefault = false
    for _,m in ipairs(out) do if m=="Default" then hasDefault=true end end
    if not hasDefault then table.insert(out, 1, "Default") end
    return out
end

-- tween helper
local function tween(obj, props, t)
    t = t or 0.2
    local info = TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    info:Play()
    return info
end

-- ==== UI Build ====
local uiParent = game.CoreGui -- change if needed: player:WaitForChild("PlayerGui")

-- ensure any previous instance removed
pcall(function() local prev = uiParent:FindFirstChild("BonsCodes_CheckpointRunner") if prev then prev:Destroy() end end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BonsCodes_CheckpointRunner"
screenGui.ResetOnSpawn = false
screenGui.Parent = uiParent

-- main frame
local main = Instance.new("Frame")
main.Name = "MainFrame"
main.Size = UDim2.new(0,380,0,480)
main.Position = UDim2.new(0,28,0,120)
main.BackgroundColor3 = Color3.fromRGB(8,16,8)
main.BackgroundTransparency = 0.08
main.BorderSizePixel = 0
main.Parent = screenGui
local mainCorner = Instance.new("UICorner", main); mainCorner.CornerRadius = UDim.new(0,14)
local mainStroke = Instance.new("UIStroke", main); mainStroke.Color = Color3.fromRGB(0,255,150); mainStroke.Thickness = 2; mainStroke.Transparency = 0.15

-- header
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,56); header.Position = UDim2.new(0,0,0,0); header.BackgroundTransparency = 1
local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.7,-8,1,0); title.Position = UDim2.new(0,12,0,0)
title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBlack; title.TextSize = 20
title.Text = "⟡ Checkpoint Runner   |   By BonsCodes"
title.TextColor3 = Color3.fromRGB(170,255,190); title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0,36,0,36); closeBtn.Position = UDim2.new(1,-44,0,10)
closeBtn.BackgroundColor3 = Color3.fromRGB(0,255,150); closeBtn.Text = "━"; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 18
local closeCorner = Instance.new("UICorner", closeBtn); closeCorner.CornerRadius = UDim.new(0,8)

-- minimize icon (small button when minimized) - use TextButton so clickable directly
local iconFrame = Instance.new("TextButton", screenGui)
iconFrame.Name = "MiniIcon"
iconFrame.Size = UDim2.new(0,56,0,56)
iconFrame.Position = UDim2.new(0,12,0,12)
iconFrame.Visible = false
iconFrame.BackgroundColor3 = Color3.fromRGB(0,30,12)
iconFrame.BackgroundTransparency = 0.06
local iconCorner = Instance.new("UICorner", iconFrame); iconCorner.CornerRadius = UDim.new(0,10)
iconFrame.Text = "CR"
iconFrame.Font = Enum.Font.GothamBlack
iconFrame.TextSize = 20
iconFrame.TextColor3 = Color3.fromRGB(170,255,190)

-- left / right panels
local left = Instance.new("Frame", main); left.Size = UDim2.new(0.48,-12,1,-80); left.Position = UDim2.new(0,12,0,68); left.BackgroundTransparency = 1
local right = Instance.new("Frame", main); right.Size = UDim2.new(0.5,-12,1,-80); right.Position = UDim2.new(0.5,6,0,68); right.BackgroundTransparency = 1

-- map controls
local mapLabel = Instance.new("TextLabel", left)
mapLabel.Size = UDim2.new(1,0,0,18); mapLabel.Position = UDim2.new(0,0,0,0)
mapLabel.BackgroundTransparency = 1; mapLabel.Text = "Map:"; mapLabel.Font = Enum.Font.GothamSemibold; mapLabel.TextSize = 14; mapLabel.TextColor3 = Color3.fromRGB(190,255,200)

local mapBtn = Instance.new("TextButton", left)
mapBtn.Size = UDim2.new(1,0,0,34); mapBtn.Position = UDim2.new(0,0,0,22)
mapBtn.Text = "Select Map (Default)"; mapBtn.Font = Enum.Font.Gotham; mapBtn.TextSize = 14
mapBtn.BackgroundColor3 = Color3.fromRGB(0,36,14); mapBtn.TextColor3 = Color3.fromRGB(200,255,200)
local mapCorner = Instance.new("UICorner", mapBtn); mapCorner.CornerRadius = UDim.new(0,8)
local mapArrow = Instance.new("TextLabel", mapBtn); mapArrow.Size = UDim2.new(0,32,1,0); mapArrow.Position = UDim2.new(1,-32,0,0); mapArrow.Text = "▾"; mapArrow.BackgroundTransparency = 1; mapArrow.Font = Enum.Font.GothamBold; mapArrow.TextColor3 = Color3.fromRGB(200,255,200)

-- name input / add / run / save/load/delete
local nameBox = Instance.new("TextBox", left)
nameBox.Size = UDim2.new(1,0,0,34); nameBox.Position = UDim2.new(0,0,0,64)
nameBox.PlaceholderText = "Checkpoint name (optional)"; nameBox.Text = ""; nameBox.Font = Enum.Font.Gotham; nameBox.TextSize = 14
nameBox.BackgroundColor3 = Color3.fromRGB(0,36,14); nameBox.TextColor3 = Color3.fromRGB(220,255,220)
Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0,8)

local addBtn = Instance.new("TextButton", left)
addBtn.Size = UDim2.new(1,0,0,40); addBtn.Position = UDim2.new(0,0,0,108)
addBtn.Text = "Add Checkpoint"; addBtn.Font = Enum.Font.GothamBold; addBtn.TextSize = 16
addBtn.BackgroundColor3 = Color3.fromRGB(0,255,150); addBtn.TextColor3 = Color3.fromRGB(10,10,10)
Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0,8)

local runBtn = Instance.new("TextButton", left)
runBtn.Size = UDim2.new(1,0,0,40); runBtn.Position = UDim2.new(0,0,0,158)
runBtn.Text = "Run"; runBtn.Font = Enum.Font.GothamBlack; runBtn.TextSize = 16
runBtn.BackgroundColor3 = Color3.fromRGB(0,230,140); runBtn.TextColor3 = Color3.fromRGB(10,10,10)
Instance.new("UICorner", runBtn).CornerRadius = UDim.new(0,8)

local saveBtn = Instance.new("TextButton", left)
saveBtn.Size = UDim2.new(1,0,0,34); saveBtn.Position = UDim2.new(0,0,0,210)
saveBtn.Text = "Save Map"; saveBtn.Font = Enum.Font.GothamSemibold; saveBtn.TextSize = 14
saveBtn.BackgroundColor3 = Color3.fromRGB(0,200,110); saveBtn.TextColor3 = Color3.fromRGB(10,10,10)
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0,8)

local loadBtn = Instance.new("TextButton", left)
loadBtn.Size = UDim2.new(1,0,0,34); loadBtn.Position = UDim2.new(0,0,0,254)
loadBtn.Text = "Load Map"; loadBtn.Font = Enum.Font.GothamSemibold; loadBtn.TextSize = 14
loadBtn.BackgroundColor3 = Color3.fromRGB(0,200,160); loadBtn.TextColor3 = Color3.fromRGB(10,10,10)
Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0,8)

local delBtn = Instance.new("TextButton", left)
delBtn.Size = UDim2.new(1,0,0,34); delBtn.Position = UDim2.new(0,0,0,298)
delBtn.Text = "Delete Map"; delBtn.Font = Enum.Font.GothamSemibold; delBtn.TextSize = 14
delBtn.BackgroundColor3 = Color3.fromRGB(200,60,60); delBtn.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0,8)

-- right: checkpoint list header
local cpLabel = Instance.new("TextLabel", right)
cpLabel.Size = UDim2.new(1,0,0,20); cpLabel.Position = UDim2.new(0,0,0,0); cpLabel.BackgroundTransparency = 1
cpLabel.Font = Enum.Font.GothamSemibold; cpLabel.TextSize = 14; cpLabel.TextColor3 = Color3.fromRGB(200,255,200)
cpLabel.Text = "Checkpoints (0)"

local cpScroll = Instance.new("ScrollingFrame", right)
cpScroll.Size = UDim2.new(1,0,1,-8); cpScroll.Position = UDim2.new(0,0,0,28)
cpScroll.CanvasSize = UDim2.new(0,0,0,0); cpScroll.ScrollBarThickness = 8
cpScroll.BackgroundTransparency = 0.06; cpScroll.BackgroundColor3 = Color3.fromRGB(0,28,10)
Instance.new("UICorner", cpScroll).CornerRadius = UDim.new(0,8)
local cpLayout = Instance.new("UIListLayout", cpScroll); cpLayout.Padding = UDim.new(0,8); cpLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- popup frame (hidden) for selecting map to load/delete
local popup = Instance.new("Frame", screenGui)
popup.Size = UDim2.new(0, 360, 0, 280)
popup.Position = UDim2.new(0.5, -180, 0.5, -140)
popup.BackgroundColor3 = Color3.fromRGB(6,16,6)
popup.Visible = false
popup.ZIndex = 50
local popCorner = Instance.new("UICorner", popup); popCorner.CornerRadius = UDim.new(0,10)
local popStroke = Instance.new("UIStroke", popup); popStroke.Color = Color3.fromRGB(0,255,150); popStroke.Transparency = 0.18

local popTitle = Instance.new("TextLabel", popup)
popTitle.Size = UDim2.new(1, -24, 0, 30); popTitle.Position = UDim2.new(0,12,0,8); popTitle.BackgroundTransparency = 1
popTitle.Text = "Saved Maps"; popTitle.Font = Enum.Font.GothamBlack; popTitle.TextSize = 16; popTitle.TextColor3 = Color3.fromRGB(200,255,200)

local popScroll = Instance.new("ScrollingFrame", popup)
popScroll.Size = UDim2.new(1, -24, 1, -68); popScroll.Position = UDim2.new(0,12,0,46); popScroll.CanvasSize = UDim2.new(0,0,0,0)
popScroll.BackgroundTransparency = 0.04; popScroll.ScrollBarThickness = 6
Instance.new("UICorner", popScroll).CornerRadius = UDim.new(0,8)
local popLayout = Instance.new("UIListLayout", popScroll); popLayout.Padding = UDim.new(0,6)

local popClose = Instance.new("TextButton", popup)
popClose.Size = UDim2.new(0, 80, 0, 30); popClose.Position = UDim2.new(1, -92, 1, -40)
popClose.Text = "Close"; popClose.Font = Enum.Font.GothamSemibold; popClose.TextSize = 14
popClose.BackgroundColor3 = Color3.fromRGB(0,80,40); popClose.TextColor3 = Color3.fromRGB(200,255,200)
Instance.new("UICorner", popClose).CornerRadius = UDim.new(0,8)

-- input popup when saving new map name
local namePopup = Instance.new("Frame", screenGui)
namePopup.Size = UDim2.new(0, 360, 0, 160); namePopup.Position = UDim2.new(0.5,-180,0.5,-80)
namePopup.BackgroundColor3 = Color3.fromRGB(6,16,6); namePopup.Visible = false
Instance.new("UICorner", namePopup).CornerRadius = UDim.new(0,10)
local npLabel = Instance.new("TextLabel", namePopup)
npLabel.Size = UDim2.new(1,-24,0,30); npLabel.Position = UDim2.new(0,12,0,12)
npLabel.Text = "Save Map As:"; npLabel.Font = Enum.Font.GothamSemibold; npLabel.TextColor3 = Color3.fromRGB(200,255,200)
local npBox = Instance.new("TextBox", namePopup)
npBox.Size = UDim2.new(1,-24,0,34); npBox.Position = UDim2.new(0,12,0,50)
npBox.PlaceholderText = "Map name (ex: GunungA)"; npBox.Font = Enum.Font.Gotham; npBox.TextSize = 14
Instance.new("UICorner", npBox).CornerRadius = UDim.new(0,8)
local npSave = Instance.new("TextButton", namePopup)
npSave.Size = UDim2.new(0.46,-8,0,34); npSave.Position = UDim2.new(0.02,0,1,-46)
npSave.Text = "Save"; npSave.Font = Enum.Font.GothamSemibold; npSave.BackgroundColor3 = Color3.fromRGB(0,200,110)
npSave.TextColor3 = Color3.fromRGB(10,10,10); Instance.new("UICorner", npSave).CornerRadius = UDim.new(0,8)
local npCancel = Instance.new("TextButton", namePopup)
npCancel.Size = UDim2.new(0.46,-8,0,34); npCancel.Position = UDim2.new(0.52,0,1,-46)
npCancel.Text = "Cancel"; npCancel.Font = Enum.Font.GothamSemibold; npCancel.BackgroundColor3 = Color3.fromRGB(200,60,60)
npCancel.TextColor3 = Color3.fromRGB(255,255,255); Instance.new("UICorner", npCancel).CornerRadius = UDim.new(0,8)

-- ==== State ====
local checkpoints = {}
local running = false
local selectedMap = "Default"
mapBtn.Text = "Map: "..selectedMap

-- notification small popup (safer)
local function notify(text, time)
    time = time or 1.6
    if not screenGui or not screenGui.Parent then return end
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 260, 0, 44)
    notif.Position = UDim2.new(0.5, -130, 0.06, 0)
    notif.AnchorPoint = Vector2.new(0.5, 0)
    notif.BackgroundTransparency = 0.12
    notif.BackgroundColor3 = Color3.fromRGB(6,18,8)
    notif.BorderSizePixel = 0
    notif.Parent = screenGui
    local uic = Instance.new("UICorner", notif); uic.CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", notif); stroke.Color = Color3.fromRGB(0,255,150); stroke.Transparency = 0.4
    local label = Instance.new("TextLabel", notif)
    label.Size = UDim2.new(1, -16, 1, -8)
    label.Position = UDim2.new(0,8,0,6)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(200,255,200)
    label.TextWrapped = true
    tween(notif, {Position = UDim2.new(0.5, -130, 0.08, 8)}, 0.18)
    delay(time, function()
        if notif and notif.Parent then
            tween(notif, {Position = UDim2.new(0.5, -130, 0.02, -40), BackgroundTransparency = 1}, 0.28)
            wait(0.32)
            pcall(function() notif:Destroy() end)
        end
    end)
end

-- functions to refresh lists
local function refreshCPList()
    -- clear all except the layout, then recreate layout to avoid stale references
    for _,child in ipairs(cpScroll:GetChildren()) do
        child:Destroy()
    end
    cpLayout = Instance.new("UIListLayout", cpScroll); cpLayout.Padding = UDim.new(0,8); cpLayout.SortOrder = Enum.SortOrder.LayoutOrder

    for i,cp in ipairs(checkpoints) do
        local idx = i -- capture index for callbacks
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,-12,0,48); row.BackgroundTransparency = 0.6; row.BackgroundColor3 = Color3.fromRGB(0,18,8)
        row.Parent = cpScroll
        local rCorner = Instance.new("UICorner", row); rCorner.CornerRadius = UDim.new(0,8)
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0.68,0,1,0); lbl.Position = UDim2.new(0,8,0,0); lbl.BackgroundTransparency = 1
        lbl.Text = tostring(idx)..". "..(cp.name or ("CP "..idx)); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(190,255,190); lbl.TextXAlignment = Enum.TextXAlignment.Left
        local go = Instance.new("TextButton", row)
        go.Size = UDim2.new(0.22, -10, 0, 30); go.Position = UDim2.new(0.7, 6, 0.12, 0); go.Text = "Go"; go.BackgroundColor3 = Color3.fromRGB(0,255,150)
        local goCorner = Instance.new("UICorner", go); goCorner.CornerRadius = UDim.new(0,6)
        local rem = Instance.new("TextButton", row)
        rem.Size = UDim2.new(0,28,0,28); rem.Position = UDim2.new(1,-36,0.12,0); rem.Text = "✕"; rem.BackgroundColor3 = Color3.fromRGB(200,40,40)
        Instance.new("UICorner", rem).CornerRadius = UDim.new(0,6)
        -- callbacks (use captured idx)
        go.MouseButton1Click:Connect(function()
            local hrp = getHRP()
            if hrp and checkpoints[idx] and checkpoints[idx].pos then
                -- teleport slightly above to avoid clipping
                hrp.CFrame = CFrame.new(checkpoints[idx].pos + Vector3.new(0,3,0))
            end
        end)
        rem.MouseButton1Click:Connect(function()
            table.remove(checkpoints, idx)
            refreshCPList()
            cpLabel.Text = "Checkpoints ("..#checkpoints..")"
        end)
    end
    cpScroll.CanvasSize = UDim2.new(0,0,0, math.max(1, #checkpoints * 58))
    cpLabel.Text = "Checkpoints ("..#checkpoints..")"
end

local function refreshMapPopup()
    for _,child in ipairs(popScroll:GetChildren()) do child:Destroy() end
    popLayout = Instance.new("UIListLayout", popScroll); popLayout.Padding = UDim.new(0,6)

    local maps = get_saved_maps()
    for _,m in ipairs(maps) do
        local row = Instance.new("Frame", popScroll); row.Size = UDim2.new(1,-12,0,40); row.BackgroundTransparency = 0.6; row.BackgroundColor3 = Color3.fromRGB(0,22,10)
        local rCorner = Instance.new("UICorner", row); rCorner.CornerRadius = UDim.new(0,6)
        local lbl = Instance.new("TextLabel", row); lbl.Size = UDim2.new(0.6,0,1,0); lbl.Position = UDim2.new(0,8,0,0)
        lbl.BackgroundTransparency = 1; lbl.Text = m; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(200,255,200); lbl.TextXAlignment = Enum.TextXAlignment.Left
        local loadb = Instance.new("TextButton", row); loadb.Size = UDim2.new(0.18,0,0,28); loadb.Position = UDim2.new(0.62,6,0.12,0); loadb.Text = "Load"; loadb.BackgroundColor3 = Color3.fromRGB(0,200,160)
        local delb = Instance.new("TextButton", row); delb.Size = UDim2.new(0.18,0,0,28); delb.Position = UDim2.new(0.82, -6, 0.12,0); delb.Text = "Del"; delb.BackgroundColor3 = Color3.fromRGB(200,60,60)
        Instance.new("UICorner", loadb).CornerRadius = UDim.new(0,6); Instance.new("UICorner", delb).CornerRadius = UDim.new(0,6)
        local mapName = m -- capture
        loadb.MouseButton1Click:Connect(function()
            local ok, out = load_map(mapName)
            if ok then
                checkpoints = out
                refreshCPList()
                selectedMap = mapName
                mapBtn.Text = "Map: "..selectedMap
                notify("Loaded map: "..mapName, 1.4)
                popup.Visible = false
            else
                notify("Failed to load: "..tostring(out), 1.6)
            end
        end)
        delb.MouseButton1Click:Connect(function()
            local ok, err = delete_map(mapName)
            if ok then
                notify("Deleted map: "..mapName, 1.2)
                refreshMapPopup()
            else
                notify("Delete failed: "..tostring(err), 1.6)
            end
        end)
    end
    popScroll.CanvasSize = UDim2.new(0,0,0, math.max(1, #maps * 48))
end

-- popup close
popClose.MouseButton1Click:Connect(function() popup.Visible = false end)

-- namePopup handlers
npCancel.MouseButton1Click:Connect(function() namePopup.Visible = false end)
npSave.MouseButton1Click:Connect(function()
    local nm = tostring(npBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    if nm == "" then notify("Masukkan nama map valid.", 1.4); return end
    local ok, err = save_map(nm, checkpoints)
    if ok then
        notify("Saved map: "..nm, 1.4)
        selectedMap = nm; mapBtn.Text = "Map: "..selectedMap
        namePopup.Visible = false
        npBox.Text = ""
    else
        notify("Save failed: "..tostring(err), 2)
    end
end)

-- button behavior
addBtn.MouseButton1Click:Connect(function()
    local hrp = getHRP()
    if not hrp then notify("Character not ready.", 1.4); return end
    local nm = tostring(nameBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    if nm == "" then nm = "CP "..tostring(#checkpoints + 1) end
    table.insert(checkpoints, {pos = hrp.Position, name = nm})
    nameBox.Text = ""
    refreshCPList()
    notify("Added "..nm, 1.0)
end)

runBtn.MouseButton1Click:Connect(function()
    if running then
        running = false
        runBtn.Text = "Run"
        runBtn.BackgroundColor3 = Color3.fromRGB(0,230,140)
        notify("Stopped", 0.8)
        return
    end
    if #checkpoints == 0 then notify("No checkpoints to run.", 1.2); return end
    running = true; runBtn.Text = "Stop"; runBtn.BackgroundColor3 = Color3.fromRGB(240,80,80)
    coroutine.wrap(function()
        for i,cp in ipairs(checkpoints) do
            if not running then break end
            local hrp = getHRP()
            if hrp and cp and cp.pos then
                hrp.CFrame = CFrame.new(cp.pos + Vector3.new(0,3,0))
            end
            local elapsed = 0
            while elapsed < 0.9 and running do elapsed = elapsed + RunService.Heartbeat:Wait() end
        end
        running = false; runBtn.Text = "Run"; runBtn.BackgroundColor3 = Color3.fromRGB(0,230,140)
        notify("Run finished", 1.2)
    end)()
end)

saveBtn.MouseButton1Click:Connect(function()
    namePopup.Visible = true
    npBox.Text = selectedMap ~= "" and selectedMap or ""
end)

loadBtn.MouseButton1Click:Connect(function()
    refreshMapPopup()
    popup.Visible = true
end)

delBtn.MouseButton1Click:Connect(function()
    refreshMapPopup()
    popup.Visible = true
end)

mapBtn.MouseButton1Click:Connect(function()
    refreshMapPopup()
    popup.Visible = true
end)

-- close: notify BEFORE destroy so user sees message
closeBtn.MouseButton1Click:Connect(function()
    notify("UI closed", 1.0)
    pcall(function() screenGui:Destroy() end)
end)

-- minimize behavior (right click) - keep as right click + main draggable
closeBtn.MouseButton2Click:Connect(function()
    main.Visible = false; iconFrame.Visible = true
end)
iconFrame.MouseButton1Click:Connect(function()
    main.Visible = true; iconFrame.Visible = false
end)

-- drag main by header (improved handling)
local dragging, dragStart, startPos = false, nil, nil
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = main.Position
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

-- initial refresh
refreshCPList()
refreshMapPopup()

-- auto load Default if exists
local ok, res = load_map("Default")
if ok then checkpoints = res; refreshCPList(); selectedMap = "Default"; mapBtn.Text = "Map: "..selectedMap end

notify("Checkpoint Runner ready — By BonsCodes", 1.6)
print("[BonsCodes] Checkpoint Runner ready")
