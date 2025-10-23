--[[
    InovoProductions - FiveR Roleplay Script
    Focused on quality-of-life tools for Dutch FiveR-style roleplay experiences.
    
    Features:
    - Prompt automation and drop collection
    - Player and vehicle ESP
    - Movement utilities (speed, sprint, flight)
    - Visual helpers (night vision, clear weather)
    - Teleport helpers with preset search + custom save slot
    - Anti-AFK protection
]]

local FiveR = {}
FiveR.__index = FiveR

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local ProximityPromptService = game:GetService("ProximityPromptService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local firePrompt = fireproximityprompt
local fireTouch = firetouchinterest

local function safeFirePrompt(prompt)
    if not prompt or not prompt:IsDescendantOf(Workspace) then
        return
    end

    if firePrompt then
        pcall(firePrompt, prompt)
    else
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration or 0.1)
            prompt:InputHoldEnd()
        end)
    end
end

local function safeTouch(partA, partB)
    if not fireTouch or not partA or not partB then
        return
    end

    pcall(function()
        fireTouch(partA, partB, 0)
        fireTouch(partA, partB, 1)
    end)
end

FiveR.Settings = {
    Utility = {
        AutoInteractPrompts = false,
        AutoCollectDrops = false,
        DispatchAlerts = true,
    },
    ESP = {
        Enabled = false,
        Players = true,
        Vehicles = true,
        ShowNames = true,
        ShowDistance = true,
        MaxDistance = 1200,
    },
    Movement = {
        SpeedEnabled = false,
        WalkSpeed = 16,
        SprintEnabled = false,
        SprintSpeed = 28,
        JumpEnabled = false,
        JumpPower = 50,
        FlyEnabled = false,
        FlySpeed = 65,
    },
    Misc = {
        AntiAFK = true,
        NightVision = false,
        ClearWeather = false,
    }
}

FiveR.LocationPresets = {
    ["Central Spawn"] = {"spawn"},
    ["Police HQ"] = {"police", "hq"},
    ["Hospital"] = {"hospital"},
    ["Fire Department"] = {"fire", "station"},
    ["Dealership"] = {"dealer"},
    ["City Hall"] = {"city", "hall"},
    ["Bank"] = {"bank"},
    ["Harbor"] = {"harbor"},
}

FiveR.__cache = {
    ESPPlayers = {},
    ESPVehicles = {},
    LastESPRefresh = 0,
    LastPromptScan = 0,
    LastDropScan = 0,
    SavedPosition = nil,
    Running = false,
    FlyVelocity = nil,
    FlyGyro = nil,
    DefaultLighting = {},
    AtmosphereDefaults = nil,
}

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local function recordLightingDefaults(cache)
    cache.DefaultLighting = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        ColorShiftTop = Lighting.ColorShiftTop,
        ColorShiftBottom = Lighting.ColorShiftBottom,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogEnd = Lighting.FogEnd,
    }

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        cache.AtmosphereDefaults = {
            Density = atmosphere.Density,
            Offset = atmosphere.Offset,
            Color = atmosphere.Color,
            Decay = atmosphere.Decay,
        }
    end
end

local function restoreLightingDefaults(cache)
    local defaults = cache.DefaultLighting
    if defaults then
        Lighting.Brightness = defaults.Brightness
        Lighting.ClockTime = defaults.ClockTime
        Lighting.ColorShiftTop = defaults.ColorShiftTop
        Lighting.ColorShiftBottom = defaults.ColorShiftBottom
        Lighting.Ambient = defaults.Ambient
        Lighting.OutdoorAmbient = defaults.OutdoorAmbient
        Lighting.FogEnd = defaults.FogEnd
    end

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere and cache.AtmosphereDefaults then
        atmosphere.Density = cache.AtmosphereDefaults.Density
        atmosphere.Offset = cache.AtmosphereDefaults.Offset
        atmosphere.Color = cache.AtmosphereDefaults.Color
        atmosphere.Decay = cache.AtmosphereDefaults.Decay
    end
end

local function findMatchingPart(tokens)
    local tokensLower = {}
    for _, token in ipairs(tokens) do
        table.insert(tokensLower, string.lower(token))
    end

    local bestCandidate
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("BasePart") and inst.Parent and inst.CanCollide then
            local lowerName = string.lower(inst.Name)
            local allMatch = true

            for _, token in ipairs(tokensLower) do
                if not string.find(lowerName, token, 1, true) then
                    allMatch = false
                    break
                end
            end

            if allMatch then
                bestCandidate = inst
                break
            end
        end
    end

    return bestCandidate
end

function FiveR:Notify(text, color)
    if not self.Settings.Utility.DispatchAlerts then
        return
    end

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "InovoProductions",
            Text = tostring(text),
            Duration = 4,
            Button1 = "OK",
            Icon = "rbxassetid://7734057667",
        })
    end)
