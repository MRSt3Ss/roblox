-- SadsXBons — HD Visuals + Freecam (final)
-- Features:
--  • GUI interactive (drag, minimize to logo, close)
--  • Presets: Morning / Sunset / Night (sunset warm + lamp boost)
--  • Bloom, SunRays, ColorCorrection, Atmosphere, DepthOfField (start OFF)
--  • DOF slider to adjust blur radius
--  • Mode Foto (Freecam): freeze character, WASD move camera, right-click hold to mouse-look, hold Ctrl to slow
--  • Effects applied only when toggled
--  • Client-side only

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- ---------- safety: remove old GUI if present ----------
local GUI_NAME = "SadsXBons_Visuals_GUI_v1"
for _,c in ipairs(PlayerGui:GetChildren()) do
	if c.Name == GUI_NAME then pcall(function() c:Destroy() end) end
end

-- ---------- helper: ensure postprocess instances (start disabled) ----------
local function ensure(className, name, parent)
	local inst = parent:FindFirstChild(name)
	if inst and inst.ClassName ~= className then
		pcall(function() inst:Destroy() end)
		inst = nil
	end
	if not inst then
		inst = Instance.new(className)
		inst.Name = name
		inst.Parent = parent
	end
	return inst
end

local Bloom = ensure("BloomEffect", "SadsXBons_Bloom", Lighting)
local SunRays = ensure("SunRaysEffect", "SadsXBons_SunRays", Lighting)
local CC = ensure("ColorCorrectionEffect", "SadsXBons_CC", Lighting)
local DOF = ensure("DepthOfFieldEffect", "SadsXBons_DOF", Lighting)
local Atmos = ensure("Atmosphere", "SadsXBons_Atmos", Lighting)
local Blur = ensure("BlurEffect", "SadsXBons_Blur", Lighting)

-- default parameters (safe, disabled)
Bloom.Enabled = false; Bloom.Intensity = 0.35; Bloom.Size = 24; Bloom.Threshold = 0.9
SunRays.Enabled = false; SunRays.Intensity = 0.12; SunRays.Spread = 0.25
CC.Enabled = false; CC.Contrast = 0.06; CC.Saturation = 0.06; CC.Brightness = 0
DOF.Enabled = false; DOF.FocusDistance = 10; DOF.InFocusRadius = 12; DOF.FarIntensity = 0.35; DOF.NearIntensity = 0
Atmos.Enabled = false; Atmos.Density = 0.25; Atmos.Offset = 0; Atmos.Color = Color3.fromRGB(255,220,210)
Blur.Enabled = false; Blur.Size = 0

-- save original lighting props to revert
local originalLighting = {
	TimeOfDay = Lighting.TimeOfDay,
	Brightness = Lighting.Brightness,
	Exposure = Lighting.ExposureCompensation,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	ColorShiftTop = Lighting.ColorShift_Top or Color3.new(0,0,0),
	ColorShiftBottom = Lighting.ColorShift_Bottom or Color3.new(0,0,0),
	GlobalShadows = Lighting.GlobalShadows,
	FogEnd = Lighting.FogEnd,
	SkyBk = (Lighting:FindFirstChildOfClass("Sky") and Lighting:FindFirstChildOfClass("Sky").SkyboxBk) or "",
}

-- workspace lights boosting helpers (store & restore)
local boostedLights = {}
local function boostWorkspaceLights(mult)
	boostedLights = {}
	for _,v in ipairs(Workspace:GetDescendants()) do
		if v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
			pcall(function()
				if boostedLights[v] == nil then boostedLights[v] = v.Brightness end
				v.Brightness = (v.Brightness or 0) * mult
				v.Enabled = true
			end)
		end
	end
end
local function revertWorkspaceLights()
	for v,orig in pairs(boostedLights) do
		pcall(function()
			if v and v.Parent then v.Brightness = orig end
		end)
	end
	boostedLights = {}
end

