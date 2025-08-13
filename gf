--[[ 
  SadsXBons • HD Graphics + Photo Mode (Cinematic)
  - GUI draggable + minimize (ikon 🌅)
  - Preset langit gradien: Pagi / Senja / Malam (smooth)
  - Bloom halus, ColorCorrection (tone), DOF fokus karakter, SunRays opsional
  - “Bayangan” lebih hidup (GlobalShadows, specular/diffuse tweak)
  - Photo Mode (Camhunt):
      * W maju, S mundur, A kiri, D kanan (relatif kamera)
      * Klik kanan tahan untuk ngarahin kamera (mouse delta)
      * Karakter dibekukan (nggak jatuh), pose tetap
      * Kecepatan kamera bisa diatur slider; Ctrl untuk lambat (optional)
--]]

--// Services
local Players            = game:GetService("Players")
local Lighting           = game:GetService("Lighting")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local Workspace          = game:GetService("Workspace")

local LocalPlayer        = Players.LocalPlayer
local PlayerGui          = LocalPlayer:WaitForChild("PlayerGui")
local Camera             = Workspace.CurrentCamera

-- // Utils
local GUI_NAME = "SadsXBons_HDGraphics_Photo_v3"

for _,v in ipairs(PlayerGui:GetChildren()) do
	if v.Name == GUI_NAME then pcall(function() v:Destroy() end) end
end

local function new(cls, props, parent)
	local o = Instance.new(cls)
	if props then for k,v in pairs(props) do o[k] = v end end
	if parent then o.Parent = parent end
	return o
end

local function ensureEffect(className, name)
	local ex = Lighting:FindFirstChild(name)
	if ex and ex.ClassName ~= className then pcall(function() ex:Destroy() end); ex = nil end
	if not ex then ex = Instance.new(className); ex.Name = name; ex.Parent = Lighting end
	return ex
end

local function notif(text)
	local gui = new("ScreenGui", {ResetOnSpawn=false}, PlayerGui)
	local f = new("Frame", {
		Size=UDim2.new(0,360,0,36),
		Position=UDim2.new(0.5,-180,0.86,0),
		BackgroundColor3=Color3.fromRGB(24,24,24),
		BorderSizePixel=0
	}, gui)
	new("UICorner",{CornerRadius=UDim.new(0,8)}, f)
	local l = new("TextLabel", {
		Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,8,0,0),
		BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left,
		Font=Enum.Font.Gotham, TextSize=14, TextColor3=Color3.fromRGB(255,170,140),
		Text=text
	}, f)
	task.delay(1.6, function() pcall(function() gui:Destroy() end) end)
end

-- // Keep originals to reset
local originals = {
	TimeOfDay = Lighting.TimeOfDay,
	Brightness = Lighting.Brightness,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	ColorShift_Top = Lighting.ColorShift_Top,
	ColorShift_Bottom = Lighting.ColorShift_Bottom,
	ClockTime = Lighting.ClockTime,
	Exposure = Lighting.ExposureCompensation,
	GlobalShadows = Lighting.GlobalShadows,
	EnvironmentDiffuseScale = Lighting:FindFirstChild("EnvironmentDiffuseScale") and Lighting.EnvironmentDiffuseScale or nil,
	EnvironmentSpecularScale = Lighting:FindFirstChild("EnvironmentSpecularScale") and Lighting.EnvironmentSpecularScale or nil,
}

-- // Effects (named & singletons)
local CC     = ensureEffect("ColorCorrectionEffect", "SXB_Color")
local Bloom  = ensureEffect("BloomEffect",           "SXB_Bloom")
local DOF    = ensureEffect("DepthOfFieldEffect",    "SXB_DOF")
local Rays   = ensureEffect("SunRaysEffect",         "SXB_SunRays")

-- Default OFF (non-intrusive)
CC.Enabled     = false; CC.TintColor = Color3.fromRGB(255,255,255); CC.Contrast = 0.05; CC.Saturation = 0.05; CC.Brightness = 0
Bloom.Enabled  = false; Bloom.Intensity = 0.6; Bloom.Size = 24; Bloom.Threshold = 0.9
DOF.Enabled    = false; DOF.InFocusRadius = 14; DOF.FocusDistance = 12; DOF.FarIntensity = 0.35; DOF.NearIntensity = 0
Rays.Enabled   = false; Rays.Intensity = 0.05; Rays.Spread = 0.45

