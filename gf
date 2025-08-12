-- BonsGraphicEnhancer - By Bons
-- GUI untuk mempercantik grafik Roblox dengan preset & custom mode

-- ==== Services ====
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- ==== Efek Setup ====
local function clearEffects()
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") then
            v:Destroy()
        end
    end
end

local function applyPreset(preset)
    clearEffects()

    local bloom = Instance.new("BloomEffect", Lighting)
    bloom.Intensity = 0.5
    bloom.Size = 56
    bloom.Threshold = 0.9

    local color = Instance.new("ColorCorrectionEffect", Lighting)
    local sunrays = Instance.new("SunRaysEffect", Lighting)
    local dof = Instance.new("DepthOfFieldEffect", Lighting)
    dof.FarIntensity = 0.1
    dof.FocusDistance = 30
    dof.InFocusRadius = 20

    if preset == "Pagi" then
        Lighting.ClockTime = 8
        Lighting.Brightness = 3
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 244, 214)
        color.TintColor = Color3.fromRGB(255, 240, 220)
        sunrays.Intensity = 0.2

    elseif preset == "Senja" then
        Lighting.ClockTime = 18.5
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 180, 150)
        color.TintColor = Color3.fromRGB(255, 200, 180)
        sunrays.Intensity = 0.4

    elseif preset == "Malam" then
        Lighting.ClockTime = 22
        Lighting.Brightness = 1
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 200, 255)
        color.TintColor = Color3.fromRGB(200, 220, 255)
        sunrays.Intensity = 0.05
    end
end

-- ==== GUI Setup ====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui
ScreenGui.Name = "BonsGraphicGUI"

local mainFrame = Instance.new("Frame", ScreenGui)
mainFrame.Size = UDim2.new(0, 300, 0, 250)
mainFrame.Position = UDim2.new(0.35, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "🎨 Bons Graphic Enhancer"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16

local function makeButton(name, order, callback)
    local btn = Instance.new("TextButton", mainFrame)
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, 40 + (order * 35))
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.MouseButton1Click:Connect(callback)
end

makeButton("🌅 Pagi", 0, function() applyPreset("Pagi") end)
makeButton("🌇 Senja", 1, function() applyPreset("Senja") end)
makeButton("🌙 Malam", 2, function() applyPreset("Malam") end)
makeButton("❌ Clear Efek", 3, function() clearEffects() end)

-- Custom mode (Bloom + Color)
makeButton("🎛 Custom Mode", 4, function()
    clearEffects()
    local bloom = Instance.new("BloomEffect", Lighting)
    bloom.Intensity = 0.8
    bloom.Size = 60
    bloom.Threshold = 0.85

    local color = Instance.new("ColorCorrectionEffect", Lighting)
    color.TintColor = Color3.fromRGB(255, 255, 255)

    Lighting.ClockTime = 12
    Lighting.Brightness = 3
end)

print("[BonsGraphicEnhancer] GUI Loaded - Pilih preset untuk aktifkan efek")
