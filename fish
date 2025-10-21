--[[
    Fish It - Auto Farm dengan Key System dari GitHub
    Validasi key via file: https://raw.githubusercontent.com/MRSt3Ss/BonsHub2/main/database.txt
]]

-- ================================================================================= --
--[[ BAGIAN 1: KEY SYSTEM - Validasi dari GitHub ]]
-- ================================================================================= --

local KeySystem = {
    Valid = false,
    Key = "",
    DatabaseUrl = "https://raw.githubusercontent.com/MRSt3Ss/BonsHub2/refs/heads/main/error_log/log_eror.txt",
    Attempts = 0,
    MaxAttempts = 3
}

-- Fungsi validasi key dari GitHub
local function validateKeyFromGitHub(key)
    local success, result = pcall(function()
        -- Download dari GitHub
        local response = game:HttpGet(KeySystem.DatabaseUrl, true)
        
        -- Split by lines dan bersihkan whitespace
        local validKeys = {}
        for line in response:gmatch("[^\r\n]+") do
            -- Ambil hanya bagian key (abaikan angka di depan jika ada)
            local cleanKey = line:gsub("^%d+%.?", ""):gsub("%s+", ""):upper()
            if cleanKey ~= "" and #cleanKey >= 5 then
                table.insert(validKeys, cleanKey)
            end
        end
        
        -- Cek jika key ada dalam database
        for _, validKey in ipairs(validKeys) do
            if key == validKey then
                print("✅ Key VALID!")
                return true, "✅ Key valid! Premium access granted."
            end
        end
        
        print("❌ Key TIDAK valid!")
        return false, "❌ Key tidak valid atau tidak ditemukan dalam database."
    end)
    
    if success then
        return result
    else
        print("❌ Error mengakses GitHub: " .. tostring(result))
        return false, "❌ Gagal mengakses database key. Cek koneksi internet."
    end
end

-- ================================================================================= --
--[[ BAGIAN 2: SIMPLE KEY INPUT GUI ]]
-- ================================================================================= --

local function showSimpleKeyInput()
    local screenGui = Instance.new("ScreenGui", game.CoreGui)
    screenGui.Name = "KeyInputGui"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local frame = Instance.new("Frame", screenGui)
    frame.Size = UDim2.new(0, 400, 0, 250)
    frame.Position = UDim2.new(0.5, -200, 0.5, -125)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 15)
    
    -- Title
    local title = Instance.new("TextLabel", frame)
    title.Text = "🔐 FISH IT HELPER"
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextWrapped = true
    
    local titleCorner = Instance.new("UICorner", title)
    titleCorner.CornerRadius = UDim.new(0, 15)
    
    -- Instruction
    local instruction = Instance.new("TextLabel", frame)
    instruction.Text = "Masukkan key premium Anda:"
    instruction.Size = UDim2.new(0.85, 0, 0, 40)
    instruction.Position = UDim2.new(0.075, 0, 0.25, 0)
    instruction.BackgroundTransparency = 1
    instruction.TextColor3 = Color3.fromRGB(180, 180, 200)
    instruction.Font = Enum.Font.Gotham
    instruction.TextSize = 14
    instruction.TextWrapped = true
    
    -- Key Input
    local input = Instance.new("TextBox", frame)
    input.Size = UDim2.new(0.85, 0, 0, 40)
    input.Position = UDim2.new(0.075, 0, 0.45, 0)
    input.PlaceholderText = "Masukkan key di sini..."
    input.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.Font = Enum.Font.Gotham
    input.TextSize = 16
    input.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
    input.TextXAlignment = Enum.TextXAlignment.Center
    
    local inputCorner = Instance.new("UICorner", input)
    inputCorner.CornerRadius = UDim.new(0, 8)
    
    -- Status Message
    local statusLabel = Instance.new("TextLabel", frame)
    statusLabel.Text = ""
    statusLabel.Size = UDim2.new(0.85, 0, 0, 30)
    statusLabel.Position = UDim2.new(0.075, 0, 0.7, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 12
    statusLabel.TextWrapped = true
    
    -- Submit Button
    local submit = Instance.new("TextButton", frame)
    submit.Size = UDim2.new(0.85, 0, 0, 40)
    submit.Position = UDim2.new(0.075, 0, 0.85, 0)
    submit.Text = "🚀 VERIFY KEY"
    submit.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    submit.TextColor3 = Color3.fromRGB(255, 255, 255)
    submit.Font = Enum.Font.GothamBold
    submit.TextSize = 16
    
    local submitCorner = Instance.new("UICorner", submit)
    submitCorner.CornerRadius = UDim.new(0, 8)
    
    submit.MouseButton1Click:Connect(function()
        local key = input.Text:gsub("%s+", ""):upper()
        if key == "" then
            statusLabel.Text = "❌ Silakan masukkan key"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        
        submit.Text = "VERIFYING..."
        submit.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
        
        -- Validasi key
        local isValid, message = validateKeyFromGitHub(key)
        
        if isValid then
            KeySystem.Valid = true
            KeySystem.Key = key
            statusLabel.Text = "✅ Key Valid! Loading..."
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            
            submit.Text = "✅ SUCCESS!"
            submit.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
            
            task.wait(1)
            screenGui:Destroy()
            
            -- Load main script langsung
            loadMainScript()
        else
            KeySystem.Attempts = KeySystem.Attempts + 1
            statusLabel.Text = message
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            submit.Text = "🔑 VERIFY KEY"
            submit.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
            
            if KeySystem.Attempts >= KeySystem.MaxAttempts then
                statusLabel.Text = "❌ Terlalu banyak percobaan gagal."
                submit.Visible = false
                task.wait(3)
                screenGui:Destroy()
            end
        end
    end)
    
    -- Enter key to submit
    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            submit.MouseButton1Click:Fire()
        end
    end)
    
    -- Auto-focus input
    task.wait(0.5)
    input:CaptureFocus()