-- ---------- small notif ----------
local function notif(text)
	local sg = Instance.new("ScreenGui", PlayerGui)
	sg.ResetOnSpawn = false
	local fr = Instance.new("Frame", sg)
	fr.Size = UDim2.new(0, 360, 0, 36)
	fr.Position = UDim2.new(0.5, -180, 0.85, 0)
	fr.AnchorPoint = Vector2.new(0.5,0)
	fr.BackgroundColor3 = Color3.fromRGB(28,28,28)
	fr.BorderSizePixel = 0
	local txt = Instance.new("TextLabel", fr)
	txt.Size = UDim2.new(1,-12,1,0); txt.Position = UDim2.new(0,6,0,0)
	txt.BackgroundTransparency = 1; txt.Font = Enum.Font.Gotham; txt.TextSize = 14
	txt.TextColor3 = Color3.fromRGB(255,140,120); txt.Text = text; txt.TextXAlignment = Enum.TextXAlignment.Left
	spawn(function() wait(1.6); pcall(function() sg:Destroy() end) end)
end

-- ---------- build GUI ----------
local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local function new(class, props)
	local o = Instance.new(class)
	if props then for k,v in pairs(props) do o[k] = v end end
	return o
end

local Main = new("Frame", {
	Parent = gui, Name = "Main",
	Size = UDim2.new(0,560,0,420),
	Position = UDim2.new(0.5,-280,0.5,-210),
	AnchorPoint = Vector2.new(0.5,0.5),
	BackgroundColor3 = Color3.fromRGB(18,18,18),
	BorderSizePixel = 0,
	Active = true,
	Draggable = true
})
new("UICorner",{Parent=Main, CornerRadius=UDim.new(0,10)})

local Header = new("Frame", {Parent=Main, Size=UDim2.new(1,0,0,56), BackgroundColor3=Color3.fromRGB(28,28,28)})
new("UICorner",{Parent=Header, CornerRadius=UDim.new(0,8)})
local Title = new("TextLabel", {Parent=Header, Text="SadsXBons • Visuals & Foto Mode", Font=Enum.Font.PatrickHand, TextSize=20, TextColor3=Color3.fromRGB(255,120,120), BackgroundTransparency=1, Position=UDim2.new(0,12,0,8), Size=UDim2.new(0.6,0,1,0)})

local CloseBtn = new("TextButton", {Parent=Header, Text="X", Size=UDim2.new(0,46,0,36), Position=UDim2.new(1,-56,0,8), BackgroundColor3=Color3.fromRGB(170,60,60), Font=Enum.Font.GothamBold, TextColor3=Color3.new(1,1,1)})
local MinBtn = new("TextButton", {Parent=Header, Text="_", Size=UDim2.new(0,46,0,36), Position=UDim2.new(1,-112,0,8), BackgroundColor3=Color3.fromRGB(80,80,80), Font=Enum.Font.GothamBold, TextColor3=Color3.new(1,1,1)})

local MinBar = new("TextButton", {Parent=gui, Text="SadsXBons Visuals (Click to open)", Font=Enum.Font.PatrickHand, TextSize=16, TextColor3=Color3.fromRGB(255,120,120), BackgroundColor3=Color3.fromRGB(20,20,20), Size=UDim2.new(0,320,0,36), Position=UDim2.new(0.5,-160,0.08,0), Visible=false})
new("UICorner",{Parent=MinBar, CornerRadius=UDim.new(0,8)})

-- columns
local Left = new("Frame", {Parent=Main, Position=UDim2.new(0,12,0,76), Size=UDim2.new(0,260,0,332), BackgroundTransparency=1})
local Right = new("Frame", {Parent=Main, Position=UDim2.new(0,288,0,76), Size=UDim2.new(0,260,0,332), BackgroundTransparency=1})

local function createButton(parent, txt, posY)
	local b = new("TextButton", {Parent=parent, Size=UDim2.new(1,0,0,36), Position=UDim2.new(0,0,0,posY), Text=txt, BackgroundColor3=Color3.fromRGB(46,46,46), Font=Enum.Font.GothamBold, TextSize=14, TextColor3=Color3.fromRGB(240,240,240)})
	new("UICorner",{Parent=b, CornerRadius=UDim.new(0,6)})
	return b
end

-- LEFT: presets + toggles + freecam mode
new("TextLabel",{Parent=Left, Text="Presets", Position=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,0,22), BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=16, TextColor3=Color3.fromRGB(255,150,120)})
local morningBtn = createButton(Left, "🌅 Morning", 28)
local sunsetBtn  = createButton(Left, "🌇 Sunset (Senja)", 28+44)
local nightBtn   = createButton(Left, "🌙 Night (Lamp boost)", 28+44*2)
local resetBtn   = createButton(Left, "⟲ Reset Visuals", 28+44*3)

