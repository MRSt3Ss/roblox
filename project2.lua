-- Pastebin-backed Checkpoint Manager (Full)
-- Admin can upload templates to Pastebin using API key.
-- Users load index/raw templates from Pastebin and auto-TP.
-- Requires an executor with HTTP request support (syn.request / http_request / request / http.request).
-- By GPT-5 Thinking mini

-- ================== CONFIG ==================
local PASTEBIN_API_KEY = "1whRCEY7X8SQXRWnet8gvBlGbk5K4zzQ" -- your provided key
local PASTEBIN_API_POST = "https://pastebin.com/api/api_post.php"
-- privacy: 0 = public, 1 = unlisted, 2 = private (private needs user key; better use 1)
local PASTE_PRIVACY = "1"

-- Local file names (writefile/readfile) for convenience
local INDEX_URL_FILE = "cp_index_raw_url.txt" -- stores raw index URL locally (device-specific)
-- ============================================

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Safe file helpers (writefile/readfile fallback)
local function safe_writefile(path, content)
    if type(writefile) == "function" then
        local ok, err = pcall(function() writefile(path, content) end)
        return ok, err
    else
        getgenv()._CP_local_storage = getgenv()._CP_local_storage or {}
        getgenv()._CP_local_storage[path] = content
        return true
    end
end
local function safe_readfile(path)
    if type(readfile) == "function" and type(isfile) == "function" and pcall(isfile, path) and isfile(path) then
        local ok, res = pcall(function() return readfile(path) end)
        return ok and res or nil
    else
        getgenv()._CP_local_storage = getgenv()._CP_local_storage or {}
        return getgenv()._CP_local_storage[path]
    end
end

-- HTTP request wrapper (tries common executor functions)
local function http_request(req)
    -- req is a table { Url=..., Method="POST"/"GET", Body=..., Headers=... }
    local funcs = {
        function(r) if syn and syn.request then return syn.request(r) end end,
        function(r) if http and http.request then return http.request(r) end end,
        function(r) if http_request then return http_request(r) end end,
        function(r) if request then return request(r) end end,
        function(r) if (http and http.request) then return http.request(r) end end,
    }
    for _,f in ipairs(funcs) do
        local ok, res = pcall(f, req)
        if ok and res and (res.Body or res.body or res.Success ~= nil) then
            -- normalize
            local body = res.Body or res.body or (res.Response and res.Response.Body) or tostring(res)
            local code = res.StatusCode or res.status or res.Status or (res.Success and (res.Success and 200 or 500)) or 200
            return { Body = body, StatusCode = code, Raw = res }
        end
    end
    return nil, "no-http-function"
end

-- Pastebin helper: create paste (returns paste_key or nil,err)
local function pastebin_create_paste(content, title)
    -- content must be utf8
    local body = "api_dev_key="..tostring(PASTEBIN_API_KEY)
               .."&api_option=paste"
               .."&api_paste_code="..HttpService:UrlEncode(content)
               .."&api_paste_private="..tostring(PASTE_PRIVACY)
               .."&api_paste_name="..HttpService:UrlEncode(tostring(title or "cp_template"))
    local req = {
        Url = PASTEBIN_API_POST,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
        },
        Body = body,
    }
    local res, err = http_request(req)
    if not res then return nil, err end
    if (res.StatusCode >= 200 and res.StatusCode < 300) then
        -- response is paste URL e.g. https://pastebin.com/AbCdEf12
        local url = tostring(res.Body)
        local key = url:match("pastebin%.com/(.+)$")
        if key then
            -- get raw key (no query)
            key = key:gsub("[^%w]", "")
            return key
        else
            return nil, "invalid-response"
        end
    else
        return nil, "http-status-"..tostring(res.StatusCode)
    end
end

-- Utility: convert paste key to raw url
local function paste_key_to_raw_url(key)
    if not key then return nil end
    return "https://pastebin.com/raw/"..tostring(key)
end

