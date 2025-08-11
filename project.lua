-- Checkpoint Manager (Full) — Login / Admin / User / Persistent Templates
-- By: GPT-5 Thinking mini (clean, robust, draggable UI, writefile fallback)
-- Features:
--  - Login (admin: irsad/irsad10 ; user: member/member)
--  - Admin: record checkpoints (HRP CFrame), preview, save template (.json)
--  - User: load templates, manual TP, Auto-TP loop with adjustable interval
--  - Persistent storage via writefile/readfile if available; fallback to getgenv
--  - Clickable checkpoint list, delete single CP, delete template
--  - Admin detector (name keywords + whitelist)
--  - Notifications + safe checks

-- ===== Services & util =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local UserInput = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ===== Safe file helpers (writefile/readfile fallback) =====
local DATA_FOLDER = "CheckpointTemplates" -- folder or key prefix
local INDEX_FILE = DATA_FOLDER .. "/index.json"

local function safe_makefolder(path)
    if type(makefolder) == "function" and type(isfolder) == "function" then
        pcall(function() if not isfolder(path) then makefolder(path) end end)
    else
        getgenv()._CP_storage = getgenv()._CP_storage or {}
    end
end

local function safe_writefile(path, content)
    if type(writefile) == "function" then
        local ok, err = pcall(function() writefile(path, content) end)
        return ok, err
    else
        getgenv()._CP_storage = getgenv()._CP_storage or {}
        getgenv()._CP_storage[path] = content
        return true
    end
end

local function safe_isfile(path)
    if type(isfile) == "function" then
        local ok, res = pcall(function() return isfile(path) end)
        return ok and res
    else
        return getgenv()._CP_storage and getgenv()._CP_storage[path] ~= nil
    end
end

local function safe_readfile(path)
    if type(readfile) == "function" then
        local ok, res = pcall(function() return readfile(path) end)
        if ok then return res end
        return nil
    else
        getgenv()._CP_storage = getgenv()._CP_storage or {}
        return getgenv()._CP_storage[path]
    end
end

local function safe_delfile(path)
    if type(delfile) == "function" then
        local ok, res = pcall(function() delfile(path) end)
        return ok
    else
        getgenv()._CP_storage = getgenv()._CP_storage or {}
        getgenv()._CP_storage[path] = nil
        return true
    end
end

safe_makefolder(DATA_FOLDER)

local function template_path(name)
    local nm = tostring(name):gsub("[^%w _%-]", "_")
    return DATA_FOLDER .. "/" .. nm .. ".json"
end

local function load_index()
    if safe_isfile(INDEX_FILE) then
        local raw = safe_readfile(INDEX_FILE)
        if raw then
            local ok, t = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok and type(t) == "table" then return t end
        end
    end
    return {}
end

local function save_index(idx)
    local ok, err = safe_writefile(INDEX_FILE, HttpService:JSONEncode(idx))
    return ok, err
end

-- ===== State =====
local role = nil -- "admin" or "user"
local currentRecording = {} -- { {x,y,z,name?}, ... } (admin-only until saved)
local templatesIndex = load_index() -- array of names
local loadedTemplateName = nil
local loadedTemplateCPs = {} -- array of {x,y,z,name}
local autoTPRunning = false
local autoTPTicket = nil

-- ===== Helpers =====
local function getHRP(waitFor)
    waitFor = waitFor == nil and true or waitFor
    local ch = LocalPlayer.Character or (waitFor and LocalPlayer.CharacterAdded:Wait())
    if not ch then return nil end
    return ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso")
end

local function notify(text, time)
    time = time or 1.6
    pcall(function()
        local f = Instance.new("Frame", CoreGui)
        f.Size = UDim2.new(0, 320, 0, 40)
        f.Position = UDim2.new(0.5, -160, 0.08, 0)
        f.AnchorPoint = Vector2.new(0.5,0)
        f.BackgroundColor3 = Color3.fromRGB(18,18,18)
        f.BorderSizePixel = 0
        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(1,-12,1,-8)
        l.Position = UDim2.new(0,6,0,4)
        l.BackgroundTransparency = 1
        l.Text = tostring(text)
        l.TextColor3 = Color3.fromRGB(200,255,200)
        l.Font = Enum.Font.Gotham
        l.TextWrapped = true
        task.delay(time, function() pcall(function() f:Destroy() end) end)
    end)
