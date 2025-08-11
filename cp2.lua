-- SadsXBons GUI fixed version

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Config
local flyEnabled = false
local flySpeed = 50
local checkpoints = {}
local isRunning = false
local godmodeEnabled = false
local walkSpeed = 16
local configFileName = "SadsXBonsConfig.txt"

-- Save/Load config
local function saveConfig()
    if writefile then
        local config = {
            flyEnabled = flyEnabled,
            flySpeed = flySpeed,
            godmodeEnabled = godmodeEnabled,
            walkSpeed = walkSpeed,
            checkpoints = checkpoints,
        }
        writefile(configFileName, HttpService:JSONEncode(config))
    end
end

local function loadConfig()
    if isfile and isfile(configFileName) then
        local success, config = pcall(function()
            return HttpService:JSONDecode(readfile(configFileName))
        end)
        if success and typeof(config) == "table" then
            flyEnabled = config.flyEnabled or false
            flySpeed = config.flySpeed or 50
            godmodeEnabled = config.godmodeEnabled or false
            walkSpeed = config.walkSpeed or 16
            checkpoints = config.checkpoints or {}
            humanoid.WalkSpeed = walkSpeed
        end
    end
end

-- Godmode loop
local godmodeLoop
local function startGodmode()
    if godmodeLoop then return end
    godmodeLoop = RunService.Heartbeat:Connect(function()
        if godmodeEnabled then
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
        end
    end)
end

local function stopGodmode()
    if godmodeLoop then
        godmodeLoop:Disconnect()
        godmodeLoop = nil
        humanoid.MaxHealth = 100
        humanoid.Health = 100
    end
end

-- Fly Logic
local bodyVelocity
local flyLoop

local function startFly()
    if flyEnabled then return end
    flyEnabled = true
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
    bodyVelocity.Velocity = Vector3.new(0,0,0)
    bodyVelocity.Parent = rootPart

    flyLoop = RunService.Heartbeat:Connect(function()
        if not flyEnabled then
            flyLoop:Disconnect()
            flyLoop = nil
            if bodyVelocity then
                bodyVelocity:Destroy()
                bodyVelocity = nil
            end
            return
        end

        local cam = workspace.CurrentCamera
        local moveVector = Vector3.new(0,0,0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVector -= Vector3.new(0,1,0) end

        if moveVector.Magnitude > 0 then
            moveVector = moveVector.Unit * flySpeed
        end

        bodyVelocity.Velocity = moveVector
    end)
end

local function stopFly()
    flyEnabled = false
    if flyLoop then
        flyLoop:Disconnect()
        flyLoop = nil
    end
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
end

-- Teleport to checkpoint
local function teleportToCheckpoint(pos)
    rootPart.CFrame = CFrame.new(pos + Vector3.new(0,3,0))
end

local function runCheckpoints()
    if isRunning or #checkpoints == 0 then return end
    isRunning = true
    for _, pos in ipairs(checkpoints) do
        teleportToCheckpoint(pos)
        wait(1) -- kasih delay biar teleport terlihat
    end
    isRunning = false
end

-- Tween helper
local function createTween(object, properties, duration)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Toggle button helper
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

    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(0, 30, 0, 30)
    slider.Position = startState and UDim2.new(0.7, 0, 0.1, 0) or UDim2.new(0.05, 0, 0.1, 0)
    slider.BackgroundColor3 = startState and Color3.fromRGB(0, 230, 64) or Color3.fromRGB(180, 0, 0)
    slider.Parent = btn
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(1, 0)
    sliderCorner.Parent = slider

    return btn, slider
end

-- Drag function for frame
local function makeDraggable(frame)
    local dragging = false
    local dragInput, mousePos, framePos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            local newPos = UDim2.new(
                math.clamp(framePos.X.Scale + delta.X / workspace.CurrentCamera.ViewportSize.X, 0, 1),
                framePos.X.Offset + delta.X,
                math.clamp(framePos.Y.Scale + delta.Y / workspace.CurrentCamera.ViewportSize.Y, 0, 1),
                framePos.Y.Offset + delta.Y
            )
            frame.Position = newPos
        end
    end)
end

-- ========== GUI Setup ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SadsXBonsGUI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 460)
mainFrame.Position = UDim2.new(0.7, 0, 0.15, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
mainFrame.BorderSizePixel = 0
mainFrame.AnchorPoint = Vector2.new(0.5, 0)
mainFrame.Parent = ScreenGui

makeDraggable(mainFrame)

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Title Bar
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

closeButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
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

-- Minimized Bar
local minimizedBar = Instance.new("TextButton")
minimizedBar.Size = UDim2.new(0, 140, 0, 30)
minimizedBar.Position = UDim2.new(0.7, 0, 0.15, 0)
minimizedBar.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
minimizedBar.Text = "SadsXBons (Minimized)"
minimizedBar.Font = Enum.Font.GothamBold
minimizedBar.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizedBar.Visible = false
minimizedBar.Parent = ScreenGui
minimizedBar.AutoButtonColor = false

minimizedBar.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    minimizedBar.Visible = false
end)