-- Fetch raw content (GET)
local function fetch_raw(url)
    local req = { Url = url, Method = "GET", Headers = {} }
    local res, err = http_request(req)
    if not res then return nil, err end
    if res.StatusCode >= 200 and res.StatusCode < 300 then
        return tostring(res.Body)
    else
        return nil, "http:"..tostring(res.StatusCode)
    end
end

-- ========== Data structures ==========
local recordedCPs = {}     -- admin local current recording: { {x,y,z,name} }
local indexRawURL = nil    -- raw index url (pastebin raw) - loaded from local file if exists
local templatesIndex = {}  -- loaded index: { {name=name, key=paste_key} }

-- load saved index url from local file (device)
local saved = safe_readfile(INDEX_URL_FILE)
if saved and type(saved) == "string" and #saved>5 then
    indexRawURL = saved
end

-- ========== UI helpers ==========
local function notify(msg, t)
    t = t or 1.6
    pcall(function()
        local f = Instance.new("Frame", CoreGui)
        f.Size = UDim2.new(0, 380, 0, 44)
        f.Position = UDim2.new(0.5, -190, 0.06, 0)
        f.AnchorPoint = Vector2.new(0.5,0)
        f.BackgroundColor3 = Color3.fromRGB(10,10,10)
        f.BorderSizePixel = 0
        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(1,-16,1,-8); l.Position = UDim2.new(0,8,0,6)
        l.BackgroundTransparency = 1
        l.Text = tostring(msg); l.TextColor3 = Color3.fromRGB(200,255,200); l.Font = Enum.Font.Gotham; l.TextWrapped = true
        task.delay(t, function() pcall(function() f:Destroy() end) end)
    end)
end

-- ========== GUI Build ==========
pcall(function() local old=CoreGui:FindFirstChild("PB_CP_UI") if old then old:Destroy() end end)

local screen = Instance.new("ScreenGui", CoreGui); screen.Name = "PB_CP_UI"; screen.ResetOnSpawn = false

-- main frame
local main = Instance.new("Frame", screen)
main.Size = UDim2.new(0,760,0,520)
main.Position = UDim2.new(0.12,0,0.06,0)
main.BackgroundColor3 = Color3.fromRGB(18,20,18)
main.BorderSizePixel = 0
main.Active = true

-- minimize toggle state
local isMinimized = false
local mainSizeNormal = main.Size

-- header (draggable)
local header = Instance.new("Frame", main); header.Size = UDim2.new(1,0,0,56); header.BackgroundColor3 = Color3.fromRGB(26,28,26)
local title = Instance.new("TextLabel", header); title.Size = UDim2.new(0.7,-8,1,0); title.Position = UDim2.new(0,12,0,0); title.BackgroundTransparency=1
title.Font = Enum.Font.GothamBlack; title.TextSize = 18; title.Text = "Checkpoint — Pastebin Manager"; title.TextColor3 = Color3.fromRGB(170,255,200); title.TextXAlignment = Enum.TextXAlignment.Left
local roleLabel = Instance.new("TextLabel", header); roleLabel.Size = UDim2.new(0.28,-20,1,0); roleLabel.Position = UDim2.new(0.72,8,0,0); roleLabel.BackgroundTransparency = 1; roleLabel.Font=Enum.Font.GothamSemibold; roleLabel.TextColor3=Color3.fromRGB(220,220,220); roleLabel.Text = "Role: -"

local btnMin = Instance.new("TextButton", header); btnMin.Size = UDim2.new(0,36,0,36); btnMin.Position = UDim2.new(1,-88,0,10); btnMin.Text="▁"; btnMin.Font=Enum.Font.Gotham; btnMin.TextColor3=Color3.fromRGB(0,0,0); btnMin.BackgroundColor3=Color3.fromRGB(200,200,0)
local btnClose = Instance.new("TextButton", header); btnClose.Size = UDim2.new(0,36,0,36); btnClose.Position = UDim2.new(1,-44,0,10); btnClose.Text="X"; btnClose.Font=Enum.Font.GothamBold; btnClose.TextColor3=Color3.fromRGB(0,0,0); btnClose.BackgroundColor3=Color3.fromRGB(160,40,40)

