-- Sniffer & Replay RemoteEvent (improved) + Draggable GUI
-- Paste di executor (Solara PC). Lakukan aksi spawn/dupe di game setelah start.

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Clean previous UI if any
pcall(function() local prev = CoreGui:FindFirstChild("EventSnifferGUI") if prev then prev:Destroy() end end)

-- Data
local capturedList = {} -- { {path=..., args={...}, time=os.time()} , ... }
local sniffing = false
local hooksApplied = false
local hookedRemoteFunctions = {} -- keep refs if hooking per-remote
local mtHooked = false

-- UI BUILD
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EventSnifferGUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 520, 0, 420)
Frame.Position = UDim2.new(0.25, 0, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

-- Drag support (manual, robust)
Frame.Active = true
local dragging, dragStart, startPos = false, nil, nil
local function enableDrag(frame)
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and dragStart and startPos then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
enableDrag(Frame)

-- Header / Title
local Header = Instance.new("Frame", Frame)
Header.Size = UDim2.new(1,0,0,36)
Header.Position = UDim2.new(0,0,0,0)
Header.BackgroundColor3 = Color3.fromRGB(45,45,45)
local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1,-60,1,0)
Title.Position = UDim2.new(0,8,0,0)
Title.BackgroundTransparency = 1
Title.Text = "RemoteEvent Sniffer & Replay"
Title.TextColor3 = Color3.fromRGB(220,220,220)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0,44,0,28)
CloseBtn.Position = UDim2.new(1,-52,0,4)
CloseBtn.Text = "Close"
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 12
CloseBtn.BackgroundColor3 = Color3.fromRGB(160,40,40)
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Left: controls
local Left = Instance.new("Frame", Frame)
Left.Size = UDim2.new(0.36, -8, 1, -46)
Left.Position = UDim2.new(0,6,0,42)
Left.BackgroundTransparency = 1

local btnEnable = Instance.new("TextButton", Left)
btnEnable.Size = UDim2.new(1,0,0,34)
btnEnable.Position = UDim2.new(0,0,0,0)
btnEnable.Text = "Enable Sniffer"
btnEnable.BackgroundColor3 = Color3.fromRGB(0,150,120)
btnEnable.TextColor3 = Color3.fromRGB(255,255,255)

local btnScanRemotes = Instance.new("TextButton", Left)
btnScanRemotes.Size = UDim2.new(1,0,0,30)
btnScanRemotes.Position = UDim2.new(0,0,0,44)
btnScanRemotes.Text = "Scan & Hook Existing RemoteEvents"
btnScanRemotes.BackgroundColor3 = Color3.fromRGB(0,120,170)
btnScanRemotes.TextColor3 = Color3.fromRGB(255,255,255)

local btnClear = Instance.new("TextButton", Left)
btnClear.Size = UDim2.new(1,0,0,30)
btnClear.Position = UDim2.new(0,0,0,80)
btnClear.Text = "Clear Captured List"
btnClear.BackgroundColor3 = Color3.fromRGB(140,140,140)
btnClear.TextColor3 = Color3.fromRGB(255,255,255)

local helpLabel = Instance.new("TextLabel", Left)
helpLabel.Size = UDim2.new(1,0,0,80)
helpLabel.Position = UDim2.new(0,0,0,120)
helpLabel.BackgroundTransparency = 1
helpLabel.Text = "Cara: enable sniffer -> lakukan aksi spawn/dupe di game -> item akan muncul di list. Klik item untuk replay."
helpLabel.TextColor3 = Color3.fromRGB(200,200,200)
helpLabel.TextWrapped = true
helpLabel.TextSize = 12
helpLabel.Font = Enum.Font.SourceSans

-- Right: captured list
local Right = Instance.new("Frame", Frame)
Right.Size = UDim2.new(0.62, -14, 1, -46)
Right.Position = UDim2.new(0.38, 8, 0, 42)
Right.BackgroundTransparency = 1

local CapLabel = Instance.new("TextLabel", Right)
CapLabel.Size = UDim2.new(1,0,0,20)
CapLabel.Position = UDim2.new(0,0,0,0)
CapLabel.BackgroundTransparency = 1
CapLabel.Text = "Captured Events (0)"
CapLabel.TextColor3 = Color3.fromRGB(220,220,220)
CapLabel.Font = Enum.Font.SourceSansBold
CapLabel.TextSize = 13