end

-- ================================================================================= --
--[[ BAGIAN 3: SCRIPT UTAMA (akan diload setelah key valid) ]]
-- ================================================================================= --

function loadMainScript()
    print("✅ Key valid! Loading main script...")
    
--[[
    Fish It - Auto Farm (Versi GILA-GILAAN)
    BYPASS ALL LIMITS - MAXIMUM INSANE SPEED
]]

-- Bagian 1: Pemuat Rayfield UI
local Rayfield = nil
local LoadedRayfield = false

-- Fungsi untuk load Rayfield dengan multiple fallback
local function loadRayfield()
    if LoadedRayfield then return Rayfield end
    
    local urls = {
        "https://raw.githubusercontent.com/Sirius-menu/Rayfield/main/source.lua",
        "https://sirius.menu/rayfield",
        "https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"
    }
    
    for _, url in ipairs(urls) do
        local success, result = pcall(function()
            local source = game:HttpGet(url)
            if source and string.find(source, "CreateWindow") then
                print("✅ Berhasil download Rayfield dari: " .. url)
                Rayfield = loadstring(source)()
                LoadedRayfield = true
                return true
            end
        end)
        
        if success and Rayfield then
            return Rayfield
        else
            warn("❌ Gagal load dari: " .. url)
        end
    end
    
    error("❌ Gagal memuat Rayfield dari semua sumber")
end

-- Coba load Rayfield
local rayfieldSuccess, rayfieldError = pcall(loadRayfield)

if not rayfieldSuccess or not Rayfield then
    -- Fallback UI sederhana
    loadMainSystems()
    createFallbackUI()
    return
end

-- ================================================================================= --
--[[ BAGIAN 4: LOAD SISTEM UTAMA SEBELUM UI ]]
-- ================================================================================= --

