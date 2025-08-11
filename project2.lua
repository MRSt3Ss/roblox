-- Pastebin Checkpoint Manager (Optimized Final)
-- Features:
--  - Separate Login screen -> Main menu
--  - Admin: record CP, custom-name Save (upload to Pastebin), Delete template (requires Pastebin account login to get api_user_key)
--  - User: load index from Pastebin, load templates, manual TP, Auto-TP
--  - Draggable UI, Minimize, efficient Auto-TP loop
--  - Local index raw URL saved via writefile/readfile if available
-- SECURITY: Keep your Pastebin API Developer Key and Pastebin account credentials private.

-- ============ CONFIG ============
local PASTEBIN_API_KEY = "1whRCEY7X8SQXRWnet8gvBlGbk5K4zzQ" -- dev key (keep private)
local PASTEBIN_API_POST = "https://pastebin.com/api/api_post.php"
local PASTEBIN_API_LOGIN = "https://pastebin.com/api/api_login.php"
local PASTE_PRIVACY = "1" -- 0 public / 1 unlisted

-- local storage file for index raw url
local INDEX_URL_FILE = "cp_index_raw_url.txt"
-- =================================

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local UserInput = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- safe local storage (writefile/readfile fallback)
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

-- HTTP wrapper (tries many executor functions)
local function http_request(req)
    local callers = {
        function(r) if syn and syn.request then return syn.request(r) end end,
        function(r) if http_request then return http_request(r) end end, -- keep fallback name safe
        function(r) if request then return request(r) end end,
        function(r) if http and http.request then return http.request(r) end end,
        function(r) return game:GetService("HttpService"):RequestAsync(r) end -- this normally errors in Roblox env, kept for completeness
    }
    for _,fn in ipairs(callers) do
        local ok, res = pcall(fn, req)
        if ok and res then
            -- normalize common fields
            local body = res.Body or res.body or res.response or res.Response or tostring(res)
            local code = res.StatusCode or res.status or res.Status or (res.Success and 200) or 200
            return { Body = tostring(body), StatusCode = tonumber(code) or 200, Raw = res }
        end
    end
    return nil, "no-http"
end

-- Pastebin helpers
local function pastebin_create_paste(content, title)
    local postBody = "api_dev_key="..HttpService:UrlEncode(tostring(PASTEBIN_API_KEY))
                   .. "&api_option=paste"
                   .. "&api_paste_code="..HttpService:UrlEncode(tostring(content))
                   .. "&api_paste_private="..HttpService:UrlEncode(tostring(PASTE_PRIVACY))
                   .. "&api_paste_name="..HttpService:UrlEncode(tostring(title or "cp_template"))
    local req = { Url = PASTEBIN_API_POST, Method = "POST", Headers = { ["Content-Type"] = "application/x-www-form-urlencoded" }, Body = postBody }
    local res, err = http_request(req)
    if not res then return nil, err end
    if res.StatusCode >= 200 and res.StatusCode < 300 then
        local url = tostring(res.Body)
        local key = url:match("pastebin%.com/(.+)$")
        if key then key = key:gsub("%s","") return key end
        return nil, "invalid-response"
    else
        return nil, "http-"..tostring(res.StatusCode)
    end
end

local function pastebin_login(username, password)
    -- returns api_user_key or nil,err
    local body = "api_dev_key="..HttpService:UrlEncode(tostring(PASTEBIN_API_KEY))
               .. "&api_user_name="..HttpService:UrlEncode(tostring(username))
               .. "&api_user_password="..HttpService:UrlEncode(tostring(password))
    local req = { Url = PASTEBIN_API_LOGIN, Method = "POST", Headers = { ["Content-Type"] = "application/x-www-form-urlencoded" }, Body = body }
    local res, err = http_request(req)
    if not res then return nil, err end
    local b = tostring(res.Body or "")
    if b:find("Bad API request") then return nil, b end
    -- on success returns api_user_key
    return b
end

local function paste_key_to_raw_url(key)
    if not key then return nil end
    return "https://pastebin.com/raw/"..tostring(key)
end

local function fetch_raw(url)
    local req = { Url = url, Method = "GET" }
    local res, err = http_request(req)
    if not res then return nil, err end
    if res.StatusCode >= 200 and res.StatusCode < 300 then return tostring(res.Body) end
    return nil, "http-"..tostring(res.StatusCode)
end

