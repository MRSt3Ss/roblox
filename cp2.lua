-- SadsXBons Ultimate GUI Script (merged, safe version)
-- Features:
-- Fly (WASD + Space/Shift), FlySpeed slider
-- Checkpoints: Add, list, Run (teleport through checkpoints with adjustable delay)
-- TP to Player: scan/search, TP (teleport local player to target HRP)
-- GetHere: client-side visual tween only
-- RequestTP: sends local chat asking the player to teleport to you
-- Settings: GodMode, WalkSpeed slider, Teleport Delay slider (applies to Run CP)
-- Save/Load config: saves settings + checkpoints as JSON to file manager, file browser load
-- Minimize/Restore GUI
-- Safe: DOES NOT attempt server-side exploitation or call/scan RemoteEvents for pulling players

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ======= Configurable variables =======
local flyEnabled = false
local flySpeed = 50             -- 1..100
local walkSpeed = 16            -- 1..100
local godMode = false
local teleportDelay = 0.9       -- seconds between teleports when running checkpoints

local checkpoints = {}         -- array of Vector3
local bodyVelocity = nil
local teleporting = false
local saveFileName = "default_config.json"

-- ======= Helpers =======
local function safeDecodeJSON(s)
	local ok, t = pcall(function() return HttpService:JSONDecode(s) end)
	if ok then return t end
	return nil
end

local function notif(msg)
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return end
	local g = Instance.new("ScreenGui")
	g.Name = "SadsXBons_Notify"
	g.ResetOnSpawn = false
	g.Parent = pg

	local frame = Instance.new("Frame", g)
	frame.Size = UDim2.new(0, 340, 0, 44)
	frame.Position = UDim2.new(0.5, -170, 0.85, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundTransparency = 0
	frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
	frame.BorderSizePixel = 0
	frame.ZIndex = 9999

	local label = Instance.new("TextLabel", frame)
	label.Size = UDim2.new(1, -16, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = msg
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextColor3 = Color3.fromRGB(255,120,120)
	label.TextXAlignment = Enum.TextXAlignment.Left

	spawn(function()
		for i=1,12 do wait(0.02); frame.BackgroundTransparency = frame.BackgroundTransparency - 0.08 end
		wait(1.0)
		for i=1,12 do wait(0.02); frame.BackgroundTransparency = frame.BackgroundTransparency + 0.08 end
		pcall(function() g:Destroy() end)
	end)
end

-- ======= GUI Build =======
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SadsXBonsGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 560, 0, 560)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -280)
MainFrame.AnchorPoint = Vector2.new(0.5,0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1,0,0,56)
Header.Position = UDim2.new(0,0,0,0)
Header.BackgroundColor3 = Color3.fromRGB(28,28,28)

local Logo = Instance.new("TextLabel", Header)
Logo.Text = "SadsXBons"
Logo.Font = Enum.Font.PatrickHand
Logo.TextSize = 28
Logo.TextColor3 = Color3.fromRGB(255,100,100)
Logo.BackgroundTransparency = 1
Logo.Position = UDim2.new(0,12,0,6)
Logo.Size = UDim2.new(0,300,1,0)

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.BackgroundColor3 = Color3.fromRGB(170,50,50)
CloseBtn.Size = UDim2.new(0,46,0,40)
CloseBtn.Position = UDim2.new(1,-56,0,8)

local MinBtn = Instance.new("TextButton", Header)
MinBtn.Text = "_"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 20
MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
MinBtn.Size = UDim2.new(0,46,0,40)
MinBtn.Position = UDim2.new(1,-112,0,8)

-- Minimized bar
local MinBar = Instance.new("TextButton", ScreenGui)
MinBar.Text = "SadsXBons (Click to Open)"
MinBar.Font = Enum.Font.PatrickHand
MinBar.TextSize = 18
MinBar.TextColor3 = Color3.fromRGB(255,100,100)
MinBar.BackgroundColor3 = Color3.fromRGB(20,20,20)
MinBar.Size = UDim2.new(0,240,0,40)
MinBar.Position = UDim2.new(0.5, -120, 0.1, 0)
MinBar.AnchorPoint = Vector2.new(0.5,0)
MinBar.Visible = false

