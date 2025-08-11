-- Auto TP Checkpoint + Admin Detector GUI
-- by GPT

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

-- GUI
local gui = Instance.new("ScreenGui")
gui.Parent = CoreGui
gui.Name = "MountainTPGUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0.35, 0, 0.35, 0)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
title.Text = "Auto TP Checkpoint + Admin Alert"
title.TextColor3 = Color3.new(1, 1, 1)

local dropdown = Instance.new("TextButton", frame)
dropdown.Size = UDim2.new(1, -10, 0, 30)
dropdown.Position = UDim2.new(0, 5, 0, 40)
dropdown.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
dropdown.TextColor3 = Color3.new(1, 1, 1)
dropdown.Text = "Select Checkpoint"

local tpBtn = Instance.new("TextButton", frame)
tpBtn.Size = UDim2.new(1, -10, 0, 30)
tpBtn.Position = UDim2.new(0, 5, 0, 80)
tpBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
tpBtn.TextColor3 = Color3.new(1, 1, 1)
tpBtn.Text = "Teleport"

local adminLabel = Instance.new("TextLabel", frame)
adminLabel.Size = UDim2.new(1, -10, 0, 30)
adminLabel.Position = UDim2.new(0, 5, 0, 120)
adminLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
adminLabel.TextColor3 = Color3.new(1, 0, 0)
adminLabel.Text = "Admin: None"

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(1, -10, 0, 25)
closeBtn.Position = UDim2.new(0, 5, 1, -30)
closeBtn.Text = "Close"
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeBtn.TextColor3 = Color3.new(1, 1, 1)

-- Vars
local checkpoints = {}
local selectedCheckpoint = nil

-- Scan checkpoints
local function scanCheckpoints()
    checkpoints = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("SpawnLocation") then
            if obj.Name:lower():find("checkpoint") then
                table.insert(checkpoints, obj)
            end
        end
    end
    print("[SCAN] Found", #checkpoints, "checkpoints.")
end

-- Dropdown logic (simple)
dropdown.MouseButton1Click:Connect(function()
    if #checkpoints == 0 then
        dropdown.Text = "No checkpoints found"
        return
    end
    local names = {}
    for i, cp in ipairs(checkpoints) do
        table.insert(names, i .. ". " .. cp.Name)
    end
    dropdown.Text = "Choose (Check console)"
    print("=== Checkpoints ===")
    for i, cp in ipairs(checkpoints) do
        print(i .. ". " .. cp.Name)
    end
    print("Type number in console: selectCheckpoint(<number>)")
end)

-- Function to set checkpoint
function selectCheckpoint(num)
    if checkpoints[num] then
        selectedCheckpoint = checkpoints[num]
        dropdown.Text = "Selected: " .. selectedCheckpoint.Name
        print("[SELECTED]", selectedCheckpoint.Name)
    else
        print("[ERROR] Invalid checkpoint number.")
    end
end

-- TP button
tpBtn.MouseButton1Click:Connect(function()
    if selectedCheckpoint then
        LocalPlayer.Character:PivotTo(selectedCheckpoint.CFrame + Vector3.new(0, 3, 0))
        print("[TP] Teleported to", selectedCheckpoint.Name)
    else
        print("[TP] No checkpoint selected.")
    end
end)

-- Admin Detector
local function checkAdmins()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if plr:GetRankInGroup(123456) >= 200 or plr.Name:lower():find("admin") then
                adminLabel.Text = "Admin: " .. plr.Name
                warn("[ADMIN ALERT]", plr.Name, "is in game!")
            end
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    task.wait(1)
    checkAdmins()
end)
Players.PlayerRemoving:Connect(function()
    task.wait(1)
    checkAdmins()
end)

-- Close GUI
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Init
scanCheckpoints()
checkAdmins()