-- make header draggable (robust)
do
    local dragging, dragInput, dragStart, startPos
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
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and dragStart and startPos then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Left: Login / Admin controls / recorded CP preview
local left = Instance.new("Frame", main); left.Size = UDim2.new(0.38,-12,1,-80); left.Position = UDim2.new(0,12,0,68); left.BackgroundTransparency = 1
local loginTitle = Instance.new("TextLabel", left); loginTitle.Size = UDim2.new(1,0,0,28); loginTitle.BackgroundTransparency = 1; loginTitle.Text="Login"; loginTitle.Font=Enum.Font.GothamSemibold; loginTitle.TextColor3=Color3.fromRGB(200,255,200)
local userBox = Instance.new("TextBox", left); userBox.Size = UDim2.new(1,0,0,32); userBox.Position = UDim2.new(0,0,0,36); userBox.PlaceholderText="Username"; userBox.BackgroundColor3=Color3.fromRGB(28,28,28); userBox.TextColor3=Color3.fromRGB(230,230,230)
local passBox = Instance.new("TextBox", left); passBox.Size = UDim2.new(1,0,0,32); passBox.Position = UDim2.new(0,0,0,72); passBox.PlaceholderText="Password"; passBox.BackgroundColor3=Color3.fromRGB(28,28,28); passBox.TextColor3=Color3.fromRGB(230,230,230)
local loginBtn = Instance.new("TextButton", left); loginBtn.Size = UDim2.new(1,0,0,36); loginBtn.Position = UDim2.new(0,0,0,112); loginBtn.Text="Login"; loginBtn.BackgroundColor3=Color3.fromRGB(0,160,120); loginBtn.Font=Enum.Font.GothamBold
local infoLabel = Instance.new("TextLabel", left); infoLabel.Size = UDim2.new(1,0,0,20); infoLabel.Position = UDim2.new(0,0,0,156); infoLabel.BackgroundTransparency = 1; infoLabel.Text = "Admin: irsad/irsad10  •  User: member/member"; infoLabel.TextColor3 = Color3.fromRGB(200,200,200)
local divider = Instance.new("Frame", left); divider.Size = UDim2.new(1,0,0,2); divider.Position = UDim2.new(0,0,0,182); divider.BackgroundColor3 = Color3.fromRGB(30,30,30)

-- Admin controls area
local addBtn = Instance.new("TextButton", left); addBtn.Size = UDim2.new(1,0,0,36); addBtn.Position = UDim2.new(0,0,0,196); addBtn.Text="Add Checkpoint"; addBtn.BackgroundColor3=Color3.fromRGB(0,200,140); addBtn.Font=Enum.Font.GothamBold
local savePBBtn = Instance.new("TextButton", left); savePBBtn.Size = UDim2.new(1,0,0,34); savePBBtn.Position = UDim2.new(0,0,0,236); savePBBtn.Text="Save to Pastebin (Upload)"; savePBBtn.BackgroundColor3=Color3.fromRGB(0,150,200)
local localIndexLabel = Instance.new("TextLabel", left); localIndexLabel.Size = UDim2.new(1,0,0,18); localIndexLabel.Position = UDim2.new(0,0,0,276); localIndexLabel.BackgroundTransparency=1; localIndexLabel.Text="Index URL (local):"; localIndexLabel.TextColor3=Color3.fromRGB(200,200,200)
local indexBox = Instance.new("TextBox", left); indexBox.Size = UDim2.new(1,0,0,30); indexBox.Position = UDim2.new(0,0,0,296); indexBox.PlaceholderText="(Paste index raw url here or leave blank)"; indexBox.Text = indexRawURL or ""; indexBox.ClearTextOnFocus = false; indexBox.BackgroundColor3=Color3.fromRGB(28,28,28); indexBox.TextColor3=Color3.fromRGB(230,230,230)
local saveIndexLocalBtn = Instance.new("TextButton", left); saveIndexLocalBtn.Size = UDim2.new(1,0,0,30); saveIndexLocalBtn.Position = UDim2.new(0,0,0,332); saveIndexLocalBtn.Text="Save Index URL Locally"; saveIndexLocalBtn.BackgroundColor3=Color3.fromRGB(80,80,80)