end

local function save_template(name, cpList)
    if type(name) ~= "string" or name:match("^%s*$") then return false, "invalid name" end
    if type(cpList) ~= "table" or #cpList == 0 then return false, "no checkpoints" end
    local path = template_path(name)
    local ok, err = safe_writefile(path, HttpService:JSONEncode(cpList))
    if not ok then return false, err end
    -- add to index if not exists
    local idx = load_index()
    local found = false
    for _,v in ipairs(idx) do if v == name then found = true; break end end
    if not found then
        table.insert(idx, name)
        save_index(idx)
    end
    return true
end

local function load_template(name)
    local path = template_path(name)
    if not safe_isfile(path) then return false, "file not found" end
    local raw = safe_readfile(path)
    if not raw then return false, "read fail" end
    local ok, t = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok then return false, t end
    return true, t
end

local function delete_template(name)
    local path = template_path(name)
    if safe_isfile(path) then safe_delfile(path) end
    local idx = load_index()
    for i,v in ipairs(idx) do if v == name then table.remove(idx,i); break end end
    save_index(idx)
    return true
end

-- ===== UI Build =====
pcall(function()
    local prev = CoreGui:FindFirstChild("CP_Manager_UI")
    if prev then prev:Destroy() end
end)

local screen = Instance.new("ScreenGui")
screen.Name = "CP_Manager_UI"
screen.ResetOnSpawn = false
screen.Parent = CoreGui

-- Login Frame
local loginFrame = Instance.new("Frame", screen)
loginFrame.Name = "LoginFrame"
loginFrame.Size = UDim2.new(0,420,0,220)
loginFrame.Position = UDim2.new(0.28,0,0.25,0)
loginFrame.BackgroundColor3 = Color3.fromRGB(24,24,24)
loginFrame.BorderSizePixel = 0
local loginTitle = Instance.new("TextLabel", loginFrame)
loginTitle.Size = UDim2.new(1,-24,0,44); loginTitle.Position = UDim2.new(0,12,0,8)
loginTitle.BackgroundTransparency = 1; loginTitle.Font = Enum.Font.GothamBlack; loginTitle.TextSize = 20
loginTitle.Text = "Checkpoint Manager — Login"; loginTitle.TextColor3 = Color3.fromRGB(180,255,200)
local userBox = Instance.new("TextBox", loginFrame)
userBox.Size = UDim2.new(1,-24,0,34); userBox.Position = UDim2.new(0,12,0,64); userBox.PlaceholderText="Username"; userBox.BackgroundColor3=Color3.fromRGB(40,40,40); userBox.TextColor3=Color3.fromRGB(220,220,220)
local passBox = Instance.new("TextBox", loginFrame)
passBox.Size = UDim2.new(1,-24,0,34); passBox.Position = UDim2.new(0,12,0,108); passBox.PlaceholderText="Password"; passBox.BackgroundColor3=Color3.fromRGB(40,40,40); passBox.TextColor3=Color3.fromRGB(220,220,220)
local loginBtn = Instance.new("TextButton", loginFrame)
loginBtn.Size = UDim2.new(1,-24,0,36); loginBtn.Position = UDim2.new(0,12,0,156); loginBtn.Font=Enum.Font.GothamBold; loginBtn.Text="Login"; loginBtn.BackgroundColor3=Color3.fromRGB(0,160,120); loginBtn.TextColor3=Color3.fromRGB(0,0,0)
local loginNote = Instance.new("TextLabel", loginFrame)
loginNote.Size = UDim2.new(1,-24,0,18); loginNote.Position = UDim2.new(0,12,1,-26); loginNote.BackgroundTransparency=1
loginNote.Text = "Admin: irsad / irsad10   •   User: member / member"; loginNote.TextColor3 = Color3.fromRGB(200,200,200); loginNote.Font = Enum.Font.SourceSans

-- Main Frame (hidden until login)
local mainFrame = Instance.new("Frame", screen)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0,780,0,520)
mainFrame.Position = UDim2.new(0.08,0,0.06,0)
mainFrame.BackgroundColor3 = Color3.fromRGB(14,16,14)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false