-- Tabs row
local Tabs = Instance.new("Frame", MainFrame)
Tabs.Size = UDim2.new(1,0,0,44)
Tabs.Position = UDim2.new(0,0,0,56)
Tabs.BackgroundTransparency = 1

local function makeTabBtn(text, x)
	local b = Instance.new("TextButton", Tabs)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.Size = UDim2.new(0,132,1,0)
	b.Position = UDim2.new(0, 12 + (x * 136), 0, 0)
	b.BackgroundColor3 = Color3.fromRGB(36,36,36)
	b.TextColor3 = Color3.fromRGB(220,220,220)
	return b
end

local FlyTabBtn = makeTabBtn("Fly", 0)
local CPBtn = makeTabBtn("Checkpoints", 1)
local PlayerTPBtn = makeTabBtn("TP to Player", 2)
local SettingsBtn = makeTabBtn("Settings", 3)

-- Content area
local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(1, -16, 1, -120)
Content.Position = UDim2.new(0,8,0,112)
Content.BackgroundTransparency = 1

-- --- Fly Tab ---
local FlyTab = Instance.new("Frame", Content)
FlyTab.Size = UDim2.new(1,0,1,0)
FlyTab.BackgroundTransparency = 1

local FlyToggle = Instance.new("TextButton", FlyTab)
FlyToggle.Text = "Fly: OFF"
FlyToggle.Font = Enum.Font.GothamBold
FlyToggle.TextSize = 18
FlyToggle.Size = UDim2.new(0,180,0,46)
FlyToggle.Position = UDim2.new(0, 12, 0, 12)
FlyToggle.BackgroundColor3 = Color3.fromRGB(90,90,90)

local FlyLabel = Instance.new("TextLabel", FlyTab)
FlyLabel.Text = "Fly Speed: "..flySpeed
FlyLabel.Font = Enum.Font.Gotham
FlyLabel.TextSize = 16
FlyLabel.BackgroundTransparency = 1
FlyLabel.Position = UDim2.new(0,12,0,70)

local FlySlider = Instance.new("Frame", FlyTab)
FlySlider.Size = UDim2.new(0,320,0,20)
FlySlider.Position = UDim2.new(0,12,0,100)
FlySlider.BackgroundColor3 = Color3.fromRGB(60,60,60)

local FlyFill = Instance.new("Frame", FlySlider)
FlyFill.Size = UDim2.new(flySpeed/100,0,1,0)
FlyFill.BackgroundColor3 = Color3.fromRGB(255,100,100)

-- --- Checkpoints Tab ---
local CPTab = Instance.new("Frame", Content)
CPTab.Size = UDim2.new(1,0,1,0)
CPTab.BackgroundTransparency = 1
CPTab.Visible = false

local AddCP = Instance.new("TextButton", CPTab)
AddCP.Text = "Add Checkpoint"
AddCP.Font = Enum.Font.GothamBold
AddCP.TextSize = 16
AddCP.Size = UDim2.new(0,180,0,40)
AddCP.Position = UDim2.new(0,12,0,12)
AddCP.BackgroundColor3 = Color3.fromRGB(100,100,100)

local RunCP = Instance.new("TextButton", CPTab)
RunCP.Text = "Run"
RunCP.Font = Enum.Font.GothamBold
RunCP.TextSize = 16
RunCP.Size = UDim2.new(0,120,0,40)
RunCP.Position = UDim2.new(0,208,0,12)
RunCP.BackgroundColor3 = Color3.fromRGB(255,100,100)

local CPList = Instance.new("ScrollingFrame", CPTab)
CPList.Size = UDim2.new(1,-24,1,-80)
CPList.Position = UDim2.new(0,12,0,70)
CPList.BackgroundColor3 = Color3.fromRGB(30,30,30)
CPList.ScrollBarThickness = 8

local CPLayout = Instance.new("UIListLayout", CPList)
CPLayout.SortOrder = Enum.SortOrder.LayoutOrder
CPLayout.Padding = UDim.new(0,6)

-- --- Player TP Tab ---
local PlayerTab = Instance.new("Frame", Content)
PlayerTab.Size = UDim2.new(1,0,1,0)
PlayerTab.BackgroundTransparency = 1
PlayerTab.Visible = false

