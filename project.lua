-- Grow-a-Garden / Naik Gunung Checkpoint Manager (Admin + User)
-- Persistent templates via writefile/readfile if available.
-- Dragable GUI, login, admin recording, user auto-TP.
-- By: Abangmu

-- ===== Services & Utils =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- File storage config
local FOLDER = "GAG_Checkpoints"
local LIST_FILE = FOLDER .. "/templates_index.json"

-- safe file helpers (support executors with writefile/readfile/isfolder/listfiles/delfile)
local function safe_makefolder(path)
    if type(makefolder) == "function" and type(isfolder) == "function" then
        pcall(function() if not isfolder(path) then makefolder(path) end end)
    end
end
local function safe_writefile(path, content)
    if type(writefile) == "function" then
        local ok, err = pcall(function() writefile(path, content) end)
        return ok, err
    else
        -- fallback to getgenv storage
        getgenv()._GAG_storage = getgenv()._GAG_storage or {}
        getgenv()._GAG_storage[path] = content
        return true
    end
end
local function safe_isfile(path)
    if type(isfile) == "function" then
        local ok, res = pcall(function() return isfile(path) end)
        return ok and res
    else
        return getgenv()._GAG_storage and getgenv()._GAG_storage[path] ~= nil
    end
end
local function safe_readfile(path)
    if type(readfile) == "function" then
        local ok, res = pcall(function() return readfile(path) end)
        return ok and res or nil
    else
        return getgenv()._GAG_storage and getgenv()._GAG_storage[path] or nil
    end
end
local function safe_delfile(path)
    if type(delfile) == "function" then
        local ok, res = pcall(function() delfile(path) end)
        return ok
    else
        if getgenv()._GAG_storage then getgenv()._GAG_storage[path] = nil end
        return true
    end
end

-- ensure folder exists
safe_makefolder(FOLDER)

-- index handling
local function load_index()
    if safe_isfile(LIST_FILE) then
        local raw = safe_readfile(LIST_FILE)
        if raw then
            local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok and type(data) == "table" then return data end
        end
    end
    return {} -- empty
end
local function save_index(idx)
    local ok, err = safe_writefile(LIST_FILE, HttpService:JSONEncode(idx))
    return ok, err
end

-- save template file path
local function template_path(name)
    -- sanitize name
    local nm = tostring(name):gsub("[^%w _-]", "_")
    return FOLDER .. "/" .. nm .. ".json"
end

-- ===== Notification helper =====
local function notify(text, t)
    t = t or 1.6
    pcall(function()
        local notif = Instance.new("TextLabel")
        notif.Size = UDim2.new(0, 300, 0, 36)
        notif.Position = UDim2.new(0.5, -150, 0.06, 0)
        notif.AnchorPoint = Vector2.new(0.5, 0)
        notif.BackgroundTransparency = 0.08
        notif.BackgroundColor3 = Color3.fromRGB(10,10,10)
        notif.TextColor3 = Color3.fromRGB(200,255,200)
        notif.Text = tostring(text)
        notif.TextWrapped = true
        notif.Parent = CoreGui
        task.delay(t, function() pcall(function() notif:Destroy() end) end)
    end)
end

-- ===== Template CRUD =====
local function save_template(name, checkpoints)
    if not name or #name == 0 or #checkpoints == 0 then return false, "Invalid" end
    local path = template_path(name)
    local ok, err = safe_writefile(path, HttpService:JSONEncode(checkpoints))
    if not ok then return false, err end
    -- update index
    local idx = load_index()
    local found = false
    for _,v in ipairs(idx) do if v == name then found = true; break end end
    if not found then table.insert(idx, name); save_index(idx) end
    return true
end

local function load_template(name)
    local path = template_path(name)
    if not safe_isfile(path) then return false, "not found" end
    local raw = safe_readfile(path)
    if not raw then return false, "read fail" end
    local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok then return false, data end
    -- expected array of {x,y,z}
    return true, data
end

local function delete_template(name)
    local path = template_path(name)
    if safe_isfile(path) then safe_delfile(path) end
    local idx = load_index()
    for i,v in ipairs(idx) do if v == name then table.remove(idx,i); break end end
    save_index(idx)
    return true
end

-- get hrp safe
local function getHRP()
    local ch = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso"))
end

-- ===== GUI BUILD =====
-- cleanup old
pcall(function() local prev = CoreGui:FindFirstChild("GAG_CheckpointManager") if prev then prev:Destroy() end end)

