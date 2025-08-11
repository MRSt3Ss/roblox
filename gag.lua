-- Universal Remote Spy (FireServer / InvokeServer) with GUI
-- Paste to executor (Solara/Synapse/other). Use at your own risk.
-- Captures any call to :FireServer / :InvokeServer (tries metatable hook, then hookfunction fallback)

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- cleanup previous
pcall(function()
    local prev = CoreGui:FindFirstChild("UniversalRemoteSpyGUI")
    if prev then prev:Destroy() end
end)

-- storage
local captured = {} -- { {id = n, path = "ReplicatedStorage.Remotes.X", method="FireServer", args = {...}, time=os.time()}, ... }
local capturing = false
local old_namecall = nil
local hooked_functions = {}
local nextId = 0

-- create UI
local screen = Instance.new("ScreenGui")
screen.Name = "UniversalRemoteSpyGUI"
screen.ResetOnSpawn = false
screen.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0,640,0,440)
main.Position = UDim2.new(0.18,0,0.12,0)
main.BackgroundColor3 = Color3.fromRGB(28,28,28)
main.BorderSizePixel = 0
main.Parent = screen
main.Active = true

-- draggable
local UserInput = game:GetService("UserInputService")
do
    local dragging, dragStart, startPos
    main.InputBegan:Connect(function(input)
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

-- header + title + close
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,40)
header.Position = UDim2.new(0,0,0,0)
header.BackgroundColor3 = Color3.fromRGB(40,40,40)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1,-120,1,0)
title.Position = UDim2.new(0,12,0,0)
title.BackgroundTransparency = 1
title.Text = "Universal Remote Spy — Capture FireServer / InvokeServer"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(230,230,230)
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0,100,0,28)
closeBtn.Position = UDim2.new(1,-110,0,6)
closeBtn.Text = "Close"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14
closeBtn.BackgroundColor3 = Color3.fromRGB(160,40,40)
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.MouseButton1Click:Connect(function() screen:Destroy() end)

-- left controls
local left = Instance.new("Frame", main)
left.Size = UDim2.new(0.34, -8, 1, -48)
left.Position = UDim2.new(0,8,0,48)
left.BackgroundTransparency = 1

local startBtn = Instance.new("TextButton", left)
startBtn.Size = UDim2.new(1,0,0,36)
startBtn.Position = UDim2.new(0,0,0,0)
startBtn.Text = "Start Capture"
startBtn.Font = Enum.Font.SourceSansBold
startBtn.TextSize = 14
startBtn.BackgroundColor3 = Color3.fromRGB(0,150,120)
startBtn.TextColor3 = Color3.fromRGB(255,255,255)

local stopBtn = Instance.new("TextButton", left)
stopBtn.Size = UDim2.new(1,0,0,30)
stopBtn.Position = UDim2.new(0,0,0,44)
stopBtn.Text = "Stop Capture"
stopBtn.BackgroundColor3 = Color3.fromRGB(170,90,0)
stopBtn.TextColor3 = Color3.fromRGB(255,255,255)

local clearBtn = Instance.new("TextButton", left)
clearBtn.Size = UDim2.new(1,0,0,30)
clearBtn.Position = UDim2.new(0,0,0,84)
clearBtn.Text = "Clear Captured"
clearBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
clearBtn.TextColor3 = Color3.fromRGB(255,255,255)

local autoSelectLabel = Instance.new("TextLabel", left)
autoSelectLabel.Size = UDim2.new(1,0,0,60)
autoSelectLabel.Position = UDim2.new(0,0,0,126)
autoSelectLabel.BackgroundTransparency = 1
autoSelectLabel.Text = "Workflow:\n1) Start Capture\n2) Perform the in-game action once (sell/place/etc)\n3) Stop Capture\n4) Select needed entries on right\n5) Replay Selected"
autoSelectLabel.TextWrapped = true
autoSelectLabel.TextColor3 = Color3.fromRGB(220,220,220)
autoSelectLabel.Font = Enum.Font.SourceSans
autoSelectLabel.TextSize = 12

