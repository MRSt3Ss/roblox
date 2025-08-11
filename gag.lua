--// Pet & Plant Spawner + Duplicator | By Abangmu //--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

--// CONFIG: Tambah list pet/tanaman di sini
local SpawnList = {
    "CuteDog",      -- contoh nama pet di game
    "GoldenCat",
    "MagicTree",
    "Sunflower",
    "DragonPet"
}

--// RemoteEvent name (ubah sesuai game)
local SpawnRemote = ReplicatedStorage:FindFirstChild("SpawnPet") or ReplicatedStorage:FindFirstChild("SpawnPlant")

--// Buat UI Mewah
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/UI-Libs/main/Kavo%20UI%20Library.lua"))()
local window = library.CreateLib("Pet & Plant Spawner | Abangmu", "Ocean")

local mainTab = window:NewTab("Spawner")
local spawnSection = mainTab:NewSection("Spawn & Duplicate")

local selectedPet = SpawnList[1]
local spawnAmount = 1

spawnSection:NewDropdown("Pilih Pet/Tanaman", "Pilih yang mau di-spawn", SpawnList, function(v)
    selectedPet = v
end)

spawnSection:NewSlider("Jumlah Spawn", "Berapa banyak spawn/duplicate", 50, 1, function(v)
    spawnAmount = v
end)

spawnSection:NewButton("SPAWN Sekarang", "Spawn pet/tanaman yang dipilih", function()
    if not SpawnRemote then
        warn("⚠️ Remote Spawn tidak ditemukan!")
        return
    end
    for i = 1, spawnAmount do
        pcall(function()
            SpawnRemote:FireServer(selectedPet) -- Param sesuai game
        end)
        task.wait(0.1) -- delay kecil biar aman
    end
end)

spawnSection:NewButton("DUPLICATE yang Ada", "Clone pet/tanaman di map", function()
    local found = Workspace:FindFirstChild(selectedPet, true)
    if found then
        for i = 1, spawnAmount do
            pcall(function()
                local clone = found:Clone()
                clone.Parent = Workspace
                clone.Position = LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 3, i * 2)
            end)
            task.wait(0.05)
        end
    else
        warn("⚠️ Tidak menemukan pet/tanaman bernama: "..selectedPet)
    end
end)

spawnSection:NewButton("KILL Semua Spawn", "Hapus semua pet/tanaman hasil spawn", function()
    for _, obj in ipairs(Workspace:GetChildren()) do
        for _, name in ipairs(SpawnList) do
            if obj.Name == name then
                obj:Destroy()
            end
        end
    end
end)

--// Anti-Mod Join (Opsional)
Players.PlayerAdded:Connect(function(plr)
    if plr:GetRankInGroup(123456) >= 200 then -- ganti group ID sesuai game
        library:Close()
        warn("⚠️ Moderator/Admin terdeteksi, UI ditutup!")
    end
end)
