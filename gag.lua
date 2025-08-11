--// OrionLib UI (PC Ready) | Simulasi Pet/Tanaman Spawner //--

local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()
local Window = OrionLib:MakeWindow({Name = "Pet & Plant Spawner | SIMULASI", HidePremium = false, SaveConfig = false, ConfigFolder = "PetPlantSpawner"})

-- Data simulasi
local SpawnList = {"CuteDog", "GoldenCat", "MagicTree", "Sunflower", "DragonPet"}
local selectedPet = SpawnList[1]
local spawnAmount = 1

-- Tab & Section
local Tab = Window:MakeTab({
	Name = "Spawner",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

Tab:AddDropdown({
	Name = "Pilih Pet/Tanaman",
	Default = SpawnList[1],
	Options = SpawnList,
	Callback = function(Value)
		selectedPet = Value
		print("[SIMULASI] Pilih Pet/Tanaman:", selectedPet)
	end    
})

Tab:AddSlider({
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

Tab:AddButton({
	Name = "SPAWN Sekarang",
	Callback = function()
		print("[SIMULASI] Spawn:", selectedPet, "Sebanyak:", spawnAmount)
	end
})

Tab:AddButton({
	Name = "DUPLICATE yang Ada",
	Callback = function()
		print("[SIMULASI] Duplicate:", selectedPet, "Sebanyak:", spawnAmount)
	end
})

Tab:AddButton({
	Name = "KILL Semua Spawn",
	Callback = function()
		print("[SIMULASI] Semua hasil spawn dihapus.")
	end
})

OrionLib:Init()
