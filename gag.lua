-- Full Capture Session + Multi-Event Replayer (improved)
-- Use: Start Capture -> do the in-game action once -> Stop Capture -> Select events -> Replay
-- Note: Works only if server accepts replayed events (depends on game). Use at your own risk.

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- cleanup old UI
pcall(function()
    local prev = CoreGui:FindFirstChild("DupeCaptureGUI")
    if prev then prev:Destroy() end
end)

-- storage
local captured = {} -- { {path = "ReplicatedStorage.SomeEvent", args = {...}, time = os.time()}, ... }
local selectedIndexes = {} -- set of indices selected for replay
local capturing = false
local oldNamecall -- saved original

-- UI
local screen = Instance.new("ScreenGui", CoreGui)
screen.Name = "DupeCaptureGUI"
screen.ResetOnSpawn = false

local main = Instance.new("Frame", screen)
main.Size = UDim2.new(0,520,0,420)
main.Position = UDim2.new(0.25,0,0.18,0)
main.BackgroundColor3 = Color3.fromRGB(28,28,28)
main.BorderSizePixel = 0
main.Active = true

-- draggable
local UserInput = game:GetService("UserInputService")
local dragging, dragStart, startPos = false, nil, nil
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

local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,36)
header.BackgroundColor3 = Color3.fromRGB(40,40,40)
local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1,-140,1,0); title.Position = UDim2.new(0,8,0,0)
title.BackgroundTransparency = 1; title.Text = "Capture Session — Event Replayer"; title.TextColor3 = Color3.fromRGB(230,230,230); title.Font = Enum.Font.SourceSansBold; title.TextSize = 15

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0,120,0,28); closeBtn.Position = UDim2.new(1,-132,0,4)
closeBtn.Text = "Close"; closeBtn.Font = Enum.Font.SourceSansBold; closeBtn.BackgroundColor3 = Color3.fromRGB(160,40,40)
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.MouseButton1Click:Connect(function() screen:Destroy() end)

-- Left: controls
local left = Instance.new("Frame", main)
left.Size = UDim2.new(0.36, -8, 1, -46)
left.Position = UDim2.new(0,6,0,42)
left.BackgroundTransparency = 1

local btnStart = Instance.new("TextButton", left)
btnStart.Size = UDim2.new(1,0,0,36); btnStart.Position = UDim2.new(0,0,0,0)
btnStart.Text = "Start Capture Session"; btnStart.Font = Enum.Font.SourceSansBold; btnStart.TextSize = 14
btnStart.BackgroundColor3 = Color3.fromRGB(0,150,100); btnStart.TextColor3 = Color3.fromRGB(255,255,255)

local btnStop = Instance.new("TextButton", left)
btnStop.Size = UDim2.new(1,0,0,30); btnStop.Position = UDim2.new(0,0,0,44)
btnStop.Text = "Stop Capture"; btnStop.BackgroundColor3 = Color3.fromRGB(170,80,0); btnStop.TextColor3 = Color3.fromRGB(255,255,255)

local info = Instance.new("TextLabel", left)
info.Size = UDim2.new(1,0,0,84); info.Position = UDim2.new(0,0,0,84)
info.BackgroundTransparency = 1
info.Text = "Workflow:\n1) Start Capture\n2) Do the in-game action once (hold item / press place / sell)\n3) Stop Capture\n4) Select events on the right\n5) Replay Selected (set repeats & delay)\n\nCaptured: 0"
info.TextColor3 = Color3.fromRGB(220,220,220)
info.TextWrapped = true
info.Font = Enum.Font.SourceSans; info.TextSize = 12

local cloneFallbackCheckbox = Instance.new("TextButton", left)
cloneFallbackCheckbox.Size = UDim2.new(1,0,0,28); cloneFallbackCheckbox.Position = UDim2.new(0,0,0,174)
cloneFallbackCheckbox.Text = "Fallback: Try Direct Clone to Backpack: OFF"; cloneFallbackCheckbox.BackgroundColor3 = Color3.fromRGB(100,100,100)
cloneFallbackCheckbox.TextColor3 = Color3.fromRGB(255,255,255)
local fallbackEnabled = false
cloneFallbackCheckbox.MouseButton1Click:Connect(function()
    fallbackEnabled = not fallbackEnabled
    cloneFallbackCheckbox.Text = "Fallback: Try Direct Clone to Backpack: " .. (fallbackEnabled and "ON" or "OFF")
    cloneFallbackCheckbox.BackgroundColor3 = fallbackEnabled and Color3.fromRGB(0,150,100) or Color3.fromRGB(100,100,100)
end)