local previewLabel = Instance.new("TextLabel", left); previewLabel.Size = UDim2.new(1,0,0,18); previewLabel.Position = UDim2.new(0,0,0,372); previewLabel.BackgroundTransparency=1; previewLabel.Text="Recorded Checkpoints:"; previewLabel.TextColor3=Color3.fromRGB(220,220,220)
local cpScroll = Instance.new("ScrollingFrame", left); cpScroll.Size = UDim2.new(1,0,0,120); cpScroll.Position = UDim2.new(0,0,0,392); cpScroll.BackgroundTransparency = 0.04; cpScroll.ScrollBarThickness = 8
local cpLayout = Instance.new("UIListLayout", cpScroll); cpLayout.Padding = UDim.new(0,6)

-- Right: templates index / template controls
local right = Instance.new("Frame", main); right.Size = UDim2.new(0.6,-12,1,-80); right.Position = UDim2.new(0.38,8,0,68); right.BackgroundTransparency = 1
local idxTitle = Instance.new("TextLabel", right); idxTitle.Size = UDim2.new(1,0,0,20); idxTitle.Position = UDim2.new(0,0,0,0); idxTitle.BackgroundTransparency = 1; idxTitle.Text = "Templates (from index)"; idxTitle.Font=Enum.Font.GothamSemibold; idxTitle.TextColor3=Color3.fromRGB(200,255,200)
local loadIndexBtn = Instance.new("TextButton", right); loadIndexBtn.Size = UDim2.new(0.48,-6,0,30); loadIndexBtn.Position = UDim2.new(0,0,0,28); loadIndexBtn.Text="Load Index from Pastebin"; loadIndexBtn.BackgroundColor3=Color3.fromRGB(0,120,200)
local refreshIndexBtn = Instance.new("TextButton", right); refreshIndexBtn.Size = UDim2.new(0.48,-6,0,30); refreshIndexBtn.Position = UDim2.new(0.52,6,0,28); refreshIndexBtn.Text="Refresh Local Index"; refreshIndexBtn.BackgroundColor3=Color3.fromRGB(80,80,80)
local tmplScroll = Instance.new("ScrollingFrame", right); tmplScroll.Size = UDim2.new(1,0,0.7,0); tmplScroll.Position = UDim2.new(0,0,0,64); tmplScroll.BackgroundTransparency = 0.04; tmplScroll.ScrollBarThickness = 8
local tmplLayout = Instance.new("UIListLayout", tmplScroll); tmplLayout.Padding = UDim.new(0,6)
local tpControls = Instance.new("Frame", right); tpControls.Size = UDim2.new(1,0,0,120); tpControls.Position = UDim2.new(0,0,0.74,8); tpControls.BackgroundTransparency = 1
local autoToggle = Instance.new("TextButton", tpControls); autoToggle.Size = UDim2.new(0.48,-6,0,36); autoToggle.Position = UDim2.new(0,0,0,6); autoToggle.Text="Auto TP: OFF"; autoToggle.BackgroundColor3=Color3.fromRGB(70,70,70)
local intervalBox = Instance.new("TextBox", tpControls); intervalBox.Size = UDim2.new(0.48,-6,0,36); intervalBox.Position = UDim2.new(0.52,6,0,6); intervalBox.PlaceholderText="Interval seconds"; intervalBox.Text="2"; intervalBox.ClearTextOnFocus=false
local manualTPBtn = Instance.new("TextButton", tpControls); manualTPBtn.Size = UDim2.new(1,0,0,36); manualTPBtn.Position = UDim2.new(0,0,0,52); manualTPBtn.Text="Manual TP to Template CP"; manualTPBtn.BackgroundColor3=Color3.fromRGB(0,150,140)
local adminLabel = Instance.new("TextLabel", main); adminLabel.Size = UDim2.new(0,320,0,24); adminLabel.Position = UDim2.new(0.5,-160,1,-40); adminLabel.BackgroundTransparency=1; adminLabel.Text="Admin: None"; adminLabel.TextColor3=Color3.fromRGB(255,120,120)

