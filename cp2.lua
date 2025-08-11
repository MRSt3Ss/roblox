-- SadsXBons Ultimate GUI (Solara executor compatible)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local flying = false
local flySpeed = 50
local godMode = false
local walkSpeed = 16
local checkpoints = {}
local teleporting = false

-- Utils
local function createTween(obj, props, time)
	return TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
end

-- Helper to get list of .json files from file manager
local function getConfigFiles()
	local files = {}
	if isfolder then
		-- Try to get all files in root folder if supported
		-- If executor does not support isfolder/listfiles, fallback empty
		-- Solara may support listfiles with listfiles() function?
		if listfiles then
			for _, filepath in pairs(listfiles("")) do
				if filepath:match("%.json$") then
					table.insert(files, filepath)
				end
			end
		end
	end
	return files
end

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SadsXBonsGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 350, 0, 450)
MainFrame.Position = UDim2.new(0.5, -175, 0.3, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(100, 100, 100)
UIStroke.Thickness = 2
UIStroke.Transparency = 0.7

-- Logo Text
local Logo = Instance.new("TextLabel")
Logo.Name = "Logo"
Logo.Text = "SadsXBons"
Logo.Font = Enum.Font.PatrickHand
Logo.TextSize = 32
Logo.TextColor3 = Color3.fromRGB(255, 100, 100)
Logo.BackgroundTransparency = 1
Logo.Size = UDim2.new(1, 0, 0, 50)
Logo.Parent = MainFrame

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 24
CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -45, 0, 5)
CloseBtn.Parent = MainFrame

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Text = "-"
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 32
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MinimizeBtn.Size = UDim2.new(0, 40, 0, 40)
MinimizeBtn.Position = UDim2.new(1, -90, 0, 5)
MinimizeBtn.Parent = MainFrame

-- Minimized Bar (hidden at start)
local MinimizedBar = Instance.new("TextButton")
MinimizedBar.Name = "MinimizedBar"
MinimizedBar.Text = "SadsXBons GUI (Click to Open)"
MinimizedBar.Font = Enum.Font.PatrickHand
MinimizedBar.TextSize = 20
MinimizedBar.TextColor3 = Color3.fromRGB(255, 100, 100)
MinimizedBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MinimizedBar.Size = UDim2.new(0, 200, 0, 40)
MinimizedBar.Position = UDim2.new(0.5, -100, 0.3, -225)
MinimizedBar.AnchorPoint = Vector2.new(0.5, 0.5)
MinimizedBar.Visible = false
MinimizedBar.Parent = ScreenGui

-- Tab Buttons Container
local TabButtons = Instance.new("Frame")
TabButtons.Name = "TabButtons"
TabButtons.Size = UDim2.new(1, 0, 0, 40)
TabButtons.Position = UDim2.new(0, 0, 0, 50)
TabButtons.BackgroundTransparency = 1
TabButtons.Parent = MainFrame

local function createTabButton(text, pos)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 110, 1, 0)
	btn.Position = UDim2.new(0, pos, 0, 0)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 20
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Parent = TabButtons
	return btn
end

local FlyTabBtn = createTabButton("Fly", 10)
local CheckpointTabBtn = createTabButton("Checkpoints", 130)
local SettingsTabBtn = createTabButton("Settings", 250)

-- Tab Content container
local TabContent = Instance.new("Frame")
TabContent.Name = "TabContent"
TabContent.Size = UDim2.new(1, -20, 1, -90)
TabContent.Position = UDim2.new(0, 10, 0, 100)
TabContent.BackgroundTransparency = 1
TabContent.Parent = MainFrame

-- Fly Tab
local FlyTab = Instance.new("Frame")
FlyTab.Name = "FlyTab"
FlyTab.Size = UDim2.new(1, 0, 1, 0)
FlyTab.BackgroundTransparency = 1
FlyTab.Parent = TabContent

local FlyToggle = Instance.new("TextButton")
FlyToggle.Size = UDim2.new(0, 140, 0, 50)
FlyToggle.Position = UDim2.new(0, 10, 0, 10)
FlyToggle.Text = "Fly: OFF"
FlyToggle.Font = Enum.Font.GothamBold
FlyToggle.TextSize = 24
FlyToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
FlyToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyToggle.Parent = FlyTab

local FlySpeedLabel = Instance.new("TextLabel")
FlySpeedLabel.Size = UDim2.new(0, 140, 0, 25)
FlySpeedLabel.Position = UDim2.new(0, 10, 0, 70)
FlySpeedLabel.Text = "Fly Speed: "..flySpeed
FlySpeedLabel.Font = Enum.Font.Gotham
FlySpeedLabel.TextSize = 18
FlySpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FlySpeedLabel.BackgroundTransparency = 1
FlySpeedLabel.Parent = FlyTab