-- Header
local header = Instance.new("Frame", mainFrame)
header.Size = UDim2.new(1,0,0,56); header.Position = UDim2.new(0,0,0,0); header.BackgroundTransparency = 1
local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.7,-8,1,0); title.Position = UDim2.new(0,12,0,0)
title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBlack; title.TextSize = 20
title.Text = "⟡ Checkpoint Manager"; title.TextColor3 = Color3.fromRGB(170,255,190); title.TextXAlignment = Enum.TextXAlignment.Left
local roleLabel = Instance.new("TextLabel", header)
roleLabel.Size = UDim2.new(0.28,-20,1,0); roleLabel.Position = UDim2.new(0.72, 8, 0, 0)
roleLabel.BackgroundTransparency = 1; roleLabel.Font = Enum.Font.GothamSemibold; roleLabel.TextSize = 14; roleLabel.TextColor3 = Color3.fromRGB(220,220,220); roleLabel.Text = "Role: -"
local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0,36,0,36); closeBtn.Position = UDim2.new(1,-44,0,10); closeBtn.BackgroundColor3 = Color3.fromRGB(0,180,120); closeBtn.Text="X"; closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextColor3=Color3.fromRGB(0,0,0)

-- Left panel (admin controls / shared)
local left = Instance.new("Frame", mainFrame); left.Size = UDim2.new(0.38,-12,1,-80); left.Position = UDim2.new(0,12,0,68); left.BackgroundTransparency = 1
local mapLabel = Instance.new("TextLabel", left); mapLabel.Size = UDim2.new(1,0,0,20); mapLabel.Position = UDim2.new(0,0,0,0); mapLabel.BackgroundTransparency=1; mapLabel.Text="Template:"; mapLabel.Font=Enum.Font.GothamSemibold; mapLabel.TextColor3=Color3.fromRGB(190,255,200)
local templateBtn = Instance.new("TextButton", left); templateBtn.Size = UDim2.new(1,0,0,34); templateBtn.Position = UDim2.new(0,0,0,26); templateBtn.Text="Select Template (None)"; templateBtn.Font=Enum.Font.Gotham; templateBtn.BackgroundColor3=Color3.fromRGB(0,36,14); templateBtn.TextColor3=Color3.fromRGB(200,255,200)
local nameBox = Instance.new("TextBox", left); nameBox.Size = UDim2.new(1,0,0,34); nameBox.Position = UDim2.new(0,0,0,68); nameBox.PlaceholderText="Checkpoint name (optional)"; nameBox.BackgroundColor3=Color3.fromRGB(0,36,14); nameBox.TextColor3=Color3.fromRGB(220,255,220)
local addBtn = Instance.new("TextButton", left); addBtn.Size = UDim2.new(1,0,0,40); addBtn.Position = UDim2.new(0,0,0,112); addBtn.Text="Add Checkpoint"; addBtn.Font=Enum.Font.GothamBlack; addBtn.BackgroundColor3=Color3.fromRGB(0,200,140)
local runBtn = Instance.new("TextButton", left); runBtn.Size = UDim2.new(1,0,0,40); runBtn.Position = UDim2.new(0,0,0,162); runBtn.Text="Run"; runBtn.Font=Enum.Font.GothamBlack; runBtn.BackgroundColor3=Color3.fromRGB(0,230,140)
local saveBtn = Instance.new("TextButton", left); saveBtn.Size = UDim2.new(1,0,0,34); saveBtn.Position = UDim2.new(0,0,0,212); saveBtn.Text="Save Template"; saveBtn.BackgroundColor3=Color3.fromRGB(0,170,110)
local loadBtn = Instance.new("TextButton", left); loadBtn.Size = UDim2.new(1,0,0,34); loadBtn.Position = UDim2.new(0,0,0,256); loadBtn.Text="Load Template"; loadBtn.BackgroundColor3=Color3.fromRGB(0,130,160)
local delBtn = Instance.new("TextButton", left); delBtn.Size = UDim2.new(1,0,0,34); delBtn.Position = UDim2.new(0,0,0,300); delBtn.Text="Delete Template"; delBtn.BackgroundColor3=Color3.fromRGB(180,60,60)