end

function FiveR:UpdateCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end

function FiveR:SafeTeleport(targetCFrame)
    if not targetCFrame or not HumanoidRootPart then
        return false
    end

    local success = pcall(function()
        local current = HumanoidRootPart.Position
        local distance = (current - targetCFrame.Position).Magnitude

        if distance > 200 then
            local tweenInfo = TweenInfo.new(math.clamp(distance / 180, 0.5, 3), Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            local tween = TweenService:Create(HumanoidRootPart, tweenInfo, {CFrame = targetCFrame})
            tween:Play()
            tween.Completed:Wait()
        else
            HumanoidRootPart.CFrame = targetCFrame
        end
    end)

    return success
end

function FiveR:TeleportPreset(name)
    local tokens = self.LocationPresets[name]
    if not tokens then
        self:Notify("Preset not found: " .. tostring(name))
        return
    end

    local part = findMatchingPart(tokens)
    if part and part:IsA("BasePart") then
        self:SafeTeleport(part.CFrame + Vector3.new(0, 3, 0))
        self:Notify("Teleported to " .. name)
    else
        self:Notify("Kon locatie niet vinden: " .. name)
    end
end

function FiveR:SavePosition()
    if HumanoidRootPart then
        self.__cache.SavedPosition = HumanoidRootPart.CFrame
        self:Notify("Positie opgeslagen")
    end
end

function FiveR:LoadPosition()
    if self.__cache.SavedPosition then
        self:SafeTeleport(self.__cache.SavedPosition)
        self:Notify("Positie geladen")
    else
        self:Notify("Geen positie opgeslagen")
    end
end

function FiveR:ClearESP()
    for _, data in pairs(self.__cache.ESPPlayers) do
        if data.Highlight then
            data.Highlight:Destroy()
        end
        if data.Billboard then
            data.Billboard:Destroy()
        end
    end

    for _, highlight in pairs(self.__cache.ESPVehicles) do
        if highlight.Highlight then
            highlight.Highlight:Destroy()
        end
        if highlight.Billboard then
            highlight.Billboard:Destroy()
        end
    end

    self.__cache.ESPPlayers = {}
    self.__cache.ESPVehicles = {}
end

function FiveR:EnsurePlayerESP(player)
    local character = player.Character
    if not character or not HumanoidRootPart then
        return
    end

    local cache = self.__cache.ESPPlayers[player]
    if not cache then
        cache = {}
        self.__cache.ESPPlayers[player] = cache
    end

    if not cache.Highlight or not cache.Highlight.Parent then
        local highlight = Instance.new("Highlight")
        highlight.Name = "InovoFiveRESP"
        highlight.Adornee = character
        highlight.FillTransparency = 1
        highlight.OutlineColor = Color3.fromRGB(45, 160, 255)
        highlight.OutlineTransparency = 0
        highlight.Parent = character
        cache.Highlight = highlight
    end

    if self.Settings.ESP.ShowNames or self.Settings.ESP.ShowDistance then
        local billboard = cache.Billboard
        if not billboard or not billboard.Parent then
            billboard = Instance.new("BillboardGui")
            billboard.Name = "InovoFiveRESPBillboard"
            billboard.Size = UDim2.new(0, 150, 0, 40)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = character

            local label = Instance.new("TextLabel")
            label.Name = "Text"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamBold
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextStrokeTransparency = 0
            label.TextScaled = true
            label.Parent = billboard

            cache.Billboard = billboard
        end

        local label = cache.Billboard:FindFirstChild("Text")
        if label then
            local fragments = {}
            if self.Settings.ESP.ShowNames then
                table.insert(fragments, player.DisplayName or player.Name)
            end
            if self.Settings.ESP.ShowDistance and character:FindFirstChild("HumanoidRootPart") and HumanoidRootPart then
                local distance = math.floor((HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude)
                table.insert(fragments, "[" .. distance .. "m]")
            end
            label.Text = table.concat(fragments, " ")
        end
    elseif cache.Billboard then
        cache.Billboard:Destroy()
        cache.Billboard = nil
    end

    if not self.Settings.ESP.Players then
        if cache.Highlight then
            cache.Highlight.OutlineTransparency = 1
        end
        if cache.Billboard then
            cache.Billboard.Enabled = false
        end
    else
        if cache.Highlight then
            cache.Highlight.OutlineTransparency = 0
        end
        if cache.Billboard then
            cache.Billboard.Enabled = true
        end
    end
end

function FiveR:EnsureVehicleESP(model)
    if not model or not HumanoidRootPart then
        return
    end

    local cache = self.__cache.ESPVehicles[model]
    if not cache then
        cache = {}
        self.__cache.ESPVehicles[model] = cache
    end

    if not cache.Highlight or not cache.Highlight.Parent then
        local highlight = Instance.new("Highlight")
        highlight.Name = "InovoFiveRVESP"
        highlight.Adornee = model
        highlight.FillTransparency = 0.85
        highlight.FillColor = Color3.fromRGB(255, 200, 60)
        highlight.OutlineColor = Color3.fromRGB(255, 150, 40)
        highlight.OutlineTransparency = 0
        highlight.Parent = model
        cache.Highlight = highlight
    end

    if not self.Settings.ESP.Vehicles and cache.Highlight then
        cache.Highlight.Enabled = false
    elseif cache.Highlight then
        cache.Highlight.Enabled = true
    end
end

function FiveR:UpdateESP()
    if not self.Settings.ESP.Enabled then
        self:ClearESP()
        return
    end

    if tick() - self.__cache.LastESPRefresh < 0.75 then
        return
    end
    self.__cache.LastESPRefresh = tick()

    for player, data in pairs(self.__cache.ESPPlayers) do
        if not player.Character or player == LocalPlayer then
            if data.Highlight then
                data.Highlight:Destroy()
            end
            if data.Billboard then
                data.Billboard:Destroy()
            end
            self.__cache.ESPPlayers[player] = nil
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            self:EnsurePlayerESP(player)
        end
    end

    for model, esp in pairs(self.__cache.ESPVehicles) do
        if not model.Parent then
            if esp.Highlight then
                esp.Highlight:Destroy()
            end
            if esp.Billboard then
                esp.Billboard:Destroy()
            end
            self.__cache.ESPVehicles[model] = nil
        end
    end

    if self.Settings.ESP.Vehicles then
        for _, seat in ipairs(Workspace:GetDescendants()) do
            if seat:IsA("VehicleSeat") or seat:IsA("Seat") then
                local model = seat:FindFirstAncestorOfClass("Model")
                if model and model ~= Character and (HumanoidRootPart.Position - seat.Position).Magnitude <= self.Settings.ESP.MaxDistance then
                    self:EnsureVehicleESP(model)
                end
            end
        end
    end
end

function FiveR:UpdateMovement()
    if not Humanoid then
        return
    end

    if self.Settings.Movement.SpeedEnabled then
        local targetSpeed = self.Settings.Movement.WalkSpeed
        if self.Settings.Movement.SprintEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            targetSpeed = self.Settings.Movement.SprintSpeed
        end
        Humanoid.WalkSpeed = targetSpeed
    else
        Humanoid.WalkSpeed = 16
    end

    if self.Settings.Movement.JumpEnabled then
        Humanoid.JumpPower = self.Settings.Movement.JumpPower
    else
        Humanoid.JumpPower = 50
    end
end

function FiveR:DisableFlight()
    local cache = self.__cache
    if cache.FlyVelocity then
        cache.FlyVelocity:Destroy()
        cache.FlyVelocity = nil
    end
    if cache.FlyGyro then
        cache.FlyGyro:Destroy()
        cache.FlyGyro = nil
    end
    if Humanoid then
        Humanoid.PlatformStand = false
    end
end

function FiveR:UpdateFlight()
    if not HumanoidRootPart then
        return
    end

    if not self.Settings.Movement.FlyEnabled then
        self:DisableFlight()
        return
    end

    local cache = self.__cache
    if not cache.FlyVelocity then
        cache.FlyVelocity = Instance.new("BodyVelocity")
        cache.FlyVelocity.Name = "InovoFiveRFlyVelocity"
        cache.FlyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        cache.FlyVelocity.Parent = HumanoidRootPart
    end

    if not cache.FlyGyro then
        cache.FlyGyro = Instance.new("BodyGyro")
        cache.FlyGyro.Name = "InovoFiveRFlyGyro"
        cache.FlyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        cache.FlyGyro.Parent = HumanoidRootPart
    end

    Humanoid.PlatformStand = true

    local direction = Vector3.new()
    local lookVector = Camera.CFrame.LookVector
    local rightVector = Camera.CFrame.RightVector

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        direction += lookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        direction -= lookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        direction += rightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        direction -= rightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        direction += Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        direction -= Vector3.new(0, 1, 0)
    end

    if direction.Magnitude > 0 then
        direction = direction.Unit
    end

    cache.FlyVelocity.Velocity = direction * self.Settings.Movement.FlySpeed
    cache.FlyGyro.CFrame = Camera.CFrame
end

function FiveR:HandlePrompts()
    if not self.Settings.Utility.AutoInteractPrompts or not HumanoidRootPart then
        return
    end

    local now = tick()
    if now - self.__cache.LastPromptScan < 1 then
        return
    end
    self.__cache.LastPromptScan = now

    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local object = prompt.Parent
            local position

            if object and object:IsA("BasePart") then
                position = object.Position
            elseif object and object:IsA("Model") and object.PrimaryPart then
                position = object.PrimaryPart.Position
            end

            if position and (HumanoidRootPart.Position - position).Magnitude <= (prompt.MaxActivationDistance + 2) then
                safeFirePrompt(prompt)
                task.wait(0.1)
                break
            end
        end
    end
end

function FiveR:CollectDrops()
    if not self.Settings.Utility.AutoCollectDrops or not HumanoidRootPart then
        return
    end

    local now = tick()
    if now - self.__cache.LastDropScan < 1.5 then
        return
    end
    self.__cache.LastDropScan = now

    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("BasePart") or inst:IsA("MeshPart") then
            local lower = string.lower(inst.Name)
            if string.find(lower, "cash", 1, true) or string.find(lower, "money", 1, true) or string.find(lower, "briefcase", 1, true) then
                if (HumanoidRootPart.Position - inst.Position).Magnitude <= 180 then
                    local targetCFrame = inst.CFrame + Vector3.new(0, 2, 0)
                    if self:SafeTeleport(targetCFrame) then
                        safeTouch(HumanoidRootPart, inst)
                        self:Notify("Drop opgepakt: " .. inst.Name)
                    end
                    break
                end
            end
        elseif inst:IsA("Tool") and string.find(string.lower(inst.Name), "cash", 1, true) then
            local handle = inst:FindFirstChild("Handle")
            if handle and (HumanoidRootPart.Position - handle.Position).Magnitude <= 180 then
                if self:SafeTeleport(handle.CFrame + Vector3.new(0, 2, 0)) then
                    safeTouch(HumanoidRootPart, handle)
                    self:Notify("Tool opgepakt: " .. inst.Name)
                end
                break
            end
        end
    end
end

function FiveR:UpdateVisuals()
    if self.Settings.Misc.NightVision then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.ColorShiftTop = Color3.fromRGB(160, 200, 255)
        Lighting.ColorShiftBottom = Color3.fromRGB(120, 170, 255)
        Lighting.Ambient = Color3.fromRGB(100, 120, 160)
        Lighting.OutdoorAmbient = Color3.fromRGB(140, 160, 200)
        Lighting.FogEnd = 3000
    end

    if self.Settings.Misc.ClearWeather then
        Lighting.FogEnd = 100000
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then
            atmosphere.Density = 0
            atmosphere.Decay = Color3.new(0, 0, 0)
        end
    end

    if not self.Settings.Misc.NightVision and not self.Settings.Misc.ClearWeather then
        restoreLightingDefaults(self.__cache)
    end
end

function FiveR:ResetVisuals()
    self.Settings.Misc.NightVision = false
    self.Settings.Misc.ClearWeather = false
    restoreLightingDefaults(self.__cache)
    self:Notify("Visuele instellingen teruggezet")
end

function FiveR:StartLoops()
    if self.__cache.Running then
        return
    end

    self.__cache.Running = true

    self.HeartbeatConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            self:UpdateMovement()
            self:UpdateFlight()
            self:HandlePrompts()
            self:CollectDrops()
            self:UpdateVisuals()
        end)
    end)

    self.RenderConnection = RunService.RenderStepped:Connect(function()
        pcall(function()
            self:UpdateESP()
        end)
    end)

    if not self.AntiAFKConnection then
        self.AntiAFKConnection = LocalPlayer.Idled:Connect(function()
            if self.Settings.Misc.AntiAFK then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end
        end)
    end
