-- BonsHD Graphics + CamHunt (Fixed & stable)
-- Fitur utama:
--  • GUI muncul pasti, draggable header, minimize -> icon, close
--  • Presets: Pagi / Senja / Malam (lampu dicoba dinyalakan di malam)
--  • Bloom & DOF (default OFF). Slider DOF & Bloom realtime.
--  • CamHunt / Mode Foto: freeze char, WASD move camera, hold RMB to look, hold Ctrl to slow
--  • Cleanup aman

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

-- remove old GUI
local GUI_NAME = "BonsHDGraphicsGUI_v1"
for _,v in ipairs(PlayerGui:GetChildren()) do
	if v.Name == GUI_NAME then
		pcall(function() v:Destroy() end)
	end
end

-- helpers
local function ensure(className, name, parent)
	local ex = parent:FindFirstChild(name)
	if ex and ex.ClassName ~= className then pcall(function() ex:Destroy() end); ex = nil end
	if not ex then
		ex = Instance.new(className)
		ex.Name = name
		ex.Parent = parent
	end
	return ex
end
local function clamp(x,a,b) if x < a then return a elseif x > b then return b else return x end end

-- postprocess (named, client-side)
local Bloom = ensure("BloomEffect", "Bons_Bloom", Lighting)
local DOF = ensure("DepthOfFieldEffect", "Bons_DOF", Lighting)
Bloom.Enabled = false; Bloom.Intensity = 0.35; Bloom.Size = 24; Bloom.Threshold = 0.9
DOF.Enabled = false; DOF.InFocusRadius = 12; DOF.FocusDistance = 10; DOF.FarIntensity = 0.35

-- save originals
local originalLighting = {
	TimeOfDay = Lighting.TimeOfDay,
	Brightness = Lighting.Brightness,
	Exposure = Lighting.ExposureCompensation,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	ColorShiftTop = Lighting.ColorShift_Top,
	ColorShiftBottom = Lighting.ColorShift_Bottom,
	GlobalShadows = Lighting.GlobalShadows,
}

-- lamp brightness store
local savedLights = {}
local function boostLampLights(mult)
	savedLights = {}
	for _,inst in ipairs(Workspace:GetDescendants()) do
		if inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") then
			pcall(function()
				if savedLights[inst] == nil then savedLights[inst] = {Brightness = inst.Brightness, Enabled = inst.Enabled} end
				inst.Enabled = true
				inst.Brightness = (inst.Brightness or 0.1) * mult
			end)
		end
	end
end
local function restoreLampLights()
	for inst,data in pairs(savedLights) do
		pcall(function()
			if inst and inst.Parent then
				inst.Brightness = data.Brightness
				inst.Enabled = data.Enabled
			end
		end)
	end
	savedLights = {}
end

-- notif helper
local function notif(text)
	local s = Instance.new("ScreenGui", PlayerGui)
	s.ResetOnSpawn = false
	local f = Instance.new("Frame", s)
	f.Size = UDim2.new(0,360,0,36); f.Position = UDim2.new(0.5,-180,0.85,0); f.BackgroundColor3 = Color3.fromRGB(28,28,28); f.BorderSizePixel = 0
	local l = Instance.new("TextLabel", f)
	l.Size = UDim2.new(1,-12,1,0); l.Position = UDim2.new(0,6,0,0); l.Text = text; l.TextXAlignment = Enum.TextXAlignment.Left
	l.BackgroundTransparency = 1; l.Font = Enum.Font.Gotham; l.TextColor3 = Color3.fromRGB(255,140,120); l.TextSize = 14
	spawn(function() wait(1.6); pcall(function() s:Destroy() end) end)
end

-- build GUI
local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.Parent = PlayerGui
gui.IgnoreGuiInset = true

local function new(class, props)
	local o = Instance.new(class)
	if props then for k,v in pairs(props) do o[k] = v end end
	return o
end

local Main = new("Frame", {
	Parent = gui, Name = "Main",
	Size = UDim2.new(0,360,0,300),
	Position = UDim2.new(0.4,0,0.25,0),
	BackgroundColor3 = Color3.fromRGB(30,30,30),
	BorderSizePixel = 0,
})
new("UICorner",{Parent=Main, CornerRadius=UDim.new(0,8)})

