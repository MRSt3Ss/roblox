--[[ 
    Auto TP Checkpoint System with Admin/User Login
    By GPT-5
    Features:
    - Admin: Record CP, Save Template, Auto TP
    - User: Load Template, Auto TP
    - Persistent storage with writefile/readfile (if supported)
]]--

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- SETTINGS
local DATA_FILE = "checkpoint_templates.json"

-- Helpers for save/load
local HttpService = game:GetService("HttpService")
local function saveData(data)
    if writefile then
        writefile(DATA_FILE, HttpService:JSONEncode(data))
    end
end

local function loadData()
    if readfile and isfile and isfile(DATA_FILE) then
        return HttpService:JSONDecode(readfile(DATA_FILE))
    else
        return {}
    end
end

-- Vars
local templates = loadData()
local currentRecording = {}
local selectedTemplate = nil
local autoTPEnabled = false
local role = nil

-- GUI Builder
local function createButton(parent, text, pos, size, color)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.Text = text
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    return btn
end

local function createLabel(parent, text, pos, size, color)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = parent
    lbl.Text = text
    lbl.Size = size
    lbl.Position = pos
    lbl.BackgroundColor3 = color
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 18
    lbl.TextWrapped = true
    return lbl
end

-- LOGIN GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
local loginFrame = Instance.new("Frame", gui)
loginFrame.Size = UDim2.new(0,300,0,180)
loginFrame.Position = UDim2.new(0.35,0,0.35,0)
loginFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
loginFrame.Active = true
loginFrame.Draggable = true

createLabel(loginFrame, "Login", UDim2.new(0,0,0,0), UDim2.new(1,0,0,30), Color3.fromRGB(25,25,25))

local userBox = Instance.new("TextBox", loginFrame)
userBox.Size = UDim2.new(1,-20,0,30)
userBox.Position = UDim2.new(0,10,0,50)
userBox.PlaceholderText = "Username"
userBox.BackgroundColor3 = Color3.fromRGB(70,70,70)
userBox.TextColor3 = Color3.new(1,1,1)

local passBox = Instance.new("TextBox", loginFrame)
passBox.Size = UDim2.new(1,-20,0,30)
passBox.Position = UDim2.new(0,10,0,90)
passBox.PlaceholderText = "Password"
passBox.BackgroundColor3 = Color3.fromRGB(70,70,70)
passBox.TextColor3 = Color3.new(1,1,1)

local loginBtn = createButton(loginFrame,"Login",UDim2.new(0,10,0,130),UDim2.new(1,-20,0,30),Color3.fromRGB(0,170,0))

-- MAIN GUI (hidden until login)
local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.new(0,400,0,300)
mainFrame.Position = UDim2.new(0.3,0,0.3,0)
mainFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = false

local titleLabel = createLabel(mainFrame, "Checkpoint System", UDim2.new(0,0,0,0), UDim2.new(1,0,0,30), Color3.fromRGB(25,25,25))

local infoLabel = createLabel(mainFrame, "Status: Idle", UDim2.new(0,0,0,40), UDim2.new(1,0,0,30), Color3.fromRGB(35,35,35))

-- Admin Buttons
local addCPBtn = createButton(mainFrame,"Add Checkpoint",UDim2.new(0,10,0,80),UDim2.new(0.45, -15, 0,30),Color3.fromRGB(0,120,200))
local saveTemplateBtn = createButton(mainFrame,"Save Template",UDim2.new(0.5,5,0,80),UDim2.new(0.45,-15,0,30),Color3.fromRGB(200,120,0))

-- Shared Buttons
local selectTemplateBtn = createButton(mainFrame,"Select Template",UDim2.new(0,10,0,120),UDim2.new(0.45,-15,0,30),Color3.fromRGB(120,0,200))
local autoTPBtn = createButton(mainFrame,"Auto TP: OFF",UDim2.new(0.5,5,0,120),UDim2.new(0.45,-15,0,30),Color3.fromRGB(200,0,0))

local closeBtn = createButton(mainFrame,"Close",UDim2.new(0,10,1,-40),UDim2.new(1,-20,0,30),Color3.fromRGB(200,0,0))

-- Logic
loginBtn.MouseButton1Click:Connect(function()
    local user = string.lower(userBox.Text)
    local pass = string.lower(passBox.Text)

    if user == "irsad" and pass == "irsad10" then
        role = "admin"
    elseif user == "member" and pass == "member" then
        role = "user"
    else
        infoLabel.Text = "Status: Wrong login"
        return
    end
    loginFrame.Visible = false
    mainFrame.Visible = true

    -- Hide admin-only buttons for user
    if role == "user" then
        addCPBtn.Visible = false
        saveTemplateBtn.Visible = false
    end
    infoLabel.Text = "Logged in as: "..role
end)

-- Admin: Add CP
addCPBtn.MouseButton1Click:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        table.insert(currentRecording, LocalPlayer.Character.HumanoidRootPart.CFrame)
        infoLabel.Text = "Checkpoint added! Total: "..#currentRecording
    end
end)

-- Admin: Save template
saveTemplateBtn.MouseButton1Click:Connect(function()
    if #currentRecording == 0 then
        infoLabel.Text = "No checkpoints to save!"
        return
    end
    local mapName = "Map_"..math.random(1000,9999)
    templates[mapName] = {}
    for _,cf in ipairs(currentRecording) do
        table.insert(templates[mapName], {x=cf.X,y=cf.Y,z=cf.Z})
    end
    saveData(templates)
    infoLabel.Text = "Template saved: "..mapName
    currentRecording = {}
end)

-- Select Template
selectTemplateBtn.MouseButton1Click:Connect(function()
    local names = {}
    for name,_ in pairs(templates) do
        table.insert(names,name)
    end
    if #names == 0 then
        infoLabel.Text = "No templates found!"
        return
    end
    selectedTemplate = names[1] -- default pick first
    infoLabel.Text = "Selected template: "..selectedTemplate
end)

-- Auto TP toggle
autoTPBtn.MouseButton1Click:Connect(function()
    autoTPEnabled = not autoTPEnabled
    autoTPBtn.Text = "Auto TP: "..(autoTPEnabled and "ON" or "OFF")
    autoTPBtn.BackgroundColor3 = autoTPEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)

    if autoTPEnabled and selectedTemplate then
        spawn(function()
            while autoTPEnabled do
                for _,pos in ipairs(templates[selectedTemplate]) do
                    if not autoTPEnabled then break end
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character:PivotTo(CFrame.new(pos.x,pos.y,pos.z))
                    end
                    task.wait(2)
                end
            end
        end)
    end
end)

-- Close
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)
