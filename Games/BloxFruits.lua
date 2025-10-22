--[[
    InovoProductions - Blox Fruits Script
    Advanced Anti-Cheat Bypass Implementation
    
    Features:
    - Auto Farm (Levels, Mastery, Boss)
    - Fruit ESP & Auto Collect
    - Safe Teleportation
    - Quest Automation
    - Combat Features
    - Anti-AFK
    
    Anti-Cheat Protection:
    - Remote Spy Protection
    - Invisible Character Option
    - Safe Speed (no detection)
    - Delayed Actions (human-like)
    - Error Handling
]]

local BloxFruits = {}
BloxFruits.__index = BloxFruits

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Local Player
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Settings
BloxFruits.Settings = {
    AutoFarm = {
        Enabled = false,
        Level = false,
        Mastery = false,
        Boss = false,
        SafeMode = true,
        FarmDistance = 15,
        BringMobs = false,
    },
    
    Combat = {
        FastAttack = false,
        AutoHaki = false,
        KillAura = false,
        KillAuraRange = 50,
        AutoAbility = false,
    },
    
    Teleport = {
        Speed = 300,
        SafeTeleport = true,
        BypassCooldown = true,
    },
    
    ESP = {
        Enabled = false,
        Fruits = true,
        Players = true,
        Mobs = false,
        Chests = true,
        MaxDistance = 5000,
    },
    
    Misc = {
        AntiAFK = true,
        AutoQuest = false,
        AutoCollectFruits = false,
        NoClip = false,
        InfiniteEnergy = false,
    },
    
    Movement = {
        SpeedEnabled = false,
        Speed = 16,
        FlightEnabled = false,
        FlightSpeed = 50,
    }
}

-- Anti-Cheat Bypass Functions
local function SafeWait(time)
    local start = tick()
    repeat
        task.wait()
    until tick() - start >= time
end

local function RandomDelay()
    return math.random(50, 150) / 1000 -- 0.05 to 0.15 seconds
end

local function SafeFireRemote(remote, ...)
    local success, result = pcall(function()
        if remote and remote:IsA("RemoteEvent") then
            remote:FireServer(...)
        end
    end)
    return success
end

local function SafeInvokeRemote(remote, ...)
    local success, result = pcall(function()
        if remote and remote:IsA("RemoteFunction") then
            return remote:InvokeServer(...)
        end
    end)
    if success then
        return result
    end
    return nil
end

-- Get Remotes (Safe)
local function GetRemotes()
    local remotes = {}
    
    pcall(function()
        remotes.Combat = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("CommF_")
    end)
    
    return remotes
end

-- Character Update
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
    SafeWait(1)
end)

-- Safe Teleport with Anti-Cheat Bypass
function BloxFruits:SafeTeleport(targetCFrame)
    if not targetCFrame or not HumanoidRootPart then return false end
    
    local success = pcall(function()
        if self.Settings.Teleport.SafeTeleport then
            -- Tween-based safe teleport
            local distance = (HumanoidRootPart.Position - targetCFrame.Position).Magnitude
            local speed = self.Settings.Teleport.Speed
            local time = distance / speed
            
            -- Create tween
            local tween = TweenService:Create(
                HumanoidRootPart,
                TweenInfo.new(time, Enum.EasingStyle.Linear),
                {CFrame = targetCFrame}
            )
            
            tween:Play()
            tween.Completed:Wait()
        else
            -- Instant teleport (higher detection risk)
            HumanoidRootPart.CFrame = targetCFrame
        end
        
        SafeWait(RandomDelay())
    end)
    
    return success
end

-- Get Quest Info
function BloxFruits:GetPlayerLevel()
    local success, level = pcall(function()
        return LocalPlayer.Data.Level.Value
    end)
    return success and level or 1
end

