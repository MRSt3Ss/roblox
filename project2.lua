-- cp.lua (Versi Update by Bons - dengan Fly dan Gendong toggle)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- UI setup (simple)
local ScreenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "ControlPanelGui"

local function createToggleButton(name, position)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Toggle"
    btn.Text = name .. ": OFF"
    btn.Size = UDim2.new(0, 150, 0, 40)
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.Parent = ScreenGui
    return btn
end

-- Fly Variables
local flyEnabled = false
local flySpeed = 50
local flyBodyVelocity

-- Gendong Variables
local carryEnabled = false
local carriedPlayer = nil
local weldToRoot

-- Create Toggle Buttons
local flyToggle = createToggleButton("Fly", UDim2.new(0, 20, 0, 20))
local carryToggle = createToggleButton("Gendong", UDim2.new(0, 20, 0, 70))

-- Fly Functions
local function enableFly()
    if flyEnabled then return end
    flyEnabled = true
    flyToggle.Text = "Fly: ON"

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.Parent = rootPart

    -- Disable Humanoid Gravity by setting PlatformStand true
    humanoid.PlatformStand = true

    RunService:BindToRenderStep("FlyControl", Enum.RenderPriority.Character.Value, function()
        if not flyEnabled then return end

        local moveVec = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVec = moveVec + workspace.CurrentCamera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVec = moveVec - workspace.CurrentCamera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVec = moveVec - workspace.CurrentCamera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVec = moveVec + workspace.CurrentCamera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVec = moveVec + Vector3.new(0,1,0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveVec = moveVec - Vector3.new(0,1,0)
        end

        flyBodyVelocity.Velocity = moveVec.Unit * flySpeed
        if moveVec.Magnitude == 0 then
            flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
    end)
end

local function disableFly()
    if not flyEnabled then return end
    flyEnabled = false
    flyToggle.Text = "Fly: OFF"

    humanoid.PlatformStand = false

    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end

    RunService:UnbindFromRenderStep("FlyControl")
end

flyToggle.MouseButton1Click:Connect(function()
    if flyEnabled then
        disableFly()
    else
        enableFly()
    end
end)

-- Gendong (Carry) Functions
local function getClosestPlayerToMouse()
    local mouse = localPlayer:GetMouse()
    local closestPlayer = nil
    local shortestDistance = math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local screenPoint = workspace.CurrentCamera:WorldToScreenPoint(player.Character.HumanoidRootPart.Position)
            local mousePos = Vector2.new(mouse.X, mouse.Y)
            local dist = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
            if dist < 100 and dist < shortestDistance then -- threshold 100 px
                closestPlayer = player
                shortestDistance = dist
            end
        end
    end
    return closestPlayer
end

local function carryPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    local targetRoot = targetPlayer.Character.HumanoidRootPart

    -- Create Weld
    weldToRoot = Instance.new("WeldConstraint")
    weldToRoot.Part0 = rootPart
    weldToRoot.Part1 = targetRoot
    weldToRoot.Parent = rootPart

    -- Optional: Set carried player’s humanoid PlatformStand true supaya gak bisa bergerak sendiri
    local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    if targetHumanoid then
        targetHumanoid.PlatformStand = true
    end

    carriedPlayer = targetPlayer
end

local function releasePlayer()
    if weldToRoot then
        weldToRoot:Destroy()
        weldToRoot = nil
    end

    if carriedPlayer and carriedPlayer.Character then
        local targetHumanoid = carriedPlayer.Character:FindFirstChild("Humanoid")
        if targetHumanoid then
            targetHumanoid.PlatformStand = false
        end
    end

    carriedPlayer = nil
end

carryToggle.MouseButton1Click:Connect(function()
    if carryEnabled then
        -- Disable carry
        carryEnabled = false
        carryToggle.Text = "Gendong: OFF"
        releasePlayer()
    else
        -- Enable carry - pilih player terdekat mouse
        local target = getClosestPlayerToMouse()
        if target then
            carryEnabled = true
            carryToggle.Text = "Gendong: ON"
            carryPlayer(target)
        else
            carryToggle.Text = "Gendong: OFF"
            carryEnabled = false
            warn("Tidak ada player dekat mouse untuk digendong.")
        end
    end
end)

-- ** Pertahankan fungsi dan fitur original script cp.lua di sini **
-- Karena gua tidak punya script asli lengkap, lu tinggal gabungin bagian ini sama script cp.lua yang asli.
-- Kalau mau gua bantu gabungin full, kirim script asli lengkap, nanti gua gabungin sekali jadi.

-- Selesai Boss! Script sudah ada tombol Fly dan Gendong toggle.

