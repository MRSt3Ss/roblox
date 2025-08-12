-- SadsXBons Visuals — Final (GUI-fix, client-only)
-- Features:
--  • GUI reliably spawns in PlayerGui (old GUI cleaned)
--  • Presets: Morning / Sunset / Night (balanced, not too dark)
--  • Bloom, SunRays, ColorCorrection, Atmosphere, DepthOfField, Blur
--  • Sliders: Bloom Intensity, DOF InFocusRadius, DOF FocusDistance, Exposure
--  • Toggles: Bloom / SunRays / ColorGrade / DOF
--  • Apply Sky (rbxassetid://...), Reset, Minimize, Close
--  • Night mode locally boosts workspace lights (attempts with pcall)
-- NOTE: All changes are CLIENT-SIDE only.

-- ===== Services & safety =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- remove old GUI if exists (avoid duplicates)
local OLD_NAME = "SadsXBons_Graphics_v2"
for _, c in ipairs(PlayerGui:GetChildren()) do
	if c.Name == OLD_NAME then
		pcall(function() c:Destroy() end)
	end
end

-- ===== Helpers: create/ensure effects =====
local function ensure(className, name, parent)
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName ~= className then
		pcall(function() existing:Destroy() end)
		existing = nil
	end
	if not existing then
		local inst = Instance.new(className)
		inst.Name = name
		inst.Parent = parent
		return inst
	end
	return existing
end

local Bloom = ensure("BloomEffect", "SadsXBons_Bloom", Lighting)
local SunRays = ensure("SunRaysEffect", "SadsXBons_SunRays", Lighting)
local CC = ensure("ColorCorrectionEffect", "SadsXBons_CC", Lighting)
local DOF = ensure("DepthOfFieldEffect", "SadsXBons_DOF", Lighting)
local Atmos = ensure("Atmosphere", "SadsXBons_Atmos", Lighting)
local Blur = ensure("BlurEffect", "SadsXBons_Blur", Lighting)

local Sky = Lighting:FindFirstChildOfClass("Sky")
if not Sky then
	Sky = Instance.new("Sky", Lighting)
	Sky.Name = "SadsXBons_Sky"
end

-- store originals to revert
local original = {
	TimeOfDay = Lighting.TimeOfDay,
	Brightness = Lighting.Brightness,
	Exposure = Lighting.ExposureCompensation,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	ColorShiftTop = Lighting.ColorShift_Top or Color3.new(0,0,0),
	ColorShiftBottom = Lighting.ColorShift_Bottom or Color3.new(0,0,0),
	GlobalShadows = Lighting.GlobalShadows,
	FogEnd = Lighting.FogEnd,
	SkyAsset = (Sky and (Sky.SkyboxBk or "")) or "",
}

-- workspace light boosting helpers (local attempt)
local boostedLights = {}
local function boostWorkspaceLights(mult)
	boostedLights = {}
	for _, v in ipairs(Workspace:GetDescendants()) do
		if v:IsA("PointLight") or v:IsA("SurfaceLight") or v:IsA("SpotLight") then
			pcall(function()
				if not boostedLights[v] then boostedLights[v] = v.Brightness end
				v.Brightness = (v.Brightness or 0) * mult
				v.Enabled = true
			end)
		end
	end
end
local function revertWorkspaceLights()
	for v, orig in pairs(boostedLights) do
		pcall(function()
			if v and v.Parent then v.Brightness = orig end
		end)
	end
	boostedLights = {}
end

-- ===== Default effect parameters (balanced) =====
Bloom.Enabled = false; Bloom.Intensity = 0.35; Bloom.Size = 24; Bloom.Threshold = 0.9
SunRays.Enabled = false; SunRays.Intensity = 0.12; SunRays.Spread = 0.25
CC.Enabled = false; CC.Contrast = 0.06; CC.Saturation = 0.06; CC.Brightness = 0
DOF.Enabled = false; DOF.FocusDistance = 10; DOF.InFocusRadius = 12; DOF.FarIntensity = 0.35
Atmos.Enabled = true; Atmos.Density = 0.25; Atmos.Offset = 0; Atmos.Color = Color3.fromRGB(255,220,210)
Blur.Enabled = false; Blur.Size = 0

-- ===== Small notif helper =====
local function notif(txt)
	local sg = Instance.new("ScreenGui", PlayerGui)
	sg.ResetOnSpawn = false
	sg.Name = "SadsXBons_Notice"
	local f = Instance.new("Frame", sg)
	f.Size = UDim2.new(0,340,0,36); f.Position = UDim2.new(0.5,-170,0.85,0)
	f.AnchorPoint = Vector2.new(0.5,0); f.BackgroundColor3 = Color3.fromRGB(28,28,28); f.BorderSizePixel = 0
	local l = Instance.new("TextLabel", f)
	l.Size = UDim2.new(1,-12,1,0); l.Position = UDim2.new(0,6,0,0); l.BackgroundTransparency = 1
	l.Font = Enum.Font.Gotham; l.TextSize = 14; l.TextColor3 = Color3.fromRGB(255,140,120); l.Text = txt; l.TextXAlignment = Enum.TextXAlignment.Left
	spawn(function() wait(1.6); pcall(function() sg:Destroy() end) end)
end

-- ===== Build GUI in PlayerGui =====
local gui = Instance.new("ScreenGui")
gui.Name = OLD_NAME
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local function mk(cls, props)
	local o = Instance.new(cls)
	for k,v in pairs(props or {}) do o[k] = v end
	return o
end

local Main = mk("Frame", {
	Parent = gui, Name = "Main",
	Size = UDim2.new(0,520,0,420),
	Position = UDim2.new(0.5,-260,0.5,-210),
	AnchorPoint = Vector2.new(0.5,0.5),
	BackgroundColor3 = Color3.fromRGB(18,18,18),
	BorderSizePixel = 0,
	Active = true,
	Draggable = true
})
mk("UICorner",{Parent=Main, CornerRadius=UDim.new(0,10)})

local Header = mk("Frame", {Parent=Main, Size=UDim2.new(1,0,0,56), BackgroundColor3 = Color3.fromRGB(28,28,28)})
mk("UICorner",{Parent=Header, CornerRadius=UDim.new(0,10)})
local Title = mk("TextLabel", {Parent=Header, Text="SadsXBons • Visuals", Font=Enum.Font.PatrickHand, TextSize=20, TextColor3=Color3.fromRGB(255,120,120), BackgroundTransparency=1, Position=UDim2.new(0,12,0,8), Size=UDim2.new(0.6,0,1,0)})

local CloseBtn = mk("TextButton", {Parent=Header, Text="X", Size=UDim2.new(0,44,0,36), Position=UDim2.new(1,-56,0,8), BackgroundColor3=Color3.fromRGB(170,60,60), Font=Enum.Font.GothamBold, TextColor3=Color3.new(1,1,1)})
local MinBtn = mk("TextButton", {Parent=Header, Text="_", Size=UDim2.new(0,44,0,36), Position=UDim2.new(1,-112,0,8), BackgroundColor3=Color3.fromRGB(80,80,80), Font=Enum.Font.GothamBold, TextColor3=Color3.new(1,1,1)})

local MinBar = mk("TextButton", {Parent=gui, Text="SadsXBons Visuals (Click to open)", Font=Enum.Font.PatrickHand, TextSize=16, TextColor3=Color3.fromRGB(255,120,120), BackgroundColor3=Color3.fromRGB(20,20,20), Size=UDim2.new(0,320,0,36), Position=UDim2.new(0.5,-160,0.08,0), Visible=false})
mk("UICorner",{Parent=MinBar, CornerRadius=UDim.new(0,8)})

-- columns
local Left = mk("Frame",{Parent=Main, Position=UDim2.new(0,12,0,76), Size=UDim2.new(0,240,0,328), BackgroundTransparency=1})
local Right = mk("Frame",{Parent=Main, Position=UDim2.new(0,268,0,76), Size=UDim2.new(0,240,0,328), BackgroundTransparency=1})

-- helper create button
local function createButton(parent, text, y)
	local b = mk("TextButton", {Parent=parent, Size=UDim2.new(1,0,0,34), Position=UDim2.new(0,0,0,y), Text=text, BackgroundColor3=Color3.fromRGB(50,50,50), Font=Enum.Font.GothamBold, TextSize=14, TextColor3=Color3.fromRGB(240,240,240)})
	mk("UICorner",{Parent=b, CornerRadius=UDim.new(0,6)})
	return b
end

-- presets
mk("TextLabel",{Parent=Left, Text="Presets", Position=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,0,24), BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=16, TextColor3=Color3.fromRGB(255,150,120)})
local morningBtn = createButton(Left, "🌅 Morning", 28)
local sunsetBtn = createButton(Left, "🌇 Sunset (Senja)", 28+40)
local nightBtn = createButton(Left, "🌙 Night", 28+80)
local resetBtn = createButton(Left, "⟲ Reset Visuals", 28+120)