-- Atmosphere + Sky (gradien lembut)
local Atmos = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
Atmos.Name = "SXB_Atmosphere"
Atmos.Density = 0.35
Atmos.Offset = 0
Atmos.Color = Color3.fromRGB(200, 210, 235)
Atmos.Decay = Color3.fromRGB(65, 80, 110)
Atmos.Glare = 0
Atmos.Haze = 2

local SkyObj = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
SkyObj.Name = "SXB_Sky"

-- Shadows / PBR feel
Lighting.GlobalShadows = true
pcall(function() Lighting.EnvironmentDiffuseScale = 1 end)
pcall(function() Lighting.EnvironmentSpecularScale = 1 end)

-- // GUI
local sg = new("ScreenGui", {Name=GUI_NAME, ResetOnSpawn=false, IgnoreGuiInset=true}, PlayerGui)

local Main = new("Frame", {
	Size=UDim2.new(0,360,0,300),
	Position=UDim2.new(0.35,0,0.3,0),
	BackgroundColor3=Color3.fromRGB(28,28,28),
	BorderSizePixel=0
}, sg)
new("UICorner",{CornerRadius=UDim.new(0,10)}, Main)

local Header = new("Frame", {Size=UDim2.new(1,0,0,40), BackgroundColor3=Color3.fromRGB(44,44,44)}, Main)
new("UICorner",{CornerRadius=UDim.new(0,10)}, Header)
local Title = new("TextLabel", {
	Text="SadsXBons • Cinematic Graphics", Font=Enum.Font.GothamBold, TextSize=16,
	TextColor3=Color3.fromRGB(255,180,140), BackgroundTransparency=1, Position=UDim2.new(0,12,0,6),
	Size=UDim2.new(1,-120,1,-6)
}, Header)

local BtnClose = new("TextButton", {
	Text="X", Size=UDim2.new(0,34,0,28), Position=UDim2.new(1,-42,0,6),
	BackgroundColor3=Color3.fromRGB(170,60,60),
	Font=Enum.Font.GothamBold, TextColor3=Color3.new(1,1,1)
}, Header)
new("UICorner",{CornerRadius=UDim.new(0,8)}, BtnClose)

local BtnMin = new("TextButton", {
	Text="_", Size=UDim2.new(0,34,0,28), Position=UDim2.new(1,-84,0,6),
	BackgroundColor3=Color3.fromRGB(80,80,80),
	Font=Enum.Font.GothamBold, TextColor3=Color3.new(1,1,1)
}, Header)
new("UICorner",{CornerRadius=UDim.new(0,8)}, BtnMin)

local MinIcon = new("TextButton", {
	Text="🌅", Size=UDim2.new(0,52,0,52), Position=UDim2.new(0,12,0,12),
	Visible=false, BackgroundColor3=Color3.fromRGB(22,22,22), TextSize=24
}, sg)
new("UICorner",{CornerRadius=UDim.new(0,12)}, MinIcon)