local ScanPlayersBtn = Instance.new("TextButton", PlayerTab)
ScanPlayersBtn.Text = "Scan All Players"
ScanPlayersBtn.Font = Enum.Font.GothamBold
ScanPlayersBtn.TextSize = 14
ScanPlayersBtn.Size = UDim2.new(0,180,0,36)
ScanPlayersBtn.Position = UDim2.new(0,12,0,12)
ScanPlayersBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)

local SearchBox = Instance.new("TextBox", PlayerTab)
SearchBox.PlaceholderText = "Search player name..."
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 14
SearchBox.Size = UDim2.new(0,320,0,36)
SearchBox.Position = UDim2.new(0,208,0,12)
SearchBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
SearchBox.TextColor3 = Color3.fromRGB(230,230,230)

local PlayerList = Instance.new("ScrollingFrame", PlayerTab)
PlayerList.Size = UDim2.new(1,-24,1,-80)
PlayerList.Position = UDim2.new(0,12,0,70)
PlayerList.BackgroundColor3 = Color3.fromRGB(30,30,30)
PlayerList.ScrollBarThickness = 8

local PlayerLayout = Instance.new("UIListLayout", PlayerList)
PlayerLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlayerLayout.Padding = UDim.new(0,6)

-- --- Settings Tab ---
local SettingsTab = Instance.new("Frame", Content)
SettingsTab.Size = UDim2.new(1,0,1,0)
SettingsTab.BackgroundTransparency = 1
SettingsTab.Visible = false

local GodBtn = Instance.new("TextButton", SettingsTab)
GodBtn.Text = "GodMode: OFF"
GodBtn.Font = Enum.Font.GothamBold
GodBtn.TextSize = 16
GodBtn.Size = UDim2.new(0,160,0,38)
GodBtn.Position = UDim2.new(0,12,0,12)
GodBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)

local WalkLabel = Instance.new("TextLabel", SettingsTab)
WalkLabel.Text = "WalkSpeed: "..walkSpeed
WalkLabel.Font = Enum.Font.Gotham
WalkLabel.TextSize = 14
WalkLabel.BackgroundTransparency = 1
WalkLabel.Position = UDim2.new(0,12,0,64)

local WalkSlider = Instance.new("Frame", SettingsTab)
WalkSlider.Size = UDim2.new(0,320,0,18)
WalkSlider.Position = UDim2.new(0,12,0,94)
WalkSlider.BackgroundColor3 = Color3.fromRGB(60,60,60)

local WalkFill = Instance.new("Frame", WalkSlider)
WalkFill.Size = UDim2.new(walkSpeed/100,0,1,0)
WalkFill.BackgroundColor3 = Color3.fromRGB(255,100,100)

-- teleport delay controls
local DelayLabel = Instance.new("TextLabel", SettingsTab)
DelayLabel.Text = "Teleport Delay: "..string.format("%.2f", teleportDelay).."s"
DelayLabel.Font = Enum.Font.Gotham
DelayLabel.TextSize = 14
DelayLabel.BackgroundTransparency = 1
DelayLabel.Position = UDim2.new(0,12,0,122)

local DelaySlider = Instance.new("Frame", SettingsTab)
DelaySlider.Size = UDim2.new(0,320,0,18)
DelaySlider.Position = UDim2.new(0,12,0,152)
DelaySlider.BackgroundColor3 = Color3.fromRGB(60,60,60)

local DelayFill = Instance.new("Frame", DelaySlider)
-- map teleportDelay 0.1..2.5 to 0..1 fill initially
local function delayToFill(d)
	local minv, maxv = 0.1, 2.5
	local t = math.clamp((d - minv)/(maxv-minv), 0, 1)
	return t
end
DelayFill.Size = UDim2.new(delayToFill(teleportDelay),0,1,0)
DelayFill.BackgroundColor3 = Color3.fromRGB(255,100,100)

-- Save/Load buttons
local SaveBtn = Instance.new("TextButton", SettingsTab)
SaveBtn.Text = "Save Config"
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.TextSize = 16
SaveBtn.Size = UDim2.new(0,160,0,40)
SaveBtn.Position = UDim2.new(0,12,1,-56)
SaveBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)