local Scroll = Instance.new("ScrollingFrame", Right)
Scroll.Size = UDim2.new(1,0,1,-28)
Scroll.Position = UDim2.new(0,0,0,26)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 8

local UIList = Instance.new("UIListLayout", Scroll)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0,6)

-- auto canvas size update
local function updateCanvas()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 12)
end
UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

-- UTIL: add button for captured event entry
local function makeReplayButton(entry)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    btn.TextColor3 = Color3.fromRGB(230,230,230)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 13
    btn.AutoButtonColor = true
    btn.LayoutOrder = #capturedList
    local summary = entry.path.." | args: "..tostring(#entry.args)
    btn.Text = summary
    btn.Parent = Scroll

    -- hover show details
    local tip = Instance.new("TextLabel")
    tip.Size = UDim2.new(1, -8, 0, 26)
    tip.BackgroundTransparency = 1
    tip.TextWrapped = true
    tip.TextSize = 12
    tip.Font = Enum.Font.SourceSans
    tip.TextColor3 = Color3.fromRGB(200,200,200)
    tip.Text = "Click to replay. Args: " .. table.concat((function()
        local t = {}
        for i,v in ipairs(entry.args) do
            local vt = typeof(v)
            if vt == "Instance" and v.Name then
                table.insert(t, ("Instance(%s)"):format(v.Name))
            else
                table.insert(t, tostring(v))
            end
        end
        return t
    end)(), ", ")
    tip.Parent = btn
    tip.Position = UDim2.new(0,6,1,4)

    -- replay on click
    btn.MouseButton1Click:Connect(function()
        local success, err = pcall(function()
            -- resolve path to object
            local obj = game
            for _, part in ipairs(string.split(entry.path, ".")) do
                if not obj then break end
                obj = obj:FindFirstChild(part)
            end
            if not obj then error("Target RemoteEvent not found (path stale).") end
            if typeof(obj.FireServer) ~= "function" and not obj:IsA("RemoteEvent") then
                -- sometimes ev bound differently; try find as RemoteEvent
                if not obj:IsA("RemoteEvent") then error("Target is not RemoteEvent") end
            end
            -- call
            local ok, r = pcall(function() obj:FireServer(unpack(entry.args)) end)
            if not ok then error(r) end
        end)
        if not success then
            warn("[REPLAY ERROR] "..tostring(err))
        else
            print("[REPLAY OK] "..entry.path)
        end
    end)

    updateCanvas()
end

-- Add captured entry (store & UI)
local function addCaptured(path, args)
    table.insert(capturedList, {path = path, args = args, time = os.time()})
    CapLabel.Text = "Captured Events ("..#capturedList..")"
    makeReplayButton(capturedList[#capturedList])
end

-- SAFE copy args (shallow)
local function copyArgs(tbl)
    local out = {}
    for i,v in ipairs(tbl) do out[i] = v end
    return out
end

-- SNIFER: Try metatable __namecall hook
local function tryHookMetatable()
    local ok, mt = pcall(getrawmetatable, game)
    if not ok or not mt then return false, "getrawmetatable failed" end
    local old = mt.__namecall
    if not old then return false, "__namecall not found" end
    local succes1, err1 = pcall(function()
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if method == "FireServer" then
                local s, fullname = pcall(function() return self:GetFullName() end)
                if s and fullname then
                    -- store shallow-copied args (pcall each to avoid errors)
                    local okArgs = {}
                    for i,v in ipairs(args) do
                        okArgs[i] = v
                    end
                    -- avoid duplicate spam: if last entry same path+args, skip
                    local last = capturedList[#capturedList]
                    if not last or last.path ~= fullname or tostring(last.args[1]) ~= tostring(okArgs[1]) then
                        addCaptured(fullname, okArgs)
                    end
                end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end)
    if not succes1 then
        return false, succes1 and nil or tostring(err1)
    end
    mtHooked = true
    return true
end

-- Fallback: hookfunction on each RemoteEvent.FireServer if hookfunction exists
local function hookAllExistingRemotes()
    if typeof(hookfunction) ~= "function" then return false, "hookfunction not available" end
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            pcall(function()
                local orig = obj.FireServer
                if type(orig) == "function" and not hookedRemoteFunctions[obj] then
                    hookedRemoteFunctions[obj] = hookfunction(orig, function(self, ...)
                        local args = {...}
                        local s, fullname = pcall(function() return obj:GetFullName() end)
                        if s and fullname then
                            addCaptured(fullname, copyArgs(args))
                        end
                        return orig(self, ...)
                    end)
                end
            end)
        end
    end
    return true
end

-- Keep hooking new RemoteEvents if hookfunction exists
if typeof(hookfunction) == "function" then
    Workspace.DescendantAdded:Connect(function(d)
        if d:IsA("RemoteEvent") then
            pcall(function()
                local orig = d.FireServer
                if type(orig) == "function" and not hookedRemoteFunctions[d] then
                    hookedRemoteFunctions[d] = hookfunction(orig, function(self, ...)
                        local args = {...}
                        local s, fullname = pcall(function() return d:GetFullName() end)
                        if s and fullname then
                            addCaptured(fullname, copyArgs(args))
                        end
                        return orig(self, ...)
                    end)
                end
            end)
        end
    end)
    ReplicatedStorage.DescendantAdded:Connect(function(d)
        if d:IsA("RemoteEvent") then
            pcall(function()
                local orig = d.FireServer
                if type(orig) == "function" and not hookedRemoteFunctions[d] then
                    hookedRemoteFunctions[d] = hookfunction(orig, function(self, ...)
                        local args = {...}
                        local s, fullname = pcall(function() return d:GetFullName() end)
                        if s and fullname then
                            addCaptured(fullname, copyArgs(args))
                        end
                        return orig(self, ...)
                    end)
                end
            end)
        end
    end)
end

-- Buttons behavior
btnEnable.MouseButton1Click:Connect(function()
    if sniffing then
        sniffing = false
        btnEnable.Text = "Enable Sniffer"
        btnEnable.BackgroundColor3 = Color3.fromRGB(0,150,120)
        print("[SNIFFER] Disabled")
        return
    end

    -- try metatable first
    local ok, err = pcall(tryHookMetatable)
    if ok and err then
        sniffing = true
        btnEnable.Text = "Sniffer: ON (metatable)"
        btnEnable.BackgroundColor3 = Color3.fromRGB(0,200,100)
        print("[SNIFFER] Metatable hook applied")
    else
        -- fallback to hookfunction per-remote
        local ok2, err2 = pcall(hookAllExistingRemotes)
        if ok2 then
            sniffing = true
            btnEnable.Text = "Sniffer: ON (hookfunction)"
            btnEnable.BackgroundColor3 = Color3.fromRGB(0,200,100)
            print("[SNIFFER] Hookfunction applied to existing RemoteEvents")
        else
            -- final fallback: inform user
            sniffing = false
            btnEnable.Text = "Enable Sniffer"
            btnEnable.BackgroundColor3 = Color3.fromRGB(160,40,40)
            warn("[SNIFFER] Failed to hook. Error:", err or err2)
        end
    end
end)

btnScanRemotes.MouseButton1Click:Connect(function()
    -- show simple list popup (console) and attempt to hook each RemoteEvent (if hookfunction available)
    local found = {}
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            table.insert(found, obj:GetFullName())
        end
    end
    table.sort(found)
    print("[SCAN] RemoteEvents found:")
    for _, v in ipairs(found) do print(" - "..v) end
    -- try to hook all if possible
    local ok, msg = pcall(hookAllExistingRemotes)
    if ok then
        print("[SCAN] Hook attempts done (hookfunction mode).")
    else
        print("[SCAN] Hook attempt failed or hookfunction unavailable.")
    end
end)

btnClear.MouseButton1Click:Connect(function()
    capturedList = {}
    for _, child in ipairs(Scroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    CapLabel.Text = "Captured Events (0)"
    updateCanvas()
end)

-- final note print
print("[READY] Sniffer UI ready. Tekan 'Enable Sniffer', lalu lakukan aksi spawn/dupe di game untuk merekam RemoteEvent.")

