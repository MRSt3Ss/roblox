--[[
    Fish It - Auto Farm dengan Key System dari GitHub
    Validasi key via file: https://raw.githubusercontent.com/MRSt3Ss/BonsHub2/main/database.txt
    
    UPDATED BY GEMINI (V13 - "REVERSED-ASYNC" MODE):
    - Menggunakan Core V11/V12 (UI & Fitur Lengkap).
    - Membalik urutan loop spam untuk menghilangkan 'jeda' antara lempar dan narik.
    - Urutan baru: Lempar (Async) -> Narik (Instan) -> Cas (Menunggu).
    - Jeda server yang tidak bisa dihindari kini dipindah ke *setelah* narik.
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
    Fish It - Auto Farm (Versi REVERSED-ASYNC V13)
    OPTIMASI: V11 Core + V13 Reversed-Async Loop
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
            Rayfield:Notify({Title = "Notifikasi", Content = msg, Duration = 3})
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
            if self.Enabled and tick() % 25 < 0.1 then
                pcall(function()
                    VirtualInputManager:SendMouseMoveEvent(5, 5, game:GetService("CoreGui"))
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.wait(0.01)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    VirtualInputManager:SendMouseMoveEvent(-5, -5, game:GetService("CoreGui"))
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
        PlatformSize = Vector3.new(8, 1, 8)
    }

    function PlatformSystem:CreatePlatform()
        self:RemovePlatform()
        
        local char = localPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        local hrp = char.HumanoidRootPart
        local position = hrp.Position - Vector3.new(0, 4, 0)
        
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
            local position = hrp.Position - Vector3.new(0, 4, 0)
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
    --[[ BAGIAN 8: LOGIKA INTI "FISH IT" (V13 - REVERSED ASYNC) ]]
    -- ================================================================================= --

    FishItV2 = {
        isInitialized = false,
        autofishV2 = false,
        perfectCastV2 = true,
        noAnimation = false,    
        charAddedConn = nil, -- Koneksi untuk animasi
        net = nil,
        finishRemote = nil,
        miniGameRemote = nil,
        chargeRemote = nil,
        equipRemote = nil
    }

    function FishItV2:SetAnimationState(enabled)
        local char = localPlayer.Character
        if not char then return end
        pcall(function()
            local animateScript = char:FindFirstChild("Animate")
            if animateScript then animateScript.Enabled = enabled end
        end)
        if not enabled then
            pcall(function()
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local animator = humanoid:FindFirstChildOfClass("Animator")
                    if animator then
                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            track:Stop()
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

    -- 🔥 FUNGSI PRELOAD REMOTES (Optimasi V10)
    function FishItV2:PreloadRemotes()
        if not self.net then return end
        pcall(function()
            -- Preload semua remotes untuk menghindari delay pertama ("warm-up")
            for _, remote in pairs({self.chargeRemote, self.miniGameRemote, self.finishRemote}) do
                if remote then
                    pcall(function() 
                        if remote:IsA("RemoteFunction") then
                            remote:InvokeServer()
                        else
                            remote:FireServer()
                        end
                    end)
                end
            end
        end)
        print("🔥 Remotes Preloaded/Warmed-up!")
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

            -- 🔥 PRELOAD REMOTES SEKALI
            self:PreloadRemotes()
        end)
        
        if not ok then
            updateStatus("ERROR: " .. tostring(err))
            return false
        end
        self.isInitialized = true
        return true
    end


    -- [[ !!! FUNGSI START V13 (REVERSED-ASYNC) !!! ]]
    function FishItV2:Start()
        if self.autofishV2 then return end
        if not self.isInitialized and not self:Initialize() then return end
        self.autofishV2 = true
        
        if self.charAddedConn then self.charAddedConn:Disconnect() self.charAddedConn = nil end
        if self.noAnimation then
            self:SetAnimationState(false)
        end
        -- Koneksi untuk mematikan animasi saat respawn
        self.charAddedConn = localPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            if self.autofishV2 and self.noAnimation then
                self:SetAnimationState(false)
            end
        end)

        -- Equip pancing SATU KALI di luar loop
        if self.equipRemote then
            pcall(function() self.equipRemote:FireServer(1) end)
            updateStatus("Pancing di-equip... Memulai REVERSED-ASYNC (V13).")
        end
        
        task.spawn(function()
            while self.autofishV2 do
                
                -- [[ PERUBAHAN V13: 'chargeRemote' (yg menunggu) dipindah ke AKHIR ]]
                local ok, err = pcall(function()    
                    
                    -- 1. Minigame (Cast/Lempar) - (Jalankan di thread baru AGAR TIDAK DITUNGGU)
                    if self.miniGameRemote then
                        task.spawn(function()
                            local x, y
                            if self.perfectCastV2 then
                                x = -0.7499996423721313 + (math.random(-500, 500) / 10000000)
                                y = 1 + (math.random(-500, 500) / 10000000)
                            else
                                x = math.random(-1000, 1000) / 1000; y = math.random(0, 1000) / 1000
                            end
                            -- pcall di dalam task.spawn agar error di thread ini tidak menghentikan thread utama
                            pcall(function() self.miniGameRemote:InvokeServer(x, y) end)
                        end)
                    end
                    
                    -- 2. Finish (Narik) - (Dijalankan LANGSUNG setelah 'Cast' dimulai, tanpa menunggu)
                    if self.finishRemote then
                        pcall(function() self.finishRemote:FireServer() end)
                    end

                    -- 3. Charge (Harus ditunggu agar server siap untuk loop berikutnya)
                    -- JEDA (BOTTLENECK) SEKARANG ADA DI SINI, SETELAH AKSI SELESAI
                    if self.chargeRemote then
                         pcall(function() self.chargeRemote:InvokeServer() end)
                    end
                    
                end) -- pcall ends
                
                if not ok then
                    -- Jeda SANGAT singkat HANYA jika ada error di pcall utama
                    task.wait(0.01)
                end
                
                -- TIDAK ADA task.wait() di sini.
            end
        end)
        updateStatus("🚀 AUTO FISH REVERSED-ASYNC (V13) AKTIF!")
    end
    -- [[ !!! AKHIR FUNGSI START V13 !!! ]]


    function FishItV2:Stop()
        self.autofishV2 = false
        self:SetAnimationState(true) -- Kembalikan animasi
        if self.charAddedConn then
            self.charAddedConn:Disconnect()
            self.charAddedConn = nil
        end
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
        Name = "🎣 Fish It Helper - REVERSED ASYNC (V13)", 
        LoadingTitle = "Loading Reversed-Async Features",
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

    -- TAB: FISH IT (VERSI REVERSED ASYNC)
    local FishItTab = Window:CreateTab("🎣 Fish It")

    FishItTab:CreateLabel("🚀 REVERSED-ASYNC SPAM (V13)")
    FishItTab:CreateLabel("⚠️ Jeda server dipindah ke *setelah* narik.")
    FishItTab:CreateDivider()
    
    FishItTab:CreateToggle({ 
        Name = "🎣 AUTO FISHING - REVERSED ASYNC", 
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
    
    FishItTab:CreateDivider()

    FishItTab:CreateLabel("⚙️ Advanced Settings")
    FishItTab:CreateDropdown({
        Name = "🎭 Animation Mode",
        Options = {"Normal", "No Animation - Less Lag"},
        CurrentValue = "Normal",
        Flag = "AnimationDropdown",
        Callback = function(Option)
            local selected = Option[1] 
            FishItV2.noAnimation = (selected == "No Animation - Less Lag")
            if FishItV2.noAnimation then
                FishItV2:SetAnimationState(false)
                updateStatus("Animation: OFF - Less Lag")
            else
                FishItV2:SetAnimationState(true)
                updateStatus("Animation: ON")
            end
        end
    })

    FishItTab:CreateButton({
        Name = "🔧 Preload Remotes (Warm-up)",
        Callback = function()
            FishItV2:PreloadRemotes()
            updateStatus("✅ Remotes sudah di-preload!")
        end
    })

    FishItTab:CreateButton({
        Name = "🔄 Reinitialize Fishing System",
        Callback = function()
            FishItV2.isInitialized = false
            if FishItV2:Initialize() then
                updateStatus("✅ Fishing system di-initialize ulang!")
            else
                updateStatus("❌ Gagal initialize fishing system")
            end
        end
    })

    -- TAB: INFO
    local InfoTab = Window:CreateTab("📊 Info")
    InfoTab:CreateLabel("🎯 FITUR REVERSED-ASYNC (V13)")
    InfoTab:CreateLabel("• Urutan: Lempar (Async) -> Narik -> Cas (Jeda)")
    InfoTab:CreateLabel("• Menghilangkan 'jeda' *sebelum* narik")
    InfoTab:CreateLabel("• Core spam V11 (while true loop)")
    InfoTab:CreateLabel("• Preload Remotes (Warm-up) Optimization")

    updateStatus("🚀 FISH IT HELPER READY! - REVERSED-ASYNC (V13)")
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
    TitleLabel.Text = "🎣 Fish It Helper - REVERSED ASYNC (V13)"
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
    fishToggle.Text = "🎣 Auto Fish REVERSED-ASYNC: OFF"
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
            fishToggle.Text = "🎣 Auto Fish REVERSED-ASYNC: OFF"
            fishToggle.BackgroundColor3 = Color3.fromRGB(65, 65, 90)
        else
            FishItV2:Start()
            fishToggle.Text = "🎣 Auto Fish REVERSED-ASYNC: ON"
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

    updateStatus("✅ Script berjalan dengan Fallback UI - REVERSED ASYNC (V13)!")
end

end

-- ================================================================================= --
--[[ BAGIAN 12: INISIALISASI SCRIPT ]]
-- ================================================================================= --

-- Mulai dengan key input
showSimpleKeyInput()