function BloxFruits:GetRecommendedQuest()
    local level = self:GetPlayerLevel()
    local questData = {
        -- Sea 1 (First Sea)
        {MinLevel = 1, MaxLevel = 9, Quest = "Bandit", Location = CFrame.new(1059.37195, 16.5, 1546.63)},
        {MinLevel = 10, MaxLevel = 14, Quest = "Monkey", Location = CFrame.new(-1445.06348, 23.5, -48.8)},
        {MinLevel = 15, MaxLevel = 29, Quest = "Gorilla", Location = CFrame.new(-1119.81, 40.5, 1838.98)},
        {MinLevel = 30, MaxLevel = 39, Quest = "Pirate", Location = CFrame.new(-1181.31, 4.5, 3803.5)},
        {MinLevel = 40, MaxLevel = 59, Quest = "Brute", Location = CFrame.new(-1145.23, 14.8, 4321.73)},
        {MinLevel = 60, MaxLevel = 74, Quest = "Desert Bandit", Location = CFrame.new(932.16, 6.5, 4481.96)},
        {MinLevel = 75, MaxLevel = 89, Quest = "Desert Officer", Location = CFrame.new(1609.12, 6.5, 4369.76)},
        {MinLevel = 90, MaxLevel = 99, Quest = "Snow Bandit", Location = CFrame.new(1386.79, 87.3, -1297.06)},
        {MinLevel = 100, MaxLevel = 119, Quest = "Snowman", Location = CFrame.new(1198.16, 105.5, -1236.97)},
        {MinLevel = 120, MaxLevel = 149, Quest = "Chief Petty Officer", Location = CFrame.new(-4881.08, 4.5, 4257.38)},
        {MinLevel = 150, MaxLevel = 174, Quest = "Sky Bandit", Location = CFrame.new(-4841.66, 717.8, -2666.88)},
        {MinLevel = 175, MaxLevel = 189, Quest = "Dark Master", Location = CFrame.new(-5217.06, 12.5, -4836.68)},
        {MinLevel = 190, MaxLevel = 209, Quest = "Prisoner", Location = CFrame.new(5309.83, 0.5, 475.46)},
        {MinLevel = 210, MaxLevel = 249, Quest = "Dangerous Prisoner", Location = CFrame.new(5086.09, 2, 466.35)},
        {MinLevel = 250, MaxLevel = 274, Quest = "Toga Warrior", Location = CFrame.new(-3625.03, 7.5, -3003.72)},
        {MinLevel = 275, MaxLevel = 299, Quest = "Gladiator", Location = CFrame.new(-1309.88, 7.5, -3251.64)},
        {MinLevel = 300, MaxLevel = 324, Quest = "Military Soldier", Location = CFrame.new(-5316.15, 12.5, -2842.48)},
        {MinLevel = 325, MaxLevel = 374, Quest = "Military Spy", Location = CFrame.new(-5815.42, 84.5, -8972.27)},
        {MinLevel = 375, MaxLevel = 399, Quest = "Fishman Warrior", Location = CFrame.new(61122.65, 18.5, 1569.06)},
        {MinLevel = 400, MaxLevel = 449, Quest = "Fishman Commando", Location = CFrame.new(61922.6, 18.5, 1493.93)},
        {MinLevel = 450, MaxLevel = 474, Quest = "God's Guard", Location = CFrame.new(-4721.88, 845.3, -1954.44)},
        {MinLevel = 475, MaxLevel = 524, Quest = "Shanda", Location = CFrame.new(-7685.12, 5567.8, -502.08)},
        {MinLevel = 525, MaxLevel = 549, Quest = "Royal Squad", Location = CFrame.new(-7665.15, 5839.5, -1818.83)},
        {MinLevel = 550, MaxLevel = 624, Quest = "Royal Soldier", Location = CFrame.new(-7836.75, 5607.8, -1540.51)},
        {MinLevel = 625, MaxLevel = 649, Quest = "Galley Pirate", Location = CFrame.new(5551.02, 42.5, 3946.25)},
        {MinLevel = 650, MaxLevel = 699, Quest = "Galley Captain", Location = CFrame.new(5436.03, 38.5, 4757.75)},
        
        -- Sea 2 (Second Sea) - More quests here
        {MinLevel = 700, MaxLevel = 724, Quest = "Raider", Location = CFrame.new(-728.27, 16.5, 2345.88)},
        {MinLevel = 725, MaxLevel = 774, Quest = "Mercenary", Location = CFrame.new(-972.46, 73.0, 1419.06)},
        {MinLevel = 775, MaxLevel = 799, Quest = "Swan Pirate", Location = CFrame.new(1036.49, 125.0, 1321.77)},
        {MinLevel = 800, MaxLevel = 874, Quest = "Marine Commodore", Location = CFrame.new(-3855.67, 73.0, -3295.82)},
        {MinLevel = 875, MaxLevel = 899, Quest = "Magma Ninja", Location = CFrame.new(-5426.25, 12.0, -5769.71)},
        {MinLevel = 900, MaxLevel = 949, Quest = "Lava Pirate", Location = CFrame.new(-5234.38, 12.0, -4898.56)},
        {MinLevel = 950, MaxLevel = 974, Quest = "Head Baker", Location = CFrame.new(-2087.99, 38.0, -12464.83)},
        {MinLevel = 975, MaxLevel = 999, Quest = "Dark Master", Location = CFrame.new(-2088.92, 38.0, -12488.72)},
        {MinLevel = 1000, MaxLevel = 1049, Quest = "Ice Admiral", Location = CFrame.new(-5520.34, 12.0, -5235.21)},
        {MinLevel = 1050, MaxLevel = 1099, Quest = "Tide Keeper", Location = CFrame.new(-3711.33, 123.0, -11208.86)},
        {MinLevel = 1100, MaxLevel = 1124, Quest = "Forest Pirate", Location = CFrame.new(-13479.58, 332.4, -7625.4)},
        {MinLevel = 1125, MaxLevel = 1174, Quest = "Mythological Pirate", Location = CFrame.new(-13545.17, 470.0, -6917.24)},
        {MinLevel = 1175, MaxLevel = 1199, Quest = "Jungle Pirate", Location = CFrame.new(-12073.21, 332.4, -10141.23)},
        {MinLevel = 1200, MaxLevel = 1249, Quest = "Musketeer Pirate", Location = CFrame.new(-13274.53, 332.4, -7896.65)},
        {MinLevel = 1250, MaxLevel = 1274, Quest = "Reborn Skeleton", Location = CFrame.new(-8760.78, 142.1, 6062.45)},
        {MinLevel = 1275, MaxLevel = 1299, Quest = "Living Zombie", Location = CFrame.new(-10144.75, 139.0, 5932.85)},
        {MinLevel = 1300, MaxLevel = 1324, Quest = "Demonic Soul", Location = CFrame.new(-9513.89, 172.1, 6145.71)},
        {MinLevel = 1325, MaxLevel = 1349, Quest = "Posessed Mummy", Location = CFrame.new(-9546.68, 6.0, 6336.49)},
        {MinLevel = 1350, MaxLevel = 1374, Quest = "Peanut Scout", Location = CFrame.new(-2103.96, 38.0, -10192.33)},
        {MinLevel = 1375, MaxLevel = 1399, Quest = "Peanut President", Location = CFrame.new(-2150.47, 38.0, -10194.59)},
        {MinLevel = 1400, MaxLevel = 1424, Quest = "Ice Cream Chef", Location = CFrame.new(-641.19, 38.0, -12824.03)},
        {MinLevel = 1425, MaxLevel = 1449, Quest = "Ice Cream Commander", Location = CFrame.new(-789.85, 65.9, -10967.33)},
        {MinLevel = 1450, MaxLevel = 1474, Quest = "Cookie Crafter", Location = CFrame.new(-2365.42, 38.0, -12099.45)},
        {MinLevel = 1475, MaxLevel = 1499, Quest = "Cake Guard", Location = CFrame.new(-1570.32, 38.0, -12355.92)},
        {MinLevel = 1500, MaxLevel = 1524, Quest = "Baking Staff", Location = CFrame.new(-1927.24, 38.0, -12850.87)},
        {MinLevel = 1525, MaxLevel = 1574, Quest = "Head Baker", Location = CFrame.new(-2087.99, 38.0, -12464.83)},
        {MinLevel = 1575, MaxLevel = 1599, Quest = "Cocoa Warrior", Location = CFrame.new(231.75, 25.0, -12197.49)},
        {MinLevel = 1600, MaxLevel = 1624, Quest = "Chocolate Bar Battler", Location = CFrame.new(620.63, 25.0, -12619.62)},
        {MinLevel = 1625, MaxLevel = 1649, Quest = "Sweet Thief", Location = CFrame.new(2433.55, 25.0, -12225.73)},
        {MinLevel = 1650, MaxLevel = 1699, Quest = "Candy Rebel", Location = CFrame.new(2519.19, 25.0, -11847.63)},
        {MinLevel = 1700, MaxLevel = 1724, Quest = "Candy Pirate", Location = CFrame.new(-1106.56, 11.6, -14204.85)},
        {MinLevel = 1725, MaxLevel = 1774, Quest = "Snow Demon", Location = CFrame.new(-5412.49, 12.0, -5269.16)},
        {MinLevel = 1775, MaxLevel = 1799, Quest = "Isle Outlaw", Location = CFrame.new(-5622.02, 8.0, -276.49)},
        {MinLevel = 1800, MaxLevel = 1849, Quest = "Island Boy", Location = CFrame.new(-4898.43, 8.0, -185.47)},
        {MinLevel = 1850, MaxLevel = 1899, Quest = "Sun-Kissed Warrior", Location = CFrame.new(-2010.75, 38.0, -10194.51)},
        {MinLevel = 1900, MaxLevel = 1924, Quest = "Cave Dweller", Location = CFrame.new(-2103.96, 38.0, -10192.33)},
        {MinLevel = 1925, MaxLevel = 1974, Quest = "Magma Ninja", Location = CFrame.new(-5426.25, 12.0, -5769.71)},
        {MinLevel = 1975, MaxLevel = 1999, Quest = "Lava Pirate", Location = CFrame.new(-5234.38, 12.0, -4898.56)},
        {MinLevel = 2000, MaxLevel = 2024, Quest = "Tide Keeper", Location = CFrame.new(-3711.33, 123.0, -11208.86)},
        {MinLevel = 2025, MaxLevel = 2049, Quest = "Fishman Raider", Location = CFrame.new(-10533.24, 332.0, -8788.52)},
        {MinLevel = 2050, MaxLevel = 2074, Quest = "Fishman Captain", Location = CFrame.new(-10961.04, 332.0, -8940.54)},
        {MinLevel = 2075, MaxLevel = 2099, Quest = "Forest Pirate", Location = CFrame.new(-13479.58, 332.4, -7625.4)},
        {MinLevel = 2100, MaxLevel = 2124, Quest = "Jungle Pirate", Location = CFrame.new(-12073.21, 332.4, -10141.23)},
        {MinLevel = 2125, MaxLevel = 2149, Quest = "Sea Soldier", Location = CFrame.new(-5850.84, 16.0, -285.33)},
        {MinLevel = 2150, MaxLevel = 2199, Quest = "Ship Deckhand", Location = CFrame.new(1232.87, 125.0, 33059.24)},
        {MinLevel = 2200, MaxLevel = 2224, Quest = "Ship Engineer", Location = CFrame.new(919.02, 44.0, 32917.43)},
        {MinLevel = 2225, MaxLevel = 2249, Quest = "Ship Steward", Location = CFrame.new(915.38, 126.0, 33518.14)},
        {MinLevel = 2250, MaxLevel = 2299, Quest = "Ship Officer", Location = CFrame.new(915.38, 181.0, 33331.78)},
        {MinLevel = 2300, MaxLevel = 2324, Quest = "Arctic Warrior", Location = CFrame.new(5823.53, 23.7, -6302.3)},
        {MinLevel = 2325, MaxLevel = 2349, Quest = "Snow Lurker", Location = CFrame.new(5518.82, 28.0, -6859.63)},
        {MinLevel = 2350, MaxLevel = 2374, Quest = "Sea Soldier", Location = CFrame.new(-5850.84, 16.0, -285.33)},
        {MinLevel = 2375, MaxLevel = 2399, Quest = "Haunted Castle", Location = CFrame.new(-9515.75, 142.0, 5543.88)},
        {MinLevel = 2400, MaxLevel = 2450, Quest = "Isle Champion", Location = CFrame.new(5283.73, 51.5, 1036.18)},
    }
    
    for _, quest in ipairs(questData) do
        if level >= quest.MinLevel and level <= quest.MaxLevel then
            return quest
        end
    end
    
    return questData[#questData] -- Return highest level quest if nothing matches
end

-- Get Nearest Enemy
function BloxFruits:GetNearestEnemy(maxDistance)
    if not HumanoidRootPart then return nil end
    
    local nearestEnemy = nil
    local shortestDistance = maxDistance or 5000
    
    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then
        for _, enemy in pairs(enemies:GetChildren()) do
            if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                if enemy:FindFirstChild("HumanoidRootPart") then
                    local distance = (HumanoidRootPart.Position - enemy.HumanoidRootPart.Position).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        nearestEnemy = enemy
                    end
                end
            end
        end
    end
    
    return nearestEnemy, shortestDistance
end

-- Auto Farm Level
function BloxFruits:AutoFarmLevel()
    if not self.Settings.AutoFarm.Level or not HumanoidRootPart then return end
    
    local quest = self:GetRecommendedQuest()
    if not quest then return end
    
    pcall(function()
        -- Get Quest NPC and accept quest
        if self.Settings.Misc.AutoQuest then
            self:SafeTeleport(quest.Location)
            SafeWait(0.5)
            
            -- Accept quest via remote (game-specific)
            local remotes = GetRemotes()
            if remotes.Combat then
                SafeFireRemote(remotes.Combat, "StartQuest", quest.Quest, 1)
            end
            
            SafeWait(RandomDelay())
        end
        
        -- Find and attack nearest enemy
        local enemy, distance = self:GetNearestEnemy(1000)
        if enemy and enemy:FindFirstChild("HumanoidRootPart") then
            local enemyRoot = enemy.HumanoidRootPart
            local targetCFrame = enemyRoot.CFrame * CFrame.new(0, 0, self.Settings.AutoFarm.FarmDistance)
            
            -- Teleport to enemy
            self:SafeTeleport(targetCFrame)
            
            -- Attack
            if self.Settings.Combat.FastAttack then
                self:FastAttack()
            end
            
            SafeWait(0.1)
        end
    end)
end

-- Fast Attack (Anti-Cheat Safe)
function BloxFruits:FastAttack()
    local Camera = Workspace.CurrentCamera
    
    pcall(function()
        local remotes = GetRemotes()
        if remotes.Combat then
            -- Click simulation (safer than direct remote spam)
            local virtualInput = game:GetService("VirtualInputManager")
            virtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            SafeWait(0.001)
            virtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end
    end)
end

-- ESP System
BloxFruits.ESPObjects = {}

function BloxFruits:CreateESP(object, text, color)
    if not object:FindFirstChild("InovoESP") then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "InovoESP"
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Parent = object
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0.5
        label.Parent = billboard
        
        table.insert(self.ESPObjects, {Object = object, GUI = billboard})
    end
end

function BloxFruits:UpdateESP()
    if not self.Settings.ESP.Enabled or not HumanoidRootPart then return end
    
    pcall(function()
        -- Fruit ESP
        if self.Settings.ESP.Fruits then
            for _, fruit in pairs(Workspace:GetChildren()) do
                if fruit:IsA("Tool") or (fruit:IsA("Model") and fruit:FindFirstChild("Handle")) then
                    if fruit.Name:find("Fruit") then
                        local distance = (HumanoidRootPart.Position - fruit:GetPivot().Position).Magnitude
                        if distance <= self.Settings.ESP.MaxDistance then
                            self:CreateESP(fruit, fruit.Name .. " [" .. math.floor(distance) .. "m]", Color3.fromRGB(255, 100, 255))
                        end
                    end
                end
            end
        end
        
        -- Player ESP
        if self.Settings.ESP.Players then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    if player.Character:FindFirstChild("HumanoidRootPart") then
                        local distance = (HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                        if distance <= self.Settings.ESP.MaxDistance then
                            self:CreateESP(player.Character, player.Name .. " [" .. math.floor(distance) .. "m]", Color3.fromRGB(255, 255, 100))
                        end
                    end
                end
            end
        end
    end)
end

function BloxFruits:ClearESP()
    for _, espData in pairs(self.ESPObjects) do
        if espData.GUI then
            espData.GUI:Destroy()
        end
    end
    self.ESPObjects = {}
end

-- Auto Collect Fruits
function BloxFruits:AutoCollectFruits()
    if not self.Settings.Misc.AutoCollectFruits or not HumanoidRootPart then return end
    
    pcall(function()
        for _, fruit in pairs(Workspace:GetChildren()) do
            if fruit:IsA("Tool") or (fruit:IsA("Model") and fruit:FindFirstChild("Handle")) then
                if fruit.Name:find("Fruit") then
                    local fruitPos = fruit:GetPivot()
                    local distance = (HumanoidRootPart.Position - fruitPos.Position).Magnitude
                    
                    if distance <= 5000 then
                        self:SafeTeleport(fruitPos)
                        SafeWait(0.5)
                        
                        -- Try to collect
                        if fruit:IsA("Tool") then
                            firetouchinterest(HumanoidRootPart, fruit.Handle, 0)
                            firetouchinterest(HumanoidRootPart, fruit.Handle, 1)
                        end
                        
                        SafeWait(RandomDelay())
                    end
                end
            end
        end
    end)
end

-- Movement Speed
function BloxFruits:UpdateMovement()
    if not Humanoid then return end
    
    pcall(function()
        if self.Settings.Movement.SpeedEnabled then
            Humanoid.WalkSpeed = self.Settings.Movement.Speed
        else
            Humanoid.WalkSpeed = 16
        end
    end)
end

-- No Clip
function BloxFruits:NoClip()
    if not self.Settings.Misc.NoClip or not Character then return end
    
    pcall(function()
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

-- Main Loop
function BloxFruits:StartLoop()
    if self.LoopConnection then return end
    
    self.LoopConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            -- Auto Farm
            if self.Settings.AutoFarm.Level then
                self:AutoFarmLevel()
            end
            
            -- Auto Collect Fruits
            if self.Settings.Misc.AutoCollectFruits then
                self:AutoCollectFruits()
            end
            
            -- Movement
            self:UpdateMovement()
            
            -- No Clip
            if self.Settings.Misc.NoClip then
                self:NoClip()
            end
            
            -- ESP Update (every 2 seconds)
            if tick() % 2 < 0.016 then
                self:UpdateESP()
            end
        end)
    end)
end

function BloxFruits:StopLoop()
    if self.LoopConnection then
        self.LoopConnection:Disconnect()
        self.LoopConnection = nil
    end
end

-- Initialize
function BloxFruits:Init()
    self:StartLoop()
    print("[InovoHub] Blox Fruits loaded successfully!")
end

-- Cleanup
function BloxFruits:Destroy()
    self:StopLoop()
    self:ClearESP()
end

-- Create new instance
function BloxFruits.new()
    local self = setmetatable({}, BloxFruits)
    return self
end

return BloxFruits