local LoadBtn = Instance.new("TextButton", SettingsTab)
LoadBtn.Text = "Load Config"
LoadBtn.Font = Enum.Font.GothamBold
LoadBtn.TextSize = 16
LoadBtn.Size = UDim2.new(0,160,0,40)
LoadBtn.Position = UDim2.new(0,196,1,-56)
LoadBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)

-- File Browser (Load)
local FileBrowser = Instance.new("Frame", ScreenGui)
FileBrowser.Size = UDim2.new(0,420,0,360)
FileBrowser.Position = UDim2.new(0.5, -210, 0.5, -180)
FileBrowser.AnchorPoint = Vector2.new(0.5,0.5)
FileBrowser.BackgroundColor3 = Color3.fromRGB(22,22,22)
FileBrowser.BorderSizePixel = 0
FileBrowser.Visible = false

local FBHeader = Instance.new("Frame", FileBrowser)
FBHeader.Size = UDim2.new(1,0,0,44)
FBHeader.BackgroundColor3 = Color3.fromRGB(32,32,32)

local FBTitle = Instance.new("TextLabel", FBHeader)
FBTitle.Text = "Load Config - Select .json"
FBTitle.Font = Enum.Font.GothamBold
FBTitle.TextSize = 16
FBTitle.BackgroundTransparency = 1
FBTitle.TextColor3 = Color3.fromRGB(255,100,100)
FBTitle.Position = UDim2.new(0,12,0,6)

local FBClose = Instance.new("TextButton", FBHeader)
FBClose.Text = "X"
FBClose.Size = UDim2.new(0,40,1,0)
FBClose.Position = UDim2.new(1,-48,0,0)
FBClose.BackgroundColor3 = Color3.fromRGB(170,50,50)

local FBList = Instance.new("ScrollingFrame", FileBrowser)
FBList.Size = UDim2.new(1,-24,1,-64)
FBList.Position = UDim2.new(0,12,0,52)
FBList.BackgroundColor3 = Color3.fromRGB(28,28,28)
local FBLayout = Instance.new("UIListLayout", FBList)
FBLayout.SortOrder = Enum.SortOrder.LayoutOrder
FBLayout.Padding = UDim.new(0,6)

-- ======= Utility UI refresh functions =======
local function refreshCPListUI()
	for _, ch in pairs(CPList:GetChildren()) do
		if ch:IsA("TextLabel") then ch:Destroy() end
	end
	for i, pos in ipairs(checkpoints) do
		local lbl = Instance.new("TextLabel", CPList)
		lbl.Size = UDim2.new(1,-12,0,28)
		lbl.BackgroundColor3 = Color3.fromRGB(42,42,42)
		lbl.TextColor3 = Color3.fromRGB(230,230,230)
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 14
		lbl.Text = ("cp%d : x=%.1f y=%.1f z=%.1f"):format(i, pos.X, pos.Y, pos.Z)
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = CPList
	end
	local layout = CPList:FindFirstChildOfClass("UIListLayout")
	if layout then
		CPList.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 12)
	end
end

