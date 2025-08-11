-- SadsXBons GUI Script by Abang
-- Fitur: Fly toggle, Add checkpoint, Run teleport, Minimize/Close GUI, Settings (Godmode, WalkSpeed, FlySpeed), Save/Load config

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local mouse = localPlayer:GetMouse()

-- ========== Variables ==========
local flyEnabled = false
local flySpeed = 50
local checkpoints = {}
local isRunning = false
local godmodeEnabled = false
local walkSpeed = 16
local configFileName = "SadsXBonsConfig.txt"

-- ========== Helper Functions ==========
local function saveConfig()
    local config = {
        flyEnabled = flyEnabled,
        flySpeed = flySpeed,
        godmodeEnabled = godmodeEnabled,
        walkSpeed = walkSpeed,
        checkpoints = checkpoints
    }
    local json = game:GetService("HttpService"):JSONEncode(config)
    -- save to file (only works in exploit with file write support)
    if writefile then
        writefile(configFileName, json)
    end
end

local function loadConfig()
    if isfile and isfile(configFileName) then
        local json = readfile(configFileName)
        local success, config = pcall(function()
            return game:GetService("HttpService"):JSONDecode(json)
        end)
        if success and type(config) == "table" then
            flyEnabled = config.flyEnabled or false
            flySpeed = config.flySpeed or 50
            godmodeEnabled = config.godmodeEnabled or false
            walkSpeed = config.walkSpeed or 16
            checkpoints = config.checkpoints or {}
            -- Apply settings
            humanoid.WalkSpeed = walkSpeed
            if godmodeEnabled then
                humanoid.Health = math.huge
            end
        end
    end
end

local function createTween(object, properties, duration)
    local TweenService = game:GetService("TweenService")
    local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

-- ========== Fly System ==========
local bodyVelocity
local function startFly()
    if flyEnabled then return end
    flyEnabled = true
    local root = character:WaitForChild("HumanoidRootPart")
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyVelocity.Velocity = Vector3.new(0,0,0)
    bodyVelocity.Parent = root

    RunService:BindToRenderStep("FlyMovement", Enum.RenderPriority.Character.Value, function()
        if not flyEnabled then
            RunService:UnbindFromRenderStep("FlyMovement")
            if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
            return
        end
        local moveDir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + workspace.CurrentCamera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - workspace.CurrentCamera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - workspace.CurrentCamera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + workspace.CurrentCamera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0,1,0) end
        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit * flySpeed
        end
        bodyVelocity.Velocity = moveDir
    end)
end

local function stopFly()
    flyEnabled = false
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    RunService:UnbindFromRenderStep("FlyMovement")
end

-- ========== Teleport Checkpoints ==========
local function teleportToCheckpoint(pos)
    local root = character:WaitForChild("HumanoidRootPart")
    root.CFrame = CFrame.new(pos + Vector3.new(0,3,0))
end

local function runCheckpoints()
    if isRunning or #checkpoints == 0 then return end
    isRunning = true
    for i, pos in ipairs(checkpoints) do
        teleportToCheckpoint(pos)
        wait(1) -- jeda antar tp
    end
    isRunning = false
end

-- ========== GUI Setup ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SadsXBonsGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 420)
mainFrame.Position = UDim2.new(0.7, 0, 0.15, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
mainFrame.BorderSizePixel = 0
mainFrame.AnchorPoint = Vector2.new(0.5, 0)
mainFrame.Parent = ScreenGui
mainFrame.ClipsDescendants = true
mainFrame.BackgroundTransparency = 0.1
mainFrame.Rounding = 12

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = mainFrame

-- Title Bar with Logo and Buttons
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleBar.Parent = mainFrame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

-- Logo Label
local logoLabel = Instance.new("TextLabel")
logoLabel.Size = UDim2.new(0, 140, 1, 0)
logoLabel.BackgroundTransparency = 1
logoLabel.Text = "SadsXBons"
logoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
logoLabel.Font = Enum.Font.GothamBold
logoLabel.TextSize = 22
logoLabel.TextXAlignment = Enum.TextXAlignment.Left
logoLabel.Position = UDim2.new(0, 10, 0, 0)
logoLabel.Parent = titleBar

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 40, 0, 30)
closeButton.Position = UDim2.new(1, -45, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.TextSize = 22
closeButton.Parent = titleBar
closeButton.AutoButtonColor = false

closeButton.MouseEnter:Connect(function()
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
end)
closeButton.MouseLeave:Connect(function()
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
end)

-- Minimize Button
local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 40, 0, 30)
minimizeButton.Position = UDim2.new(1, -90, 0, 5)
minimizeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
minimizeButton.Text = "_"
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextColor3 = Color3.new(1,1,1)
minimizeButton.TextSize = 22
minimizeButton.Parent = titleBar
minimizeButton.AutoButtonColor = false