-- Right: captured list + replay controls
local right = Instance.new("Frame", main)
right.Size = UDim2.new(0.62, -14, 1, -46)
right.Position = UDim2.new(0.38, 8, 0, 42)
right.BackgroundTransparency = 1

local capLabel = Instance.new("TextLabel", right)
capLabel.Size = UDim2.new(1,0,0,20); capLabel.Position = UDim2.new(0,0,0,0)
capLabel.BackgroundTransparency = 1; capLabel.Text = "Captured Events (0)"; capLabel.TextColor3 = Color3.fromRGB(230,230,230); capLabel.Font = Enum.Font.SourceSansBold

local scroll = Instance.new("ScrollingFrame", right)
scroll.Size = UDim2.new(1,0,1,-120); scroll.Position = UDim2.new(0,0,0,26); scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 8
local listLayout = Instance.new("UIListLayout", scroll); listLayout.Padding = UDim.new(0,6)

local replayPanel = Instance.new("Frame", right)
replayPanel.Size = UDim2.new(1,0,0,96); replayPanel.Position = UDim2.new(0,0,1,-96)
replayPanel.BackgroundTransparency = 1

local repeatsBox = Instance.new("TextBox", replayPanel)
repeatsBox.Size = UDim2.new(0.32,0,0,28); repeatsBox.Position = UDim2.new(0,6,0,6)
repeatsBox.PlaceholderText = "Repeats (e.g. 5)"; repeatsBox.Text = "3"

local delayBox = Instance.new("TextBox", replayPanel)
delayBox.Size = UDim2.new(0.32,0,0,28); delayBox.Position = UDim2.new(0.34,6,0,6)
delayBox.PlaceholderText = "Delay sec (0.05)"; delayBox.Text = "0.05"

local replayBtn = Instance.new("TextButton", replayPanel)
replayBtn.Size = UDim2.new(0.32,0,0,28); replayBtn.Position = UDim2.new(0.68,6,0,6)
replayBtn.Text = "Replay Selected"; replayBtn.BackgroundColor3 = Color3.fromRGB(0,130,200); replayBtn.TextColor3 = Color3.fromRGB(255,255,255)

local clearBtn = Instance.new("TextButton", replayPanel)
clearBtn.Size = UDim2.new(1,-12,0,28); clearBtn.Position = UDim2.new(0,6,0,42)
clearBtn.Text = "Clear Captured"; clearBtn.BackgroundColor3 = Color3.fromRGB(150,50,50); clearBtn.TextColor3 = Color3.fromRGB(255,255,255)

-- helper: refresh captured UI list
local function refreshList()
    for _,c in ipairs(scroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for i,entry in ipairs(captured) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-8,0,36)
        btn.Position = UDim2.new(0,4,0, (i-1)*40)
        btn.BackgroundColor3 = selectedIndexes[i] and Color3.fromRGB(45,120,45) or Color3.fromRGB(60,60,60)
        btn.TextColor3 = Color3.fromRGB(230,230,230)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 13
        btn.AutoButtonColor = false
        btn.TextWrapped = true
        local argPreview = ""
        for ai,a in ipairs(entry.args) do
            local s = typeof(a) == "Instance" and ("Instance:"..(a.Name or "nil")) or tostring(a)
            argPreview = argPreview .. (ai>1 and ", " or "") .. s
            if #argPreview > 80 then argPreview = argPreview .. "..." break end
        end
        btn.Text = string.format("[%d] %s | Args: %s", i, entry.path, argPreview)
        btn.Parent = scroll
        btn.LayoutOrder = i
        btn.MouseButton1Click:Connect(function()
            if selectedIndexes[i] then selectedIndexes[i] = nil else selectedIndexes[i] = true end
            refreshList()
        end)
    end
    capLabel.Text = "Captured Events ("..#captured..")"
    info.Text = info.Text:gsub("Captured: %d+", "Captured: "..#captured)
end

-- safe copy args (try to preserve Instances)
local function copyArgs(tbl)
    local out = {}
    for i,v in ipairs(tbl) do out[i] = v end
    return out
end

-- Hooking mechanism (metatable) capturing FireServer & InvokeServer
local function enableHook()
    if oldNamecall then return true end
    local ok, mt = pcall(getrawmetatable, game)
    if not ok or not mt then return false, "getrawmetatable failed" end
    oldNamecall = mt.__namecall
    local new = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        -- capture only when capturing session active
        if capturing and (method == "FireServer" or method == "InvokeServer") then
            local s, fullname = pcall(function() return self:GetFullName() end)
            if s and fullname then
                table.insert(captured, {path = fullname, args = copyArgs(args), method = method})
                refreshList()
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, false)
    mt.__namecall = new
    setreadonly(mt, true)
    return true