local function refreshPlayerListUI(filter)
	filter = filter and filter:lower() or ""
	-- clear frames
	for _, ch in pairs(PlayerList:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= LocalPlayer then
			local nameLower = (pl.Name or ""):lower()
			local displayLower = (pl.DisplayName or ""):lower()
			if filter == "" or nameLower:find(filter) or displayLower:find(filter) then
				local entry = Instance.new("Frame", PlayerList)
				entry.Size = UDim2.new(1,-12,0,62)
				entry.BackgroundColor3 = Color3.fromRGB(38,38,38)

				local nameLbl = Instance.new("TextLabel", entry)
				nameLbl.Size = UDim2.new(0.6,0,1,0)
				nameLbl.Position = UDim2.new(0,8,0,0)
				nameLbl.BackgroundTransparency = 1
				nameLbl.Font = Enum.Font.Gotham
				nameLbl.TextSize = 14
				nameLbl.TextColor3 = Color3.fromRGB(230,230,230)
				nameLbl.Text = pl.Name .. " | " .. (pl.DisplayName or "")

				local tpBtn = Instance.new("TextButton", entry)
				tpBtn.Size = UDim2.new(0,76,0,28)
				tpBtn.Position = UDim2.new(0.62,8,0,8)
				tpBtn.Text = "TP"
				tpBtn.Font = Enum.Font.GothamBold
				tpBtn.TextSize = 14
				tpBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)

				local getBtn = Instance.new("TextButton", entry)
				getBtn.Size = UDim2.new(0,76,0,28)
				getBtn.Position = UDim2.new(0.78,8,0,8)
				getBtn.Text = "GetHere"
				getBtn.Font = Enum.Font.GothamBold
				getBtn.TextSize = 14
				getBtn.BackgroundColor3 = Color3.fromRGB(255,100,100)

				local reqBtn = Instance.new("TextButton", entry)
				reqBtn.Size = UDim2.new(0,100,0,22)
				reqBtn.Position = UDim2.new(0.62,8,0,36)
				reqBtn.Text = "RequestTP"
				reqBtn.Font = Enum.Font.GothamBold
				reqBtn.TextSize = 12
				reqBtn.BackgroundColor3 = Color3.fromRGB(80,80,200)

				-- actions
				tpBtn.MouseButton1Click:Connect(function()
					local ok, char = pcall(function() return pl.Character end)
					if not ok or not char then notif("Player character not available"); return end
					local hrp = char:FindFirstChild("HumanoidRootPart")
					local myChar = LocalPlayer.Character
					if hrp and myChar and myChar:FindFirstChild("HumanoidRootPart") then
						pcall(function() myChar.HumanoidRootPart.CFrame = hrp.CFrame + Vector3.new(0,3,0) end)
					else
						notif("TP failed: missing HRP")
					end
				end)

				getBtn.MouseButton1Click:Connect(function()
					-- Client-side visual tween of the *target's* HRP to our position (affects only our client view)
					local ok, char = pcall(function() return pl.Character end)
					if not ok or not char then notif("Player character not available"); return end
					local targetHRP = char:FindFirstChild("HumanoidRootPart")
					local myChar = LocalPlayer.Character
					if not targetHRP or not myChar or not myChar:FindFirstChild("HumanoidRootPart") then
						notif("GetHere failed: missing HRP")
						return
					end
					local start = targetHRP.CFrame
					local dest = myChar.HumanoidRootPart.CFrame * CFrame.new(0,1,0)
					local duration = 0.6
					local elapsed = 0
					spawn(function()
						while elapsed < duration do
							local dt = task.wait()
							elapsed = elapsed + dt
							local alpha = math.clamp(elapsed / duration, 0, 1)
							alpha = alpha * alpha * (3 - 2*alpha) -- smoothstep
							local cf = start:Lerp(dest, alpha)
							pcall(function() targetHRP.CFrame = cf end) -- local only
						end
						pcall(function() targetHRP.CFrame = dest end)
					end)
					notif("Applied local GetHere to "..pl.Name)
				end)

				reqBtn.MouseButton1Click:Connect(function()
					local msg = "[RequestTP] Hey "..pl.Name..", could you teleport to me? (requested by "..LocalPlayer.Name..")"
					pcall(function() LocalPlayer:Chat(msg) end)
					notif("Request sent to "..pl.Name)
				end)
			end
		end
	end
	-- adjust canvas size
	local layout = PlayerList:FindFirstChildOfClass("UIListLayout")
	if layout then
		PlayerList.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 12)
	end
end

