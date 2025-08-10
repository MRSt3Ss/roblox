-- Auto Farm Fishing | Custom GUI
-- by [nama lu di GitHub nanti]

-- Service
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Vars
local autoCast = false
local autoReel = false
local autoShake = false

-- Functions
local function pressKey(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

local function doCast()
    if autoCast then
        pressKey("E") -- asumsi tombol cast E
    end
end

local function doReel()
    if autoReel then
        pressKey("E") -- asumsi tombol reel E
    end
end

local function doShake()
    if autoShake then
        -- contoh simulasi arah shake W/A/S/D
        local keys = {"W","A","S","D"}
        for _, k in ipairs(keys) do
            pressKey(k)
            task.wait(0.1)
        end
    end
end

-- Loop Auto Farm
RunService.Heartbeat:Connect(function()
    -- deteksi kondisi tertentu di sini
    -- ini masih template karena tiap game beda remot eventnya
    doCast()
    doReel()
    doShake()
end)

-- ===== GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFishGUI"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 150)
frame.Position = UDim2.new(0.5, -125, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "🎣 Auto Farm Fishing"
title.Parent = frame

-- Toggle buttons
local function createToggle(name, ypos, varRef)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, ypos)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = name .. ": OFF"
    btn.Parent = frame

    btn.MouseButton1Click:Connect(function()
        _G[varRef] = not _G[varRef]
        btn.Text = name .. ": " .. (_G[varRef] and "ON" or "OFF")
        if varRef == "autoCast" then autoCast = _G[varRef] end
        if varRef == "autoReel" then autoReel = _G[varRef] end
        if varRef == "autoShake" then autoShake = _G[varRef] end
    end)
end

createToggle("Auto Cast", 40, "autoCast")
createToggle("Auto Reel", 75, "autoReel")
createToggle("Auto Shake", 110, "autoShake")