-- toggles group
mk("TextLabel",{Parent=Left, Text="Effects", Position=UDim2.new(0,0,0,180), Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=14, TextColor3=Color3.fromRGB(255,150,120)})
local bloomToggle = createButton(Left, "Bloom: OFF", 204)
local sunToggle = createButton(Left, "SunRays: OFF", 204+40)
local ccToggle = createButton(Left, "ColorGrade: OFF", 204+80)
local dofToggle = createButton(Left, "DepthOfField: OFF", 204+120)

-- slider builder (returns {valueLabel, set, get})
local function makeSlider(parent, y, labelText, min, max, default)
	local lab = mk("TextLabel",{Parent=parent, Text=labelText, Position=UDim2.new(0,0,0,y), Size=UDim2.new(1,0,0,18), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=13, TextColor3=Color3.fromRGB(220,220,220)})
	local bar = mk("Frame",{Parent=parent, Position=UDim2.new(0,0,0,y+18), Size=UDim2.new(1,0,0,16), BackgroundColor3=Color3.fromRGB(48,48,48)})
	mk("UICorner",{Parent=bar, CornerRadius=UDim.new(0,6)})
	local fill = mk("Frame",{Parent=bar, Size=UDim2.new((default-min)/(max-min),0,1,0), BackgroundColor3=Color3.fromRGB(255,120,120)})
	mk("UICorner",{Parent=fill, CornerRadius=UDim.new(0,6)})
	local val = mk("TextLabel",{Parent=parent, Text=tostring(default), Position=UDim2.new(0,0,0,y+36), Size=UDim2.new(1,0,0,16), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=12, TextColor3=Color3.fromRGB(200,200,200)})
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
	local function set(v)
		v = math.clamp(v, min, max)
		local rel = (v-min)/(max-min)
		fill.Size = UDim2.new(rel,0,1,0)
		val.Text = string.format("%.2f", v)
	end
	local function get() return tonumber(val.Text) end
	return {label=lab, bar=bar, fill=fill, value=val, set=set, get=get}
