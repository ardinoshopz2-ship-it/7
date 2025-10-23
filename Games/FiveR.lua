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
local HumanoidStateType = Enum.HumanoidStateType

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local firePrompt = fireproximityprompt
local fireTouch = firetouchinterest
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}

local LightingPropertyAliases = {
    ColorShiftTop = "ColorShift_Top",
    ColorShiftBottom = "ColorShift_Bottom",
}

local LightingTrackedProperties = {
    "Brightness",
    "ClockTime",
    "Ambient",
    "OutdoorAmbient",
    "FogEnd",
    "ColorShiftTop",
    "ColorShiftBottom",
}

local function getLightingValue(prop)
    local success, value = pcall(function()
        return Lighting[prop]
    end)
    if success then
        return value, prop
    end

    local alias = LightingPropertyAliases[prop]
    if alias then
        success, value = pcall(function()
            return Lighting[alias]
        end)
        if success then
            return value, alias
        end
    end

    return nil, nil
end

local function setLightingValue(prop, value)
    local success = pcall(function()
        Lighting[prop] = value
    end)
    if success then
        return true
    end

    local alias = LightingPropertyAliases[prop]
    if alias then
        success = pcall(function()
            Lighting[alias] = value
        end)
        if success then
            return true
        end
    end

    return false
end

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
FiveR.LocationOverrides = _G.InovoFiveRLocations or {}
_G.InovoFiveRLocations = FiveR.LocationOverrides

FiveR.__cache = {
    ESPPlayers = {},
    ESPVehicles = {},
    LastESPRefresh = 0,
    LastPromptScan = 0,
    LastDropScan = 0,
    SavedPosition = nil,
    Running = false,
    FlyAltitude = nil,
    LastFlightTick = nil,
    OriginalHipHeight = nil,
    ResolvedLocations = {},
    DefaultLighting = {},
    AtmosphereDefaults = nil,
}

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local function recordLightingDefaults(cache)
    cache.DefaultLighting = {}

    for _, prop in ipairs(LightingTrackedProperties) do
        local value, actualName = getLightingValue(prop)
        if value ~= nil then
            cache.DefaultLighting[prop] = {
                name = actualName or prop,
                value = value
            }
        end
    end

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
        for prop, data in pairs(defaults) do
            if typeof(data) == "table" then
                if data.value ~= nil then
                    setLightingValue(data.name or prop, data.value)
                end
            elseif data ~= nil then
                setLightingValue(prop, data)
            end
        end
    end

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere and cache.AtmosphereDefaults then
        atmosphere.Density = cache.AtmosphereDefaults.Density
        atmosphere.Offset = cache.AtmosphereDefaults.Offset
        atmosphere.Color = cache.AtmosphereDefaults.Color
        atmosphere.Decay = cache.AtmosphereDefaults.Decay
    end
end

local function getCFrameFromInstance(inst)
    if not inst then
        return nil
    end

    if inst:IsA("BasePart") then
        return inst.CFrame
    end

    if inst:IsA("Model") then
        local primary = inst.PrimaryPart
        if primary then
            return primary.CFrame
        end

        local part = inst:FindFirstChildWhichIsA("BasePart", true)
        if part then
            return part.CFrame
        end
    end

    return nil
end

local function findMatchingLocation(tokens)
    local tokensLower = {}
    for _, token in ipairs(tokens) do
        table.insert(tokensLower, string.lower(token))
    end

    local bestCFrame
    local bestScore
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("BasePart") or inst:IsA("Model") then
            local lowerName = string.lower(inst.Name)
            local matches = true
            for _, token in ipairs(tokensLower) do
                if not string.find(lowerName, token, 1, true) then
                    matches = false
                    break
                end
            end

            if matches then
                local cframe = getCFrameFromInstance(inst)
                if cframe then
                    local score = #lowerName
                    if not bestScore or score < bestScore then
                        bestScore = score
                        bestCFrame = cframe
                    end
                end
            end
        end
    end

    return bestCFrame
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

    if raycastParams then
        raycastParams.FilterDescendantsInstances = {char}
    end
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

    local cached = self.LocationOverrides[name] or self.__cache.ResolvedLocations[name]
    if not cached then
        cached = findMatchingLocation(tokens)
        if cached then
            self.__cache.ResolvedLocations[name] = cached
        end
    end

    if cached then
        self:SafeTeleport(cached + Vector3.new(0, 3, 0))
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

