-- Tunggu dulu biar services kebuka
task.wait(1)

-- Load OrionLib
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

-- Buat Window
local Window = OrionLib:MakeWindow({
    Name = "Pet & Plant Spawner | SIMULASI",
    HidePremium = false,
    SaveConfig = false,
    IntroEnabled = true,
    ConfigFolder = "PetPlantSpawner"
})

-- Data Simulasi
local SpawnList = {"CuteDog", "GoldenCat", "MagicTree", "Sunflower", "DragonPet"}
local selectedPet = SpawnList[1]
local spawnAmount = 1

-- Buat Tab
local MainTab = Window:MakeTab({
    Name = "Spawner",
    Icon = "rbxassetid://6034996695",
    PremiumOnly = false
})

-- Dropdown
MainTab:AddDropdown({
    Name = "Pilih Pet/Tanaman",
    Default = SpawnList[1],
    Options = SpawnList,
    Callback = function(Value)
        selectedPet = Value
        print("[SIMULASI] Pilih Pet/Tanaman:", selectedPet)
    end
})

-- Slider
MainTab:AddSlider({
    Name = "Jumlah Spawn",
    Min = 1,
    Max = 50,
    Default = 1,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "x",
    Callback = function(Value)
        spawnAmount = Value
        print("[SIMULASI] Jumlah Spawn:", spawnAmount)
    end
})

-- Tombol Spawn
MainTab:AddButton({
    Name = "SPAWN Sekarang",
    Callback = function()
        print("[SIMULASI] Spawn:", selectedPet, "Sebanyak:", spawnAmount)
    end
})

-- Tombol Duplicate
MainTab:AddButton({
    Name = "DUPLICATE yang Ada",
    Callback = function()
        print("[SIMULASI] Duplicate:", selectedPet, "Sebanyak:", spawnAmount)
    end
})

-- Tombol Kill All
MainTab:AddButton({
    Name = "KILL Semua Spawn",
    Callback = function()
        print("[SIMULASI] Semua hasil spawn dihapus.")
    end
})

-- Inisialisasi GUI
OrionLib:Init()