local Header = new("Frame", {Parent=Main, Size=UDim2.new(1,0,0,40), BackgroundColor3 = Color3.fromRGB(44,44,44)})
new("UICorner",{Parent=Header, CornerRadius=UDim.new(0,8)})
local Title = new("TextLabel", {Parent=Header, Text="Bons HD Graphics", Font=Enum.Font.GothamBold, TextSize=16, TextColor3=Color3.fromRGB(255,160,120), BackgroundTransparency=1, Position=UDim2.new(0,10,0,6)})
local CloseBtn = new("TextButton", {Parent=Header, Text="X", Size=UDim2.new(0,36,0,28), Position=UDim2.new(1,-44,0,6), BackgroundColor3=Color3.fromRGB(170,60,60), Font=Enum.Font.GothamBold, TextColor3=Color3.new(1,1,1)})
new("UICorner",{Parent=CloseBtn, CornerRadius=UDim.new(0,6)})
local MinBtn = new("TextButton", {Parent=Header, Text="_", Size=UDim2.new(0,36,0,28), Position=UDim2.new(1,-88,0,6), BackgroundColor3=Color3.fromRGB(80,80,80), Font=Enum.Font.GothamBold, TextColor3=Color3.new(1,1,1)})
new("UICorner",{Parent=MinBtn, CornerRadius=UDim.new(0,6)})

local MinIcon = new("TextButton", {Parent=gui, Text="🌅 BonsHD", Size=UDim2.new(0,110,0,36), Position=UDim2.new(0,8,0,8), Visible=false, BackgroundColor3=Color3.fromRGB(24,24,24), Font=Enum.Font.GothamBold, TextColor3=Color3.fromRGB(255,140,120)})
new("UICorner",{Parent=MinIcon, CornerRadius=UDim.new(0,8)})

-- Left & Right
local Left = new("Frame", {Parent=Main, Position=UDim2.new(0,10,0,48), Size=UDim2.new(0,170,0,240), BackgroundTransparency=1})
local Right = new("Frame", {Parent=Main, Position=UDim2.new(0,190,0,48), Size=UDim2.new(0,160,0,240), BackgroundTransparency=1})

local function createBtn(parent, text, y)
	local b = new("TextButton", {Parent=parent, Text=text, Size=UDim2.new(1,0,0,34), Position=UDim2.new(0,0,0,y), BackgroundColor3=Color3.fromRGB(50,50,50), Font=Enum.Font.GothamBold, TextColor3=Color3.fromRGB(240,240,240)})
	new("UICorner",{Parent=b, CornerRadius=UDim.new(0,6)})
	return b
end

-- presets
local morningBtn = createBtn(Left, "🌅 Pagi (smooth)", 0)
local sunsetBtn = createBtn(Left, "🌇 Senja (smooth)", 46)
local nightBtn = createBtn(Left, "🌙 Malam (lamp boost)", 92)
local resetBtn = createBtn(Left, "⟲ Reset", 138)

-- Freecam controls
local fotoBtn = createBtn(Left, "📷 Mode Foto (Freecam): OFF", 184)
local fotoHint = new("TextLabel", {Parent=Left, Text="WASD • Hold RMB to look • Hold Ctrl to slow", Position=UDim2.new(0,0,0,224), Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=12, TextColor3=Color3.fromRGB(200,200,200)})

-- Right: DOF & Bloom sliders
local labelDOF = new("TextLabel", {Parent=Right, Text="DOF InFocusRadius", Position=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,0,18), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=13, TextColor3=Color3.fromRGB(220,220,220)})
local sliderBar = new("Frame", {Parent=Right, Position=UDim2.new(0,0,0,20), Size=UDim2.new(1,0,0,16), BackgroundColor3=Color3.fromRGB(50,50,50)})
new("UICorner",{Parent=sliderBar, CornerRadius=UDim.new(0,6)})
local sliderFill = new("Frame", {Parent=sliderBar, Size=UDim2.new(0.06,0,1,0), BackgroundColor3=Color3.fromRGB(255,120,120)})
new("UICorner",{Parent=sliderFill, CornerRadius=UDim.new(0,6)})
local sliderValLabel = new("TextLabel", {Parent=Right, Text=tostring(DOF.InFocusRadius), Position=UDim2.new(0,0,0,40), Size=UDim2.new(1,0,0,18), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=12, TextColor3=Color3.fromRGB(200,200,200), TextXAlignment=Enum.TextXAlignment.Center})

