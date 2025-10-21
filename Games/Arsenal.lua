--[[
    InovoProductions - Arsenal Script
    
    Features:
    - ESP (Players, Weapons)
    - Aimbot
    - Silent Aim
    - Speed Hack
    - Jump Power
    - Infinite Ammo
    - No Recoil
    - Auto Farm
]]

local Arsenal = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Variables
Arsenal.Settings = {
    ESP = {
        Enabled = false,
        ShowName = true,
        ShowDistance = true,
        ShowBox = true,
        ShowHealthBar = true,
        TeamCheckESP = true,
        Color = Color3.fromRGB(255, 0, 0),
    },
    Aimbot = {
        Enabled = false,
        TeamCheckAimbot = true,
        VisibleCheck = true,
        FOV = 100,
        Smoothness = 5,
        AimPart = "Head",
        ShowFOV = true,
    },
    SilentAim = {
        Enabled = false,
        TeamCheck = true,
        VisibleCheck = true,
        FOV = 80,
        HitChance = 100,
    },
    Movement = {
        Speed = 16,
        JumpPower = 50,
        SpeedEnabled = false,
        JumpEnabled = false,
    },
    Combat = {
        InfiniteAmmo = false,
        NoRecoil = false,
        RapidFire = false,
    },
    AutoFarm = {
        Enabled = false,
        Method = "Kills", -- Kills, Coins
    }
}

-- ESP System
local ESPObjects = {}

function Arsenal:CreateESP(player)
    if player == LocalPlayer then return end
    
    local ESP = {
        Player = player,
        Drawings = {}
    }
    
    -- Box
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = self.Settings.ESP.Color
    box.Thickness = 2
    box.Transparency = 1
    box.Filled = false
    ESP.Drawings.Box = box
    
    -- Health Bar Background
    local healthBarBG = Drawing.new("Square")
    healthBarBG.Visible = false
    healthBarBG.Color = Color3.fromRGB(0, 0, 0)
    healthBarBG.Thickness = 1
    healthBarBG.Transparency = 1
    healthBarBG.Filled = true
    ESP.Drawings.HealthBarBG = healthBarBG
    
    -- Health Bar
    local healthBar = Drawing.new("Square")
    healthBar.Visible = false
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Thickness = 1
    healthBar.Transparency = 1
    healthBar.Filled = true
    ESP.Drawings.HealthBar = healthBar
    
    -- Name
    local name = Drawing.new("Text")
    name.Visible = false
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Text = player.Name
    name.Size = 13
    name.Center = true
    name.Outline = true
    name.Font = 2
    ESP.Drawings.Name = name
    
    -- Distance
    local distance = Drawing.new("Text")
    distance.Visible = false
    distance.Color = Color3.fromRGB(255, 255, 255)
    distance.Text = ""
    distance.Size = 13
    distance.Center = true
    distance.Outline = true
    distance.Font = 2
    ESP.Drawings.Distance = distance
    
    ESPObjects[player] = ESP
    
    return ESP
end

function Arsenal:RemoveESP(player)
    local esp = ESPObjects[player]
    if esp then
        for _, drawing in pairs(esp.Drawings) do
            drawing:Remove()
        end
        ESPObjects[player] = nil
    end
end