minimizeButton.MouseEnter:Connect(function()
    minimizeButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
end)
minimizeButton.MouseLeave:Connect(function()
    minimizeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
end)

-- Minimized Bar (small clickable bar when minimized)
local minimizedBar = Instance.new("TextButton")
minimizedBar.Size = UDim2.new(0, 120, 0, 30)
minimizedBar.Position = UDim2.new(0.7, 0, 0.15, 0)
minimizedBar.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
minimizedBar.Text = "SadsXBons (Minimized)"
minimizedBar.Font = Enum.Font.GothamBold
minimizedBar.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizedBar.Visible = false
minimizedBar.Parent = ScreenGui
minimizedBar.AutoButtonColor = false

-- Main UI Elements Container
local container = Instance.new("Frame")
container.Size = UDim2.new(1, -20, 1, -50)
container.Position = UDim2.new(0, 10, 0, 45)
container.BackgroundTransparency = 1
container.Parent = mainFrame

-- Animated Button Creation Helper
local function createToggleButton(text, startState)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    btn.Text = text
    btn.AutoButtonColor = false
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn

    -- Slider part for on/off
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(0, 30, 0, 30)
    slider.Position = UDim2.new(startState and 0.7 or 0.05, 0, 0.1, 0)
    slider.BackgroundColor3 = startState and Color3.fromRGB(0, 230, 64) or Color3.fromRGB(180, 0, 0)
    slider.Parent = btn
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(1, 0)
    sliderCorner.Parent = slider

    return btn, slider
end

-- ========== Fly Toggle ==========
local flyToggleBtn, flySlider = createToggleButton("Fly", flyEnabled)
flyToggleBtn.Parent = container
flyToggleBtn.Position = UDim2.new(0, 10, 0, 0)
flyToggleBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    -- Animate slider
    local goalPos = flyEnabled and UDim2.new(0.7, 0, 0.1, 0) or UDim2.new(0.05, 0, 0.1, 0)
    local goalColor = flyEnabled and Color3.fromRGB(0, 230, 64) or Color3.fromRGB(180, 0, 0)
    local TweenService = game:GetService("TweenService")
    TweenService:Create(flySlider, TweenInfo.new(0.25), {Position = goalPos, BackgroundColor3 = goalColor}):Play()

    if flyEnabled then
        startFly()
    else
        stopFly()
    end
    saveConfig()
end)

-- ========== Add Checkpoint Button ==========
local addCPBtn = Instance.new("TextButton")
addCPBtn.Size = UDim2.new(0, 120, 0, 40)
addCPBtn.Position = UDim2.new(0, 160, 0, 0)
addCPBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
addCPBtn.TextColor3 = Color3.new(1,1,1)
addCPBtn.Font = Enum.Font.GothamBold
addCPBtn.TextSize = 18
addCPBtn.Text = "Add Checkpoint"
addCPBtn.AutoButtonColor = false
local addCPCorner = Instance.new("UICorner")
addCPCorner.CornerRadius = UDim.new(0, 10)
addCPCorner.Parent = addCPBtn
addCPBtn.Parent = container

-- Checkpoint List Frame
local cpListFrame = Instance.new("ScrollingFrame")
cpListFrame.Size = UDim2.new(1, 0, 0, 200)
cpListFrame.Position = UDim2.new(0, 0, 0, 50)
cpListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
cpListFrame.BorderSizePixel = 0
cpListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
cpListFrame.ScrollBarThickness = 6
cpListFrame.Parent = container
local cpListUICorner = Instance.new("UICorner")
cpListUICorner.CornerRadius = UDim.new(0, 10)
cpListUICorner.Parent = cpListFrame

local cpListLayout = Instance.new("UIListLayout")
cpListLayout.SortOrder = Enum.SortOrder.LayoutOrder
cpListLayout.Parent = cpListFrame
cpListLayout.Padding = UDim.new(0, 5)