local FlySpeedSlider = Instance.new("TextButton")
FlySpeedSlider.Size = UDim2.new(0, 140, 0, 25)
FlySpeedSlider.Position = UDim2.new(0, 10, 0, 100)
FlySpeedSlider.Text = "Adjust Fly Speed"
FlySpeedSlider.Font = Enum.Font.Gotham
FlySpeedSlider.TextSize = 18
FlySpeedSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
FlySpeedSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
FlySpeedSlider.Parent = FlyTab

local SliderFill = Instance.new("Frame")
SliderFill.Name = "Fill"
SliderFill.Size = UDim2.new(flySpeed/100, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
SliderFill.Parent = FlySpeedSlider

-- Checkpoint Tab
local CheckpointTab = Instance.new("Frame")
CheckpointTab.Name = "CheckpointTab"
CheckpointTab.Size = UDim2.new(1, 0, 1, 0)
CheckpointTab.BackgroundTransparency = 1
CheckpointTab.Visible = false
CheckpointTab.Parent = TabContent

local AddCPBtn = Instance.new("TextButton")
AddCPBtn.Size = UDim2.new(0, 140, 0, 50)
AddCPBtn.Position = UDim2.new(0, 10, 0, 10)
AddCPBtn.Text = "Add Checkpoint"
AddCPBtn.Font = Enum.Font.GothamBold
AddCPBtn.TextSize = 22
AddCPBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
AddCPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AddCPBtn.Parent = CheckpointTab

local CPList = Instance.new("ScrollingFrame")
CPList.Size = UDim2.new(0, 320, 0, 280)
CPList.Position = UDim2.new(0, 10, 0, 70)
CPList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CPList.CanvasSize = UDim2.new(0, 0, 0, 0)
CPList.Parent = CheckpointTab

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = CPList
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

local RunCPBtn = Instance.new("TextButton")
RunCPBtn.Size = UDim2.new(0, 140, 0, 50)
RunCPBtn.Position = UDim2.new(0, 180, 0, 10)
RunCPBtn.Text = "Run"
RunCPBtn.Font = Enum.Font.GothamBold
RunCPBtn.TextSize = 22
RunCPBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
RunCPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RunCPBtn.Parent = CheckpointTab

-- Settings Tab
local SettingsTab = Instance.new("Frame")
SettingsTab.Name = "SettingsTab"
SettingsTab.Size = UDim2.new(1, 0, 1, 0)
SettingsTab.BackgroundTransparency = 1
SettingsTab.Visible = false
SettingsTab.Parent = TabContent

local GodModeToggle = Instance.new("TextButton")
GodModeToggle.Size = UDim2.new(0, 140, 0, 50)
GodModeToggle.Position = UDim2.new(0, 10, 0, 10)
GodModeToggle.Text = "GodMode: OFF"
GodModeToggle.Font = Enum.Font.GothamBold
GodModeToggle.TextSize = 24
GodModeToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
GodModeToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
GodModeToggle.Parent = SettingsTab

local WalkSpeedLabel = Instance.new("TextLabel")
WalkSpeedLabel.Size = UDim2.new(0, 140, 0, 25)
WalkSpeedLabel.Position = UDim2.new(0, 10, 0, 70)
WalkSpeedLabel.Text = "WalkSpeed: "..walkSpeed
WalkSpeedLabel.Font = Enum.Font.Gotham
WalkSpeedLabel.TextSize = 18
WalkSpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
WalkSpeedLabel.BackgroundTransparency = 1
WalkSpeedLabel.Parent = SettingsTab

local WalkSpeedSlider = Instance.new("TextButton")
WalkSpeedSlider.Size = UDim2.new(0, 140, 0, 25)
WalkSpeedSlider.Position = UDim2.new(0, 10, 0, 100)
WalkSpeedSlider.Text = "Adjust WalkSpeed"
WalkSpeedSlider.Font = Enum.Font.Gotham
WalkSpeedSlider.TextSize = 18
WalkSpeedSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
WalkSpeedSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
WalkSpeedSlider.Parent = SettingsTab

local WSFill = Instance.new("Frame")
WSFill.Name = "Fill"
WSFill.Size = UDim2.new(walkSpeed/100, 0, 1, 0)
WSFill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
WSFill.Parent = WalkSpeedSlider

local SaveConfigBtn = Instance.new("TextButton")
SaveConfigBtn.Size = UDim2.new(0, 140, 0, 50)
SaveConfigBtn.Position = UDim2.new(0, 10, 0, 140)
SaveConfigBtn.Text = "Save Config"
SaveConfigBtn.Font = Enum.Font.GothamBold
SaveConfigBtn.TextSize = 22
SaveConfigBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
SaveConfigBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveConfigBtn.Parent = SettingsTab

local LoadConfigBtn = Instance.new("TextButton")
LoadConfigBtn.Size = UDim2.new(0, 140, 0, 50)
LoadConfigBtn.Position = UDim2.new(0, 180, 0, 140)
LoadConfigBtn.Text = "Load Config"
LoadConfigBtn.Font = Enum.Font.GothamBold
LoadConfigBtn.TextSize = 22
LoadConfigBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
LoadConfigBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadConfigBtn.Parent = SettingsTab

-- LoadConfig FileBrowser Frame
local FileBrowserFrame = Instance.new("Frame")
FileBrowserFrame.Name = "FileBrowserFrame"
FileBrowserFrame.Size = UDim2.new(0, 340, 0, 300)
FileBrowserFrame.Position = UDim2.new(0.5, -170, 0.5, -150)
FileBrowserFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
FileBrowserFrame.BorderSizePixel = 0
FileBrowserFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FileBrowserFrame.Visible = false
FileBrowserFrame.Parent = ScreenGui

local FBTitle = Instance.new("TextLabel")
FBTitle.Size = UDim2.new(1, 0, 0, 40)
FBTitle.BackgroundTransparency = 1
FBTitle.Text = "Load Config - Select a file"
FBTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
FBTitle.Font = Enum.Font.GothamBold
FBTitle.TextSize = 24
FBTitle.Parent = FileBrowserFrame

local CloseFBBtn = Instance.new("TextButton")
CloseFBBtn.Text = "X"
CloseFBBtn.Size = UDim2.new(0, 40, 0, 40)
CloseFBBtn.Position = UDim2.new(1, -45, 0, 0)
CloseFBBtn.Font = Enum.Font.SourceSansBold
CloseFBBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
CloseFBBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CloseFBBtn.Parent = FileBrowserFrame

local FBList = Instance.new("ScrollingFrame")
FBList.Size = UDim2.new(1, -20, 1, -50)
FBList.Position = UDim2.new(0, 10, 0, 40)
FBList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
FBList.Parent = FileBrowserFrame

local FBLayout = Instance.new("UIListLayout")
FBLayout.Parent = FBList
FBLayout.SortOrder = Enum.SortOrder.LayoutOrder
FBLayout.Padding = UDim.new(0, 5)

-- Function to clear child UI in a frame
local function clearChildren(frame)
	for _, child in pairs(frame:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

-- Function to refresh file list in FileBrowserFrame
local function refreshFileList()
	clearChildren(FBList)
	local files = {}
	if listfiles then
		for _, f in pairs(listfiles("")) do
			if f:match("%.json$") then
				table.insert(files, f)
			end
		end
	end
	table.sort(files)
	
	for _, fpath in ipairs(files) do
		local fname = fpath
		-- Trim path for display if contains folders
		if fname:find("/") then
			fname = fname:match("([^/]+)$")
		end
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 30)
		btn.Text = fname
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 18
		btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Parent = FBList
		
		btn.MouseButton1Click:Connect(function()
			FileBrowserFrame.Visible = false
			loadConfigFromFile(fpath)
		end)
	end
	
	if #files == 0 then
		local nofile = Instance.new("TextLabel")
		nofile.Size = UDim2.new(1, 0, 0, 30)
		nofile.Text = "No .json config files found."
		nofile.Font = Enum.Font.Gotham
		nofile.TextSize = 18
		nofile.TextColor3 = Color3.fromRGB(150, 150, 150)
		nofile.BackgroundTransparency = 1
		nofile.Parent = FBList
	end
end

-- Load Config from filename (separated func for FileBrowser)
function loadConfigFromFile(filename)
	if not isfile(filename) then
		warn("File not found: "..filename)
		return
	end
	local json = readfile(filename)
	local ok, cfg = pcall(function() return HttpService:JSONDecode(json) end)
	if ok and cfg then
		flySpeed = cfg.flySpeed or flySpeed
		godMode = cfg.godMode or godMode
		walkSpeed = cfg.walkSpeed or walkSpeed
		checkpoints = cfg.checkpoints or checkpoints
		
		FlySpeedLabel.Text = "Fly Speed: "..flySpeed
		SliderFill.Size = UDim2.new(flySpeed/100, 0, 1, 0)
		
		GodModeToggle.Text = "GodMode: "..(godMode and "ON" or "OFF")
		GodModeToggle.BackgroundColor3 = godMode and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(70, 70, 70)
		
		WalkSpeedLabel.Text = "WalkSpeed: "..walkSpeed
		WSFill.Size = UDim2.new(walkSpeed/100, 0, 1, 0)
		
		local character = LocalPlayer.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = walkSpeed
				if godMode then
					humanoid.MaxHealth = math.huge
					humanoid.Health = math.huge
				else
					humanoid.MaxHealth = 100
					humanoid.Health = 100
				end
			end
		end
		
		-- Clear CPList and recreate
		for _, c in pairs(CPList:GetChildren()) do
			if c:IsA("TextLabel") then c:Destroy() end
		end
		for i,v in ipairs(checkpoints) do
			local cpLabel = Instance.new("TextLabel")
			cpLabel.Text = "cp"..i.." : "..string.format("x=%.1f y=%.1f z=%.1f", v.X, v.Y, v.Z)
			cpLabel.Size = UDim2.new(1, -10, 0, 30)
			cpLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			cpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			cpLabel.Font = Enum.Font.Gotham
			cpLabel.TextSize = 18
			cpLabel.Parent = CPList
		end
		local layout = CPList:FindFirstChildOfClass("UIListLayout")
		if layout then
			CPList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
		end
	end
end

-- Save config (minta nama file via prompt)
local function promptInput(title, default)
	local InputGui = Instance.new("ScreenGui")
	InputGui.Name = "InputGui"
	InputGui.ResetOnSpawn = false
	InputGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	
	local Frame = Instance.new("Frame", InputGui)
	Frame.Size = UDim2.new(0, 300, 0, 120)
	Frame.Position = UDim2.new(0.5, -150, 0.5, -60)
	Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
	Frame.BorderSizePixel = 0
	Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	
	local TextLabel = Instance.new("TextLabel", Frame)
	TextLabel.Size = UDim2.new(1, -20, 0, 40)
	TextLabel.Position = UDim2.new(0, 10, 0, 10)
	TextLabel.Text = title
	TextLabel.Font = Enum.Font.GothamBold
	TextLabel.TextSize = 20
	TextLabel.TextColor3 = Color3.fromRGB(255,255,255)
	TextLabel.BackgroundTransparency = 1
	
	local TextBox = Instance.new("TextBox", Frame)
	TextBox.Size = UDim2.new(1, -20, 0, 30)
	TextBox.Position = UDim2.new(0, 10, 0, 60)
	TextBox.Text = default or ""
	TextBox.ClearTextOnFocus = false
	TextBox.Font = Enum.Font.Gotham
	TextBox.TextSize = 20
	TextBox.TextColor3 = Color3.fromRGB(255,255,255)
	TextBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
	TextBox.BorderSizePixel = 0
	
	local confirmed = false
	
	local function cleanup()
		InputGui:Destroy()
	end
	
	local result = nil
	TextBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			result = TextBox.Text
			confirmed = true
			cleanup()
		end
	end)
	
	while not confirmed do wait() end
	
	return result
