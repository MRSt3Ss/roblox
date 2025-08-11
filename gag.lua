--// Dupe Sniffer for Held Item
--// By GPT
-- WARNING: Work only if game logic allows client duplication

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

-- GUI
local gui = Instance.new("ScreenGui")
gui.Parent = CoreGui
gui.Name = "DupeGUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 250, 0, 150)
frame.Position = UDim2.new(0.3, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.Active = true
frame.Draggable = true

local heldLabel = Instance.new("TextLabel", frame)
heldLabel.Size = UDim2.new(1, -10, 0, 30)
heldLabel.Position = UDim2.new(0, 5, 0, 5)
heldLabel.TextColor3 = Color3.new(1, 1, 1)
heldLabel.BackgroundTransparency = 1
heldLabel.Text = "Held Item: None"

local scanBtn = Instance.new("TextButton", frame)
scanBtn.Size = UDim2.new(0.45, 0, 0, 30)
scanBtn.Position = UDim2.new(0.025, 0, 0, 40)
scanBtn.Text = "Scan Held Item"
scanBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
scanBtn.TextColor3 = Color3.new(1, 1, 1)

local dupeBtn = Instance.new("TextButton", frame)
dupeBtn.Size = UDim2.new(0.45, 0, 0, 30)
dupeBtn.Position = UDim2.new(0.525, 0, 0, 40)
dupeBtn.Text = "Duplicate"
dupeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
dupeBtn.TextColor3 = Color3.new(1, 1, 1)

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(1, -10, 0, 25)
closeBtn.Position = UDim2.new(0, 5, 1, -30)
closeBtn.Text = "Close"
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeBtn.TextColor3 = Color3.new(1, 1, 1)

-- Vars
local heldItemName = nil
local dupeEvent = nil
local dupeArgs = nil

-- Scan Held Item
scanBtn.MouseButton1Click:Connect(function()
    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        heldItemName = tool.Name
        heldLabel.Text = "Held Item: " .. heldItemName
        print("[SCAN] Holding:", heldItemName)
    else
        heldItemName = nil
        heldLabel.Text = "Held Item: None"
        print("[SCAN] No tool held")
    end
end)

-- Hook FireServer
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall

mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if method == "FireServer" and heldItemName then
        for _, arg in ipairs(args) do
            if tostring(arg) == heldItemName then
                dupeEvent = self
                dupeArgs = args
                print("[SNIFF] Captured event for", heldItemName, ":", self.Name)
            end
        end
    end
    return oldNamecall(self, ...)
end

-- Dupe Function
dupeBtn.MouseButton1Click:Connect(function()
    if dupeEvent and dupeArgs then
        print("[DUPE] Trying to duplicate:", heldItemName)
        for i = 1, 5 do
            dupeEvent:FireServer(unpack(dupeArgs))
            wait(0.1)
        end
    else
        print("[DUPE] No captured event for held item.")
    end
end)

-- Close Button
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)