end

function FiveR:StopLoops()
    self.__cache.Running = false

    if self.HeartbeatConnection then
        self.HeartbeatConnection:Disconnect()
        self.HeartbeatConnection = nil
    end

    if self.RenderConnection then
        self.RenderConnection:Disconnect()
        self.RenderConnection = nil
    end

    self:DisableFlight()
end

function FiveR:Init()
    recordLightingDefaults(self.__cache)

    if not self.CharacterAddedConnection then
        self.CharacterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(char)
            pcall(function()
                self:UpdateCharacter(char)
                task.wait(1)
                self:Notify("FiveR | Character klaar")
            end)
        end)
    end

    if not self.CharacterRemovingConnection then
        self.CharacterRemovingConnection = LocalPlayer.CharacterRemoving:Connect(function()
            self:DisableFlight()
        end)
    end

    self:StartLoops()
    self:Notify("FiveR Roleplay toolkit geladen")
end

function FiveR:Destroy()
    self:StopLoops()
    self:ClearESP()
    self:DisableFlight()

    if self.CharacterAddedConnection then
        self.CharacterAddedConnection:Disconnect()
        self.CharacterAddedConnection = nil
    end

    if self.CharacterRemovingConnection then
        self.CharacterRemovingConnection:Disconnect()
        self.CharacterRemovingConnection = nil
    end
end

return FiveR