end

local saveFileName = "default_config.json"

local function saveConfig()
	local filename = promptInput("Masukkan nama file save config (contoh: cp map A):", saveFileName)
	if not filename or filename == "" then return end
	if not filename:lower():match("%.json$") then
		filename = filename .. ".json"
	end
	
	local cfg = {
		flySpeed = flySpeed,
		godMode = godMode,
		walkSpeed = walkSpeed,
		checkpoints = checkpoints
	}
	
	local json = HttpService:JSONEncode(cfg)
	writefile(filename, json)
	saveFileName = filename
end

-- Button Events
SaveConfigBtn.MouseButton1Click:Connect(function()
	saveConfig()
end)

LoadConfigBtn.MouseButton1Click:Connect(function()
	refreshFileList()
	FileBrowserFrame.Visible = true
end)

CloseFBBtn.MouseButton1Click:Connect(function()
	FileBrowserFrame.Visible = false
end)

-- Tab Switching
local function switchTab(tabName)
	FlyTab.Visible = false
	CheckpointTab.Visible = false
	SettingsTab.Visible = false
	if tabName == "Fly" then FlyTab.Visible = true
	elseif tabName == "Checkpoints" then CheckpointTab.Visible = true
	elseif tabName == "Settings" then SettingsTab.Visible = true end