local function pastebin_delete_paste(api_user_key, paste_key)
    -- requires api_dev_key + api_user_key + api_paste_key and api_option=delete
    local body = "api_dev_key="..HttpService:UrlEncode(tostring(PASTEBIN_API_KEY))
               .. "&api_user_key="..HttpService:UrlEncode(tostring(api_user_key))
               .. "&api_paste_key="..HttpService:UrlEncode(tostring(paste_key))
               .. "&api_option=delete"
    local req = { Url = PASTEBIN_API_POST, Method = "POST", Headers = { ["Content-Type"] = "application/x-www-form-urlencoded" }, Body = body }
    local res, err = http_request(req)
    if not res then return false, err end
    local b = tostring(res.Body or "")
    if b:find("Paste Removed") or b == "" then
        return true
    elseif b:find("Bad API request") then
        return false, b
    else
        -- Pastebin often returns "Paste Removed" or empty; treat other as failure
        return (res.StatusCode >= 200 and res.StatusCode < 300), b
    end
end

-- ========= Data / state =========
local recordedCPs = {}       -- admin temporary recorded list: { {x,y,z,name} }
local indexRawURL = nil      -- stored local index raw url (string)
local templatesIndex = {}    -- loaded index: array of { name=, key= }
local loadedTemplate = nil   -- { name=, cps = { {x,y,z,name} } }

-- try load local saved index raw url
local stored = safe_readfile(INDEX_URL_FILE)
if stored and type(stored) == "string" and #stored > 5 then indexRawURL = stored end

-- ======= UI Build (clean + minimal) =======
pcall(function() local old = CoreGui:FindFirstChild("PB_CP_UI_FINAL") if old then old:Destroy() end end)
local screen = Instance.new("ScreenGui", CoreGui); screen.Name = "PB_CP_UI_FINAL"; screen.ResetOnSpawn = false

-- MAIN container (hidden until login)
local main = Instance.new("Frame", screen)
main.Name = "Main"
main.Size = UDim2.new(0,760,0,520)
main.Position = UDim2.new(0.12,0,0.06,0)
main.BackgroundColor3 = Color3.fromRGB(18,20,18)
main.BorderSizePixel = 0
main.Visible = false
main.Active = true

-- LOGIN container (visible first)
local loginFrame = Instance.new("Frame", screen)
loginFrame.Name = "Login"
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
loginBtn.Size = UDim2.new(1,-24,0,36); loginBtn.Position = UDim2.new(0,12,0,156); loginBtn.Font=Enum.Font.GothamBold; loginBtn.Text="Login"; loginBtn.BackgroundColor3=Color3.fromRGB(0,160,120)
local loginNote = Instance.new("TextLabel", loginFrame)
loginNote.Size = UDim2.new(1,-24,0,18); loginNote.Position = UDim2.new(0,12,1,-26); loginNote.BackgroundTransparency=1; loginNote.TextColor3=Color3.fromRGB(200,200,200)
loginNote.Text = "(Credentials are private — don't share the script with others)"

-- Header inside main (draggable + minimize + close)
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,56); header.Position = UDim2.new(0,0,0,0); header.BackgroundTransparency = 1
local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.7,-8,1,0); title.Position = UDim2.new(0,12,0,0); title.BackgroundTransparency=1
title.Font = Enum.Font.GothamBlack; title.TextSize = 18; title.Text = "CP Manager — Pastebin (Final)"; title.TextColor3 = Color3.fromRGB(170,255,200); title.TextXAlignment = Enum.TextXAlignment.Left
local roleLabel = Instance.new("TextLabel", header)
roleLabel.Size = UDim2.new(0.28,-20,1,0); roleLabel.Position = UDim2.new(0.72,8,0,0); roleLabel.BackgroundTransparency = 1; roleLabel.Font = Enum.Font.GothamSemibold; roleLabel.TextSize = 14; roleLabel.Text = "Role: -"; roleLabel.TextColor3 = Color3.fromRGB(220,220,220)
local btnMin = Instance.new("TextButton", header); btnMin.Size = UDim2.new(0,36,0,36); btnMin.Position = UDim2.new(1,-88,0,10); btnMin.Text="▁"; btnMin.Font=Enum.Font.Gotham; btnMin.BackgroundColor3=Color3.fromRGB(200,200,0)
local btnClose = Instance.new("TextButton", header); btnClose.Size = UDim2.new(0,36,0,36); btnClose.Position = UDim2.new(1,-44,0,10); btnClose.Text="X"; btnClose.Font=Enum.Font.GothamBold; btnClose.BackgroundColor3=Color3.fromRGB(160,40,40)

-- make main draggable via header
do
    local dragging, dragStart, startPos
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