-- Draggable
do
	local dragging=false; local dragStart; local startPos
	Header.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 then
			dragging=true; dragStart=input.Position; startPos=Main.Position
			input.Changed:Connect(function()
				if input.UserInputState==Enum.UserInputState.End then dragging=false end
			end)
		end
	end)
	Header.InputChanged:Connect(function(input)
		if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end
BtnMin.MouseButton1Click:Connect(function() Main.Visible=false; MinIcon.Visible=true end)
MinIcon.MouseButton1Click:Connect(function() Main.Visible=true; MinIcon.Visible=false end)
BtnClose.MouseButton1Click:Connect(function() pcall(function() sg:Destroy() end) end)

-- Body (2 kolom)
local Left  = new("Frame",{Size=UDim2.new(0.52,0,1,-48), Position=UDim2.new(0,10,0,48), BackgroundTransparency=1}, Main)
local Right = new("Frame",{Size=UDim2.new(0.4,0,1,-48),  Position=UDim2.new(0.58,0,0,48), BackgroundTransparency=1}, Main)

local function mkBtn(p, txt, y)
	local b = new("TextButton", {
		Text=txt, Size=UDim2.new(1,0,0,34), Position=UDim2.new(0,0,0,y),
		BackgroundColor3=Color3.fromRGB(52,52,52), TextColor3=Color3.fromRGB(235,235,235),
		Font=Enum.Font.GothamBold, TextSize=14
	}, p)
	new("UICorner",{CornerRadius=UDim.new(0,8)}, b)
	return b
end

-- Presets
local BtnMorning = mkBtn(Left,  "🌤️  Pagi (Soft Blue)",     0)
local BtnSunset  = mkBtn(Left,  "🌇  Senja (Orange Grad)",  40)
local BtnNight   = mkBtn(Left,  "🌙  Malam (Neon Lamps)",   80)
local BtnReset   = mkBtn(Left,  "⟲  Reset Visuals",        140)

-- Toggles & sliders (Right)
local TG_CC    = mkBtn(Right, "Color Grade: OFF", 0)
local TG_Bloom = mkBtn(Right, "Bloom: OFF",       40)
local TG_DOF   = mkBtn(Right, "DOF: OFF",         80)
local TG_Rays  = mkBtn(Right, "Sun Rays: OFF",    120)

local lblDOF = new("TextLabel", {
	Text="DOF InFocusRadius", Size=UDim2.new(1,0,0,18), Position=UDim2.new(0,0,0,166),
	BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=12, TextColor3=Color3.fromRGB(220,220,220),
	TextXAlignment=Enum.TextXAlignment.Left
}, Right)
local barDOF = new("Frame", {Size=UDim2.new(1,0,0,18), Position=UDim2.new(0,0,0,186), BackgroundColor3=Color3.fromRGB(52,52,52)}, Right)
new("UICorner",{CornerRadius=UDim.new(0,6)}, barDOF)
local fillDOF = new("Frame", {Size=UDim2.new(0.1,0,1,0), BackgroundColor3=Color3.fromRGB(255,140,120)}, barDOF)
new("UICorner",{CornerRadius=UDim.new(0,6)}, fillDOF)
local valDOF = new("TextLabel", {Text=tostring(DOF.InFocusRadius), Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,0,206), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=12, TextColor3=Color3.fromRGB(200,200,200), TextXAlignment=Enum.TextXAlignment.Center}, Right)

local lblCam = new("TextLabel", {
	Text="Camera Speed", Size=UDim2.new(1,0,0,18), Position=UDim2.new(0,0,0,230),
	BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=12, TextColor3=Color3.fromRGB(220,220,220),
	TextXAlignment=Enum.TextXAlignment.Left
}, Right)
local barCam = new("Frame", {Size=UDim2.new(1,0,0,18), Position=UDim2.new(0,0,0,250), BackgroundColor3=Color3.fromRGB(52,52,52)}, Right)
new("UICorner",{CornerRadius=UDim.new(0,6)}, barCam)
local fillCam = new("Frame", {Size=UDim2.new(0.3,0,1,0), BackgroundColor3=Color3.fromRGB(255,140,120)}, barCam)
new("UICorner",{CornerRadius=UDim.new(0,6)}, fillCam)
local valCam = new("TextLabel", {Text="30", Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,0,270), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=12, TextColor3=Color3.fromRGB(200,200,200), TextXAlignment=Enum.TextXAlignment.Center}, Right)

-- Photo Mode Toggle
local BtnPhoto = mkBtn(Left, "📷  Mode Foto: OFF", 190)

-- Slider helpers
local function attachBar(bar, fill, minv, maxv, cb)
	local dragging=false
	bar.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 then
			dragging=true
			local function setFrom(x)
				local rel = math.clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
				fill.Size = UDim2.new(rel,0,1,0)
				local v = minv + (maxv-minv)*rel
				if cb then cb(v) end
			end
			setFrom(UserInputService:GetMouseLocation().X)
			local conn
			conn = UserInputService.InputChanged:Connect(function(i)
				if not dragging then if conn then conn:Disconnect() end return end
				if i.UserInputType==Enum.UserInputType.MouseMovement then
					setFrom(i.Position.X)
				end
			end)
			bar.InputEnded:Once(function(e)
				if e.UserInputType==Enum.UserInputType.MouseButton1 then
					dragging=false
					if conn then conn:Disconnect() end
				end
			end)
		end
	end)
end

attachBar(barDOF, fillDOF, 4, 120, function(v)
	DOF.InFocusRadius = math.floor(v+0.5)
	valDOF.Text = tostring(DOF.InFocusRadius)
end)

local camSpeed = 30
attachBar(barCam, fillCam, 5, 120, function(v)
	camSpeed = math.floor(v+0.5)
	valCam.Text = tostring(camSpeed)
end)

-- Toggle helpers
local function applyToggle(btn, state)
	btn.TextColor3 = Color3.fromRGB(235,235,235)
	btn.BackgroundColor3 = state and Color3.fromRGB(170,96,96) or Color3.fromRGB(52,52,52)