local screen = Instance.new("ScreenGui", CoreGui)
screen.Name = "GAG_CheckpointManager"
screen.ResetOnSpawn = false

-- login frame
local loginFrame = Instance.new("Frame", screen)
loginFrame.Size = UDim2.new(0, 420, 0, 220)
loginFrame.Position = UDim2.new(0.35, 0, 0.28, 0)
loginFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
loginFrame.BorderSizePixel = 0
loginFrame.Name = "LoginFrame"

local title = Instance.new("TextLabel", loginFrame)
title.Size = UDim2.new(1, -20, 0, 36)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text = "Checkpoint Manager — Login"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(180,255,200)

local userBox = Instance.new("TextBox", loginFrame)
userBox.Size = UDim2.new(1, -20, 0, 36)
userBox.Position = UDim2.new(0, 10, 0, 64)
userBox.PlaceholderText = "Username"
userBox.Text = ""
userBox.ClearTextOnFocus = false

local passBox = Instance.new("TextBox", loginFrame)
passBox.Size = UDim2.new(1, -20, 0, 36)
passBox.Position = UDim2.new(0, 10, 0, 108)
passBox.PlaceholderText = "Password"
passBox.Text = ""
passBox.ClearTextOnFocus = false
passBox.TextScaled = false

local loginBtn = Instance.new("TextButton", loginFrame)
loginBtn.Size = UDim2.new(1, -20, 0, 36)
loginBtn.Position = UDim2.new(0, 10, 0, 156)
loginBtn.BackgroundColor3 = Color3.fromRGB(0,180,140)
loginBtn.TextColor3 = Color3.fromRGB(0,0,0)
loginBtn.Text = "Login"

-- small note
local note = Instance.new("TextLabel", loginFrame)
note.Size = UDim2.new(1, -20, 0, 16)
note.Position = UDim2.new(0, 10, 1, -24)
note.BackgroundTransparency = 1
note.Text = "Admin: irsad / irsad10   •   User: member / member"
note.TextColor3 = Color3.fromRGB(200,200,200)
note.TextScaled = false
note.Font = Enum.Font.SourceSansItalic
note.TextSize = 12