-- Load semua sistem utama terlebih dahulu
function loadMainSystems()
    -- Layanan dan Variabel Global
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local localPlayer = Players.LocalPlayer

    -- Fungsi Notifikasi Global
    function updateStatus(msg)
        if Rayfield then
            Rayfield:Notify({Title = "Notifikasi", Content = msg, Duration = 1})
        else
            warn("[Status] " .. tostring(msg))
        end
    end

    -- ================================================================================= --
    --[[ BAGIAN 5: FITUR ANTI AFK ]]
    -- ================================================================================= --

    AntiAFK = {
        Enabled = false,
        Connection = nil
    }

    function AntiAFK:Start()
        if self.Enabled then return end
        self.Enabled = true
        
        self.Connection = RunService.Heartbeat:Connect(function()
            if self.Enabled then
                pcall(function()
                    VirtualInputManager:SendMouseMoveEvent(1, 1, game:GetService("CoreGui"))
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    VirtualInputManager:SendMouseMoveEvent(-1, -1, game:GetService("CoreGui"))
                end)
            end
        end)
        
        updateStatus("Anti AFK diaktifkan!")
    end

    function AntiAFK:Stop()
        self.Enabled = false
        if self.Connection then
            self.Connection:Disconnect()
            self.Connection = nil
        end
        updateStatus("Anti AFK dimatikan!")
    end

    -- ================================================================================= --
    --[[ BAGIAN 6: FITUR SPAWN PLATFORM ]]
    -- ================================================================================= --

    PlatformSystem = {
        CurrentPlatform = nil,
        PlatformSize = Vector3.new(6, 1, 6)
    }

    function PlatformSystem:CreatePlatform()
        self:RemovePlatform()
        
        local char = localPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        local hrp = char.HumanoidRootPart
        local position = hrp.Position - Vector3.new(0, 3, 0)
        
        local platform = Instance.new("Part")
        platform.Name = "AntiFallPlatform"
        platform.Size = self.PlatformSize
        platform.Position = position
        platform.Anchored = true
        platform.CanCollide = true
        platform.Material = Enum.Material.Neon
        platform.BrickColor = BrickColor.new("Bright blue")
        platform.Parent = workspace
        
        self.CurrentPlatform = platform
        updateStatus("Platform berhasil dibuat!")
    end

    function PlatformSystem:RemovePlatform()
        if self.CurrentPlatform then
            self.CurrentPlatform:Destroy()
            self.CurrentPlatform = nil
            updateStatus("Platform dihapus!")
        end
    end

    function PlatformSystem:FollowCharacter()
        if not self.CurrentPlatform then return end
        local char = localPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local position = hrp.Position - Vector3.new(0, 3, 0)
            self.CurrentPlatform.Position = position
        end
    end

    -- ================================================================================= --
    --[[ BAGIAN 7: FITUR TELEPORT TO PLAYER ]]
    -- ================================================================================= --

    TeleportSystem = {
        PlayersList = {}
    }

    function TeleportSystem:GetPlayers()
        self.PlayersList = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                table.insert(self.PlayersList, player.Name)
            end
        end
        table.sort(self.PlayersList)
        return self.PlayersList
    end

    function TeleportSystem:TeleportToPlayer(playerName)
        local targetPlayer = Players:FindFirstChild(playerName)
        if not targetPlayer then
            updateStatus("Player tidak ditemukan: " .. playerName)
            return
        end
        
        local char = targetPlayer.Character
        local localChar = localPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
            updateStatus("Karakter tidak ditemukan")
            return
        end
        
        local hrp = localChar.HumanoidRootPart
        local targetPos = char.HumanoidRootPart.Position + Vector3.new(0, 3, 0)
        hrp.CFrame = CFrame.new(targetPos)
        
        updateStatus("Teleport ke: " .. playerName)
    end

    -- ================================================================================= --
    --[[ BAGIAN 8: LOGIKA INTI "FISH IT" (VERSI GILA-GILAAN) ]]
    -- ================================================================================= --

    FishItV2 = {
        isInitialized = false,
        autofishV2 = false,
        perfectCastV2 = true,
        noAnimation = true,
        fishingLoop = nil,
        steppedLoop = nil,
        renderLoop = nil,
        postSimulationLoop = nil,
        net = nil,
        finishRemote = nil,
        miniGameRemote = nil,
        chargeRemote = nil,
        equipRemote = nil,
        castCount = 0,
        lastUpdate = 0,
        spamLevel = 50 -- 🔥 LEVEL SPAM GILA-GILAAN
    }

    function FishItV2:SetAnimationState(enabled)
        if not enabled then
            local char = localPlayer.Character
            if not char then return end
            pcall(function()
                local animateScript = char:FindFirstChild("Animate")
                if animateScript then animateScript.Enabled = false end
                
                -- 🔥 KILL ALL ANIMATIONS BRUTALLY
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local animator = humanoid:FindFirstChildOfClass("Animator")
                    if animator then
                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            track:Stop(0) -- STOP IMMEDIATELY
                        end
                    end
                end
            end)
        end
    end

    local function findRemote(container, ...)
        for i = 1, select("#", ...) do
            local name = select(i, ...)
            local r = container:FindFirstChild(name)
            if r then return r end
        end
        return nil
    end

    -- 🔥 PRELOAD REMOTES GILA-GILAAN
    function FishItV2:InsanePreload()
        if not self.net then return end
        
        -- 🔥 PRELOAD 100x UNTUK MEMASTIKAN TIDAK ADA DELAY
        for i = 1, 100 do
            task.spawn(function()
                pcall(function()
                    if self.chargeRemote then
                        self.chargeRemote:InvokeServer(workspace:GetServerTimeNow())
                    end
                end)
                pcall(function()
                    if self.miniGameRemote then
                        self.miniGameRemote:InvokeServer(-0.75, 1.0)
                    end
                end)
                pcall(function()
                    if self.finishRemote then
                        self.finishRemote:FireServer()
                    end
                end)
            end)
        end
    end

    function FishItV2:Initialize()
        local ok, err = pcall(function()
            local packages = ReplicatedStorage:FindFirstChild("Packages") or ReplicatedStorage
            local index = packages and packages:FindFirstChild("_Index")
            local netContainer
            
            if index and index:FindFirstChild("sleitnick_net@0.2.0") then
                netContainer = index["sleitnick_net@0.2.0"].net
            else
                if ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages._Index then
                    for _,child in ipairs(ReplicatedStorage.Packages._Index:GetChildren()) do
                        if child:FindFirstChild("net") then
                            netContainer = child.net
                            break
                        end
                    end
                end
            end
            
            self.net = netContainer
            if not self.net then error("Container 'net' tidak ditemukan") end
            
            self.equipRemote = findRemote(self.net, "RE/EquipToolFromHotbar", "RE/EquipRodSkin", "RE/EquipTool", "RE/Equip")
            self.chargeRemote = findRemote(self.net, "RF/ChargeFishingRod", "RF/ChargeRod", "RF/Charge")
            self.miniGameRemote = findRemote(self.net, "RF/RequestFishingMinigameStarted", "RF/RequestFishingMinigame", "RF/StartFishingMinigame")
            self.finishRemote = findRemote(self.net, "RE/FishingCompleted", "RE/FinishFishing", "RE/FishingComplete")
            
            if not (self.equipRemote and self.chargeRemote and self.miniGameRemote and self.finishRemote) then
                error("Remote fishing tidak lengkap")
            end

            -- 🔥 PRELOAD GILA-GILAAN
            self:InsanePreload()
        end)
        
        if not ok then
            updateStatus("ERROR: " .. tostring(err))
            return false
        end
        self.isInitialized = true
        return true
    end

    -- 🔥 FUNGSI CATCH GILA-GILAAN - BYPASS ALL
    function FishItV2:InsaneCatch()
        if not self.autofishV2 then return end
        
        -- 🔥 BYPASS SEMUA LIMIT - EKSEKUSI LANGSUNG TANPA PENCECKAN
        pcall(function() self.equipRemote:FireServer(1) end)
        pcall(function() self.chargeRemote:InvokeServer(workspace:GetServerTimeNow()) end)
        pcall(function() self.miniGameRemote:InvokeServer(-0.7499996423721313, 1.0) end)
        pcall(function() self.finishRemote:FireServer() end)
        
        self.castCount = self.castCount + 1
    end

    -- 🔥 FUNGSI MEGA SPAM GILA-GILAAN
    function FishItV2:InsaneSpam()
        if not self.autofishV2 then return end
        
        -- 🔥 SPAM LEVEL GILA: 50x PER FRAME
        for i = 1, self.spamLevel do
            self:InsaneCatch()
        end
        
        -- 🔥 EXTRA SPAM UNTUK MEMASTIKAN SERVER KEWALAHAN
        for i = 1, 25 do
            task.spawn(function() self:InsaneCatch() end)
        end
        
        -- 🔥 ULTRA SPAM UNTUK MAXIMUM PRESSURE
        for i = 1, 15 do
            self:InsaneCatch()
        end
    end

    function FishItV2:Start()
        if self.autofishV2 then return end
        if not self.isInitialized and not self:Initialize() then return end
        self.autofishV2 = true
        self.castCount = 0
        self.lastUpdate = tick()
        
        -- 🔥 KILL ALL ANIMATIONS UNTUK MAX SPEED
        self:SetAnimationState(false)
        
        -- 🔥 QUADRUPLE LOOP SYSTEM - BYPASS ALL LIMITS
        
        -- LOOP 1: Heartbeat - Main Spam
        self.fishingLoop = RunService.Heartbeat:Connect(function()
            if self.autofishV2 then
                self:InsaneSpam()
            end
        end)
        
        -- LOOP 2: Stepped - Extra Spam
        self.steppedLoop = RunService.Stepped:Connect(function()
            if self.autofishV2 then
                for i = 1, 20 do
                    self:InsaneCatch()
                end
            end
        end)
        
        -- LOOP 3: RenderStepped - Ultra Spam
        self.renderLoop = RunService.RenderStepped:Connect(function()
            if self.autofishV2 then
                for i = 1, 15 do
                    self:InsaneCatch()
                end
            end
        end)
        
        -- LOOP 4: PostSimulation - Final Spam
        self.postSimulationLoop = RunService.PostSimulation:Connect(function()
            if self.autofishV2 then
                for i = 1, 10 do
                    self:InsaneCatch()
                end
            end
        end)
        
        -- 🔥 PERFORMANCE MONITOR GILA
        local monitorLoop = RunService.Heartbeat:Connect(function()
            if self.autofishV2 and tick() - self.lastUpdate >= 1 then
                local castsPerSecond = self.castCount
                updateStatus("🤯 SPEED: " .. castsPerSecond .. " casts/second - INSANE MODE")
                self.castCount = 0
                self.lastUpdate = tick()
            end
        end)
        
        updateStatus("🚀 AUTO FISH GILA-GILAAN AKTIF!")
        updateStatus("🔥 " .. (self.spamLevel + 25 + 15 + 20 + 15 + 10) .. "x casts per cycle!")
    end

    function FishItV2:Stop()
        self.autofishV2 = false
        if self.fishingLoop then
            self.fishingLoop:Disconnect()
            self.fishingLoop = nil
        end
        if self.steppedLoop then
            self.steppedLoop:Disconnect()
            self.steppedLoop = nil
        end
        if self.renderLoop then
            self.renderLoop:Disconnect()
            self.renderLoop = nil
        end
        if self.postSimulationLoop then
            self.postSimulationLoop:Disconnect()
            self.postSimulationLoop = nil
        end
        self:SetAnimationState(true)
        updateStatus("Auto Fish dimatikan!")
    end

    -- ================================================================================= --
    --[[ BAGIAN 9: PLATFORM FOLLOW SYSTEM ]]
    -- ================================================================================= --

    local platformFollowConnection = RunService.Heartbeat:Connect(function()
        if PlatformSystem.CurrentPlatform then
            PlatformSystem:FollowCharacter()
        end
    end)

    updateStatus("✅ Semua sistem utama berhasil di-load!")