-- Container Frame
local container = Instance.new("Frame")
container.Size = UDim2.new(1, -20, 1, -60)
container.Position = UDim2.new(0, 10, 0, 45)
container.BackgroundTransparency = 1
container.Parent = mainFrame

-- Fly Toggle Button
local flyToggleBtn, flySlider = createToggleButton("Fly", flyEnabled)
flyToggleBtn.Parent = container
flyToggleBtn.Position = UDim2.new(0, 10, 0, 0)
flyToggleBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    local goalPos = flyEnabled and UDim2.new(0.7, 0, 0.1, 0) or UDim2.new(0.05, 0, 0.1, 0)
    local goalColor = flyEnabled and Color3.fromRGB(0, 230, 64) or Color3.fromRGB(180, 0, 0)
    TweenService:Create(flySlider, TweenInfo.new(0.25), {Position = goalPos, BackgroundColor3 = goalColor}):Play()
    if flyEnabled then
        startFly()
    else
        stopFly()
    end
    saveConfig()
end)

-- Add Checkpoint Button
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
    for _, v in ipairs(cpListFrame:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
    for i, pos in ipairs(checkpoints) do
        local cpLabel = Instance.new("TextLabel")
        cpLabel.Size = UDim2.new(1, -10, 0, 30)
        cpLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        cpLabel.TextColor3 = Color3.new(1,1,1)
        cpLabel.Font = Enum.Font.GothamBold
        cpLabel.TextSize = 18
        cpLabel.Text = "CP"..i.." ("..math.floor(pos.X)..","..math.floor(pos.Y)..","..math.floor(pos.Z)..")"
        cpLabel.Parent = cpListFrame
        local labelCorner = Instance.new("UICorner")
        labelCorner.CornerRadius = UDim.new(0, 6)
        labelCorner.Parent = cpLabel
    end
    cpListFrame.CanvasSize = UDim2.new(0, 0, 0, cpListLayout.AbsoluteContentSize.Y)
end

addCPBtn.MouseButton1Click:Connect(function()
    table.insert(checkpoints, rootPart.Position)
    refreshCPList()
    saveConfig()
end)

-- Run Button
local runBtn = Instance.new("TextButton")
runBtn.Size = UDim2.new(0, 120, 0, 40)
runBtn.Position = UDim2.new(0, 10, 0, 260)
runBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
runBtn.TextColor3 = Color3.new(1,1,1)
runBtn.Font = Enum.Font.GothamBold
runBtn.TextSize = 18
runBtn.Text = "Run"
runBtn.AutoButtonColor = false
local runCorner = Instance.new("UICorner")
runCorner.CornerRadius = UDim.new(0, 10)
runCorner.Parent = runBtn
runBtn.Parent = container

runBtn.MouseButton1Click:Connect(function()
    if #checkpoints == 0 then return end
    runCheckpoints()
end)

-- Settings Button and Frame
local settingsBtn = Instance.new("TextButton")
settingsBtn.Size = UDim2.new(0, 40, 0, 30)
settingsBtn.Position = UDim2.new(1, -135, 0, 5)
settingsBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
settingsBtn.Text = "⚙"
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.TextColor3 = Color3.new(1,1,1)
settingsBtn.TextSize = 24
settingsBtn.Parent = titleBar
settingsBtn.AutoButtonColor = false

local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(0, 300, 0, 180)
settingsFrame.Position = UDim2.new(0, 10, 0, 280)
settingsFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
settingsFrame.Visible = false
settingsFrame.Parent = mainFrame
local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0, 12)
settingsCorner.Parent = settingsFrame

-- Godmode Toggle
local godmodeBtn, godmodeSlider = createToggleButton("Godmode", godmodeEnabled)
godmodeBtn.Position = UDim2.new(0, 20, 0, 20)
godmodeBtn.Parent = settingsFrame
godmodeBtn.MouseButton1Click:Connect(function()
    godmodeEnabled = not godmodeEnabled
    local goalPos = godmodeEnabled and UDim2.new(0.7, 0, 0.1, 0) or UDim2.new(0.05, 0, 0.1, 0)
    local goalColor = godmodeEnabled and Color3.fromRGB(0, 230, 64) or Color3.fromRGB(180, 0, 0)
    TweenService:Create(godmodeSlider, TweenInfo.new(0.25), {Position = goalPos, BackgroundColor3 = goalColor}):Play()
    if godmodeEnabled then
        startGodmode()
    else
        stopGodmode()
    end
    saveConfig()
end)

-- Walk Speed Label and Slider
local walkSpeedLabel = Instance.new("TextLabel")
walkSpeedLabel.Size = UDim2.new(0, 140, 0, 25)
walkSpeedLabel.Position = UDim2.new(0, 20, 0, 80)
walkSpeedLabel.BackgroundTransparency = 1
walkSpeedLabel.TextColor3 = Color3.new(1,1,1)
walkSpeedLabel.Font = Enum.Font.GothamBold
walkSpeedLabel.TextSize = 16
walkSpeedLabel.Text = "Walk Speed: "..walkSpeed
walkSpeedLabel.Parent = settingsFrame