local bloomToggle = new("TextButton", {Parent=Right, Text="Bloom: OFF", Position=UDim2.new(0,0,0,70), Size=UDim2.new(1,0,0,34), BackgroundColor3=Color3.fromRGB(50,50,50), Font=Enum.Font.GothamBold, TextColor3=Color3.fromRGB(240,240,240)})
new("UICorner",{Parent=bloomToggle, CornerRadius=UDim.new(0,6)})
local bloomBar = new("Frame", {Parent=Right, Position=UDim2.new(0,0,0,110), Size=UDim2.new(1,0,0,14), BackgroundColor3=Color3.fromRGB(50,50,50)})
new("UICorner",{Parent=bloomBar, CornerRadius=UDim.new(0,6)})
local bloomFill = new("Frame", {Parent=bloomBar, Size=UDim2.new(Bloom.Intensity/2,0,1,0), BackgroundColor3=Color3.fromRGB(255,120,120)})
new("UICorner",{Parent=bloomFill, CornerRadius=UDim.new(0,6)})
local bloomVal = new("TextLabel", {Parent=Right, Text=string.format("%.2f",Bloom.Intensity), Position=UDim2.new(0,0,0,128), Size=UDim2.new(1,0,0,18), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=12, TextColor3=Color3.fromRGB(200,200,200), TextXAlignment=Enum.TextXAlignment.Center})

-- simple bar controller implementation (no nested Connect spam)
local function attachBar(bar, fill, minV, maxV, onChange)
	local dragging = false
	local function updateFromPosition(x)
		local rel = clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		fill.Size = UDim2.new(rel,0,1,0)
		local val = minV + (maxV-minV) * rel
		if onChange then pcall(onChange, val) end
	end
	-- mouse down
	bar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateFromPosition(UserInputService:GetMouseLocation().X)
		end
	end)
	-- mouse up
	bar.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	-- global mouse move when dragging
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			updateFromPosition(inp.Position.X)
		end
	end)
end

attachBar(sliderBar, sliderFill, 1, 500, function(v)
	DOF.InFocusRadius = math.floor(v + 0.5)
	sliderValLabel.Text = tostring(math.floor(v + 0.5))
end)
attachBar(bloomBar, bloomFill, 0, 2, function(v)
	Bloom.Intensity = v
	bloomVal.Text = string.format("%.2f", v)
end)

-- bloom toggle
local bloomOn = false
bloomToggle.MouseButton1Click:Connect(function()
	bloomOn = not bloomOn
	Bloom.Enabled = bloomOn
	bloomToggle.Text = bloomOn and "Bloom: ON" or "Bloom: OFF"
	bloomToggle.BackgroundColor3 = bloomOn and Color3.fromRGB(180,100,100) or Color3.fromRGB(50,50,50)
end)

-- presets (simple, reliable)
local function tweenColor3(inst, prop, toColor, time)
	time = time or 0.9
	local start = inst[prop]
	local elapsed = 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		elapsed = elapsed + dt
		local t = clamp(elapsed / time, 0, 1)
		pcall(function() inst[prop] = start:Lerp(toColor, t) end)
		if t >= 1 then conn:Disconnect() end
	end)
end
local function tweenNumber(inst, prop, toVal, time)
	time = time or 0.9
	local start = inst[prop]
	local elapsed = 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		elapsed = elapsed + dt
		local t = clamp(elapsed / time, 0, 1)
		pcall(function() inst[prop] = start + (toVal - start) * t end)
		if t >= 1 then conn:Disconnect() end
	end)
end

local function applyMorning()
	tweenColor3(Lighting, "ColorShift_Top", Color3.fromRGB(200,210,255), 1.0)
	tweenColor3(Lighting, "ColorShift_Bottom", Color3.fromRGB(255,245,230), 1.0)
	tweenNumber(Lighting, "Brightness", 2.2, 1.0)
	Lighting.TimeOfDay = "07:30:00"
	Bloom.Enabled = true
	DOF.Enabled = true
	notif("Preset Pagi diterapkan")
end

local function applySunset()
	tweenColor3(Lighting, "ColorShift_Top", Color3.fromRGB(240,180,140), 1.2)
	tweenColor3(Lighting, "ColorShift_Bottom", Color3.fromRGB(255,120,60), 1.2)
	tweenNumber(Lighting, "Brightness", 1.6, 1.2)
	Lighting.TimeOfDay = "18:15:00"
	Bloom.Enabled = true
	DOF.Enabled = true
	notif("Preset Senja diterapkan")
end

local function applyNight()
	tweenColor3(Lighting, "ColorShift_Top", Color3.fromRGB(10,10,30), 1.0)
	tweenColor3(Lighting, "ColorShift_Bottom", Color3.fromRGB(40,45,70), 1.0)
	tweenNumber(Lighting, "Brightness", 0.9, 1.0)
	Lighting.TimeOfDay = "22:50:00"
	Bloom.Enabled = true
	DOF.Enabled = true
	pcall(function() boostLampLights(1.8) end)
	notif("Preset Malam diterapkan (lampu dicoba dinyalakan)")