-- state for UI lists
local ui_tmpl_buttons = {}
local loadedTemplate = nil -- { name =..., cps = {...} }

-- ========== UI utility functions ==========
local function clearFrameChildren(f)
    for _,c in ipairs(f:GetChildren()) do
        if not (c:IsA("UIListLayout") or c:IsA("UIPadding")) then
            pcall(function() c:Destroy() end)
        end
    end
end

local function rebuildRecordedList()
    clearFrameChildren(cpScroll)
    for i,cp in ipairs(recordedCPs) do
        local row = Instance.new("Frame", cpScroll); row.Size = UDim2.new(1,-8,0,34); row.BackgroundTransparency = 0.6; row.BackgroundColor3 = Color3.fromRGB(6,16,6)
        local lbl = Instance.new("TextLabel", row); lbl.Size = UDim2.new(0.8,0,1,0); lbl.Position = UDim2.new(0,8,0,0); lbl.BackgroundTransparency=1; lbl.Text = string.format("%d) %s (%.1f, %.1f, %.1f)", i, recordedCPs[i].name or ("CP"..i), recordedCPs[i].x, recordedCPs[i].y, recordedCPs[i].z); lbl.TextColor3=Color3.fromRGB(200,255,200); lbl.Font = Enum.Font.Gotham
        local del = Instance.new("TextButton", row); del.Size = UDim2.new(0,28,0,28); del.Position = UDim2.new(1,-36,0.06,0); del.Text="✕"; del.BackgroundColor3 = Color3.fromRGB(200,40,40)
        del.MouseButton1Click:Connect(function()
            table.remove(recordedCPs, i)
            rebuildRecordedList()
        end)
    end
    cpScroll.CanvasSize = UDim2.new(0,0,0, math.max(1, #recordedCPs * 42))
end

local function rebuildTemplateList()
    clearFrameChildren(tmplScroll)
    ui_tmpl_buttons = {}
    for i,entry in ipairs(templatesIndex or {}) do
        local name = entry.name or ("Template"..i)
        local key = entry.key
        local btn = Instance.new("TextButton", tmplScroll); btn.Size = UDim2.new(1,-8,0,36); btn.Position = UDim2.new(0,6,0,(i-1)*44)
        btn.Text = name; btn.BackgroundColor3 = Color3.fromRGB(60,60,60); btn.TextColor3 = Color3.fromRGB(230,230,230); btn.Font = Enum.Font.Gotham
        ui_tmpl_buttons[name] = btn
        btn.MouseButton1Click:Connect(function()
            -- visual selection
            for _,b in pairs(ui_tmpl_buttons) do if b and b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(60,60,60) end end
            btn.BackgroundColor3 = Color3.fromRGB(40,140,40)
            -- load template raw
            local rawUrl = paste_key_to_raw_url(key)
            notify("Fetching template '"..name.."' ...", 1.2)
            spawn(function()
                local content, err = fetch_raw(rawUrl)
                if not content then notify("Failed fetch template: "..tostring(err), 2.2); return end
                local ok, tbl = pcall(function() return HttpService:JSONDecode(content) end)
                if not ok or type(tbl) ~= "table" then notify("Template JSON invalid", 1.8); return end
                -- expect tbl.checkpoints array with {x,y,z,name?}
                loadedTemplate = { name = name, cps = tbl.checkpoints or {} }
                notify("Template loaded: "..name, 1.4)
            end)
        end)
    end
    tmplScroll.CanvasSize = UDim2.new(0,0,0, math.max(1, #templatesIndex * 44))
end

-- ========== core actions ==========

-- Add checkpoint (admin action)
addBtn.MouseButton1Click:Connect(function()
    -- require admin role
    if roleLabel.Text ~= "Role: Admin" then notify("Add requires admin login", 1.6); return end
    local hrp = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Torso") or LocalPlayer.Character:FindFirstChild("UpperTorso"))
    if not hrp then notify("Character not ready",1.4); return end
    local nm = "CP "..tostring(#recordedCPs + 1)
    table.insert(recordedCPs, { x = hrp.Position.X, y = hrp.Position.Y, z = hrp.Position.Z, name = nm })
    rebuildRecordedList()
    notify("Checkpoint added: "..nm, 1.2)
end)

-- Save template to Pastebin (admin)
savePBBtn.MouseButton1Click:Connect(function()
    if roleLabel.Text ~= "Role: Admin" then notify("Save requires admin login",1.6); return end
    if #recordedCPs == 0 then notify("No recorded CPs to save",1.6); return end
    -- build JSON payload for template
    local payload = { mapName = ("Template_%s"):format(tostring(os.time())), checkpoints = {} }
    for i,cp in ipairs(recordedCPs) do
        table.insert(payload.checkpoints, { x = cp.x, y = cp.y, z = cp.z, name = cp.name })
    end
    local content = HttpService:JSONEncode(payload)
    notify("Uploading template to Pastebin...", 2)
    spawn(function()
        local key, err = pastebin_create_paste(content, payload.mapName)
        if not key then notify("Upload failed: "..tostring(err), 3); return end
        local pasteUrl = paste_key_to_raw_url(key)
        notify("Template uploaded: "..pasteUrl, 3)
        -- Now update index: fetch existing index (if indexRawURL present), else build new index
        -- Index format: { templates = [ {name=name, key=key}, ... ] }
        local indexTbl = { templates = {} }
        -- try fetch existing index from indexBox or stored indexRawURL
        local idxRaw = indexBox.Text and (#tostring(indexBox.Text) > 10 and tostring(indexBox.Text) or indexRawURL) or indexRawURL
        if idxRaw and #idxRaw > 10 then
            -- if idxRaw is raw url, fetch content and decode
            local okContent, err2 = fetch_raw(idxRaw)
            if okContent then
                local ok2, dec = pcall(function() return HttpService:JSONDecode(okContent) end)
                if ok2 and type(dec) == "table" and dec.templates then
                    indexTbl = dec
                end
            end
        end
        -- insert new template entry (name/paste_key)
        table.insert(indexTbl.templates, { name = payload.mapName, key = key })
        -- create new index paste to reflect updated list
        local indexContent = HttpService:JSONEncode(indexTbl)
        local idxKey, ierr = pastebin_create_paste(indexContent, "CP_Index_"..tostring(os.time()))
        if not idxKey then
            notify("Template saved but index update failed: "..tostring(ierr), 4)
            -- still show template url
            -- save template raw url locally in case admin wants to share
            safe_writefile("last_template_url.txt", pasteUrl)
            return
        end
        local idxRawUrl = paste_key_to_raw_url(idxKey)
        -- save idxRawUrl locally to INDEX_URL_FILE
        safe_writefile(INDEX_URL_FILE, idxRawUrl)
        indexBox.Text = idxRawUrl
        indexRawURL = idxRawUrl
        -- refresh local index
        notify("Index updated: "..idxRawUrl, 4)
    end)
    -- clear recorded list after uploading (optional)
    recordedCPs = {}
    rebuildRecordedList()
end)

-- Save index raw url locally
saveIndexLocalBtn.MouseButton1Click:Connect(function()
    local txt = tostring(indexBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    if txt == "" then notify("Index URL empty", 1.4); return end
    local ok, err = safe_writefile(INDEX_URL_FILE, txt)
    if ok then indexRawURL = txt; notify("Index URL saved locally", 1.4) else notify("Save failed: "..tostring(err), 1.8) end
end)

-- Load index from indexRawURL (fetch from Pastebin)
loadIndexBtn.MouseButton1Click:Connect(function()
    local idxRaw = tostring(indexBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    if idxRaw == "" then idxRaw = indexRawURL end
    if not idxRaw or #idxRaw < 10 then notify("Index URL not set. Ask admin to share index raw URL.", 2); return end
    notify("Fetching index...", 1.2)
    spawn(function()
        local content, err = fetch_raw(idxRaw)
        if not content then notify("Failed fetch index: "..tostring(err), 2.4); return end
        local ok, dec = pcall(function() return HttpService:JSONDecode(content) end)
        if not ok or type(dec) ~= "table" or type(dec.templates) ~= "table" then notify("Index invalid JSON", 2.4); return end
        -- populate templatesIndex from dec
        templatesIndex = {}
        for _,ent in ipairs(dec.templates) do
            if type(ent.name) == "string" and type(ent.key) == "string" then
                table.insert(templatesIndex, { name = ent.name, key = ent.key })
            end
        end
        rebuildTemplateList()
        notify("Index loaded ("..tostring(#templatesIndex).." templates).", 2)
    end)
end)

-- Refresh local index from loaded templatesIndex
refreshIndexBtn.MouseButton1Click:Connect(function()
    templatesIndex = templatesIndex or {}
    rebuildTemplateList()
    notify("Template list refreshed", 1.2)
end)

-- Manual TP to template CP (popup)
manualTPBtn.MouseButton1Click:Connect(function()
    if not loadedTemplate or not loadedTemplate.cps or #loadedTemplate.cps == 0 then notify("No template loaded",1.4); return end
    -- spawn modal listing CPs
    local modal = Instance.new("Frame", screen); modal.Size = UDim2.new(0,360,0,360); modal.Position = UDim2.new(0.5,-180,0.5,-180); modal.BackgroundColor3=Color3.fromRGB(12,14,12)
    local label = Instance.new("TextLabel", modal); label.Size = UDim2.new(1,-24,0,28); label.Position = UDim2.new(0,12,0,8); label.BackgroundTransparency=1; label.Text="Select CP to TP: "..tostring(loadedTemplate.name or ""); label.Font=Enum.Font.GothamSemibold; label.TextColor3=Color3.fromRGB(200,255,200)
    local sframe = Instance.new("ScrollingFrame", modal); sframe.Size = UDim2.new(1,-24,1,-72); sframe.Position = UDim2.new(0,12,0,44); sframe.ScrollBarThickness=6
    local layout = Instance.new("UIListLayout", sframe); layout.Padding = UDim.new(0,6)
    local close = Instance.new("TextButton", modal); close.Size = UDim2.new(0,80,0,30); close.Position = UDim2.new(1,-92,1,-40); close.Text="Close"; close.BackgroundColor3=Color3.fromRGB(0,120,40)
    close.MouseButton1Click:Connect(function() modal:Destroy() end)
    for i,cp in ipairs(loadedTemplate.cps) do
        local b = Instance.new("TextButton", sframe); b.Size = UDim2.new(1,0,0,36); b.Text = string.format("%d) %s (%.1f,%.1f,%.1f)", i, (cp.name or "CP"..i), cp.x, cp.y, cp.z); b.BackgroundColor3=Color3.fromRGB(60,60,60); b.TextColor3=Color3.fromRGB(230,230,230)
        b.MouseButton1Click:Connect(function()
            local hrp = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Torso") or LocalPlayer.Character:FindFirstChild("UpperTorso"))
            if hrp then hrp.CFrame = CFrame.new(Vector3.new(cp.x, cp.y, cp.z) + Vector3.new(0,3,0)) end
            notify("Teleported to CP "..i,1.2)
            modal:Destroy()
        end)
    end
end)

-- Auto TP loop for loaded template
local autoTPRunning = false
local function startAutoTP()
    if not loadedTemplate or not loadedTemplate.cps or #loadedTemplate.cps == 0 then notify("No template loaded",1.4); return end
    if autoTPRunning then return end
    autoTPRunning = true; autoToggle.Text = "Auto TP: ON"; autoToggle.BackgroundColor3 = Color3.fromRGB(0,160,120)
    spawn(function()
        while autoTPRunning do
            for _,cp in ipairs(loadedTemplate.cps) do
                if not autoTPRunning then break end
                local hrp = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Torso") or LocalPlayer.Character:FindFirstChild("UpperTorso"))
                if hrp then hrp.CFrame = CFrame.new(Vector3.new(cp.x, cp.y, cp.z) + Vector3.new(0,3,0)) end
                local waitSec = tonumber(intervalBox.Text) or 2
                local waited = 0
                while waited < waitSec and autoTPRunning do waited = waited + 0.1; task.wait(0.1) end
            end
        end
    end)
    notify("Auto TP started ("..tostring(loadedTemplate.name)..")", 1.6)
end
local function stopAutoTP()
    autoTPRunning = false; autoToggle.Text = "Auto TP: OFF"; autoToggle.BackgroundColor3 = Color3.fromRGB(70,70,70); notify("Auto TP stopped",1.2)
end
autoToggle.MouseButton1Click:Connect(function() if autoTPRunning then stopAutoTP() else startAutoTP() end end)

-- Login handling (simple)
local function enterAsAdmin()
    roleLabel.Text = "Role: Admin"
    -- enable admin controls
    addBtn.Visible = true
    savePBBtn.Visible = true
    indexBox.Visible = true
    saveIndexLocalBtn.Visible = true
end
local function enterAsUser()
    roleLabel.Text = "Role: User"
    addBtn.Visible = false
    savePBBtn.Visible = false
    indexBox.Visible = true
    saveIndexLocalBtn.Visible = true
end

loginBtn.MouseButton1Click:Connect(function()
    local u = tostring(userBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    local p = tostring(passBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    if u == "irsad" and p == "irsad10" then enterAsAdmin()
    elseif u == "member" and p == "member" then enterAsUser()
    else notify("Login failed",1.6); return end
    notify("Logged in as "..u,1.2)
end)

-- Close & Minimize
btnClose.MouseButton1Click:Connect(function() pcall(function() screen:Destroy() end) end)
btnMin.MouseButton1Click:Connect(function()
    if isMinimized then
        main.Size = mainSizeNormal
        isMinimized = false
    else
        mainSizeNormal = main.Size
        main.Size = UDim2.new(0, 420, 0, 64)
        isMinimized = true
    end
end)

-- Admin detector (simple name keyword)
local ADMIN_KEYWORDS = {"admin","mod","owner"}
local ADMIN_WHITELIST = { "irsad" }
local function checkAdmins()
    local found = {}
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            local n = tostring(pl.Name):lower()
            local flag = false
            for _,k in ipairs(ADMIN_KEYWORDS) do if n:find(k) then flag = true; break end end
            for _,v in ipairs(ADMIN_WHITELIST) do if n == v then flag = true; break end end
            if flag then table.insert(found, pl.Name) end
        end
    end
    if #found > 0 then adminLabel.Text = "Admin: "..table.concat(found,", "); notify("Admin detected: "..table.concat(found,", "),2) else adminLabel.Text = "Admin: None" end
end
Players.PlayerAdded:Connect(function() task.wait(0.8); checkAdmins() end)
Players.PlayerRemoving:Connect(function() task.wait(0.8); checkAdmins() end)
task.delay(0.8, function() checkAdmins() end)

-- If there is saved local index URL initially, set indexBox text and auto-load index optionally
if indexRawURL and #indexRawURL > 10 then
    indexBox.Text = indexRawURL
    -- optional: auto load index on start (comment/uncomment as needed)
    -- loadIndexBtn:Fire() is not available, so call function directly
    -- simulate click:
    spawn(function()
        task.wait(0.6)
        loadIndexBtn:Capture() -- some executors might not support Capture; ignore
        -- instead just call loadIndexBtn handler:
        loadIndexBtn:GetPropertyChangedSignal("Text"):Connect(function() end)
        -- directly call load logic:
        loadIndexBtn.MouseButton1Click:Connect(function() end) -- noop to avoid errors
    end)
end

-- initialize UI lists from any already-loaded index
rebuildRecordedList()
rebuildTemplateList()

notify("Pastebin Checkpoint Manager ready", 1.8)

-- Expose some debug globals
_G.CP_fetch_raw = fetch_raw
_G.CP_pastebin_create = pastebin_create_paste
_G.CP_index_raw_url = indexRawURL

-- End of script