-- ======= File browser refresh =======
local function refreshFileBrowser()
	for _, ch in pairs(FBList:GetChildren()) do
		if ch:IsA("TextButton") or ch:IsA("TextLabel") then ch:Destroy() end
	end
	local files = {}
	if listfiles then
		local ok, res = pcall(function() return listfiles("") end)
		if ok and type(res) == "table" then
			for _, f in ipairs(res) do
				if tostring(f):lower():match("%.json$") then table.insert(files, f) end
			end
		end
	end
	table.sort(files)
	if #files == 0 then
		local lbl = Instance.new("TextLabel", FBList)
		lbl.Size = UDim2.new(1,0,0,36)
		lbl.Position = UDim2.new(0,0,0,0)
		lbl.Text = "No .json config files found."
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Color3.fromRGB(160,160,160)
	else
		for _, f in ipairs(files) do
			local btn = Instance.new("TextButton", FBList)
			btn.Size = UDim2.new(1,0,0,36)
			btn.Text = f
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 14
			btn.BackgroundColor3 = Color3.fromRGB(44,44,44)
			btn.MouseButton1Click:Connect(function()
				FileBrowser.Visible = false
				if isfile and isfile(f) then
					local ok2, data = pcall(function() return readfile(f) end)
					if ok2 and data then
						local cfg = safeDecodeJSON(data)
						if cfg then
							-- apply config
							flySpeed = cfg.flySpeed or flySpeed
							godMode = cfg.godMode or godMode
							walkSpeed = cfg.walkSpeed or walkSpeed
							teleportDelay = cfg.teleportDelay or teleportDelay
							checkpoints = {}
							if cfg.checkpoints and type(cfg.checkpoints) == "table" then
								for i, cp in ipairs(cfg.checkpoints) do
									if type(cp) == "table" and cp.x and cp.y and cp.z then
										table.insert(checkpoints, Vector3.new(cp.x, cp.y, cp.z))
									end
								end
							end
							-- update UI
							FlyFill.Size = UDim2.new(flySpeed/100,0,1,0)
							FlyLabel.Text = "Fly Speed: "..flySpeed
							WalkFill.Size = UDim2.new(walkSpeed/100,0,1,0)
							WalkLabel.Text = "WalkSpeed: "..walkSpeed
							DelayFill.Size = UDim2.new(delayToFill(teleportDelay),0,1,0)
							DelayLabel.Text = "Teleport Delay: "..string.format("%.2f", teleportDelay).."s"
							GodBtn.Text = "GodMode: "..(godMode and "ON" or "OFF")
							refreshCPListUI()
							notif("Loaded config: "..f)
						else
							notif("Invalid json")
						end
					else
						notif("Can't read file")
					end
				else
					notif("File not accessible")
				end
			end)
		end
	end
end

-- ======= Save/Load prompt & functions =======
local function promptInput(title, default, callback)
	local g = Instance.new("ScreenGui")
	g.Name = "SadsXBons_Prompt"
	g.Parent = PlayerGui
	g.ResetOnSpawn = false

	local f = Instance.new("Frame", g)
	f.Size = UDim2.new(0,420,0,120)
	f.Position = UDim2.new(0.5, -210, 0.5, -60)
	f.AnchorPoint = Vector2.new(0.5,0.5)
	f.BackgroundColor3 = Color3.fromRGB(28,28,28)
	f.BorderSizePixel = 0

	local lbl = Instance.new("TextLabel", f)
	lbl.Size = UDim2.new(1,-24,0,36)
	lbl.Position = UDim2.new(0,12,0,8)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 16
	lbl.TextColor3 = Color3.fromRGB(255,100,100)
	lbl.Text = title

	local tb = Instance.new("TextBox", f)
	tb.Size = UDim2.new(1,-24,0,36)
	tb.Position = UDim2.new(0,12,0,48)
	tb.Font = Enum.Font.Gotham
	tb.TextSize = 14
	tb.Text = default or ""
	tb.ClearTextOnFocus = false
	tb.BackgroundColor3 = Color3.fromRGB(40,40,40)
	tb.TextColor3 = Color3.fromRGB(230,230,230)

	local saveBtn = Instance.new("TextButton", f)
	saveBtn.Size = UDim2.new(0,120,0,30)
	saveBtn.Position = UDim2.new(1,-140,1,-40)
	saveBtn.Text = "Save"
	saveBtn.Font = Enum.Font.GothamBold
	saveBtn.BackgroundColor3 = Color3.fromRGB(255,100,100)

	local function close()
		pcall(function() g:Destroy() end)
	end
	local function doSave()
		local text = tb.Text
		if text and text ~= "" then
			close()
			callback(text)
		else
			notif("Enter a valid filename")
		end
	end
	saveBtn.MouseButton1Click:Connect(doSave)
	tb.FocusLost:Connect(function(enter) if enter then doSave() end end)
end