-- Left admin area
local left = Instance.new("Frame", main); left.Size = UDim2.new(0.38,-12,1,-80); left.Position = UDim2.new(0,12,0,68); left.BackgroundTransparency = 1
local addBtn = Instance.new("TextButton", left); addBtn.Size = UDim2.new(1,0,0,36); addBtn.Position = UDim2.new(0,0,0,0); addBtn.Text="Add Checkpoint"; addBtn.BackgroundColor3=Color3.fromRGB(0,200,140); addBtn.Font=Enum.Font.GothamBold
local saveBtn = Instance.new("TextButton", left); saveBtn.Size = UDim2.new(1,0,0,34); saveBtn.Position = UDim2.new(0,0,0,44); saveBtn.Text="Save to Pastebin (custom name)"; saveBtn.BackgroundColor3=Color3.fromRGB(0,140,200)
local deleteBtn = Instance.new("TextButton", left); deleteBtn.Size = UDim2.new(1,0,0,34); deleteBtn.Position = UDim2.new(0,0,0,82); deleteBtn.Text="Delete Template (Pastebin)"; deleteBtn.BackgroundColor3=Color3.fromRGB(180,60,60)
local savedNote = Instance.new("TextLabel", left); savedNote.Size = UDim2.new(1,0,0,18); savedNote.Position = UDim2.new(0,0,0,122); savedNote.BackgroundTransparency=1; savedNote.Text="Index RAW URL (local):"; savedNote.TextColor3=Color3.fromRGB(200,200,200)
local indexBox = Instance.new("TextBox", left); indexBox.Size = UDim2.new(1,0,0,32); indexBox.Position = UDim2.new(0,0,0,140); indexBox.PlaceholderText="paste index raw url here (or leave)"; indexBox.Text = indexRawURL or ""; indexBox.BackgroundColor3=Color3.fromRGB(28,28,28); indexBox.TextColor3=Color3.fromRGB(230,230,230)
local saveIndexBtn = Instance.new("TextButton", left); saveIndexBtn.Size = UDim2.new(1,0,0,30); saveIndexBtn.Position = UDim2.new(0,0,0,176); saveIndexBtn.Text="Save Index URL Locally"; saveIndexBtn.BackgroundColor3=Color3.fromRGB(80,80,80)
local recordedLabel = Instance.new("TextLabel", left); recordedLabel.Size = UDim2.new(1,0,0,18); recordedLabel.Position = UDim2.new(0,0,0,212); recordedLabel.BackgroundTransparency=1; recordedLabel.Text="Recorded Checkpoints:"; recordedLabel.TextColor3=Color3.fromRGB(220,220,220)
local cpScroll = Instance.new("ScrollingFrame", left); cpScroll.Size = UDim2.new(1,0,0,220); cpScroll.Position = UDim2.new(0,0,0,232); cpScroll.ScrollBarThickness = 8; cpScroll.BackgroundTransparency = 0.04
local cpLayout = Instance.new("UIListLayout", cpScroll); cpLayout.Padding = UDim.new(0,6)

-- Right templates area
local right = Instance.new("Frame", main); right.Size = UDim2.new(0.6,-12,1,-80); right.Position = UDim2.new(0.38,8,0,68); right.BackgroundTransparency = 1
local loadIndexBtn = Instance.new("TextButton", right); loadIndexBtn.Size = UDim2.new(0.48,-6,0,34); loadIndexBtn.Position = UDim2.new(0,0,0,0); loadIndexBtn.Text="Load Index from Pastebin"; loadIndexBtn.BackgroundColor3=Color3.fromRGB(0,120,200)
local refreshBtn = Instance.new("TextButton", right); refreshBtn.Size = UDim2.new(0.48,-6,0,34); refreshBtn.Position = UDim2.new(0.52,6,0,0); refreshBtn.Text="Refresh List"; refreshBtn.BackgroundColor3=Color3.fromRGB(80,80,80)
local tmplScroll = Instance.new("ScrollingFrame", right); tmplScroll.Size = UDim2.new(1,0,0.74,0); tmplScroll.Position = UDim2.new(0,0,0,40); tmplScroll.ScrollBarThickness = 8; tmplScroll.BackgroundTransparency = 0.04
local tmplLayout = Instance.new("UIListLayout", tmplScroll); tmplLayout.Padding = UDim.new(0,6)
local autoToggle = Instance.new("TextButton", right); autoToggle.Size = UDim2.new(0.48,-6,0,36); autoToggle.Position = UDim2.new(0,0,0,0.74); autoToggle.Text="Auto TP: OFF"; autoToggle.BackgroundColor3=Color3.fromRGB(70,70,70)
local intervalBox = Instance.new("TextBox", right); intervalBox.Size = UDim2.new(0.48,-6,0,36); intervalBox.Position = UDim2.new(0.52,6,0,0.74); intervalBox.Text="2"; intervalBox.PlaceholderText="Interval seconds"
local manualTPBtn = Instance.new("TextButton", right); manualTPBtn.Size = UDim2.new(1,0,0,36); manualTPBtn.Position = UDim2.new(0,0,0,0.82); manualTPBtn.Text="Manual TP to Template CP"; manualTPBtn.BackgroundColor3=Color3.fromRGB(0,150,140)
local adminLabel = Instance.new("TextLabel", main); adminLabel.Size = UDim2.new(0,320,0,24); adminLabel.Position = UDim2.new(0.5,-160,1,-40); adminLabel.BackgroundTransparency=1; adminLabel.Text="Admin: None"; adminLabel.TextColor3=Color3.fromRGB(255,120,120)