end

local function resetAll()
	Lighting.TimeOfDay = originalLighting.TimeOfDay or "12:00:00"
	Lighting.Brightness = originalLighting.Brightness or 1
	Lighting.ExposureCompensation = originalLighting.Exposure or 0
	Lighting.Ambient = originalLighting.Ambient or Color3.new(0.5,0.5,0.5)
	Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient or Color3.new(0.5,0.5,0.5)
	Lighting.ColorShift_Top = originalLighting.ColorShiftTop
	Lighting.ColorShift_Bottom = originalLighting.ColorShiftBottom
	Bloom.Enabled = false
	DOF.Enabled = false
	restoreLampLights()
	notif("Visuals di-reset")
end

morningBtn.MouseButton1Click:Connect(applyMorning)
sunsetBtn.MouseButton1Click:Connect(applySunset)
nightBtn.MouseButton1Click:Connect(applyNight)
resetBtn.MouseButton1Click:Connect(resetAll)

-- dropdown (simple)
local dropdown = new("Frame", {Parent=Main, Size=UDim2.new(0,140,0,0), Position=UDim2.new(0,12,0,44), BackgroundColor3=Color3.fromRGB(40,40,40), Visible=false})
new("UICorner",{Parent=dropdown, CornerRadius=UDim.new(0,6)})
local optH = 30
local function addOption(txt, y)
	local b = new("TextButton", {Parent=dropdown, Text=txt, Position=UDim2.new(0,0,0,y), Size=UDim2.new(1,0,0,optH), BackgroundColor3=Color3.fromRGB(48,48,48), Font=Enum.Font.Gotham, TextColor3=Color3.fromRGB(230,230,230)})
	new("UICorner",{Parent=b, CornerRadius=UDim.new(0,6)})
	return b
end
local opt1 = addOption("Pagi", 0)
local opt2 = addOption("Senja", optH)
local opt3 = addOption("Malam", optH*2)
local timeChoice = new("TextButton", {Parent=Main, Text="Pilih Waktu ▼", Size=UDim2.new(0,140,0,28), Position=UDim2.new(0,12,0,6), BackgroundColor3=Color3.fromRGB(50,50,50), Font=Enum.Font.Gotham, TextColor3=Color3.fromRGB(230,230,230)})
new("UICorner",{Parent=timeChoice, CornerRadius=UDim.new(0,6)})
timeChoice.MouseButton1Click:Connect(function()
	dropdown.Visible = not dropdown.Visible
	if dropdown.Visible then dropdown.Size = UDim2.new(0,140,0,optH*3) else dropdown.Size = UDim2.new(0,120,0,0) end
end)
opt1.MouseButton1Click:Connect(function() dropdown.Visible=false; timeChoice.Text="Pilih Waktu: Pagi"; applyMorning() end)
opt2.MouseButton1Click:Connect(function() dropdown.Visible=false; timeChoice.Text="Pilih Waktu: Senja"; applySunset() end)
opt3.MouseButton1Click:Connect(function() dropdown.Visible=false; timeChoice.Text="Pilih Waktu: Malam"; applyNight() end)

-- Header dragging (reliable)
do
	local dragging = false
	local dragStart, startPos
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

-- minimize/close
MinBtn.MouseButton1Click:Connect(function() Main.Visible = false; MinIcon.Visible = true end)
MinIcon.MouseButton1Click:Connect(function() Main.Visible = true; MinIcon.Visible = false end)
CloseBtn.MouseButton1Click:Connect(function() pcall(function() gui:Destroy() end) end)

-- ===== CamHunt / Freecam =====
local freecam = {
	active = false,
	saved = {},
	speed = 120,
	slowMult = 0.35,
	yaw = 0,
	pitch = 0,
	rightDown = false,
	lastMouse = UserInputService:GetMouseLocation(),
}

local function attachHighlight()
	-- create highlight to PlayerGui for visibility (optional)
	local char = LocalPlayer.Character
	if not char then return end
	if not char:FindFirstChild("Bons_Highlight") then
		local h = Instance.new("Highlight")
		h.Name = "Bons_Highlight"
		h.Adornee = char
		h.Parent = PlayerGui
		h.FillTransparency = 0.6
		h.OutlineColor = Color3.fromRGB(255,200,120)
	end
end
local function removeHighlight()
	local h = PlayerGui:FindFirstChild("Bons_Highlight")
	if h then pcall(function() h:Destroy() end) end
end