end

-- ================================================================================= --
--[[ BAGIAN 10: BUAT UI RAYFIELD ]]
-- ================================================================================= --

if Rayfield and LoadedRayfield then
    print("✅ Rayfield berhasil di-load, membuat UI...")
    
    local Window = Rayfield:CreateWindow({ 
        Name = "🎣 Fish It Helper - INSANE MODE", 
        LoadingTitle = "Loading Insane Mode Features",
        LoadingSubtitle = "Key: " .. string.sub(KeySystem.Key, 1, 8) .. "...",
        Theme = "Default",
        ToggleUIKeybind = "K"
    })

    -- Load sistem utama terlebih dahulu
    loadMainSystems()

    -- TAB: UTILITIES
    local UtilitiesTab = Window:CreateTab("Utilities")
    UtilitiesTab:CreateLabel("🔑 Premium Key: " .. string.sub(KeySystem.Key, 1, 12) .. "...")

    -- Anti AFK
    UtilitiesTab:CreateLabel("Anti AFK System")
    UtilitiesTab:CreateToggle({ 
        Name = "🔄 Anti AFK", 
        CurrentValue = false, 
        Flag = "AntiAFKToggle", 
        Callback = function(Value) 
            if Value then AntiAFK:Start() else AntiAFK:Stop() end 
        end 
    })

    -- Platform System
    UtilitiesTab:CreateLabel("Platform System")
    UtilitiesTab:CreateToggle({ 
        Name = "🔼 Auto Platform", 
        CurrentValue = false, 
        Flag = "AutoPlatformToggle", 
        Callback = function(Value) 
            if Value then PlatformSystem:CreatePlatform() else PlatformSystem:RemovePlatform() end 
        end 
    })

    UtilitiesTab:CreateButton({
        Name = "🔼 Spawn Platform Sekarang",
        Callback = function() PlatformSystem:CreatePlatform() end
    })

    UtilitiesTab:CreateButton({
        Name = "❌ Hapus Platform", 
        Callback = function() PlatformSystem:RemovePlatform() end
    })

    -- Teleport System
    UtilitiesTab:CreateLabel("Teleport System")
    local playersDropdown = UtilitiesTab:CreateDropdown({
        Name = "👥 Pilih Player",
        Options = TeleportSystem:GetPlayers(),
        CurrentValue = "",
        Flag = "PlayersDropdown",
        Callback = function(Option)
            if Option[1] ~= "" then TeleportSystem:TeleportToPlayer(Option[1]) end
        end
    })

    UtilitiesTab:CreateButton({
        Name = "🔄 Refresh Players List",
        Callback = function()
            playersDropdown:Set(TeleportSystem:GetPlayers())
            updateStatus("Players list diperbarui!")
        end
    })

    UtilitiesTab:CreateInput({
        Name = "🎯 Teleport ke Player",
        PlaceholderText = "Masukkan nama player",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text)
            if Text and Text ~= "" then TeleportSystem:TeleportToPlayer(Text) end
        end
    })

    -- TAB: FISH IT (VERSI GILA-GILAAN)
    local FishItTab = Window:CreateTab("🎣 Fish It")

    FishItTab:CreateLabel("🤯 INSANE MODE FISHING")
    
    FishItTab:CreateToggle({ 
        Name = "🎣 AUTO FISH - INSANE MODE", 
        CurrentValue = false, 
        Flag = "AutoFishV2Toggle", 
        Callback = function(Value) 
            if Value then 
                FishItV2:Start()
            else 
                FishItV2:Stop()
            end 
        end 
    })

    FishItTab:CreateToggle({ 
        Name = "🎯 PERFECT CAST", 
        CurrentValue = true, 
        Flag = "PerfectCastV2Toggle", 
        Callback = function(Value) 
            FishItV2.perfectCastV2 = Value 
            updateStatus("Perfect Cast: " .. (Value and "ON" or "OFF")) 
        end 
    })

    -- 🔥 SLIDER SPAM LEVEL GILA-GILAAN
    FishItTab:CreateSlider({
        Name = "🔥 Insane Spam Level",
        Range = {10, 100},
        Increment = 5,
        Suffix = "x",
        CurrentValue = 50,
        Flag = "SpamLevelSlider",
        Callback = function(Value)
            FishItV2.spamLevel = Value
            updateStatus("Spam Level: " .. Value .. "x per frame - INSANE!")
        end,
    })

    FishItTab:CreateLabel("⚡ INSANE SETTINGS")
    FishItTab:CreateToggle({
        Name = "🚫 Kill All Animations",
        CurrentValue = true,
        Flag = "NoAnimationToggle",
        Callback = function(Value)
            FishItV2.noAnimation = Value
            if Value then
                FishItV2:SetAnimationState(false)
                updateStatus("Animations: KILLED - Maximum Speed")
            else
                FishItV2:SetAnimationState(true)
                updateStatus("Animations: Enabled")
            end
        end
    })

    FishItTab:CreateButton({
        Name = "🔧 Insane Preload Remotes",
        Callback = function()
            FishItV2:InsanePreload()
            updateStatus("✅ Remotes insane preloaded!")
        end
    })

    FishItTab:CreateButton({
        Name = "🔄 Reinitialize System",
        Callback = function()
            FishItV2.isInitialized = false
            if FishItV2:Initialize() then
                updateStatus("✅ System reinitialized!")
            else
                updateStatus("❌ Gagal initialize system")
            end
        end
    })

    -- TAB: STATS
    local StatsTab = Window:CreateTab("📊 Live Stats")
    StatsTab:CreateLabel("📈 REAL-TIME PERFORMANCE")
    StatsTab:CreateLabel("Casts/Second: Calculating...")
    StatsTab:CreateLabel("Spam Level: 50x per frame")
    StatsTab:CreateLabel("Total Loops: 4 Active")
    StatsTab:CreateLabel("Status: INSANE MODE")
    
    StatsTab:CreateLabel("")
    StatsTab:CreateLabel("🤯 INSANE FEATURES")
    StatsTab:CreateLabel("• Quadruple Loop System")
    StatsTab:CreateLabel("• 100x Preload Remotes")
    StatsTab:CreateLabel("• Bypass All Limits")
    StatsTab:CreateLabel("• Maximum Server Pressure")
    StatsTab:CreateLabel("• No Safety Checks")

    updateStatus("🚀 FISH IT HELPER READY! - INSANE MODE ACTIVATED")