local walkSpeedSlider = Instance.new("Frame")
walkSpeedSlider.Size = UDim2.new(0, 200, 0, 20)
walkSpeedSlider.Position = UDim2.new(0, 20, 0, 110)
walkSpeedSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
walkSpeedSlider.Parent = settingsFrame
local walkSpeedCorner = Instance.new("UICorner")
walkSpeedCorner.CornerRadius = UDim.new(0, 10)
walkSpeedCorner.Parent = walkSpeedSlider

local walkSpeedFill = Instance.new("Frame")
walkSpeedFill.Size = UDim2.new(math.clamp((walkSpeed - 16) / 84, 0, 1), 0, 1, 0)
walkSpeedFill.BackgroundColor3 = Color3.fromRGB(0, 200, 64)
walkSpeedFill.Parent = walkSpeedSlider
local walkSpeedFillCorner = Instance.new("UICorner")
walkSpeedFillCorner.CornerRadius = UDim.new(0, 10)
walkSpeedFillCorner.Parent = walkSpeedFill

walkSpeedSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local function move(input2)
            local pos = input2.Position.X - walkSpeedSlider.AbsolutePosition.X
            pos = math.clamp(pos, 0, walkSpeedSlider.AbsoluteSize.X)
            local ratio = pos / walkSpeedSlider.AbsoluteSize.X
            walkSpeed = math.floor(16 + ratio * 84)
            walkSpeedLabel.Text = "Walk Speed: "..walkSpeed
            walkSpeedFill.Size = UDim2.new(ratio, 0, 1, 0)
            humanoid.WalkSpeed = walkSpeed
            saveConfig()
        end
        local moveConn
        local upConn
        moveConn = UserInputService.InputChanged:Connect(function(input2)
            if input2.UserInputType == Enum.UserInputType.MouseMovement then
                move(input2)
            end
        end)
        upConn = UserInputService.InputEnded:Connect(function(input2)
            if input2.UserInputType == Enum.UserInputType.MouseButton1 then
                moveConn:Disconnect()
                upConn:Disconnect()
            end
        end)
        move(input)
    end
end)

-- Fly Speed Label and Slider
local flySpeedLabel = Instance.new("TextLabel")
flySpeedLabel.Size = UDim2.new(0, 140, 0, 25)
flySpeedLabel.Position = UDim2.new(0, 20, 0, 140)
flySpeedLabel.BackgroundTransparency = 1
flySpeedLabel.TextColor3 = Color3.new(1,1,1)
flySpeedLabel.Font = Enum.Font.GothamBold
flySpeedLabel.TextSize = 16
flySpeedLabel.Text = "Fly Speed: "..flySpeed
flySpeedLabel.Parent = settingsFrame

local flySpeedSlider = Instance.new("Frame")
flySpeedSlider.Size = UDim2.new(0, 200, 0, 20)
flySpeedSlider.Position = UDim2.new(0, 20, 0, 170)
flySpeedSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
flySpeedSlider.Parent = settingsFrame
local flySpeedCorner = Instance.new("UICorner")
flySpeedCorner.CornerRadius = UDim.new(0, 10)
flySpeedCorner.Parent = flySpeedSlider

local flySpeedFill = Instance.new("Frame")
flySpeedFill.Size = UDim2.new(math.clamp(flySpeed / 200, 0, 1), 0, 1, 0)
flySpeedFill.BackgroundColor3 = Color3.fromRGB(0, 200, 64)
flySpeedFill.Parent = flySpeedSlider
local flySpeedFillCorner = Instance.new("UICorner")
flySpeedFillCorner.CornerRadius = UDim.new(0, 10)
flySpeedFillCorner.Parent = flySpeedFill

flySpeedSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local function move(input2)
            local pos = input2.Position.X - flySpeedSlider.AbsolutePosition.X
            pos = math.clamp(pos, 0, flySpeedSlider.AbsoluteSize.X)
            local ratio = pos / flySpeedSlider.AbsoluteSize.X
            flySpeed = math.floor(ratio * 200)
            flySpeed = math.max(10, flySpeed)
            flySpeedLabel.Text = "Fly Speed: "..flySpeed
            flySpeedFill.Size = UDim2.new(ratio, 0, 1, 0)
            if flyEnabled then
                stopFly()
                startFly()
            end
            saveConfig()
        end
        local moveConn
        local upConn
        moveConn = UserInputService.InputChanged:Connect(function(input2)
            if input2.UserInputType == Enum.UserInputType.MouseMovement then
                move(input2)
            end
        end)
        upConn = UserInputService.InputEnded:Connect(function(input2)
            if input2.UserInputType == Enum.UserInputType.MouseButton1 then
                moveConn:Disconnect()
                upConn:Disconnect()
            end
        end)
        move(input)
    end
end)

-- Settings Toggle
settingsBtn.MouseButton1Click:Connect(function()
    settingsFrame.Visible = not settingsFrame.Visible
end)

-- Initialize
loadConfig()
refreshCPList()
humanoid.WalkSpeed = walkSpeed
if godmodeEnabled then
    startGodmode()
end
if flyEnabled then
    startFly()
end