end

-- disable hook (restore)
local function disableHook()
    if not oldNamecall then return end
    local ok, mt = pcall(getrawmetatable, game)
    if ok and mt then
        setreadonly(mt, false)
        mt.__namecall = oldNamecall
        setreadonly(mt, true)
    end
    oldNamecall = nil
end

-- start / stop capture buttons
btnStart.MouseButton1Click:Connect(function()
    if capturing then return end
    local ok, err = pcall(enableHook)
    if not ok then
        warn("Hook failed:", err)
        return
    end
    captured = {}
    selectedIndexes = {}
    capturing = true
    btnStart.BackgroundColor3 = Color3.fromRGB(0,200,120)
    btnStart.Text = "Capture: ON"
    info.Text = info.Text:gsub("Captured: %d+", "Captured: 0")
    print("[CAPTURE] Session started. Perform the in-game action now.")
end)

btnStop.MouseButton1Click:Connect(function()
    if not capturing then return end
    capturing = false
    btnStart.BackgroundColor3 = Color3.fromRGB(0,150,100)
    btnStart.Text = "Start Capture Session"
    print("[CAPTURE] Session stopped. "..#captured.." events captured.")
end)

clearBtn.MouseButton1Click:Connect(function()
    captured = {}
    selectedIndexes = {}
    refreshList()
end)

-- replay selected sequence
replayBtn.MouseButton1Click:Connect(function()
    -- gather selected in order
    local seq = {}
    for i,entry in ipairs(captured) do
        if selectedIndexes[i] then table.insert(seq, entry) end
    end
    if #seq == 0 then
        warn("No events selected for replay.")
        return
    end
    local repeats = tonumber(repeatsBox.Text) or 1
    local delaySec = tonumber(delayBox.Text) or 0.05
    print(string.format("[REPLAY] Running %d events x %d repeats (delay %.3f)", #seq, repeats, delaySec))

    -- Attempt replay; if error, and fallbackEnabled true, try clone fallback for Instance args
    for r = 1, repeats do
        for _,entry in ipairs(seq) do
            local success, err = pcall(function()
                -- resolve object by path string (like "ReplicatedStorage.SomeEvent")
                local root = game
                local parts = {}
                for part in string.gmatch(entry.path, "([^%.]+)") do table.insert(parts, part) end
                local obj = root
                for _,p in ipairs(parts) do
                    if obj then obj = obj:FindFirstChild(p) end
                end
                if obj and typeof(obj.FireServer) == "function" then
                    obj:FireServer(unpack(entry.args))
                elseif obj and typeof(obj.InvokeServer) == "function" then
                    obj:InvokeServer(unpack(entry.args))
                else
                    error("Target not found or not a Remote.")
                end
            end)
            if not success then
                warn("[REPLAY] entry failed:", err)
                if fallbackEnabled then
                    -- try clone fallback: look for an Instance arg referencing Workspace and clone it to Backpack
                    for _,a in ipairs(entry.args) do
                        if typeof(a) == "Instance" and a:IsDescendantOf(game.Workspace) then
                            local ok2, err2 = pcall(function()
                                local clone = a:Clone()
                                clone.Parent = LocalPlayer:FindFirstChild("Backpack") or LocalPlayer:FindFirstChild("StarterGear") or LocalPlayer
                            end)
                            if ok2 then
                                print("[FALLBACK] Cloned", a:GetFullName(), "to Backpack")
                            else
                                warn("[FALLBACK] Clone failed:", err2)
                            end
                        end
                    end
                end
            end
            task.wait(delaySec)
        end
    end
    print("[REPLAY] Done.")
end)

-- final note
print("[READY] Capture GUI ready. Start session, perform action in-game, stop session, then select and replay.")