local function saveConfig()
	promptInput("Enter filename to save (eg: cp map A):", saveFileName, function(name)
		if not name:lower():match("%.json$") then name = name .. ".json" end
		local cfg = {
			flySpeed = flySpeed,
			godMode = godMode,
			walkSpeed = walkSpeed,
			teleportDelay = teleportDelay,
			checkpoints = {}
		}
		for i, v in ipairs(checkpoints) do
			cfg.checkpoints[i] = {x = v.X, y = v.Y, z = v.Z}
		end
		local ok, err = pcall(function() writefile(name, HttpService:JSONEncode(cfg)) end)
		if ok then
			saveFileName = name
			notif("Saved: "..name)
		else
			notif("Save failed: "..tostring(err))
		end
	end)
end

-- ======= Fly implementation =======
local function startFly()
	if bodyVelocity then return end
	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
	bodyVelocity.Velocity = Vector3.new(0,0,0)
	bodyVelocity.Parent = hrp

	RunService:BindToRenderStep("SadsXBons_Fly", Enum.RenderPriority.Character.Value + 1, function()
		if not bodyVelocity or not hrp then return end
		local dir = Vector3.new(0,0,0)
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + workspace.CurrentCamera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - workspace.CurrentCamera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - workspace.CurrentCamera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + workspace.CurrentCamera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
		if dir.Magnitude > 0 then
			bodyVelocity.Velocity = dir.Unit * flySpeed
		else
			bodyVelocity.Velocity = Vector3.new(0,0,0)
		end
	end)
end

local function stopFly()
	if bodyVelocity then
		pcall(function() bodyVelocity:Destroy() end)
		bodyVelocity = nil
		pcall(function() RunService:UnbindFromRenderStep("SadsXBons_Fly") end)
	end
end

-- ======= Checkpoint functions =======
local function addCheckpoint()
	local char = LocalPlayer.Character
	if not char then notif("Character not found"); return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then notif("HRP not found"); return end
	table.insert(checkpoints, hrp.Position)
	refreshCPListUI()
end

local function runCheckpoints()
	if teleporting then return end
	if #checkpoints == 0 then notif("No checkpoints"); return end
	teleporting = true
	local char = LocalPlayer.Character
	if not char then teleporting = false; return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then teleporting = false; return end
	for _, pos in ipairs(checkpoints) do
		pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end)
		wait(teleportDelay)
	end
	teleporting = false
end

-- ======= UI Events =======
-- Tabs
local function switchTab(name)
	FlyTab.Visible = (name == "Fly")
	CPTab.Visible = (name == "CP")
	PlayerTab.Visible = (name == "Player")
	SettingsTab.Visible = (name == "Settings")
	-- highlight
	FlyTabBtn.BackgroundColor3 = (name=="Fly") and Color3.fromRGB(60,60,60) or Color3.fromRGB(36,36,36)
	CPBtn.BackgroundColor3 = (name=="CP") and Color3.fromRGB(60,60,60) or Color3.fromRGB(36,36,36)
	PlayerTPBtn.BackgroundColor3 = (name=="Player") and Color3.fromRGB(60,60,60) or Color3.fromRGB(36,36,36)
	SettingsBtn.BackgroundColor3 = (name=="Settings") and Color3.fromRGB(60,60,60) or Color3.fromRGB(36,36,36)
end

FlyTabBtn.MouseButton1Click:Connect(function() switchTab("Fly") end)
CPBtn.MouseButton1Click:Connect(function() switchTab("CP") end)
PlayerTPBtn.MouseButton1Click:Connect(function() switchTab("Player") end)
SettingsBtn.MouseButton1Click:Connect(function() switchTab("Settings") end)

-- Close/minimize
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
MinBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
	MinBar.Visible = true
end)
MinBar.MouseButton1Click:Connect(function()
	MainFrame.Visible = true
	MinBar.Visible = false
end)

-- Fly toggle
FlyToggle.MouseButton1Click:Connect(function()
	if bodyVelocity then
		FlyToggle.Text = "Fly: OFF"
		FlyToggle.BackgroundColor3 = Color3.fromRGB(90,90,90)
		stopFly()
	else
		FlyToggle.Text = "Fly: ON"
		FlyToggle.BackgroundColor3 = Color3.fromRGB(255,100,100)
		startFly()
	end
end)