end

-- right column sliders
local bloomSlider = makeSlider(Right, 28, "Bloom Intensity", 0, 2, Bloom.Intensity)
local dofRadiusSlider = makeSlider(Right, 100, "DOF InFocus Radius", 1, 200, DOF.InFocusRadius)
local dofFocusSlider = makeSlider(Right, 172, "DOF Focus Distance", 1, 2000, DOF.FocusDistance)
local exposureSlider = makeSlider(Right, 244, "ExposureCompensation", -1, 2, Lighting.ExposureCompensation or 0)

-- sky input & apply
mk("TextLabel",{Parent=Right, Text="Sky asset (rbxassetid://...)", Position=UDim2.new(0,0,0,316), Size=UDim2.new(1,0,0,18), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=12, TextColor3=Color3.fromRGB(200,200,200)})
local skyInput = mk("TextBox",{Parent=Right, Text=original.SkyAsset or "", Position=UDim2.new(0,0,0,334), Size=UDim2.new(1,0,0,24), BackgroundColor3=Color3.fromRGB(38,38,38), TextColor3=Color3.fromRGB(230,230,230), Font=Enum.Font.Gotham, TextSize=12})
local applySkyBtn = createButton(Right, "Apply Sky", 364)

-- minimize/close behavior
CloseBtn.MouseButton1Click:Connect(function() pcall(function() gui:Destroy() end) end)
MinBtn.MouseButton1Click:Connect(function() Main.Visible = false; MinBar.Visible = true end)
MinBar.MouseButton1Click:Connect(function() Main.Visible = true; MinBar.Visible = false end)

-- ===== Behavior: Presets & toggles =====
local function setCommonBalanced()
	Lighting.GlobalShadows = true
	Lighting.Brightness = math.max(0.8, original.Brightness or 1)
	Lighting.ExposureCompensation = original.Exposure or 0
	Atmos.Density = 0.25; Atmos.Offset = 0