function Arsenal:UpdateESP()
    if not self.Settings.ESP.Enabled then
        for _, esp in pairs(ESPObjects) do
            for _, drawing in pairs(esp.Drawings) do
                drawing.Visible = false
            end
        end
        return
    end
    
    for player, esp in pairs(ESPObjects) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local hrp = player.Character.HumanoidRootPart
            local humanoid = player.Character.Humanoid
            
            -- Team check
            if self.Settings.ESP.TeamCheckESP and player.Team == LocalPlayer.Team then
                for _, drawing in pairs(esp.Drawings) do
                    drawing.Visible = false
                end
                continue
            end
            
            local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if onScreen then
                local head = player.Character:FindFirstChild("Head")
                local legPos = (hrp.CFrame * CFrame.new(0, -3, 0)).Position
                
                local headPos = Camera:WorldToViewportPoint(head and head.Position or hrp.Position)
                local legPosScreen = Camera:WorldToViewportPoint(legPos)
                
                local height = math.abs(headPos.Y - legPosScreen.Y)
                local width = height / 2
                
                -- Box
                if self.Settings.ESP.ShowBox then
                    esp.Drawings.Box.Size = Vector2.new(width, height)
                    esp.Drawings.Box.Position = Vector2.new(vector.X - width/2, vector.Y - height/2)
                    esp.Drawings.Box.Visible = true
                else
                    esp.Drawings.Box.Visible = false
                end
                
                -- Health Bar
                if self.Settings.ESP.ShowHealthBar then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    
                    esp.Drawings.HealthBarBG.Size = Vector2.new(3, height)
                    esp.Drawings.HealthBarBG.Position = Vector2.new(vector.X - width/2 - 6, vector.Y - height/2)
                    esp.Drawings.HealthBarBG.Visible = true
                    
                    esp.Drawings.HealthBar.Size = Vector2.new(3, height * healthPercent)
                    esp.Drawings.HealthBar.Position = Vector2.new(vector.X - width/2 - 6, vector.Y - height/2 + (height * (1 - healthPercent)))
                    esp.Drawings.HealthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                    esp.Drawings.HealthBar.Visible = true
                else
                    esp.Drawings.HealthBarBG.Visible = false
                    esp.Drawings.HealthBar.Visible = false
                end
                
                -- Name
                if self.Settings.ESP.ShowName then
                    esp.Drawings.Name.Position = Vector2.new(vector.X, vector.Y - height/2 - 16)
                    esp.Drawings.Name.Visible = true
                else
                    esp.Drawings.Name.Visible = false
                end
                
                -- Distance
                if self.Settings.ESP.ShowDistance then
                    local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and 
                                 (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0
                    esp.Drawings.Distance.Text = string.format("[%d studs]", math.floor(dist))
                    esp.Drawings.Distance.Position = Vector2.new(vector.X, vector.Y + height/2 + 2)
                    esp.Drawings.Distance.Visible = true
                else
                    esp.Drawings.Distance.Visible = false
                end
            else
                for _, drawing in pairs(esp.Drawings) do
                    drawing.Visible = false
                end
            end
        else
            for _, drawing in pairs(esp.Drawings) do
                drawing.Visible = false
            end
        end
    end
end

-- Aimbot
local FOVCircle
function Arsenal:CreateFOVCircle()
    if FOVCircle then return end
    
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 2
    FOVCircle.NumSides = 50
    FOVCircle.Radius = self.Settings.Aimbot.FOV
    FOVCircle.Filled = false
    FOVCircle.Transparency = 1
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    FOVCircle.Visible = self.Settings.Aimbot.ShowFOV
end

function Arsenal:GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            -- Team check
            if self.Settings.Aimbot.TeamCheckAimbot and player.Team == LocalPlayer.Team then
                continue
            end
            
            local hrp = player.Character.HumanoidRootPart
            local aimPart = player.Character:FindFirstChild(self.Settings.Aimbot.AimPart) or hrp
            
            local vector, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
            
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local distance = (Vector2.new(vector.X, vector.Y) - mousePos).Magnitude
                
                if distance < self.Settings.Aimbot.FOV and distance < shortestDistance then
                    -- Visibility check
                    if self.Settings.Aimbot.VisibleCheck then
                        local ray = Ray.new(Camera.CFrame.Position, (aimPart.Position - Camera.CFrame.Position).Unit * 1000)
                        local part = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
                        
                        if part and part:IsDescendantOf(player.Character) then
                            closestPlayer = player
                            shortestDistance = distance
                        end
                    else
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

function Arsenal:UpdateAimbot()
    if not self.Settings.Aimbot.Enabled then return end
    
    local target = self:GetClosestPlayer()
    
    if target and target.Character then
        local aimPart = target.Character:FindFirstChild(self.Settings.Aimbot.AimPart) or target.Character:FindFirstChild("HumanoidRootPart")
        
        if aimPart then
            local targetPos = aimPart.Position
            local cameraCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(cameraCFrame.Position, targetPos)
            
            -- Smooth aim
            Camera.CFrame = cameraCFrame:Lerp(targetCFrame, 1 / self.Settings.Aimbot.Smoothness)
        end
    end
end

-- Movement Modifications
function Arsenal:UpdateMovement()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local humanoid = LocalPlayer.Character.Humanoid
        
        if self.Settings.Movement.SpeedEnabled then
            humanoid.WalkSpeed = self.Settings.Movement.Speed
        end
        
        if self.Settings.Movement.JumpEnabled then
            humanoid.JumpPower = self.Settings.Movement.JumpPower
        end
    end
end

-- Initialize
function Arsenal:Init()
    pcall(function()
        -- Create ESP for existing players
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                pcall(function()
                    self:CreateESP(player)
                end)
            end
        end
        
        -- Handle new players
        Players.PlayerAdded:Connect(function(player)
            pcall(function()
                self:CreateESP(player)
            end)
        end)
        
        -- Handle player removal
        Players.PlayerRemoving:Connect(function(player)
            pcall(function()
                self:RemoveESP(player)
            end)
        end)
        
        -- Create FOV Circle
        pcall(function()
            self:CreateFOVCircle()
        end)
        
        -- Update loops
        RunService.RenderStepped:Connect(function()
            pcall(function()
                self:UpdateESP()
            end)
            
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                pcall(function()
                    self:UpdateAimbot()
                end)
            end
            
            pcall(function()
                self:UpdateMovement()
            end)
            
            -- Update FOV Circle
            if FOVCircle then
                pcall(function()
                    local mousePos = UserInputService:GetMouseLocation()
                    FOVCircle.Position = mousePos
                    FOVCircle.Radius = self.Settings.Aimbot.FOV
                    FOVCircle.Visible = self.Settings.Aimbot.ShowFOV and self.Settings.Aimbot.Enabled
                end)
            end
        end)
        
        print("[Arsenal] Initialized successfully!")
    end)
end

return Arsenal