end

-- Presets (gradien & tone)
local function presetMorning()
	Lighting.TimeOfDay = "07:30:00"; Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(140,140,150)
	Lighting.OutdoorAmbient = Color3.fromRGB(210,220,240)
	Lighting.ColorShift_Top = Color3.fromRGB(210,220,255)
	Lighting.ColorShift_Bottom = Color3.fromRGB(255,248,235)
	Atmos.Density = 0.32; Atmos.Color = Color3.fromRGB(215,225,245); Atmos.Decay = Color3.fromRGB(80,100,140); Atmos.Haze = 1.8
	CC.Enabled = true; CC.TintColor = Color3.fromRGB(250,255,255); CC.Contrast = 0.08; CC.Saturation = 0.08; CC.Brightness = 0.02
	Bloom.Enabled = true; Bloom.Intensity = math.clamp(Bloom.Intensity,0.5,1.2); Bloom.Size = 24; Bloom.Threshold = 0.9
	Rays.Enabled = false
	DOF.Enabled = true; DOF.FarIntensity = 0.35; DOF.NearIntensity = 0
	notif("Preset: Pagi diterapkan")
end

local function presetSunset()
	Lighting.TimeOfDay = "18:10:00"; Lighting.Brightness = 1.6
	Lighting.Ambient = Color3.fromRGB(110,85,75)
	Lighting.OutdoorAmbient = Color3.fromRGB(225,170,130)
	Lighting.ColorShift_Top = Color3.fromRGB(245,185,140)    -- orange lembut
	Lighting.ColorShift_Bottom = Color3.fromRGB(255,130,70)  -- gradien senja
	Atmos.Density = 0.38; Atmos.Color = Color3.fromRGB(240,200,165); Atmos.Decay = Color3.fromRGB(120,90,80); Atmos.Haze = 2.2
	CC.Enabled = true; CC.TintColor = Color3.fromRGB(255,230,210); CC.Contrast = 0.12; CC.Saturation = 0.12; CC.Brightness = 0.01
	Bloom.Enabled = true; Bloom.Intensity = math.clamp(Bloom.Intensity,0.7,1.6); Bloom.Size = 28; Bloom.Threshold = 0.82
	Rays.Enabled = true; Rays.Intensity = 0.08; Rays.Spread = 0.5
	DOF.Enabled = true; DOF.FarIntensity = 0.42; DOF.NearIntensity = 0
	notif("Preset: Senja diterapkan")
end

local savedLights = {}
local function boostLamps(mult)
	savedLights = {}
	for _,v in ipairs(Workspace:GetDescendants()) do
		if v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
			local ok, oldB = pcall(function() return v.Brightness end)
			if ok then
				if savedLights[v]==nil then savedLights[v] = {Brightness=v.Brightness, Enabled=v.Enabled} end
				pcall(function() v.Enabled = true; v.Brightness = (oldB or 0.2)*mult end)
			end
		end
	end
end
local function restoreLamps()
	for inst,dat in pairs(savedLights) do
		if inst and inst.Parent then
			pcall(function() inst.Brightness = dat.Brightness; inst.Enabled = dat.Enabled end)
		end
	end
	savedLights = {}
end

local function presetNight()
	Lighting.TimeOfDay = "22:40:00"; Lighting.Brightness = 0.9
	Lighting.Ambient = Color3.fromRGB(30,34,42)
	Lighting.OutdoorAmbient = Color3.fromRGB(40,48,72)
	Lighting.ColorShift_Top = Color3.fromRGB(12,16,30)
	Lighting.ColorShift_Bottom = Color3.fromRGB(40,52,80)
	Atmos.Density = 0.42; Atmos.Color = Color3.fromRGB(150,170,220); Atmos.Decay = Color3.fromRGB(55,70,100); Atmos.Haze = 2.6
	CC.Enabled = true; CC.TintColor = Color3.fromRGB(220,230,255); CC.Contrast = 0.10; CC.Saturation = 0.05; CC.Brightness = -0.02
	Bloom.Enabled = true; Bloom.Intensity = math.clamp(Bloom.Intensity,0.4,1.0); Bloom.Size = 20; Bloom.Threshold = 0.92
	Rays.Enabled = false
	DOF.Enabled = true; DOF.FarIntensity = 0.34; DOF.NearIntensity = 0
	boostLamps(1.8)
	notif("Preset: Malam diterapkan (lampu diperkuat)")