-- replay controls
local replayLabel = Instance.new("TextLabel", left)
replayLabel.Size = UDim2.new(1,0,0,22)
replayLabel.Position = UDim2.new(0,0,0,200)
replayLabel.BackgroundTransparency = 1
replayLabel.Text = "Replay Controls:"
replayLabel.TextColor3 = Color3.fromRGB(230,230,230)
replayLabel.Font = Enum.Font.SourceSansBold
replayLabel.TextSize = 13

local repeatsBox = Instance.new("TextBox", left)
repeatsBox.Size = UDim2.new(1,0,0,28)
repeatsBox.Position = UDim2.new(0,0,0,226)
repeatsBox.PlaceholderText = "Repeats (default 3)"
repeatsBox.Text = "3"
repeatsBox.ClearTextOnFocus = false

local delayBox = Instance.new("TextBox", left)
delayBox.Size = UDim2.new(1,0,0,28)
delayBox.Position = UDim2.new(0,0,0,260)
delayBox.PlaceholderText = "Delay seconds between calls (e.g. 0.05)"
delayBox.Text = "0.05"
delayBox.ClearTextOnFocus = false

local replayBtn = Instance.new("TextButton", left)
replayBtn.Size = UDim2.new(1,0,0,36)
replayBtn.Position = UDim2.new(0,0,0,296)
replayBtn.Text = "Replay Selected"
replayBtn.BackgroundColor3 = Color3.fromRGB(0,130,200)
replayBtn.TextColor3 = Color3.fromRGB(255,255,255)

local fallbackCloneBtn = Instance.new("TextButton", left)
fallbackCloneBtn.Size = UDim2.new(1,0,0,30)
fallbackCloneBtn.Position = UDim2.new(0,0,0,340)
fallbackCloneBtn.Text = "Try Clone Selected to Backpack"
fallbackCloneBtn.BackgroundColor3 = Color3.fromRGB(120,80,160)
fallbackCloneBtn.TextColor3 = Color3.fromRGB(255,255,255)

-- right: list + detail
local right = Instance.new("Frame", main)
right.Size = UDim2.new(0.64, -16, 1, -48)
right.Position = UDim2.new(0.36, 8, 0, 48)
right.BackgroundTransparency = 1

local capLabel = Instance.new("TextLabel", right)
capLabel.Size = UDim2.new(1,0,0,22)
capLabel.Position = UDim2.new(0,0,0,0)
capLabel.BackgroundTransparency = 1
capLabel.Text = "Captured (0)"
capLabel.Font = Enum.Font.SourceSansBold
capLabel.TextColor3 = Color3.fromRGB(230,230,230)
capLabel.TextSize = 13

local scroll = Instance.new("ScrollingFrame", right)
scroll.Size = UDim2.new(1,0,0.64,0)
scroll.Position = UDim2.new(0,0,0,28)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 8

