--// GUI SIMULASI | Pet & Plant Spawner Test //--

-- Load UI Library (Kavo)
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/UI-Libs/main/Kavo%20UI%20Library.lua"))()
local window = library.CreateLib("Pet & Plant Spawner | SIMULASI", "Ocean")

-- Tab & Section
local mainTab = window:NewTab("Spawner")
local spawnSection = mainTab:NewSection("Spawn & Duplicate")

-- Data simulasi
local SpawnList = {"CuteDog", "GoldenCat", "MagicTree", "Sunflower", "DragonPet"}
local selectedPet = SpawnList[1]
local spawnAmount = 1

spawnSection:NewDropdown("Pilih Pet/Tanaman", "Pilih yang mau di-spawn", SpawnList, function(v)
    selectedPet = v
    print("[SIMULASI] Pilih Pet/Tanaman:", selectedPet)
end)

spawnSection:NewSlider("Jumlah Spawn", "Berapa banyak spawn/duplicate", 50, 1, function(v)
    spawnAmount = v
    print("[SIMULASI] Jumlah Spawn:", spawnAmount)
end)

spawnSection:NewButton("SPAWN Sekarang", "Spawn pet/tanaman yang dipilih", function()
    print("[SIMULASI] Spawn:", selectedPet, "Sebanyak:", spawnAmount)
end)

spawnSection:NewButton("DUPLICATE yang Ada", "Clone pet/tanaman di map", function()
    print("[SIMULASI] Duplicate:", selectedPet, "Sebanyak:", spawnAmount)
end)

spawnSection:NewButton("KILL Semua Spawn", "Hapus semua pet/tanaman hasil spawn", function()
    print("[SIMULASI] Semua pet/tanaman hasil spawn dihapus.")
end)