new("TextLabel",{Parent=Left, Text="Effects", Position=UDim2.new(0,0,0,208), Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=14, TextColor3=Color3.fromRGB(255,150,120)})
local bloomToggle = createButton(Left, "Bloom: OFF", 236)
local sunToggle   = createButton(Left, "SunRays: OFF", 236+40)
local ccToggle    = createButton(Left, "ColorGrade: OFF", 236+80)
local dofToggle   = createButton(Left, "DOF: OFF", 236+120)

local fotoBtn = createButton(Left, "📷 Mode Foto (Freecam): OFF", 236+160)

-- RIGHT: sliders + sky + info
new("TextLabel",{Parent=Right, Text="Adjustments", Position=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,0,22), BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=16, TextColor3=Color3.fromRGB(255,150,120)})

local function makeSlider(parent, y, labelText, min, max, default)
	local lab = new("TextLabel", {Parent=parent, Text=labelText, Position=UDim2.new(0,0,0,y), Size=UDim2.new(1,0,0,18), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=13, TextColor3=Color3.fromRGB(220,220,220)})
	local bar = new("Frame", {Parent=parent, Position=UDim2.new(0,0,0,y+18), Size=UDim2.new(1,0,0,16), BackgroundColor3=Color3.fromRGB(48,48,48)})
	new("UICorner",{Parent=bar, CornerRadius=UDim.new(0,6)})
	local rel = (default - min) / (max - min)
	if rel ~= rel then rel = 0 end
	local fill = new("Frame", {Parent=bar, Size=UDim2.new(rel,0,1,0), BackgroundColor3=Color3.fromRGB(255,120,120)})
	new("UICorner",{Parent=fill, CornerRadius=UDim.new(0,6)})
	local val = new("TextLabel", {Parent=parent, Text=tostring(default), Position=UDim2.new(0,0,0,y+36), Size=UDim2.new(1,0,0,16), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=12, TextColor3=Color3.fromRGB(200,200,200)})
	local dragging = false
	bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
	bar.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
	bar.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
			fill.Size = UDim2.new(rel,0,1,0)
			local v = min + (max-min) * rel
			val.Text = string.format("%.2f", v)
		end
	end)
	return {set = function(v) local r=(v-min)/(max-min); fill.Size=UDim2.new(math.clamp(r,0,1),0,1,0); val.Text=string.format("%.2f",v) end,
		 get = function() return tonumber(val.Text) end,
		 valueLabel = val}
end

local bloomSlider = makeSlider(Right, 28, "Bloom Intensity", 0, 2, Bloom.Intensity)
local dofRadiusSlider = makeSlider(Right, 100, "DOF InFocus Radius (bigger = more background sharp)", 1, 500, DOF.InFocusRadius)
local dofFocusOffset = makeSlider(Right, 172, "DOF Focus Offset (camera->char offset)", -200, 200, 0)
local exposureSlider = makeSlider(Right, 244, "ExposureCompensation", -1, 2, Lighting.ExposureCompensation or 0)

new("TextLabel",{Parent=Right, Text="Sky asset (rbxassetid://...)", Position=UDim2.new(0,0,0,316), Size=UDim2.new(1,0,0,18), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=12, TextColor3=Color3.fromRGB(200,200,200)})
local skyInput = new("TextBox", {Parent=Right, Text = originalLighting.SkyBk or "", Position=UDim2.new(0,0,0,334), Size=UDim2.new(1,0,0,24), BackgroundColor3=Color3.fromRGB(38,38,38), TextColor3=Color3.fromRGB(230,230,230), Font=Enum.Font.Gotham, TextSize=12})
local applySkyBtn = createButton(Right, "Apply Sky", 364)

-- minimize/close behavior
CloseBtn.MouseButton1Click:Connect(function() pcall(function() gui:Destroy() end) end)
MinBtn.MouseButton1Click:Connect(function() Main.Visible = false; MinBar.Visible = true end)
MinBar.MouseButton1Click:Connect(function() Main.Visible = true; MinBar.Visible = false end)

-- make Main draggable by header (custom) to be reliable
do
	local dragging = false
	local dragStart = nil
	local startPos = nil
	Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = Main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	Header.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- ---------- preset functions ----------