local function refreshCPList()
    cpListFrame:ClearAllChildren()
    cpListLayout.Parent = cpListFrame
    for i, pos in ipairs(checkpoints) do
        local cpLabel = Instance.new("TextLabel")
        cpLabel.Size = UDim2.new(1, -10, 0, 30)
        cpLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        cpLabel.TextColor3 = Color3.new(1,1,1)
        cpLabel.Font = Enum.Font.GothamBold
        cpLabel.TextSize = 18
        cpLabel.Text = "CP"..i.."  ("..math.floor(pos.X)..","..math.floor(pos.Y)..","..math.floor(pos.Z)..")"
        cpLabel.Parent = cpListFrame
        local labelCorner = Instance.new("UICorner")
        labelCorner.CornerRadius = UDim.new(0, 6)
        labelCorner.Parent = cpLabel
    end
    local canvasSize = cpListLayout.AbsoluteContentSize.Y
    cpListFrame.CanvasSize = UDim2.new(0, 0, 0, canvasSize)
end

addCPBtn.MouseButton1Click:Connect(function()
    local root = character:WaitForChild("HumanoidRootPart")
    table.insert(checkpoints, root.Position)
    refreshCPList()
    saveConfig()
end)

-- ========== Run Button ==========
local runBtn = Instance.new("TextButton")
runBtn.Size = UDim2.new(0, 120, 0, 40)
runBtn.Position = UDim2.new(0, 10, 0, 260)
runBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
runBtn.TextColor3 = Color3.new(1,1,1)
runBtn.Font = Enum.Font.GothamBold
runBtn.TextSize = 18
runBtn.Text = "Run Checkpoints"
runBtn.AutoButtonColor = false
local runBtnCorner = Instance.new("UICorner")
runBtnCorner.CornerRadius = UDim.new(0, 10)
runBtnCorner.Parent = runBtn
runBtn.Parent = container

runBtn.MouseButton1Click:Connect(function()
    if isRunning then return end
    spawn(function()
        runCheckpoints()
    end)
end)

-- ========== Settings Button and Frame ==========
local settingsBtn = Instance.new("TextButton")
settingsBtn.Size = UDim2.new(0, 40, 0, 30)
settingsBtn.Position = UDim2.new(1, -40, 0, 5)
settingsBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
settingsBtn.Text = "⚙"
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.TextColor3 = Color3.new(1,1,1)
settingsBtn.TextSize = 20
settingsBtn.Parent = titleBar
settingsBtn.AutoButtonColor = false
local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(0, 280, 0, 180)
settingsFrame.Position = UDim2.new(0, 20, 0, 230)
settingsFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)
settingsFrame.Visible = false
settingsFrame.Parent = container
local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0, 10)
settingsCorner.Parent = settingsFrame

-- Settings: Godmode Toggle
local godmodeToggleBtn, godmodeSlider = createToggleButton("Godmode", godmodeEnabled)
godmodeToggleBtn.Parent = settingsFrame
godmodeToggleBtn.Position = UDim2.new(0, 20, 0, 20)
godmodeToggleBtn.MouseButton1Click:Connect(function()
    godmodeEnabled = not godmodeEnabled
    local goalPos = godmodeEnabled and UDim2.new(0.7, 0, 0.1, 0) or UDim2.new(0.05, 0, 0.1, 0)
    local goalColor = godmodeEnabled and Color3.fromRGB(0, 230, 64) or Color3.fromRGB(180, 0, 0)
    local TweenService = game:GetService("TweenService")
    TweenService:Create(godmodeSlider, TweenInfo.new(0.25), {Position = goalPos, BackgroundColor3 = goalColor}):Play()

    if godmodeEnabled then
        humanoid.Health = math.huge
        humanoid.MaxHealth = math.huge
    else
        humanoid.MaxHealth = 100
        humanoid.Health = 100
    end
    saveConfig()
end)

-- Settings: WalkSpeed Slider
local walkSpeedLabel = Instance.new("TextLabel")
walkSpeedLabel.Size = UDim2.new(0, 100, 0, 25)
walkSpeedLabel.Position = UDim2.new(0, 20, 0, 80)
walkSpeedLabel.BackgroundTransparency = 1
walkSpeedLabel.TextColor3 = Color3.new(1,1,1)
walkSpeedLabel.Font = Enum.Font.GothamBold
walkSpeedLabel.TextSize = 16
walkSpeedLabel.Text = "Walk Speed: "..walkSpeed
walkSpeedLabel.Parent = settingsFrame

local walkSpeedSlider = Instance.new("Frame")
walkSpeedSlider.Size = UDim2.new(0, 150, 0, 20)
walkSpeedSlider.Position = UDim2.new(0, 120, 0, 85)
walkSpeedSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
walkSpeedSlider.Parent = settingsFrame
local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(0, 10)
sliderCorner.Parent = walkSpeedSlider

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new((walkSpeed-16)/84, 0, 1, 0) -- max walk speed 100
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 64)
sliderFill.Parent = walkSpeedSlider
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 10)
fillCorner.Parent = sliderFill

walkSpeedSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local function onMove(move)
            local pos = move.Position.X - walkSpeedSlider.AbsolutePosition.X
            pos = math.clamp(pos, 0, walkSpeedSlider.AbsoluteSize.X)
            local ratio = pos / walkSpeedSlider.AbsoluteSize.X
            walkSpeed = math.floor(16 + ratio * 84) -- min 16 max 100
            sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
            walkSpeedLabel.Text = "Walk Speed: "..walkSpeed
            humanoid.WalkSpeed = walkSpeed
            saveConfig()
        end
        local function onUp()
            UserInputService.InputChanged:Disconnect()
            UserInputService.InputEnded:Disconnect()
        end
        local conn1
        local conn2
        conn1 = UserInputService.InputChanged:Connect(function(input2)
            if input2.UserInputType == Enum.UserInputType.MouseMovement then
                onMove(input2)
            end
        end)
        conn2 = UserInputService.InputEnded:Connect(function(input2)
            if input2.UserInputType == Enum.UserInputType.MouseButton1 then
                conn1:Disconnect()
                conn2:Disconnect()
            end
        end)
        onMove(input)
    end
end)

-- Settings: Fly Speed Slider (Mirip walk speed)
local flySpeedLabel = Instance.new("TextLabel")
flySpeedLabel.Size = UDim2.new(0, 100, 0, 25)
flySpeedLabel.Position = UDim2.new(0, 20, 0, 120)
flySpeedLabel.BackgroundTransparency = 1
flySpeedLabel.TextColor3 = Color3.new(1,1,1)
flySpeedLabel.Font = Enum.Font.GothamBold
flySpeedLabel.TextSize = 16
flySpeedLabel.Text = "Fly Speed: "..flySpeed
flySpeedLabel.Parent = settingsFrame

local flySpeedSlider = Instance.new("Frame")
flySpeedSlider.Size = UDim2.new(0, 150, 0, 20)
flySpeedSlider.Position = UDim2.new(0, 120, 0, 125)
flySpeedSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
flySpeedSlider.Parent = settingsFrame
local flySliderCorner = Instance.new("UICorner")
flySliderCorner.CornerRadius = UDim.new(0, 10)
flySliderCorner.Parent = flySpeedSlider

local flySliderFill = Instance.new("Frame")
flySliderFill.Size = UDim2.new(flySpeed/200, 0, 1, 0) -- max fly speed 200
flySliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 64)
flySliderFill.Parent = flySpeedSlider
local flyFillCorner = Instance.new("UICorner")
flyFillCorner.CornerRadius = UDim.new(0, 10)
flyFillCorner.Parent = flySliderFill

flySpeedSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local function onMove(move)
            local pos = move.Position.X - flySpeedSlider.AbsolutePosition.X
            pos = math.clamp(pos, 0, flySpeedSlider.AbsoluteSize.X)
            local ratio = pos / flySpeedSlider.AbsoluteSize.X
            flySpeed = math.floor(ratio * 200)
            flySpeed = math.max(10, flySpeed)
            flySliderFill.Size = UDim2.new(ratio, 0, 1, 0)
            flySpeedLabel.Text = "Fly Speed: "..flySpeed
            if flyEnabled then
                -- restart fly to update speed
                stopFly()
                startFly()
            end
            saveConfig()
        end
        local function onUp()
            UserInputService.InputChanged:Disconnect()
            UserInputService.InputEnded:Disconnect()
        end
        local conn1
        local conn2
        conn1 = UserInputService.InputChanged:Connect(function(input2)
            if input2.UserInputType == Enum.UserInputType.MouseMovement then
                onMove(input2)
            end
        end)
        conn2 = UserInputService.InputEnded:Connect(function(input2)
            if input2.UserInputType == Enum.UserInputType.MouseButton1 then
                conn1:Disconnect()
                conn2:Disconnect()
            end
        end)
        onMove(input)
    end
end)

-- Settings toggle logic
settingsBtn.MouseButton1Click:Connect(function()
    settingsFrame.Visible = not settingsFrame.Visible
end)

-- ========== Minimize / Close Logic ==========
closeButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

minimizeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    minimizedBar.Visible = true
end)

minimizedBar.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    minimizedBar.Visible = false
end)

-- ========== Init Load Config ==========
loadConfig()
refreshCPList()
if flyEnabled then
    startFly()
end
if godmodeEnabled then
    humanoid.Health = math.huge
    humanoid.MaxHealth = math.huge
end
humanoid.WalkSpeed = walkSpeed