-- main frame (hidden until login)
local mainFrame = Instance.new("Frame", screen)
mainFrame.Size = UDim2.new(0, 640, 0, 440)
mainFrame.Position = UDim2.new(0.2, 0, 0.08, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(16,16,16)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false

-- header + close + role label
local header = Instance.new("Frame", mainFrame)
header.Size = UDim2.new(1,0,0,44)
header.Position = UDim2.new(0,0,0,0)
header.BackgroundColor3 = Color3.fromRGB(28,28,28)

local hdrTitle = Instance.new("TextLabel", header)
hdrTitle.Size = UDim2.new(1, -200, 1, 0)
hdrTitle.Position = UDim2.new(0, 12, 0, 0)
hdrTitle.BackgroundTransparency = 1
hdrTitle.Text = "Checkpoint Manager"
hdrTitle.Font = Enum.Font.GothamBlack
hdrTitle.TextSize = 18
hdrTitle.TextColor3 = Color3.fromRGB(180,255,200)
hdrTitle.TextXAlignment = Enum.TextXAlignment.Left

local roleLabel = Instance.new("TextLabel", header)
roleLabel.Size = UDim2.new(0, 200, 1, 0)
roleLabel.Position = UDim2.new(1, -210, 0, 0)
roleLabel.BackgroundTransparency = 1
roleLabel.Text = "Role: -"
roleLabel.TextColor3 = Color3.fromRGB(220,220,220)
roleLabel.Font = Enum.Font.GothamSemibold
roleLabel.TextSize = 14

local closeMain = Instance.new("TextButton", header)
closeMain.Size = UDim2.new(0, 90, 0, 28)
closeMain.Position = UDim2.new(1, -96, 0, 8)
closeMain.Text = "Close"
closeMain.BackgroundColor3 = Color3.fromRGB(160,40,40)
closeMain.TextColor3 = Color3.fromRGB(255,255,255)
closeMain.Font = Enum.Font.GothamBold

closeMain.MouseButton1Click:Connect(function()
    pcall(function() screen:Destroy() end)
end)

-- left admin panel (record / save)
local left = Instance.new("Frame", mainFrame)
left.Size = UDim2.new(0.38, -12, 1, -54)
left.Position = UDim2.new(0, 8, 0, 46)
left.BackgroundTransparency = 1

local btnAdd = Instance.new("TextButton", left)
btnAdd.Size = UDim2.new(1, 0, 0, 40)
btnAdd.Position = UDim2.new(0, 0, 0, 0)
btnAdd.Text = "Add Checkpoint (record current pos)"
btnAdd.BackgroundColor3 = Color3.fromRGB(0,170,120)
btnAdd.TextColor3 = Color3.fromRGB(0,0,0)

local cpListLabel = Instance.new("TextLabel", left)
cpListLabel.Size = UDim2.new(1,0,0,20)
cpListLabel.Position = UDim2.new(0,0,0,48)
cpListLabel.BackgroundTransparency = 1
cpListLabel.Text = "Recorded Checkpoints: 0"
cpListLabel.TextColor3 = Color3.fromRGB(220,220,220)

local cpScroll = Instance.new("ScrollingFrame", left)
cpScroll.Size = UDim2.new(1,0,0,220)
cpScroll.Position = UDim2.new(0,0,0,72)
cpScroll.BackgroundTransparency = 1
cpScroll.ScrollBarThickness = 8

local cpLayout = Instance.new("UIListLayout", cpScroll)
cpLayout.Padding = UDim.new(0,6)

local saveNameBox = Instance.new("TextBox", left)
saveNameBox.Size = UDim2.new(1,0,0,36)
saveNameBox.Position = UDim2.new(0,0,0,304)
saveNameBox.PlaceholderText = "Template name (e.g. Gunung Arunika)"
saveNameBox.ClearTextOnFocus = false

local saveBtn = Instance.new("TextButton", left)
saveBtn.Size = UDim2.new(1,0,0,36)
saveBtn.Position = UDim2.new(0,0,0,346)
saveBtn.Text = "Save Template (admin)"
saveBtn.BackgroundColor3 = Color3.fromRGB(0,150,200)
saveBtn.TextColor3 = Color3.fromRGB(0,0,0)

local delBtnAdmin = Instance.new("TextButton", left)
delBtnAdmin.Size = UDim2.new(1,0,0,28)
delBtnAdmin.Position = UDim2.new(0,0,0,388)
delBtnAdmin.Text = "Delete Template (select from right)"
delBtnAdmin.BackgroundColor3 = Color3.fromRGB(170,80,80)
delBtnAdmin.TextColor3 = Color3.fromRGB(255,255,255)

-- right user panel (templates + play)
local right = Instance.new("Frame", mainFrame)
right.Size = UDim2.new(0.62, -8, 1, -54)
right.Position = UDim2.new(0.38, 8, 0, 46)
right.BackgroundTransparency = 1

local tmplLabel = Instance.new("TextLabel", right)
tmplLabel.Size = UDim2.new(1,0,0,20); tmplLabel.Position = UDim2.new(0,0,0,0)
tmplLabel.BackgroundTransparency = 1
tmplLabel.Text = "Templates:"
tmplLabel.TextColor3 = Color3.fromRGB(220,220,220)
tmplLabel.Font = Enum.Font.GothamSemibold

local tmplScroll = Instance.new("ScrollingFrame", right)
tmplScroll.Size = UDim2.new(1,0,0.6,0)
tmplScroll.Position = UDim2.new(0,0,0,28)
tmplScroll.BackgroundTransparency = 1
tmplScroll.ScrollBarThickness = 8

local tmplLayout = Instance.new("UIListLayout", tmplScroll)
tmplLayout.Padding = UDim.new(0,6)

local tpControls = Instance.new("Frame", right)
tpControls.Size = UDim2.new(1,0,0,120)
tpControls.Position = UDim2.new(0,0,0.62,8)
tpControls.BackgroundTransparency = 1

local autoToggle = Instance.new("TextButton", tpControls)
autoToggle.Size = UDim2.new(0.48, -6, 0, 36)
autoToggle.Position = UDim2.new(0, 0, 0, 6)
autoToggle.Text = "Auto TP: OFF"
autoToggle.BackgroundColor3 = Color3.fromRGB(70,70,70)
autoToggle.TextColor3 = Color3.fromRGB(230,230,230)

local intervalBox = Instance.new("TextBox", tpControls)
intervalBox.Size = UDim2.new(0.48, -6, 0, 36)
intervalBox.Position = UDim2.new(0.52, 6, 0, 6)
intervalBox.PlaceholderText = "Interval seconds (default 2)"
intervalBox.Text = "2"
intervalBox.ClearTextOnFocus = false

local manualTPBtn = Instance.new("TextButton", tpControls)
manualTPBtn.Size = UDim2.new(1,0,0,36)
manualTPBtn.Position = UDim2.new(0,0,0,52)
manualTPBtn.Text = "Manual TP to Selected Checkpoint"
manualTPBtn.BackgroundColor3 = Color3.fromRGB(0,150,140)
manualTPBtn.TextColor3 = Color3.fromRGB(0,0,0)

local adminAlertLabel = Instance.new("TextLabel", mainFrame)
adminAlertLabel.Size = UDim2.new(0, 300, 0, 24)
adminAlertLabel.Position = UDim2.new(0.5, -150, 1, -34)
adminAlertLabel.BackgroundTransparency = 1
adminAlertLabel.Text = "Admin: None"
adminAlertLabel.TextColor3 = Color3.fromRGB(230, 120, 120)

-- ===== State =====
local role = "guest" -- "admin" or "user"
local recorded = {} -- current recording checkpoints { {x,y,z}, ... }
local templates = load_index() -- list of names
local loadedTemplate = nil -- current template name
local loadedCheckpoints = {} -- loaded checkpoint positions
local autoTPEnabled = false
local autoTPCoroutine = nil

-- ===== UI Functions =====
local function refresh_cp_list()
    for _,c in ipairs(cpScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for i,cp in ipairs(recorded) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -6, 0, 28)
        btn.Position = UDim2.new(0, 6, 0, (i-1)*34)
        btn.AnchorPoint = Vector2.new(0,0)
        btn.Text = string.format("%d) (%.1f, %.1f, %.1f)", i, cp.x, cp.y, cp.z)
        btn.Parent = cpScroll
        btn.MouseButton1Click:Connect(function()
            -- teleport preview to that checkpoint
            local hrp = getHRP()
            if hrp then hrp.CFrame = CFrame.new(Vector3.new(cp.x, cp.y, cp.z) + Vector3.new(0,3,0)) end
        end)
    end
    cpListLabel.Text = "Recorded Checkpoints: " .. tostring(#recorded)
end

local selectedTemplateBtn = nil
local function refresh_templates()
    templates = load_index()
    for _,c in ipairs(tmplScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for i,name in ipairs(templates) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 34)
        btn.Position = UDim2.new(0, 6, 0, (i-1)*40)
        btn.Text = name
        btn.Parent = tmplScroll
        btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        btn.TextColor3 = Color3.fromRGB(230,230,230)
        btn.MouseButton1Click:Connect(function()
            -- select template: highlight and load points
            if selectedTemplateBtn then selectedTemplateBtn.BackgroundColor3 = Color3.fromRGB(60,60,60) end
            btn.BackgroundColor3 = Color3.fromRGB(40,140,40)
            selectedTemplateBtn = btn
            loadedTemplate = name
            local ok, data = load_template(name)
            if ok then
                loadedCheckpoints = data -- expect array of {x,y,z}
                notify("Template loaded: "..name, 1.4)
            else
                loadedCheckpoints = {}
                notify("Failed load: "..tostring(data), 1.8)
            end
        end)
    end
end

-- ===== Recording & Saving =====
btnAdd.MouseButton1Click:Connect(function()
    local hrp = getHRP()
    if not hrp then notify("Character not ready."); return end
    local pos = hrp.Position
    table.insert(recorded, { x = pos.X, y = pos.Y, z = pos.Z })
    refresh_cp_list()
    notify("Checkpoint added ("..#recorded..")", 1.2)
end)

saveBtn.MouseButton1Click:Connect(function()
    if role ~= "admin" then notify("Only admin can save templates.", 1.6); return end
    local name = tostring(saveNameBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    if name == "" then notify("Masukkan nama template valid.", 1.6); return end
    if #recorded == 0 then notify("Belum ada checkpoint direkam.", 1.6); return end
    local ok, err = save_template(name, recorded)
    if ok then
        notify("Saved template: "..name, 1.6)
        saveNameBox.Text = ""
        recorded = {}
        refresh_cp_list()
        refresh_templates()
    else
        notify("Save failed: "..tostring(err), 2)
    end
end)

delBtnAdmin.MouseButton1Click:Connect(function()
    if role ~= "admin" then notify("Only admin can delete templates.", 1.6); return end
    if not loadedTemplate then notify("Pilih template di kanan dulu.", 1.6); return end
    delete_template(loadedTemplate)
    loadedTemplate = nil
    loadedCheckpoints = {}
    refresh_templates()
    notify("Template deleted.", 1.4)
end)

-- Manual TP to selected checkpoint in loadedCheckpoints (choose by index dialog)
manualTPBtn.MouseButton1Click:Connect(function()
    if not loadedTemplate or #loadedCheckpoints == 0 then notify("No template loaded.", 1.4); return end
    -- ask user in console to pick index (simple)
    notify("Open console and call selectCheckpointIndex(n) with n number.", 3)
    print("Loaded checkpoints for template:", loadedTemplate)
    for i,cp in ipairs(loadedCheckpoints) do
        print(i, cp.x, cp.y, cp.z)
    end
    print("Use selectCheckpointIndex(<n>) to teleport.")
end)

-- helper global function for console convenience
_G.selectCheckpointIndex = function(n)
    n = tonumber(n)
    if not n or not loadedCheckpoints[n] then
        print("Invalid index or no template loaded.")
        return
    end
    local cp = loadedCheckpoints[n]
    local hrp = getHRP()
    if hrp then hrp.CFrame = CFrame.new(Vector3.new(cp.x, cp.y, cp.z) + Vector3.new(0,3,0)) end
    print("Teleported to checkpoint", n)
end

-- ===== Auto TP logic =====
local function startAutoTP()
    if autoTPEnabled then return end
    if not loadedTemplate or #loadedCheckpoints == 0 then notify("No template loaded.", 1.4); return end
    autoTPEnabled = true
    autoToggle.Text = "Auto TP: ON"
    autoToggle.BackgroundColor3 = Color3.fromRGB(0,160,120)

    autoTPCoroutine = coroutine.create(function()
        while autoTPEnabled do
            for _,cp in ipairs(loadedCheckpoints) do
                if not autoTPEnabled then break end
                local hrp = getHRP()
                if hrp then
                    hrp.CFrame = CFrame.new(Vector3.new(cp.x, cp.y, cp.z) + Vector3.new(0,3,0))
                end
                local delaySec = tonumber(intervalBox.Text) or 2
                for i=1, math.max(1, math.floor(delaySec*20)) do
                    if not autoTPEnabled then break end
                    task.wait(delaySec / math.max(1, math.floor(delaySec*20)))
                end
            end
            -- loop templates continuously
        end
    end)
    coroutine.resume(autoTPCoroutine)
    notify("Auto TP started for template: "..tostring(loadedTemplate), 1.6)
end

local function stopAutoTP()
    autoTPEnabled = false
    autoToggle.Text = "Auto TP: OFF"
    autoToggle.BackgroundColor3 = Color3.fromRGB(70,70,70)
    notify("Auto TP stopped.", 1.2)
end

autoToggle.MouseButton1Click:Connect(function()
    if autoTPEnabled then stopAutoTP() else startAutoTP() end
end)

-- ===== Admin Detector (player names or group rank) =====
local function checkAdmins()
    local found = nil
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local n = plr.Name:lower()
            if n:find("admin") or n:find("mod") or plr:GetRankInGroup ~= nil and pcall(function() return plr:GetRankInGroup(0) end) and false then
                found = plr.Name
                break
            end
            -- also check specific known admin usernames (example)
            if plr.Name:lower() == "irsad" then found = plr.Name; break end
        end
    end
    adminAlertLabel.Text = "Admin: " .. (found or "None")
    if found then notify("Admin detected: "..found, 2.2) end
end
Players.PlayerAdded:Connect(checkAdmins)
Players.PlayerRemoving:Connect(checkAdmins)

-- ===== Login handling =====
local function show_main_for(roleName)
    role = roleName
    roleLabel.Text = "Role: " .. (role == "admin" and "Admin" or "User")
    loginFrame.Visible = false
    mainFrame.Visible = true
    refresh_templates()
    notify("Logged in as "..role, 1.4)
end

loginBtn.MouseButton1Click:Connect(function()
    local user = tostring(userBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    local pass = tostring(passBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    if user == "irsad" and pass == "irsad10" then
        show_main_for("admin")
    elseif user == "member" and pass == "member" then
        show_main_for("user")
    else
        notify("Login failed. Cek username/password.", 1.8)
    end
end)

-- When main loads, update templates
refresh_templates()
checkAdmins()

-- final note
print("[GAG CheckpointManager] Ready. Login to start.")