end

-- ================================================================================= --
--[[ BAGIAN 11: FALLBACK UI JIKA RAYFIELD GAGAL ]]
-- ================================================================================= --

function createFallbackUI()
    local CoreGui = game:GetService("CoreGui")
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FishItHelper_FallbackUI"
    ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 400, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = MainFrame

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    TitleBar.Parent = MainFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = TitleBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "🎣 Fish It Helper - INSANE MODE"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar

    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -20, 1, -60)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 50)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.ScrollBarThickness = 6
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
    ScrollFrame.Parent = MainFrame

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 8)
    UIListLayout.Parent = ScrollFrame

    -- Auto Fish Toggle
    local fishToggle = Instance.new("TextButton")
    fishToggle.Size = UDim2.new(1, 0, 0, 40)
    fishToggle.BackgroundColor3 = Color3.fromRGB(65, 65, 90)
    fishToggle.Text = "🎣 Auto Fish INSANE: OFF"
    fishToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    fishToggle.Font = Enum.Font.GothamBold
    fishToggle.TextSize = 14
    fishToggle.Parent = ScrollFrame

    local fishCorner = Instance.new("UICorner")
    fishCorner.CornerRadius = UDim.new(0, 8)
    fishCorner.Parent = fishToggle

    fishToggle.MouseButton1Click:Connect(function()
        if FishItV2.autofishV2 then
            FishItV2:Stop()
            fishToggle.Text = "🎣 Auto Fish INSANE: OFF"
            fishToggle.BackgroundColor3 = Color3.fromRGB(65, 65, 90)
        else
            FishItV2:Start()
            fishToggle.Text = "🎣 Auto Fish INSANE: ON"
            fishToggle.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        end
    end)

    -- Anti AFK Toggle
    local afkToggle = Instance.new("TextButton")
    afkToggle.Size = UDim2.new(1, 0, 0, 40)
    afkToggle.BackgroundColor3 = Color3.fromRGB(65, 65, 90)
    afkToggle.Text = "🔄 Anti AFK: OFF"
    afkToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    afkToggle.Font = Enum.Font.GothamBold
    afkToggle.TextSize = 14
    afkToggle.Parent = ScrollFrame

    local afkCorner = Instance.new("UICorner")
    afkCorner.CornerRadius = UDim.new(0, 8)
    afkCorner.Parent = afkToggle

    afkToggle.MouseButton1Click:Connect(function()
        if AntiAFK.Enabled then
            AntiAFK:Stop()
            afkToggle.Text = "🔄 Anti AFK: OFF"
            afkToggle.BackgroundColor3 = Color3.fromRGB(65, 65, 90)
        else
            AntiAFK:Start()
            afkToggle.Text = "🔄 Anti AFK: ON"
            afkToggle.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        end
    end)

    -- Platform Buttons
    local platformBtn = Instance.new("TextButton")
    platformBtn.Size = UDim2.new(1, 0, 0, 40)
    platformBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 90)
    platformBtn.Text = "🔼 Spawn Platform"
    platformBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    platformBtn.Font = Enum.Font.GothamBold
    platformBtn.TextSize = 14
    platformBtn.Parent = ScrollFrame

    local platformCorner = Instance.new("UICorner")
    platformCorner.CornerRadius = UDim.new(0, 8)
    platformCorner.Parent = platformBtn

    platformBtn.MouseButton1Click:Connect(function()
        PlatformSystem:CreatePlatform()
    end)

    -- Drag functionality
    local dragging = false
    local dragInput, dragStart, startPos

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)

    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    updateStatus("✅ Script berjalan dengan Fallback UI - INSANE MODE!")
end

end

-- ================================================================================= --
--[[ BAGIAN 12: INISIALISASI SCRIPT ]]
-- ================================================================================= --

-- Mulai dengan key input
showSimpleKeyInput()