local function enableFreecam()
	if freecam.active then return end
	local char = LocalPlayer.Character
	if not char then notif("Character not found"); return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then notif("Humanoid not found"); return end
	-- save
	freecam.saved.CameraType = Camera.CameraType
	freecam.saved.CameraCFrame = Camera.CFrame
	freecam.saved.walkspeed = humanoid.WalkSpeed
	freecam.saved.jump = humanoid.JumpPower
	freecam.saved.platform = humanoid.PlatformStand
	-- freeze locally
	pcall(function() humanoid.WalkSpeed = 0; humanoid.JumpPower = 0; humanoid.PlatformStand = true end)
	-- highlight
	attachHighlight()
	-- scriptable camera
	Camera.CameraType = Enum.CameraType.Scriptable
	freecam.active = true
	fotoBtn.Text = "📷 Mode Foto (Freecam): ON"
	fotoBtn.BackgroundColor3 = Color3.fromRGB(120,180,120)
	notif("Freecam ON — WASD to move, hold RMB to look, hold Ctrl to slow")
end

local function disableFreecam()
	if not freecam.active then return end
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid and freecam.saved then
		pcall(function()
			humanoid.WalkSpeed = freecam.saved.walkspeed or 16
			humanoid.JumpPower = freecam.saved.jump or 50
			humanoid.PlatformStand = freecam.saved.platform or false
		end)
	end
	pcall(function()
		if freecam.saved.CameraType then Camera.CameraType = freecam.saved.CameraType end
		if freecam.saved.CameraCFrame then Camera.CFrame = freecam.saved.CameraCFrame end
	end)
	freecam.active = false
	fotoBtn.Text = "📷 Mode Foto (Freecam): OFF"
	fotoBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
	removeHighlight()
	notif("Freecam OFF — character restored")
end

fotoBtn.MouseButton1Click:Connect(function()
	if freecam.active then disableFreecam() else enableFreecam() end
end)

-- RMB look handling
UserInputService.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.UserInputType == Enum.UserInputType.MouseButton2 then
		freecam.rightDown = true
		freecam.lastMouse = UserInputService:GetMouseLocation()
	end
end)
UserInputService.InputEnded:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton2 then
		freecam.rightDown = false
	end
end)
UserInputService.InputChanged:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseMovement and freecam.rightDown and freecam.active then
		local cur = UserInputService:GetMouseLocation()
		local delta = cur - freecam.lastMouse
		freecam.lastMouse = cur
		local sens = 0.18
		freecam.yaw = freecam.yaw - delta.X * sens
		freecam.pitch = clamp(freecam.pitch - delta.Y * sens, -89, 89)
	end
end)

-- renderstep for freecam movement and DOF update
RunService:BindToRenderStep("Bons_Freecam", Enum.RenderPriority.Camera.Value, function(dt)
	-- DOF focus update (if enabled)
	if DOF.Enabled then
		pcall(function()
			local char = LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local cam = workspace.CurrentCamera
			if hrp and cam then
				local dist = (cam.CFrame.Position - hrp.Position).Magnitude
				DOF.FocusDistance = clamp(dist, 1, 5000)
			end
		end)
	end

	if freecam.active then
		-- rotation
		local rot = CFrame.Angles(math.rad(freecam.pitch), math.rad(freecam.yaw), 0)
		local pos = Camera.CFrame.Position
		Camera.CFrame = CFrame.new(pos) * rot

		-- movement
		local mv = Vector3.new()
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + Camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - Camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - Camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + Camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
		local slow = (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl))
		local speed = freecam.speed * (slow and freecam.slowMult or 1)
		if mv.Magnitude > 0 then mv = mv.Unit end
		Camera.CFrame = Camera.CFrame + mv * speed * dt
	end
end)

-- heartbeat: apply slider-driven values
RunService.Heartbeat:Connect(function()
	-- Bloom intensity only when enabled
	if Bloom.Enabled then
		Bloom.Intensity = clamp(Bloom.Intensity, 0, 5)
	end
	DOF.InFocusRadius = clamp(tonumber(sliderValLabel.Text) or DOF.InFocusRadius, 1, 500)
end)

-- cleanup on destroy
gui.Destroying:Connect(function()
	restoreLampLights()
	if freecam.active then disableFreecam() end
end)

-- initial UI values & notice
sliderValLabel.Text = tostring(DOF.InFocusRadius)
bloomVal.Text = string.format("%.2f", Bloom.Intensity)
notif("BonsHD ready — GUI muncul. Efek default MATI. Pilih preset atau aktifkan Freecam.")

-- EOF