function FiveR:SetPresetLocation(name, cframe)
    if not name or not cframe then
        return
    end

    self.LocationOverrides[name] = cframe
    self.__cache.ResolvedLocations[name] = cframe
    _G.InovoFiveRLocations = self.LocationOverrides
    self:Notify("Locatie bijgewerkt: " .. tostring(name))
end

function FiveR:CaptureLocation(name)
    if not HumanoidRootPart then
        self:Notify("Kon huidige positie niet bepalen.")
        return
    end

    self:SetPresetLocation(name, HumanoidRootPart.CFrame)
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
    if player == LocalPlayer then
        return
    end

    local character = player.Character
    if not character or not HumanoidRootPart then
        return
    end

    local cache = self.__cache.ESPPlayers[player]
    if not cache then
        cache = {}
        self.__cache.ESPPlayers[player] = cache
    end

    if (not cache.Highlight or not cache.Highlight.Parent) and self.Settings.ESP.Players and self.Settings.ESP.Enabled then
        local highlight = Instance.new("Highlight")
        highlight.Name = "InovoFiveRESP"
        highlight.Adornee = character
        highlight.FillTransparency = 1
        highlight.OutlineColor = Color3.fromRGB(45, 160, 255)
        highlight.OutlineTransparency = 0
        highlight.Parent = character
        cache.Highlight = highlight
    end

    local billboard = cache.Billboard
    if (not billboard or not billboard.Parent) and (self.Settings.ESP.ShowNames or self.Settings.ESP.ShowDistance) then
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

    local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
    local distance = humanoidRoot and (HumanoidRootPart.Position - humanoidRoot.Position).Magnitude or math.huge
    cache.Distance = distance

    local withinRange = distance <= (self.Settings.ESP.MaxDistance or 1200)
    local showHighlight = self.Settings.ESP.Enabled and self.Settings.ESP.Players and withinRange

    if cache.Highlight then
        cache.Highlight.Enabled = showHighlight
        cache.Highlight.FillTransparency = 1
        cache.Highlight.OutlineTransparency = showHighlight and 0 or 1
    end

    if billboard then
        local showBillboard = showHighlight and (self.Settings.ESP.ShowNames or self.Settings.ESP.ShowDistance)
        billboard.Enabled = showBillboard

        if showBillboard then
            local label = billboard:FindFirstChild("Text")
            if label then
                local fragments = {}
                if self.Settings.ESP.ShowNames then
                    table.insert(fragments, player.DisplayName or player.Name)
                end
                if self.Settings.ESP.ShowDistance then
                    table.insert(fragments, "[" .. math.floor(distance) .. "m]")
                end
                label.Text = table.concat(fragments, " ")
            end
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

    if (not cache.Highlight or not cache.Highlight.Parent) and self.Settings.ESP.Vehicles then
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

    if not cache.PrimaryPart or not cache.PrimaryPart.Parent then
        if model:IsA("Model") then
            cache.PrimaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        elseif model:IsA("BasePart") then
            cache.PrimaryPart = model
        end
    end

    local distance = math.huge
    if cache.PrimaryPart then
        distance = (HumanoidRootPart.Position - cache.PrimaryPart.Position).Magnitude
    end
    cache.Distance = distance

    if cache.Highlight then
        local withinRange = self.Settings.ESP.Enabled and self.Settings.ESP.Vehicles and distance <= (self.Settings.ESP.MaxDistance or 1200)
        cache.Highlight.Enabled = withinRange
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
            self.__cache.ESPVehicles[model] = nil
        else
            self:EnsureVehicleESP(model)
        end
    end

    local maxDistance = self.Settings.ESP.MaxDistance or 1200
    if self.Settings.ESP.Vehicles then
        for _, seat in ipairs(Workspace:GetDescendants()) do
            if seat:IsA("VehicleSeat") or seat:IsA("Seat") then
                local model = seat:FindFirstAncestorOfClass("Model")
                if model and model ~= Character and (HumanoidRootPart.Position - seat.Position).Magnitude <= maxDistance then
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
    cache.FlyAltitude = nil
    cache.LastFlightTick = nil

    if Humanoid then
        Humanoid.PlatformStand = false
        Humanoid.AutoRotate = true
        if cache.OriginalHipHeight then
            pcall(function()
                Humanoid.HipHeight = cache.OriginalHipHeight
            end)
        end
    end

    cache.OriginalHipHeight = nil
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
    if not cache.FlyAltitude then
        cache.FlyAltitude = HumanoidRootPart.Position.Y
        if Humanoid then
            cache.OriginalHipHeight = Humanoid.HipHeight
            Humanoid.AutoRotate = false
        end
    end

    local now = tick()
    local dt = math.clamp(now - (cache.LastFlightTick or now), 0, 0.2)
    cache.LastFlightTick = now

    Humanoid.PlatformStand = false
    Humanoid:ChangeState(HumanoidStateType.Freefall)

    local verticalSpeed = math.clamp(self.Settings.Movement.FlySpeed / 4, 3, 18)
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        cache.FlyAltitude += verticalSpeed * dt
    elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
        cache.FlyAltitude -= verticalSpeed * dt
    end

    local rayResult = Workspace:Raycast(HumanoidRootPart.Position, Vector3.new(0, -200, 0), raycastParams)
    local groundY = rayResult and rayResult.Position.Y or (HumanoidRootPart.Position.Y - 200)
    cache.FlyAltitude = math.clamp(cache.FlyAltitude, groundY + 2, groundY + 120)

    local horizontal = Vector3.new()
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        horizontal += Camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        horizontal -= Camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        horizontal += Camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        horizontal -= Camera.CFrame.RightVector
    end
    horizontal = Vector3.new(horizontal.X, 0, horizontal.Z)
    if horizontal.Magnitude > 1 then
        horizontal = horizontal.Unit
    end

    local speed = math.clamp(self.Settings.Movement.FlySpeed, 10, 40)
    local moveDelta = horizontal * speed * dt
    local targetPos = HumanoidRootPart.Position + moveDelta
    targetPos = Vector3.new(targetPos.X, cache.FlyAltitude, targetPos.Z)

    HumanoidRootPart.AssemblyLinearVelocity = HumanoidRootPart.AssemblyLinearVelocity:Lerp(Vector3.zero, 0.45)

    local lookDirection = horizontal.Magnitude > 0 and horizontal.Unit or Camera.CFrame.LookVector
    local targetCFrame = CFrame.new(targetPos, targetPos + lookDirection)
    HumanoidRootPart.CFrame = HumanoidRootPart.CFrame:Lerp(targetCFrame, 0.6)

    if Humanoid and cache.OriginalHipHeight then
        Humanoid.HipHeight = math.clamp(cache.FlyAltitude - HumanoidRootPart.Position.Y, 0, cache.OriginalHipHeight + 2)
    end
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
        setLightingValue("Brightness", 3)
        setLightingValue("ClockTime", 14)
        setLightingValue("ColorShiftTop", Color3.fromRGB(160, 200, 255))
        setLightingValue("ColorShiftBottom", Color3.fromRGB(120, 170, 255))
        setLightingValue("Ambient", Color3.fromRGB(100, 120, 160))
        setLightingValue("OutdoorAmbient", Color3.fromRGB(140, 160, 200))
        setLightingValue("FogEnd", 3000)
    end

    if self.Settings.Misc.ClearWeather then
        setLightingValue("FogEnd", 100000)
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
            if not self.Settings.Misc.AntiAFK then
                return
            end

            pcall(function()
                local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(HumanoidStateType.Jumping)
                    humanoid:Move(Vector3.new(0, 0, 0), true)
                end
            end)
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