local function setCommonBalanced()
	Lighting.GlobalShadows = true
	Lighting.Brightness = math.max(0.8, originalLighting.Brightness or 1)
	Lighting.ExposureCompensation = originalLighting.Exposure or 0
	Atmos.Density = 0.25; Atmos.Offset = 0
end

local function applyMorning()
	setCommonBalanced()
	Lighting.TimeOfDay = "07:30:00"
	Lighting.Brightness = 2.2
	Lighting.OutdoorAmbient = Color3.fromRGB(200,200,220)
	Lighting.Ambient = Color3.fromRGB(120,120,120)
	Lighting.ColorShift_Top = Color3.fromRGB(200,210,255)
	Lighting.ColorShift_Bottom = Color3.fromRGB(255,245,230)
	Bloom.Enabled = true; Bloom.Intensity = 0.28; Bloom.Size = 20; Bloom.Threshold = 0.9
	SunRays.Enabled = true; SunRays.Intensity = 0.12; SunRays.Spread = 0.22
	CC.Enabled = true; CC.Contrast = 0.03; CC.Saturation = 0.06; CC.Brightness = 0.01
	DOF.Enabled = true; DOF.InFocusRadius = dofRadiusSlider.get()
	Blur.Enabled = false
	notif("Applied Morning")
end

local function applySunset()
	setCommonBalanced()
	Lighting.TimeOfDay = "18:15:00"
	Lighting.Brightness = 1.6
	Lighting.OutdoorAmbient = Color3.fromRGB(220,160,130)
	Lighting.Ambient = Color3.fromRGB(90,70,60)
	Lighting.ColorShift_Top = Color3.fromRGB(240,180,140)
	Lighting.ColorShift_Bottom = Color3.fromRGB(255,120,60)
	Atmos.Density = 0.45; Atmos.Color = Color3.fromRGB(255,160,110); Atmos.Offset = 0.02
	Bloom.Enabled = true; Bloom.Intensity = math.clamp(bloomSlider.get() or 0.6, 0.2, 1.8); Bloom.Size = 30; Bloom.Threshold = 0.78
	SunRays.Enabled = true; SunRays.Intensity = 0.28; SunRays.Spread = 0.38
	CC.Enabled = true; CC.Contrast = 0.12; CC.Saturation = 0.18; CC.Brightness = -0.01
	DOF.Enabled = true; DOF.InFocusRadius = dofRadiusSlider.get()
	Blur.Enabled = false
	notif("Applied Sunset (Senja)")
end

local function applyNight()
	setCommonBalanced()
	Lighting.TimeOfDay = "22:50:00"
	Lighting.Brightness = 0.9
	Lighting.OutdoorAmbient = Color3.fromRGB(30,40,60)
	Lighting.Ambient = Color3.fromRGB(20,22,28)
	Lighting.ColorShift_Top = Color3.fromRGB(10,10,30)
	Lighting.ColorShift_Bottom = Color3.fromRGB(40,45,70)
	Atmos.Density = 0.6; Atmos.Color = Color3.fromRGB(70,90,140)
	Bloom.Enabled = true; Bloom.Intensity = 0.22; Bloom.Size = 18; Bloom.Threshold = 0.92
	SunRays.Enabled = false
	CC.Enabled = true; CC.Contrast = 0.14; CC.Saturation = -0.05; CC.Brightness = -0.06
	DOF.Enabled = true; DOF.InFocusRadius = dofRadiusSlider.get()
	Blur.Enabled = false
	Lighting.ExposureCompensation = 0.12
	pcall(function() boostWorkspaceLights(1.9) end)
	notif("Applied Night (lamp boost attempted)")
end

local function resetVisuals()
	Lighting.TimeOfDay = originalLighting.TimeOfDay or "12:00:00"
	Lighting.Brightness = originalLighting.Brightness or 1
	Lighting.ExposureCompensation = originalLighting.Exposure or 0
	Lighting.Ambient = originalLighting.Ambient or Color3.fromRGB(127,127,127)
	Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient or Color3.fromRGB(127,127,127)
	Lighting.ColorShift_Top = originalLighting.ColorShiftTop or Color3.new(0,0,0)
	Lighting.ColorShift_Bottom = originalLighting.ColorShiftBottom or Color3.new(0,0,0)
	Lighting.GlobalShadows = originalLighting.GlobalShadows
	Bloom.Enabled = false; SunRays.Enabled = false; CC.Enabled = false; DOF.Enabled = false; Blur.Enabled = false
	Atmos.Density = 0.25; Atmos.Offset = 0; Atmos.Color = Color3.fromRGB(255,220,210)
	pcall(revertWorkspaceLights)
	notif("Visuals reset")