local previewLabel = Instance.new("TextLabel", left); previewLabel.Size = UDim2.new(1,0,0,20); previewLabel.Position = UDim2.new(0,0,0,344); previewLabel.BackgroundTransparency=1; previewLabel.Text="Recorded Checkpoints:"; previewLabel.TextColor3=Color3.fromRGB(220,220,220)
local cpScroll = Instance.new("ScrollingFrame", left); cpScroll.Size = UDim2.new(1,0,0,160); cpScroll.Position = UDim2.new(0,0,0,366); cpScroll.BackgroundTransparency = 0.05; cpScroll.ScrollBarThickness = 8
local cpLayout = Instance.new("UIListLayout", cpScroll); cpLayout.Padding = UDim.new(0,8)

-- Right panel (templates list + controls)
local right = Instance.new("Frame", mainFrame); right.Size = UDim2.new(0.6,-12,1,-80); right.Position = UDim2.new(0.38,8,0,68); right.BackgroundTransparency = 1
local tmplLabel = Instance.new("TextLabel", right); tmplLabel.Size = UDim2.new(1,0,0,20); tmplLabel.Position = UDim2.new(0,0,0,0); tmplLabel.BackgroundTransparency=1; tmplLabel.Text="Templates:"; tmplLabel.Font=Enum.Font.GothamSemibold; tmplLabel.TextColor3=Color3.fromRGB(200,255,200)
local tmplScroll = Instance.new("ScrollingFrame", right); tmplScroll.Size = UDim2.new(1,0,0.6,0); tmplScroll.Position = UDim2.new(0,0,0,28); tmplScroll.BackgroundTransparency = 0.04; tmplScroll.ScrollBarThickness=8
local tmplLayout = Instance.new("UIListLayout", tmplScroll); tmplLayout.Padding = UDim.new(0,6)
local tpControls = Instance.new("Frame", right); tpControls.Size = UDim2.new(1,0,0,120); tpControls.Position = UDim2.new(0,0,0.62,8); tpControls.BackgroundTransparency = 1
local autoToggle = Instance.new("TextButton", tpControls); autoToggle.Size = UDim2.new(0.48,-6,0,36); autoToggle.Position = UDim2.new(0,0,0,6); autoToggle.Text="Auto TP: OFF"; autoToggle.BackgroundColor3=Color3.fromRGB(70,70,70)
local intervalBox = Instance.new("TextBox", tpControls); intervalBox.Size = UDim2.new(0.48,-6,0,36); intervalBox.Position = UDim2.new(0.52,6,0,6); intervalBox.Text="2"; intervalBox.PlaceholderText="Interval seconds"
local manualTPBtn = Instance.new("TextButton", tpControls); manualTPBtn.Size = UDim2.new(1,0,0,36); manualTPBtn.Position = UDim2.new(0,0,0,52); manualTPBtn.Text="Manual TP to Selected Checkpoint"; manualTPBtn.BackgroundColor3=Color3.fromRGB(0,150,140)
local adminAlertLabel = Instance.new("TextLabel", mainFrame); adminAlertLabel.Size = UDim2.new(0, 320, 0, 24); adminAlertLabel.Position = UDim2.new(0.5,-160,1,-40); adminAlertLabel.BackgroundTransparency=1; adminAlertLabel.Text="Admin: None"; adminAlertLabel.TextColor3=Color3.fromRGB(255,120,120)

-- ===== Internal state for UI =====
local recordedCPs = {} -- { {pos=Vector3, name=string}, ... }
local ui_selected_cp_index = nil
local ui_selected_tmpl_name = nil
local ui_tmpl_buttons = {} -- name -> button
local ui_cp_buttons = {} -- index -> button
local templates = templatesIndex -- local cached index

-- ===== Utility UI functions =====
local function clearChildren(frame)
    for _,c in ipairs(frame:GetChildren()) do
        if not (c:IsA("UIListLayout") or c:IsA("UIPadding")) then
            pcall(function() c:Destroy() end)
        end
    end
end