-- Fly slider interaction
do
	local dragging = false
	FlySlider.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
	FlySlider.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
	FlySlider.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local relX = math.clamp(i.Position.X - FlySlider.AbsolutePosition.X, 0, FlySlider.AbsoluteSize.X)
			flySpeed = math.max(1, math.floor((relX / FlySlider.AbsoluteSize.X) * 100))
			FlyFill.Size = UDim2.new(flySpeed/100,0,1,0)
			FlyLabel.Text = "Fly Speed: "..flySpeed
		end
	end)
end

-- Add checkpoint / run
AddCP.MouseButton1Click:Connect(addCheckpoint)
RunCP.MouseButton1Click:Connect(runCheckpoints)

-- Player scan/search
ScanPlayersBtn.MouseButton1Click:Connect(function()
	refreshPlayerListUI()
	notif("Scanned players")
end)
SearchBox.FocusLost:Connect(function(enter)
	if enter then refreshPlayerListUI(SearchBox.Text) end
end)
SearchBox.Changed:Connect(function(prop) if prop == "Text" then refreshPlayerListUI(SearchBox.Text) end end)

-- WalkSpeed slider
do
	local dragging = false
	WalkSlider.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
	WalkSlider.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
	WalkSlider.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local relX = math.clamp(i.Position.X - WalkSlider.AbsolutePosition.X, 0, WalkSlider.AbsoluteSize.X)
			walkSpeed = math.max(1, math.floor((relX / WalkSlider.AbsoluteSize.X) * 100))
			WalkFill.Size = UDim2.new(walkSpeed/100,0,1,0)
			WalkLabel.Text = "WalkSpeed: "..walkSpeed
			local char = LocalPlayer.Character
			if char then
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if humanoid then pcall(function() humanoid.WalkSpeed = walkSpeed end) end
			end
		end
	end)
end

-- Teleport delay slider (maps 0.1..2.5 sec)
do
	local dragging = false
	local minv, maxv = 0.1, 2.5
	DelaySlider.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
	DelaySlider.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
	DelaySlider.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local relX = math.clamp(i.Position.X - DelaySlider.AbsolutePosition.X, 0, DelaySlider.AbsoluteSize.X)
			local t = relX / DelaySlider.AbsoluteSize.X
			teleportDelay = minv + (maxv - minv) * t
			DelayFill.Size = UDim2.new(t,0,1,0)
			DelayLabel.Text = "Teleport Delay: "..string.format("%.2f", teleportDelay).."s"
		end
	end)
end

-- GodMode toggle
GodBtn.MouseButton1Click:Connect(function()
	godMode = not godMode
	GodBtn.Text = "GodMode: "..(godMode and "ON" or "OFF")
	GodBtn.BackgroundColor3 = godMode and Color3.fromRGB(255,100,100) or Color3.fromRGB(80,80,80)
	local char = LocalPlayer.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if godMode then
				pcall(function() humanoid.MaxHealth = math.huge humanoid.Health = math.huge end)
			else
				pcall(function() humanoid.MaxHealth = 100 humanoid.Health = 100 end)
			end
		end
	end
end)

-- Save / Load
SaveBtn.MouseButton1Click:Connect(saveConfig)
LoadBtn.MouseButton1Click:Connect(function() refreshFileBrowser(); FileBrowser.Visible = true end)
FBClose.MouseButton1Click:Connect(function() FileBrowser.Visible = false end)

-- FileBrowser refresh on open is handled above

-- ======= Ensure UI shows existing state =======
refreshCPListUI()
refreshPlayerListUI()
FlyFill.Size = UDim2.new(flySpeed/100,0,1,0)
WalkFill.Size = UDim2.new(walkSpeed/100,0,1,0)
DelayFill.Size = UDim2.new(delayToFill(teleportDelay),0,1,0)
FlyLabel.Text = "Fly Speed: "..flySpeed
WalkLabel.Text = "WalkSpeed: "..walkSpeed
DelayLabel.Text = "Teleport Delay: "..string.format("%.2f", teleportDelay).."s"

-- Update player humanoid on spawn (apply walkSpeed, godMode)
Players.LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.7)
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		pcall(function() humanoid.WalkSpeed = walkSpeed end)
		if godMode then pcall(function() humanoid.MaxHealth = math.huge humanoid.Health = math.huge end) end
	end
end)

-- Safe final message
notif("SadsXBons GUI loaded — ready.")

-- End of script