-- UI state containers
local ui_template_buttons = {}
local local_templates_index = {} -- { {name=, key=} }
local selected_template_key = nil
local selected_template_name = nil
local autoTPFlag = false

-- ========== UI helpers ==========
local function clearChildren(parent)
    for _,c in ipairs(parent:GetChildren()) do
        if not (c:IsA("UIListLayout") or c:IsA("UIPadding")) then
            pcall(function() c:Destroy() end)
        end
    end
end

local function rebuildRecordedList()
    clearChildren(cpScroll)
    for i,cp in ipairs(recordedCPs) do
        local row = Instance.new("Frame", cpScroll); row.Size=UDim2.new(1,-8,0,34); row.BackgroundTransparency=0.6; row.BackgroundColor3=Color3.fromRGB(6,16,6)
        local lbl = Instance.new("TextLabel", row); lbl.Size=UDim2.new(0.9,0,1,0); lbl.Position=UDim2.new(0,8,0,0); lbl.BackgroundTransparency=1; lbl.Text = string.format("%d) %s (%.1f,%.1f,%.1f)", i, recordedCPs[i].name or ("CP"..i), recordedCPs[i].x, recordedCPs[i].y, recordedCPs[i].z)
        lbl.Font = Enum.Font.Gotham; lbl.TextColor3 = Color3.fromRGB(200,255,200)
        local del = Instance.new("TextButton", row); del.Size = UDim2.new(0,28,0,28); del.Position = UDim2.new(1,-36,0.06,0); del.Text="✕"; del.BackgroundColor3 = Color3.fromRGB(200,40,40)
        del.MouseButton1Click:Connect(function()
            table.remove(recordedCPs, i)
            rebuildRecordedList()
        end)
    end
    cpScroll.CanvasSize = UDim2.new(0,0,0, math.max(1, #recordedCPs * 42))
end

local function rebuildTemplateList()
    clearChildren(tmplScroll)
    ui_template_buttons = {}
    for i,entry in ipairs(local_templates_index) do
        local btn = Instance.new("TextButton", tmplScroll); btn.Size=UDim2.new(1,-8,0,36); btn.Position=UDim2.new(0,6,0,(i-1)*44)
        btn.Text = entry.name; btn.BackgroundColor3 = Color3.fromRGB(60,60,60); btn.TextColor3=Color3.fromRGB(230,230,230); btn.Font = Enum.Font.Gotham
        ui_template_buttons[entry.key] = btn
        btn.MouseButton1Click:Connect(function()
            -- mark selection
            for k,b in pairs(ui_template_buttons) do if b and b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(60,60,60) end end
            btn.BackgroundColor3 = Color3.fromRGB(40,140,40)
            selected_template_key = entry.key; selected_template_name = entry.name
            -- fetch raw content
            local rawUrl = paste_key_to_raw_url(entry.key)
            notify("Fetching template '"..entry.name.."' ...", 1.2)
            spawn(function()
                local content, err = fetch_raw(rawUrl)
                if not content then notify("Fetch failed: "..tostring(err), 2); return end
                local ok, dec = pcall(function() return HttpService:JSONDecode(content) end)
                if not ok or type(dec) ~= "table" or type(dec.checkpoints) ~= "table" then notify("Template invalid JSON", 1.8); return end
                loadedTemplate = { name = entry.name, cps = dec.checkpoints }
                notify("Template loaded: "..entry.name, 1.4)
            end)
        end)
    end
    tmplScroll.CanvasSize = UDim2.new(0,0,0, math.max(1, #local_templates_index * 44))
end

-- ========== core logic actions ==========
-- add CP (admin)
addBtn.MouseButton1Click:Connect(function()
    if roleLabel.Text ~= "Role: Admin" then notify("Admin only") return end
    local ch = LocalPlayer.Character
    local hrp = ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso"))
    if not hrp then notify("Character not ready",1.2); return end
    local name = "CP "..tostring(#recordedCPs + 1)
    table.insert(recordedCPs, { x = hrp.Position.X, y = hrp.Position.Y, z = hrp.Position.Z, name = name })
    rebuildRecordedList()
    notify("CP added: "..name, 1.0)
end)

-- Save to Pastebin (admin) with custom name modal
saveBtn.MouseButton1Click:Connect(function()
    if roleLabel.Text ~= "Role: Admin" then notify("Admin only") return end
    if #recordedCPs == 0 then notify("No CP recorded",1.4); return end
    -- show modal asking name
    local modal = Instance.new("Frame", screen); modal.Size = UDim2.new(0,360,0,140); modal.Position = UDim2.new(0.5,-180,0.5,-70); modal.BackgroundColor3=Color3.fromRGB(10,12,10)
    local lbl = Instance.new("TextLabel", modal); lbl.Size=UDim2.new(1,-24,0,28); lbl.Position=UDim2.new(0,12,0,8); lbl.BackgroundTransparency=1; lbl.Text="Enter template name:"; lbl.Font=Enum.Font.GothamSemibold; lbl.TextColor3=Color3.fromRGB(200,255,200)
    local box = Instance.new("TextBox", modal); box.Size=UDim2.new(1,-24,0,34); box.Position=UDim2.new(0,12,0,44); box.PlaceholderText="GunungArunika or MyMapName"
    local ok = Instance.new("TextButton", modal); ok.Size=UDim2.new(0.46,-8,0,34); ok.Position=UDim2.new(0.02,0,1,-46); ok.Text="Save"; ok.BackgroundColor3=Color3.fromRGB(0,200,110)
    local cancel = Instance.new("TextButton", modal); cancel.Size=UDim2.new(0.46,-8,0,34); cancel.Position=UDim2.new(0.52,0,1,-46); cancel.Text="Cancel"; cancel.BackgroundColor3=Color3.fromRGB(180,60,60)
    ok.MouseButton1Click:Connect(function()
        local name = tostring(box.Text or ""):gsub("^%s*(.-)%s*$","%1")
        if name == "" then notify("Name invalid",1.4); return end
        local payload = { mapName = name, checkpoints = {} }
        for _,cp in ipairs(recordedCPs) do table.insert(payload.checkpoints, { x = cp.x, y = cp.y, z = cp.z, name = cp.name }) end
        local content = HttpService:JSONEncode(payload)
        notify("Uploading template to Pastebin...", 1.6)
        spawn(function()
            local key, err = pastebin_create_paste(content, name)
            if not key then notify("Upload failed: "..tostring(err), 3); return end
            local urlRaw = paste_key_to_raw_url(key)
            notify("Template uploaded: "..urlRaw, 3)
            -- load existing index (from indexBox or indexRawURL)
            local idxRaw = tostring(indexBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
            if idxRaw == "" then idxRaw = indexRawURL end
            local indexTable = { templates = {} }
            if idxRaw and #idxRaw > 10 then
                local contentIdx, err2 = fetch_raw(idxRaw)
                if contentIdx then
                    local ok2, dec = pcall(function() return HttpService:JSONDecode(contentIdx) end)
                    if ok2 and type(dec) == "table" and type(dec.templates) == "table" then indexTable = dec end
                end
            end
            table.insert(indexTable.templates, { name = name, key = key })
            local indexContent = HttpService:JSONEncode(indexTable)
            local idxKey, ierr = pastebin_create_paste(indexContent, "CP_Index_"..tostring(os.time()))
            if not idxKey then
                notify("Index create failed: "..tostring(ierr), 3)
                -- still save last template raw locally
                safe_writefile("last_template_url.txt", urlRaw)
                modal:Destroy()
                recordedCPs = {}
                rebuildRecordedList()
                rebuildTemplateList()
                return
            end
            local idxRawUrl = paste_key_to_raw_url(idxKey)
            safe_writefile(INDEX_URL_FILE, idxRawUrl)
            indexBox.Text = idxRawUrl
            indexRawURL = idxRawUrl
            notify("Index updated: "..idxRawUrl, 3)
            -- refresh local template list by loading index
            -- parse index into local_templates_index
            local okIdx, idxContent = pcall(function() return fetch_raw(idxRawUrl) end)
            if okIdx and idxContent then
                local ok2, dec2 = pcall(function() return HttpService:JSONDecode(idxContent) end)
                if ok2 and type(dec2) == "table" and type(dec2.templates) == "table" then
                    local_templates_index = {}
                    for _,e in ipairs(dec2.templates) do
                        if e.name and e.key then table.insert(local_templates_index, { name = e.name, key = e.key }) end
                    end
                end
            end
            rebuildTemplateList()
            modal:Destroy()
            recordedCPs = {}
            rebuildRecordedList()
        end)
    end)
    cancel.MouseButton1Click:Connect(function() modal:Destroy() end)
end)

-- Delete template (admin) — requires Pastebin account login to obtain api_user_key
deleteBtn.MouseButton1Click:Connect(function()
    if roleLabel.Text ~= "Role: Admin" then notify("Admin only") return end
    if #local_templates_index == 0 then notify("No templates in index",1.4); return end
    -- pick template to delete: open small popup list
    local p = Instance.new("Frame", screen); p.Size = UDim2.new(0,360,0,360); p.Position = UDim2.new(0.5,-180,0.5,-180); p.BackgroundColor3=Color3.fromRGB(10,12,10)
    local label = Instance.new("TextLabel", p); label.Size=UDim2.new(1,-24,0,28); label.Position=UDim2.new(0,12,0,8); label.BackgroundTransparency=1; label.Text="Select template to DELETE (uses Pastebin account login)"; label.Font=Enum.Font.GothamSemibold; label.TextColor3=Color3.fromRGB(200,200,200)
    local sframe = Instance.new("ScrollingFrame", p); sframe.Size=UDim2.new(1,-24,1,-140); sframe.Position=UDim2.new(0,12,0,44); sframe.ScrollBarThickness=6
    local layout = Instance.new("UIListLayout", sframe); layout.Padding = UDim.new(0,6)
    local close = Instance.new("TextButton", p); close.Size=UDim2.new(0,80,0,30); close.Position=UDim2.new(1,-92,1,-40); close.Text="Close"; close.BackgroundColor3=Color3.fromRGB(80,80,80)
    close.MouseButton1Click:Connect(function() p:Destroy() end)
    for _,entry in ipairs(local_templates_index) do
        local row = Instance.new("Frame", sframe); row.Size=UDim2.new(1,0,0,40); row.BackgroundTransparency=0.6; row.BackgroundColor3=Color3.fromRGB(6,16,6)
        local lbl = Instance.new("TextLabel", row); lbl.Size=UDim2.new(0.7,0,1,0); lbl.Position = UDim2.new(0,8,0,0); lbl.BackgroundTransparency=1; lbl.Text = entry.name; lbl.Font=Enum.Font.Gotham; lbl.TextColor3=Color3.fromRGB(200,255,200)
        local btn = Instance.new("TextButton", row); btn.Size=UDim2.new(0.28,0,0,28); btn.Position = UDim2.new(0.72, -6, 0.12, 0); btn.Text = "Delete"; btn.BackgroundColor3=Color3.fromRGB(180,60,60)
        btn.MouseButton1Click:Connect(function()
            -- ask for Pastebin account login (username/password) for deletion
            local credModal = Instance.new("Frame", screen); credModal.Size = UDim2.new(0,340,0,160); credModal.Position = UDim2.new(0.5,-170,0.5,-80); credModal.BackgroundColor3=Color3.fromRGB(10,12,10)
            local t = Instance.new("TextLabel", credModal); t.Size=UDim2.new(1,-24,0,28); t.Position=UDim2.new(0,12,0,8); t.BackgroundTransparency=1; t.Text="Pastebin account (required to delete)"; t.Font=Enum.Font.GothamSemibold; t.TextColor3=Color3.fromRGB(200,200,200)
            local ubox = Instance.new("TextBox", credModal); ubox.Size=UDim2.new(1,-24,0,32); ubox.Position=UDim2.new(0,12,0,44); ubox.PlaceholderText="Pastebin username"
            local pbox = Instance.new("TextBox", credModal); pbox.Size=UDim2.new(1,-24,0,32); pbox.Position=UDim2.new(0,12,0,80); pbox.PlaceholderText="Pastebin password"
            local okbtn = Instance.new("TextButton", credModal); okbtn.Size=UDim2.new(0.46,-8,0,32); okbtn.Position=UDim2.new(0.02,0,1,-44); okbtn.Text="Login & Delete"; okbtn.BackgroundColor3=Color3.fromRGB(0,160,120)
            local cancelbtn = Instance.new("TextButton", credModal); cancelbtn.Size=UDim2.new(0.46,-8,0,32); cancelbtn.Position=UDim2.new(0.52,0,1,-44); cancelbtn.Text="Cancel"; cancelbtn.BackgroundColor3=Color3.fromRGB(180,60,60)
            okbtn.MouseButton1Click:Connect(function()
                local usr = tostring(ubox.Text or ""):gsub("^%s*(.-)%s*$","%1"); local pwd = tostring(pbox.Text or ""):gsub("^%s*(.-)%s*$","%1")
                if usr == "" or pwd == "" then notify("Credentials empty",1.4); return end
                notify("Logging into Pastebin...",1.2)
                spawn(function()
                    local user_key, login_err = pastebin_login(usr, pwd)
                    if not user_key then notify("Login failed: "..tostring(login_err), 3); return end
                    notify("Logged in, deleting paste...", 1.2)
                    local success, derr = pastebin_delete_paste(user_key, entry.key)
                    if success then
                        notify("Paste deleted. Rebuilding index (will remove entry).", 2.6)
                        -- remove from local index table and upload new index paste
                        local newIndex = { templates = {} }
                        for _,e in ipairs(local_templates_index) do
                            if e.key ~= entry.key then table.insert(newIndex.templates, { name = e.name, key = e.key }) end
                        end
                        -- upload new index
                        local idxContent = HttpService:JSONEncode(newIndex)
                        local idxKey, ierr = pastebin_create_paste(idxContent, "CP_Index_"..tostring(os.time()))
                        if idxKey then
                            local idxRawUrl = paste_key_to_raw_url(idxKey)
                            safe_writefile(INDEX_URL_FILE, idxRawUrl)
                            indexBox.Text = idxRawUrl
                            indexRawURL = idxRawUrl
                            -- update local list
                            local_templates_index = {}
                            for _,e in ipairs(newIndex.templates) do table.insert(local_templates_index, { name = e.name, key = e.key }) end
                            rebuildTemplateList()
                            notify("Index updated after delete: "..idxRawUrl, 3)
                        else
                            notify("Deleted but index update failed: "..tostring(ierr), 3)
                        end
                    else
                        notify("Delete failed: "..tostring(derr), 3)
                    end
                end)
                credModal:Destroy()
                p:Destroy()
            end)
            cancelbtn.MouseButton1Click:Connect(function() credModal:Destroy() end)
        end)
    end
end)

-- Save index URL locally
saveIndexBtn.MouseButton1Click:Connect(function()
    local txt = tostring(indexBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    if txt == "" then notify("Index URL empty", 1.4); return end
    local ok, err = safe_writefile(INDEX_URL_FILE, txt)
    if ok then indexRawURL = txt; notify("Index URL saved locally", 1.4); else notify("Save failed: "..tostring(err), 1.8) end
end)

-- Load index from Pastebin (index raw url must be in indexBox or saved)
loadIndexBtn.MouseButton1Click:Connect(function()
    local idxRaw = tostring(indexBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    if idxRaw == "" then idxRaw = indexRawURL end
    if not idxRaw or #idxRaw < 10 then notify("Index URL not set. Ask admin to share index raw URL.", 2); return end
    notify("Fetching index...", 1.2)
    spawn(function()
        local content, err = fetch_raw(idxRaw)
        if not content then notify("Fetch index failed: "..tostring(err), 2.4); return end
        local ok, dec = pcall(function() return HttpService:JSONDecode(content) end)
        if not ok or type(dec) ~= "table" or type(dec.templates) ~= "table" then notify("Index invalid JSON", 2.4); return end
        local_templates_index = {}
        for _,ent in ipairs(dec.templates) do
            if type(ent.name) == "string" and type(ent.key) == "string" then table.insert(local_templates_index, { name = ent.name, key = ent.key }) end
        end
        rebuildTemplateList()
        notify("Index loaded ("..tostring(#local_templates_index).." templates).", 2)
    end)
end)

refreshBtn.MouseButton1Click:Connect(function()
    rebuildTemplateList(); notify("Template list refreshed", 1.2)
end)

-- Manual TP to selected template CP
manualTPBtn.MouseButton1Click:Connect(function()
    if not loadedTemplate or type(loadedTemplate.cps) ~= "table" or #loadedTemplate.cps == 0 then notify("No template loaded",1.4); return end
    -- build modal and list
    local modal = Instance.new("Frame", screen); modal.Size = UDim2.new(0,360,0,360); modal.Position = UDim2.new(0.5,-180,0.5,-180); modal.BackgroundColor3=Color3.fromRGB(12,14,12)
    local label = Instance.new("TextLabel", modal); label.Size = UDim2.new(1,-24,0,28); label.Position = UDim2.new(0,12,0,8); label.BackgroundTransparency=1; label.Text="Select CP to TP: "..tostring(loadedTemplate.name or ""); label.Font=Enum.Font.GothamSemibold; label.TextColor3=Color3.fromRGB(200,255,200)
    local sframe = Instance.new("ScrollingFrame", modal); sframe.Size = UDim2.new(1,-24,1,-72); sframe.Position = UDim2.new(0,12,0,44); sframe.ScrollBarThickness=6
    local layout = Instance.new("UIListLayout", sframe); layout.Padding = UDim.new(0,6)
    local close = Instance.new("TextButton", modal); close.Size = UDim2.new(0,80,0,30); close.Position = UDim2.new(1,-92,1,-40); close.Text="Close"; close.BackgroundColor3=Color3.fromRGB(0,120,40)
    close.MouseButton1Click:Connect(function() modal:Destroy() end)
    for i,cp in ipairs(loadedTemplate.cps) do
        local b = Instance.new("TextButton", sframe); b.Size = UDim2.new(1,0,0,36); b.Text = string.format("%d) %s (%.1f,%.1f,%.1f)", i, (cp.name or "CP"..i), cp.x, cp.y, cp.z); b.BackgroundColor3=Color3.fromRGB(60,60,60); b.TextColor3=Color3.fromRGB(230,230,230)
        b.MouseButton1Click:Connect(function()
            local ch = LocalPlayer.Character
            local hrp = ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso"))
            if hrp then hrp.CFrame = CFrame.new(Vector3.new(cp.x, cp.y, cp.z) + Vector3.new(0,3,0)) end
            notify("Teleported to CP "..i, 1.2)
            modal:Destroy()
        end)
    end
end)

-- Auto TP optimized loop
local autoCoroutine = nil
local function startAutoTP()
    if autoTPFlag then return end
    if not loadedTemplate or type(loadedTemplate.cps) ~= "table" or #loadedTemplate.cps == 0 then notify("No template loaded",1.4); return end
    autoTPFlag = true; autoToggle.Text = "Auto TP: ON"; autoToggle.BackgroundColor3 = Color3.fromRGB(0,160,120)
    autoCoroutine = coroutine.create(function()
        while autoTPFlag do
            for _,cp in ipairs(loadedTemplate.cps) do
                if not autoTPFlag then break end
                local ch = LocalPlayer.Character
                local hrp = ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso"))
                if hrp then hrp.CFrame = CFrame.new(Vector3.new(cp.x, cp.y, cp.z) + Vector3.new(0,3,0)) end
                local waitSec = tonumber(intervalBox.Text) or 2
                -- use coarse sleep but check flag each iteration
                local elapsed = 0
                while elapsed < waitSec and autoTPFlag do elapsed = elapsed + 0.15; task.wait(0.15) end
            end
        end
    end)
    coroutine.resume(autoCoroutine)
    notify("Auto TP started: "..tostring(loadedTemplate.name or "template"), 1.4)
end
local function stopAutoTP()
    autoTPFlag = false; autoToggle.Text = "Auto TP: OFF"; autoToggle.BackgroundColor3 = Color3.fromRGB(70,70,70); notify("Auto TP stopped", 1.0)
end
autoToggle.MouseButton1Click:Connect(function() if autoTPFlag then stopAutoTP() else startAutoTP() end end)

-- login button (separate login -> main)
loginBtn.MouseButton1Click:Connect(function()
    local u = tostring(userBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    local p = tostring(passBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    if u == "irsad" and p == "irsad10" then
        loginFrame.Visible = false; main.Visible = true; roleLabel.Text = "Role: Admin"; notify("Logged in as admin",1.2)
    elseif u == "member" and p == "member" then
        loginFrame.Visible = false; main.Visible = true; roleLabel.Text = "Role: User"; notify("Logged in as user",1.2)
    else
        notify("Login failed",1.6)
    end
end)

-- Close and minimize
btnClose.MouseButton1Click:Connect(function() pcall(function() screen:Destroy() end) end)
local minimized = false; local normalSize = main.Size
btnMin.MouseButton1Click:Connect(function()
    if minimized then main.Size = normalSize; minimized = false else normalSize = main.Size; main.Size = UDim2.new(0,420,0,64); minimized = true end
end)

-- Admin detector (simple)
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
task.delay(0.8, checkAdmins)

-- if indexRawURL present at start, put into box
if indexRawURL and #indexRawURL > 10 then indexBox.Text = indexRawURL end

-- initial rebuilds
rebuildRecordedList()
rebuildTemplateList()

notify("CP Manager ready — login to start", 1.8)

-- expose small debugging (optional)
_G.CP_fetch_raw = fetch_raw
_G.CP_create_paste = pastebin_create_paste
_G.CP_delete_paste = pastebin_delete_paste
_G.CP_index_url = indexRawURL

-- End of script