end

local function applyMorning()
	setCommonBalanced()
	Lighting.TimeOfDay = "07:30:00"; Lighting.Brightness = 2.2
	Lighting.OutdoorAmbient = Color3.fromRGB(200,200,220); Lighting.Ambient = Color3.fromRGB(120,120,120)
	Lighting.ColorShift_Top = Color3.fromRGB(200,210,255); Lighting.ColorShift_Bottom = Color3.fromRGB(255,245,230)
	-- effects
	Bloom.Enabled = true; Bloom.Intensity = 0.28; Bloom.Size = 20; Bloom.Threshold = 0.9
	SunRays.Enabled = true; SunRays.Intensity = 0.12; SunRays.Spread = 0.22
	CC.Enabled = true; CC.Contrast = 0.03; CC.Saturation = 0.06; CC.Brightness = 0.01
	DOF.Enabled = true; DOF.InFocusRadius = dofRadiusSlider.get and tonumber(dofRadiusSlider.get()) or 12; DOF.FocusDistance = dofFocusSlider.get and tonumber(dofFocusSlider.get()) or 10
	Blur.Enabled = false
	notif("Applied Morning")
end

local function applySunset()
	setCommonBalanced()
	Lighting.TimeOfDay = "18:15:00"; Lighting.Brightness = 1.6
	Lighting.OutdoorAmbient = Color3.fromRGB(220,160,130); Lighting.Ambient = Color3.fromRGB(90,70,60)
	Lighting.ColorShift_Top = Color3.fromRGB(240,180,140); Lighting.ColorShift_Bottom = Color3.fromRGB(255,120,60)
	Atmos.Density = 0.45; Atmos.Color = Color3.fromRGB(255,160,110); Atmos.Offset = 0.02
	Bloom.Enabled = true; Bloom.Intensity = math.clamp(bloomSlider.get and tonumber(bloomSlider.get()) or 0.6, 0.2, 1.8); Bloom.Size = 30; Bloom.Threshold = 0.78
	SunRays.Enabled = true; SunRays.Intensity = 0.28; SunRays.Spread = 0.38
	CC.Enabled = true; CC.Contrast = 0.12; CC.Saturation = 0.18; CC.Brightness = -0.01
	DOF.Enabled = true; DOF.InFocusRadius = dofRadiusSlider.get and tonumber(dofRadiusSlider.get()) or 18; DOF.FocusDistance = dofFocusSlider.get and tonumber(dofFocusSlider.get()) or 40
	Blur.Enabled = false
	notif("Applied Sunset (Senja)")
end

local function applyNight()
	setCommonBalanced()
	Lighting.TimeOfDay = "22:50:00"; Lighting.Brightness = 0.9
	Lighting.OutdoorAmbient = Color3.fromRGB(30,40,60); Lighting.Ambient = Color3.fromRGB(20,22,28)
	Lighting.ColorShift_Top = Color3.fromRGB(10,10,30); Lighting.ColorShift_Bottom = Color3.fromRGB(40,45,70)
	Atmos.Density = 0.6; Atmos.Color = Color3.fromRGB(70,90,140)
	Bloom.Enabled = true; Bloom.Intensity = 0.22; Bloom.Size = 18; Bloom.Threshold = 0.92
	SunRays.Enabled = false
	CC.Enabled = true; CC.Contrast = 0.14; CC.Saturation = -0.05; CC.Brightness = -0.06
	DOF.Enabled = true; DOF.InFocusRadius = dofRadiusSlider.get and tonumber(dofRadiusSlider.get()) or 8; DOF.FocusDistance = dofFocusSlider.get and tonumber(dofFocusSlider.get()) or 12
	Blur.Enabled = false
	Lighting.ExposureCompensation = 0.12
	pcall(function() boostWorkspaceLights(1.9) end)
	notif("Applied Night")
end

