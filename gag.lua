--// Sniffer & Replay RemoteEvent + Dragable GUI //--

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- GUI
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "EventSnifferGUI"

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 400, 0, 300)
Frame.Position = UDim2.new(0.3, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Active = true
Frame.Draggable = true -- bisa di drag
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Text = "RemoteEvent Sniffer & Replay"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = Frame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Parent = Frame
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -10, 1, -40)
Scroll.Position = UDim2.new(0, 5, 0, 35)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 6
Scroll.Parent = Frame

-- Data penyimpanan
local capturedEvents = {}

-- Fungsi bikin tombol replay
local function addEventButton(eventPath, args)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 25)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = eventPath
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Parent = Scroll

    btn.MouseButton1Click:Connect(function()
        local success, err = pcall(function()
            local ev = game
            for _, part in ipairs(string.split(eventPath, ".")) do
                ev = ev[part]
            end
            ev:FireServer(unpack(args))
        end)
        if success then
            print("[REPLAY] Event fired:", eventPath, args)
        else
            warn("[ERROR] Replay failed:", err)
        end
    end)
end

-- Hook Namecall buat sniff semua FireServer
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if method == "FireServer" then
        local success, path = pcall(function()
            return self:GetFullName()
        end)

        if success and not capturedEvents[path] then
            capturedEvents[path] = args
            print("[SNIFF] RemoteEvent:", path, args)
            addEventButton(path, args)
        end
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

print("[READY] Sniffer aktif. Lakukan aksi spawn / dupe di game untuk merekam eventnya.")