end

FlyTabBtn.MouseButton1Click:Connect(function() switchTab("Fly") end)
CheckpointTabBtn.MouseButton1Click:Connect(function() switchTab("Checkpoints") end)
SettingsTabBtn.MouseButton1Click:Connect(function() switchTab("Settings") end)

switchTab("Fly")

-- Close & Minimize
CloseBtn.MouseButton1Click:Connect(function()
	ScreenGui:Destroy()
end)

MinimizeBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
	MinimizedBar.Visible = true
end)

MinimizedBar.MouseButton1Click:Connect(function()
	MainFrame.Visible = true
	MinimizedBar.Visible = false
end)

-- Fly Toggle
FlyToggle.MouseButton1Click:Connect(function()
	flying = not flying
	FlyToggle.Text = "Fly: "..(flying and "ON" or "OFF")
end)

-- Fly Speed Slider Drag
local draggingFly = false
FlySpeedSlider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingFly = true
	end
end)
FlySpeedSlider.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingFly = false
	end
end)
FlySpeedSlider.InputChanged:Connect(function(input)
	if draggingFly and input.UserInputType == Enum.UserInputType.MouseMovement then
		local relX = math.clamp(input.Position.X - FlySpeedSlider.AbsolutePosition.X, 0, FlySpeedSlider.AbsoluteSize.X)
		flySpeed = math.floor((relX / FlySpeedSlider.AbsoluteSize.X) * 100)
		if flySpeed < 1 then flySpeed = 1 end
		SliderFill.Size = UDim2.new(flySpeed/100, 0, 1, 0)
		FlySpeedLabel.Text = "Fly Speed: "..flySpeed
	end
end)