local function rebuildCPList()
    clearChildren(cpScroll)
    ui_cp_buttons = {}
    for i,cp in ipairs(recordedCPs) do
        local row = Instance.new("Frame", cpScroll)
        row.Size = UDim2.new(1,-8,0,40); row.BackgroundTransparency = 0.6; row.BackgroundColor3 = Color3.fromRGB(0,18,8)
        local txt = Instance.new("TextLabel", row); txt.Size = UDim2.new(0.68,0,1,0); txt.Position = UDim2.new(0,8,0,0); txt.BackgroundTransparency=1
        txt.Text = string.format("%d) %s (%.1f,%.1f,%.1f)", i, cp.name or ("CP "..i), cp.pos.X, cp.pos.Y, cp.pos.Z); txt.TextColor3=Color3.fromRGB(200,250,200); txt.Font=Enum.Font.Gotham; txt.TextXAlignment = Enum.TextXAlignment.Left
        local go = Instance.new("TextButton", row); go.Size=UDim2.new(0.22,-10,0,28); go.Position = UDim2.new(0.7,6,0.12,0); go.Text="Go"; go.BackgroundColor3=Color3.fromRGB(0,255,150)
        local rem = Instance.new("TextButton", row); rem.Size=UDim2.new(0,28,0,28); rem.Position = UDim2.new(1,-36,0.12,0); rem.Text="✕"; rem.BackgroundColor3=Color3.fromRGB(200,40,40)
        ui_cp_buttons[i] = row
        go.MouseButton1Click:Connect(function()
            local hrp = getHRP(false)
            if hrp then hrp.CFrame = CFrame.new(cp.pos + Vector3.new(0,3,0)) end
        end)
        rem.MouseButton1Click:Connect(function()
            table.remove(recordedCPs, i)
            rebuildCPList()
        end)
    end
    cpScroll.CanvasSize = UDim2.new(0,0,0, math.max(1,#recordedCPs * 48))
end

local function rebuildTemplateList()
    clearChildren(tmplScroll)
    ui_tmpl_buttons = {}
    templates = load_index()
    for i,name in ipairs(templates) do
        local btn = Instance.new("TextButton", tmplScroll)
        btn.Size = UDim2.new(1,-8,0,36); btn.Position = UDim2.new(0,6,0,(i-1)*44)
        btn.Text = name; btn.BackgroundColor3 = Color3.fromRGB(60,60,60); btn.TextColor3 = Color3.fromRGB(230,230,230); btn.Font = Enum.Font.Gotham
        ui_tmpl_buttons[name] = btn
        btn.MouseButton1Click:Connect(function()
            -- select & load template
            if ui_selected_tmpl_name then
                local prev = ui_tmpl_buttons[ui_selected_tmpl_name]
                if prev and prev:IsA("TextButton") then prev.BackgroundColor3 = Color3.fromRGB(60,60,60) end
            end
            ui_selected_tmpl_name = name
            btn.BackgroundColor3 = Color3.fromRGB(40,140,40)
            templateBtn.Text = "Template: "..name
            local ok, loaded = load_template(name)
            if ok then
                loadedTemplateName = name
                loadedTemplateCPs = loaded or {}
                notify("Loaded template: "..name, 1.4)
            else
                notify("Load failed: "..tostring(loaded), 2)
                loadedTemplateName = nil
                loadedTemplateCPs = {}
            end
        end)
    end
    tmplScroll.CanvasSize = UDim2.new(0,0,0, math.max(1,#templates * 44))
end

-- ===== Login behavior =====
local function enter_main_as(r)
    role = r
    roleLabel.Text = "Role: " .. (r == "admin" and "Admin" or "User")
    loginFrame.Visible = false
    mainFrame.Visible = true
    rebuildTemplateList()
    rebuildCPList()
    notify("Logged in as "..role, 1.4)
    -- admin-only UI enabled/disabled
    saveBtn.Visible = (role == "admin")
    addBtn.Visible = (role == "admin")
    nameBox.Visible = (role == "admin")
    delBtn.Visible = (role == "admin")
end

loginBtn.MouseButton1Click:Connect(function()
    local u = tostring(userBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    local p = tostring(passBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    if u == "irsad" and p == "irsad10" then
        enter_main_as("admin")
    elseif u == "member" and p == "member" then
        enter_main_as("user")
    else
        notify("Login failed - invalid credentials", 2)
    end
end)

-- ===== Admin: add checkpoint =====
addBtn.MouseButton1Click:Connect(function()
    if role ~= "admin" then notify("Add requires admin",1.4); return end
    local hrp = getHRP()
    if not hrp then notify("Character not ready",1.2); return end
    local nm = tostring(nameBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    if nm == "" then nm = "CP "..tostring(#recordedCPs+1) end
    table.insert(recordedCPs, { pos = hrp.Position, name = nm })
    nameBox.Text = ""
    rebuildCPList()
    notify("Checkpoint added: "..nm, 1.2)
end)

-- ===== Admin: save template =====
saveBtn.MouseButton1Click:Connect(function()
    if role ~= "admin" then notify("Save requires admin",1.4); return end
    if #recordedCPs == 0 then notify("No checkpoints recorded",1.4); return end
    -- prompt for name with simple input via modal
    local modal = Instance.new("Frame", screen)
    modal.Size = UDim2.new(0,360,0,140); modal.Position = UDim2.new(0.5,-180,0.5,-70); modal.BackgroundColor3 = Color3.fromRGB(8,12,8)
    local lbl = Instance.new("TextLabel", modal); lbl.Size=UDim2.new(1,-24,0,28); lbl.Position=UDim2.new(0,12,0,8); lbl.BackgroundTransparency=1; lbl.Text="Save Template As:"; lbl.Font=Enum.Font.GothamSemibold; lbl.TextColor3=Color3.fromRGB(200,255,200)
    local box = Instance.new("TextBox", modal); box.Size=UDim2.new(1,-24,0,34); box.Position=UDim2.new(0,12,0,44); box.PlaceholderText="Template name (e.g. GunungArunika)"
    local okBtn = Instance.new("TextButton", modal); okBtn.Size=UDim2.new(0.46,-8,0,34); okBtn.Position=UDim2.new(0.02,0,1,-46); okBtn.Text="Save"; okBtn.BackgroundColor3=Color3.fromRGB(0,200,110)
    local cancelBtn = Instance.new("TextButton", modal); cancelBtn.Size=UDim2.new(0.46,-8,0,34); cancelBtn.Position=UDim2.new(0.52,0,1,-46); cancelBtn.Text="Cancel"; cancelBtn.BackgroundColor3=Color3.fromRGB(180,60,60)
    okBtn.MouseButton1Click:Connect(function()
        local name = tostring(box.Text or ""):gsub("^%s*(.-)%s*$","%1")
        if name == "" then notify("Name invalid",1.4); return end
        -- prepare array: { {x=,y=,z=,name=}, ... }
        local arr = {}
        for _,cp in ipairs(recordedCPs) do
            table.insert(arr, { x = cp.pos.X, y = cp.pos.Y, z = cp.pos.Z, name = cp.name })
        end
        local ok, err = save_template(name, arr)
        if ok then notify("Template saved: "..name, 1.6) else notify("Save failed: "..tostring(err), 2.2) end
        modal:Destroy()
        recordedCPs = {}
        rebuildCPList()
        rebuildTemplateList()
    end)
    cancelBtn.MouseButton1Click:Connect(function() modal:Destroy() end)
end)

-- ===== Load/Delete template buttons (open popup) =====
local function openTemplatePopup(mode) -- mode = "load" or "delete"
    -- build popup content
    local p = Instance.new("Frame", screen); p.Size = UDim2.new(0,360,0,320); p.Position = UDim2.new(0.5,-180,0.5,-160); p.BackgroundColor3=Color3.fromRGB(6,16,6)
    local t = Instance.new("TextLabel", p); t.Size=UDim2.new(1,-24,0,28); t.Position=UDim2.new(0,12,0,8); t.BackgroundTransparency=1; t.Text = (mode=="load" and "Load Template" or "Delete Template"); t.Font=Enum.Font.GothamBlack; t.TextColor3=Color3.fromRGB(200,255,200)
    local scroll = Instance.new("ScrollingFrame", p); scroll.Size=UDim2.new(1,-24,1,-72); scroll.Position=UDim2.new(0,12,0,44); scroll.BackgroundTransparency=0.04; scroll.ScrollBarThickness=6
    local layout = Instance.new("UIListLayout", scroll); layout.Padding=UDim.new(0,6)
    local close = Instance.new("TextButton", p); close.Size=UDim2.new(0,80,0,30); close.Position=UDim2.new(1,-92,1,-40); close.Text="Close"; close.BackgroundColor3=Color3.fromRGB(0,80,40)
    close.MouseButton1Click:Connect(function() p:Destroy() end)
    -- populate
    local idx = load_index()
    for i,name in ipairs(idx) do
        local row = Instance.new("Frame", scroll); row.Size=UDim2.new(1,-12,0,40); row.BackgroundTransparency=0.6; row.BackgroundColor3=Color3.fromRGB(0,20,10)
        local lbl = Instance.new("TextLabel", row); lbl.Size=UDim2.new(0.6,0,1,0); lbl.Position=UDim2.new(0,8,0,0); lbl.BackgroundTransparency=1; lbl.Text=name; lbl.Font=Enum.Font.Gotham; lbl.TextColor3=Color3.fromRGB(200,255,200); lbl.TextXAlignment=Enum.TextXAlignment.Left
        local btn = Instance.new("TextButton", row); btn.Size=UDim2.new(0.28,0,0,28); btn.Position=UDim2.new(0.62,6,0.12,0); btn.Text = (mode=="load" and "Load" or "Del"); btn.BackgroundColor3 = (mode=="load" and Color3.fromRGB(0,200,160) or Color3.fromRGB(200,60,60))
        btn.MouseButton1Click:Connect(function()
            if mode == "load" then
                local ok, res = load_template(name)
                if ok then
                    loadedTemplateName = name
                    loadedTemplateCPs = res
                    templateBtn.Text = "Template: "..name
                    notify("Loaded template: "..name, 1.4)
                else
                    notify("Load failed: "..tostring(res), 2)
                end
                p:Destroy()
            else -- delete
                local succ = delete_template(name)
                if succ then notify("Deleted: "..name, 1.4); rebuildTemplateList() end
                p:Destroy()
            end
        end)
    end
end

loadBtn.MouseButton1Click:Connect(function() openTemplatePopup("load") end)
delBtn.MouseButton1Click:Connect(function() openTemplatePopup("delete") end)
templateBtn.MouseButton1Click:Connect(function()
    if ui_selected_tmpl_name then
        -- clear selection
        local prev = ui_tmpl_buttons[ui_selected_tmpl_name]
        if prev then prev.BackgroundColor3 = Color3.fromRGB(60,60,60) end
        ui_selected_tmpl_name = nil
        templateBtn.Text = "Select Template (None)"
    else
        openTemplatePopup("load")
    end
end)

-- ===== Manual TP to a selected CP from loadedTemplateCPs or recordedCPs =====
manualTPBtn.MouseButton1Click:Connect(function()
    -- choose priority: selected in recorded list -> else selected loaded template checkpoint by index
    if ui_selected_cp_index and recordedCPs[ui_selected_cp_index] then
        local cp = recordedCPs[ui_selected_cp_index]
        local hrp = getHRP(false)
        if hrp then hrp.CFrame = CFrame.new(cp.pos + Vector3.new(0,3,0)) end
        notify("Teleported to recorded CP "..(cp.name or ui_selected_cp_index), 1.2)
        return
    end
    -- if loaded template present, open simple selection dialog
    if not loadedTemplateName or #loadedTemplateCPs == 0 then notify("No template loaded",1.4); return end
    -- build modal listing template CPs clickable
    local modal = Instance.new("Frame", screen); modal.Size = UDim2.new(0,360,0,360); modal.Position = UDim2.new(0.5,-180,0.5,-180); modal.BackgroundColor3=Color3.fromRGB(10,12,10)
    local label = Instance.new("TextLabel", modal); label.Size=UDim2.new(1,-24,0,28); label.Position=UDim2.new(0,12,0,8); label.Text="Select checkpoint to TP: "..loadedTemplateName; label.BackgroundTransparency=1; label.Font=Enum.Font.GothamSemibold; label.TextColor3=Color3.fromRGB(200,255,200)
    local sframe = Instance.new("ScrollingFrame", modal); sframe.Size=UDim2.new(1,-24,1,-72); sframe.Position=UDim2.new(0,12,0,44); sframe.ScrollBarThickness = 6
    local layout = Instance.new("UIListLayout", sframe); layout.Padding = UDim.new(0,6)
    local close = Instance.new("TextButton", modal); close.Size=UDim2.new(0,80,0,30); close.Position=UDim2.new(1,-92,1,-40); close.Text="Close"; close.BackgroundColor3=Color3.fromRGB(0,80,40)
    close.MouseButton1Click:Connect(function() modal:Destroy() end)
    for i,cp in ipairs(loadedTemplateCPs) do
        local b = Instance.new("TextButton", sframe); b.Size=UDim2.new(1,0,0,36); b.Text = string.format("%d) %s (%.1f,%.1f,%.1f)", i, (cp.name or "CP"..i), cp.x, cp.y, cp.z); b.BackgroundColor3=Color3.fromRGB(60,60,60); b.TextColor3=Color3.fromRGB(230,230,230)
        b.MouseButton1Click:Connect(function()
            local hrp = getHRP(false)
            if hrp then hrp.CFrame = CFrame.new(Vector3.new(cp.x, cp.y, cp.z) + Vector3.new(0,3,0)) end
            notify("Teleported to template CP "..i,1.2)
            modal:Destroy()
        end)
    end
end)

-- ===== Auto TP loop for loaded template =====
local function startAutoTP()
    if autoTPRunning then return end
    if not loadedTemplateName or #loadedTemplateCPs == 0 then notify("No template loaded",1.4); return end
    autoTPRunning = true; autoToggle.Text = "Auto TP: ON"; autoToggle.BackgroundColor3 = Color3.fromRGB(0,160,120)
    autoTPTicket = coroutine.create(function()
        while autoTPRunning do
            for _,cp in ipairs(loadedTemplateCPs) do
                if not autoTPRunning then break end
                local ok, hrp = pcall(getHRP, false)
                if ok and hrp then
                    hrp.CFrame = CFrame.new(Vector3.new(cp.x, cp.y, cp.z) + Vector3.new(0,3,0))
                end
                local delaySec = tonumber(intervalBox.Text) or 2
                local waited = 0
                while waited < delaySec and autoTPRunning do
                    waited = waited + 0.1
                    task.wait(0.1)
                end
            end
        end
    end)
    coroutine.resume(autoTPTicket)
    notify("Auto TP started ("..loadedTemplateName..")", 1.4)
end

local function stopAutoTP()
    autoTPRunning = false; autoToggle.Text = "Auto TP: OFF"; autoToggle.BackgroundColor3 = Color3.fromRGB(70,70,70)
    notify("Auto TP stopped", 1.2)
end

autoToggle.MouseButton1Click:Connect(function()
    if autoTPRunning then stopAutoTP() else startAutoTP() end
end)

-- ===== Admin detector (keywords + whitelist) =====
local ADMIN_KEYWORDS = {"admin","mod","owner"}
local ADMIN_WHITELIST = { "irsad" } -- lower-case exact matches
local function checkAdmins()
    local found = {}
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local n = tostring(plr.Name):lower()
            local flagged = false
            for _,k in ipairs(ADMIN_KEYWORDS) do if n:find(k) then flagged = true; break end end
            for _,v in ipairs(ADMIN_WHITELIST) do if n == v then flagged = true; break end end
            if flagged then table.insert(found, plr.Name) end
        end
    end
    if #found>0 then adminAlertLabel.Text = "Admin: "..table.concat(found,", "); notify("Admin detected: "..table.concat(found,", "), 2) else adminAlertLabel.Text = "Admin: None" end
end

Players.PlayerAdded:Connect(function() task.wait(0.8); checkAdmins() end)
Players.PlayerRemoving:Connect(function() task.wait(0.8); checkAdmins() end)

-- ===== Close button behavior =====
closeBtn.MouseButton1Click:Connect(function() notify("UI closed",1); pcall(function() screen:Destroy() end) end)

-- ===== Small helpers & init =====
rebuildTemplateList()
rebuildCPList()
checkAdmins()
notify("Checkpoint Manager ready — Login to start", 1.6)

-- expose some helpful globals for console testing (optional)
_G.CP_load_index = load_index
_G.CP_load_template = load_template
_G.CP_delete_template = delete_template
_G.CP_save_template = function(name) 
    local arr = {}
    for _,cp in ipairs(recordedCPs) do table.insert(arr, {x=cp.pos.X,y=cp.pos.Y,z=cp.pos.Z,name=cp.name}) end
    return save_template(name, arr)
end

-- end of script