local function resetVisuals()
	Lighting.TimeOfDay = original.TimeOfDay or "12:00:00"
	Lighting.Brightness = original.Brightness or 1
	Lighting.ExposureCompensation = original.Exposure or 0
	Lighting.Ambient = original.Ambient or Color3.fromRGB(127,127,127)
	Lighting.OutdoorAmbient = original.OutdoorAmbient or Color3.fromRGB(127,127,127)
	Lighting.ColorShift_Top = original.ColorShiftTop or Color3.new(0,0,0)
	Lighting.ColorShift_Bottom = original.ColorShiftBottom or Color3.new(0,0,0)
	Lighting.GlobalShadows = original.GlobalShadows
	-- revert sky if had original
	if Sky and original.SkyAsset and original.SkyAsset ~= "" then
		pcall(function()
			Sky.SkyboxBk = original.SkyAsset
			Sky.SkyboxFt = original.SkyAsset
			Sky.SkyboxUp = original.SkyAsset
			Sky.SkyboxDn = original.SkyAsset
			Sky.SkyboxLf = original.SkyAsset
			Sky.SkyboxRt = original.SkyAsset
		end)
	end
	-- disable effects
	Bloom.Enabled = false; SunRays.Enabled = false; CC.Enabled = false; DOF.Enabled = false; Blur.Enabled = false
	Atmos.Density = 0.25; Atmos.Offset = 0
	pcall(revertWorkspaceLights)
	notif("Visuals reset")
end

-- Bind preset buttons
morningBtn.MouseButton1Click:Connect(applyMorning)
sunsetBtn.MouseButton1Click:Connect(applySunset)
nightBtn.MouseButton1Click:Connect(applyNight)
resetBtn.MouseButton1Click:Connect(resetVisuals)

-- toggle UI helper
local function toggleUI(btn, flag, labelBase)
	if flag then
		btn.Text = labelBase .. ": ON"
		btn.BackgroundColor3 = Color3.fromRGB(200,100,100)
	else
		btn.Text = labelBase .. ": OFF"
		btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
	end
end

-- toggles initial states
local bloomOn=false; sunOn=false; ccOn=false; dofOn=false
bloomToggle.MouseButton1Click:Connect(function() bloomOn = not bloomOn; Bloom.Enabled = bloomOn; toggleUI(bloomToggle,bloomOn,"Bloom") end)
sunToggle.MouseButton1Click:Connect(function() sunOn = not sunOn; SunRays.Enabled = sunOn; toggleUI(sunToggle,sunOn,"SunRays") end)
ccToggle.MouseButton1Click:Connect(function() ccOn = not ccOn; CC.Enabled = ccOn; toggleUI(ccToggle,ccOn,"ColorGrade") end)
dofToggle.MouseButton1Click:Connect(function() dofOn = not dofOn; DOF.Enabled = dofOn; toggleUI(dofToggle,dofOn,"DepthOfField") end)

-- sliders: poll & apply each heartbeat (cheap)
RunService.Heartbeat:Connect(function()
	-- bloom
	local bval = tonumber(bloomSlider.value.Text) or Bloom.Intensity
	Bloom.Intensity = math.clamp(bval, 0, 5)
	-- DOF
	local rad = tonumber(dofRadiusSlider.value.Text) or DOF.InFocusRadius
	local foc = tonumber(dofFocusSlider.value.Text) or DOF.FocusDistance
	DOF.InFocusRadius = math.clamp(rad, 1, 500)
	DOF.FocusDistance = math.clamp(foc, 1, 5000)
	-- exposure
	Lighting.ExposureCompensation = tonumber(exposureSlider.value.Text) or Lighting.ExposureCompensation
	-- keep DOF focused on character HRP so character stays sharp
	pcall(function()
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and workspace.CurrentCamera then
			local dist = (workspace.CurrentCamera.CFrame.Position - hrp.Position).Magnitude
			DOF.FocusDistance = dist
		end
	end)
end)

-- Apply Sky button
applySkyBtn.MouseButton1Click:Connect(function()
	local s = skyInput.Text or ""
	if s == "" then notif("Enter rbxassetid://..."); return end
	pcall(function()
		Sky.SkyboxBk = s; Sky.SkyboxFt = s; Sky.SkyboxUp = s; Sky.SkyboxDn = s; Sky.SkyboxLf = s; Sky.SkyboxRt = s
	end)
	notif("Sky applied (client-side)")
end)

-- cleanup when GUI destroyed
gui.Destroying:Connect(function()
	pcall(revertWorkspaceLights)
end)

notif("SadsXBons Visuals ready — open GUI and choose preset.")
