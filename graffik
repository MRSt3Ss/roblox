-- Bons Graphics Enhancer GUI
-- Efek hanya aktif kalau diaktifkan lewat tombol GUI

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BonsGraphicsGUI"
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 200)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Bons Graphics Enhancer"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = MainFrame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 120, 0, 40)
ToggleButton.Position = UDim2.new(0.5, -60, 0.5, -20)
ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ToggleButton.Text = "ON"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 18
ToggleButton.Parent = MainFrame

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 16
CloseButton.Parent = MainFrame

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -70, 0, 5)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 20
MinimizeButton.Parent = MainFrame

-- Efek Lighting
local Bloom = Instance.new("BloomEffect", Lighting)
Bloom.Intensity = 0
Bloom.Size = 24
Bloom.Threshold = 0.8

local DepthOfField = Instance.new("DepthOfFieldEffect", Lighting)
DepthOfField.InFocusRadius = 50
DepthOfField.NearIntensity = 0
DepthOfField.FarIntensity = 0

local ColorCorrection = Instance.new("ColorCorrectionEffect", Lighting)
ColorCorrection.Brightness = 0
ColorCorrection.Contrast = 0
ColorCorrection.Saturation = 0

-- Status
local graphicsOn = false
local minimized = false

-- Fungsi ON/OFF
local function toggleGraphics()
	graphicsOn = not graphicsOn
	if graphicsOn then
		ToggleButton.Text = "OFF"
		Bloom.Intensity = 0.6
		DepthOfField.NearIntensity = 0.2
		DepthOfField.FarIntensity = 0.4
		ColorCorrection.Brightness = 0.05
		ColorCorrection.Contrast = 0.1
		ColorCorrection.Saturation = 0.2
	else
		ToggleButton.Text = "ON"
		Bloom.Intensity = 0
		DepthOfField.NearIntensity = 0
		DepthOfField.FarIntensity = 0
		ColorCorrection.Brightness = 0
		ColorCorrection.Contrast = 0
		ColorCorrection.Saturation = 0
	end
end

-- Event
ToggleButton.MouseButton1Click:Connect(toggleGraphics)
CloseButton.MouseButton1Click:Connect(function()
	ScreenGui:Destroy()
end)
MinimizeButton.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		for _, v in pairs(MainFrame:GetChildren()) do
			if v ~= Title and v ~= MinimizeButton and v ~= CloseButton then
				v.Visible = false
			end
		end
		MainFrame.Size = UDim2.new(0, 300, 0, 40)
	else
		for _, v in pairs(MainFrame:GetChildren()) do
			v.Visible = true
		end
		MainFrame.Size = UDim2.new(0, 300, 0, 200)
	end
end)