-- Add Checkpoint
AddCPBtn.MouseButton1Click:Connect(function()
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	local hrp = character.HumanoidRootPart
	local cpNum = #checkpoints + 1
	table.insert(checkpoints, hrp.Position)
	
	local cpLabel = Instance.new("TextLabel")
	cpLabel.Text = "cp"..cpNum.." : "..string.format("x=%.1f y=%.1f z=%.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
	cpLabel.Size = UDim2.new(1, -10, 0, 30)
	cpLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	cpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	cpLabel.Font = Enum.Font.Gotham
	cpLabel.TextSize = 18
	cpLabel.Parent = CPList
	
	local layout = CPList:FindFirstChildOfClass("UIListLayout")
	if layout then
		CPList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end
end)

-- Run teleport to checkpoints
RunCPBtn.MouseButton1Click:Connect(function()
	if teleporting then return end
	if #checkpoints == 0 then return end
	teleporting = true
	
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart")
	
	for i, pos in ipairs(checkpoints) do
		hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0))
		wait(1)
	end
	
	teleporting = false
end)

-- WalkSpeed Slider Drag
local draggingWS = false
WalkSpeedSlider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingWS = true
	end
end)
WalkSpeedSlider.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingWS = false
	end
end)
WalkSpeedSlider.InputChanged:Connect(function(input)
	if draggingWS and input.UserInputType == Enum.UserInputType.MouseMovement then
		local relX = math.clamp(input.Position.X - WalkSpeedSlider.AbsolutePosition.X, 0, WalkSpeedSlider.AbsoluteSize.X)
		walkSpeed = math.floor((relX / WalkSpeedSlider.AbsoluteSize.X) * 100)
		if walkSpeed < 8 then walkSpeed = 8 end
		WSFill.Size = UDim2.new(walkSpeed/100, 0, 1, 0)
		WalkSpeedLabel.Text = "WalkSpeed: "..walkSpeed
		
		local character = LocalPlayer.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = walkSpeed
			end
		end
	end
end)

-- GodMode Toggle
GodModeToggle.MouseButton1Click:Connect(function()
	godMode = not godMode
	GodModeToggle.Text = "GodMode: "..(godMode and "ON" or "OFF")
	GodModeToggle.BackgroundColor3 = godMode and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(70, 70, 70)
	
	local character = LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if godMode then
				humanoid.MaxHealth = math.huge
				humanoid.Health = math.huge
			else
				humanoid.MaxHealth = 100
				humanoid.Health = 100
			end
		end
	end
end)

-- Fly control
local bodyVelocity = nil
local function startFly()
	if bodyVelocity then return end
	
	local character = LocalPlayer.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(9e4, 9e4, 9e4)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.Parent = hrp
end
local function stopFly()
	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end
end

spawn(function()
	while wait() do
		if flying then
			startFly()
			local direction = Vector3.new(0, 0, 0)
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + workspace.CurrentCamera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - workspace.CurrentCamera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - workspace.CurrentCamera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + workspace.CurrentCamera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction = direction - Vector3.new(0, 1, 0) end
			direction = direction.Unit
			if direction ~= direction then direction = Vector3.new(0,0,0) end
			if bodyVelocity then
				bodyVelocity.Velocity = direction * flySpeed
			end
		else
			stopFly()
		end
	end
end)
