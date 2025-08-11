--// Full Dupe Sniffer & Multi-Event Replayer
--// by GPT
--// Note: Work only if game has client-side trust or exploitable validation

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "FullDupeGUI"
gui.Parent = CoreGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0.35, 0, 0.35, 0)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
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
dupeBtn.Text = "Duplicate All"
dupeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
dupeBtn.TextColor3 = Color3.new(1, 1, 1)

local logBox = Instance.new("TextBox", frame)
logBox.Size = UDim2.new(1, -10, 0, 70)
logBox.Position = UDim2.new(0, 5, 0, 80)
logBox.MultiLine = true
logBox.TextWrapped = true
logBox.ClearTextOnFocus = false
logBox.TextYAlignment = Enum.TextYAlignment.Top
logBox.TextXAlignment = Enum.TextXAlignment.Left
logBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
logBox.TextColor3 = Color3.new(1, 1, 1)
logBox.Text = "Event Log:\n"

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(1, -10, 0, 25)
closeBtn.Position = UDim2.new(0, 5, 1, -30)
closeBtn.Text = "Close"
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeBtn.TextColor3 = Color3.new(1, 1, 1)

-- Vars
local heldItemName = nil
local eventList = {}

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

-- Hook FireServer to log all related events
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall

mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if method == "FireServer" and heldItemName then
        -- Cek kalau event ini ada hubungannya sama item
        local related = false
        for _, arg in ipairs(args) do
            if tostring(arg):find(heldItemName) then
                related = true
                break
            end
        end
        if related then
            table.insert(eventList, {event = self, args = args})
            logBox.Text = logBox.Text .. string.format("[Captured] %s | Args: %s\n", self.Name, table.concat(args, ", "))
            print("[SNIFF] Captured:", self.Name, args)
        end
    end
    return oldNamecall(self, ...)
end

-- Duplicate all captured events
dupeBtn.MouseButton1Click:Connect(function()
    if #eventList > 0 then
        print("[DUPE] Replaying", #eventList, "events...")
        for i = 1, 5 do -- ulang 5x untuk spam
            for _, data in ipairs(eventList) do
                data.event:FireServer(unpack(data.args))
                task.wait(0.05)
            end
        end
    else
        print("[DUPE] No events captured yet.")
    end
end)

-- Close GUI
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)