local listLayout = Instance.new("UIListLayout", scroll)
listLayout.Padding = UDim.new(0,6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local detailLabel = Instance.new("TextLabel", right)
detailLabel.Size = UDim2.new(1,0,0,24)
detailLabel.Position = UDim2.new(0,0,0.66,8)
detailLabel.BackgroundTransparency = 1
detailLabel.Text = "Selected Detail:"
detailLabel.Font = Enum.Font.SourceSansBold
detailLabel.TextColor3 = Color3.fromRGB(210,210,210)
detailLabel.TextSize = 13

local detailBox = Instance.new("TextBox", right)
detailBox.Size = UDim2.new(1,0,0.32, -12)
detailBox.Position = UDim2.new(0,0,0.68,8)
detailBox.ClearTextOnFocus = false
detailBox.MultiLine = true
detailBox.TextWrapped = true
detailBox.Text = "No selection"
detailBox.TextColor3 = Color3.fromRGB(230,230,230)
detailBox.BackgroundColor3 = Color3.fromRGB(20,20,20)

-- helper functions
local function tostring_safe(v)
    local ok, s = pcall(function()
        if typeof(v) == "Instance" then
            return ("Instance(%s)"):format(v:GetFullName())
        elseif typeof(v) == "table" then
            local parts={}
            for i,k in ipairs(v) do
                table.insert(parts, tostring_safe(k))
                if #parts >= 8 then break end
            end
            return ("{ %s%s }"):format(table.concat(parts, ", "), (#parts>=8) and ",..." or "")
        else
            return tostring(v)
        end
    end)
    return ok and s or "<unprintable>"
end

local function addCapturedEntry(path, method, args)
    nextId = nextId + 1
    local entry = { id = nextId, path = path, method = method, args = args, time = os.time() }
    table.insert(captured, entry)

    -- create button in list
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-8,0,36)
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    btn.TextColor3 = Color3.fromRGB(230,230,230)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 13
    btn.AutomaticSize = Enum.AutomaticSize.Y
    btn.TextWrapped = true
    btn.LayoutOrder = #captured
    btn.Name = "Entry_"..entry.id
    btn.Parent = scroll
    local argPreview = {}
    for i,a in ipairs(args) do
        table.insert(argPreview, tostring_safe(a))
        if #argPreview >= 4 then break end
    end
    local preview = table.concat(argPreview, ", ")
    btn.Text = string.format("[%d] %s | %s | %s", entry.id, entry.path, method, preview)

    local selected = false
    btn.MouseButton1Click:Connect(function()
        selected = not selected
        btn.BackgroundColor3 = selected and Color3.fromRGB(45,120,45) or Color3.fromRGB(60,60,60)
        entry._selected = selected
        -- update detail box
        local lines = {}
        table.insert(lines, ("ID: %d"):format(entry.id))
        table.insert(lines, ("Path: %s"):format(entry.path))
        table.insert(lines, ("Method: %s"):format(entry.method))
        table.insert(lines, ("Time: %s"):format(os.date("%X", entry.time)))
        table.insert(lines, "Args:")
        for i,a in ipairs(entry.args) do table.insert(lines, ("  [%d] = %s"):format(i, tostring_safe(a))) end
        detailBox.Text = table.concat(lines, "\n")
    end)

    capLabel.Text = ("Captured (%d)"):format(#captured)
end

-- metatable hook attempt
local function try_metatable_hook()
    local ok, mt = pcall(getrawmetatable, game)
    if not ok or not mt then return false, "getrawmetatable failed" end
    if not mt.__namecall then return false, "__namecall not found" end
    if old_namecall then return true end
    old_namecall = mt.__namecall
    local newf
    newf = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if capturing and (method == "FireServer" or method == "InvokeServer") then
            local s, fullname = pcall(function() return self:GetFullName() end)
            if s and fullname then
                local copy = {}
                for i,v in ipairs(args) do copy[i] = v end
                addCapturedEntry(fullname, method, copy)
            end
        end
        return old_namecall(self, ...)
    end)
    pcall(function()
        setreadonly(mt, false)
        mt.__namecall = newf
        setreadonly(mt, true)
    end)
    return true
end

-- fallback: hookfunction per-remote (if available)
local function hook_all_remotes()
    if type(hookfunction) ~= "function" then return false, "hookfunction unavailable" end
    local function tryhook(obj)
        if not obj then return end
        if obj:IsA("RemoteEvent") then
            if not hooked_functions[obj] then
                pcall(function()
                    local orig = obj.FireServer
                    hooked_functions[obj] = hookfunction(orig, function(self, ...)
                        if capturing then
                            local args = {...}
                            local copy = {}
                            for i,v in ipairs(args) do copy[i]=v end
                            addCapturedEntry(obj:GetFullName(), "FireServer", copy)
                        end
                        return orig(self, ...)
                    end)
                end)
            end
        elseif obj:IsA("RemoteFunction") then
            if not hooked_functions[obj] then
                pcall(function()
                    local orig = obj.InvokeServer
                    hooked_functions[obj] = hookfunction(orig, function(self, ...)
                        if capturing then
                            local args = {...}
                            local copy = {}
                            for i,v in ipairs(args) do copy[i]=v end
                            addCapturedEntry(obj:GetFullName(), "InvokeServer", copy)
                        end
                        return orig(self, ...)
                    end)
                end)
            end
        end
    end
    for _,obj in ipairs(game:GetDescendants()) do tryhook(obj) end
    -- auto-hook new remotes
    game.DescendantAdded:Connect(function(d)
        pcall(function() tryhook(d) end)
    end)
    return true
end

-- start/stop handlers
startBtn.MouseButton1Click:Connect(function()
    if capturing then return end
    captured = {}
    for _,c in ipairs(scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    capLabel.Text = "Captured (0)"
    detailBox.Text = "No selection"

    local ok, err = pcall(try_metatable_hook)
    if ok then
        -- metatable hook applied (or was already applied)
        capturing = true
        startBtn.Text = "Capturing..."
        startBtn.BackgroundColor3 = Color3.fromRGB(0,200,120)
        print("[Spy] Metatable hook applied. Capture started.")
        return
    end

    -- fallback
    local ok2, err2 = pcall(hook_all_remotes)
    if ok2 then
        capturing = true
        startBtn.Text = "Capturing (hookfunction)"
        startBtn.BackgroundColor3 = Color3.fromRGB(0,180,120)
        print("[Spy] Hookfunction fallback applied. Capture started.")
        return
    end

    warn("[Spy] Failed to hook (metatable/hookfunction). Errors:", err, err2)
end)

stopBtn.MouseButton1Click:Connect(function()
    if not capturing then return end
    capturing = false
    startBtn.Text = "Start Capture"
    startBtn.BackgroundColor3 = Color3.fromRGB(0,150,120)
    print("[Spy] Capture stopped. Total captured:", #captured)
end)

clearBtn.MouseButton1Click:Connect(function()
    captured = {}
    for _,c in ipairs(scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    capLabel.Text = "Captured (0)"
    detailBox.Text = "No selection"
end)

-- replay selected
replayBtn.MouseButton1Click:Connect(function()
    local seq = {}
    for _,entry in ipairs(captured) do
        if entry._selected then table.insert(seq, entry) end
    end
    if #seq == 0 then warn("No entries selected"); return end
    local repeats = tonumber(repeatsBox.Text) or 1
    local delaySec = tonumber(delayBox.Text) or 0.05
    print(("[Spy] Replaying %d entries x %d repeats (delay %s)"):format(#seq, repeats, tostring(delaySec)))
    for r=1,repeats do
        for _,e in ipairs(seq) do
            local ok, err = pcall(function()
                -- resolve object by path: split on '.' and find children
                local root = game
                for part in string.gmatch(e.path, "([^%.]+)") do
                    if root then root = root:FindFirstChild(part) end
                end
                if not root then error("target not found: "..e.path) end
                if e.method == "FireServer" and typeof(root.FireServer) == "function" then
                    root:FireServer(unpack(e.args))
                elseif e.method == "InvokeServer" and typeof(root.InvokeServer) == "function" then
                    root:InvokeServer(unpack(e.args))
                else
                    error("target not a remote or method mismatch")
                end
            end)
            if not ok then
                warn("[Spy] Replay error:", err)
            end
            task.wait(delaySec)
        end
    end
    print("[Spy] Replay done.")
end)

-- fallback clone selected: try cloning Instance args into Backpack
fallbackCloneBtn.MouseButton1Click:Connect(function()
    local found = false
    for _,e in ipairs(captured) do
        if e._selected then
            for _,a in ipairs(e.args) do
                if typeof(a) == "Instance" and a:IsDescendantOf(game.Workspace) then
                    local ok, err = pcall(function()
                        local clone = a:Clone()
                        local bp = Players.LocalPlayer:FindFirstChild("Backpack") or Players.LocalPlayer
                        clone.Parent = bp
                        print("[Spy] Cloned to Backpack:", a:GetFullName())
                    end)
                    if not ok then warn("Clone fail:", err) end
                    found = true
                end
            end
        end
    end
    if not found then warn("No clonable Instance args found in selected entries.") end
end)

-- utility: if new captured entries were added by metatable hook we need to visually add them
-- The metatable hook adds via addCapturedEntry already -> done.

-- final message
print("[UniversalRemoteSpy] Ready. Start capture, perform the in-game action, stop capture, select entries, then replay.")