end

-- bind preset buttons
morningBtn.MouseButton1Click:Connect(applyMorning)
sunsetBtn.MouseButton1Click:Connect(applySunset)
nightBtn.MouseButton1Click:Connect(applyNight)
resetBtn.MouseButton1Click:Connect(resetVisuals)

-- toggles UI helper
local function toggleUI(btn, flag, label)
	if flag then
		btn.Text = label .. ": ON"
		btn.BackgroundColor3 = Color3.fromRGB(200,100,100)
	else
		btn.Text = label .. ": OFF"
		btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
	end
end

-- toggles logic
local bloomOn=false; local sunOn=false; local ccOn=false; local dofOn=false
bloomToggle.MouseButton1Click:Connect(function() bloomOn = not bloomOn; Bloom.Enabled=bloomOn; toggleUI(bloomToggle,bloomOn,"Bloom") end)
sunToggle.MouseButton1Click:Connect(function() sunOn = not sunOn; SunRays.Enabled=sunOn; toggleUI(sunToggle,sunOn,"SunRays") end)
ccToggle.MouseButton1Click:Connect(function() ccOn = not ccOn; CC.Enabled=ccOn; toggleUI(ccToggle,ccOn,"ColorGrade") end)
dofToggle.MouseButton1Click:Connect(function() dofOn = not dofOn; DOF.Enabled=dofOn; toggleUI(dofToggle,dofOn,"DOF") end)

-- apply sky
applySkyBtn.MouseButton1Click:Connect(function()
	local s = skyInput.Text or ""
	if s == "" then notif("Masukkan rbxassetid://...") return end
	local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
	pcall(function()
		sky.SkyboxBk = s; sky.SkyboxFt = s; sky.SkyboxUp = s; sky.SkyboxDn = s; sky.SkyboxLf = s; sky.SkyboxRt = s
	end)
	notif("Sky applied (client-side)")
end)

-- ---------- Freecam (Mode Foto) ----------
local freecamActive = false
local savedCamera = {}
local savedHumanoid = {}
local savedCharacterMotion = {}
local freecamSpeed = 120         -- studs / second
local freecamSlowMult = 0.35
local freecamYaw = 0
local freecamPitch = 0
local rightMouseDown = false

local function enableFreecam()
	if freecamActive then return end
	local char = LocalPlayer.Character
	if not char then notif("Character not found"); return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then notif("Missing HRP"); return end

	-- save camera & character state
	savedCamera.CFrame = Camera.CFrame
	savedCamera.CameraType = Camera.CameraType
	-- freeze character: keep humanoid, store WalkSpeed & JumpPower & PlatformStand
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		savedHumanoid.WalkSpeed = humanoid.WalkSpeed
		savedHumanoid.JumpPower = humanoid.JumpPower
		savedHumanoid.PlatformStand = humanoid.PlatformStand
		-- make character stand still
		pcall(function()
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.PlatformStand = true
		end)
	end

	-- set scriptable camera
	Camera.CameraType = Enum.CameraType.Scriptable
	freecamActive = true
	fotoBtn.Text = "📷 Mode Foto (Freecam): ON"
	fotoBtn.BackgroundColor3 = Color3.fromRGB(120,180,120)
	notif("Freecam ON — character frozen locally. Use WASD to move camera, hold RMB to look, hold Ctrl to slow.")
end

local function disableFreecam()
	if not freecamActive then return end
	-- restore humanoid
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid and savedHumanoid then
		pcall(function()
			humanoid.WalkSpeed = savedHumanoid.WalkSpeed or 16
			humanoid.JumpPower = savedHumanoid.JumpPower or 50
			humanoid.PlatformStand = savedHumanoid.PlatformStand or false
		end)
	end
	-- restore camera
	pcall(function()
		if savedCamera.CameraType then Camera.CameraType = savedCamera.CameraType end
		if savedCamera.CFrame then Camera.CFrame = savedCamera.CFrame end
	end)
	freecamActive = false
	fotoBtn.Text = "📷 Mode Foto (Freecam): OFF"
	fotoBtn.BackgroundColor3 = Color3.fromRGB(46,46,46)
	notif("Freecam OFF — character restored")