end

local function resetVisuals()
	Lighting.TimeOfDay = originals.TimeOfDay
	Lighting.Brightness = originals.Brightness
	Lighting.Ambient = originals.Ambient
	Lighting.OutdoorAmbient = originals.OutdoorAmbient
	Lighting.ColorShift_Top = originals.ColorShift_Top
	Lighting.ColorShift_Bottom = originals.ColorShift_Bottom
	Lighting.ExposureCompensation = originals.Exposure or 0
	Lighting.GlobalShadows = originals.GlobalShadows
	if originals.EnvironmentDiffuseScale then pcall(function() Lighting.EnvironmentDiffuseScale = originals.EnvironmentDiffuseScale end) end
	if originals.EnvironmentSpecularScale then pcall(function() Lighting.EnvironmentSpecularScale = originals.EnvironmentSpecularScale end) end

	CC.Enabled=false; Bloom.Enabled=false; DOF.Enabled=false; Rays.Enabled=false
	restoreLamps()
	notif("Visuals direset ke kondisi awal")
end

-- Bind preset buttons
BtnMorning.MouseButton1Click:Connect(presetMorning)
BtnSunset.MouseButton1Click:Connect(presetSunset)
BtnNight.MouseButton1Click:Connect(presetNight)
BtnReset.MouseButton1Click:Connect(resetVisuals)

-- Toggle buttons
local ccOn, bloomOn, dofOn, raysOn = false, false, false, false
local function setCC(state)   ccOn=state;   CC.Enabled=state;   TG_CC.Text   = state and "Color Grade: ON" or "Color Grade: OFF"; applyToggle(TG_CC, state) end
local function setBloom(s)    bloomOn=s;    Bloom.Enabled=s;    TG_Bloom.Text= s and "Bloom: ON"       or "Bloom: OFF";       applyToggle(TG_Bloom, s) end
local function setDOF(s)      dofOn=s;      DOF.Enabled=s;      TG_DOF.Text  = s and "DOF: ON"         or "DOF: OFF";         applyToggle(TG_DOF, s) end
local function setRays(s)     raysOn=s;     Rays.Enabled=s;     TG_Rays.Text = s and "Sun Rays: ON"    or "Sun Rays: OFF";    applyToggle(TG_Rays, s) end

TG_CC.MouseButton1Click:Connect(function() setCC(not ccOn) end)
TG_Bloom.MouseButton1Click:Connect(function() setBloom(not bloomOn) end)
TG_DOF.MouseButton1Click:Connect(function() setDOF(not dofOn) end)
TG_Rays.MouseButton1Click:Connect(function() setRays(not raysOn) end)

-- // DOF focus terus ke karakter (biar subjek tajam, background blur halus)
RunService.Heartbeat:Connect(function()
	if DOF.Enabled then
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
			DOF.FocusDistance = math.clamp(dist, 1, 5000)
		end
	end
end)

-- // PHOTO MODE (Free-cam) — FIXED CONTROLS
local photoOn = false
local rbmHeld = false
local camYaw, camPitch = 0, 0
local keyDown = {W=false, A=false, S=false, D=false}
local slowFactor = 0.35 -- saat Ctrl ditekan
local boostFactor = 1.8 -- saat Shift ditekan
local charState = {
	WalkSpeed=nil, JumpPower=nil, AutoRotate=nil, PlatformStand=nil,
	HRP_Anchored=nil, HRP_CFrame=nil
}

local function freezeCharacter()
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if humanoid and hrp then
		charState.WalkSpeed = humanoid.WalkSpeed
		charState.JumpPower = humanoid.JumpPower
		charState.AutoRotate = humanoid.AutoRotate
		charState.PlatformStand = humanoid.PlatformStand
		charState.HRP_Anchored = hrp.Anchored
		charState.HRP_CFrame = hrp.CFrame

		pcall(function()
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.AutoRotate = false
			humanoid.PlatformStand = true
			hrp.Anchored = true
		end)
	end
end

local function unfreezeCharacter()
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if humanoid and hrp then
		pcall(function()
			humanoid.WalkSpeed = charState.WalkSpeed or 16
			humanoid.JumpPower = charState.JumpPower or 50
			humanoid.AutoRotate = (charState.AutoRotate ~= nil) and charState.AutoRotate or true
			humanoid.PlatformStand = charState.PlatformStand or false
			hrp.Anchored = charState.HRP_Anchored or false
			hrp.CFrame = charState.HRP_CFrame or hrp.CFrame
		end)
	end
