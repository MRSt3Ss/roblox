--[[
  Roblox HD Graphics GUI (Template Aman)
  Fitur:
    - Preset waktu: Pagi, Senja, Malam
    - Efek: Bloom, DOF, Shadow
    - GUI draggable + minimize icon
    - Photo Mode (freecam) dengan kontrol W/A/S/D + klik kanan arah kamera
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- GUI Setup
local gui = Instance.new("ScreenGui")
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false

-- Draggable function
local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
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
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 200)
mainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Text = "HD Graphics Controller"
title.TextColor3 = Color3.new(1, 1, 1)
title.Parent = mainFrame

makeDraggable(mainFrame, title)

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -30, 0, 0)
minimizeBtn.Text = "-"
minimizeBtn.Parent = mainFrame

local minimizedIcon = Instance.new("TextButton")
minimizedIcon.Size = UDim2.new(0, 50, 0, 50)
minimizedIcon.Position = UDim2.new(0, 10, 0, 10)
minimizedIcon.Text = "🎥"
minimizedIcon.Visible = false
minimizedIcon.Parent = gui

minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    minimizedIcon.Visible = true
end)

minimizedIcon.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    minimizedIcon.Visible = false
end)

-- Lighting Effects
local dof = Instance.new("DepthOfFieldEffect", Lighting)
local bloom = Instance.new("BloomEffect", Lighting)
local shadow = Instance.new("SunRaysEffect", Lighting)

dof.Enabled = false
bloom.Enabled = false
shadow.Enabled = false

local function applyPreset(preset)
    if preset == "Pagi" then
        Lighting.TimeOfDay = "07:00:00"
        Lighting.Brightness = 3
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 240, 220)
        bloom.Enabled = true
        dof.Enabled = true
        shadow.Enabled = true
    elseif preset == "Senja" then
        Lighting.TimeOfDay = "18:00:00"
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 180, 120)
        bloom.Enabled = true
        dof.Enabled = true
        shadow.Enabled = true
    elseif preset == "Malam" then
        Lighting.TimeOfDay = "22:00:00"
        Lighting.Brightness = 1
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 200, 255)
        bloom.Enabled = true
        dof.Enabled = true
        shadow.Enabled = false
    end
end

-- Time Button
local timeBtn = Instance.new("TextButton")
timeBtn.Size = UDim2.new(1, -20, 0, 30)
timeBtn.Position = UDim2.new(0, 10, 0, 40)
timeBtn.Text = "Pilih Waktu"
timeBtn.Parent = mainFrame

local presets = {"Pagi", "Senja", "Malam"}
timeBtn.MouseButton1Click:Connect(function()
    local choice = presets[math.random(1, #presets)]
    timeBtn.Text = "Waktu: " .. choice
    applyPreset(choice)
end)

-- Depth Slider
local sliderFrame = Instance.new("Frame")
sliderFrame.Size = UDim2.new(1, -20, 0, 20)
sliderFrame.Position = UDim2.new(0, 10, 0, 80)
sliderFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
sliderFrame.Parent = mainFrame

local slider = Instance.new("Frame")
slider.Size = UDim2.new(0.5, 0, 1, 0)
slider.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
slider.Parent = sliderFrame

local draggingSlider = false
slider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = true
    end
end)
slider.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = false
    end
end)

RunService.RenderStepped:Connect(function()
    if draggingSlider then
        local mouseX = UserInputService:GetMouseLocation().X
        local relX = math.clamp((mouseX - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
        slider.Size = UDim2.new(relX, 0, 1, 0)
        dof.InFocusRadius = 50 * (1 - relX)
    end
end)

-- Photo Mode
local inPhotoMode = false
local cam = workspace.CurrentCamera
local moveDir = Vector3.zero
local speed = 1

local photoBtn = Instance.new("TextButton")
photoBtn.Size = UDim2.new(1, -20, 0, 30)
photoBtn.Position = UDim2.new(0, 10, 0, 120)
photoBtn.Text = "Mode Foto: OFF"
photoBtn.Parent = mainFrame

photoBtn.MouseButton1Click:Connect(function()
    inPhotoMode = not inPhotoMode
    photoBtn.Text = "Mode Foto: " .. (inPhotoMode and "ON" or "OFF")
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if inPhotoMode then
        if input.KeyCode == Enum.KeyCode.W then moveDir = Vector3.new(0, 0, -1) end
        if input.KeyCode == Enum.KeyCode.S then moveDir = Vector3.new(0, 0, 1) end
        if input.KeyCode == Enum.KeyCode.A then moveDir = Vector3.new(-1, 0, 0) end
        if input.KeyCode == Enum.KeyCode.D then moveDir = Vector3.new(1, 0, 0) end
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if inPhotoMode then
        if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S or
           input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
            moveDir = Vector3.zero
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if inPhotoMode then
        cam.CFrame = cam.CFrame * CFrame.new(moveDir * speed * dt * 10)
    end
end)