end

-- toggle on button
fotoBtn.MouseButton1Click:Connect(function()
	if freecamActive then disableFreecam() else enableFreecam() end
end)

-- Freecam controls:
-- WASD: move along camera look vectors, Space/Q for up/down
-- RMB hold: mouse look (track delta)
-- Ctrl: slow multiplier
local cameraVelocity = Vector3.new(0,0,0)
local lastMousePos = Vector2.new(0,0)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightMouseDown = true
		-- capture mouse start
		lastMousePos = UserInputService:GetMouseLocation()
	end
end)
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightMouseDown = false
	end
end)

-- Mouse movement for look when RMB held
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and rightMouseDown and freecamActive then
		local current = UserInputService:GetMouseLocation()
		local delta = current - lastMousePos
		lastMousePos = current
		-- sensitivity
		local sens = 0.18
		freecamYaw = freecamYaw - delta.X * sens
		freecamPitch = math.clamp(freecamPitch - delta.Y * sens, -89, 89)
	end
end)

-- movement per heartbeat
RunService:BindToRenderStep("SadsXBons_Freecam", Enum.RenderPriority.Camera.Value, function(dt)
	-- live apply DOF focus to keep character sharp if DOF enabled and not freecam OR even while freecam (user asked char remain sharp)
	if DOF.Enabled then
		pcall(function()
			local char = LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and Camera then
				local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
				local offset = tonumber(dofFocusOffset.get() or 0) or 0
				DOF.FocusDistance = math.clamp(dist + offset, 1, 5000)
				-- Keep InFocusRadius from slider
				DOF.InFocusRadius = math.clamp(dofRadiusSlider.get() or DOF.InFocusRadius, 1, 500)
			end
		end)
	end

	if freecamActive then
		-- mouse-look applied to camera orientation
		local cf = Camera.CFrame
		local rot = CFrame.Angles(math.rad(freecamPitch), math.rad(freecamYaw), 0)
		-- keep camera position, apply rotation
		local pos = cf.Position
		Camera.CFrame = CFrame.new(pos) * rot

		-- movement vector
		local moveDir = Vector3.new(0,0,0)
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + (Camera.CFrame.LookVector) end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - (Camera.CFrame.LookVector) end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - (Camera.CFrame.RightVector) end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + (Camera.CFrame.RightVector) end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
			moveDir = moveDir * freecamSlowMult
		end
		-- normalize & apply speed
		if moveDir.Magnitude > 0 then
			moveDir = moveDir.Unit
		end
		local speed = freecamSpeed
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then speed = speed * freecamSlowMult end
		local displacement = moveDir * speed * dt
		Camera.CFrame = Camera.CFrame + displacement
	end
end)

-- ---------- heartbeat: apply live slider params (only when enabled) ----------
RunService.Heartbeat:Connect(function()
	-- bloom intensity only if Bloom enabled
	if Bloom.Enabled then
		local b = bloomSlider.get() or Bloom.Intensity
		Bloom.Intensity = math.clamp(b, 0, 5)
	end
	-- Exposure apply always (safe)
	Lighting.ExposureCompensation = exposureSlider.get() or Lighting.ExposureCompensation
end)

-- ---------- UI events for free controls ----------
bloomSlider.set(Bloom.Intensity)
dofRadiusSlider.set(DOF.InFocusRadius)
dofFocusOffset.set(0)
exposureSlider.set(Lighting.ExposureCompensation or 0)

-- fotoBtn already toggles via click
-- Change text color initial
fotoBtn.BackgroundColor3 = Color3.fromRGB(46,46,46)

-- Clean up when GUI destroyed
gui.Destroying:Connect(function()
	-- if freecam active restore
	disableFreecam()
	pcall(revertWorkspaceLights)
end)

-- initial notice
notif("SadsXBons ready — GUI loaded. Efek dimulai OFF. Pilih preset atau aktifkan secara manual.")

-- End of script