end

local function setPhotoMode(state)
	if state == photoOn then return end
	photoOn = state
	if state then
		-- aktifkan efek default cinematic ringan
		if not ccOn then setCC(true) end
		if not bloomOn then setBloom(true) end
		if not dofOn then setDOF(true) end

		freezeCharacter()

		-- camera setup
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local origin = hrp and (hrp.CFrame + Vector3.new(0, 3, 0)) or CFrame.new(Camera.CFrame.Position)
		Camera.CameraType = Enum.CameraType.Scriptable
		Camera.CFrame = origin
		-- init yaw/pitch dari orientasi kamera sekarang
		local look = Camera.CFrame - Camera.CFrame.Position
		local _, y, _ = look:ToOrientation()
		camYaw = y; camPitch = 0

		BtnPhoto.Text = "📷  Mode Foto: ON"
		applyToggle(BtnPhoto, true)
		notif("Mode Foto ON — W/A/S/D gerak, klik kanan tahan untuk putar kamera")
	else
		Camera.CameraType = Enum.CameraType.Custom
		unfreezeCharacter()

		BtnPhoto.Text = "📷  Mode Foto: OFF"
		applyToggle(BtnPhoto, false)
		notif("Mode Foto OFF")
	end
end

BtnPhoto.MouseButton1Click:Connect(function()
	setPhotoMode(not photoOn)
end)

-- Input handling (W maju, S mundur, A kiri, D kanan)
UserInputService.InputBegan:Connect(function(inp, gpe)
	if gpe then return end
	if inp.KeyCode == Enum.KeyCode.W then keyDown.W = true end
	if inp.KeyCode == Enum.KeyCode.A then keyDown.A = true end
	if inp.KeyCode == Enum.KeyCode.S then keyDown.S = true end
	if inp.KeyCode == Enum.KeyCode.D then keyDown.D = true end

	if inp.UserInputType == Enum.UserInputType.MouseButton2 then
		rbmHeld = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		UserInputService.MouseIconEnabled = false
	end
end)
UserInputService.InputEnded:Connect(function(inp, gpe)
	if inp.KeyCode == Enum.KeyCode.W then keyDown.W = false end
	if inp.KeyCode == Enum.KeyCode.A then keyDown.A = false end
	if inp.KeyCode == Enum.KeyCode.S then keyDown.S = false end
	if inp.KeyCode == Enum.KeyCode.D then keyDown.D = false end

	if inp.UserInputType == Enum.UserInputType.MouseButton2 then
		rbmHeld = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
end)

-- Camera update loop
RunService.RenderStepped:Connect(function(dt)
	if not photoOn then return end

	-- rotasi saat RMB ditekan
	if rbmHeld then
		local delta = UserInputService:GetMouseDelta()
		camYaw   = camYaw - delta.X * 0.0025
		camPitch = math.clamp(camPitch - delta.Y * 0.0025, -1.2, 1.2)
	end

	-- arah dari yaw/pitch
	local rot = CFrame.fromOrientation(camPitch, camYaw, 0)
	local fwd = rot.LookVector
	local right = rot.RightVector

	-- kecepatan
	local speed = camSpeed
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then speed = speed * slowFactor end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * boostFactor end

	-- vektor gerak: W maju (fwd), S mundur, A kiri (-right), D kanan (right)
	local move = Vector3.new(0,0,0)
	if keyDown.W then move = move + fwd end
	if keyDown.S then move = move - fwd end
	if keyDown.A then move = move - right end
	if keyDown.D then move = move + right end

	if move.Magnitude > 0 then
		move = move.Unit * speed * dt
	end

	-- terapkan
	local pos = Camera.CFrame.Position + move
	Camera.CFrame = CFrame.new(pos) * rot
end)

-- Safety: kalau character respawn saat mode foto, refreeze
Players.LocalPlayer.CharacterAdded:Connect(function(char)
	if photoOn then
		task.wait(0.8)
		freezeCharacter()
	end
end)

-- Init toggle UI states
applyToggle(TG_CC, ccOn)
applyToggle(TG_Bloom, bloomOn)
applyToggle(TG_DOF, dofOn)
applyToggle(TG_Rays, raysOn)
applyToggle(BtnPhoto, photoOn)

notif("SadsXBons Cinematic siap. Pilih preset/efek. Mode Foto: W/A/S/D • RMB untuk putar kamera.")
